//
//  ShareFromManagedViewController+ViewModel.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 17/6/2024.
//

import Foundation

extension ShareFromManagedViewController {
    class ViewModel {

        enum Status {
            case idel
            case deleteDeviceWithCompletion(result: Result<String, Swift.Error>)
        }

        enum Event {
            case idel
            case deleteDevice
        }

        @Published var status: Status = .idel
        var event: Event = .idel {
            didSet {
                switch self.event {
                case .deleteDevice:
                    self.deleteDevice()
                default: break
                }
            }
        }

        @Published var ownerInfo: DeviceShare.OwnerInfo?

        var anyCancellables: Set<AnyCancellable> = []
        let disposeBag: DisposeBag = .init()

        let deviceId: String
        init(deviceId: String) {
            self.deviceId = deviceId
            self.requestOwnerInfo()
        }

        func requestOwnerInfo() {
            DeviceShare.requestOwnerInfoPublisher(deviceId: self.deviceId).sink { completion in
                guard case let .failure(err) = completion else { return }
            } receiveValue: { [weak self] ownerInfo in
                self?.ownerInfo = ownerInfo
            }.store(in: &self.anyCancellables)
        }

        func deleteDevice() {
            guard let device = DeviceManager2.fetchDevice(self.deviceId) else { return }
            DeviceManager2.shared.deleteDeviceAndStoreObservable(device: device, deleteFrom: .app).subscribe { [weak self] devGhost in
                self?.status = .deleteDeviceWithCompletion(result: .success(devGhost.deviceId))
            } onFailure: { [weak self] err in
                self?.status = .deleteDeviceWithCompletion(result: .failure(err))
            }.disposed(by: self.disposeBag)
        }
    }
}
