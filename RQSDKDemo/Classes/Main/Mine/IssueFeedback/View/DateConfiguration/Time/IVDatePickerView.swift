//
//  IVDatePickerView.swift
//  Yoosee
//
//  Created by hongxiaobin on 2022/4/14.
//  Copyright © 2022 Gwell. All rights reserved.
//
// 年 月 日 时 分 秒 各种组合大乱炖的时间选择器 这里会从年开始依次向秒排序

import UIKit

// MARK: - IVDatePickerColKey

/// 这里定义是为了让OC可以使用，不然都直接用IVDatePickerColType 里面定义的key了
@objcMembers
class IVDatePickerColKey: NSObject {
    public static let year = "kIVDatePickerColYearKey"
    public static let month = "kIVDatePickerColMonthKey"
    public static let day = "kIVDatePickerColDayKey"
    public static let hour = "kIVDatePickerColHourKey"
    public static let minute = "kIVDatePickerColMinuteKey"
    public static let second = "kIVDatePickerColSecondKey"
}

// MARK: - IVDatePickerColType

@objc enum IVDatePickerColType: Int {
    /// 年
    case year = 1
    /// 月
    case month = 2
    /// 日
    case day = 3
    /// 时
    case hour = 4
    /// 分
    case minute = 5
    /// 秒
    case second = 6

    // MARK: Internal

    var title: String {
        switch self {
        case .year:
            return String.localization.localized("#", note: "年")
        case .month:
            return String.localization.localized("#", note: "月")
        case .day:
            return String.localization.localized("AA0463", note: "日")
        case .hour:
            return String.localization.localized("AA0435", note: "时")
        case .minute:
            return String.localization.localized("AA0436", note: "分")
        case .second:
            return String.localization.localized("#", note: "秒")
        }
    }
}

// MARK: - IVDatePickerDateTitleType

@objc enum IVDatePickerDateTitleType: Int {
    /// 没有
    case none
    /// 标题在顶部
    case top
    /// 标题在中间
    case center
    /// 在日期选中后 直接加入到日期后面
    case centerSelectInset
    /// 标题在底部
    case bottom
}

// MARK: - IVDatePickerView

@objcMembers
class IVDatePickerView: UIView {
    // MARK: Lifecycle

    /// 主要OC用的初始化方法
    /// - Parameters:
    ///   - minYear: 滚动框上最小的年份
    ///   - maxYear: 滚动框上最大的年份
    ///   - numberTypeArray: number类型的时间类型 数组
    init(minYear: Int,
         maxYear: Int,
         numberTypeArray: [NSNumber]) {
        super.init(frame: .zero)
        service.makeModel(minYear: minYear,
                          maxYear: maxYear,
                          numberTypeArray: numberTypeArray)
        setupUI()
        setupEvent()
        reloadSelectIndex()
    }

    /// 主要swift用的初始化方法
    /// - Parameters:
    ///   - minYear: 滚动框上最小的年份
    ///   - maxYear: 滚动框上最大的年份
    ///   - typeArray: IVDatePickerColType类型的时间类型 数组
    init(minYear: Int,
         maxYear: Int,
         typeArray: [IVDatePickerColType]) {
        super.init(frame: .zero)
        service.makeModel(minYear: minYear,
                          maxYear: maxYear,
                          typeArray: typeArray)
        setupUI()
        setupEvent()
        reloadSelectIndex()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public

    /// 日期标题高度
    public var dateTitleLabelHeight: CGFloat = 30.0

    /// 每列最大宽度
    public var componentMaxWidth: CGFloat = 90.0

    /// 当选择器的时间已经更改   返回（self, 格式化时间）
    public var onPickerTimeChanged: ((IVDatePickerView, String) -> Void)?

    /// 确认按钮点击  返回（self, 格式化时间）
    public var onConfirmClick: ((IVDatePickerView, String) -> Void)?

    /// 日期标题位置偏移 centerSelectInset该设置无效
    public var dateTitleOffset: CGPoint = .zero

    /// 行高
    public var rowHeight: CGFloat = 30.0

    // MARK: Public Property

    /// 标题
    public var title: String = "" {
        didSet {
            titleLabel.text = title
        }
    }

    /// 是否隐藏顶部标题
    public var isHiddenTitleLabel: Bool = true {
        didSet {
            if isHiddenTitleLabel {
                titleLabel.removeFromSuperview()
            } else {
                addSubview(titleLabel)
            }
            titleLabel.isHidden = isHiddenTitleLabel
            setNeedsLayout()
        }
    }

    /// 是否隐藏标题下分割线
    public var isHiddenTitleBottomLine: Bool = true {
        didSet {
            if isHiddenTitleBottomLine {
                line.removeFromSuperview()
            } else {
                addSubview(line)
            }
            line.isHidden = isHiddenTitleBottomLine
            setNeedsLayout()
        }
    }

    /// 是否隐藏确认按钮
    public var isHiddenConfirmButton: Bool = true {
        didSet {
            if isHiddenConfirmButton {
                confirmButton.removeFromSuperview()
            } else {
                addSubview(confirmButton)
            }
            confirmButton.isHidden = isHiddenConfirmButton
            setNeedsLayout()
        }
    }

    /// 确认按钮标题
    public var confirmButtonTitle: String = "" {
        didSet {
            confirmButton.setTitle(confirmButtonTitle, for: .normal)
        }
    }

    /// 标题格式
    public var dateTitleType: IVDatePickerDateTitleType = .none {
        didSet {
            makeTitleLabel()
            setNeedsLayout()
        }
    }

    /// 日期标题颜色
    public var dateTitleColor = UIColor(rgb: 0x161514) {
        didSet {
            for dateTitleLabel in dateTitleLabelArray {
                dateTitleLabel.textColor = dateTitleColor
            }
        }
    }

    /// 日期标题文字大小
    public var dateTitleFont: UIFont = .systemFont(ofSize: 10.0) {
        didSet {
            for dateTitleLabel in dateTitleLabelArray {
                dateTitleLabel.font = dateTitleFont
            }
        }
    }

    /// 滚动中间日期的文字颜色
    public var dateColor = UIColor(rgb: 0x333333) {
        didSet {
            timePickerView.reloadAllComponents()
        }
    }

    /// 滚动中间日期的文字大小
    public var dateFont: UIFont = .systemFont(ofSize: 14) {
        didSet {
            timePickerView.reloadAllComponents()
        }
    }

    /// 选中的日期的颜色   如果没有，则不设置
    public var selectDateColor: UIColor? {
        didSet {
            timePickerView.reloadAllComponents()
        }
    }

    /// 选中的日期的大小   如果没有，则不设置
    public var selectDateFont: UIFont? {
        didSet {
            timePickerView.reloadAllComponents()
        }
    }

    /// 选中的时间标题的颜色   如果没有，则以selectDateColor为主, 有则在选中后改变颜色
    public var selectTitleColor: UIColor? {
        didSet {
            timePickerView.reloadAllComponents()
        }
    }

    /// 选中的时间标题的大小   如果没有，则以selectDateFont为主, 有则在选中后改变大小
    public var selectTitleFont: UIFont? {
        didSet {
            timePickerView.reloadAllComponents()
        }
    }

    /// 是否设置选中的背景色
    public var selectBackgroundColor: UIColor? {
        didSet {
            timePickerView.reloadAllComponents()
        }
    }

    /// 显示的 月 日 时 分 秒 是否补齐  0   例如 0 显示00
    public var isFillZero: Bool = false {
        didSet {
            service.isFillZero = isFillZero
        }
    }

    /// 返回时间格式
    public var format: String {
        set {
            service.format = newValue
        }
        get {
            return service.format
        }
    }

    /// 根据自定义格式 设置或返回选中的时间字符串
    public var selectTime: String {
        set {
            service.selectTime = newValue
            reloadSelectIndex()
        }
        get {
            return service.selectTime
        }
    }

    /// 循环次数
    public var loopNumber: Int {
        set {
            service.loopNumber = newValue
        }
        get {
            return service.loopNumber
        }
    }

    /// 设置时间选中   该方法是OC用的
    /// - Parameters:
    ///   - key: IVDatePickerColKey 的key
    ///   - value: 选中的值
    public func setSelectTime(key: String, value: String) {
        service.setSelectTime(key: key, value: value)

        guard let (component, model) = service.getModel(key: key) else { return }
        timePickerView.selectRow(model.selectDealRow, inComponent: component, animated: false)
    }

    /// 获取选中的时间的字典   该方法是OC用的
    /// - Returns: 选中的时间字典  key 是IVDatePickerColKey中的key
    public func getSelectTimeDict() -> [String: String] {
        return service.getSelectTimeDict()
    }

    /// 获取选中的时间的字典  该方法是swift用的
    /// - Returns: 选中的时间字典  IVDatePickerColType类型存储的
    public func getSelectTimeTypeDict() -> [IVDatePickerColType: String] {
        return service.getSelectTimeTypeDict()
    }

    /// 获取选中的时间类型的值
    /// - Parameter type: 时间类型
    /// - Returns: 值
    public func getSelectTime(type: IVDatePickerColType) -> String {
        return service.getSelectTime(type: type)
    }

    // MARK: Internal

    /// 标题
    internal lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        label.textAlignment = .center
        label.textColor = UIColor(rgb: 0x333333)
        label.font = .systemFont(ofSize: 12)
        label.isHidden = true
        return label
    }()

    /// 分割线
    internal lazy var line: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(rgb: 0xF6F6F6)
        view.isHidden = true
        return view
    }()

    /// 时间选择器
    internal let timePickerView = UIPickerView().then {
        $0.backgroundColor = .clear
        $0.showsSelectionIndicator = false
    }

    /// 确认按钮
    internal lazy var confirmButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor(rgb: 0x2E6DEA)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17.0)
        button.clipsToBounds = true
        button.addEvent(.touchUpInside) { [weak self] _ in
            guard let `self` = self else { return }
            self.onConfirmClick?(self, self.selectTime)
        }
        return button
    }()

    /// 设置时间选中   该方法是swift用的
    /// - Parameters:
    ///   - type: 日期类型
    ///   - value: 选中的值
    func setSelectTime(type: IVDatePickerColType, value: String) {
        service.setSelectTime(type: type, value: value)

        guard let (component, model) = service.getModel(type: type) else { return }
        timePickerView.selectRow(model.selectDealRow, inComponent: component, animated: false)
    }

    override func layoutSubviews() {
        /// 标题
        if !isHiddenTitleLabel {
            let titleLabelFrame = CGRect(x: 0, y: 0, width: width, height: 30.0)
            titleLabel.frame = titleLabelFrame
        }

        /// 分割线
        if !isHiddenTitleBottomLine {
            let lineFrame = CGRect(x: 0, y: titleLabel.bottom, width: width, height: 0.5)
            line.frame = lineFrame
        }

        /// 确认按钮
        var confirmButtonMarginBottom: CGFloat = 0.0
        if !isHiddenConfirmButton {
            confirmButtonMarginBottom = 10.0
            let confirmButtonFrame = CGRect(x: 10.0, y: height - confirmButtonMarginBottom - 45.0, width: width - 20.0, height: 45.0)
            confirmButton.frame = confirmButtonFrame
            confirmButton.layer.cornerRadius = 22.5
        }

        /// 计算时间选择器的位置
        let timePickerViewMinY: CGFloat = line.bottom
        let timePickerViewHeight = height - confirmButton.height - confirmButtonMarginBottom - line.bottom
        let timePickerViewFrame = CGRect(x: 0,
                                         y: timePickerViewMinY,
                                         width: width,
                                         height: timePickerViewHeight)
        timePickerView.frame = timePickerViewFrame

        if dateTitleType == .none || dateTitleType == .centerSelectInset {
            for dateTitleLabel in dateTitleLabelArray {
                dateTitleLabel.isHidden = true
            }
            return
        }

        /// 计算日期标题的位置 大小
        /// 横向间隔
        let dateTitleLabelLandscapeInterval: CGFloat = 5.0
        /// 日期标题的宽度
        let countFloat = CGFloat(dateTitleLabelArray.count)
        var dateTitleLabelWidth: CGFloat = countFloat > 0 ? ((width - dateTitleLabelLandscapeInterval * (countFloat - 1)) / countFloat) : 0
        dateTitleLabelWidth = dateTitleLabelWidth > componentMaxWidth ? componentMaxWidth : dateTitleLabelWidth

        /// 日期标题的位置
        var dateTitleLabelMinX: CGFloat = (width - dateTitleLabelWidth * countFloat - dateTitleLabelLandscapeInterval * (countFloat - 1.0)) / 2.0 + dateTitleOffset.x
        var dateTitleLabelMinY: CGFloat = line.bottom + dateTitleOffset.y
        if dateTitleType == .center {
            dateTitleLabelMinX = dateTitleLabelMinX + dateTitleLabelWidth / 2.0 + dateTitleFont.pointSize + dateTitleOffset.x
            dateTitleLabelMinY = (timePickerView.height - dateTitleLabelHeight) / 2.0 + line.bottom + dateTitleOffset.y
        } else if dateTitleType == .bottom {
            dateTitleLabelMinY = height - dateTitleLabelHeight - confirmButton.height - confirmButtonMarginBottom + dateTitleOffset.y
        }
        var dateTitleOffsetX: CGFloat = 0
        /// frame
        var dateTitleLabelFrame = CGRect.zero

        /// 重置日期标题的位置
        for (index, dateTitleLabel) in dateTitleLabelArray.enumerated() {
            dateTitleLabel.isHidden = false
            if index >= service.dateColModelArray.count {
                break
            }

            let model = service.dateColModelArray[index]

            /// 年要多偏移一点
            if index == 0, model.type == .year, dateTitleType == .center {
                dateTitleOffsetX = dateTitleFont.pointSize
            } else {
                dateTitleOffsetX = 0
            }
            dateTitleLabelFrame = CGRect(x: dateTitleLabelMinX + (dateTitleLabelWidth + dateTitleLabelLandscapeInterval) * CGFloat(index) + dateTitleOffsetX,
                                         y: dateTitleLabelMinY,
                                         width: dateTitleLabelWidth,
                                         height: dateTitleLabelHeight)
            dateTitleLabel.frame = dateTitleLabelFrame

            if dateTitleType == .center {
                dateTitleLabel.textAlignment = .left
            } else {
                dateTitleLabel.textAlignment = .center
            }
        }
    }

    /// 重新设置 PickerView选中行
    func reloadSelectIndex() {
        for (index, model) in service.dateColModelArray.enumerated() {
            timePickerView.selectRow(model.selectDealRow, inComponent: index, animated: false)
        }
    }

    /// 创建TitleLabel
    func makeTitleLabel() {
        if !dateTitleLabelArray.isEmpty || dateTitleType == .none {
            return
        }
        for (_, model) in service.dateColModelArray.enumerated() {
            /// 标题
            let titleLabel = UILabel().then {
                $0.backgroundColor = .clear
                $0.textAlignment = .left
                $0.textColor = dateTitleColor
                $0.font = dateTitleFont
                $0.isUserInteractionEnabled = false
                $0.baselineAdjustment = .alignCenters
                $0.adjustsFontSizeToFitWidth = true
                $0.text = model.type.title
            }
            dateTitleLabelArray.append(titleLabel)
            addSubview(titleLabel)
        }
    }

    // MARK: Private

    // MARK: Private Property

    private var service = IVDatePickerViewService()

    /// 标题视图数组
    private var dateTitleLabelArray = [UILabel]()

    private func setupUI() {
        backgroundColor = .white

        /// 时间选择器
        addSubview(timePickerView)
    }

    private func setupEvent() {
        /// 时间选择器
        timePickerView.delegate = self
        timePickerView.dataSource = self
    }
}

// MARK: UIPickerViewDelegate, UIPickerViewDataSource

extension IVDatePickerView: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return service.dateColModelArray.count
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component < service.dateColModelArray.count {
            let model = service.dateColModelArray[component]
            return model.colStringArray!.count * service.loopNumber
        }
        return 0
    }

    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        let countFloat = CGFloat(dateTitleLabelArray.count)
        if countFloat > 0 {
            /// 横向间隔
            let dateTitleLabelLandscapeInterval: CGFloat = 5.0

            let dateTitleLabelWidth: CGFloat = (width - dateTitleLabelLandscapeInterval * (countFloat - 1)) / countFloat
            return dateTitleLabelWidth > componentMaxWidth ? componentMaxWidth : dateTitleLabelWidth
        } else {
            return componentMaxWidth
        }
    }

    internal func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return rowHeight
    }

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        for singleLine in pickerView.subviews {
            if singleLine.frame.size.height < 1.0 {
                singleLine.backgroundColor = .clear
            }
        }

        /// 时间
        let timeLabel = UILabel().then {
            $0.backgroundColor = .clear
            $0.textAlignment = .center
            $0.textColor = dateColor
            $0.font = .systemFont(ofSize: 17)
        }

        if component < service.dateColModelArray.count {
            let model = service.dateColModelArray[component]

            let colStringArray = model.colStringArray!
            let index = row % colStringArray.count
            timeLabel.text = colStringArray[index]

            if model.selectDealRow == row {
                reloadSelectLabelStyle(model: model, component: component)
            }
        }

        if let selectBackgroundColor = selectBackgroundColor {
            let subviews = pickerView.subviews
            if #available(iOS 14.0, *) {
                if subviews.count > 1 {
                    pickerView.subviews[1].backgroundColor = selectBackgroundColor
                }
            }
        }

        return timeLabel
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        /// 检查 日 是否需要改变天数
        if service.checkDateIsReset(component: component, row: row) {
            let dayModel = service.dateColModelArray[2]
            pickerView.reloadComponent(2)
            pickerView.selectRow(dayModel.selectDealRow, inComponent: 2, animated: false)
        }
        if component < service.dateColModelArray.count {
            let model = service.dateColModelArray[component]
            model.selectDealRow = row
            model.selectRow = row % model.colStringArray!.count

            reloadSelectLabelStyle(model: model, component: component)
        }

        onPickerTimeChanged?(self, selectTime)
    }

    /// 重新设置选中行的label的视图样式
    /// - Parameters:
    ///   - model: 选中的model
    ///   - component: 列
    func reloadSelectLabelStyle(model: IVDatePickerModel, component: Int) {
        /// 如果选中后需要用富文本
        let isAppendTitle: Bool = dateTitleType == .centerSelectInset
        if !isAppendTitle {
            let label = timePickerView.view(forRow: model.selectDealRow, forComponent: component) as? UILabel
            label?.textColor = selectDateColor
            label?.font = selectDateFont
        } else {
            let attributedString = service.dealAttributed(model: model,
                                                          isAppendTitle: isAppendTitle,
                                                          dateColor: selectDateColor,
                                                          dateFont: selectDateFont,
                                                          titleColor: selectTitleColor,
                                                          titleFont: selectTitleFont)
            if let attributedString = attributedString {
                let label = timePickerView.view(forRow: model.selectDealRow, forComponent: component) as? UILabel
                label?.attributedText = attributedString
            }
        }
    }
}
