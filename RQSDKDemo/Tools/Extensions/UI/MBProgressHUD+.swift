//
//  MBProgressHUD+.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 28/7/2023.
//

import Foundation

private var MBPrpgressHUDKeyboardObserverDisposeBagKey: Void?

// 拷贝自 Yoosee IVProgressHUD
extension MBProgressHUD {

    /// 弱指针数组, 存储着被显示的HUD, 通过 fromTag(_ tag: Int) 在外部获取
    private static var hudCollector: NSHashTable<MBProgressHUD> = .init(options: .weakMemory)

    /// 尝试获取被设置了 tag 的 hud
    public static func fromTag(_ tag: Int) -> MBProgressHUD? {
        while let hud = Self.hudCollector.objectEnumerator().nextObject() as? MBProgressHUD, hud.tag == tag {
            return hud
        }
        return nil
    }

    /// 显示 HUD
    /// - Parameters:
    ///   - text: text
    ///   - icon: icon
    ///   - view: 在哪个 View 显示
    ///   - mask: 是否需要背景
    ///   - delay: 自动 dismiss
    ///   - autoAdjustOffset: 如遇键盘遮挡, 自动调整 offset.y 以避免遮挡
    /// - Returns: MBProgressHUD
    @discardableResult
    static func showHUD_DispatchOnMainThread(text: String, icon: UIImage? = nil, inView view: UIView? = nil, isMask mask: Bool = false, autoDismissAfter delay: TimeInterval = 3, autoAdjustOffset: Bool = true) -> MBProgressHUD {
        if !Thread.current.isMainThread {
            var obj: MBProgressHUD?
            DispatchQueue.main.sync {
                obj = Self.showHUD_DispatchOnMainThread(text: text, icon: icon, inView: view, isMask: mask, autoDismissAfter: delay)
            }
            return obj!
        }

        let showView = view ?? AppEntranceManager.shared.keyWindow!
        let hud = MBProgressHUD.showAdded(to: showView, animated: true)
        hud.bezelView.style = .solidColor
        hud.bezelView.color = R.color.hudBackground()!
        hud.bezelView.layer.cornerRadius = 18
        hud.contentColor = .white
        hud.label.font = .systemFont(ofSize: 14)
        hud.offset = .init(x: 0, y: showView.bounds.height * 0.5 - showView.safeAreaInsets.bottom - 64)
        hud.margin = 10
        hud.label.text = text
        hud.label.numberOfLines = 0

        if let icon = icon {
            hud.customView = UIImageView(image: icon)
            hud.mode = .customView
        } else {
            hud.mode = .text
        }

        if mask {
            hud.backgroundView.color = UIColor(white: 0, alpha: 0.4)
            hud.isUserInteractionEnabled = true
        } else {
            hud.isUserInteractionEnabled = false
        }

        if autoAdjustOffset {
            hud.observeKeyBoardFrame()
        }

        hud.removeFromSuperViewOnHide = true
        hud.hideDispatchOnMainThread(afterDelay: delay)
        return hud
    }

    @discardableResult
    static func showLoadingHUD_DispatchOnMainThread(text: String? = nil, inView view: UIView? = nil, isMask mask: Bool = false, autoDismissAfter delay: TimeInterval = 0, tag: Int? = nil) -> MBProgressHUD {
        if !Thread.current.isMainThread {
            var obj: MBProgressHUD!
            DispatchQueue.main.sync {
                obj = Self.showLoadingHUD_DispatchOnMainThread(text: text, inView: view, isMask: mask, autoDismissAfter: delay)
            }
            return obj
        }
        let showView = view ?? AppEntranceManager.shared.keyWindow!
        let hud = MBProgressHUD.showAdded(to: showView, animated: true)
        hud.bezelView.style = .solidColor
        hud.bezelView.color = R.color.hudBackground()!
        hud.contentColor = .white
        hud.label.font = .systemFont(ofSize: 14)
        hud.label.text = text
        hud.label.numberOfLines = 0
        hud.mode = .indeterminate
        if mask {
            hud.backgroundView.color = UIColor(white: 0, alpha: 0.4)
            hud.isUserInteractionEnabled = true
        } else {
            hud.isUserInteractionEnabled = false
        }
        hud.removeFromSuperViewOnHide = true
        // 如果 tag 非空, 放入 hudCollector
        if let tag = tag {
            hud.tag = tag
            Self.hudCollector.add(hud)
        }
        if delay > 0 {
            hud.hideDispatchOnMainThread(afterDelay: delay)
        }
        return hud
    }

    func hideDispatchOnMainThread(afterDelay: TimeInterval = 0) {
        DispatchQueue.main_async_safe {
            self.hide(animated: true, afterDelay: afterDelay)
        }
    }

    /// 监听键盘弹出, 以避免 HUD 被键盘遮挡
    fileprivate func observeKeyBoardFrame() {
        let disposeBag = DisposeBag()

        AppEntranceManager.shared.$currentKeyboardStatus.observe(on: MainScheduler.asyncInstance).bind { [weak self] keyboardStatus in
            guard let self = self else { return }
            if keyboardStatus.isShow {
                // 键盘显示
                self.offset = .init(x: 0, y: self.bounds.height * 0.5 - keyboardStatus.frame.height - 44)
            }else{
                // 键盘隐藏
                self.offset = .init(x: 0, y: self.bounds.height * 0.5 - self.safeAreaInsets.bottom - 64)
            }
        }.disposed(by: disposeBag)

        objc_setAssociatedObject(self, &MBPrpgressHUDKeyboardObserverDisposeBagKey, disposeBag, .OBJC_ASSOCIATION_RETAIN)
    }
}
