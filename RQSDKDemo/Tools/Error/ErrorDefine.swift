//
//  ErrorDefine.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 28/7/2023.
//

import Foundation
import NetworkExtension

/*
 LocalizedError 和 CustomNSError 可参考: https://www.jianshu.com/p/a36047852ccc

    let err = (ReoqooError.deviceConnectError(reason: .bindTokenExpired) as NSError)
    print(err.code)                     // 21101
    print(err.description)              // Reoqoo.ReoqooError.deviceConnectError(reason: Reoqoo.ReoqooError.DeviceConnectError.bindTokenExpired)
    print(err.localizedDescription)     // 输出由 ReoqooError.errorDescription 决定
 */
enum ReoqooError: LocalizedError, CustomNSError {

    case customError(reason: CustomErrorReason)
    case generalError(reason: GeneralErrorReason)
    case accountError(reason: AccountErrorReason)
    case deviceConnectError(reason: DeviceConnectError)
    case autoConnectWifiError(_ error: NEHotspotConfigurationError)
    case deviceShareError(_ error: DeviceShareError)
    case deviceFirmwareUpgradeError(_ error: DeviceFirmwareUpgradeErrorReason)
    
    // MARK: LocalizedError
    var errorDescription: String? {
        switch self {
        case .customError(let reason):
            return reason.description
        case .generalError(let reason):
            return reason.description
        case .accountError(let reason):
            return reason.description
        case .deviceConnectError(let reason):
            return reason.description
        case .autoConnectWifiError(let code):
            return NSError.init(domain: NEHotspotConfigurationErrorDomain, code: code.rawValue).description
        case .deviceShareError(let reason):
            return reason.description
        case let .deviceFirmwareUpgradeError(reason):
            return reason.description
        }
    }

    // MARK: CustomNSError
    var errorCode: Int {
        switch self {
        case .customError(let reason):
            return reason.code
        case .generalError(let reason):
            return reason.code
        case .accountError(let reason):
            return reason.code
        case .deviceConnectError(let reason):
            return reason.code
        case .autoConnectWifiError(let reason):
            return reason.rawValue
        case .deviceShareError(let reason):
            return reason.rawValue
        case .deviceFirmwareUpgradeError(let reason):
            return reason.rawValue
        }
    }

    // MARK: Helper
    func isReason(_ targetReason: any ReoqooErrorReason) -> Bool {
        switch self {
        case .customError(let reason):
            return (targetReason as? CustomErrorReason) == reason
        case .accountError(let reason):
            return (targetReason as? AccountErrorReason) == reason
        case .deviceConnectError(let reason):
            return (targetReason as? DeviceConnectError) == reason
        case .generalError(reason: let reason):
            return (targetReason as? GeneralErrorReason) == reason
        case let .deviceFirmwareUpgradeError(reason):
            return (targetReason as? DeviceFirmwareUpgradeErrorReason) == reason
        case .autoConnectWifiError, .deviceShareError:
            return false
        }
    }
    
    /// 尝试从某 error 的 code 组建 ReoqooError
    /// - Parameters:
    ///   - error: 其他 error
    ///   - seriesOfReason: 指定某些原因
    static func generateFromOther(_ error: Swift.Error, seriesOfReason: [any ReoqooErrorReason.Type]? = nil) -> ReoqooError? {
        if let error = error as? ReoqooError { return error }
        var allErrorReasons: [any ReoqooErrorReason] = []
        if let seriesOfReason = seriesOfReason {
            allErrorReasons = seriesOfReason.reduce(into: [any ReoqooErrorReason](), { partialResult, type in
                let reasons = type.allCases.compactMap({ $0 as? (any ReoqooErrorReason) })
                partialResult.append(contentsOf: reasons)
            })
        }else{
            allErrorReasons = AccountErrorReason.allCases + DeviceConnectError.allCases + GeneralErrorReason.allCases +  DeviceFirmwareUpgradeErrorReason.allCases
        }
        guard let reason = allErrorReasons.filter({ $0.code == (error as NSError).code }).first else { return nil }
        return Self.errorFromReason(reason)
    }
    
    /// 从 ReoqooErrorReason 组建 ReoqooError
    static func errorFromReason(_ reason: any ReoqooErrorReason) -> ReoqooError {
        if let reason = reason as? GeneralErrorReason {
            return .generalError(reason: reason)
        }
        if let reason = reason as? AccountErrorReason {
            return .accountError(reason: reason)
        }
        if let reason = reason as? DeviceShareError {
            return .deviceShareError(reason)
        }
        if let reason = reason as? DeviceConnectError {
            return .deviceConnectError(reason: reason)
        }
        if let reason = reason as? DeviceFirmwareUpgradeErrorReason {
            return .deviceFirmwareUpgradeError(reason)
        }
        return .generalError(reason: .undefineError)
    }
}

extension Swift.Result {
    func isReoqooErrorReason(_ targetReson: any ReoqooErrorReason) -> Bool {
        guard case let .failure(err) = self, let err = err as? ReoqooError else { return false }
        return err.isReason(targetReson)
    }
}

func Error(code: Int, description: String = "", domain: String = Bundle.appIdentifier) -> Error {
    return NSError(domain: domain, code: code, userInfo: [NSLocalizedDescriptionKey: description])
}
