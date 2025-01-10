//
//  RxSwift+Operator.swift
//  Reoqoo
//
//  Created by xiaojuntao on 13/9/2023.
//

import Foundation
import RxSwift

extension RxSwift.Observable {
    public func retry(_ maxAttemptCount: Int, period: RxTimeInterval) -> Observable {
        self.catch({ err in
            RxSwift.Observable<Int>.timer(period, scheduler: MainScheduler.asyncInstance).flatMap { _ in
                Observable.error(err)
            }
        }).retry(maxAttemptCount)
    }
    
    /// 将一些会抛出错误的 Observable 进行包装, catch error 使其不会抛出错误
    public func mapAndCatchErrorWrapAsSwiftResult() -> Observable<Swift.Result<Element, Swift.Error>> {
        return self.map { .success($0) }.catch({ .just(.failure($0)) })
    }
}
