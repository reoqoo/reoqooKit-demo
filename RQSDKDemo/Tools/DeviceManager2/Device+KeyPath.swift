//
//  DeviceEntity+KeyPath.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 26/1/2024.
//

import Foundation

extension PartialKeyPath where Root == DeviceEntity {
    var asString: String {
        switch self {
        case \.deviceId: return "deviceId"
        case \.remarkName: return "remarkName"
        case \.role: return "role"
        case \.cloudStatus: return "cloudStatus"
        case \.hasShared: return "hasShared"
        case \.picDays: return "picDays"
        case \.properties: return "properties"
        case \.saas: return "saas"
        case \.gwell: return "gwell"
        case \.dophigo: return "dophigo"
        case \.vss: return "vss"
        case \.fourCard: return "fourCard"
        case \.ai: return "ai"
        case \.custcare: return "custcare"
        case \.freeEvs: return "freeEvs"
        case \.status: return "status"
        case \.presentVersion: return "presentVersion"
        case \.swVersion: return "swVersion"
        case \.deviceListSortID: return "deviceListSortID"
        case \.liveViewSortID: return "liveViewSortID"
        case \.isLiveClose: return "isLiveClose"
        case \.isDeleted: return "isDeleted"
        case \.newVersionInfo: return "newVersionInfo"
        case \.isSupportCloud: return "isSupportCloud"
        case \.productModule: return "productModule"
        case \.productName: return "productName"
        case \.devExpandType: return "devExpandType"
        default: fatalError("DeviceEntity+KeyPath 没有匹配的KeyPath")
        }
    }
}
