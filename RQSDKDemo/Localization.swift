//
//  Localization.swift
//  RQCore
//
//  Created by xiaojuntao on 25/9/2024.
//

import Foundation

extension String {

    public class Localization {

        let bundle: Bundle
        /// which bundle's localization files want load
        init(bundle: Bundle) {
            self.bundle = bundle
        }

        lazy var englishLocalizationFile = Bundle.init(path: self.bundle.path(forResource: "en", ofType: "lproj")!)

        /// 语言国际化
        ///
        ///     Localized("AA0111", note: "密码错误")
        ///
        /// - Parameters:
        ///   - key: 键值
        ///   - note: 注释信息，为便于阅读代码请传入中文注释
        ///   - args: 字符串中要替换的参数值, 例如: "My name is %@, i'm %ld years old"
        /// - Returns: 翻译文案
        public func localized(_ key: String, note: String, args: String...) -> String {
            var translation = NSLocalizedString(key, comment: note)
            if translation.isEmpty || translation == key || translation == "null" {
                translation = self.englishLocalizationFile?.localizedString(forKey: key, value: nil, table: "Localizable") ?? note
                if translation.isEmpty || translation == key || translation == "null" {
                    translation = note
                }
            }
            translation = String(format: translation, arguments: args)
            return translation
        }
    }

    static var localization: Localization = {
        return .init(bundle: Bundle.main)
    }()
}
