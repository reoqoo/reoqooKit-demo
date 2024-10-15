//
//  ShareManagedViewController+ViewModel.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 13/6/2024.
//

import Foundation

extension ShareManagedViewController {
    class ViewModel {

        enum Event {
            case idle
            case refreshDeviceList
        }

        enum State {
            case idle
            case refreshing
            case refreshDeviceListResult(Result<Void, Swift.Error>)
        }

        var event: Event = .idle {
            didSet {
                switch event {
                case .idle:
                    break
                case .refreshDeviceList:
                    // 主动发起请求设备, 否则无法准确获取设备是否被分享的情况
                    self.state = .refreshing
                    DeviceManager2.shared.requestDevicesObservable().subscribe { [weak self] devs in
                        self?.state = .refreshDeviceListResult(.success(()))
                    } onError: { [weak self] err in
                        self?.state = .refreshDeviceListResult(.failure(err))
                    }.disposed(by: self.disposeBag)
                }
            }
        }

        @DidSetPublished var state: State = .idle

        /// 分享出去的设备
        @DidSetPublished var sharedToDevices: [DeviceEntity] = []

        /// 接受分享的设备
        @DidSetPublished var sharedFromDevices: [DeviceEntity] = []

        typealias TableViewSection = (title: String, devices: [DeviceEntity])
        @DidSetPublished var tableViewDataSources: [TableViewSection] = []
        
        var disposeBag: DisposeBag = .init()
        var anyCancellables: Set<AnyCancellable> = []

        init() {
            // 对 DeviceManager 进行监听
            DeviceManager2.shared.generateDevicesObservable(keyPaths: [\.role, \.cloudStatus]).subscribe { [weak self] res in
                guard let arr = res?.toArray() else { return }
                self?.sharedToDevices = arr.filter({ $0.role == .master && $0.hasShared })
                self?.sharedFromDevices = arr.filter({ $0.role == .shared })
            }.disposed(by: self.disposeBag)

            Publishers.CombineLatest(self.$sharedToDevices, self.$sharedFromDevices).sink { [weak self] shareTo, shareFrom in
                let sections = [(String.localization.localized("AA0178", note: "分享的设备"), shareTo), (String.localization.localized("AA0179", note: "来自分享的设备"), shareFrom)]
                self?.tableViewDataSources = sections.filter({ !$1.isEmpty })
            }.store(in: &self.anyCancellables)
        }
    }
}
