//
//  FamilyViewController2+ViewModel.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 17/2/2024.
//

import Foundation

extension FamilyViewController2 {
    class ViewModel {

        /// 设备分享请求发布者
        public lazy var deviceShareInviteObservable: RxSwift.PublishSubject<MessageCenter.DeviceShareInviteModel> = .init()

        /// 供 View 监听, 以弹出 首页顶部Banner
        public let headerBannerSubject: RxSwift.PublishSubject<IVBBSMgr.Banner> = .init()

        /// 当分享邀请被处理(接受/拒绝)后, 会触发此发布者
        public let shareInviteHandlingResultObservable: RxSwift.PublishSubject<(String, Bool)> = .init()

        private let disposeBag: DisposeBag = .init()

        init() {
            /// 这里监听p2p的在线消息（设备分享）
            // 为了使 APP 启动后取一次消息, 以 NOTIFY_USER_MSG_UPDATE 作为首发元素
            let p2pMsg = P2POnlineMsg.init(topic: P2POnlineMsg.TopicType.NOTIFY_USER_MSG_UPDATE.rawValue)
            RQSDKDelegate.shared.$p2pOnlineMsg.startWith(p2pMsg).bind { [weak self] onlineMsg in
                switch onlineMsg.topicType {
                case .NOTIFY_USER_MSG_UPDATE:
                    // 刷新邀请消息
                    self?.checkOutInviteMessage()
                    // 刷新公告消息
                    self?.fetchNotices()
                case .NOTIFY_SYS: //消息中心刷新通知
                    if let deviceId = onlineMsg.isGuestDidBind { 
                        // 接受设备分享通知
                        self?.shareInviteHandlingResultObservable.onNext((deviceId, true))
                    } else if let deviceId = onlineMsg.isGuestDidUnbind { 
                        // 移除访客通知
                        self?.shareInviteHandlingResultObservable.onNext((deviceId, false))
                    }
                default: break
                }
            }.disposed(by: self.disposeBag)
        }

        // 展示浮窗/顶部banner
        func fetchNotices() {
            let bbsMsgMgr = RQCore.Agent.shared.ivBBSMgr
            bbsMsgMgr.checkOut { [weak bbsMsgMgr, weak self] suc in
                if let banner = bbsMsgMgr?.getBannerInfo(of: .home) {
                    logInfo("展示首页顶部Banner: ", banner.picUrl as Any, banner.url as Any)
                    self?.headerBannerSubject.onNext(banner)
                }
            }
        }

        // 获取用户邀请消息
        func checkOutInviteMessage() {
            RQCore.Agent.shared.ivUserMsgMgr.checkOut { [weak self] success in
                if !success { return }
                let messages = RQCore.Agent.shared.ivUserMsgMgr.getMessages(isRead: .unread, isExpired: .notExpire) ?? []
                // 取出分享消息
                guard let inviteMsg = messages.filter({ $0.type == .share }).first, let jsonStr = inviteMsg.data else { return }
                let json = JSON.init(parseJSON: jsonStr)
                // 组件模型
                var inviteModel = MessageCenter.DeviceShareInviteModel()
                inviteModel.msgId = inviteMsg.msgId
                inviteModel.url = json["url"].stringValue
                inviteModel.deviceId = json["deviceId"].stringValue
                inviteModel.showWay = json["showWay"].intValue
                inviteModel.shareToken = json["shareToken"].stringValue
                inviteModel.inviteAccount = json["inviteAccount"].stringValue
                // 发布者发布邀请
                self?.deviceShareInviteObservable.onNext(inviteModel)
            }
        }
    }
}
