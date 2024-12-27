//
//  DeviceManager2.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 5/1/2024.
//

import Foundation
import DophiGoHiLink
import DophiGoHiLinkIV

extension DeviceManager2 {
    // 描述删除操作是从哪里发生的
    enum DeleteFrom {
        case app
        case reoqooSDK
    }
}

/*
 [
    {"status":2,
    "vss":{"vssExpireTime":-62135596800,"vssRenew":0,"support":0,"storageDuration":0,"type":0,"cornerUrl":"","accessWay":0},
    "fourCard":{"status":0,"fgRenew":0,"useFlow":0,"support":0,"fgExpireTime":0,"purchaseUrl":"","totalFlow":0,"surplusFlow":0,"factoryId":0,"cornerUrl":""},
    "ai":{"aiInfo":0,"aiSupport":0},
    "freeEvs":{"status":"","revProIds":null},
    "PicDays":7,
    "dophigo":{"pid":"","sort":"","subType":"","ownerId":"","model":"","functionmask":"","standbymode":""},
    "saas":{"productId":"15032386049","sn":"6804030123BU400E","permission":"3"},
    "relation":1,
    "properties":1,
    "gwell":{"secretKey":"","modifyTime":0,"devConfig":0,"permission":""},
    "custCare":{"entId":""},
    "devId":12885347714,
    "remarkName":"小青龙严正1"},
    {"status":2,"vss":{"vssExpireTime":-62135596800,"vssRenew":0,"support":0,"storageDuration":0,"type":0,"cornerUrl":"","accessWay":0},"fourCard":{"status":0,"fgRenew":0,"useFlow":0,"support":0,"fgExpireTime":0,"purchaseUrl":"","totalFlow":0,"surplusFlow":0,"factoryId":0,"cornerUrl":""},"ai":{"aiInfo":0,"aiSupport":0},"freeEvs":{"status":"","revProIds":null},"PicDays":7,"dophigo":{"pid":"","sort":"","subType":"","ownerId":"","model":"","functionmask":"","standbymode":""},"saas":{"productId":"15032386049","sn":"6804030123BU400F","permission":"3"},"relation":1,"properties":1,"gwell":{"secretKey":"","modifyTime":0,"devConfig":0,"permission":""},"custCare":{"entId":""},"devId":12885347719,"remarkName":"小青龙严正3"},
    {"status":0,"vss":{"vssExpireTime":1704952932,"vssRenew":0,"support":0,"storageDuration":7,"type":1,"cornerUrl":"","accessWay":0},"fourCard":{"status":0,"fgRenew":0,"useFlow":0,"support":0,"fgExpireTime":0,"purchaseUrl":"","totalFlow":0,"surplusFlow":0,"factoryId":0,"cornerUrl":""},"ai":{"aiInfo":0,"aiSupport":0},"freeEvs":{"status":"","revProIds":null},"PicDays":7,"dophigo":{"pid":"","sort":"","subType":"","ownerId":"","model":"","functionmask":"","standbymode":""},"saas":{"productId":"15032386049","sn":"6804030123C54001","permission":"117"},"relation":2,"properties":1,"gwell":{"secretKey":"","modifyTime":0,"devConfig":0,"permission":""},"custCare":{"entId":""},"devId":12885353119,"remarkName":"小青龙严正4"},
    {"status":0,"vss":{"vssExpireTime":1704684603,"vssRenew":0,"support":0,"storageDuration":3,"type":1,"cornerUrl":"","accessWay":0},"fourCard":{"status":0,"fgRenew":0,"useFlow":0,"support":0,"fgExpireTime":0,"purchaseUrl":"","totalFlow":0,"surplusFlow":0,"factoryId":0,"cornerUrl":""},"ai":{"aiInfo":0,"aiSupport":0},"freeEvs":{"status":"","revProIds":null},"PicDays":7,"dophigo":{"pid":"","sort":"","subType":"","ownerId":"","model":"","functionmask":"","standbymode":""},"saas":{"productId":"15032386053","sn":"6804010023AL000E","permission":"3"},"relation":1,"properties":1,"gwell":{"secretKey":"","modifyTime":0,"devConfig":0,"permission":""},"custCare":{"entId":""},"devId":12885290873,"remarkName":"Reoqoo Smart Camera X10"}]
 */

/*
 DeviceManager数据唯一流向:
 `网络请求 -> 数据库 -> 内存 -> UI`
 由于使用了 Realm, 当可轻松建立 数据库 和 内存 之间的映射关系
 self.devices 是按照设备列表排序后的设备模型集合
 */
class DeviceManager2 {

    static let shared: DeviceManager2 = .init()
    
    /// 设备集合. 仅当设备增删会触发发布者
    @RxBehavioral private(set) var devices: AnyRealmCollection<DeviceEntity> = .init(RealmSwift.List())

    /// 从服务器请求 device/list 结果
    public private(set) lazy var requestDeviceListResultObservable: RxSwift.PublishSubject<Result<Void, Swift.Error>> = .init()

    /// 新增设备操作发布者
    public private(set) lazy var addDeviceOperationResultObservable: RxSwift.PublishSubject<DeviceEntity> = .init()

    /// 设备残影
    /// 当设备被删除后, 对外通知时会用到
    typealias DeviceGhost = (deviceId: String, role: RQCore.DeviceRole, deleteFrom: DeleteFrom)

    /// 设备删除操作事件发布者
    /// 被动删除(异端删除, 主人移除访客等)也会触发
    /// 设备ID, 操作是否成功
    public private(set) lazy var devicesHasBeenDeletedOperationResultObservable: RxSwift.PublishSubject<Result<[DeviceGhost], Swift.Error>> = .init()

    /// 是否展示云服务入口
    /// 当用户登出登入 / 设备列表获取等事件发生后, 会影响此值变化
    /// 可监听属性
    @RxBehavioral var needShowVasEntrance: Bool = false

    /// 是否展示4G流量服务入口
    /// 当用户登出登入 / 设备列表获取等事件发生后, 会影响此值变化
    /// 可监听属性
    @RxBehavioral var needShow4GFluxEntrance: Bool = false

    /// 是否包含主人设备
    public var isContainMasterDevice: Bool { self.devices.filter({ $0.role == .master }).first != nil }

    private let disposeBag: DisposeBag = .init()

    /// 查询设备状态 DisposeBag 存储器
    /// 当发起查询设备状态请求时, 会写入 DisposeBag 于此 mapping
    /// 发起请求前, 先查询是否已有该设备正在被查询, 如有, 放弃新的查询操作
    /// 查询操作会自动重试直至成功
    private var devId_deviceStatusReqDisposeBag_mapping: [String: DisposeBag] = [:]

    /// 查询新版本信息 BaDisposeBag 存储器
    /// 当发起查询设备新版本请求时, 会写入 DisposeBag 于此 mapping
    /// 发起请求前, 先查询是否已有该设备正在被查询, 如有, 放弃新的查询操作
    /// 查询操作会自动重试直至成功
    private var devId_deviceNewVersionDisposeBag_mapping: [String: DisposeBag] = [:]

    private init() {

        // 监听用户登录状态, 从数据库查询设备 (建立数据库与内存的连接`self.devices`)
        // keyPaths参数只传入 ["deviceId"] 决定确保下游只关心 `设备数据库增加`, `设备数据库删除` 这两种事件. 减少 self.devices 被频繁触发变化
        self.generateDevicesObservable(keyPaths: [\.deviceId])
            .debounce(.milliseconds(100), scheduler: MainScheduler.asyncInstance)
            .throttle(.milliseconds(100), scheduler: MainScheduler.asyncInstance)
            .bind { [weak self] (devs: Results<DeviceEntity>?) in
                self?.devices = devs?.sorted(by: \.deviceListSortID, ascending: true).toAnyCollection() ?? .init(List())
            }.disposed(by: self.disposeBag)

        // 监听事件以刷新设备列表
        // IOTVideo 上线, p2p通知设备分享成功通知, p2p监听设备主人移除访客设备通知, 用户登录, app进入前台
        // iot 上线
        let iotOnlineObservable = RQSDKDelegate.shared.$linkStatus.filter { $0 == .online }
        // p2p 消息
        let p2pMsgObservable = RQSDKDelegate.shared.$p2pOnlineMsg.filter {
            // 接受分享通知
            if $0.topicType == .NOTIFY_SYS, let _ = $0.isGuestDidBind { return true }
            // 移除访客设备通知
            if $0.topicType == .NOTIFY_GUEST_DELETED_BY_MASTER { return true }
            // 主人移除了设备, 访客用户要刷新设备列表
            if let _ = $0.isGuestDidUnbind { return true }
            // 设备被重置后, 被其他账号绑定
            if let _ = $0.isUnbindOnwer { return true }
            // 分享的设备被接受消息
            if $0.topicType == .NOTIFY_MESSAGE_CENTER_UPDATE, let msgType = P2POnlineMsg.MsgType.init(rawValue: JSON.init(parseJSON: $0.msg)["type"].stringValue), msgType == .shareGuestConfirm { return true }
            return false
        }

        // 监听上面发布者, 触发刷新设备列表
        Observable.combineLatest(
            iotOnlineObservable,
            p2pMsgObservable.startWith(.init()),
            AccountCenter.shared.$currentUser.filter({ $0 != nil }),
            UIApplication.rx.didBecomeActive.startWith(())
        )
        .debounce(.milliseconds(300), scheduler: MainScheduler.asyncInstance)
        .throttle(.milliseconds(300), scheduler: MainScheduler.asyncInstance)
        .bind { [weak self] _ in
            self?.requestDevices()
        }.disposed(by: self.disposeBag)

        // 监听 device.swVersion, 当发生变化时, 拉取新的固件版本信息
        self.$devices.compactMap({
            // 仅关注主人设备
            $0.filter { $0.role == .master }
        }).flatMap { devs in
            /// 监听设备的 swVersion 属性变化, 并往下游发送 设备本身
            let swVersionObservables = devs.map { Observable.from(object: $0, emitInitialValue: false, properties: ["swVersion"]).mapAndCatchErrorWrapAsSwiftResult() }
            return Observable.merge(swVersionObservables)
        }.subscribe(onNext: { [weak self] result in
            guard case let .success(dev) = result else { return }
            // 设备在线才查新版本, 不在线不查
            guard dev.status == .online else { return }
            self?.queryNewVersionInfo(device: dev)
        }).disposed(by: self.disposeBag)

        // 监听App即将要退出, 检查是否需要执行物理删除
        AppEntranceManager.shared.$applicationState.filter { $0 == .didEnterBackground }.bind { [weak self] _ in
            self?.checkAndExecuteDevicePhysicalDeleted()
        }.disposed(by: self.disposeBag)

        // 监听相关要素以控制是否开启云服务入口
        self.observeVssSwitch()
//         监听相关要素以控制是否开启4G流量服务入口
        self.observe4GFluxSwitch()
    }

    /// 考虑到有些场景下, 仅仅靠 self.$devices 以监听设备变化是不足够的. 因为 self.$devices 只会因为设备增删而触发
    /// 因此对外提供这一方法, 创建一个用于监听设备数据库变化的发布者
    /// - Parameter keyPaths: 例如希望在设备 remarkName 发生变化时, 发布者会发元素, 可传入 [.remarkName], 如传入空数组, 表示设备列表中的任何设备中的任何属性改变, 都会触发发布者
    ///
    /// 用例: GuardianViewController+LiveCollectionCell.swift
    public func generateDevicesObservable(keyPaths: [PartialKeyPath<DeviceEntity>]? = nil) -> Observable<Results<DeviceEntity>?> {
        AccountCenter.shared.$currentUser.observe(on: MainScheduler.asyncInstance).flatMap {
            // 用户没登录, 返回 nil
            guard let user = $0, let db = user.realmDB else { return RxSwift.Observable<(Results<DeviceEntity>?)>.just(nil) }
            // 对 realm fetch 的结果进行监听
            let res = db.objects(DeviceEntity.self).where({ $0.isDeleted == false })
            // 确保下游只关心 `设备数据库增加`, `设备数据库删除` 这两种事件. 减少 self.devices 被频繁触发变化
            let keyPaths = keyPaths?.map({ $0.asString })
            return Observable.collection(from: res, keyPaths: keyPaths).map { $0 }
        }
    }

    /// 请求 /devices/list 接口
    public func requestDevices() {
        self.requestDevicesObservable().subscribe().disposed(by: self.disposeBag)
    }

    /// 请求
    public func requestDevicesObservable() -> Observable<[DeviceEntity]> {
        return self.getDevicesAndStoreObservable().do { [weak self] devs in
            // 更新设备们的信息
            self?.updateDevicesInfo()
            // 匹配产品型号
            self?.productModuleMatching()
            self?.requestDeviceListResultObservable.onNext(.success(()))
        } onError: { [weak self] err in
            self?.requestDeviceListResultObservable.onNext(.failure(err))
        }.asObservable()
    }

    /// 更新设备列表中的设备们的状态 (上线/离线, 版本信息)
    public func updateDevicesInfo() {
        // 遍历设备列表调用状态查询
        for dev in self.devices {
            // 如遇有查询任务未完成, 放弃新的查询操作
            if let _ = self.devId_deviceStatusReqDisposeBag_mapping[dev.deviceId] { continue }
            // 发起查询
            self.updateDeviceInfo(device: dev)
        }
    }

    /// 型号匹配操作
    private func productModuleMatching() {
        StandardConfiguration.shared.configurationJsonFetchObservable
            .observe(on: MainScheduler.asyncInstance)
            .subscribe { [weak self] (supportedProductInfo: [String : ProductTemplate], sceneNames: [String : [String]]) in
                guard let self else { return }
                DeviceManager2.db_updateDevicesWithContext { _ in
                    for dev in self.devices {
                        dev.productModule = supportedProductInfo[dev.productId]?.productModule ?? ""
                        dev.productName = supportedProductInfo[dev.productId]?.productName ?? ""
                        dev.devExpandType = supportedProductInfo[dev.productId]?.devExpandType ?? 0
                    }
                }
            }.disposed(by: self.disposeBag)
    }

    /// 查询单个设备的状态 (上线/离线, 版本信息)
    private func updateDeviceInfo(device: DeviceEntity) {
        // 创建 disposeBag, 存起来
        let disposeBag: DisposeBag = .init()
        self.devId_deviceStatusReqDisposeBag_mapping[device.deviceId] = disposeBag
        let deviceId = device.deviceId
        // 发起请求, 如遇失败自动重试, 3次, 10秒间隔
        self.updateDeviceInfoObservable(deviceId: deviceId, autoRetryTimes: 3, period: 10)
            .observe(on: MainScheduler.asyncInstance)
            .subscribe { devInfo in
                logInfo("[DeviceManager] 查询设备状态成功 deviceId = \(deviceId)", "devInfo.status =", devInfo.status.rawValue)
                // 查询成功, 写入到数据库
                Self.db_updateDevicesWithContext { db in
                    guard let device = DeviceManager2.fetchDevice(deviceId) else { return }
                    device.status = devInfo.status
                    device.presentVersion = devInfo.firmwareVer4
                    device.swVersion = devInfo.firmwareVer3
                }
        } onFailure: { err in
            logInfo("[DeviceManager] 查询设备状态失败 deviceId = \(deviceId), 将该设备标记为离线", err)
            Self.db_updateDevicesWithContext { db in
                guard let device = DeviceManager2.fetchDevice(deviceId) else { return }
                device.status = .offline
            }
        } onDisposed: { [weak self] in
            self?.devId_deviceStatusReqDisposeBag_mapping[deviceId] = nil
        }.disposed(by: disposeBag)
    }

    /// 查询某个设备的新版本
    private func queryNewVersionInfo(device: DeviceEntity) {
        // 如果已有查询操作正在执行未完成, 退出函数
        if let _ = self.devId_deviceNewVersionDisposeBag_mapping[device.deviceId] { return }
        let disposeBag: DisposeBag = .init()
        let deviceId = device.deviceId
        self.devId_deviceNewVersionDisposeBag_mapping[deviceId] = disposeBag
        device.checkNewVersionInfoObservable().subscribe(on: MainScheduler.asyncInstance).subscribe { info in
            Self.db_updateDevicesWithContext { _ in
                let device = Self.fetchDevice(deviceId)
                device?.newVersionInfo = info
            }
        } onFailure: { err in
            logInfo("[DeviceManager] 查询设备新版本失败 deviceId = \(deviceId)", err)
        } onDisposed: { [weak self] in
            self?.devId_deviceNewVersionDisposeBag_mapping[deviceId] = nil
        }.disposed(by: disposeBag)
    }
    
    /// 新增设备
    /// - Parameters:
    ///   - deviceId: deviceId
    ///   - deviceName: name
    ///   - deviceRole: 角色
    ///   - permission: 权限 (目前暂时没用)
    ///   - needTiggerPresent: 是否需要触发弹出插件
    public func addDevice(deviceId: String, deviceName: String, deviceRole: RQCore.DeviceRole, permission: String? = nil, needTiggerPresent: Bool) {

        // 直接通过 device/list 接口获取设备列表, 然后从列表中找到目标设备后抛出
        self.requestDevicesObservable().subscribe(on: MainScheduler.asyncInstance).subscribe(onNext: { [weak self] _ in
            // 如果 needTiggerPresent 为 true, 触发发布者发布事件
            if !needTiggerPresent { return }

            // 找到目标 device, 触发发布者
            guard let dev = Self.fetchDevice(deviceId) else { return }
            // 触发新增设备发布者
            self?.addDeviceOperationResultObservable.onNext(dev)
        }).disposed(by: self.disposeBag)
        
    }

    /// 删除设备: 发起请求 + 逻辑删除
    public func deleteDevice(_ dev: DeviceEntity, deleteOperationFrom: DeleteFrom) {
        self.deleteDeviceAndStoreObservable(device: dev, deleteFrom: deleteOperationFrom).subscribe().disposed(by: self.disposeBag)
    }

    // MARK: Helper
    /// 监听云服务入口开关
    private func observeVssSwitch() {
        // 设备列表为空
        let deviceIsEmptyObservable = self.$devices.map({ $0.isEmpty })
        // 只要有一台设备支持云服务, 都算是支持
        let isVssSupportObservable = self.$devices.map { $0.contains { $0.isSupportCloud } }
        // 超级VIP
        let userIsSuperVipObservable = AccountCenter.shared.$currentUser.compactMap({ $0 }).flatMap { $0.$basicInfo }.map({ $0.userId == User.SUPERVIP_userId })
        Observable.combineLatest(deviceIsEmptyObservable, isVssSupportObservable, userIsSuperVipObservable).map({
            if $2 { return false }
            if $0 { return false }
            return $1
        }).observe(on: MainScheduler.asyncInstance).bind { [weak self] on in
            self?.needShowVasEntrance = on
        }.disposed(by: self.disposeBag)
    }

    /// 监听4G服务入口开关
    private func observe4GFluxSwitch() {
        // 设备列表为空
        let deviceIsEmptyObservable = self.$devices.map({ $0.isEmpty })
        // 只要有一台设备支持云服务, 都算是支持
        let is4GFluxSupportObservable = self.$devices.map { $0.contains { $0.isSupport4GBuy } }
        // 超级VIP
        let userIsSuperVipObservable = AccountCenter.shared.$currentUser.compactMap({ $0 }).flatMap { $0.$basicInfo }.map({ $0.userId == User.SUPERVIP_userId })
        Observable.combineLatest(deviceIsEmptyObservable, is4GFluxSupportObservable, userIsSuperVipObservable).map({
            if $2 { return false }
            if $0 { return false }
            return $1
        }).observe(on: MainScheduler.asyncInstance).bind { [weak self] on in
            self?.needShow4GFluxEntrance = on
        }.disposed(by: self.disposeBag)
    }

    /// 配置设备排序参数
    /// 于 `查询device/list接口(批量插入设备)`, `删除设备` 后调用
    private static func configureSortID() {
        guard let db = AccountCenter.shared.currentUser?.realmDB else { return }
        let devs = db.objects(DeviceEntity.self).sorted(by: \.deviceId, ascending: true).toArray()
        Self.configureLiveListSortId(devs)
        Self.configureDevicesListSortId(devs)
    }

    /// 从数据库中找出不存在于 `deviceIds` 数组的 Device 对象
    /// 例如数据库中有 Device(1), Device(2). 传入 deviceIds 为 ["1"], 那么输出 [Device(2)]
    /// - Parameter deviceIds: 设备id数组
    private static func queryDevicesThatNotExistIn(deviceIds: [String]) -> [DeviceEntity] {
        guard let db = AccountCenter.shared.currentUser?.realmDB else { return [] }
        let res = db.objects(DeviceEntity.self).where({ $0.isDeleted == false })
        return res.toArray().filter({ !deviceIds.contains($0.deviceId) })
    }

    /// 配置设备列表排序参数
    private static func configureDevicesListSortId(_ devs: [DeviceEntity]) {
        // 以 deviceListSortID 排序
        var devs = devs.sorted { ($0.deviceListSortID ?? -1) < ($1.deviceListSortID ?? -1) }
        // 找出 deviceListSortID 为 nil 的元素们
        let tmp_devs = devs.filter { $0.deviceListSortID == nil }.sorted(by: { $0.deviceId < $1.deviceId })
        // 移除 deviceListSortID 为 nil 的元素们
        devs.removeAll(where: { tmp_devs.contains($0) })
        // 将 tmp_devs 添加到数组末尾
        devs += tmp_devs
        // 写入
        Self.db_updateDevicesWithContext { _ in
            for (idx, d) in devs.enumerated() {
                if d.deviceListSortID == idx { continue }
                d.deviceListSortID = idx
            }
        }
    }

    /// 配置看家列表排序参数
    private static func configureLiveListSortId(_ devs: [DeviceEntity]) {
        // 以 deviceListSortID 排序
        var devs = devs.sorted { ($0.liveViewSortID ?? -1) < ($1.liveViewSortID ?? -1) }
        // 找出 deviceListSortID 为 nil 的元素们
        let tmp_devs = devs.filter { $0.liveViewSortID == nil }.sorted(by: { $0.deviceId < $1.deviceId })
        // 移除 deviceListSortID 为 nil 的元素们
        devs.removeAll(where: { tmp_devs.contains($0) })
        // 将 tmp_devs 添加到数组末尾
        devs += tmp_devs
        // 写入
        Self.db_updateDevicesWithContext { _ in
            for (idx, d) in devs.enumerated() {
                if d.liveViewSortID == idx { continue }
                d.liveViewSortID = idx
            }
        }
    }

    /// 从数据库中取出 device
    /// 在哪个线程执行, 就在哪个线程取出
    public static func fetchDevice(_ deviceId: String) -> DeviceEntity? {
        guard let db = AccountCenter.shared.currentUser?.realmDB else { return nil }
        return db.object(ofType: DeviceEntity.self, forPrimaryKey: deviceId)
    }

    /// 开关设备
    public func turnOnDevice(_ deviceId: String, on: Bool) {
        self.turnOnDeviceObservable(deviceId, on: on).subscribe().disposed(by: self.disposeBag)
    }

    /// 检查设设备列表并执行物理删除操作
    private func checkAndExecuteDevicePhysicalDeleted() {
        guard let db = AccountCenter.shared.currentUser?.realmDB else { return }
        // 取出被标记为已删除的设备
        let devs = db.objects(DeviceEntity.self).where { $0.isDeleted }.toArray()
        // 取出设备id
        let devIds = devs.map({ $0.deviceId })
        if devs.count <= 0 { return }
        do {
            try db.write {
                db.delete(devs)
                logInfo("[DeviceManager] 成功执行物理删除操作", devIds.joined(separator: ","))
            }
        } catch let err {
            logError("[DeviceManager] 执行物理删除操作失败", err)
        }
    }
}

// MARK: 数据库相关
extension DeviceManager2 {
    
    /// 提供一个 数据库 修改环境, 让外部改变 Device 对象
    /// 在 db.write {} 方法外修改 Device 对象都是无效错误的
    /// `注意: 不论此方法在任何线程调用, 最终会在主线程发起 writeAsync, 因此, 需要确保 闭包context 中传入的 Realm对象实例都是来自主线程`
    /// `或者直接在闭包中查询Realm对象然后再进行修改, 这样可以保证不会发生跨线程访问错误`
    public static func db_updateDevicesWithContext(_ context: ((Realm)->())?) {
        // 跳到主线程, 防止 `Cannot schedule async transaction. Make sure you are running from inside a run loop` 错误发生
        DispatchQueue.main.async {
            guard let db = AccountCenter.shared.currentUser?.realmDB else { return }
            db.writeAsync {
                context?(db)
            } onComplete: { err in
                guard let err = err else { return }
                logError("[DeviceManager] 写数据库出错了", err)
            }
        }
    }

    /// 新增 设备列表到数据库 操作发布者
    fileprivate func db_insertDevicesObservable(devices: [DeviceEntity]) -> RxSwift.Single<Void> {
        return .create { observer in
            guard let db = AccountCenter.shared.currentUser?.realmDB else {
                observer(.failure(ReoqooError.generalError(reason: .userIsLogout)))
                return Disposables.create()
            }

            // 写入到数据库前, 遍历 devices, 检查是否已存在数据库中
            for dev in devices {
                guard let exist_dev = db.object(ofType: DeviceEntity.self, forPrimaryKey: dev.deviceId) else { continue }
                // 如果已存在, 将已存在对象的属性转移到新对象中
                DeviceEntity.keysThatWhenCreateIgnore.forEach {
                    dev.setValue(exist_dev.value(forKey: $0.asString), forKey: $0.asString)
                }
            }

            // 设置排序id
            Self.configureLiveListSortId(devices)
            Self.configureDevicesListSortId(devices)

            // 写入到数据库
            db.writeAsync {
                // update 参数决定了当相同的主键存在时所采取的策略
                // 不存在, 写入
                // 存在, 修改
                db.add(devices, update: .modified)
                observer(.success(()))
            } onComplete: {
                guard let err = $0 else { return }
                logError("[DeviceManager] 写realm数据库失败", err)
            }

            return Disposables.create()
        }
    }

    /// 将设备模型标记为被删除 (逻辑删除)发布者
    public func db_markDevicesAsDeleted(devices: [DeviceEntity], deleteOperationFrom: DeleteFrom) {
        self.db_markDeviceAsDeletedObservable(devices: devices, deleteOperationFrom: deleteOperationFrom).subscribe().disposed(by: self.disposeBag)
    }

    /// 将设备模型标记为被删除 (逻辑删除)发布者
    fileprivate func db_markDeviceAsDeletedObservable(devices: [DeviceEntity], deleteOperationFrom: DeleteFrom) -> RxSwift.Single<Void> {
        guard let db = AccountCenter.shared.currentUser?.realmDB else { return .error(ReoqooError.generalError(reason: .userIsLogout)) }
        let deviceGhosts = devices.map { ($0.deviceId, $0.role, deleteOperationFrom) }
        return .create { [weak self] observer in
            if db.isInWriteTransaction {
                devices.forEach { $0.isDeleted = true }
            }else{
                do {
                    try db.write {
                        devices.forEach { $0.isDeleted = true }
                        observer(.success(()))
                        self?.devicesHasBeenDeletedOperationResultObservable.onNext(.success(deviceGhosts))
                    }
                } catch let err {
                    logError("[DeviceManager] 写realm数据库失败(将设备标记为已删除)", err)
                    observer(.failure(err))
                    self?.devicesHasBeenDeletedOperationResultObservable.onNext(.failure(err))
                }
            }
            return Disposables.create()
        }
    }

    /// 物理删除发布者
    fileprivate func db_deleteObservable(devices: [DeviceEntity]) -> RxSwift.Single<Void> {
        guard let db = AccountCenter.shared.currentUser?.realmDB else { return .error(ReoqooError.generalError(reason: .userIsLogout)) }
        return .create { observer in
            db.writeAsync {
                db.delete(devices)
                observer(.success(()))
            } onComplete: {
                guard let err = $0 else { return }
                logError("[DeviceManager] 写realm数据库失败(删除操作)", err)
                observer(.failure(err))
            }
            return Disposables.create()
        }
    }
}

// MARK: 发布者封装
extension DeviceManager2 {

    /// 获取设备列表请求 + 写入数据库两个操作合并的发布者
    private func getDevicesAndStoreObservable() -> RxSwift.Single<[DeviceEntity]> {
        self.getDevicesObservable()
            // 比对本地和网络请求得到的设备, 从本地找到不存在于网络请求得到的设备, 将这些设备标记为已删除
            .flatMap { [weak self] devs in
                guard let obs = self?.markDevicesAsDeletedThatAfterSubtractObservable(devs) else { return .error(ReoqooError.generalError(reason: .optionalTypeUnwrapped)) }
                return obs.map { _ -> [DeviceEntity] in devs }
            }
            // 将网络请求得到的设备写入数据库
            .flatMap { [weak self] (devs: [DeviceEntity]) in
                guard let obs = self?.db_insertDevicesObservable(devices: devs) else { return .error(ReoqooError.generalError(reason: .optionalTypeUnwrapped)) }
                return obs.map({ devs })
            }
    }

    /// 获取设备列表发布者
    private func getDevicesObservable() -> RxSwift.Single<[DeviceEntity]> {
        RxSwift.Single<JSON>.create { observer in
            RQApi.Api.queryDeviceList {
                let res = ResponseHandler.responseHandling(jsonStr: $0, error: $1)
                observer(res)
            }
            return Disposables.create()
        }.map { json -> [DeviceEntity] in
            try json["data"]["deviceList"].decoded(as: [DeviceEntity].self)
        }
    }

    /// 一些设备被删除事件本地数据库是无法感知的, 例如多端登录删除场景, 主人删除分享设备场景.
    /// 所以设备数据应以网络请求为标准. 此方法会将 网络请求得到的 Devices 和 本地数据库 Devices 进行比对, 如 本地 Devices 不存在于 网络请求得到的Devices 数组中, 将本地那一份数据进行逻辑删除
    /// - Parameter devices: 从网络请求得来的设备列表
    private func markDevicesAsDeletedThatAfterSubtractObservable(_ devices: [DeviceEntity]) -> RxSwift.Single<Void> {
        // 从数据库中取出不存在于 devices 的设备
        let devicesThatNotExist = Self.queryDevicesThatNotExistIn(deviceIds: devices.map({ $0.deviceId }))
        return self.db_markDeviceAsDeletedObservable(devices: devicesThatNotExist, deleteOperationFrom: .app)
    }

    /// 获取设备信息查询发布者
    /// - Parameters:
    ///   - autoRetryTimes: 自动重试次数
    ///   - period: 重试间隔
    private func updateDeviceInfoObservable(deviceId: String, autoRetryTimes: Int = 10, period: Int) -> RxSwift.Single<RQCore.DeviceExtraInfo> {
        let single = Single<RQCore.DeviceExtraInfo>.create { observer in
            Agent.shared.requestDeviceInfo(deviceId) {
                observer($0)
            }
            return Disposables.create()
        }
        return single.subscribe(on: MainScheduler.asyncInstance).catch { err in
            Single<Int>.timer(.seconds(period), scheduler: MainScheduler.asyncInstance).flatMap { _ in
                return Single<RQCore.DeviceExtraInfo>.error(err)
            }
        }.retry(autoRetryTimes)
    }

    /// 删除设备请求 + 逻辑删除 两个操作合并发布者
    public func deleteDeviceAndStoreObservable(device: DeviceEntity, deleteFrom: DeleteFrom) -> RxSwift.Single<DeviceGhost> {
        let devId = device.deviceId
        let role = device.role
        logInfo("[DeviceManager] 即将执行设备删除操作", devId)
        return self.deleteDeviceObservable(device: device).flatMap { [weak self] dev in
            guard let obs = self?.db_markDeviceAsDeletedObservable(devices: [device], deleteOperationFrom: deleteFrom) else { return .error(ReoqooError.generalError(reason: .optionalTypeUnwrapped)) }
            return obs.map { (devId, role, deleteFrom) }
        }.do(onSuccess: { ghost in
            logInfo("[DeviceManager] 删除设备操作成功", devId)
            // 重置排序id
            Self.configureSortID()
        }, onError: { err in
            logInfo("[DeviceManager] 删除设备请求失败", devId, err)
        })
    }

    /// 创建删除设备请求发布者
    /// - Parameter device: 设备
    /// - Returns: 被删除的设备的ID
    private func deleteDeviceObservable(device: DeviceEntity) -> RxSwift.Single<DeviceEntity> {
        if device.role == .master {
            return RxSwift.Single<DeviceEntity>.create { observer in
                RQApi.Api.deleteDevice(withDeviceId: device.deviceId) { json, error in
                    let result = ResponseHandler.responseHandling(jsonStr: json, error: error)
                    switch result {
                    case .failure(let error):
                        observer(.failure(error))
                    case .success(_):
                        observer(.success(device))
                    }
                }
                return Disposables.create()
            }
        }else{
            return RxSwift.Single<DeviceEntity>.create { observer in
                RQApi.Api.removeDeviceWhichFromShared(withDeviceId: device.deviceId) { json, error in
                    let result = ResponseHandler.responseHandling(jsonStr: json, error: error)
                    switch result {
                    case .failure(let error):
                        observer(.failure(error))
                    case .success(_):
                        observer(.success(device))
                    }
                }
                return Disposables.create()
            }
        }
    }

    /// 开关设备发布者
    public func turnOnDeviceObservable(_ deviceId: String, on: Bool) -> Single<Void> {
        .create { observer in
            DHReoqooApi.setCameraOn(on, deviceId: deviceId) { code, msg, resObj in
                if code == kReoqooApiCodeSuccess {
                    observer(.success(()))
                }else{
                    observer(.failure(NSError.init(domain: "SET_CAMERA_ON_ERROR", code: Int(code))))
                }
            }
            return Disposables.create()
        }.do(onSuccess: {
            // 成功后会在 `ReoqooApi.swift` func postDeviceStatus(_ pluginId: String, deviceId: String, status: DHDeviceStatus) 中对 Device.status 进行修改, 所以这里不管这个状态更新
        }, onSubscribed: {
            Self.db_updateDevicesWithContext { _ in
                let device = Self.fetchDevice(deviceId)
                device?.status = on ? .turningOn : .turningOff
            }
        })
    }
}
