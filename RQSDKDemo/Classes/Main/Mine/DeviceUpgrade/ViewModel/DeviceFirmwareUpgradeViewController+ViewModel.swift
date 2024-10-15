//
//  DeviceUpgradeViewController+ViewModel.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 7/10/2023.
//

import Foundation

extension DeviceFirmwareUpgradeViewController {
    class ViewModel {

        enum Status {
            case idle
            // 检查设备是否可更新操作 完成
            case didFinishCheckingDevicesUpgrade(Result<[TableViewCellItem], Swift.Error>)
            /// 设备开始更新
            case deviceDidStartUpgrade(deviceId: String)
            // 设备更新成功了
            case deviceFirmwareUpgradeSuccess(DeviceEntity)
            // 设备更新失败
            case deviceFirmwareUpgradeFailure(device: DeviceEntity, description: String)
        }

        enum Event {
            case startCheck
            case updateDeviceAtIndex(Int)
            case updateAll
        }

        @RxBehavioral var status: Status = .idle

        @RxBehavioral var tableViewDataSources: [TableViewCellItem] = []
        
        let disposeBag: DisposeBag = .init()

        var tasksObserverDisposeBag: DisposeBag = .init()

        init() {
            // 监听每个设备的升级状态
            FirmwareUpgradeCenter.shared.taskLatestStatusObservable
                // 防止挤兑发布
                .throttle(.milliseconds(200), scheduler: MainScheduler.asyncInstance)
                .skip(1)
                .subscribe(onNext: { [weak self] deviceId, status in
                    switch status {
                    case .success:
                        guard let device = DeviceManager2.fetchDevice(deviceId) else { return }
                        self?.status = .deviceFirmwareUpgradeSuccess(device)
                    case let .failure(_, description, _):
                        guard let device = DeviceManager2.fetchDevice(deviceId) else { return }
                        self?.status = .deviceFirmwareUpgradeFailure(device: device, description: description)
                    default:
                        break
                    }
                }).disposed(by: self.disposeBag)

            // 组建TableView 数据源, 仅限升级非升级成功的任务, 当 FirmwareUpgradeCenter.tasks 改变或任何任务状态改变都会触发此发布者
            FirmwareUpgradeCenter.shared.$tasks.flatMap {
                let obs = $0.map { task in
                    task.upgradeStatusObservable.map { _ in task }
                }
                return Observable.combineLatest(obs)
            }.map { (tasks: [FirmwareUpgradeTask]) in
                // 只显示非成功的任务, 按设备id排序
                tasks.filter({ !$0.upgradeStatus.isSuccess }).sorted(by: { $0.deviceId > $1.deviceId })
            }.subscribe(onNext: { [weak self] tasks in
                let items = tasks.map({ TableViewCellItem.init(task: $0, isExpanded: false) })
                self?.tableViewDataSources = items
                self?.status = .didFinishCheckingDevicesUpgrade(.success(items))
            }).disposed(by: self.tasksObserverDisposeBag)
        }

        func processEvent(_ event: Event) {
            switch event {
            case .startCheck:
                self.checkDevicesUpgrade()
            case let .updateDeviceAtIndex(idx):
                guard let task = self.tableViewDataSources[safe_: idx]?.task else { return }
                self.updateDeviceWithTask(task)
            case .updateAll:
                self.updateAll()
            }
        }
        
        /// 客户端检查设备是否有新版本, 组建 TableViewDataSource
        func checkDevicesUpgrade() {
            // 使 DeviceManager 更新版本信息
            DeviceManager2.shared.updateDevicesInfo()
        }

        // 发布者: 当前正在升级的设备们
        var updatingDevicesObservable: Observable<[FirmwareUpgradeTask]> = {
            FirmwareUpgradeCenter.shared.$tasks.map {
                $0.sorted(by: { $0.deviceId > $1.deviceId })
            }.flatMap { tasks in
                let obs = tasks.map {
                    Observable.combineLatest(Single.just($0).asObservable(), $0.upgradeStatusObservable)
                }
                return Observable.combineLatest(obs)
            }.map { x in
                x.filter { $0.1.isUpdating }.map { $0.0 }
            }
        }()

        // MARK: 设备升级
        /// 升级设备
        func updateDeviceWithTask(_ task: FirmwareUpgradeTask) {
            // 让设备开始升级 (步骤1)
            task.letDeviceConfirmUpgrade()
            self.status = .deviceDidStartUpgrade(deviceId: task.deviceId)
        }

        /// 升级全部设备
        func updateAll() {
            self.tableViewDataSources.forEach {
                self.updateDeviceWithTask($0.task)
            }
        }
    }
}
