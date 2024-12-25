//
//  DeviceShare+Api.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 17/6/2024.
//

import Foundation

struct DeviceShare {}

extension DeviceShare {

    /// 获取最近分享的用户们
    static func requestRecentlyGuestListPublisher() -> AnyPublisher<[DeviceShare.GuestUser], Swift.Error> {
        Future.init { promise in
            RQApi.Api.getRecentlyGuestList {
                let res = ResponseHandler.responseHandling(jsonStr: $0, error: $1)
                if case let .success(json) = res {
                    do {
                        let guests = try json["data"]["guestList"].decoded(as: [DeviceShare.GuestUser].self)
                        promise(.success(guests))
                    } catch let err {
                        promise(.failure(err))
                    }
                }
                if case let .failure(err) = res {
                    promise(.failure(err))
                }
            }
        }.eraseToAnyPublisher()
    }

    /// 获取设备分享详情
    static func requestDeviceShareSituationPublisher(deviceId: String) -> AnyPublisher<DeviceShare.DeviceShareSituation, Swift.Error> {
        Future.init { promise in
            RQApi.Api.getDeviceSharingSituation(withDeviceId: deviceId) {
                let res = ResponseHandler.responseHandling(jsonStr: $0, error: $1)
                if case let .success(json) = res {
                    do {
                        let situation = try json["data"].decoded(as: DeviceShare.DeviceShareSituation.self)
                        promise(.success(situation))
                    } catch let err {
                        promise(.failure(err))
                    }
                }
                if case let .failure(err) = res {
                    promise(.failure(err))
                }
            }
        }.eraseToAnyPublisher()
    }

    /// 请求二维码
    static func requestQRCodePublisher(deviceId: String) -> AnyPublisher<DeviceShare.ShareQRCodeItem, Swift.Error> {
        Future.init { promise in
            RQApi.Api.getShareQRCodeToken(withDeviceId: deviceId) {
                let res = ResponseHandler.responseHandling(jsonStr: $0, error: $1)
                if case let .success(json) = res {
                    do {
                        let situation = try json["data"].decoded(as: DeviceShare.ShareQRCodeItem.self)
                        promise(.success(situation))
                    } catch let err {
                        promise(.failure(err))
                    }
                }
                if case let .failure(err) = res {
                    promise(.failure(err))
                }
            }
        }.eraseToAnyPublisher()
    }

    /// 用户输入账号信息, 发起查询
    static func checkShareUserInfoPublisher(account: String, deviceId: String) -> AnyPublisher<[DeviceShare.GuestUser], Swift.Error> {
        Future.init { promise in
            RQApi.Api.getVisitorInfo(visitorAccountId: account, deviceId: deviceId) {
                let res = ResponseHandler.responseHandling(jsonStr: $0, error: $1)
                if case let .success(json) = res {
                    do {
                        let guests = try json["data"]["userList"].decoded(as: [DeviceShare.GuestUser].self)
                        promise(.success(guests))
                    } catch let err {
                        promise(.failure(err))
                    }
                }
                if case let .failure(err) = res {
                    promise(.failure(err))
                }
            }
        }.eraseToAnyPublisher()
    }

    /// 主人分享给访客接口
    static func share2UserPublisher(deviceId: String, userId: String) -> AnyPublisher<Void, Swift.Error> {
        Future.init { promise in
            RQApi.Api.shareDevice(deviceId, toVisitor: userId) {
                let res = ResponseHandler.responseHandling(jsonStr: $0, error: $1)
                if case .success = res {
                    promise(.success(()))
                }
                if case let .failure(err) = res {
                    promise(.failure(err))
                }
            }
        }.eraseToAnyPublisher()
    }

    /// 主人主动移除访客接口
    /// guestId 传 nil 表示移除所有访客
    static func removeGuestPublisher(_ deviceId: String, guestId: String?) -> AnyPublisher<Void, Swift.Error> {
        Future.init { promise in
            RQApi.Api.removeDeviceSharing(deviceId, visitor: guestId) {
                let result = ResponseHandler.responseHandling(jsonStr: $0, error: $1)
                switch result {
                case .failure(let error):
                    logDebug("[REQ] unshared device end, err: \(String(describing: error))")
                    promise(.failure(error))
                case .success(_):
                    promise(.success(()))
                }
            }
        }.eraseToAnyPublisher()
    }

    /// 获取设备主人信息
    static func requestOwnerInfoPublisher(deviceId: String) -> AnyPublisher<DeviceShare.OwnerInfo, Swift.Error> {
        Future.init { promise in
            RQApi.Api.getDeviceOwnerInfo(deviceId) {
                let result = ResponseHandler.responseDecode(to: DeviceShare.OwnerInfo.self, json: $0, error: $1)
                switch result {
                case .failure(let error):
                    promise(.failure(error))
                case .success(let ownerInfoRes):
                    promise(.success(ownerInfoRes))
                }
            }
        }.eraseToAnyPublisher()
    }

    /// 扫描分享二维码后, 接受该设备分享
    static func handleScanningInvitationPublisher(deviceId: String, invideToken: String, remarkName: String) -> AnyPublisher<DeviceShare.ShareConfirmItem, Swift.Error> {
        Future.init { promise in
            RQApi.Api.acceptQRCodeInvitation(invideToken, remarkName: remarkName) {
                //如果是超出限制的错误，则把限制数量传递出去（当成功处理）
                let result = ResponseHandler.responseDecode(to: DeviceShare.ShareConfirmItem.self, json: $0, error: $1, successCode: [ReoqooError.DeviceShareError.deviceGuestNumLimit.rawValue])
                promise(result)
            }
        }.eraseToAnyPublisher()
    }
    
    /// 获取分享邀请信息
    static func requestInvitationInfoPublisher(inviteToken: String, deviceId: String) -> AnyPublisher<DeviceShare.ShareInvitationInfo, Swift.Error> {
        Future.init { promise in
            RQApi.Api.getQRCodeInvitationInfo(inviteToken, deviceId: deviceId) {
                let result = ResponseHandler.responseDecode(to: DeviceShare.ShareInvitationInfo.self, json: $0, error: $1)
                promise(result)
            }
        }.eraseToAnyPublisher()
    }

    /// 用户收到分享消息后, 点击确认接受分享
    static func confirmInvitationPublisher(inviteToken: String, remarkName: String) -> AnyPublisher<DeviceShare.ShareConfirmItem, Swift.Error> {
        Future.init { promise in
            RQApi.Api.confirmSharing(inviteToken, remarkName: remarkName) {
                let result = ResponseHandler.responseDecode(to: DeviceShare.ShareConfirmItem.self, json: $0, error: $1)
                promise(result)
            }
        }.eraseToAnyPublisher()
    }
}
