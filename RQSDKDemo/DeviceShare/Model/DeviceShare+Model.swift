//
//  ShareDeviceConfirmViewController+Model.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 13/6/2024.
//

import Foundation

extension DeviceShare {
    class GuestUser: Codable, CustomStringConvertible {

        /// 访客id
        var guestId: String
        /// 访客账号（是云端做掩码处理后数据）
        var account: String?
        /// 主人对访客的备注名
        var remarkName: String?
        /// 头像
        var headUrl: String?
        /// 分享确认时间,时间戳，单位秒
        var shareTime: Int?
        /// 权限
        var permission: String?
        /// 分享状态：3：待确认分享，4：分享失效
        var shareType: Int?

        required init(from decoder: Decoder) throws {
            let container: KeyedDecodingContainer<DeviceShare.GuestUser.CodingKeys> = try decoder.container(keyedBy: DeviceShare.GuestUser.CodingKeys.self)
            self.guestId = {
                if let id = try? decoder.decodeIfPresent("guestId", as: String.self) {
                    return id
                }
                if let id = try? decoder.decodeIfPresent("userId", as: String.self) {
                    return id
                }
                return ""
            }()
            // 同时 decode [guestAccount, account] 两个 key
            self.account = {
                if let account = try? decoder.decodeIfPresent("guestAccount", as: String.self) {
                    return account
                }
                if let account = try? decoder.decodeIfPresent("account", as: String.self) {
                    return account
                }
                return ""
            }()
            self.remarkName = try container.decodeIfPresent(String.self, forKey: DeviceShare.GuestUser.CodingKeys.remarkName)
            self.headUrl = try container.decodeIfPresent(String.self, forKey: DeviceShare.GuestUser.CodingKeys.headUrl)
            self.shareTime = try container.decodeIfPresent(Int.self, forKey: DeviceShare.GuestUser.CodingKeys.shareTime)
            self.permission = try container.decodeIfPresent(String.self, forKey: DeviceShare.GuestUser.CodingKeys.permission)
            self.shareType = try container.decodeIfPresent(Int.self, forKey: DeviceShare.GuestUser.CodingKeys.shareType)
        }

        var description: String {
            guard let remarkName = remarkName, !remarkName.isEmpty else {
                return account ?? ""
            }

            guard let account = account, !account.isEmpty else {
                return remarkName
            }

            return "\(remarkName)(\(account))"
        }
    }

    /// 设备分享情况描述
    class DeviceShareSituation: Codable {
        /// 已分享
        var guestList: [GuestUser]
        /// 准备分享, 已分享未接受
        var preGuestList: [GuestUser]
        /// 设备可分享数总量
        var guestCount: Int
    }

    /// 生成二维码的信息
    struct ShareQRCodeItem: Codable {
        /// 分享的url
        var shareLink: String
        /// 二维码过期时间，单位秒
        var expireTime: Double
    }

    /// 设备主人信息
    struct OwnerInfo: Codable, CustomStringConvertible {
        /// 主人昵称
        var nickName: String?
        /// 主人账号信息
        var ownerAccount: String?
        /// 产品id
        var productId: Int?

        var description: String {
            //显示规则：昵称(帐号) 或 昵称 或帐号
            var text: String = self.ownerAccount ?? ""
            if let nickName = self.nickName, !nickName.isEmpty {
                if let ownerAccount = self.ownerAccount, !ownerAccount.isEmpty {
                    text = "\(nickName)(\(ownerAccount))"
                } else {
                    text = nickName
                }
            }
            return String.localization.localized("AA0191", note: "分享用户") + " \(text)"
        }
    }

    /// 来自他人分享设备确认分享model：openapi/app/user/device/confirmShare
    /// 面对面扫码他人分享设备确认分享model：openapi/app/user/device/scanShareQrcode
    struct ShareConfirmItem: Codable {
        /// 设备did
        var devId: String?
        /// 返回设备token
        var devToken: String?
        /// 设备默认备注名
        var remarkName: String?
        /// 产品id
        var pid: Int?

        //MARK: code=11048（分享失败，超出分享数量限制）
        /// 同一台设备允许分享给访客的最大限制数量
        var devGuestNumLimit: Int?
    }

    /// 访客受邀信息展示model
    /// openapi/app/user/device/inviteInfo
    struct ShareInvitationInfo: Codable {
        /// 用户昵称
        var nickName: String?
        /// 权限信息
        var permission: String?
        /// 过期时间
        var expireTime: String?
        /// 产品id
        var pid: Int?
    }
    
    /// 权限项
    class SharePermission {

        /// 权限类型
        enum PermissionType: String, CustomStringConvertible, CaseIterable {
            /// 实时监控
            case live
            /// 对讲
            case intercom
            /// 云台
            case consoleControl
            /// 回放
            case playback
            /// 智能看家设置
            case surveillanceConfiguration
            /// 设备设置
            case deviceConfiguration

            var description: String {
                [PermissionType.live: String.localization.localized("AA0637", note: "实时监控"),
                 PermissionType.intercom: String.localization.localized("AA0638", note: "对讲"),
                 PermissionType.consoleControl: String.localization.localized("AA0639", note: "云台"),
                 PermissionType.playback: String.localization.localized("AA0640", note: "回放"),
                 PermissionType.surveillanceConfiguration: String.localization.localized("AA0192", note: "智能看家"),
                 PermissionType.deviceConfiguration: String.localization.localized("AA0642", note: "设备配置"),][self] ?? ""
            }

            // 是否可被配置
            var configurable: Bool {
                [PermissionType.live: false,
                 PermissionType.intercom: true,
                 PermissionType.consoleControl: true,
                 PermissionType.playback: true,
                 PermissionType.surveillanceConfiguration: true,
                 PermissionType.deviceConfiguration: true][self] ?? false
            }
        }

        /// 权限类型属于哪个系列
        enum PermissionSerie: String, CustomStringConvertible {
            /// 监控
            case surveillance
            /// 回放
            case playback
            /// 配置
            case configuration

            var description: String {
                [PermissionSerie.surveillance: String.localization.localized("AA0643", note: "设备监控"),
                 PermissionSerie.surveillance: String.localization.localized("AA0644", note: "设备回放"),
                 PermissionSerie.surveillance: String.localization.localized("AA0645", note: "设备控制")][self] ?? ""
            }
        }

        let type: PermissionType
        let serie: PermissionSerie
        var isValid: Bool = false

        init(type: PermissionType, serie: PermissionSerie, isValid: Bool) {
            self.type = type
            self.serie = serie
            self.isValid = isValid
        }
    }
}
