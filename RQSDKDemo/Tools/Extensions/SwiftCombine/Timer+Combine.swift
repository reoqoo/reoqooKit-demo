//
//  Timer+Combine.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 4/9/2024.
//

import Combine
import CombineExt

extension Timer {
    static func countdownPublisher(_ interval: TimeInterval, every: TimeInterval, on: RunLoop = .main, inRunLoopMode: RunLoop.Mode = .common) -> AnyPublisher<Date, Never> {
        var interval = interval
        if interval == TimeInterval.greatestFiniteMagnitude {
            interval = TimeInterval(Int.max)
        }
        var count = Int(floor(interval / every))
        return Publishers.Create<Date, Never>.init { subscriber in
            Timer.publish(every: every, on: on, in: inRunLoopMode).autoconnect().sink { date in
                subscriber.send(date)
                count -= 1
                if count <= 0 {
                    subscriber.send(completion: .finished)
                }
            }
        }.eraseToAnyPublisher()
    }
}
