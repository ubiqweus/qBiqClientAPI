//
//  Devices.swift
//  qbiq
//
//  Created by Kyle Jessup on 2017-12-23.
//  Copyright © 2017 Treefrog Inc. All rights reserved.
//

import Foundation
import SwiftCodables
import SAuthCodables

#if false//DEBUG // this
	#if TARGET_IPHONE_SIMULATOR
let apiServerBaseURL = "http://localhost:8080"
	#else
let apiServerBaseURL = "http://10.10.1.134:8080"//"http://192.168.0.26:8080"
	#endif
#else
let apiServerBaseURL = "https://api.ubiqweus.com"
#endif

let apiVersion = "v1"

enum APIEndpoint: String {
	case groupList = "/group/list"
	case groupCreate = "/group/create"
	case groupUpdate = "/group/update"
	case groupDelete = "/group/delete"
	case groupDeviceAdd = "/group/device/add"
	case groupDeviceRemove = "/group/device/remove"
	case groupDeviceList = "/group/device/list"

	case deviceSearch = "/device/search"
	case deviceList = "/device/list"
	case deviceStat = "/device/stat"
	case deviceRegister = "/device/register"
	case deviceUnregister = "/device/unregister"
	case deviceInfo = "/device/info"
	case deviceShare = "/device/share"
	case deviceShareToken = "/device/share/token"
	case deviceUnshare = "/device/unshare"
	case deviceUpdate = "/device/update"
	case deviceObservations = "/device/obs"
	case deviceSummary = "/device/sum"
	case deviceDeleteObservations = "/device/obs/delete"
	case deviceSetLimits = "/device/limits"
	case deviceProfileUpdate = "/device/profile/update"
	case deviceProfileGet = "/device/profile/get"
	case deviceLocation = "/device/location"
	case deviceFollowers = "/device/followers"
	case deviceTag = "/device/tag"
	case deviceTagGet = "/device/tag/get"
	case deviceTagDel = "/device/tag/del"
	case deviceTagAdd = "/device/tag/add"
	case deviceType = "/device/type"
	case deviceBookmark = "/device/bookmark"
	case deviceFirmware = "/device/firmware"

	case chatLoad = "/chat/load"
	case chatSave = "/chat/save"

	case profileUpload = "/profile/upload"
	case profileDownload = "/profile/download"
	case profileUpdateText = "/profile/update"
	case profileGetText = "/profile/get"
	case profileGetFullName = "/profile/name"
	case profileBill = "/profile/bill"

	case recipeGet = "/recipe/get"
	case recipeDel = "/recipe/del"
	case recipeSet = "/recipe/set"
	case recipeTagAdd = "/recipe/tag/add"
	case recipeTagDel = "/recipe/tag/del"
	case recipeTagGet = "/recipe/tag/get"
	case recipeMediaAdd = "/recipe/media/add"
	case recipeMediaDel = "/recipe/media/del"
	case recipeMediaGet = "/recipe/media/get"
	case recipeThresholdAdd = "/recipe/threshold/add"
	case recipeThresholdDel = "/recipe/threshold/del"
	case recipeThresholdGet = "/recipe/threshold/get"
	case recipeSearch = "/recipe/search"

	var url: URL {
		return URL(string: "\(apiServerBaseURL)/\(apiVersion)\(rawValue)")!
	}
	var post: Bool {
		switch self {
		case .groupList:
			return false
		case .groupCreate:
			return true
		case .groupUpdate:
			return true
		case .groupDelete:
			return true
		case .groupDeviceAdd:
			return true
		case .groupDeviceRemove:
			return true
		case .groupDeviceList:
			return false
		case .deviceSearch:
			return false
		case .deviceList:
			return false
		case .deviceStat:
			return false
		case .deviceRegister:
			return true
		case .deviceUnregister:
			return true
		case .deviceUpdate:
			return true
		case .deviceObservations:
			return false
		case .deviceSummary:
			return false
		case .deviceShare:
			return true
		case .deviceUnshare:
			return true
		case .deviceInfo:
			return false
		case .deviceSetLimits:
			return true
		case .deviceDeleteObservations:
			return true
		case .deviceShareToken:
			return true
		case .deviceProfileGet:
			return false
		case .deviceProfileUpdate:
			return true
		case .deviceLocation:
			return true
		case .deviceFollowers:
			return true
		case .deviceTag:
			return false
		case .deviceTagGet:
			return false
		case .deviceTagAdd:
			return true
		case .deviceTagDel:
			return true
		case .deviceType:
			return false
		case .deviceBookmark:
			return true
		case .deviceFirmware:
			return false
		case .chatLoad:
			return false
		case .chatSave:
			return true
		case .profileUpload:
			return true
		case .profileDownload:
			return false
		case .profileUpdateText:
			return true
		case .profileGetText:
			return false
		case .profileGetFullName:
			return false
		case .profileBill:
			return true
		case .recipeGet:
			return false
		case .recipeDel:
			return false
		case .recipeSet:
			return true
		case .recipeTagAdd:
			return true
		case .recipeTagDel:
			return true
		case .recipeTagGet:
			return false
		case .recipeMediaAdd:
			return true
		case .recipeMediaDel:
			return true
		case .recipeMediaGet:
			return false
		case .recipeThresholdAdd:
			return true
		case .recipeThresholdDel:
			return true
		case .recipeThresholdGet:
			return false
		case .recipeSearch:
			return false
		}
	}
}

public struct Receipt: Codable {
	public let product_id: String
	public let purchase_date_ms: String
	public let expires_date_ms: String

	private func getTimeStamp(_ value: String) -> Int {
		return Int((TimeInterval(purchase_date_ms) ?? 0) / 1000)
	}
	public var timestampPurchase: Int {
		return getTimeStamp(purchase_date_ms)
	}

	public var timestampExpiration: Int {
		return getTimeStamp(expires_date_ms)
	}

	public init(product_id id: String, purchase_date_ms p: String, expires_date_ms e: String) {
		product_id = id
		purchase_date_ms = p
		expires_date_ms = e
	}
}

public struct MovementSummary: Codable {
	public var unitid = 0
	public var moves = 0
}

public struct ChatLogQuery: Codable {
	public let last: Int64
	public init(last l: Int64) {
		last = l
	}
}

public struct ProfileAPIRequest: Codable {
	public var uid = ""
}

public struct RecipeAPIRequest: Codable {
	public var uri = ""
}

public typealias RecipeAPIResponse = ProfileAPIResponse

extension APIResponse where T: Decodable {
	init(from: APIResponse<Data>) {
		self.init { () -> T in
			return try JSONDecoder().decode(T.self, from: try from.get())
		}
	}
}

private func sendRequest<T>(endpoint: APIEndpoint,
														parameters: RequestParameters<T>,
														callback: @escaping (APIResponse<Data>) -> ()) {
	let url = parameters.complete(url: endpoint.url)
	guard let session = Authentication.shared?.token else {
		return callback(APIResponse {throw Authentication.Error("No user token.")})
	}
	APIRequest.sendRequest(endpointURL: url, sessionInfo: session, post: endpoint.post, parameters: parameters, callback: callback)
}

private func sendRequest(endpoint: APIEndpoint,
												 callback: @escaping (APIResponse<Data>) -> ()) {
	sendRequest(endpoint: endpoint, parameters: RequestParameters(body: [String:String]()), callback: callback)
}

/// Device related API calls.
public extension DeviceAPI {
	/// List all devices the user has access to.
	/// The response will be delivered to the provided callback.
	static func listDevices(user: AuthenticatedUser, callback: @escaping (APIResponse<[DeviceAPI.ListDevicesResponseItem]>) -> ()) {
		sendRequest(endpoint: .deviceList) { callback(APIResponse(from: $0)) }
	}
	/// Rename the indicated device.
	/// This will fail if the user is not the device's owner.
	/// The response will be delivered to the provided callback.
	static func renameDevice(user: AuthenticatedUser, deviceId: DeviceURN, newName: String, callback: @escaping (APIResponse<EmptyReply>) -> ()) {
		let request = DeviceAPI.UpdateRequest(deviceId: deviceId, name: newName)
		sendRequest(endpoint: .deviceUpdate, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}
	/// Attempt to register the indicated device.
	/// If successful the current user will become the device's owner.
	/// The response will be delivered to the provided callback.
	static func registerDevice(user: AuthenticatedUser, deviceId: DeviceURN, callback: @escaping (APIResponse<BiqDevice>) -> ()) {
		let request = DeviceAPI.RegisterRequest(deviceId: deviceId)
		sendRequest(endpoint: .deviceRegister, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}
	/// Attempt to unregister the indicated device.
	/// If successful then the device will become unowned.
	/// The response will be delivered to the provided callback.
	static func unregisterDevice(user: AuthenticatedUser, deviceId: DeviceURN, callback: @escaping (APIResponse<EmptyReply>) -> ()) {
		let request = DeviceAPI.RegisterRequest(deviceId: deviceId)
		sendRequest(endpoint: .deviceUnregister, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}
	/// Attempt to share the device to the current user.
	/// This will fail if the device is locked and no valid share token is provided.
	/// The response will be delivered to the provided callback.
	static func shareDevice(user: AuthenticatedUser, deviceId: DeviceURN, shareToken: UUID?, callback: @escaping (APIResponse<BiqDevice>) -> ()) {
		let request = DeviceAPI.ShareRequest(deviceId: deviceId, token: shareToken)
		sendRequest(endpoint: .deviceShare, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}
	/// Remove a shared device.
	/// The response will be delivered to the provided callback.
	static func unshareDevice(user: AuthenticatedUser, deviceId: DeviceURN, callback: @escaping (APIResponse<EmptyReply>) -> ()) {
		let request = DeviceAPI.ShareRequest(deviceId: deviceId)
		sendRequest(endpoint: .deviceUnshare, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}
	/// Create a share token which can be given to another user permitting them to
	/// observe the device's data.
	/// The response will be delivered to the provided callback.
	static func getShareDeviceToken(user: AuthenticatedUser, deviceId: DeviceURN, callback: @escaping (APIResponse<ShareTokenResponse>) -> ()) {
		let request = DeviceAPI.ShareTokenRequest(deviceId: deviceId)
		sendRequest(endpoint: .deviceShareToken, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}
	/// Retrieve information on the indicated device.
	/// The response will be delivered to the provided callback.
	static func deviceInfo(user: AuthenticatedUser, deviceId: DeviceURN, callback: @escaping (APIResponse<BiqDevice>) -> ()) {
		let request = DeviceAPI.ShareRequest(deviceId: deviceId)
		sendRequest(endpoint: .deviceInfo, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}
	/// Retrieve device observations of the indicated interval.
	/// The response will be delivered to the provided callback.
	static func deviceObservations(user: AuthenticatedUser,
																 deviceId: DeviceURN,
																 interval: DeviceAPI.ObsRequest.Interval, callback: @escaping (APIResponse<[ObsDatabase.BiqObservation]>) -> ()) {
		let request = DeviceAPI.ObsRequest(deviceId: deviceId, interval: interval)
		sendRequest(endpoint: .deviceObservations, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}
	/// Retrieve device summary of the indicated interval.
	/// The response will be delivered to the provided callback.
	static func deviceSummary(user: AuthenticatedUser,
														deviceId: DeviceURN,
														interval: DeviceAPI.ObsRequest.Interval, callback: @escaping (APIResponse<[MovementSummary]>) -> ()) {
		let request = DeviceAPI.ObsRequest(deviceId: deviceId, interval: interval)
		sendRequest(endpoint: .deviceSummary, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}

	static func deviceProfileUpdate(user: AuthenticatedUser,
																	profile: BiqProfile,
																	callback: @escaping (APIResponse<ProfileAPIResponse>) -> ()) {
		sendRequest(endpoint: .deviceProfileUpdate, parameters: RequestParameters(body: profile)) {
			callback(APIResponse(from: $0))
		}
	}

	static func deviceProfileGet(user: AuthenticatedUser, uid: String,
															 callback: @escaping (APIResponse<BiqProfile>) -> ()) {
		let request = ProfileAPIRequest.init(uid: uid)
		sendRequest(endpoint: .deviceProfileGet, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}

	static func deviceLocation(user: AuthenticatedUser, location: BiqLocation,
														 callback: @escaping (APIResponse<ProfileAPIResponse>) -> ()) {
		sendRequest(endpoint: .deviceLocation, parameters: RequestParameters(body: location)) {
			callback(APIResponse(from: $0))
		}
	}

	static func deviceFollowers(user: AuthenticatedUser, deviceId: DeviceURN,
															callback: @escaping (APIResponse<[String]>) -> ()) {
		let req = RequestParameters<String>(rawString: deviceId)
		sendRequest(endpoint: .deviceFollowers, parameters: req) {
			callback(APIResponse(from: $0))
		}
	}

	static func deviceTag(user: AuthenticatedUser, tag: String,
												callback: @escaping (APIResponse<[BiqDevice]>) -> ()) {
		struct SimpleRequest: Codable {
			let with: String
		}
		let request = SimpleRequest.init(with: tag)
		sendRequest(endpoint: .deviceTag, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}

	static func deviceTagGet(user: AuthenticatedUser, uid: String,
													 callback: @escaping (APIResponse<[BiqProfileTag]>) -> ()) {
		let request = ProfileAPIRequest(uid: uid)
		sendRequest(endpoint: .deviceTagGet, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}

	static func deviceTagAdd(user: AuthenticatedUser, tags: [BiqProfileTag],
													 callback: @escaping (APIResponse<ProfileAPIResponse>) -> ()) {
		sendRequest(endpoint: .deviceTagAdd, parameters: RequestParameters(body: tags)) {
			callback(APIResponse(from: $0))
		}
	}

	static func deviceTagDel(user: AuthenticatedUser, tags: [BiqProfileTag],
													 callback: @escaping (APIResponse<ProfileAPIResponse>) -> ()) {
		sendRequest(endpoint: .deviceTagDel, parameters: RequestParameters(body: tags)) {
			callback(APIResponse(from: $0))
		}
	}

	static func deviceType(user: AuthenticatedUser, deviceId: DeviceURN, enableMovementFeature: Bool,
												 callback: @escaping (APIResponse<ProfileAPIResponse>) -> ()) {
		struct DeviceTypeSettings: Codable {
			let id: String
			let move: Int
		}
		let setting = DeviceTypeSettings.init(id: deviceId, move: enableMovementFeature ? 1 : 0)
		sendRequest(endpoint: .deviceType, parameters: RequestParameters(body: setting)) {
			callback(APIResponse(from: $0))
		}
	}

	static func setBookmark(user: AuthenticatedUser, bookmark: BiqBookmark,
													callback: @escaping (APIResponse<ProfileAPIResponse>) -> ()) {
		sendRequest(endpoint: .deviceBookmark, parameters: RequestParameters(body: bookmark)) {
			callback(APIResponse(from: $0))
		}
	}

	static func deviceFirmware(user: AuthenticatedUser,
														 callback: @escaping (APIResponse<[BiqDeviceFirmware]>) -> ()) {
		sendRequest(endpoint: .deviceFirmware) {
			callback(APIResponse(from: $0))
		}
	}

	static func chatLoad(user: AuthenticatedUser,
											 checkpoint: Int64,
											 callback: @escaping (APIResponse<[ChatLog]>) -> ()) {
		let request = ChatLogQuery.init(last: checkpoint)
		sendRequest(endpoint: .chatLoad, parameters: RequestParameters(body: request)){
			callback(APIResponse(from : $0))
		}
	}

	static func chatSave(user: AuthenticatedUser,
											 deviceId: DeviceURN,
											 message: String,
											 callback: @escaping (APIResponse<Int>) -> ()) {
		let request = ChatLogCreation.init(topic: deviceId, content: message)
		sendRequest(endpoint: .chatSave, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}

	static func profileUpload(user: AuthenticatedUser, payload: String, callback: @escaping (APIResponse<ProfileAPIResponse>) -> ()) {
		let request = ProfileAPIResponse.init(content: payload)
		sendRequest(endpoint: .profileUpload, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}

	static func profileDownload(user: AuthenticatedUser, uid: String, callback: @escaping (APIResponse<ProfileAPIResponse>) -> ()) {
		let request = ProfileAPIRequest.init(uid: uid)
		sendRequest(endpoint: .profileDownload, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}

	static func profileUpdateText(user: AuthenticatedUser, payload: String, callback: @escaping (APIResponse<ProfileAPIResponse>) -> ()) {
		let request = ProfileAPIResponse.init(content: payload)
		sendRequest(endpoint: .profileUpdateText, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}

	static func profileGetText(user: AuthenticatedUser, uid: String, callback: @escaping (APIResponse<ProfileAPIResponse>) -> ()) {
		let request = ProfileAPIRequest.init(uid: uid)
		sendRequest(endpoint: .profileGetText, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}

	static func profileGetFullName(user: AuthenticatedUser, uid: String, callback: @escaping (APIResponse<ProfileAPIResponse>) -> ()) {
		let request = ProfileAPIRequest.init(uid: uid)
		sendRequest(endpoint: .profileGetFullName, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}

	static func profileValidateBill(user: AuthenticatedUser, receipt: Data, callback: @escaping (APIResponse<[Receipt]>) -> ()) {
		let postbody = receipt.base64EncodedString()
		sendRequest(endpoint: .profileBill, parameters: RequestParameters<String>(rawString: postbody)) {
			callback(APIResponse(from: $0))
		}
	}

	static func deviceStat(user: AuthenticatedUser, uid: String, callback: @escaping (APIResponse<BiqStat>) -> ()) {
		let request = ProfileAPIRequest.init(uid: uid)
		sendRequest(endpoint: .deviceStat, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}

	static func deviceSearch(user: AuthenticatedUser, uid: String, callback: @escaping (APIResponse<[BiqDevice]>) -> ()) {
		let request = ProfileAPIRequest.init(uid: uid)
		sendRequest(endpoint: .deviceSearch, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}


	/// Delete all device observations.
	/// This will fail if the current user is not the device's owner.
	/// The response will be delivered to the provided callback.
	static func deviceDeleteObservations(user: AuthenticatedUser,
																			 deviceId: DeviceURN,
																			 callback: @escaping (APIResponse<[EmptyReply]>) -> ()) {
		let request = DeviceAPI.GenericDeviceRequest(deviceId: deviceId)
		sendRequest(endpoint: .deviceDeleteObservations, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}
	/// Set the flags for the indicated device.
	/// Currently only the `locked` flag may be set.
	/// The response will be delivered to the provided callback.
	static func setDeviceFlags(user: AuthenticatedUser, deviceId: DeviceURN, newFlags: BiqDeviceFlag, callback: @escaping (APIResponse<EmptyReply>) -> ()) {
		let request = DeviceAPI.UpdateRequest(deviceId: deviceId, flags: newFlags)
		sendRequest(endpoint: .deviceUpdate, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}
	/// Set the limits for the device.
	/// The response will be delivered to the provided callback.
	static func setDeviceLimits(user: AuthenticatedUser, deviceId: DeviceURN, newLimits: [DeviceLimit], callback: @escaping (APIResponse<DeviceLimitsResponse>) -> ()) {
		let request = DeviceAPI.UpdateLimitsRequest(deviceId: deviceId, limits: newLimits)
		sendRequest(endpoint: .deviceSetLimits, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}

	static func recipeGet(user: AuthenticatedUser, uri: String, callback: @escaping (APIResponse<BiqRecipe>) -> ()) {
		let request = RecipeAPIRequest(uri: uri)
		sendRequest(endpoint: .recipeGet, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}

	static func recipeDel(user: AuthenticatedUser, uri: String, callback: @escaping (APIResponse<BiqRecipe>) -> ()) {
		let request = RecipeAPIRequest(uri: uri)
		sendRequest(endpoint: .recipeDel, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}

	static func recipeSet(user: AuthenticatedUser, recipe: BiqRecipe, callback: @escaping (APIResponse<RecipeAPIResponse>) -> ()) {
		sendRequest(endpoint: .recipeSet, parameters: RequestParameters(body: recipe)) {
			callback(APIResponse(from: $0))
		}
	}

	static func recipeTagGet(user: AuthenticatedUser, uri: String, callback: @escaping(APIResponse<[BiqRecipeTag]>) -> ()) {
		let request = RecipeAPIRequest(uri: uri)
		sendRequest(endpoint: .recipeTagGet, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}

	static func recipeTagAdd(user: AuthenticatedUser, tags: [BiqRecipeTag], callback: @escaping(APIResponse<RecipeAPIResponse>) -> ()) {
		sendRequest(endpoint: .recipeTagAdd, parameters: RequestParameters(body: tags)) {
			callback(APIResponse(from: $0))
		}
	}

	static func recipeTagDel(user: AuthenticatedUser, tags: [BiqRecipeTag], callback: @escaping(APIResponse<RecipeAPIResponse>) -> ()) {
		sendRequest(endpoint: .recipeTagDel, parameters: RequestParameters(body: tags)) {
			callback(APIResponse(from: $0))
		}
	}

	static func recipeMediaGet(user: AuthenticatedUser, uri: String, callback: @escaping(APIResponse<[BiqRecipeMedia]>) -> ()) {
		let request = RecipeAPIRequest(uri: uri)
		sendRequest(endpoint: .recipeMediaGet, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}

	static func recipeMediaAdd(user: AuthenticatedUser, tags: [BiqRecipeMedia], callback: @escaping(APIResponse<RecipeAPIResponse>) -> ()) {
		sendRequest(endpoint: .recipeMediaAdd, parameters: RequestParameters(body: tags)) {
			callback(APIResponse(from: $0))
		}
	}

	static func recipeMediaDel(user: AuthenticatedUser, tags: [BiqRecipeMedia], callback: @escaping(APIResponse<RecipeAPIResponse>) -> ()) {
		sendRequest(endpoint: .recipeMediaDel, parameters: RequestParameters(body: tags)) {
			callback(APIResponse(from: $0))
		}
	}

	static func recipeThresholdGet(user: AuthenticatedUser, uri: String, callback: @escaping(APIResponse<[BiqThreshold]>) -> ()) {
		let request = RecipeAPIRequest(uri: uri)
		sendRequest(endpoint: .recipeThresholdGet, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}

	static func recipeThresholdAdd(user: AuthenticatedUser, tags: [BiqThreshold], callback: @escaping(APIResponse<RecipeAPIResponse>) -> ()) {
		sendRequest(endpoint: .recipeThresholdAdd, parameters: RequestParameters(body: tags)) {
			callback(APIResponse(from: $0))
		}
	}

	static func recipeThresholdDel(user: AuthenticatedUser, tags: [BiqThreshold], callback: @escaping(APIResponse<RecipeAPIResponse>) -> ()) {
		sendRequest(endpoint: .recipeThresholdDel, parameters: RequestParameters(body: tags)) {
			callback(APIResponse(from: $0))
		}
	}
}

/// Device group related API calls.
public extension GroupAPI {
	/// List the groups belonging to the user.
	/// The response will be delivered to the provided callback.
	static func listGroups(user: AuthenticatedUser, callback: @escaping (APIResponse<[BiqDeviceGroup]>) -> ()) {
		sendRequest(endpoint: .groupList) {
			callback(APIResponse(from: $0))
		}
	}
	/// List the devices in the indicated group.
	/// The response will be delivered to the provided callback.
	static func listDevices(user: AuthenticatedUser, groupId: GroupId, callback: @escaping (APIResponse<[BiqDevice]>) -> ()) {
		let request = GroupAPI.ListDevicesRequest(groupId: groupId)
		sendRequest(endpoint: .groupDeviceList, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}
	/// Create a group with the given name.
	/// The response will be delivered to the provided callback.
	static func createGroup(user: AuthenticatedUser, groupName: String, callback: @escaping (APIResponse<BiqDeviceGroup>) -> ()) {
		let request = GroupAPI.CreateRequest(name: groupName)
		sendRequest(endpoint: .groupCreate, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}
	/// Rename the indicated group.
	/// The response will be delivered to the provided callback.
	static func renameGroup(user: AuthenticatedUser, groupId: GroupId, newName: String, callback: @escaping (APIResponse<EmptyReply>) -> ()) {
		let request = GroupAPI.UpdateRequest(groupId: groupId, name: newName)
		sendRequest(endpoint: .groupUpdate, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}
	/// Delete the indicated group.
	/// The response will be delivered to the provided callback.
	static func deleteGroup(user: AuthenticatedUser, groupId: GroupId, callback: @escaping (APIResponse<EmptyReply>) -> ()) {
		let request = GroupAPI.DeleteRequest(groupId: groupId)
		sendRequest(endpoint: .groupDelete, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}
	/// Add the device to the indicated group.
	/// The response will be delivered to the provided callback.
	static func addGroupDevice(user: AuthenticatedUser, groupId: GroupId, deviceId: DeviceURN, callback: @escaping (APIResponse<EmptyReply>) -> ()) {
		let request = GroupAPI.AddDeviceRequest(groupId: groupId, deviceId: deviceId)
		sendRequest(endpoint: .groupDeviceAdd, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}
	/// Remove the indicated device from the group.
	/// The response will be delivered to the provided callback.
	static func removeGroupDevice(user: AuthenticatedUser, groupId: GroupId, deviceId: DeviceURN, callback: @escaping (APIResponse<EmptyReply>) -> ()) {
		let request = GroupAPI.AddDeviceRequest(groupId: groupId, deviceId: deviceId)
		sendRequest(endpoint: .groupDeviceRemove, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}
}


