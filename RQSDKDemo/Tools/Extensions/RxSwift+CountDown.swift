//
//  RxSwift+CountDown.swift
//  Reoqoo
//
//  Created by xiaojuntao on 31/7/2023.
//

import Foundation
import RxSwift

extension Reactive where Base: Timer {

    /// 创建一个倒数发布者
    /// - Parameters:
    ///   - seconds: 倒数总秒数
    ///   - immediately: 是否马上开始.
    ///         false: 会在 `every` 秒后再开始
    ///   - every: 每多少秒响应一次
    ///   - scheduler: 队列
    /// - Returns: Observable<Int>
    public static func countDown(seconds: Int, immediately: Bool = false, every: Int = 1, scheduler: SchedulerType) -> Observable<Int> {
        guard every != 0 else { fatalError("Parameter `every` can not be zero") }
        return Observable<Int>.create { observer -> Disposable in
            let disposable = Observable<Int>.timer(.seconds(immediately ? 0 : every), period: .seconds(1), scheduler: scheduler).subscribe(onNext: { i in
                if i % every == 0 {
                    observer.onNext(seconds - i)
                }
                if i == seconds {
                    observer.onCompleted()
                }
            })
            return disposable
        }
    }

    /*
     用例1:
     logDebug("~~~~~~~~~~~~~~~~开始~~~~~~~~~~~~~~~~~~~")
     Timer.rx.countDown(seconds: 12, immediately: true, every: 1, scheduler: ConcurrentDispatchQueueScheduler.init(queue: .global())).subscribe { i in
         logDebug("~~~~~~~~~~~~~~~~\(i)~~~~~~~~~~~~~~~~~")
     } onError: { err in

     } onCompleted: {
         logDebug("~~~~~~~~~~~~~~完成~~~~~~~~~~~~~~~~~")
     } onDisposed: {
         logDebug("~~~~~~~~~~~~~DISPOSE~~~~~~~~~~~~~~")
     }.disposed(by: self.disposeBag)

     14:17:07.953 [BK] ~~~~~~~~~~~~~~~~开始~~~~~~~~~~~~~~~~~~~
     14:17:07.954 [BK] ~~~~~~~~~~~~~~~~12~~~~~~~~~~~~~~~~~
     14:17:08.955 [BK] ~~~~~~~~~~~~~~~~11~~~~~~~~~~~~~~~~~
     14:17:09.955 [BK] ~~~~~~~~~~~~~~~~10~~~~~~~~~~~~~~~~~
     14:17:10.955 [BK] ~~~~~~~~~~~~~~~~9~~~~~~~~~~~~~~~~~
     14:17:11.954 [BK] ~~~~~~~~~~~~~~~~8~~~~~~~~~~~~~~~~~
     14:17:12.955 [BK] ~~~~~~~~~~~~~~~~7~~~~~~~~~~~~~~~~~
     14:17:13.955 [BK] ~~~~~~~~~~~~~~~~6~~~~~~~~~~~~~~~~~
     14:17:14.955 [BK] ~~~~~~~~~~~~~~~~5~~~~~~~~~~~~~~~~~
     14:17:15.955 [BK] ~~~~~~~~~~~~~~~~4~~~~~~~~~~~~~~~~~
     14:17:16.955 [BK] ~~~~~~~~~~~~~~~~3~~~~~~~~~~~~~~~~~
     14:17:17.955 [BK] ~~~~~~~~~~~~~~~~2~~~~~~~~~~~~~~~~~
     14:17:18.954 [BK] ~~~~~~~~~~~~~~~~1~~~~~~~~~~~~~~~~~
     14:17:19.954 [BK] ~~~~~~~~~~~~~~完成~~~~~~~~~~~~~~~~~
     14:17:19.955 [BK] ~~~~~~~~~~~~~DISPOSE~~~~~~~~~~~~~~

     用例2:
     logDebug("~~~~~~~~~~~~~~~~开始~~~~~~~~~~~~~~~~~~~")
     Timer.rx.countDown(seconds: 12, immediately: true, every: 5, scheduler: ConcurrentDispatchQueueScheduler.init(queue: .global())).subscribe { i in
         logDebug("~~~~~~~~~~~~~~~~\(i)~~~~~~~~~~~~~~~~~")
     } onError: { err in

     } onCompleted: {
         logDebug("~~~~~~~~~~~~~~完成~~~~~~~~~~~~~~~~~")
     } onDisposed: {
         logDebug("~~~~~~~~~~~~~DISPOSE~~~~~~~~~~~~~~")
     }.disposed(by: self.disposeBag)

     14:19:29.731 [BK] ~~~~~~~~~~~~~~~~开始~~~~~~~~~~~~~~~~~~~
     14:19:29.732 [BK] ~~~~~~~~~~~~~~~~12~~~~~~~~~~~~~~~~~
     14:19:34.733 [BK] ~~~~~~~~~~~~~~~~7~~~~~~~~~~~~~~~~~
     14:19:39.733 [BK] ~~~~~~~~~~~~~~~~2~~~~~~~~~~~~~~~~~
     14:19:41.733 [BK] ~~~~~~~~~~~~~~完成~~~~~~~~~~~~~~~~~
     14:19:41.733 [BK] ~~~~~~~~~~~~~DISPOSE~~~~~~~~~~~~~~
     */
}
