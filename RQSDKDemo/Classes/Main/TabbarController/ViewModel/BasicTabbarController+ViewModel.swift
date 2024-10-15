//
//  BasicTabbarController+ViewModel.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 14/12/2023.
//

import Foundation

extension BasicTabbarController {
    class ViewModel {

        let disposeBag: DisposeBag = .init()
        
        /// 供 View 监听, 发布 用户消息, 以弹出 H5 推广页面
        let usrMsgEventSubject: RxSwift.PublishSubject<(IVUserMessageMgr.Message)> = .init()

        init() {
            // 为了使 APP 启动后取一次消息, 以 NOTIFY_USER_MSG_UPDATE 作为首发元素
            let p2pMsg = P2POnlineMsg.init(topic: P2POnlineMsg.TopicType.NOTIFY_USER_MSG_UPDATE.rawValue)
            RQSDKDelegate.shared.$p2pOnlineMsg
                .startWith(p2pMsg)
                .bind { [weak self] msg in
                    guard msg.topicType == P2POnlineMsg.TopicType.NOTIFY_USER_MSG_UPDATE else { return }
                    self?.fetchH5Msg(ignoreDeviceFirstBind: true)
                }.disposed(by: self.disposeBag)
        }
        
        // 展示用户消息H5弹窗 notice/usrmsg
        func fetchH5Msg(ignoreDeviceFirstBind: Bool) {
            let userMsgMgr = RQCore.Agent.shared.ivUserMsgMgr
            userMsgMgr.checkOut { [weak userMsgMgr, weak self] msgs_list in
                let msgList = userMsgMgr?.getMessages(of: [.h5], isRead: .unread, isExpired: .notExpire)
                // 取出消息
                guard let msg = msgList?.first, let data = msg.model as? IVUserMessageMgr.PopupH5TagData else { return }
                // 如果是首绑消息, 按 ignoreDeviceFirstBind 参数过滤一下
                if ignoreDeviceFirstBind && data.msgType == "VasPromotion" { return }
                self?.usrMsgEventSubject.onNext(msg)
            }
        }
    }
}
