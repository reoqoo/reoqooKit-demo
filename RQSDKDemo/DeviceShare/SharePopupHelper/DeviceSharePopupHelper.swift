//
//  DeviceSharePopupView.swift
//  RQSDKDemo
//
//  Created by chenchangxin on 2023/9/25.
//

import Foundation

/// 设备分享弹窗处理
class DeviceSharePopupHelper {

    private var anyCancellables: Set<AnyCancellable> = []

    /// 检查分享信息是否已经过期
    func checkShare(inviteModel: MessageCenter.DeviceShareInviteModel) {

        DeviceShare.requestInvitationInfoPublisher(inviteToken: inviteModel.shareToken, deviceId: inviteModel.deviceId).sink { [weak self] completion in
            guard case .failure = completion else { return }
            self?.handleCheckShareFail()
        } receiveValue: { [weak self] model in
            if Int(model.expireTime) < Int(NSDate().timeIntervalSince1970) {
                self?.handleCheckShareFail()
            } else {
                self?.handleCheckShareSuccess(inviteModel: inviteModel, inviteInfoRes: model)
            }
        }.store(in: &self.anyCancellables)
    }
    
    /// 处理检测分享信息有效结果
    private func handleCheckShareSuccess(inviteModel: MessageCenter.DeviceShareInviteModel, inviteInfoRes: DeviceShare.ShareInvitationInfo) {

        var inviteAccount = inviteModel.inviteAccount
        if let nickName = inviteInfoRes.nickName, nickName != inviteAccount {
            inviteAccount = nickName
        }
        
        let productId = String(inviteInfoRes.pid ?? 0)
        let customView = DeviceShareHeaderView(style: .default, frame: .zero)
        customView.setImage(productId: productId)
        customView.setProductName(productId: productId)
        
        let property = ReoqooPopupViewProperty()
        property.title = String.localization.localized("AA0164", note: "%@分享的设备", args: inviteAccount)
        property.customView = customView
        property.ratio = 0.65

        let refuseAction = IVPopupAction(title: String.localization.localized("AA0067", note: "拒绝"), style: .custom, color: R.color.text_link_4A68A6(), handler: { [weak self] in
            self?.refuseShare(deviceId: inviteModel.deviceId, inviteToken: inviteModel.shareToken)
        })
        let acceptAction = IVPopupAction(title: String.localization.localized("AA0165", note: "接受"), style: .custom, color: R.color.text_link_4A68A6(), handler: { [weak self] in
            self?.confirmShare(inviteToken: inviteModel.shareToken, inviteInfoRes: inviteInfoRes, remarkName: customView.name)
        })
        IVPopupView(property: property, actions: [refuseAction, acceptAction]).show()
    }
    
    /// 处理检测分享信息失效结果
    private func handleCheckShareFail() {
        //先弹窗提醒用户
        let property = ReoqooPopupViewProperty()
        property.message = String.localization.localized("AA0168", note: "分享失效，可让主人重新分享")
        
        let okAction = IVPopupAction(title: String.localization.localized("AA0131", note: "知道了"), style: .custom, color: R.color.text_link_4A68A6(), handler: {})
        IVPopupView(property: property, actions: [okAction]).show()
    }
    
    /// 拒绝分享 & 结果
    private func refuseShare(deviceId: String, inviteToken: String) {
        RQApi.Api.removeDeviceWhichFromShared(withDeviceId: deviceId) { _, _ in }
    }
    
    /// 接受分享 & 结果
    private func confirmShare(inviteToken: String, inviteInfoRes: DeviceShare.ShareInvitationInfo, remarkName: String) {
        DeviceShare.confirmInvitationPublisher(inviteToken: inviteToken, remarkName: remarkName).sink { completion in
            guard case let .failure(err) = completion else { return }
            switch (err as NSError).code {
            case ReoqooError.DeviceShareError.notSupportSpanned.rawValue:
                MBProgressHUD.showHUD_DispatchOnMainThread(text: String.localization.localized("AA0172", note: "您和主人不是同一区域，不支持分享"))
            default:
                MBProgressHUD.showHUD_DispatchOnMainThread(text: String.localization.localized("AA0167", note: "添加失败"))
            }
        } receiveValue: { item in
            /**
             如果接受分享成功，则按以下步骤处理：
             1. 先弹窗提醒用户
             2. 然后新增到本地列表中（内部会读取云端最新数据，并刷新九宫格列表，最后拉起插件）
             */

            //先弹窗提醒用户
            let property = ReoqooPopupViewProperty()
            property.message = String.localization.localized("AA0089", note: "添加成功")
            
            let cancelAction = IVPopupAction(title: String.localization.localized("AA0059", note: "取消"), style: .custom, color: R.color.text_link_4A68A6(), handler: {
                guard let devId = item.devId else { return }
                DeviceManager2.shared.addDevice(deviceId: devId, deviceName: remarkName, deviceRole: .master, permission: nil, needTiggerPresent: false)
            })
            let checkAction = IVPopupAction(title: String.localization.localized("AA0166", note: "立即查看"), style: .custom, color: R.color.text_link_4A68A6(), handler: {
                guard let devId = item.devId else { return }
                DeviceManager2.shared.addDevice(deviceId: devId, deviceName: remarkName, deviceRole: .shared, permission: inviteInfoRes.permission, needTiggerPresent: true)
            })
            IVPopupView(property: property, actions: [cancelAction, checkAction]).show()
        }.store(in: &self.anyCancellables)
    }
}
