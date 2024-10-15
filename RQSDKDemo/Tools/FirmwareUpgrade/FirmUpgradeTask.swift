//
//  FirmUpgradeTask.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 11/10/2023.
//

import Foundation

extension FirmwareUpgradeTask {
    /// 对固件升级任务的状态描述
    enum FirmwareUpgradeStatus: Codable, Equatable {
        // 升级任务未开始
        case idle
        // 设备(主动)检查新版本 (此操作视为任务开始的第一步)
        case checkingNewVersion
        // 客户端接收到 `设备主动检查新版本` 动作的结果
        case didConfirmNewVersion
        // 设备发送了更新请求 (step 2)
        case sendingUpdateRequest
        // 更新中
        case updating(Double)
        // 更新成功
        case success(atTime: TimeInterval)
        // 更新失败 (由于要写本地, 所以仅记录错误码和错误描述) didPresent: 记录是否已向用户展示过此状态
        case failure(errorCode: Int, errorDescription: String, atTime: TimeInterval)

        var isUpdating: Bool {
            switch self {
            case .idle, .success, .failure:
                return false
            case .checkingNewVersion, .didConfirmNewVersion, .sendingUpdateRequest, .updating(_):
                return true
            }
        }

        var isSuccess: Bool {
            switch self {
            case .success:
                return true
            default:
                return false
            }
        }

        var isFailure: Bool {
            switch self {
            case .failure:
                return true
            default:
                return false
            }
        }
    }
}

/// 固件升级任务
class FirmwareUpgradeTask: Codable {

    /// 由于要存 UserDefaults , 所以需要 userId 作为关联键
    let userId: String
    /// 设备id
    let deviceId: String
    /// 任务id
    let taskId: String
    /// 任务创建时间
    let createTime: TimeInterval
    /// 任务开始时间
    var beginTime: TimeInterval?
    /// 任务结束 (成功/失败) 时间
    var completeTime: TimeInterval?
    /// 即将要升级到的目标版本号, 3段式, 从查询新版本接口获取
    let targetVersion: String
    /// 原始版本号, 3段式, 创建时通过 Device 对象的 swVersion 属性赋值
    let originalVersion: String
    
    /// 轮询超时时长
#if DEBUG
    static let pollingTimeOutInterval: Double = 180
#else
    static let pollingTimeOutInterval: Double = 600
#endif

    /// lazy 是为了避免参与 encode / decode 操作
    private lazy var disposeBag: DisposeBag = .init()

    /// 轮询版本 Disposable, 为了保证同一时间下只有一个版本查询请求正在被处理
    private lazy var pollingDisposable: Disposable? = nil

    /// 更新状态`发布者`, 供外部监听
    public lazy var upgradeStatusObservable: RxSwift.BehaviorSubject<FirmwareUpgradeStatus> = .init(value: self.upgradeStatus)

    /// 升级状态
    private(set) var upgradeStatus: FirmwareUpgradeStatus = .idle {
        didSet {
            // 当状态被赋值为 .success / .failure, 执行持久化操作
            switch self.upgradeStatus {
            case .checkingNewVersion:
                // 赋值任务开始时间
                self.beginTime = Date().timeIntervalSince1970
            case let .success(atTime):
                self.completeTime = atTime
                logInfo("[DeviceFirmwareUpgrade] 设备(\(self.deviceId)) 升级成功")
            case let .failure(code, description, atTime):
                self.completeTime = atTime
                logInfo("[DeviceFirmwareUpgrade] 设备(\(self.deviceId)) 升级失败, code: \(code) description: \(description)")
            default:
                break
            }
            // Observable 发送事件
            self.upgradeStatusObservable.onNext(self.upgradeStatus)
        }
    }

    static func createTaskId(deviceId: String, originalVersion: String, targetVersion: String) -> String {
        [deviceId, originalVersion, targetVersion].joined(separator: "/").md5
    }

    init(deviceId: String, originalVersion: String, targetVersion: String) {
        self.taskId = Self.createTaskId(deviceId: deviceId, originalVersion: originalVersion, targetVersion: targetVersion)
        self.createTime = Date().timeIntervalSince1970
        self.deviceId = deviceId
        self.originalVersion = originalVersion
        self.targetVersion = targetVersion
        self.userId = AccountCenter.shared.currentUser?.basicInfo.userId ?? ""
    }

    /// iotVideo IVMessageDelegate 发出的更新进度状态, 通知到此处, 以影响 self.upgradeStatus 属性
    fileprivate func updateProgressChange(_ progress: Double) {
        // 分析 IVMessageDelegate 发来的更新进度
        // 正数为进度
        if progress >= 0 {
            self.upgradeStatus = .updating(progress)
        }
        // >= 100 为成功
        if progress >= 100 {
            self.upgradeStatus = .success(atTime: Date().timeIntervalSince1970)
        }
        // 负数为错误
        if progress < 0 {
            let code = Int(progress)
            // 组装 error
            let reason = ReoqooError.DeviceFirmwareUpgradeErrorReason(rawValue: code) ?? .other
            logInfo("[DeviceFirmwareUpgrade] 设备升级失败: deviceId = \(deviceId), code = \(code), \(reason.description)")
            self.upgradeStatus = .failure(errorCode: ReoqooError.deviceFirmwareUpgradeError(reason).errorCode, errorDescription: ReoqooError.deviceFirmwareUpgradeError(reason).localizedDescription, atTime: Date().timeIntervalSince1970)
        }
    }

    /// 让设备(主动)检查是否有新版本可升级
    /// 此操作被定义为开始更新操作的第一步
    public func letDeviceConfirmUpgrade() {
        if self.upgradeStatus.isUpdating { return }
        self.letDeviceConfirmUpgradeObservable().subscribe().disposed(by: self.disposeBag)
    }

    /// 发起升级请求
    private func letDeviceBeginUpgrade() {
        self.letDeviceBeginUpgradeObservable().subscribe().disposed(by: self.disposeBag)
    }

    /// 让设备检查新版本是否可升级
    /// - 区别于 `Device.checkNewVersionInfo()` 方法, 此方法是向设备发送命令, 让设备自己去服务器查新版本是否可升级
    private func letDeviceConfirmUpgradeObservable() -> Single<Void> {
        let deviceId = self.deviceId
        let obs = Single<Void>.create { observer in
            RQCore.Agent.shared.ivDevMgr.searchNewestOtaVersion(of: deviceId) { error in
                if let error {
                    observer(.failure(error))
                }else{
                    observer(.success(()))
                }
            }
            return Disposables.create()
        }.do(onSubscribe: { [weak self] in
            // 开始了订阅(发送请求开始)
            logInfo("[DeviceFirmwareUpgrade]: \(deviceId) 向设备发送检查版本指令(固件升级第一步)")
            // 修改任务状态为 "正在检查新版本"
            self?.upgradeStatus = .checkingNewVersion
        })
        return self.catchUpgradeRequestObservableErrorAndDo(obs)
    }

    /// 让设备开始升级 (向设备发送升级指令)
    private func letDeviceBeginUpgradeObservable() -> Single<Void> {
        let deviceId = self.deviceId
        let obs = Single<Void>.create { observer in
            RQCore.Agent.shared.ivDevMgr.performUpdate(of: deviceId) { error in
                if let error {
                    observer(.failure(error))
                }else{
                    observer(.success(()))
                }
            }
            return Disposables.create()
        }.do(onSubscribe: { [weak self] in
            // 开始了订阅(发送请求开始)
            logInfo("[DeviceFirmwareUpgrade]: \(deviceId) 向设备发送升级指令")
            // 修改任务状态为 "正在发送更新请求"
            self?.upgradeStatus = .sendingUpdateRequest
        })
        return self.catchUpgradeRequestObservableErrorAndDo(obs)
    }

    /// 检查版本发布者
    private func checkVersionObservable() -> Single<String> {
        let deviceId = self.deviceId
        return Single.create { observer in
            RQCore.Agent.shared.ivDevMgr.getSoftwareVersion(of: deviceId) { swVer, error in
                if let err = error {
                    observer(.failure(err))
                }else{
                    observer(.success(swVer))
                }
            }
            return Disposables.create()
        }
    }

    /// 针对上面两个发布者 (func letDeviceBeginUpgradeObservable(), func checkVersionObservable), 为它们增加操作符, 对错误做拦截, 以及对结果做干预
    private func catchUpgradeRequestObservableErrorAndDo(_ observable: Single<Void>) -> Single<Void> {
        observable.catch { err in
            // 错误转换
            if (err as NSError).code == IVASrvErr.dst_error_relation.rawValue || (err as NSError).code == IVTermErr._msg_send_peer_timeout.rawValue {
                return Single.error(ReoqooError.deviceFirmwareUpgradeError(.networkError))
            }
            else if (err as NSError).code == IVASrvErr.dst_offline.rawValue {
                return Single.error(ReoqooError.deviceFirmwareUpgradeError(.deviceOffline))
            }
            if (err as NSError).code == IVMessageError.duplicate.rawValue {
                return Single.error(ReoqooError.deviceFirmwareUpgradeError(.operationDuplicate))
            }
            // 未知错误, 由下游直接打印
            return Single.error(err)
        }.do(onError: { [weak self] err in
            logInfo("[DeviceFirmwareUpgrade] 发送新版本查询指令/升级指令失败", "deviceId = \(String(describing: self?.deviceId))", err)
            // 如遇错误, 更新 任务状态
            self?.upgradeStatus = .failure(errorCode: (err as NSError).code, errorDescription: err.localizedDescription, atTime: Date().timeIntervalSince1970)
        })
    }
    
    /// 将任务标记为成功
    public func signAsSuccess() {
        self.upgradeStatus = .success(atTime: self.createTime + 300)
    }

    /// 当 Iotvideo 接收到 "Action._otaVersion" 后, 触发到此方法, 更新 firmwareUpgradeTask.upgradeStatus 的状态
    public func newFirmwareAlready() {
        logInfo("[DeviceFirmwareUpgrade] newFirmwareAlready 设备(主动)检查到新版本", "deviceId = \(self.deviceId)")
        // 如果当前状态正确, 退出
        if self.upgradeStatus != .checkingNewVersion { return }
        self.upgradeStatus = .didConfirmNewVersion
        self.letDeviceBeginUpgrade()
    }

    /// 当 Iotvideo 接收到 "Action._otaUpgrade" 后, 触发到此方法, 更新 firmwareUpgradeTask.upgradeStatus 的状态
    public func firmwareUpgradeProgressDidChanged(_ progress: Double) {
        logInfo("[DeviceFirmwareUpgrade] firmwareUpgradeProgressDidChanged", "deviceId = \(self.deviceId)", progress)
        self.updateProgressChange(progress)
    }

    /// 当设备上线时调用
    /// 由 FirmwareUpgradeCenter 告知
    public func deviceDidOnline() {
        // 如果不是正在进行升级操作, return
        if !self.upgradeStatus.isUpdating { return }
        // 进度没达到 80 以上, 不因设备上线而检查比对版本
        guard case let .updating(progress) = self.upgradeStatus, progress >= 80 else { return }
        // 任务开始时间至今是否超过了1分钟
        guard let beginTime = self.beginTime, Date().timeIntervalSince1970 - beginTime > 60 else { return }
        
        logInfo("[DeviceFirmwareUpgrade] 设备(\(self.deviceId))上线, 查询设备当前版本号")
        self.versionCheckPolling(beginTime: beginTime)
    }

    /// 由 FirmwareUpgradeCenter 中的定时器触发
    /// 当任务状态为正在升级中时, 定时检查版本, 以确定升级操作完成
    public func timerTigger() {
        // 如果不是正在进行升级操作, return
        if !self.upgradeStatus.isUpdating { return }

        guard let beginTime = self.beginTime else { return }
        let now = Date().timeIntervalSince1970
        let timeInterval = now - beginTime
        
        // 如果任务开始时间未超过1分钟, 且设备未上线, 不开启轮询版本操作
        if timeInterval < 90 { return }

        // 每15秒检查一次版本
        if Int(timeInterval) % 15 == 0 {
            self.versionCheckPolling(beginTime: beginTime)
        }
    }

    /// 版本检查轮询
    private func versionCheckPolling(beginTime: TimeInterval) {
        
        if let _ = self.pollingDisposable { return }

        let deviceId = self.deviceId
        let originalVersion = self.originalVersion
        let targetVersion = self.targetVersion
        let versionCompareFailure = ReoqooError.deviceFirmwareUpgradeError(.versionCompareFailure)

        logInfo("[DeviceFirmwareUpgrade] 执行版本检查操作")
        
        self.pollingDisposable = self.checkVersionObservable()
            // 提前进行比对, 如遇比对不通过, 往下游抛出错误, 在 catch 操作符处执行重试
            .map({ currentVersion in
                if currentVersion.compareAsVersionString(originalVersion) != .newer {
                    logInfo("[DeviceFirmwareUpgrade] 升级版本比对不通过: currentVersion: \(currentVersion) originalVersion: \(originalVersion), targetVersion: \(targetVersion)")
                    throw versionCompareFailure
                }
                return currentVersion
            })
            .subscribe(onSuccess: { [weak self] currentVersion in
                // 由于上游拦截了错误, 所以这里一定是比对成功的结果, 成功直接对状态进行赋值
                self?.upgradeStatus = .success(atTime: Date().timeIntervalSince1970)
            }, onFailure: { [weak self] err in
                let interval = Date().timeIntervalSince1970 - beginTime
                // 已经超时了, 直接将任务定义为错误
                if interval > Self.pollingTimeOutInterval {
                    logInfo("[DeviceFirmwareUpgrade] 设备升级失败: 经过多次版本检查后, 版本对比仍不通过, deviceId:", deviceId)
                    self?.upgradeStatus = .failure(errorCode: (err as NSError).code, errorDescription: (err as NSError).localizedDescription, atTime: Date().timeIntervalSince1970)
                    return
                }

                // 判断错误类型
                guard let err = err as? ReoqooError, case let .deviceFirmwareUpgradeError(reason) = err, case .versionCompareFailure = reason else {
                    // 遇到网络请求错误, 直接 return, 等待下一次轮询
                    return
                }

                // 来到这里表示遇到 .deviceFirmwareUpgradeError(.versionCompareFailure) 错误, 即版本比对不通过
                // 如果设备已上线, 直接将结果置为失败
                let device = DeviceManager2.fetchDevice(deviceId)
                if device?.status == .online, case let .updating(progress) = self?.upgradeStatus, progress >= 80 {
                    logInfo("[DeviceFirmwareUpgrade] 设备升级失败: 设备已上线, 版本对比不通过, deviceId:", deviceId)
                    self?.upgradeStatus = .failure(errorCode: (err as NSError).code, errorDescription: (err as NSError).localizedDescription, atTime: Date().timeIntervalSince1970)
                    return
                }
            }, onDisposed: { [weak self] in
                self?.pollingDisposable = nil
            })
    }
}

// MARK: Hashable
extension FirmwareUpgradeTask: Hashable {
    var hashValue: Int { self.taskId.hashValue }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.taskId)
    }

    static func == (lhs: FirmwareUpgradeTask, rhs: FirmwareUpgradeTask) -> Bool { lhs.taskId == rhs.taskId }
}

// MARK: 持久化
extension FirmwareUpgradeTask {
    /// 从 UserDefaults 中获取某个设备的所有升级任务记录
    static func allTaskRecords() -> [FirmwareUpgradeTask] {
        let userDefault_key = UserDefaults.UserKey.Reoqoo_FirmwareUpgradeTasks.rawValue
        guard let tasks = try? AccountCenter.shared.currentUser?.userDefault?.data(forKey: userDefault_key)?.decoded(as: [FirmwareUpgradeTask].self) else { return [] }
        return tasks
    }
}

extension Array where Element == FirmwareUpgradeTask {
    /// 保存任务到 UserDefaults
    func save() {
        let json = try? self.encoded()
        let userDefault_key = UserDefaults.UserKey.Reoqoo_FirmwareUpgradeTasks.rawValue
        AccountCenter.shared.currentUser?.userDefault?.set(json, forKey: userDefault_key)
        AccountCenter.shared.currentUser?.userDefault?.synchronize()
        logInfo("[DeviceFirmwareUpgrade] Tasks 持久化")
    }
}
