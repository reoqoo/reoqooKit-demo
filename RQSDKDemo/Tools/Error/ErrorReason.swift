//
//  ErrorReason.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 9/8/2023.
//

import Foundation

protocol ReoqooErrorReason: CaseIterable {
    var code: Int { get }
    var description: String { get }
    var domain: String? { get }
}

extension ReoqooErrorReason {

    var domain: String? { String.init(describing: Self.self) }

    static func from(_ code: Int) -> (any ReoqooErrorReason)? {
        Self.allCases.filter({ $0.code == code }).first
    }

}

extension ReoqooError {

    /// 自定义错误Reason
    struct CustomErrorReason: ReoqooErrorReason, Equatable {

        static var allCases: [ReoqooError.CustomErrorReason] = []

        var code: Int
        var description: String
        init(code: Int, description: String) {
            self.code = code
            self.description = description
        }
    }

    // 通用场景 error
    enum GeneralErrorReason: Int, ReoqooErrorReason {
        /// Optional unwrapped Error
        case optionalTypeUnwrapped = 101
        /// 扫描二维码识别结果为空
        case recognizeQRCodeEmptyResult = 102
        /// 初始化手机摄像头失败
        case cannotInitCameraDevice = 103
        /// 压缩文件操作失败
        case zipFileFailure = 104
        /// 用户未登录
        case userIsLogout = 105
        /// 未定义的错误
        case undefineError = 99999999

        var code: Int { self.rawValue }
        var description: String {
            switch self {
            case .undefineError:
                return String.localization.localized("AA0532", note: "操作失败")
            case .optionalTypeUnwrapped:
                return String.localization.localized("AA0532", note: "操作失败")
            case .recognizeQRCodeEmptyResult:
                return String.localization.localized("AA0478", note: "不支持的二维码")
            case .cannotInitCameraDevice:
                return String.localization.localized("AA0068", note: "没有相机权限，请在设置中开启")
            case .zipFileFailure:
                return String.localization.localized("AA0532", note: "操作失败")
            case .userIsLogout:
                return String.localization.localized("AA0532", note: "操作失败")
            }
        }
    }

    // 账号中心相关(登录, 注册, 修改用户信息) error
    enum AccountErrorReason: Int, ReoqooErrorReason {
        /// 两次输入的密码不一致
        case confirmPasswordError = 106
        /// 密码格式不正确 (需要字母+数字组合)
        case passwordFormatError = 107
        /// 昵称包含非法字符
        case nickNameContainInvalidCharacter = 108
        /// AccessToken 过期了, 退出登录
        case accessTokenDidExpired = 10026
        /// 验证码发送失败
        case sendOneTimeCodeFailure = 12004
        /// 密码错误
        case passwordError = 12005
        /// 账号不存在
        case accountIsNotExist = 12013
        /// 新密码和旧密码相同
        case newPasswordIsTheSameAsOldPassword = 12018
        /// 手机号已被注册
        case telephoneHaveBeenRegistered = 10902020
        /// 邮箱已被注册
        case emailHaveBeenRegistered = 10902021
        /// 手机号码非法
        case invalidTelephone = 10901022
        /// 国家码不支持发送手机短信
        case regionIsNotSupportSMSSending = 10902019
        /// 登录账号或密码错误
        case loginPasswordError = 10902011
        /// 用户被注销了
        case userDidClosed = 10902013
        /// 达到验证码请求上限
        case verifyCodeLimited = 10902026

        var code: Int { self.rawValue }
        var description: String {
            switch self {
            case .newPasswordIsTheSameAsOldPassword:
                return String.localization.localized("AA0575", note: "旧密码和新密码一样")
            case .passwordFormatError:
                return String.localization.localized("AA0396", note: "密码为8-30位包含字母、数字的字符")
            case .nickNameContainInvalidCharacter:
                return String.localization.localized("AA0288", note: "昵称不能包含特殊符号")
            case .accessTokenDidExpired:
                return String.localization.localized("AA0283", note: "退出登录")
            case .accountIsNotExist:
                return String.localization.localized("AA0033", note: "账号不存在")
            case .confirmPasswordError:
                return String.localization.localized("AA0373", note: "两次输入不一致")
            case .telephoneHaveBeenRegistered:
                return String.localization.localized("AA0382", note: "手机号码已被使用")
            case .emailHaveBeenRegistered:
                return String.localization.localized("AA0525", note: "邮箱已被使用")
            case .regionIsNotSupportSMSSending:
                return String.localization.localized("AA0523", note: "国家码不支持发送手机短信")
            case .loginPasswordError:
                return String.localization.localized("AA0013", note: "账号或密码错误")
            case .userDidClosed:
                return String.localization.localized("AA0522", note: "账号已注销")
            case .sendOneTimeCodeFailure:
                return String.localization.localized("AA0391", note: "发送验证码失败")
            case .passwordError:
                return String.localization.localized("AA0294", note: "旧密码错误")
            case .verifyCodeLimited:
                return String.localization.localized("AA0386", note: "已经达到上限")
            case .invalidTelephone:
                return String.localization.localized("AA0564", note: "手机号/邮箱格式错误")
            }
        }
    }

    /// 配网 error
    enum DeviceConnectError: Int, ReoqooErrorReason {
        /// 蓝牙没授权
        case bluetoothNoAuthority = 107
        /// 蓝牙设备扫描超时
        case bluetoothPeripheralScanningTimeOver = 108
        /// 设备类型不匹配
        case deviceTypeNotMatchable = 109
        /// 没有本地网络访问权限
        case localNetworkAccessFailure = 110
        /// 监听设备上线操作超时
        case observeDeviceOnlineOperationTimeOut = 111
        /// wifi 连接信息不完整
        case wifiConnectionInfoIncomplete = 112
        /// 生成设备二维码失败
        case createDeviceQRCodeFailure = 113
        /// ap wifi 连接不正确
        case apWifiConnectError = 114
        /// 通过 ProductID 匹配 ProductTemplate 时, 找不到匹配的 ProductTemplate
        case matchableProductTemplateNotFound = 115
        /// 从 "配置表.json" 中取得的最低app版本号和大于app当前版本, 不允许配网
        case appVersionNotSupport = 116
        /// 设备没连接互联网
        case deviceIsNotConnected2Internet = 117
        /// 设备不能被绑定
        case deviceCanNotBeBind = 118
        /// 配网token 过期
        case bindTokenExpired = 21101
        /// 已是设备主人
        case deviceHaveAlreadyBeenBind = 10905009
        
        var code: Int { self.rawValue }
        var description: String {
            switch self {
            case .bluetoothNoAuthority:
                return String.localization.localized("AA0076", note: "没有蓝牙权限，请在设置中开启")
            case .bluetoothPeripheralScanningTimeOver:
                return String.localization.localized("AA0389", note: "连接超时,请检查网络")
            case .deviceTypeNotMatchable:
                return String.localization.localized("AA0532", note: "操作失败")
            case .localNetworkAccessFailure:
                return String.localization.localized("AA0557", note: "没有本地局域网设备访问权限，请在设置中开启")
            case .observeDeviceOnlineOperationTimeOut:
                return String.localization.localized("AA0389", note: "连接超时,请检查网络")
            case .wifiConnectionInfoIncomplete:
                return String.localization.localized("AA0440", note: "Wi-Fi连接超时")
            case .createDeviceQRCodeFailure:
                return String.localization.localized("AA0558", note: "创建设备二维码失败")
            case .apWifiConnectError:
                return String.localization.localized("AA0440", note: "Wi-Fi连接超时")
            case .matchableProductTemplateNotFound:
                return String.localization.localized("AA0478", note: "不支持的二维码")
            case .appVersionNotSupport:
                return String.localization.localized("AA0499", note: "当前APP版本过低,无法兼容此款新设备。")
            case .bindTokenExpired:
                return String.localization.localized("AA0389", note: "连接超时,请检查网络")
            case .deviceIsNotConnected2Internet:
                // 此错误不需要显示错误信息
                return String.localization.localized("AA0167", note: "添加失败")
            case .deviceCanNotBeBind:
                return String.localization.localized("AA0167", note: "添加失败")
            case .deviceHaveAlreadyBeenBind:
                return String.localization.localized("AA0387", note: "该设备已被其他账户绑定,需要解绑才能继续使用")
            }
        }
    }
    
    /// 分享 error
    enum DeviceShareError: Int, ReoqooErrorReason {
        /// 通用错误
        case common = 99
        /// 账号不存在
        case accountNonExistent = 10902004
        /// 账号不可用
        case accountInvalid = 10902013
        /// 系统中找不到账号(未注册)
        case accountIsNotInTheSystem = 10905020
        /// 目标用户不可用（账号注销或冻结）
        case accountIsNotInTheSystem2 = 10905021
        /// 不支持跨区域分享
        case notSupportSpanned = 10905022
        /// 已是设备主人
        case alreadyMaster = 10905009
        /// 访客已存在
        case guestAlreadyExistent = 10905010
        /// 扫描到的二维码已过期
        case qrcodeIsExpired = 11044
        /// 设备分享访客数量超出最大限制
        case deviceGuestNumLimit = 11048
        /// 访客邀请码过期了 (从消息中心试图接受过期的邀请会遇到)
        case invitationIsExpired = 11049
        
        var code: Int { self.rawValue }
        var description: String {
            switch self {
            case .common: 
                return ""
            case .accountNonExistent:
                return String.localization.localized("AA0033", note: "账号不存在")
            case .accountIsNotInTheSystem:
                return String.localization.localized("AA0033", note: "账号不存在")
            case .accountIsNotInTheSystem2:
                return String.localization.localized("AA0033", note: "账号不存在")
            case .accountInvalid:
                return String.localization.localized("AA0566", note: "目标账号不可用")
            case .notSupportSpanned:
                return String.localization.localized("AA0172", note: "您和主人不是同一区域，不支持分享")
            case .alreadyMaster:
                return String.localization.localized("AA0392", note: "已是设备主人")
            case .guestAlreadyExistent:
                return String.localization.localized("AA0155", note: "已经分享给该好友了")
            case .deviceGuestNumLimit:
                return String.localization.localized("AA0515", note: "每个设备最多10个访客")
            case .qrcodeIsExpired:
                return String.localization.localized("AA0514", note: "您扫描到的二维码已过期")
            case .invitationIsExpired:
                return String.localization.localized("AA0168", note: "分享失效，可让主人重新分享")
            }
        }
    }

    /// 设备升级 Error
    enum DeviceFirmwareUpgradeErrorReason: Int, ReoqooErrorReason {

        // 客户端定义
        /// 其他（自定义-100类型）
        case other = 100
        /// 请求错误
        case networkError = 101
        /// 设备离线
        case deviceOffline = 102
        /// 操作太频繁
        case operationDuplicate = 103
        /// 版本比对不通过 (新版本 小于或等于 旧版本)
        case versionCompareFailure = 104
        /// 经过超时时间后, 仍然检查不到设备已升级到目标版本, 超时错误
        case operationTimeOut = 105

        // 固件定义
        /// 固件下载失败 文件太小
        case downloadFileTooSmart = -1
        /// 固件下载失败 文件太大
        case downloadFileTooBig = -2
        /// SD卡出错 保存文件失败
        case saveFileFail = -3
        /// SD卡出错 创建文件失败
        case createFileFail = -4
        /// 链接地址有误
        case urlError = -5
        /// 连接服务器异常
        case connectServiceFail = -6
        /// 请求下载异常
        case requestDownloadFail = -7
        /// 下载超时
        case downloadTimeOut = -8
        /// app拒绝升级
        case appRejectUpgrade = -9
        /// 模块繁忙（升级中）
        case moduleBusy = -10
        /// 模块退出
        case moduleExit = -11
        /// 文件无权限
        case fileNotAccess = -12
        /// 电量过低
        case lowElectricity = -33

        var code: Int { self.rawValue }
        var description: String {
            switch self {
            case .networkError:
                return String.localization.localized("AA0389", note: "连接超时,请检查网络")
            case .deviceOffline:
                return String.localization.localized("AA0380", note: "设备离线")
            case .operationDuplicate:
                return String.localization.localized("AA0395", note: "操作频繁,请稍后再试")
            case .other:
                return String.localization.localized("AA0539", note: "升级失败，请稍后重试")
            case .downloadFileTooSmart, .downloadFileTooBig:
                return String.localization.localized("AA0540", note: "下载失败，请稍后重试")
            case .saveFileFail, .createFileFail:
                return String.localization.localized("AA0541", note: "升级失败，请重启设备或插入内存卡重试")
            case .urlError:
                return String.localization.localized("AA0539", note: "升级失败，请稍后重试")
            case .connectServiceFail, .requestDownloadFail, .downloadTimeOut:
                return String.localization.localized("AA0542", note: "下载失败，请检查设备网络后重试")
            case .appRejectUpgrade, .moduleExit, .fileNotAccess:
                return String.localization.localized("AA0543", note: "升级失败，请重启设备后重试")
            case .lowElectricity:
                return String.localization.localized("#", note: "摄像机电量过低,请在电量充足的状态下升级~")
            case .moduleBusy:   // 升级中
                return ""
            case .versionCompareFailure:
                return String.localization.localized("AA0539", note: "升级失败，请稍后重试")
            case .operationTimeOut:
                return String.localization.localized("AA0539", note: "升级失败，请稍后重试")
            }
        }
    }
}
