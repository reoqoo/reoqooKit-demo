//
//  ResponseHandler.swift
//  RQSDKDemo
//
//  Created by chenchangxin on 2023/8/16.
//

import Foundation

/// 对网络请求回调中接收到的 jsonStr 以及 error 进行处理, 往外抛出 JSON / Decoable 模型
/// 对错误码进行拦截, 组建 ReoqooError 类型的 error
/// 对特定错误码进行拦截, 例如用户已注销. 发送通知, 使用户登出
enum ResponseHandler {

    /// sass层接口应答数据解析，返回data的model对象，如：["code": 0, "msg": xxx, "data": xxx]
    /// - Parameters:
    ///   - to: response.data中对应model
    ///   - json: response的json
    ///   - error: response的error
    ///   - successCode: 成功code，默认 []
    /// - Returns: 返回Result<T, Error>
    static func responseDecode<T:Codable>(to: T.Type, json: String?, error: Error?, successCode: [Int] = []) -> Result<T, Error> {

        let res = Self.responseHandling(jsonStr: json, error: error)

        guard case let .success(json_) = res else {
            return .failure(error!)
        }

        let code = json_["code"].intValue
        let msg  = json_["msg"].stringValue

        if code != 0 && successCode.filter({ $0 == code }).count == 0 { //如果没有匹配到code成功值，则不解析model
            return .failure(Error(code: code, description: msg))
        }

        do {
            let model = try json_["data"].decoded(as: T.self)
            return .success(model)
        } catch let err {
            return .failure(err)
        }
    }

    /// sass层接口应答基本数据解析，返回第一层级别model对象，如：["code": 0, "msg": xxx, "data": xxx]
    /// - Parameters:
    ///   - json: response的json
    ///   - error: response的error
    ///   - successCode: 成功code，默认 []
    /// - Returns: 返回Result<T, Error>
    static func responseHandling(jsonStr: String?, error: Error?, rangeOfSuccess: [Int] = []) -> Result<JSON, Swift.Error> {

        let res = Self.responseHandling(jsonStr: jsonStr, error: error)

        guard case let .success(json_) = res else {
            return res
        }

        let code = json_["code"].intValue
        let msg = json_["msg"].stringValue

        // 如果 code 不在 successCode 范围内, 则定义为错误
        if code != 0 && rangeOfSuccess.filter({ $0 == code }).count == 0 { //如果没有匹配到code成功值，则不解析model
            return .failure(Error(code: code, description: msg))
        }

        return res
    }

    /// IVNetworkResponseHandler 是携带两个参数的网络请求结果闭包: (jsonStr: String?, err: Swift.Error?)
    /// 因为 jsonStr 和 err 参数都是 optional, 所以在处理这个闭包回调时就很麻烦, 需要判断 err 是否为空, jsonStr 是否为空
    /// 此方法将上述操作封装起来
    /// 根据 IVNetworkResponseHandler 调用源头: IVNetwork func request(methodType: urlString: params:_ 函数可见, jsonStr 和 err 不会同时为 nil, 也不会同时 非nil
    static func responseHandling(jsonStr: String?, error: Swift.Error?) -> Result<JSON, Swift.Error> {
        if let error = error {
            // 拦截用户被注销错误, 发通知
            if (error as NSError).code == ReoqooError.AccountErrorReason.userDidClosed.code {
                NotificationCenter.default.post(name: AccountCenter.accountDidCloseNotification, object: nil, userInfo: [AccountCenter.accountDidCloseNotificationUserInfoKey_IsManual: false])
            }
            // 收到 10026 错误码表示 AccessToken 过期, 退出登录
            if (error as NSError).code == ReoqooError.AccountErrorReason.accessTokenDidExpired.code {
                NotificationCenter.default.post(name: AccountCenter.accessTokenDidExpiredNotification, object: nil, userInfo: nil)
            }
            // 根据错误码尝试组建 ReoqooError 类型的 error
            if let reoqooError = ReoqooError.generateFromOther(error, seriesOfReason: [ReoqooError.AccountErrorReason.self, ReoqooError.DeviceShareError.self, ReoqooError.DeviceConnectError.self]) {
                return .failure(reoqooError)
            }
            return .failure(error)
        }
        guard let jsonStr = jsonStr else { return .failure(ReoqooError.generalError(reason: .optionalTypeUnwrapped)) }
        return .success(JSON.init(parseJSON: jsonStr))
    }
}

