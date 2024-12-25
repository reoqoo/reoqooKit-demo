//
//  MessageCenterViewController+Model.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 18/9/2023.
//

import Foundation

extension MessageCenter {
    /// https://domain/openapi/msgcenter/msgtype/list

    /// 消息类型. 对应下面消息模型中的 tag 字段
    enum MessageTag: String, Codable {
        ///  设备提醒报警事件
        case alarmEvent = "MsgCenter_AlarmEvent"
        /// 优惠券提醒
        case couponRemind = "MsgCenter_CouponRemind"
        /// 客服消息
        case customerSrv = "MsgCenter_CustomerSrv"
        /// 云存服务动态
        case vss = "MsgCenter_VSS"
        /// 4G流量服务动态
        case fcs = "MsgCenter_FCS"
        /// app更新
        case appUpdate = "MsgCenter_APPUpgrade"
        ///  固件升级
        case firmwareUpdate = "MsgCenter_FirmwareUpdate"
        ///  金豆提醒
        case coinsRemind = "MsgCenter_CoinsRemind"
        ///  问题反馈
        case feedback = "MsgCenter_Feedback"
        ///  分享访客
        case shareGuest = "MsgCenter_ShareGuest"
    }

    /// 系统消息一级接口模型
    class FirstLevelMessageItem: Codable {
        var tag: MessageTag
        var title: String
        var deviceId: Int64
        var msgTime: TimeInterval
        /// 消息是否沉淀入库，false：无详情页，true：有详情页可点击进入
        var isHeap: Bool
        /// 消息概要
        var summary: String
        /// 未读数量
        var unreadCnt: Int {
            didSet {
                self.unreadCountObservable.onNext(self.unreadCnt)
            }
        }
        /// 覆盖类消息，点击跳转页面地址，为空时不可跳转
        var redirectUrl: String

        var icon: UIImage? {
            switch self.tag {
            case .shareGuest:
                return self.unreadCnt == 0 ? R.image.messageCenterTypeShare() : R.image.messageCenterTypeShareUnread()
            case .couponRemind:
                return self.unreadCnt == 0 ? R.image.messageCenterTypeCoupon() : R.image.messageCenterTypeCouponUnread()
            case .vss:
                return self.unreadCnt == 0 ? R.image.messageCenterTypeCloud() : R.image.messageCenterTypeCloudUnread()
            case .appUpdate:
                return self.unreadCnt == 0 ? R.image.messageCenterTypeAppUpdate() : R.image.messageCenterTypeAppUpdateUnread()
            case .firmwareUpdate:
                return self.unreadCnt == 0 ? R.image.messageCenterTypeDeviceUpdate() : R.image.messageCenterTypeDeviceUpdateUnread()
            case .feedback:
                return self.unreadCnt == 0 ? R.image.messageCenterTypeFeedbackReply() : R.image.messageCenterTypeFeedbackReplyUnread()
            default:
                return nil
            }
        }
        
        /// 未读消息数量 发布者
        lazy var unreadCountObservable: RxSwift.BehaviorSubject<Int> = .init(value: 0)

        init(tag: MessageTag, title: String, deviceId: Int64, msgTime: TimeInterval, isHeap: Bool, summary: String, unreadCnt: Int, redirectUrl: String) {
            self.tag = tag
            self.title = title
            self.deviceId = deviceId
            self.msgTime = msgTime
            self.isHeap = isHeap
            self.summary = summary
            self.unreadCnt = unreadCnt
            self.redirectUrl = redirectUrl

            self.unreadCountObservable.onNext(unreadCnt)
        }
    }

    /// 系统消息二级接口模型
    struct SecondLevelMessageItem: Codable {
        var id: Int64
        var tag: MessageTag
        var deviceId: Int64
        var type: Int
        var title: String
        var body: String
        var time: TimeInterval
        var redirectUrl: String
    }

    /// 福利活动模型
    class WelfareActivityItem: Codable {
        let id: Int
        /// 后台对应需要上报统计的id  非上面的id
        let noticeId: Int
        /// 标签
        let tag: String
        /// 跳转路径
        let url: String
        /// banner图片
        let picUrl: String
        ///  0 未读 1 已读 2 已过期
        var status: Int
        /// 开始时间
        var startTime: TimeInterval
        /// 结束时间
        var expireTime: TimeInterval = Date().timeIntervalSince1970
    }

    /// 用户消息DeviceShareInvite类型的data模型
    struct DeviceShareInviteModel {
        /// 消息id
        var msgId: Int = 0

        /// 弹窗对应h5页面url
        var url: String = ""
        /// 设备id
        var deviceId: String = ""
        /// 展示方式 0：静默不展示，1：弹窗展示url，2：跳转展示url
        var showWay: Int = 0
        /// 邀请码
        var shareToken: String = ""
        /// 邀请账号
        var inviteAccount: String = ""
    }

    /// 消息中心固件更新消息模型
    class FirmwareUpgradeMessageRecord: Codable, Hashable {

        /// 以 deviceId  + newVersion 作为 hashValue
        var hashValue: Int { (self.deviceId + self.newVersion).md5.hashValue }

        func hash(into hasher: inout Hasher) {
            hasher.combine(self.deviceId + self.newVersion)
        }
        
        static func == (lhs: MessageCenter.FirmwareUpgradeMessageRecord, rhs: MessageCenter.FirmwareUpgradeMessageRecord) -> Bool { lhs.hashValue == rhs.hashValue }

        let deviceId: String
        let newVersion: String
        let deviceName: String
        var unreadCount: Int {
            didSet {
                self.unreadCountObservable.onNext(self.unreadCount)
            }
        }
        var messageItem: SecondLevelMessageItem
        
        lazy var unreadCountObservable: RxSwift.BehaviorSubject<Int> = .init(value: 0)

        init(deviceId: String, deviceName: String, newVersion: String, unreadCount: Int, messageItem: SecondLevelMessageItem) {
            self.deviceId = deviceId
            self.newVersion = newVersion
            self.deviceName = deviceName
            self.unreadCount = unreadCount
            self.messageItem = messageItem
            
            self.unreadCountObservable.onNext(unreadCount)
        }
    }
}
