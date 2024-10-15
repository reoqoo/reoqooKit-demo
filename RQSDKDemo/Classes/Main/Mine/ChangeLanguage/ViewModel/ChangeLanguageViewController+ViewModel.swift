//
//  ViewModel.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 12/9/2023.
//

import Foundation

extension ChangeLanguageViewController {

    enum TableViewCellItem: CustomStringConvertible, Equatable {
        case baseOnSystem
        case assign(IVLanguageCode)

        var description: String {
            switch self {
            case .baseOnSystem:
                return String.localization.localized("AA0272", note: "跟随系统语言")
            case let .assign(langCode):
                return langCode.translate
            }
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            if case .baseOnSystem = lhs, case .baseOnSystem = rhs {
                return true
            }

            if case let .assign(langCode_lhs) = lhs, case let .assign(langCode_rhs) = rhs {
                return langCode_lhs.rawValue == langCode_rhs.rawValue
            }

            return false
        }

        static func from(langCode: IVLanguageCode?) -> Self {
            guard let langCode = langCode else { return .baseOnSystem }
            return .assign(langCode)
        }
    }

    class ViewModel {

        lazy var selectedRow: Int = {
            guard let assignLang = Bundle.assignLanguage() else {
                return 0
            }
            let ivLangCode = IVLanguageCode.from(nanoCode2: assignLang)
            let item = TableViewCellItem.from(langCode: ivLangCode)
            return self.dataSource.firstIndex(where: { item == $0 }) ?? 0
        }()

        let dataSource: [TableViewCellItem] = [.baseOnSystem, .assign(.CN), .assign(.TC), .assign(.EN), .assign(.TH), .assign(.VI), .assign(.JA), .assign(.KO), .assign(.ID), .assign(.MS)]

        func changeLanguage(at: Int) {
            let item = self.dataSource[at]
            if case .baseOnSystem = item {
                Bundle.setAssignLanguage(nil)
            }
            if case let .assign(ivCode) = item {
                Bundle.setAssignLanguage(ivCode.nanoCode2)
            }
        }
    }

}
