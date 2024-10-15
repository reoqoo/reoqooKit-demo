//
//  DeviceDidSharedDetailViewController+ViewModel.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 17/6/2024.
//

import Foundation

extension ShareToManagedViewController {
    class ViewModel: ObservableObject {
        
        enum Status {
            case idel
            case willRequestSharedSituation
            case didFinishedRequestSharedSituation(Result<DeviceShare.DeviceShareSituation, Swift.Error>)
            case didFinishedRemoveGuest(Result<DeviceShare.DeviceShareSituation, Swift.Error>)
        }

        enum Event {
            case idel
            case removeGuest(guestId: String)
            case removeAllGuest
        }

        let deviceId: String

        init(deviceId: String) {
            self.deviceId = deviceId

            self.requestSharedSituation()
        }

        var anyCancellables: Set<AnyCancellable> = []

        @DidSetPublished var situation: DeviceShare.DeviceShareSituation?

        @Published var status: Status = .idel

        var event: Event = .idel {
            didSet {
                switch self.event {
                case let .removeGuest(guestId):
                    self.removeGuest(guestId: guestId)
                case .removeAllGuest:
                    self.removeGuest(guestId: nil)
                default: break
                }
            }
        }

        func requestSharedSituation() {
            self.status = .willRequestSharedSituation
            DeviceShare.requestDeviceShareSituationPublisher(deviceId: self.deviceId).sink { [weak self] completion in
                guard case let .failure(err) = completion else { return }
                self?.status = .didFinishedRequestSharedSituation(.failure(err))
            } receiveValue: { [weak self] situation in
                self?.situation = situation
                self?.status = .didFinishedRequestSharedSituation(.success(situation))
            }.store(in: &self.anyCancellables)
        }

        func removeGuest(guestId: String?) {
            let deviceId = self.deviceId
            DeviceShare.removeGuestPublisher(self.deviceId, guestId: guestId).sink { [weak self] completion in
                guard case let .failure(err) = completion else { return }
                let reoqooErr = ReoqooError.generateFromOther(err, seriesOfReason: [ReoqooError.DeviceShareError.self]) ?? err
                self?.status = .didFinishedRemoveGuest(.failure(reoqooErr))
            } receiveValue: { [weak self] _ in
                guard let situation = self?.situation else { return }
                if let guestId = guestId {
                    situation.guestList = situation.guestList.filter({ $0.guestId != guestId })
                }else{
                    situation.guestList = []
                }
                // 如果该设备下 guestList 为空, 修改 device.cloudStatus = 0, 表示没有发生分享
                let isGuestListEmpty = self?.situation?.guestList.isEmpty ?? true
                if isGuestListEmpty {
                    DeviceManager2.db_updateDevicesWithContext { _ in
                        guard let dev = DeviceManager2.fetchDevice(deviceId), let cloudStatus = dev.cloudStatus else { return }
                        // 将 bit1 位置为 0, 表示没有发生分享
                        dev.cloudStatus = cloudStatus & ~(1 << 1)
                    }
                }
                self?.situation = situation
                self?.status = .didFinishedRemoveGuest(.success(situation))
            }.store(in: &self.anyCancellables)
        }
    }
}
