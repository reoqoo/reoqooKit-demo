//
//  PageSheetStyleViewController.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 31/8/2023.
//

import UIKit

/// 提供一个背景透明, 带 contentView 的 ViewController
/// 提供展示时 contentView 的 appear 以及 disappear 的动画
class PageSheetStyleViewController: BaseViewController {

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.modalTransitionStyle = .crossDissolve
        self.modalPresentationStyle = .custom
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.modalTransitionStyle = .crossDissolve
        self.modalPresentationStyle = .custom
    }

    lazy var contentView: UIView = .init().then {
        $0.backgroundColor = R.color.background_FFFFFF_white()!
        $0.layer.cornerRadius = 16
        $0.layer.masksToBounds = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIView.animate(withDuration: 0.3) {
            self.contentView.transform = .identity
            self.view.backgroundColor = R.color.background_000000_40()!
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIView.animate(withDuration: 0.3) {
            self.contentView.transform = .init(translationX: 0, y: self.view.bounds.height)
            self.view.backgroundColor = .clear
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(self.contentView)
        self.layoutContentView()

        // appear 动画
        self.contentView.transform = .init(translationX: 0, y: self.view.bounds.height)
        self.view.backgroundColor = .clear
    }

    /// 供子类重写, 在此方法中对 contentView 进行布局
    func layoutContentView() {
        self.contentView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(16)
            make.height.equalToSuperview().multipliedBy(0.55)
        }
    }
}
