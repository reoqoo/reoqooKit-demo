//
//  IVCalendarTimeSelectView.swift
//  Yoosee
//
//  Created by hongxiaobin on 2023/4/24.
//  Copyright © 2023 Gwell. All rights reserved.
//

import UIKit
import BaseKit

// MARK: - IVPopoverHeadView

class IVPopoverHeadView: UIView {
    // MARK: Lifecycle

    init() {
        super.init(frame: .zero)
        setupUI()
        setupEvent()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public

    /// 关闭回调
    public var onCloseClickHandler: (() -> Void)?

    /// 确认回调
    public var onConfirmClickHandler: (() -> Void)?

    // MARK: Public Property

    /// 标题
    public var title: String = "" {
        didSet {
            titleLabel.text = title
        }
    }

    /// 关闭按钮图标
    public var closeImage: UIImage? {
        didSet {
            self.closeButton.setImage(closeImage, for: UIControl.State.normal)
        }
    }

    public var content: String = "" {
        didSet {
            contentLabel.text = content
        }
    }

    // MARK: Internal

    /// 关闭按钮
    let closeButton = UIButton().then {
        $0.backgroundColor = .clear
        $0.setImage(R.image.commonCross(), for: UIControl.State.normal)
    }

    ///
    let contentView = UIView().then {
        $0.backgroundColor = .clear
    }

    /// 标题
    let titleLabel = UILabel().then {
        $0.backgroundColor = .clear
        $0.textAlignment = .center
        $0.textColor = R.color.text_000000_90()
        $0.font = .boldSystemFont(ofSize: 18)
    }

    /// 内容
    let contentLabel = UILabel().then {
        $0.backgroundColor = .clear
        $0.textAlignment = .center
        $0.textColor = R.color.text_000000_90()
        $0.font = .systemFont(ofSize: 12)
    }

    /// 确认按钮
    let confirmButton = UIButton(type: .system).then {
        $0.backgroundColor = .clear
        $0.tintColor = R.color.text_000000_90()
        $0.setImage(R.image.commonTick(), for: UIControl.State.normal)
    }

    // MARK: Private Property

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.snp.remakeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(closeButton.snp.right).offset(10.0)
            make.right.equalTo(confirmButton.snp.left).offset(-10.0)
        }
    }

    func setupUI() {
        /// 关闭按钮
        addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(48.0)
            make.height.equalTo(48.0)
        }

        /// 标题背景
        addSubview(contentView)

        /// 标题
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
        }

        /// 内容
        contentView.addSubview(contentLabel)
        contentLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom)
            make.bottom.left.right.equalToSuperview()
        }

        /// 确认按钮
        addSubview(confirmButton)
        confirmButton.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(48.0)
            make.height.equalTo(48.0)
        }
    }

    func setupEvent() {
        closeButton.addEvent { [weak self] _ in
            guard let `self` = self else { return }
            self.onCloseClickHandler?()
        }

        confirmButton.addEvent { [weak self] _ in
            guard let `self` = self else { return }
            self.onConfirmClickHandler?()
        }
    }
}

class IVCalendarTimeSelectView: UIView {
    // MARK: Lifecycle

    init() {
        super.init(frame: .zero)
        setupUI()
        setupEvent()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        logDebug(self.classForCoder)
    }
    
    // MARK: Public

    // MARK: Public Property
    
    /// 返回回调
    public var onBackHandler: ((Int) -> Void)?
    
    /// 确认回调
    public var onConfirmHandler: ((Int) -> Void)?

    /// 选择秒数
    public var second: Int {
        set {
            let hour: Int = newValue / 3600
            let minute: Int = newValue / 60
            timePickerView.setSelectTime(type: IVDatePickerColType.hour, value: "\(hour)")
            timePickerView.setSelectTime(type: IVDatePickerColType.minute, value: "\(minute)")
        }
        get {
            let hourString = timePickerView.getSelectTime(type: IVDatePickerColType.hour)
            let minuteString = timePickerView.getSelectTime(type: IVDatePickerColType.minute)

            let hour: Int = hourString.count > 0 ? (Int(hourString) ?? 0) : 0
            let minute: Int = minuteString.count > 0 ? (Int(minuteString) ?? 0) : 0
            return hour * 3600 + minute * 60
        }
    }
    
    // MARK: Internal

    /// 头视图
    let headView = IVPopoverHeadView().then {
        $0.closeImage = R.image.commonNavigationBack()
        $0.title = String.localization.localized("AA0414", note: "开始时间")
    }
    
    /// 小时分钟视图
    let timePickerView = IVDatePickerView(minYear: 2010, maxYear: 2030, typeArray: [.hour, .minute]).then {
        $0.backgroundColor = .clear
        $0.dateTitleType = .center
        $0.rowHeight = 40
        $0.selectBackgroundColor = .clear
        $0.isFillZero = true
        $0.loopNumber = 1
        
        $0.selectDateColor = R.color.text_000000_90()
        $0.selectDateFont = .boldSystemFont(ofSize: 24.0)
        
        $0.selectTitleColor = UIColor(rgb: 0x171A1D)
        $0.selectTitleFont = .systemFont(ofSize: 17.0)
        
        $0.dateTitleOffset = CGPointMake(4.0, -6.0)
        $0.dateTitleFont = .systemFont(ofSize: 12.0)
        $0.dateTitleColor = UIColor(rgb: 0x171A1D)
    }

    // MARK: Private Property
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        /// 头视图
        headView.snp.makeConstraints { make in
            make.top.equalTo(self).offset(0)
            make.left.right.equalTo(self)
            make.height.equalTo(64.0)
        }
        
        /// 小时分钟视图
        timePickerView.snp.remakeConstraints { make in
            make.top.equalTo(headView.snp.bottom).offset(0.0)
            make.left.right.equalTo(self)
            make.height.equalTo(220)
        }
    }

    // MARK: Private

    private func setupUI() {
        backgroundColor = .white
        clipsToBounds = true
        layer.cornerRadius = 10.0
        
        /// 头视图
        addSubview(headView)
        
        /// 小时分钟视图
        addSubview(timePickerView)
    }
    
    private func setupEvent() {
        /// 返回回调
        headView.onCloseClickHandler = { [weak self] in
            guard let `self` = self else { return }
            self.onBackHandler?(self.second)
        }
        
        /// 确认回调
        headView.onConfirmClickHandler = { [weak self] in
            guard let `self` = self else { return }
            self.onConfirmHandler?(self.second)
        }
    }
}
