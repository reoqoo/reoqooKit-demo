//
//  IVDeviceMgr+Rx.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 19/9/2023.
//

import Foundation
import RQApi

extension RQApi.Api {

    /// 获取设备最新版本发布者
    static func queryDeviceNewVersionObservable(deviceId: String, version: String) -> Single<DeviceNewVersionInfoEntity?> {
        Single<JSON>.create { observer in
            RQApi.Api.checkDeviceNewVersion(deviceId: deviceId, currentVersion: version) {
                let res = ResponseHandler.responseHandling(jsonStr: $0, error: $1)
                observer(res)
            }
            return Disposables.create()
        }.map { json -> DeviceNewVersionInfoEntity? in
            var json = json["data"]
            // 如果版本为空, 表示没有新版本
            if json["version"].stringValue.isEmpty {
                return nil
            }
            // 写入当前时间
            json["checkedTime"] = JSON.init(floatLiteral: Date().timeIntervalSince1970)
            return try json.decoded(as: DeviceNewVersionInfoEntity.self)
        }
    }

}
