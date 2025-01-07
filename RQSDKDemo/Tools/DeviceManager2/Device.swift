//
//  DeviceEntity.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 5/1/2024.
//

import Foundation

extension RQCore.DeviceStatus: RealmSwift.PersistableEnum {

    var description: String {
        switch self {
        case .offline:  return String.localization.localized("AA0054", note: "离线")
        case .online:   return String.localization.localized("AA0053", note: "在线")
        case .shutdown: return String.localization.localized("AA0502", note: "关机")
        case .turningOn: return String.localization.localized("AA0502", note: "关机")
        case .turningOff:   return String.localization.localized("AA0053", note: "在线")
        }
    }

    var image: UIImage? {
        switch self {
        case .offline:  return R.image.family_offline()
        case .online:   return R.image.family_online()
        case .shutdown: return R.image.family_shutdown()
        default: return nil
        }
    }

    var color: UIColor? {
        switch self {
        case .offline:  return R.color.device_offline_000000()
        case .online:   return R.color.device_online_15F715()
        case .shutdown: return R.color.device_shutdown_FA2A2D()
        case .turningOn: return R.color.device_offline_000000()
        case .turningOff: return R.color.device_online_15F715()
        }
    }
}

extension RQCore.DeviceRole: RealmSwift.PersistableEnum {}

class DeviceNewVersionInfoEntity: RealmSwiftEmbeddedObject, Codable, RQCore.DeviceNewVersionInfo {
    // 下载地址
    @Persisted var downUrl: String?
    // 最新版本: 3段式, 用于对比
    @Persisted var version: String?
    // 更新描述
    @Persisted var upgDescs: String?
    // 检查新版本的时间 (这个不是接口给的, 是客户端写的, 写的是查询这个新版本的时间)
    @Persisted var checkedTime: TimeInterval?
}

class DeviceEntity: RealmSwiftObject, Codable, RQCore.Device {

    /// 设备did
    @Persisted(primaryKey: true) var deviceId: String
    /// 备注名
    @Persisted var remarkName: String
    /// 关系链，1-绑定，2-分享
    @Persisted var role: DeviceRole
    /// 免打扰
    //var noDisturb: Int?
    /// 状态，bit0：云服务开关（0-开，1-关），bit1：针对主人设备是否有发生分享（0-否，1-是）
    @Persisted var cloudStatus: Int?
    /// 事件列表图片展示天数
    @Persisted var picDays: Int?
    /// 属性项，不同bit位标识是否存在相关属性 (bit0: 是否为T平台设备)
    @Persisted var properties: Int
    /// saas平台特有属性，properties bit0 为1时返回否则不返回
    @Persisted var saas: DeviceSassEntity?

    /// Gwell平台设备特有属性，properties bit1 为1时返回否则不返回
    @Persisted var gwell: DeviceGwellEntity?
    /// 小豚历史设备特有属性，properties bit2 为1时返回否则不返回
    @Persisted var dophigo: DeviceDophigoEntity?

    /// 云存服务相关属性，properties bit3 为1时返回否则不返回
    @Persisted var vss: DeviceVssEntity?
    /// 4G设备相关属性，properties bit4 为1时返回否则不返回
    @Persisted var fourCard: DeviceFourCardEntity?

    /// ai相关属性，properties bit5 为1时返回否则不返回
    @Persisted var ai: DeviceFourAIEntity?
    /// 客服相关属性，properties bit6 为1时返回否则不返回（不展示入口）
    @Persisted var custcare: DeviceCustcareEntity?
    /// 免费8s事件信息，properties bit7 为1时返回否则不返回
    @Persisted var freeEvs: DeviceFreeEvsEntity?

    // `status`, `presentVersion`, `swVersion` 三个属性由 DophiGoApiManager.getDeviceInfo(deviceID: device.deviceId) 接口查询
    /// 设备状态
    @Persisted var status: RQCore.DeviceStatus = .offline

    /// 版本号: 4段式, 仅用于展示.
    /// 目前 Reoqoo 宿主中没有使用的场景
    @Persisted var presentVersion: String?
    /// 版本号: 3段式, 用于比对, 查询新版本等
    @Persisted var swVersion: String?

    /// 设备列表排序id (本地定义)
    @Persisted var deviceListSortID: Int?
    /// 看家直播排序id (本地定义)
    @Persisted var liveViewSortID: Int?
    /// 看家是否关闭画面 (本地定义)
    @Persisted var isLiveClose: Bool = false
    /// 为了避免 realm 出现  "Object has been deleted or invalidated" 崩溃, 故 DeviceEntity 模型使用软删除机制
    /// 当一个设备被标记为 isDeleted, 不会马上执行从数据库删除的操作, 真正的删除操作会延后执行
    @Persisted var isDeleted: Bool = false

    /// 产品型号. 在取得 device list 后,  从 StandardConfiguration 中匹配对应的值并赋值到此属性
    @Persisted var productModule: String?
    /// 产品名称. 在取得 device list 后,  从 StandardConfiguration 中匹配对应的值并赋值到此属性
    @Persisted var productName: String?
    /// 设备扩展信息
    /// 在取得 device list 后,  从 StandardConfiguration 中匹配对应的值并赋值到此属性
    /// bit0: 是否4G设备
    /// bit1: 是否双摄
    /// bit2: 是否具备AI分析能力
    @Persisted var devExpandType: Int?

    /// 新版本信息
    /// 如为 nil, 表示没有新版本
    /// 当 Device 执行 checkNewVersionInfo() 方法后, 如有新版本, 会对此值进行赋值
    @Persisted var newVersionInfo: DeviceNewVersionInfoEntity?

    /// 是否固件升级中
    var isFirmwareUpdating: Bool {
        // 从 FirmwareUpgradeCenter 过滤
        FirmwareUpgradeCenter.shared.tasks.contains(where: { $0.deviceId == self.deviceId && $0.upgradeStatus.isUpdating })
    }

    required init(from decoder: Decoder) throws {
        super.init()
        self.deviceId = String(try decoder.decode("devId", as: Int.self))
        self.remarkName = try decoder.decode("remarkName", as: String.self)
        self.role = try decoder.decode("relation", as: DeviceRole.self)
        self.cloudStatus = try decoder.decode("status", as: Int.self)
        self.picDays = try? decoder.decode("picDays", as: Int.self)
        self.properties = try decoder.decode("properties", as: Int.self)
        self.saas = try? decoder.decode("saas", as: DeviceSassEntity.self)
        self.gwell = try? decoder.decode("gwell", as: DeviceGwellEntity.self)
        self.dophigo = try? decoder.decode("dophigo", as: DeviceDophigoEntity.self)
        self.vss = try? decoder.decode("vss", as: DeviceVssEntity.self)
        self.fourCard = try? decoder.decode("fourCard", as: DeviceFourCardEntity.self)
        self.ai = try? decoder.decode("ai", as: DeviceFourAIEntity.self)
        self.custcare = try? decoder.decode("custcare", as: DeviceCustcareEntity.self)
        self.freeEvs = try? decoder.decode("freeEvs", as: DeviceFreeEvsEntity.self)
    }

    override init() { super.init() }
    // 忽略 encode 操作, 没有此使用场景
    func encode(to encoder: Encoder) throws {}

    /// 不需要在创建时同步到数据库的属性
    /// 例如排序id由本地创建赋值不需同步的, status 和 版本号信息是创建后另外请求的
    static var keysThatWhenCreateIgnore: [PartialKeyPath<DeviceEntity>] = [\.deviceListSortID, \.liveViewSortID, \.isLiveClose, \.status, \.presentVersion, \.swVersion, \.productModule, \.productName, \.devExpandType]

    /// 创建从服务器获取新版本信息发布者
    func checkNewVersionInfoObservable() -> RxSwift.Single<DeviceNewVersionInfoEntity?> {
        guard let version = self.swVersion else { return .just(nil) }
        return RQApi.Api.queryDeviceNewVersionObservable(deviceId: self.deviceId, version: version)
    }

    /// 获取设备图片
    /// - Returns: observable <URL?>
    func getImageURLPublisher() -> AnyPublisher<URL?, Never> {
        return ProductTemplate.getProductImageURLPublisher(pid: self.productId).receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }

    /// 获取设备默认产品名称
    /// - Returns: observable <String?>
    func getProductNamePublisher() -> AnyPublisher<String?, Never> {
        return ProductTemplate.getProductNamePublisher(pid: self.productId).receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }

    /// 获取设备型号
    func getProductModelObservable() -> AnyPublisher<String?, Never> {
        return ProductTemplate.getProductModulePublisher(pid: self.productId).receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }

    /// 针对 @Persisted 持久化属性, 创建属性变化发布者
    /// - Parameters:
    ///   - key: DeviceEntity KeyPath
    ///   - errorValue: 当Realm对象从数据库删除后, observer 会接收到一个 error. 由于创建的发布者不会抛出错误, 所以需要给定一个默认值, 当错误发生时抛出
    ///   - emitInitialValue: 是否马上发布初始值
    /// - Returns: Observable<ValueType>
    func observable<ValueType>(_ key: KeyPath<DeviceEntity, ValueType>, whenErrorOccur errorValue: ValueType, emitInitialValue: Bool = true) -> Observable<ValueType> {
        return Observable.from(object: self, emitInitialValue: emitInitialValue, properties: [key.asString]).map { $0[keyPath: key] }.catchAndReturn(errorValue)
    }

}

// MARK: saas平台特有属性，properties bit0 为1时返回否则不返回
class DeviceSassEntity: RealmSwiftEmbeddedObject, Codable, RQCore.DeviceSass {
    /// 权限
    @Persisted var permission: String?
    /// 产品id
    @Persisted var productId: String?
    /// 产品SN
    @Persisted var sn: String?

    override class func className() -> String { String.init(describing: self) }
}

// MARK: Gwell平台设备特有属性，properties bit1 为1时返回否则不返回
class DeviceGwellEntity: RealmSwiftEmbeddedObject, Codable, RQCore.DeviceGwell {
    /// 权限
    @Persisted var permission: String?
    /// 修改时间
    @Persisted var modifyTime: Int?
    /// 秘钥
    @Persisted var secretKey: String?
    /// 设备配置项，按bit位解析，0：否，1：是。bit0: 是否为云存G升级V设备,bit1: 设备人形检测ai是否开通
    @Persisted var devConfig: Int?
}

// MARK: 小豚历史设备特有属性，properties bit2 为1时返回否则不返回
class DeviceDophigoEntity: RealmSwiftEmbeddedObject, Codable, RQCore.DeviceDophigo {
    /// 设备分类
    @Persisted var sort: String?
    /// 设备子分类
    @Persisted var subType: String?
    /// 设备型号
    @Persisted var model: String?
    /// 备用模式，0 睡眠模式 1低功耗模式
    @Persisted var standbymode: String?
    /// 设备主人id，当permission为分享的设备时不为空，例如0xxxx
    @Persisted var ownerId: String?
    /// 产品id
    @Persisted var pid: String?
    /// 功能掩码
    @Persisted var functionmask: String?
}

// MARK: 云存服务相关属性，properties bit3 为1时返回否则不返回
class DeviceVssEntity: RealmSwiftEmbeddedObject, Codable, RQCore.DeviceVss {
    /// 该设备是否支持云存 0：不支持、1：支持
    @Persisted var support: Int?
    /// 历史G平台设备云存接入方式，（0：默认历史处理方式，1：已接入saas、云存首页、回放等请使用saas相关接口）
    @Persisted var accessWay: Int?
    /// 云存服务过期时间，已过期时返回上次过期时间，未过期时返回即将过期时间，（0：未开通）
    @Persisted var vssExpireTime: Int?
    /// 云存服务自动续费状态，0：未续费，1：续费中
    @Persisted var vssRenew: Int?
    /// 自定义角标展示url
    @Persisted var cornerUrl: String?
    /// 服务类型，（bit0: 0-全时 1-事件，bit1: 0-购买 1-赠送）
    @Persisted var type: Int?
    /// 云存服务存储时长（单位天）, 免费云存期间，app可通过该字段控制查看天数，不返回时app默认3天
    @Persisted var storageDuration: Int?

    var isSupport: Bool {
        guard let support = support else {
            return false
        }
        return support != 0
    }

    var isBuyCloud: Bool {
        /**
         云存开通状态
         已开通：vss.vssExpireTime > curTime
         未开通：vss.vssExpireTime < curTime
         已过期：vss.vssExpireTime > 0 && curTime - vss.vssExpireTime < 7天
         */
        guard let vssExpireTime = vssExpireTime else {
            return false
        }
        return vssExpireTime > Int(Date().timeIntervalSince1970)
    }
}

// MARK: 4G设备相关属性，properties bit4 为1时返回否则不返回
class DeviceFourCardEntity: RealmSwiftEmbeddedObject, Codable, RQCore.DeviceFourCard {
    /// 不同bit位代表不同指标，bit0（卡是否注销，0-正常，1-注销），bit1（是否不支持购买云存，0-支持云存，1-不支持云存）
    @Persisted var status: Int?
    /// 该区是否支持4G流量运营 0：不支持、1：支持
    @Persisted var support: Int?
    /// 4G流量运营页面url
    @Persisted var purchaseUrl: String?
    /// 厂商编号
    @Persisted var factoryId: Int?
    /// 4G流量服务过期时间，已过期时返回上次过期时间，未过期时返回即将过期时间，（0：未开通）
    @Persisted var fgExpireTime: Int?
    /// 4G流量服务自动续费状态，0：未续费，1：续费中
    @Persisted var fgRenew: Int?
    /// 自定义角标展示url
    @Persisted var cornerUrl: String?
    /// 剩余流量，单位MB（小豚不返回此参数）
    @Persisted var surplusFlow: Int64?
    /// 总流量（单位MB），0表示无限流量套餐
    @Persisted var totalFlow: Int64?
    /// 已使用流量（单位MB）
    @Persisted var useFlow: Int64?

    /// 4G流量开通状态
    var isBuy4G: Bool {
        guard let fgExpireTime = fgExpireTime else {
            return false
        }
        return fgExpireTime > Int(Date().timeIntervalSince1970)
    }

    var isSupport: Bool {
        guard let support = support else { return false }
        return support != 0
    }
}

// MARK: ai相关属性，properties bit5 为1时返回否则不返回
class DeviceFourAIEntity: RealmSwiftEmbeddedObject, Codable, RQCore.DeviceFourAI {
    /// 该设备是否支持AI 0：不支持、1：支持（bit0:车辆检测, bit1:宠物识别）
    @Persisted var aiSupport: Int?
    /// 设备是否已开通AI，bit 0: 已解锁车辆检测 bit 1: 已解锁宠物识别
    @Persisted var aiInfo: Int?
}

// MARK: 客服相关属性，properties bit6 为1时返回否则不返回（不展示入口）
class DeviceCustcareEntity: RealmSwiftEmbeddedObject, Codable, RQCore.DeviceCustcare {
    /// 设备所属企业id
    @Persisted var endId: String?
}

// MARK: 免费8s事件信息，properties bit7 为1时返回否则不返回
class DeviceFreeEvsEntity: RealmSwiftEmbeddedObject, Codable, RQCore.DeviceFreeEvs {

    /// 免费8s的开通状态，0：未开通，1：已开通
    @Persisted var status: String?
    /// 需要主动领取免费8s的产品id列表
//    var revProIds_: [String] = []
    @Persisted var _revProIds: RealmSwift.List<String>
    required init(from decoder: Decoder) throws {
        self.status = try decoder.decode("status", as: String.self)
        self._revProIds = (try? decoder.decode("revProIds", as: RealmSwift.List<String>.self)) ?? .init()
    }

    override init() { super.init() }

    var revProIds: [String] {
        self._revProIds.toArray()
    }
}
