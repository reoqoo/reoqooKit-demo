//
//  Localization.swift
//  RQCore
//
//  Created by xiaojuntao on 25/9/2024.
//

import Foundation

extension String {
    static var localization: String.Localization = {
        return .init(bundle: Bundle.main)
    }()
}
