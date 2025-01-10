//
//  MJRefreshComponent+Rx.swift
//  Reoqoo
//
//  Created by xiaojuntao on 28/9/2023.
//

import Foundation
import MJRefresh
import RxSwift
import RxCocoa

extension Reactive where Base: MJRefreshComponent {
    //正在刷新事件
    public var refreshing: ControlEvent<Void> {
        let source: Observable<Void> = Observable.create {
            [weak control = self.base] observer  in
            if let control = control {
                control.refreshingBlock = {
                    observer.on(.next(()))
                }
            }
            return Disposables.create()
        }
        return ControlEvent(events: source)
    }

    //停止刷新
    public var endRefreshing: Binder<Bool> {
        Binder(base) { refresh, isEnd in
            if isEnd {
                refresh.endRefreshing()
            }
        }
    }
}
