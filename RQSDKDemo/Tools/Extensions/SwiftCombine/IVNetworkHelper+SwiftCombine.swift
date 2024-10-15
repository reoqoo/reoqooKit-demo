//
//  IVNetwork+SwiftCombine.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 7/6/2024.
//

import Foundation

extension IVNetworkHelper {
    
    /// `获取ssid操作` 发布者
    var ssidCapturePublisher: AnyPublisher<String, Swift.Error> {
        Combine.Future.init { [weak self] promise in
            self?.getCurrentWiFiSSIDCallback({ ssid in
                promise(.success(ssid))
            })
        }.eraseToAnyPublisher()
    }

    // 获取本地网络访问权限发布者. 也就是对 requestLocalNetworkAuthorization 的 Combine 封装
    static func requestLocalNetworkAuthorizationPublisher() -> AnyPublisher<Bool, Never> {
        if #unavailable(iOS 14) { return Combine.Just.init(true).eraseToAnyPublisher() }
        return Future.init { promise in
            IVNetworkHelper.requestLocalNetworkAuthorization(completion: {
                promise(.success($0))
            })
        }.eraseToAnyPublisher()
    }

}
