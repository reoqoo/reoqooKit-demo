//
//  UNUserNotificationCenter+Rx.swift
//  Reoqoo
//
//  Created by xiaojuntao on 19/9/2023.
//

import Foundation
import RxSwift

extension UNUserNotificationCenter {
    public static func getNotificationSettingsObservable() -> Single<UNNotificationSettings> {
        .create { observer in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                observer(.success(settings))
            }
            return Disposables.create()
        }.observe(on: MainScheduler.asyncInstance)
    }
}
