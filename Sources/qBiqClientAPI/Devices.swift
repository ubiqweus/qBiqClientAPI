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

#if DEBUG // this
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
	
	case deviceList = "/device/list"
	case deviceRegister = "/device/register"
	case deviceUnregister = "/device/unregister"
	case deviceInfo = "/device/info"
	case deviceShare = "/device/share"
	case deviceShareToken = "/device/share/token"
	case deviceUnshare = "/device/unshare"
	case deviceUpdate = "/device/update"
	case deviceObservations = "/device/obs"
	case deviceDeleteObservations = "/device/obs/delete"
	case deviceSetLimits = "/device/limits"
	
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
		case .deviceList:
			return false
		case .deviceRegister:
			return true
		case .deviceUnregister:
			return true
		case .deviceUpdate:
			return true
		case .deviceObservations:
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
		}
	}
}

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

public extension DeviceAPI {
	// all devices the user has available
	// any device may ultimately belong to other users
	static func listDevices(user: AuthenticatedUser, callback: @escaping (APIResponse<[DeviceAPI.ListDevicesResponseItem]>) -> ()) {
		sendRequest(endpoint: .deviceList) { callback(APIResponse(from: $0)) }
	}
	static func renameDevice(user: AuthenticatedUser, deviceId: DeviceURN, newName: String, callback: @escaping (APIResponse<EmptyReply>) -> ()) {
		let request = DeviceAPI.UpdateRequest(deviceId: deviceId, name: newName)
		sendRequest(endpoint: .deviceUpdate, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}
	static func registerDevice(user: AuthenticatedUser, deviceId: DeviceURN, callback: @escaping (APIResponse<BiqDevice>) -> ()) {
		let request = DeviceAPI.RegisterRequest(deviceId: deviceId)
		sendRequest(endpoint: .deviceRegister, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}
	static func unregisterDevice(user: AuthenticatedUser, deviceId: DeviceURN, callback: @escaping (APIResponse<EmptyReply>) -> ()) {
		let request = DeviceAPI.RegisterRequest(deviceId: deviceId)
		sendRequest(endpoint: .deviceUnregister, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}
	static func shareDevice(user: AuthenticatedUser, deviceId: DeviceURN, shareToken: UUID?, callback: @escaping (APIResponse<BiqDevice>) -> ()) {
		let request = DeviceAPI.ShareRequest(deviceId: deviceId, token: shareToken)
		sendRequest(endpoint: .deviceShare, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}
	static func unshareDevice(user: AuthenticatedUser, deviceId: DeviceURN, callback: @escaping (APIResponse<EmptyReply>) -> ()) {
		let request = DeviceAPI.ShareRequest(deviceId: deviceId)
		sendRequest(endpoint: .deviceUnshare, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}
	static func getShareDeviceToken(user: AuthenticatedUser, deviceId: DeviceURN, callback: @escaping (APIResponse<ShareTokenResponse>) -> ()) {
		let request = DeviceAPI.ShareTokenRequest(deviceId: deviceId)
		sendRequest(endpoint: .deviceShareToken, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}
	static func deviceInfo(user: AuthenticatedUser, deviceId: DeviceURN, callback: @escaping (APIResponse<BiqDevice>) -> ()) {
		let request = DeviceAPI.ShareRequest(deviceId: deviceId)
		sendRequest(endpoint: .deviceInfo, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}
	static func deviceObservations(user: AuthenticatedUser,
								   deviceId: DeviceURN,
								   interval: DeviceAPI.ObsRequest.Interval, callback: @escaping (APIResponse<[ObsDatabase.BiqObservation]>) -> ()) {
		let request = DeviceAPI.ObsRequest(deviceId: deviceId, interval: interval)
		sendRequest(endpoint: .deviceObservations, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}
	static func deviceDeleteObservations(user: AuthenticatedUser,
										 deviceId: DeviceURN,
										 callback: @escaping (APIResponse<[EmptyReply]>) -> ()) {
		let request = DeviceAPI.GenericDeviceRequest(deviceId: deviceId)
		sendRequest(endpoint: .deviceDeleteObservations, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}
	static func setDeviceFlags(user: AuthenticatedUser, deviceId: DeviceURN, newFlags: BiqDeviceFlag, callback: @escaping (APIResponse<EmptyReply>) -> ()) {
		let request = DeviceAPI.UpdateRequest(deviceId: deviceId, flags: newFlags)
		sendRequest(endpoint: .deviceUpdate, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}
	static func setDeviceLimits(user: AuthenticatedUser, deviceId: DeviceURN, newLimits: [DeviceLimit], callback: @escaping (APIResponse<DeviceLimitsResponse>) -> ()) {
		let request = DeviceAPI.UpdateLimitsRequest(deviceId: deviceId, limits: newLimits)
		sendRequest(endpoint: .deviceSetLimits, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}
}

public extension GroupAPI {
	static func listGroups(user: AuthenticatedUser, callback: @escaping (APIResponse<[BiqDeviceGroup]>) -> ()) {
		sendRequest(endpoint: .groupList) {
			callback(APIResponse(from: $0))
		}
	}
	static func listDevices(user: AuthenticatedUser, groupId: Id, callback: @escaping (APIResponse<[BiqDevice]>) -> ()) {
		let request = GroupAPI.ListDevicesRequest(groupId: groupId)
		sendRequest(endpoint: .groupDeviceList, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}
	static func createGroup(user: AuthenticatedUser, groupName: String, callback: @escaping (APIResponse<BiqDeviceGroup>) -> ()) {
		let request = GroupAPI.CreateRequest(name: groupName)
		sendRequest(endpoint: .groupCreate, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}
	static func renameGroup(user: AuthenticatedUser, groupId: Id, newName: String, callback: @escaping (APIResponse<EmptyReply>) -> ()) {
		let request = GroupAPI.UpdateRequest(groupId: groupId, name: newName)
		sendRequest(endpoint: .groupUpdate, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}
	static func deleteGroup(user: AuthenticatedUser, groupId: Id, callback: @escaping (APIResponse<EmptyReply>) -> ()) {
		let request = GroupAPI.DeleteRequest(groupId: groupId)
		sendRequest(endpoint: .groupDelete, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}
	static func addGroupDevice(user: AuthenticatedUser, groupId: Id, deviceId: DeviceURN, callback: @escaping (APIResponse<EmptyReply>) -> ()) {
		let request = GroupAPI.AddDeviceRequest(groupId: groupId, deviceId: deviceId)
		sendRequest(endpoint: .groupDeviceAdd, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}
	static func removeGroupDevice(user: AuthenticatedUser, groupId: Id, deviceId: DeviceURN, callback: @escaping (APIResponse<EmptyReply>) -> ()) {
		let request = GroupAPI.AddDeviceRequest(groupId: groupId, deviceId: deviceId)
		sendRequest(endpoint: .groupDeviceRemove, parameters: RequestParameters(body: request)) {
			callback(APIResponse(from: $0))
		}
	}
}

