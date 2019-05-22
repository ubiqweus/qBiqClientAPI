//
//  Authentication.swift
//  qbiq
//
//  Created by Kyle Jessup on 2017-11-10.
//  Copyright © 2017 Treefrog Inc. All rights reserved.
//

import Foundation
import OAuthSwift
import SwiftCodables
import SAuthCodables

#if false//DEBUG // this
	#if TARGET_IPHONE_SIMULATOR
let authServerBaseURL = "http://localhost:8181"
	#else
let authServerBaseURL = "http://192.168.0.26:8181"
	#endif
#else
let authServerBaseURL = "https://auth.ubiqweus.com"
#endif

let sessionIdKey = "sessionid"

enum AuthAPIEndpoint: String {
	case register = "/api/v1/register"
	case login = "/api/v1/login"
	case passReset = "/api/v1/passreset"
	case me = "/api/v1/a/me"
	case changePassword = "/api/v1/a/changepassword"
	case myData = "/api/v1/a/mydata"
	
	case oauthGoogleReturn = "/api/v1/oauth/return/google"
	case oauthFacebookReturn = "/api/v1/oauth/return/facebook"
	case oauthLinkedInReturn = "/api/v1/oauth/return/linkedin"
	case oauthUpgrade = "/api/v1/oauth/upgrade/"
	
	case addDeviceId = "/api/v1/a/mobile/add"
	
	var url: URL {
		return URL(string: authServerBaseURL + rawValue)!
	}
}

/// An authenticated SAuth user account.
public typealias AuthenticatedUser = Account
/// Extensions on Account.
public extension Account {
	/// User id as a string.
	var userId: String { return id.uuidString }
}

struct AuthServerResponse: Decodable {
	let error: String?
	let msg: String?
}

struct RequestParameters<Body: Encodable> {
	typealias NameValuePair = (name: String, value: String)
	let body: Body
	let paths: [String]
	var _rawString: String? = nil

	init(rawString: String) {
		_rawString = rawString
		body = rawString as! Body
		paths = []
	}

	init(body b: Body, paths p: [String] = []) {
    _rawString = nil
		body = b
		paths = p
	}
	
	var formURLEncoded: String {
		let encoder = ParameterEncoder()
		do {
			try body.encode(to: encoder)
			return encoder.formURLEncoded
		} catch {
			return ""
		}
	}
	
	var jsonEncoded: String {
		if let raw = _rawString {
			return raw
		}
		guard let data = try? JSONEncoder().encode(body),
				let s = String(data: data, encoding: .utf8) else {
			return "{}"
		}
		return s
	}
	
	func complete(url: URL) -> URL {
		guard !paths.isEmpty else {
			return url
		}
		return URL(string:
			url.absoluteString + "/" + paths.compactMap {
				$0.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) }.joined(separator: "/"))!
	}
}

/// Current state of user authentication for the app.
/// One instance of this should be created when the app moves to try and authenticate the user.
/// The global instance of this object is in `Authentication.shared`.
public class Authentication {
	/// The shared instance.
	public private(set) static var shared: Authentication?
	/// The id for the users mobile device.
	/// This is used for APN and should be set by the app.
	/// If this `deviceId` value is set when the user is authenticated then
	/// then the `addDeviceId` call will automatically send the value to the Auth server.
	public static var deviceId: String?
	/// Error object thrown for some auth related problems.
	public struct Error: Swift.Error, CustomStringConvertible {
		/// A description of the problem.
		public let description: String
		init(_ message: String)  {
			description = message
		}
	}
	/// The token returned by the auth server after successful authentication.
	/// When set, this value will be written to UserDefaults.
	public var token: TokenAcquiredResponse? {
		didSet {
			if let s = token {
				UserDefaults.standard.set(s.token, forKey: sessionIdKey)
				user = s.account
			#if DEBUG
				print("token: \(token?.token ?? "none")")
			#endif
			} else {
				UserDefaults.standard.removeObject(forKey: sessionIdKey)
				user = nil
			}
			UserDefaults.standard.synchronize()
		}
	}
	/// The authenticated user. If this is nil then the user is not authenticated.
	public var user: AuthenticatedUser? {
		didSet {
			if let deviceId = Authentication.deviceId {
				DispatchQueue.global().async {
					self.addDeviceId(deviceId) {
						try? $0.get()
					}
				}
			}
		}
	}
	var oauth: OAuth2Swift?
	/// Init an Authentication.
	public init() {
		if let sessionId = UserDefaults.standard.string(forKey: sessionIdKey) {
			token = TokenAcquiredResponse(token: sessionId, account: nil)
		} else {
			token = nil
		}
		Authentication.shared = self
	}
	
	func settingsFor(service: String) -> [String:String] {
		if let path = Bundle.main.path(forResource: "Services", ofType: "plist"),
			let d = NSDictionary(contentsOfFile: path) as? [String:Any],
			let ret = d[service] as? [String:String] {
			return ret
		}
		return [:]
	}
	/// Checks if the user is logged in and that the current token is valid.
	/// The response will be delivered to the provided callback.
	public func checkLoggedIn(callback: @escaping (APIResponse<Bool>) -> ()) {
		if let _ = user {
			return callback(APIResponse {return true})
		}
		// if no session then we are not logged in
		if nil == token {
			return callback(APIResponse {return false})
		}
		// check with the server
		getMe() {
			result in
			do {
				self.user = try result.get()
				callback(APIResponse {return true})
			} catch {
				callback(APIResponse {return false})
			}
		}
	}
	/// Retrieves up to date information for the current user.
	/// The response will be delivered to the provided callback.
	public func getMe(callback: @escaping (APIResponse<AuthenticatedUser>) -> ()) {
		sendRequest(endpoint: .me, sessionInfo: self.token) {
			result in
			do {
				let d = try JSONDecoder().decode(AuthenticatedUser.self, from: try result.get())
				callback(APIResponse {return d})
			} catch {
				
				callback(APIResponse {
					self.token = nil
					throw error
				})
			}
		}
	}
	/// Remove all current authentication state.
	/// The response will be delivered to the provided callback.
	public func logout(callback: @escaping (APIResponse<Void>) -> ()) {
		guard let _ = token else {
			return callback(APIResponse {return})
		}
		callback(APIResponse {
			self.token = nil
			self.user = nil
		})
	}
	/// Attempt to log in with the given address and password.
	/// The response will be delivered to the provided callback.
	public func login(email: String, password: String, callback: @escaping (APIResponse<Void>) -> ()) {
		let params = RequestParameters(body: ["email":email, "password":password])
		sendRequest(endpoint: .login, sessionInfo: self.token, post: false, parameters: params) {
			result in
			do {
				let response = try JSONDecoder().decode(TokenAcquiredResponse.self, from: try result.get())
				self.token = response
				callback(APIResponse {return})
			} catch {
				callback(APIResponse {throw error})
			}
		}
	}
	/// Complete a device local password recovery operation.
	/// The `password` parameter will be the new password to set.
	/// The `token` will have been obtained by
	/// The response will be delivered to the provided callback.
	public func completeRecoverPassword(address: String, password: String, token: String, callback: @escaping (APIResponse<Void>) -> ()) {
		let req = AuthAPI.PasswordResetCompleteRequest(address: address, password: password, authToken: token)
		let params = RequestParameters(body: req)
		sendRequest(endpoint: .passReset, post: true, parameters: params) {
			result in
			do {
				let response = try JSONDecoder().decode(TokenAcquiredResponse.self, from: try result.get())
				self.token = response
				callback(APIResponse {return})
			} catch {
				callback(APIResponse {throw error})
			}
		}
	}
	/// Begin a password recovery operation.
	/// If the user has previously logged in on the device and an APNS device token
	/// was successfully set on the server then a device local recovery will be attempted.
	/// The response will be delivered to the provided callback.
	public func startRecoverPassword(address: String, callback: @escaping (APIResponse<Void>) -> ()) {
		let req = AuthAPI.PasswordResetRequest(address: address, deviceId: Authentication.deviceId)
		let params = RequestParameters(body: req)
		sendRequest(endpoint: .passReset, parameters: params) {
			result in
			do {
				_ = try result.get()
				callback(APIResponse {return})
			} catch {
				callback(APIResponse {throw error})
			}
		}
	}
	/// Get the meta-data attached to the account.
	/// Currently only `fullName` is supported.
	/// The response will be delivered to the provided callback.
	public func getMeta(callback: @escaping (APIResponse<AccountPublicMeta>) -> ()) {
		sendRequest(endpoint: .myData, sessionInfo: self.token) {
			result in
			do {
				let d = try JSONDecoder().decode(AccountPublicMeta.self, from: try result.get())
				callback(APIResponse {return d})
			} catch {
				callback(APIResponse {throw error})
			}
		}
	}
	/// Set meta-data for the account.
	/// Currently only `fullName` is supported.
	/// The response will be delivered to the provided callback.
	public func putMeta(data: AccountPublicMeta, callback: @escaping (APIResponse<Void>) -> ()) {
		let params = RequestParameters(body: data)
		sendRequest(endpoint: .myData, sessionInfo: self.token, post: true, parameters: params) {
			result in
			do {
				let _ = try JSONSerialization.jsonObject(with: try result.get(), options: [])
				callback(APIResponse {return})
			} catch {
				callback(APIResponse {throw error})
			}
		}
	}
	/// Attempt to register a new account.
	/// If successful this will also set the full name meta value.
	/// The response will be delivered to the provided callback.
	public func register(email: String, password: String, fullName: String, callback: @escaping (APIResponse<Void>) -> ()) {
		let params = RequestParameters(body: ["email":email, "password":password, "fullName":fullName])
		sendRequest(endpoint: .register, sessionInfo: self.token, post: true, parameters: params) {
			result in
			do {
				_ = try JSONDecoder().decode(AliasBrief.self, from: try result.get())
				callback(APIResponse {return})
			} catch {
				callback(APIResponse {throw error})
			}
		}
	}
	/// Send the device id to the server.
	/// It will be stored with the user's account and used for push notifications.
	/// The response will be delivered to the provided callback.
	public func addDeviceId(_ id: String, callback: @escaping (APIResponse<Void>) -> ()) {
		let request = AuthAPI.AddMobileDeviceRequest(deviceId: id, deviceType: "ios")
		let params = RequestParameters(body: request)
		sendRequest(endpoint: .addDeviceId, sessionInfo: token, post: true, parameters: params) {
			result in
			do {
				_ = try result.get()
				callback(APIResponse {return})
			} catch {
				callback(APIResponse {throw error})
			}
		}
	}
	
	fileprivate func sendRequest<T>(endpoint: AuthAPIEndpoint,
								 sessionInfo: TokenAcquiredResponse? = nil,
								 post: Bool = false,
								 parameters: RequestParameters<T>,
								 callback: @escaping (APIResponse<Data>) -> ()) {
		let url = parameters.complete(url: endpoint.url)
		APIRequest.sendRequest(endpointURL: url, sessionInfo: sessionInfo, post: post, parameters: parameters, callback: callback)
	}
	
	fileprivate func sendRequest(endpoint: AuthAPIEndpoint,
								 sessionInfo: TokenAcquiredResponse? = nil,
								 post: Bool = false,
								 callback: @escaping (APIResponse<Data>) -> ()) {
		sendRequest(endpoint: endpoint, sessionInfo: sessionInfo, post: post, parameters: RequestParameters(body: [String:String]()), callback: callback)
	}
}
/// OAuth related extensions on Authentication
public extension Authentication {
	/// Abstracted handler maker.
	typealias OAuthURLHandlerMaker = (OAuth2Swift) -> OAuthSwiftURLHandlerType
	
	private func oauthSuccess(provider: String, _ credential: OAuthSwiftCredential, _ response: OAuthSwiftResponse?, _ parameters: OAuthSwift.Parameters, _ callback: @escaping (APIResponse<Void>) -> ()) {
		let token = credential.oauthToken
		upgradeUser(provider: provider, token: token) {
			result in
			DispatchQueue.main.async {
				callback(APIResponse {
					try result.get()
				})
			}
		}
	}
	/// Attempt to log in through Google OAuth.
	/// The response will be delivered to the provided callback.
	func loginOAuthGoogle(handlerMaker: OAuthURLHandlerMaker, callback: @escaping (APIResponse<Void>) -> ()) {
		let params = settingsFor(service: "Google")
		guard let oauth = OAuth2Swift(parameters: params) else {
			return callback(APIResponse { throw Authentication.Error("Unable to get parameters for OAuth service \"Google\".") })
		}
		self.oauth = oauth
		oauth.authorizeURLHandler = handlerMaker(oauth) // OAuthSwiftOpenURLExternally.sharedInstance
		oauth.authorize(withCallbackURL: AuthAPIEndpoint.oauthGoogleReturn.url,
						scope: "https://www.googleapis.com/auth/plus.profile.emails.read",
						state: generateState(withLength: 20),
						success: {
							(a, b, c) in
							return self.oauthSuccess(provider: "google", a, b, c, callback)
						},
						failure: {
							error in
							self.oauth = nil
							callback(APIResponse {throw error})
						}
		)
	}
	
	/// Attempt to log in through Facebook OAuth.
	/// The response will be delivered to the provided callback.
	func loginOAuthFacebook(handlerMaker: OAuthURLHandlerMaker, callback: @escaping (APIResponse<Void>) -> ()) {
		let params = settingsFor(service: "Facebook")
		guard let oauth = OAuth2Swift(parameters: params) else {
			return callback(APIResponse { throw Authentication.Error("Unable to get parameters for OAuth service \"Facebook\".") })
		}
		self.oauth = oauth
		oauth.authorizeURLHandler = handlerMaker(oauth)
		oauth.authorize(withCallbackURL: AuthAPIEndpoint.oauthFacebookReturn.url,
						scope: "email",
						state: generateState(withLength: 20),
						success: {
							(a, b, c) in
							return self.oauthSuccess(provider: "facebook", a, b, c, callback)
		},
						failure: {
							error in
							self.oauth = nil
							callback(APIResponse {throw error})
		}
		)
	}
	
	/// Attempt to log in through Linkedin OAuth.
	/// The response will be delivered to the provided callback.
	func loginOAuthLinkedin(handlerMaker: OAuthURLHandlerMaker, callback: @escaping (APIResponse<Void>) -> ()) {
		let params = settingsFor(service: "Linkedin")
		guard let oauth = OAuth2Swift(parameters: params) else {
			return callback(APIResponse { throw Authentication.Error("Unable to get parameters for OAuth service \"Linkedin\".") })
		}
		self.oauth = oauth
		oauth.authorizeURLHandler = handlerMaker(oauth)
		oauth.authorize(withCallbackURL: AuthAPIEndpoint.oauthLinkedInReturn.url,
						scope: "r_basicprofile,r_emailaddress",
						state: generateState(withLength: 20),
						success: {
							(a, b, c) in
							return self.oauthSuccess(provider: "linkedin", a, b, c, callback)
		},
						failure: {
							error in
							self.oauth = nil
							callback(APIResponse {throw error})
		}
		)
	}
	
	private func upgradeUser(provider: String, token: String, callback: @escaping (APIResponse<Void>) -> ()) {
		let params = RequestParameters(body: EmptyReply(), paths: [provider, token])
		self.sendRequest(endpoint: .oauthUpgrade, sessionInfo: self.token, parameters: params) {
			result in
			do {
				let response = try JSONDecoder().decode(TokenAcquiredResponse.self, from: try result.get())
				self.token = response
				callback(APIResponse {return})
			} catch {
				callback(APIResponse {throw error})
			}
		}
	}
}

