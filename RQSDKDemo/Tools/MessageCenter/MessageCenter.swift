//
//  MessageCenter.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 2/11/2023.
//

import Foundation
import IVMessageMgr

/// 对接 消息中心 的工具类
class MessageCenter {

    static let shared: MessageCenter = .init()
    
    // 未读系统消息数量
    @RxBehavioral var numberOfUnreadSystemMessages: Int = 0

    // 未读app新版本消息数量 (只有 0, 1)
    @RxBehavioral var numberOfUnreadAppNewVersionMessages: Int = 0

    // 未读固件新版本消息数量
    @RxBehavioral var numberOfNewFirmwareMessages: Int = 0

    // 未读福利活动消息数量
    @RxBehavioral var numberOfUnreadWelfareActivityMessages: Int = 0

    // app新版本消息
    @RxBehavioral var appNewVersionMessageMapping: [String: FirstLevelMessageItem] = [:]
    
    // 设备新版本消息记录
    @RxBehavioral var deviceFirmwareMessages: Set<FirmwareUpgradeMessageRecord> = []
    
    /// 福利活动模型
    /// 由于没有针对福利活动未读数量的接口, 所以要获取未读福利活动数量需要直接请求`获取福利活动`接口来获得
    @RxBehavioral var welfareActivityMessages: [WelfareActivityItem] = []
    
    /// 作为一个开关, 以便手动触发 "检查未读消息数量"
    private(set) var manualCheckUnreadMsgCountSwitchObservable: RxSwift.BehaviorSubject = .init(value: false)
    
    private let disposeBag: DisposeBag = .init()
    
    private init() {

        // 尝试从本地加载 app新版本 消息
        self.appNewVersionMessageMapping = self.tryLoadAppUpdateMessageFromUserDefaults() ?? [:]

        // 监听 app新版本消息 发布者
        self.latestVersionMessageObservable().bind { [weak self] (version, item) in
            // 每次创建 "App新版本消息" 后都写入 UserDefaults
            guard let item = item else {
                // item 为空, 表示没有新版本
                AccountCenter.shared.currentUser?.userDefault?.set(nil, forKey: UserDefaults.UserKey.Reoqoo_NewVersionMessage.rawValue)
                self?.appNewVersionMessageMapping = [:]
                return
            }
            guard let version = version else {
                // version 为空, 表示检查新版本操作遇到网络错误
                return
            }
            // 持久化此条消息
            let localizeData = try? [version: item].encoded()
            AccountCenter.shared.currentUser?.userDefault?.set(localizeData, forKey: UserDefaults.UserKey.Reoqoo_NewVersionMessage.rawValue)
            AccountCenter.shared.currentUser?.userDefault?.synchronize()
            // 修改 self.appNewVersionMessageItem
            self?.appNewVersionMessageMapping = [version: item]
        }.disposed(by: self.disposeBag)
        
        // 监听 固件更新 消息
        self.firmwareUpgradeMessagesObservable().subscribe(onNext: { [weak self] records in
            self?.insertFirmwareUpdateMessageRecord2UserDefaults(records, dropNewIfDuplicate: true)
            self?.deviceFirmwareMessages = self?.tryLoadFirmwareUpdateMessageFromUserDefaults() ?? []
        }).disposed(by: self.disposeBag)

        // 监听用户登出, 清理 appNewVersionMessageMapping, deviceFirmwareMessages
        AccountCenter.shared.$currentUser.bind { [weak self] user in
            if let _ = user { return }
            self?.appNewVersionMessageMapping = [:]
            self?.deviceFirmwareMessages = []
            self?.numberOfNewFirmwareMessages = 0
            self?.numberOfUnreadSystemMessages = 0
            self?.numberOfUnreadWelfareActivityMessages = 0
            self?.numberOfUnreadAppNewVersionMessages = 0
        }.disposed(by: self.disposeBag)
        
        // app 新版本未读消息数量
        self.$appNewVersionMessageMapping.flatMap {
            // Observables<Int>
            let obs = $0.values.map { $0.unreadCountObservable }
            return Observable.merge(obs)
        }.startWith(0).subscribe { [weak self] num in
            self?.numberOfUnreadAppNewVersionMessages = num
        }.disposed(by: self.disposeBag)

        // 设备新固件未读消息数量
        self.$deviceFirmwareMessages.flatMap {
            // Observables<Int>
            let obs = $0.map({ $0.unreadCountObservable })
            return Observable.merge(obs)
        }.startWith(0).subscribe { [weak self] num in
            self?.numberOfNewFirmwareMessages = num
        }.disposed(by: self.disposeBag)

        // 系统未读消息数量
        // 服务器获取新消息, 拦截请求错误, 如遇错误直接返回0
        // 每120秒刷新一次, 如遇 p2p 收到 "MessageCenter.Update" 消息 也刷一次, self.manualCheckUnreadMsgCountSwitchObservable 传来元素也触发
        let requestUnreadMessageCountFromServerObservable = self.requestUnreadMessageCountFromServerObservable().catchAndReturn(0)
        Observable.merge([
            RQSDKDelegate.shared.$p2pOnlineMsg.map({ $0.topic == P2POnlineMsg.TopicType.NOTIFY_MESSAGE_CENTER_UPDATE.rawValue }).startWith(false),
            Observable<Int>.timer(.seconds(0), period: .seconds(120), scheduler: ConcurrentDispatchQueueScheduler.init(queue: DispatchQueue.global())).map({ _ in true }),
            self.manualCheckUnreadMsgCountSwitchObservable
        ])
        .throttle(.milliseconds(100), scheduler: MainScheduler.asyncInstance)
        // 丢弃 false
        .skip(while: { !$0 })
        .flatMap { _ in requestUnreadMessageCountFromServerObservable }
        .subscribe { [weak self] num in
            self?.numberOfUnreadSystemMessages = num
        }.disposed(by: self.disposeBag)

        // 获取福利活动消息,
        // 每隔 120 秒获取一次,
        // 收到 p2p 消息 NOTIFY_MESSAGE_CENTER_UPDATE 获取一次
        // 手动刷新也获取一次
        let requestWelfareActivityObservable = self.requestWelfareActivityObservable()
        Observable.merge([
            RQSDKDelegate.shared.$p2pOnlineMsg.map({ $0.topic == P2POnlineMsg.TopicType.NOTIFY_MESSAGE_CENTER_UPDATE.rawValue }).startWith(false),
            Observable<Int>.timer(.seconds(0), period: .seconds(120), scheduler: ConcurrentDispatchQueueScheduler.init(queue: DispatchQueue.global())).map({ _ in true }),
            self.manualCheckUnreadMsgCountSwitchObservable
        ])
        .throttle(.milliseconds(100), scheduler: MainScheduler.asyncInstance)
        // 丢弃 false
        .skip(while: { !$0 })
        .flatMap { _ in requestWelfareActivityObservable }
        .map({ $0.sorted { $0.expireTime > $1.expireTime } })
        .subscribe { [weak self] (items: [WelfareActivityItem]) in
            // 设置模型
            self?.welfareActivityMessages = items
            // 设置未读数量
            self?.numberOfUnreadWelfareActivityMessages = items.filter({ $0.status == 0 }).count
        }.disposed(by: self.disposeBag)
    }

    /// 从 UserDefaults 中加载 app 更新消息
    private func tryLoadAppUpdateMessageFromUserDefaults() -> [String: FirstLevelMessageItem]? {
        guard let data = AccountCenter.shared.currentUser?.userDefault?.object(forKey: UserDefaults.UserKey.Reoqoo_NewVersionMessage.rawValue) as? Data,
           let mapping = try? data.decoded(as: [String: FirstLevelMessageItem].self) else {
            return nil
        }
        // 主动触发 unreadCountObservable, 否则 unreadCountObservable 发布的初始值为 0
        mapping.forEach {
            let unreadCount = $0.value.unreadCnt
            $0.value.unreadCountObservable.onNext(unreadCount)
        }
        return mapping
    }
    
    /// 从 UserDefaults 中加载 固件更新消息
    private func tryLoadFirmwareUpdateMessageFromUserDefaults() -> Set<FirmwareUpgradeMessageRecord> {
        guard let data = AccountCenter.shared.currentUser?.userDefault?.object(forKey: UserDefaults.UserKey.Reoqoo_NewFirmwareMessage.rawValue) as? Data,
                let records = try? data.decoded(as: Set<FirmwareUpgradeMessageRecord>.self) else {
            return []
        }
        // 主动触发 unreadCountObservable, 否则 unreadCountObservable 发布的初始值为 0
        records.forEach {
            $0.unreadCountObservable.onNext($0.unreadCount)
        }
        return records
    }

    /// 插入 固件升级消息模型到 UserDefaults
    /// - Parameters:
    ///   - dropNewIfDuplicate: 
    ///     当为 true,  `records` 和 userdefaults 中已有的重复了, `records` 中的值会被丢弃, 以旧的为准
    ///     当为 false,  `records` 和 userdefaults 中已有的重复了, `userdefaults` 中的值会被丢弃, 以新的为准
    private func insertFirmwareUpdateMessageRecord2UserDefaults(_ records: Set<FirmwareUpgradeMessageRecord>, dropNewIfDuplicate: Bool) {
        var records = records
        // 读取
        var oldRecords = self.tryLoadFirmwareUpdateMessageFromUserDefaults()
        // 插入
        if dropNewIfDuplicate {
            oldRecords.forEach { records.remove($0) }
        }else{
            records.forEach { oldRecords.remove($0) }
        }
        records.forEach { oldRecords.insert($0) }
        // 写入 UserDefaults
        let localizeData = try? oldRecords.encoded()
        AccountCenter.shared.currentUser?.userDefault?.setValue(localizeData, forKey: UserDefaults.UserKey.Reoqoo_NewFirmwareMessage.rawValue)
        AccountCenter.shared.currentUser?.userDefault?.synchronize()
    }

    // MARK: 检查 APP 是否有新版本
    /// 检查 APP 是否有新版本发布者
    /// 共享型发布者
    /// 如遇错误最多重试 5次, 间隔 20秒
    private let checkLatestVersionObservable: Observable<String> = {
        // 检查是否有新版本 https://itunes.apple.com/lookup?id=6466230911
        let url = URL(string: "https://itunes.apple.com/lookup?id=6466230911")!
        let request = URLRequest(url: url)
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 15.0
        let session = URLSession(configuration: sessionConfig)
        return session.rx.response(request: request).map({ (response: HTTPURLResponse, data: Data) in
            let json = try JSON.init(data: data)
            // 如果取不到 appstore 上的最新版本信息, 表示 app 还没发布.
            // 返回当前app版本, 以便下游对比
            guard let latestVersion = json["results"].array?.first?["version"].string else {
                return Bundle.majorVersion
            }
            return latestVersion
        }).retry(5, period: .seconds(20)).share(replay: 1, scope: .forever)
    }()

    // MARK: 获取福利活动接口
    private func requestWelfareActivityObservable() -> Single<[WelfareActivityItem]> {
        Single<JSON>.create { observer in
            IVMessageCenterMgr.share.msgCenterNoticeList {
                let result = ResponseHandler.responseHandling(jsonStr: $0, error: $1)
                observer(result)
            }
            return Disposables.create()
        }.map {
            try $0["data"]["list"].decoded(as: [WelfareActivityItem].self)
        }
    }

    // MARK: 获取未读消息数量
    /// 从服务器获取未读消息数量 发布者, 此数量只包含系统消息数量, 不包含"活动福利"未读消息数量
    private func requestUnreadMessageCountFromServerObservable() -> Single<Int> {
        Single<JSON>.create { observer in
            IVMessageCenterMgr.share.unreadMessageCount {
                let result = ResponseHandler.responseHandling(jsonStr: $0, error: $1)
                observer(result)
            }
            return Disposables.create()
        }.map { json in
            return json["data"]["count"].intValue
        }
    }

    // MARK: 设备固件升级消息
    /// 获取固件消息发布者
    private func firmwareUpgradeMessagesObservable() -> Observable<Set<FirmwareUpgradeMessageRecord>> {
        DeviceManager2.shared.generateDevicesObservable(keyPaths: [\.deviceId, \.newVersionInfo])
            .compactMap({ $0?.filter({ $0.newVersionInfo != nil && $0.role == .master }) })
            .map { allDevs in
                // 过滤可升级的设备
                // Observable<(DeviceName, DeviceID, NewVersion: String?, CheckTime: Doubel?)>
                let obs = allDevs.map({
                    let deviceName = $0.remarkName
                    let deviceId = $0.deviceId
                    let newVersion = $0.newVersionInfo?.version
                    let newVersionCheckTime = $0.newVersionInfo?.checkedTime
                    return (deviceName, deviceId, newVersion, newVersionCheckTime)
                })
                return obs
            }.map { (infos: [(String, String, String?, TimeInterval?)]) in
                var res: Set<FirmwareUpgradeMessageRecord> = []
                for i in infos {
                    guard let newVersion = i.2 else { continue }
                    let deviceName = i.0
                    let deviceId = i.1
                    let time = i.3 ?? Date().timeIntervalSince1970
                    let body = String.localization.localized("AA0496", note: "%@上线啦。查看更新内容>>", args: newVersion)
                    let msgItem = MessageCenter.SecondLevelMessageItem.init(id: 0, tag: .firmwareUpdate, deviceId: 0, type: 0, title: deviceName, body: body, time: time, redirectUrl: "")
                    let record = FirmwareUpgradeMessageRecord.init(deviceId: deviceId, deviceName: deviceName, newVersion: newVersion, unreadCount: 1, messageItem: msgItem)
                    res.insert(record)
                }
                return res
            }
    }

    /// 获取APP新版本消息 发布者
    private func latestVersionMessageObservable() -> Observable<(String?, MessageCenter.FirstLevelMessageItem?)> {
        self.checkLatestVersionObservable.map { [weak self] latestVersion -> (String?, MessageCenter.FirstLevelMessageItem?) in
            // 比对当前 app 版本, 如果版本相同或当前版本较新, 消息返回 nil
            let versionCompareResult = Bundle.majorVersion.compareAsVersionString(latestVersion)
            if versionCompareResult == .equal || versionCompareResult == .newer {
                return (latestVersion, nil)
            }
            // 检查 UserDefaults 是否存有此消息
            if let mapping = self?.tryLoadAppUpdateMessageFromUserDefaults(), let messageItem = mapping[latestVersion] {
                return (latestVersion, messageItem)
            }
            // 否则创建新的
            let title = String.localization.localized("AA0496", note: "%@上线啦。查看更新内容>>", args: latestVersion)
            let item = MessageCenter.FirstLevelMessageItem.init(tag: .appUpdate, title: title, deviceId: 0, msgTime: Date().timeIntervalSince1970, isHeap: false, summary: "", unreadCnt: 1, redirectUrl: URL.AppStoreURL.absoluteString)
            return (latestVersion, item)
        }.catchAndReturn((nil, nil))
    }

    // MARK: 消息已读接口
    /// 将某类型消息标记为已读
    func syncMsgHaveBeenRead(tag: String?, deviceId: Int64?) {
        let tag = tag ?? ""
        let deviceId = deviceId ?? 0
        // 如果 tag isEmpty, 或 是 appUpdate 类型, 修改存于 UserDefaults 中的 unreadCnt 状态
        if tag.isEmpty || tag == MessageCenter.MessageTag.appUpdate.rawValue {
            // 将 appNewVersionMessageMapping 中的 message 未读数量置为 0
            self.appNewVersionMessageMapping.values.forEach { $0.unreadCnt = 0 }
            AccountCenter.shared.currentUser?.userDefault?.setValue((try? self.appNewVersionMessageMapping.encoded()), forKey: UserDefaults.UserKey.Reoqoo_NewVersionMessage.rawValue)
            AccountCenter.shared.currentUser?.userDefault?.synchronize()
        }
        // 将固件升级消息标记为已读
        if tag.isEmpty || tag == MessageCenter.MessageTag.firmwareUpdate.rawValue {
            self.deviceFirmwareMessages.forEach({ $0.unreadCount = 0 })
            self.insertFirmwareUpdateMessageRecord2UserDefaults(self.deviceFirmwareMessages, dropNewIfDuplicate: false)
        }
        // 请求服务器, 将 tag 类型的消息标记为已读
        IVMessageCenterMgr.share.refreshReadedMsg(tag: tag, deviceId: deviceId) { [weak self] _, _ in
            // 手动触发 "检查未读消息数量"
            self?.manualCheckUnreadMsgCountSwitchObservable.onNext(true)
        }
    }

    /// 福利活动已读处理
    func syncWelfareActivityBeenReaded(_ listOfActivitys: [WelfareActivityItem]) {
        // 将模型标记为已读
        listOfActivitys.forEach { $0.status = 1 }
        // 将未读数量标记为0
        self.numberOfUnreadWelfareActivityMessages = 0
        let ids = listOfActivitys.map({ Int64($0.id) })
        // 将活动福利标记为已读
        IVMessageCenterMgr.share.updateCenterNoticeStatus(idList: ids) {
            let res = ResponseHandler.responseHandling(jsonStr: $0, error: $1)
            if case let .failure(error) = res {
                logError("将福利活动消息置为已读", error)
            }
        }
    }

}
