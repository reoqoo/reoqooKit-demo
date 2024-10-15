//
//  IVLanguageCode+.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 8/8/2023.
//

import Foundation

extension IVLanguageCode {

    static var current: IVLanguageCode {
        // 如果用户指定了当前语言, 就返回当前语言
        if let assignLanguage = Bundle.assignLanguage(), let res = IVLanguageCode.from(nanoCode2: assignLanguage) {
            return res
        }

        // 否则返回系统当前语言
        guard let languages = UserDefaults.standard.object(forKey: "AppleLanguages") as? [String],
              let currentLang = languages[safe_: 0] else { return .EN }
        // ( zh-Hant-TW, yue-Hant-CN, zh-Hans-CN, en-CN, zh-Hant-HK, en-GB)
        let components = (currentLang.lowercased() as NSString).components(separatedBy: "-")
        guard let firstComponent = components.first else { return .EN }
        let secondComponent = components[safe_: 1]
        for i in LanguageCase.allCases {
            // 先判断第一个 component, 如果符合, 直接返回
            if i.firstPossibleComponents.contains(firstComponent) && i.secondPossibleComponents.isEmpty {
                return i.code
            }
            // 如果第二个 component 非空, 也就是 "hant" 那一段, 包含则返回
            if let secondComponent = secondComponent, i.firstPossibleComponents.contains(firstComponent), i.secondPossibleComponents.contains(secondComponent) {
                return i.code
            }
        }
        return .EN
    }
}
