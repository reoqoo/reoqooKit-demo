//
//  PasswordInputView.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 26/7/2023.
//

import UIKit

class PasswordInputView: UIView {

    @RxBehavioral var isEditing = false

    @RxBehavioral var text: String?

    private(set) lazy var textField: UITextField = .init().then {
        $0.textContentType = .password
        $0.keyboardType = .asciiCapable
        $0.returnKeyType = .done
        $0.clearButtonMode = .whileEditing
        $0.isSecureTextEntry = true
        $0.delegate = self
        $0.textColor = R.color.text_000000_90()!
        $0.font = .systemFont(ofSize: 16)
        $0.placeholder = String.localization.localized("AA0003", note: "密码")
    }

    private(set) lazy var hidePasswordBtn: UIButton = {
        let res = UIButton.init(type: .custom)
        res.setContentHuggingPriority(.init(999), for: .horizontal)
        res.setImage(R.image.commonIsHidePasswordTrue(), for: .normal)
        res.setImage(R.image.commonIsHidePasswordFalse(), for: .selected)
        res.contentEdgeInsets = .init(top: 8, left: 16, bottom: 8, right: 24)
        return res
    }()

    /// 底部线条. 进入输入状态后高亮
    private(set) lazy var bottomLine: UIView = {
        let res = UIView.init()
        res.backgroundColor = R.color.lineInputDisable()!
        return res
    }()

    private var disposeBag: DisposeBag = .init()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }

    func setup() {
        self.addSubview(self.textField)
        self.textField.snp.makeConstraints { make in
            make.top.bottom.leading.equalToSuperview()
        }

        self.addSubview(self.hidePasswordBtn)
        self.hidePasswordBtn.snp.makeConstraints { make in
            make.leading.equalTo(self.textField.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview()
        }

        self.addSubview(self.bottomLine)
        self.bottomLine.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }

        self.hidePasswordBtn.rx.tap.subscribe { [weak self] _ in
            self?.hidePasswordBtn.isSelected.toggle()
        }.disposed(by: self.disposeBag)

        // 使 self.textField.isSecureTextEntry 监听 self.hidePasswordBtn.isSelected
        self.hidePasswordBtn.rx.observe(\.isSelected).map({ !$0 }).bind(to: self.textField.rx.isSecureTextEntry).disposed(by: self.disposeBag)

        // 监听 textfield 被 setText 的情况
        self.textField.rx.observe(\.text).bind { [weak self] str in
            self?.text = str
        }.disposed(by: self.disposeBag)
    }
}

extension PasswordInputView: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        self.bottomLine.backgroundColor = R.color.lineInputEnable()
        self.bottomLine.snp.updateConstraints { make in
            make.height.equalTo(1)
        }
        self.isEditing = true
        return true
    }

    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        self.bottomLine.backgroundColor = R.color.lineInputDisable()
        self.bottomLine.snp.updateConstraints { make in
            make.height.equalTo(0.5)
        }
        self.isEditing = false
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        self.text = (textField.text as? NSString)?.replacingCharacters(in: range, with: string)
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.endEditing(true)
        return true
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        self.text = nil
        return true
    }
}
