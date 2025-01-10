//
//  RxSwift+PublishedPropertyWrapper.swift
//  Reoqoo
//
//  Created by xiaojuntao on 26/7/2023.
//

import Foundation
import RxSwift

/*
 仿照 Swift.Combine 提供的 @Published 的做法, 提供 projectedValue 以便通过 $value 访问属性变化的发布者
 */
@propertyWrapper
public class RxBehavioral<T> {

    public var wrappedValue: T {
        didSet {
            // 当 wrappedValue 发生变化, 发布者发布事件
            self.projectedValue.onNext(self.wrappedValue)
        }
    }

    public lazy var projectedValue: RxSwift.BehaviorSubject<T> = .init(value: self.wrappedValue)

    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }

}

/// RxPublished 和 RxBehavioral 的区别是:
/// RxBehavioral: 当订阅者对其进行订阅后, 马上接收到该发布者的最新元素
/// RxPublished: 当订阅者对其进行订阅后, 不会马上接受到该发布者的最新元素
@propertyWrapper
public class RxPublished<T> {

    public var wrappedValue: T {
        didSet {
            // 当 wrappedValue 发生变化, 发布者发布事件
            self.projectedValue.onNext(self.wrappedValue)
        }
    }

    public lazy var projectedValue: RxSwift.PublishSubject<T> = .init()

    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }

}
