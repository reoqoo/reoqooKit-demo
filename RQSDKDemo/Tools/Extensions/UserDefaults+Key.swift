//
//  UserDefaults+Key.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 25/7/2023.
//

import Foundation

extension UserDefaults {
    // UserDefaults 全局 Key
    enum GlobalKey: String {
        /// debug 模式开启
        case Reoqoo_DebugMode
        /// app请求地址 String
        case Reoqoo_AppHost
        /// 插件请求地址 String
        case Reoqoo_DophigoPluginHost
        /// H5 请求地址 String
        case Reoqoo_H5Host
        /// H5 DEBUG 模式 Bool
        case Reoqoo_H5DebugMode

        /// 强开云服务入口
        case Reoqoo_IsForceOpenVasEntrance
        /// 强开4G流量入口
        case Reoqoo_IsForceOpen4GFluxEntrance

        /// 强开设备权限管理功能
        case Reoqoo_IsSharePermissionConfigurationSupport

        // 用户选择的地区信息 Dictionary<String, String>
        case Reoqoo_UserSelectedRegionInfo
        // wifi 连接信息 Dictionary<String, String>
        case Reoqoo_WiFiConnectionInfo
        // 首次使用 app 需要弹出用户协议弹框, 记录一下同意协议的版本号 String
        case Reoqoo_AgreeToUsageAgreementOnAppVersion
        /// 指定的语言( 写在 NSBundle+Language.m 中 ), swift 代码没有直接使用此值, 此处声明仅做备忘用
        case Reoqoo_AssignLanguage

        /// 最近执行迁移操作的版本
        case Reoqoo_MigrationRecord
    }

    // UserDefaults 用户相关信息 Key, 跟用户绑定
    // 每个 User 对象下有专属 UserDefaults.init(suiteName: User.id) 对象用户存储相关数据, 换言之, 每个 User 下的 UserDefaults 存储的数据都是独立的
    enum UserKey: String {

        /// 记录上次 AccessToken 更新时间 Double
        case Reoqoo_LatestUpdateAccessTokenTime
        
        /// 首次查看看家新手引导数据记录 Data 类型的: [BeginnerGuidance.ShowRecordInfo] 数据
        case Reoqoo_BeginnerGuidanceInfo

        /// 看家直播画面布局方式, 类型为 Int, 映射枚举类型 `LiveViewContainer.LayoutMode`
        case Reoqoo_LiveViewLayoutMode
    }
}
