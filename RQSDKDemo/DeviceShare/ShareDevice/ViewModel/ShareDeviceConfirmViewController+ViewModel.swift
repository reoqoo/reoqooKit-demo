//
//  ShareDeviceConfirmViewController+ViewModel.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 13/6/2024.
//

import Foundation

extension ShareDeviceConfirmViewController {
    class ViewModel {

        enum Event {
            case idel
            case shareConfirmViewDidLoad
            case refreshQRCode
            case requestDeviceSituation
            case checkAccount(account: String, deviceId: String)
            case share2User(user: DeviceShare.GuestUser, deviceId: String)
        }

        enum Status {
            case idel
            case didFinishRequestRecentlyGuest(Result<[DeviceShare.GuestUser], Swift.Error>)
            case didFinishRequestDeviceShareSituation(Result<DeviceShare.DeviceShareSituation, Swift.Error>)
            /// 将要请求二维码
            case willRequestQRCode
            /// 完成请求二维码
            case didFinishRequestQRCode(Result<DeviceShare.ShareQRCodeItem, Swift.Error>)
            /// 查询用户
            case didCheckAccount(Result<[DeviceShare.GuestUser], Swift.Error>)
            /// 分享请求完成
            case didFinishShareRequest(Result<Void, Swift.Error>)
        }

        @Published var status: Status = .idel

        var anyCancellables: Set<AnyCancellable> = []
        var event: Event = .idel {
            didSet {
                switch self.event {
                case .idel:
                    break
                case .shareConfirmViewDidLoad:
                    self.requestRecentlyGuestList()
                    self.requestDeviceSituation()
                case .requestDeviceSituation:
                    self.requestDeviceSituation()
                case .refreshQRCode:
                    self.requestQRCode()
                case .checkAccount(let account, let deviceId):
                    self.checkAcount(account, deviceId: deviceId)
                case .share2User(let user, let deviceId):
                    self.share2User(user, deviceId: deviceId)
                }
            }
        }

        @Published var recentlyShareGuests: [DeviceShare.GuestUser] = []
        @DidSetPublished var deviceSharedSituation: DeviceShare.DeviceShareSituation?
        /// 最近刷新的二维码
        @Published var latestQRCodeItem: DeviceShare.ShareQRCodeItem?

        let deviceId: String
        init(deviceId: String) {
            self.deviceId = deviceId
        }

        /// 请求最近分享的用户信息列表
        func requestRecentlyGuestList() {
            DeviceShare.requestRecentlyGuestListPublisher().sink { completion in
                guard case let .failure(err) = completion else { return }
                self.status = .didFinishRequestRecentlyGuest(.failure(err))
            } receiveValue: { [weak self] users in
                self?.recentlyShareGuests = users
                self?.status = .didFinishRequestRecentlyGuest(.success(users))
            }.store(in: &self.anyCancellables)
        }

        /// 请求设备的分享情况
        func requestDeviceSituation() {
            DeviceShare.requestDeviceShareSituationPublisher(deviceId: self.deviceId).sink { [weak self] completion in
                guard case let .failure(err) = completion else { return }
                self?.status = .didFinishRequestDeviceShareSituation(.failure(err))
            } receiveValue: { [weak self] situation in
                self?.deviceSharedSituation = situation
                self?.status = .didFinishRequestDeviceShareSituation(.success(situation))
            }.store(in: &self.anyCancellables)
        }

        /// 请求分享二维码
        func requestQRCode() {
            self.status = .willRequestQRCode
            DeviceShare.requestQRCodePublisher(deviceId: self.deviceId).sink { [weak self] completion in
                guard case let .failure(err) = completion else { return }
                self?.status = .didFinishRequestQRCode(.failure(err))
            } receiveValue: { [weak self] item in
                self?.latestQRCodeItem = item
                self?.status = .didFinishRequestQRCode(.success(item))
            }.store(in: &self.anyCancellables)
        }

        /// 用户点击共享后, 先对输入的 account 进行查询
        /// 如果查询得到的用户只有一个, 直接发起分享请求
        /// 如果有多个, 弹出Alert让用户选择
        func checkAcount(_ account: String, deviceId: String) {
            DeviceShare.checkShareUserInfoPublisher(account: account, deviceId: deviceId).sink { [weak self] completion in
                guard case let .failure(err) = completion else { return }
                let reoqooErr = ReoqooError.generateFromOther(err, seriesOfReason: [ReoqooError.DeviceShareError.self]) ?? err
                self?.status = .didCheckAccount(.failure(reoqooErr))
            } receiveValue: { users in
                self.status = .didCheckAccount(.success(users))
            }.store(in: &self.anyCancellables)
        }

        // 发起分享请求
        func share2User(_ user: DeviceShare.GuestUser, deviceId: String) {
            DeviceShare.share2UserPublisher(deviceId: deviceId, userId: user.guestId).sink { [weak self] completion in
                guard case let .failure(err) = completion else { return }
                let reoqooErr = ReoqooError.generateFromOther(err, seriesOfReason: [ReoqooError.DeviceShareError.self]) ?? err
                self?.status = .didFinishShareRequest(.failure(reoqooErr))
            } receiveValue: { [weak self] in
                self?.status = .didFinishShareRequest(.success(()))
            }.store(in: &self.anyCancellables)
        }
    }
}
