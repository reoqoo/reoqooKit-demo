//
//  KeyWindow.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 25/7/2023.
//

import UIKit

/// ~~负责 摇一摇 弹出 debug 助手功能~~
/// 在多屏幕需求出现之前, 此 Window 实例仅有一份, 且生命周期由 AppDelegate 或 SceneDelegate 管理, AppEntranceManager 也会持有此 Window 实例, 掌握生命周期
class KeyWindow: UIWindow {

    let disposeBag: DisposeBag = .init()

    override var canBecomeFirstResponder: Bool { true }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

}
