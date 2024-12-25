//
//  CombineExt+Create.Subscriber.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 5/9/2024.
//

import CombineExt

extension Publishers.Create.Subscriber {
    /* 使 Subscriber 可以直接将 Result 发送, 下游直接完成订阅操作

     Publishers.Create<JSON, Error> { subscriber in
         IVAccountMgr.default.getNetCfgResult(token: token) {
             let result: Result<JSON, Swift.Error> = ResponseHandler.responseHandling(jsonStr: $0, error: $1)
             // 将 Result<JSON, Swift.Error> 发送出去
             subscriber.send(result: result)
         }
         return AnyCancellable.init {}
     }
     */
    public func send(result: Result<Output, Failure>) {
        if let output = result.value {
            self.send(output)
            self.send(completion: .finished)
        }
        if let err = result.error {
            self.send(completion: .failure(err))
        }
    }
}
