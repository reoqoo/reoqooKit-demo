//
//  ModifyPasswordViewController.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 15/9/2023.
//

import UIKit

class ModifyPasswordViewController: BaseViewController, ScrollBaseViewAndKeyboardMatchable {

    var scrollable: UIScrollView { self.scrollView }

    var anyCancellables: Set<AnyCancellable> = []

    lazy var scrollView: UIScrollView = .init().then {
        $0.showsVerticalScrollIndicator = true
        $0.alwaysBounceVertical = true
        $0.keyboardDismissMode = .interactive
    }

    lazy var oldPasswordInputTextView: PasswordInputView = .init().then {
        $0.textField.placeholder = String.localization.localized("AA0291", note: "旧密码")
    }

    lazy var newPasswordInputTextView: PasswordInputView = .init().then {
        $0.textField.placeholder = String.localization.localized("AA0292", note: "新密码")
    }

    lazy var confirmPasswordInputTextView: PasswordInputView = .init().then {
        $0.textField.placeholder = String.localization.localized("AA0293", note: "确认新密码")
    }

    lazy var tipLabel: UILabel = .init().then {
        $0.numberOfLines = 0
        $0.font = .systemFont(ofSize: 12)
        $0.textColor = R.color.text_000000_60()
        $0.text = String.localization.localized("AA0025", note: "密码为8～30位包含字⺟、数字的字符")
    }

    lazy var sureBtn: UIButton = .init(type: .custom).then {
        $0.setTitle(String.localization.localized("AA0058", note: "确定"), for: .normal)
        $0.setStyle_0()
        $0.layer.cornerRadius = 23
        $0.layer.masksToBounds = true
    }

    let disposeBag: DisposeBag = .init()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = String.localization.localized("AA0278", note: "修改密码")

        self.dismissKeyboardWhenTapOnNonInteractiveArea()
        self.adjustScrollViewContentInsetWhenKeyboardFrameChanged()

        self.view.backgroundColor = R.color.background_FFFFFF_white()
        self.setNavigationBarBackground(R.color.background_FFFFFF_white()!, tintColor: R.color.text_000000_90()!)

        self.view.addSubview(self.scrollView)
        self.scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.scrollView.addSubview(self.oldPasswordInputTextView)
        self.oldPasswordInputTextView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(48)
            make.trailing.equalToSuperview().offset(-28)
            make.leading.equalToSuperview().offset(28)
            make.height.equalTo(56)
        }

        self.scrollView.addSubview(self.newPasswordInputTextView)
        self.newPasswordInputTextView.snp.makeConstraints { make in
            make.top.equalTo(self.oldPasswordInputTextView.snp.bottom).offset(12)
            make.trailing.equalToSuperview().offset(-28)
            make.leading.equalToSuperview().offset(28)
            make.height.equalTo(56)
        }

        self.scrollView.addSubview(self.confirmPasswordInputTextView)
        self.confirmPasswordInputTextView.snp.makeConstraints { make in
            make.top.equalTo(self.newPasswordInputTextView.snp.bottom).offset(12)
            make.trailing.equalToSuperview().offset(-28)
            make.leading.equalToSuperview().offset(28)
            make.height.equalTo(56)
        }

        self.scrollView.addSubview(self.tipLabel)
        self.tipLabel.snp.makeConstraints { make in
            make.top.equalTo(self.confirmPasswordInputTextView.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(28)
            make.trailing.equalToSuperview().offset(-28)
        }

        self.scrollView.addSubview(self.sureBtn)
        self.sureBtn.snp.makeConstraints { make in
            make.top.equalTo(self.tipLabel.snp.bottom).offset(56)
            make.leading.equalToSuperview().offset(28)
            make.trailing.equalToSuperview().offset(-28)
            make.height.equalTo(46)
            make.width.equalTo(self.view.snp.width).offset(-56)
            make.bottom.equalToSuperview().offset(-16)
        }

        Observable.combineLatest(self.oldPasswordInputTextView.$text, self.newPasswordInputTextView.$text, self.confirmPasswordInputTextView.$text).map { old, new, confirm in
            if (old?.isEmpty ?? true) || (new?.isEmpty ?? true) || (confirm?.isEmpty ?? true) { return false }
            return true
        }.bind(to: self.sureBtn.rx.isEnabled).disposed(by: self.disposeBag)

        self.sureBtn.rx.tap.bind { [weak self] _ in
            self?.modifyPassword()
        }.disposed(by: self.disposeBag)
    }

    func modifyPassword() {
        let hud = MBProgressHUD.showLoadingHUD_DispatchOnMainThread(isMask: true)
        self.modifyPasswordObservable(old: self.oldPasswordInputTextView.text, new: self.newPasswordInputTextView.text, confirm: self.confirmPasswordInputTextView.text).subscribe {  _ in
            AccountCenter.shared.logoutCurrentUser()
            MBProgressHUD.showHUD_DispatchOnMainThread(text: String.localization.localized("AA0295", note: "密码修改成功，请重新登录"))
        } onFailure: { err in
            MBProgressHUD.showHUD_DispatchOnMainThread(text: err.localizedDescription)
        } onDisposed: {
            hud.hideDispatchOnMainThread()
        }.disposed(by: self.disposeBag)
    }

    func modifyPasswordObservable(old: String?, new: String?, confirm: String?) -> Single<RQCore.ProfileInfo> {
        // 两次输入不一致
        if new != confirm {
            return Single.error(ReoqooError.accountError(reason: .confirmPasswordError))
        }

        guard let new = new else {
            return Single.error(ReoqooError.accountError(reason: .passwordFormatError))
        }

        // 密码必须为 数字 + 字母 组合
        if !new.isValidPassword {
            return Single.error(ReoqooError.accountError(reason: .passwordFormatError))
        }

        guard let modifyUserInfoObservable = AccountCenter.shared.currentUser?.modifyUserInfoObservable(header: nil, nick: nil, oldPassword: old, newPassword: new) else {
            return Single.error(ReoqooError.generalError(reason: .optionalTypeUnwrapped))
        }
        // 修改密码后, 调登出接口
        return modifyUserInfoObservable
    }

}
