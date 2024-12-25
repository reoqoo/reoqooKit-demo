//
//  UIApplication+Key.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 19/7/2023.
//

import Foundation

extension UIApplication {
    enum Key {}
    
    /// appName
    static let appName = "reoqoo.ios"

    // 反馈邮件
    static let feedbackContractEmail: String = "c-service@reoqoo.com"

}

extension UIApplication.Key {
    enum Bugly {
        static let appID = "c4c7e120ae"
        static let appKey = "af233192-1ae2-442d-844d-d47895ee7af5"
    }
}

// MARK: 网络请求相关信息定义
extension UIApplication {

    /// IotVideo App ID
    static let iotVideoAppID                = "00009a327a04385853251b2bb2303dee"
    /// IotVideo App Token
    static let iotVideoAppToken             = "03f17fdfd3afb6be5b608094bbfaa33a4aa801a6e58f336433ebb0526b20096a"
    /// p2p地址
    static let p2pHost                      = "|list.iotvideo.cloudlinks.cn"

    /// IotVideo 主域名 (生产环境)
    static let iotVideoHost                 = "https://openapi.reoqoo.com"
    /// IotVideo 主域名 (测试环境)
    static let iotVideoHost_DEBUG            = "https://openapi-test.reoqoo.com"
    
    /// DophiGo插件sass主域名 (生产环境)
    static let dophigoPluginSassHost        = "https://openapi-plugin.reoqoo.com"
    /// DophiGo插件sass主域名 (测试环境)
    static let dophigoPluginSassHost_DEBUG   = "https://openapi-test-plugin.reoqoo.com"
    
    /// H5 host
    static let h5Host = "https://trade.reoqoo.com"
    /// H5 host 测试环境
    static let h5HostDebug = "https://trade-test.reoqoo.com"

    /// 网络请求 / js交互 传给服务器的版本号
    static let businessAppVersion: String = {
        let version = "7.98" + "." + Bundle.majorVersion
        // 分割为 ["7", "98", "1", "0"] 表示 7.98.主版本号.次版本号.修订号
        return version.split(separator: ".").map { String.init($0) }
        // 不足两位补零 -> ["07", "98", "01", "00"]
            .map({ String.init(format: "%02d", Int.init($0, radix: 10) ?? 0) })
        // 组合为 07.98.主版本号.次版本号.修订号
            .joined(separator: ".")
    }()

    /// APP的网络请求参数
    static var appNetworkParams: IVNetworkParams {
        // 
        let isDebug     = false
        let params      = IVNetworkParams()
        params.platform = .reoqoo
        params.pkgName  = Bundle.appIdentifier
        params.appName  = UIApplication.appName
        params.host     = StandardConfiguration.shared.appHost
        params.isDebug  = isDebug
        return params
    }
}
