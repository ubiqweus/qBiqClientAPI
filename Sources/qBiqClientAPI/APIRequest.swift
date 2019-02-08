//
//  APIRequest.swift
//  qbiq
//
//  Created by Kyle Jessup on 2017-12-23.
//  Copyright © 2017 Treefrog Inc. All rights reserved.
//

import Foundation
import SwiftCodables
import SAuthCodables

/// Response for an API call.
/// Call `try x.get()` to either return the response value or throw whatever error occured during the call.
public struct APIResponse<T> {
	/// Type of function returning response value or throwing the error.
	public typealias GetFunc = (() throws -> T)
	/// The `get` function.
	public let get: GetFunc
	/// Init an APIResponse.
	public init(_ fnc: @escaping GetFunc) {
		get = fnc
	}
}
#if DEBUG
let apiRequestTimeout = 60.0
#else
let apiRequestTimeout = 60.0
#endif

/// Namespace around lower level API request activities.
public struct APIRequest {
	/// Error type thrown from API calls.
	public struct Error: Swift.Error, Codable {
		/// The HTTP status code for the error response.
		public let status: Int
		/// Description of the problem.
		public let description: String
	}
	static func sendRequest<T>(endpointURL url: URL,
							sessionInfo: TokenAcquiredResponse? = nil,
							post: Bool = false,
							parameters: RequestParameters<T>,
							callback: @escaping (APIResponse<Data>) -> ()) {
	#if DEBUG
		//print("API request: " + url.absoluteString)
	#endif
		let session = URLSession.shared
		let request: NSMutableURLRequest
		if post {
			request = NSMutableURLRequest(url: url,
										  cachePolicy: .reloadIgnoringCacheData,
										  timeoutInterval: apiRequestTimeout)
			request.httpMethod = "POST"
			request.addValue("application/json", forHTTPHeaderField: "Content-Type")
			request.httpBody = parameters.jsonEncoded.data(using: .utf8)
		} else if let url = URL(string: url.absoluteString + "?\(parameters.formURLEncoded)") { // GET with params
			request = NSMutableURLRequest(url: url,
										  cachePolicy: .reloadIgnoringCacheData,
										  timeoutInterval: apiRequestTimeout)
		} else { // GET with no params
			request = NSMutableURLRequest(url: url,
										  cachePolicy: .reloadIgnoringCacheData,
										  timeoutInterval: apiRequestTimeout)
		}
		if let si = sessionInfo {
			let bearer = "Bearer \(si.token)"
			request.addValue(bearer, forHTTPHeaderField: "Authorization")
		}
		session.dataTask(with: request as URLRequest, completionHandler: {
			data, response, error in
			if let e = error  {
				return callback(APIResponse {throw e})
			}
			guard let response = response as? HTTPURLResponse else {
				return callback(APIResponse {throw Authentication.Error("Invalid response type.")})
			}
			guard let d = data else {
				return callback(APIResponse {throw Authentication.Error("Server returned no data.")})
			}
		#if DEBUG
			//print("API: \(url.absoluteString) status: \(response.statusCode) data size: \(data?.count ?? 0)")//"\ndata: " + (String(data: d, encoding: .utf8) ?? "no data"))//" token: \(sessionInfo?.token ?? "")")
		#endif
			guard response.statusCode == 200 else {
				if let error = try? JSONDecoder().decode(APIRequest.Error.self, from: d) {
					return callback(APIResponse {throw error})
				} else {
					return callback(APIResponse {throw Authentication.Error("Server returned error code \(response.statusCode) with data: \(String(data: d, encoding: .utf8) ?? "no data").")})
				}
			}
			callback(APIResponse {return d})
		}).resume()
	}
}

class SingleParameterWriter: SingleValueEncodingContainer {
	var codingPath: [CodingKey] = []
	var stringedValue = ""
	let parent: ParameterEncoder
	init(_ p: ParameterEncoder) {
		parent = p
	}
	
	func encodeNil() throws {
		
	}
	
	func encode(_ value: Bool) throws {
		stringedValue = "\(value)"
	}
	
	func encode(_ value: Int) throws {
		stringedValue = "\(value)"
	}
	
	func encode(_ value: Int8) throws {
		stringedValue = "\(value)"
	}
	
	func encode(_ value: Int16) throws {
		stringedValue = "\(value)"
	}
	
	func encode(_ value: Int32) throws {
		stringedValue = "\(value)"
	}
	
	func encode(_ value: Int64) throws {
		stringedValue = "\(value)"
	}
	
	func encode(_ value: UInt) throws {
		stringedValue = "\(value)"
	}
	
	func encode(_ value: UInt8) throws {
		stringedValue = "\(value)"
	}
	
	func encode(_ value: UInt16) throws {
		stringedValue = "\(value)"
	}
	
	func encode(_ value: UInt32) throws {
		stringedValue = "\(value)"
	}
	
	func encode(_ value: UInt64) throws {
		stringedValue = "\(value)"
	}
	
	func encode(_ value: Float) throws {
		stringedValue = "\(value)"
	}
	
	func encode(_ value: Double) throws {
		stringedValue = "\(value)"
	}
	
	func encode(_ value: String) throws {
		stringedValue = "\(value)"
	}
	
	func encode<T>(_ value: T) throws where T : Encodable {
		try value.encode(to: parent)
	}
}

class ParameterWriter<K: CodingKey>: KeyedEncodingContainerProtocol {
	typealias Key = K
	let codingPath: [CodingKey] = []
	let parent: ParameterEncoder
	init(_ p: ParameterEncoder) {
		parent = p
	}
	func addParameter(_ key: Key, value: String) {
		parent.addParameter(key: key, value: value)
	}
	func encodeNil(forKey key: K) throws {
		addParameter(key, value: "")
	}
	func encode(_ value: Bool, forKey key: K) throws {
		addParameter(key, value: String(value))
	}
	func encode(_ value: Int, forKey key: K) throws {
		addParameter(key, value: String(value))
	}
	func encode(_ value: Int8, forKey key: K) throws {
		addParameter(key, value: String(value))
	}
	func encode(_ value: Int16, forKey key: K) throws {
		addParameter(key, value: String(value))
	}
	func encode(_ value: Int32, forKey key: K) throws {
		addParameter(key, value: String(value))
	}
	func encode(_ value: Int64, forKey key: K) throws {
		addParameter(key, value: String(value))
	}
	func encode(_ value: UInt, forKey key: K) throws {
		addParameter(key, value: String(value))
	}
	func encode(_ value: UInt8, forKey key: K) throws {
		addParameter(key, value: String(value))
	}
	func encode(_ value: UInt16, forKey key: K) throws {
		addParameter(key, value: String(value))
	}
	func encode(_ value: UInt32, forKey key: K) throws {
		addParameter(key, value: String(value))
	}
	func encode(_ value: UInt64, forKey key: K) throws {
		addParameter(key, value: String(value))
	}
	func encode(_ value: Float, forKey key: K) throws {
		addParameter(key, value: String(value))
	}
	func encode(_ value: Double, forKey key: K) throws {
		addParameter(key, value: String(value))
	}
	func encode(_ value: String, forKey key: K) throws {
		addParameter(key, value: value)
	}
	func encode<T>(_ value: T, forKey key: K) throws where T : Encodable {
		try value.encode(to: parent)
		if let s = parent.lastSingleParameter {
			addParameter(key, value: s.stringedValue)
			parent.lastSingleParameter = nil
		}
	}
	func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
		fatalError("Unimplemented")
	}
	func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
		fatalError("Unimplemented")
	}
	func superEncoder() -> Encoder {
		fatalError("Unimplemented")
	}
	func superEncoder(forKey key: K) -> Encoder {
		fatalError("Unimplemented")
	}
}

class ParameterEncoder: Encoder {
	let codingPath: [CodingKey] = []
	let userInfo: [CodingUserInfoKey : Any] = [:]
	var collected: [(String, String)] = []
	var lastSingleParameter: SingleParameterWriter?
	var formURLEncoded: String {
		let a = collected.compactMap {
			(nvName, nvValue) -> String? in
			guard let name = nvName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
				let value = nvValue.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
					return nil
			}
			return "\(name)=\(value)"
		}
		return a.joined(separator: "&")
	}
	func addParameter<Key: CodingKey>(key: Key, value: String) {
		collected.append((key.stringValue, value))
	}
	func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
		return KeyedEncodingContainer<Key>(ParameterWriter<Key>(self))
	}
	func unkeyedContainer() -> UnkeyedEncodingContainer {
		fatalError("Unimplemented")
	}
	func singleValueContainer() -> SingleValueEncodingContainer {
		let single = SingleParameterWriter(self)
		lastSingleParameter = single
		return single
	}
}
