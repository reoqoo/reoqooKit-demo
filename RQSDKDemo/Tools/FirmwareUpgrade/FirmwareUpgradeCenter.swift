//
//  FirmwareUpgradeCenter.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 11/10/2023.
//

import Foundation

/// 固件升级管理器
/// 设备升级任务生命周期:
/// - 由 self.tasks 管理
/// - 在 startMointoringDevice() 方法调用后, 对 DeviceManager.share.$deviceList 中的 "设备新版本" 进行监听
/// - 如果某设备有新版本, 尝试从 UserDefaults 中取出相关任务插入到 self.tasks 中, 如 UserDefaults没有, 就新建任务
/// - FirmwareUpgradeCenter 监听 app willResignActive 事件, 当 app 要进入后台, 就对 self.tasks 中的任务进行持久化操作
class FirmwareUpgradeCenter {

    static let shared: FirmwareUpgradeCenter = .init()
    
    /// 任务集合
    @RxBehavioral var tasks: [FirmwareUpgradeTask] = []

    typealias TaskUpgradeStatusObservableResult = (deviceId: String, status: FirmwareUpgradeTask.FirmwareUpgradeStatus)
    /// 任务们的最新执行状态发布者
    var taskLatestStatusObservable: RxSwift.PublishSubject<TaskUpgradeStatusObservableResult> = .init()

    /// 定时器 disposeBag
    private var timerDisposeBag: DisposeBag?

    private let disposeBag: DisposeBag = .init()

    private init() {
        UIApplication.rx.didEnterBackground.bind { [weak self] _ in
            // 从 self.tasks 中筛选出已经被干掉的设备的任务对应的设备id
//            let deviceIds = DeviceManager2.shared.devices.map({ $0.deviceId })
//            let targetDeviceIds = self?.tasks.reduce(into: [String](), { partialResult, task in
//                if !(deviceIds.contains(task.deviceId)) {
//                    partialResult.append(task.deviceId)
//                }
//            })
//            logInfo("[DeviceFirmwareUpgrade] App即将进入后台, 删除已被删掉的设备对应的升级任务(兜底方案): ", targetDeviceIds as Any)
//            self?.tasks.removeAll {
//                return targetDeviceIds?.contains($0.deviceId) ?? false
//            }
            // 当 APP 即将 didEnterBackground 了, 将 tasks 存到本地
            self?.tasks.save()
        }.disposed(by: self.disposeBag)
        
        // 监听 User 登出, 清空 tasks
        AccountCenter.shared.$currentUser.subscribe(on: MainScheduler.asyncInstance).bind { [weak self] user in
            if let _ = user {
                // user 非 nil, 赋值 self.tasks
                self?.tasks = FirmwareUpgradeTask.allTaskRecords()
            }else{
                // 当 User 为 nil, 表示 user 登出
                self?.tasks = []
                self?.timerDisposeBag = .init()
            }
        }.disposed(by: self.disposeBag)
        
        // 监听任务状态
        self.observerTaskStatus()
    }

    /// 开始对 DeviceManager.deviceList 进行监听, 以组建升级任务
    public func observerDeviceList() {

        // 对设备新版本信息进行监听, 以组建任务
        DeviceManager2.shared.generateDevicesObservable(keyPaths: [\.deviceId, \.newVersionInfo])
            .compactMap({ $0?.filter({ $0.role == .master }) })
            .throttle(.milliseconds(200), scheduler: MainScheduler.asyncInstance)
            .flatMap { devices in
                let obs = devices.map({ dev in
                    let deviceId = dev.deviceId
                    let swVersion = dev.swVersion
                    let newVersion = dev.newVersionInfo
                    return Observable.just((deviceId, swVersion, newVersion))
                })
                return Observable.merge(obs)
            }.subscribe(onNext: { [weak self] res in   // [(String, String, NewVersionInfo)]
                let deviceId = res.0
                let originalVersion = res.1
                let newVersionInfo = res.2
                self?.generateUpgradeTaskIfNeed(deviceId: deviceId, originalVersion: originalVersion, newVersionInfo: newVersionInfo)
            }).disposed(by: self.disposeBag)
        
        // 对设备删除事件进行监听, 设备被删除后, 移除相关任务
        DeviceManager2.shared.devicesHasBeenDeletedOperationResultObservable.bind { [weak self] in
            guard case let .success(ghosts) = $0 else { return }
            for devGhost in ghosts {
                if devGhost.role != .master { return }
                self?.tasks.removeAll(where: { $0.deviceId == devGhost.deviceId })
            }
        }.disposed(by: self.disposeBag)

        // 对设备上线状态进行监听, 将状态分发给 FirmUpgradeTask, 使其发起轮询 versionCheckPolling(_)
        DeviceManager2.shared.generateDevicesObservable(keyPaths: [\.status])
            .throttle(.milliseconds(100), scheduler: MainScheduler.asyncInstance)
            .debounce(.milliseconds(100), scheduler: MainScheduler.asyncInstance)
            .subscribe { [weak self] results in
                results?.toArray().forEach({ dev in
                    guard dev.status == .online else { return }
                    guard let task = self?.tasks.filter({ $0.deviceId == dev.deviceId }).first else { return }
                    task.deviceDidOnline()
                })
            }.disposed(by: self.disposeBag)
    }

    /// 生成任务
    /// - Parameters:
    ///   - deviceId: 设备id
    ///   - originalVersion: 原始版本
    ///   - newVersionInfo: 新版本信息
    private func generateUpgradeTaskIfNeed(deviceId: String, originalVersion: String?, newVersionInfo: DeviceNewVersionInfo?) {
        logInfo("[DeviceFirmwareUpgrade] 尝试插入新任务, deviceId: \(deviceId), originalVersion: \(String(describing: originalVersion)), newVersionInfo: \(String(describing: newVersionInfo))")
        guard let originalVersion = originalVersion else { return }

        // 遍历 self.tasks 中的版本, 检查是否有未成功的 task 的 targetVersion < originalVersion, 将这些 tasks 定义为升级成功
        self.tasks.forEach {
            if $0.deviceId == deviceId && !$0.upgradeStatus.isSuccess && $0.targetVersion.compareAsVersionString(originalVersion) != .newer {
                logInfo("[DeviceFirmwareUpgrade] deviceId: \(deviceId), 升级任务目标版本(\($0.targetVersion))低于设备当前版本(\(originalVersion)), 故将该旧任务标记为成功")
                $0.signAsSuccess()
            }
        }

        guard let newVersionInfo = newVersionInfo, let newVersion = newVersionInfo.version else {
            logInfo("[DeviceFirmwareUpgrade] 尝试插入新任务, 新版本信息为空, 故取消操作, deviceId: \(deviceId)")
            // 由于newversion为空, 即移除任务列表中对应的设备的所有任务
            self.tasks.removeAll { $0.deviceId == deviceId }
            return
        }

        // 检查 self.tasks 是否已经有 taskId 相同的任务, 如果有就不插入了
        if self.tasks.contains(where: { $0.taskId == FirmwareUpgradeTask.createTaskId(deviceId: deviceId, originalVersion: originalVersion, targetVersion: newVersion) }) {
            logInfo("[DeviceFirmwareUpgrade] 尝试插入新任务, deviceId: \(deviceId), 任务列表中已有相同任务, 无需插入新任务")
            return
        }

        // 检查是否存在 deviceId 相同的任务, 如果有, 先将旧的任务标记为成功 (这是循环升级的情况. 由于循环升级永远不会被标记为成功, 如果不做这一操作, 会导致列表中显示属于同一个设备的两个任务)
        self.tasks.forEach {
            if $0.deviceId != deviceId { return }
            logInfo("[DeviceFirmwareUpgrade] 尝试插入新任务, deviceId: \(deviceId), 任务列表中存在设备id相同的旧任务, 先将其标记为成功. 旧任务: \($0.targetVersion)")
            $0.signAsSuccess()
        }

        // 插入新任务
        logInfo("[DeviceFirmwareUpgrade] 尝试插入新任务, deviceId: \(deviceId), 插入新任务", newVersion)
        let firmwareUpgradeTask: FirmwareUpgradeTask = .init(deviceId: deviceId, originalVersion: originalVersion, targetVersion: newVersion)
        self.tasks.append(firmwareUpgradeTask)
    }
    
    /// 监听任务状态
    private func observerTaskStatus() {
        self.$tasks.flatMap {
            // 组建任务状态发布者集合 [Observable<FirmUpgradeTask>]
            let statusObservbles = $0.map({ t in
                return t.upgradeStatusObservable.map({ _ in t })
            })
            return Observable.merge(statusObservbles)
        }
        .subscribe(on: MainScheduler.asyncInstance)
        .subscribe(onNext: { [weak self] (t: FirmwareUpgradeTask) in
            // 如果任务成功了, 将对应的 Device 模型中的 newVersionInfo 置空
            if case .success = t.upgradeStatus {
                DeviceManager2.db_updateDevicesWithContext { _ in
                    let dev = DeviceManager2.fetchDevice(t.deviceId)
                    dev?.newVersionInfo = nil
                }
                // 任务成功后将该任务从任务列表中移除, 否则任务列表中有重复的设备任务的话, 会使进度派发有误
                self?.tasks.removeAll(where: { $0.deviceId == t.deviceId })
            }
            // 检查任务列表是否还有任务正在进行, 如无任务进行中, 关闭timer
            if (self?.tasks.filter { $0.upgradeStatus.isUpdating } ?? []).isEmpty {
                self?.timerDisposeBag = nil
            }else{
                self?.launchTimerTigger()
            }
            // 触发发布者
            self?.taskLatestStatusObservable.onNext((t.deviceId, t.upgradeStatus))
        }, onCompleted: {
            
        }).disposed(by: self.disposeBag)
    }

    /// 启动定时器对任务发起 timerTigger 操作
    private func launchTimerTigger() {
        if let _ = self.timerDisposeBag { return }
        let disposeBag: DisposeBag = .init()
        self.timerDisposeBag = disposeBag
        // 启动定时器
        Observable<Int>.timer(.seconds(0), period: .seconds(1), scheduler: MainScheduler.asyncInstance).bind { [weak self] i in
            self?.tasks.forEach({ $0.timerTigger() })
        }.disposed(by: disposeBag)
    }

    /// 对 self.tasks 中的任务 分发升级进度
    public func handOutProgress(deviceId: String, progress: Int) {
        self.tasks.filter({ $0.deviceId == deviceId }).first?.firmwareUpgradeProgressDidChanged(Double(progress))
    }
    
    /// 告知任务检查操作完成, 可以执行升级了
    public func didConfirmNewVersion(deviceId: String) {
        self.tasks.filter({ $0.deviceId == deviceId }).first?.newFirmwareAlready()
    }
    
}
