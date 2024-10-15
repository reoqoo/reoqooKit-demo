//
//  IVDatePickerViewService.swift
//  Yoosee
//
//  Created by hongxiaobin on 2022/4/14.
//  Copyright © 2022 Gwell. All rights reserved.
//

import UIKit

// MARK: - IVDatePickerModel

class IVDatePickerModel: NSObject {
    /// 列类型
    var type: IVDatePickerColType = .year

    var colStringArray: [String]?

    /// 选中的行 如果有 在第500圈，colStringArray有10个，选中第一个 ，则这个值是0
    var selectRow: Int = 0

    /// 实际选中的行 如果有 在第500圈，colStringArray有10个，选中第一个 ，则这个值是5000
    var selectDealRow: Int = 0
}

// MARK: - IVDatePickerViewService

class IVDatePickerViewService: NSObject {
    // MARK: Lifecycle

    override init() {
        super.init()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public

    /// 当前使用的日期列 数组
    public var dateTypeArray = [IVDatePickerColType]()

    /// 日期列的model数组
    public var dateColModelArray = [IVDatePickerModel]()

    /// 返回时间格式
    public var format: String = "yyyy-MM-dd HH:mm:ss"

    // MARK: Public Property

    /// 循环次数
    public var loopNumber: Int = 1000 {
        didSet {
            defaultColStringArray()
        }
    }

    /// 显示的 月 日 时 分 秒 是否补齐  0   例如 0 显示00
    public var isFillZero: Bool = false {
        didSet {
            defaultColStringArray()
        }
    }

    /// 根据自定义格式返回选中的时间字符串
    public var selectTime: String {
        set {
            setSelectTime(time: newValue)
        }
        get {
            return dealSelectTime()
        }
    }

    /// 设置时间选中
    /// - Parameters:
    ///   - key: IVDatePickerColKey 的key
    ///   - value: 选中的值
    public func setSelectTime(key: String, value: String) {
        setSelectTime(type: getColType(key: key), value: value)
    }

    /// 获取选中的时间的字典
    /// - Returns: 选中的时间字典  key 是IVDatePickerColKey中的key
    public func getSelectTimeDict() -> [String: String] {
        var dict = [String: String]()
        for model in dateColModelArray {
            dict[getKey(colType: model.type)] = getString(colStringArray: model.colStringArray, selectRow: model.selectRow)
        }
        return dict
    }

    /// 获取选中的时间的字典
    /// - Returns: 选中的时间字典  IVDatePickerColType类型存储的
    public func getSelectTimeTypeDict() -> [IVDatePickerColType: String] {
        var dict = [IVDatePickerColType: String]()
        for model in dateColModelArray {
            dict[model.type] = getString(colStringArray: model.colStringArray, selectRow: model.selectRow)
        }
        return dict
    }

    /// 获取选中的时间类型的值
    /// - Parameter type: 时间类型
    /// - Returns: 值
    public func getSelectTime(type: IVDatePickerColType) -> String {
        for model in dateColModelArray {
            if type == model.type {
                return getString(colStringArray: model.colStringArray, selectRow: model.selectRow)
            }
        }
        return "0"
    }

    /// 根据key类型获取下标和model
    /// - Parameter key: key
    /// - Returns: 查找的(下标，model)
    public func getModel(key: String) -> (Int, IVDatePickerModel)? {
        return getModel(type: getColType(key: key))
    }

    /// 根据类型获取下标和model
    /// - Parameter type: 时间类型
    /// - Returns: 查找的(下标，model)
    public func getModel(type: IVDatePickerColType) -> (Int, IVDatePickerModel)? {
        for (index, model) in dateColModelArray.enumerated() {
            if type == model.type {
                return (index, model)
            }
        }
        return nil
    }

    // MARK: Internal

    func makeModel(minYear: Int,
                   maxYear: Int,
                   numberTypeArray: [NSNumber]) {
        var typeArray = [IVDatePickerColType]()
        for numberType in numberTypeArray {
            if let type = IVDatePickerColType(rawValue: numberType.intValue) {
                typeArray.append(type)
            }
        }
        makeModel(minYear: minYear,
                  maxYear: maxYear,
                  typeArray: typeArray)
    }

    func makeModel(minYear: Int,
                   maxYear: Int,
                   typeArray: [IVDatePickerColType]) {
        dateTypeArray = typeArray.sorted(by: { type1, type2 in
            type1.rawValue < type2.rawValue
        })

        dateColModelArray.removeAll()

        for type in dateTypeArray {
            let model = IVDatePickerModel()
            model.type = type
            dateColModelArray.append(model)
        }

        self.minYear = minYear
        self.maxYear = maxYear
        /// 默认处理Col的字符串数组
        defaultColStringArray()

        /// 默认选中下标
        defaultColSelect()
    }

    /// 默认处理Col的字符串数组
    func defaultColStringArray() {
        for model in dateColModelArray {
            if model.type == .year {
                model.colStringArray = getYearArray(min: minYear, max: maxYear)
            } else if model.type == .month {
                model.colStringArray = getMonthArray()
            } else if model.type == .day {
                model.colStringArray = getDayArray(year: minYear, month: 1)
            } else if model.type == .hour {
                model.colStringArray = getHourArray()
            } else if model.type == .minute {
                model.colStringArray = getMinuteArray()
            } else if model.type == .second {
                model.colStringArray = getSecondArray()
            }
        }
    }

    /// 默认选中下标
    func defaultColSelect() {
        for model in dateColModelArray {
            model.selectRow = 0
            if let colStringArray = model.colStringArray {
                model.selectDealRow = loopNumber / 2 * colStringArray.count
            } else {
                model.selectDealRow = 0
            }
        }
    }

    /// 滚动改变检查 日期是否需要改变ColString数组  这里主要改变day天数
    /// - Parameters:
    ///   - component: 列
    ///   - row: 行
    /// - Returns: 是否要改变
    func checkDateIsReset(component: Int, row: Int) -> Bool {
        if !dateTypeArray.contains(.day) {
            return false
        }

        if component < dateColModelArray.count {
            let model = dateColModelArray[component]

            /// 有年月日的话  年的下标必定是0 月的下标是1 日的下标是2
            if model.type == .year && dateTypeArray.contains(.month) ||
                model.type == .month && dateTypeArray.contains(.year) {
                let (isChange, changeDay) = checkDayIsResetWhenChange(component: component, row: row)

                if isChange {
                    let dayModel = dateColModelArray[2]
                    /// 日期要修改的话，选中行数也要修改
                    var selectIndex = dayModel.selectRow
                    if selectIndex >= changeDay {
                        selectIndex = changeDay - 1
                    }

                    dayModel.colStringArray = getDayArray(day: changeDay)
                    dayModel.selectRow = selectIndex
                    dayModel.selectDealRow = loopNumber / 2 * changeDay + selectIndex
                }

                return isChange
            }
        }
        return false
    }

    /// 获取对应列和行 返回相应选中的值
    /// - Parameters:
    ///   - component: 列
    ///   - row: 行
    /// - Returns: 相应选中的值
    func getColString(component: Int, row: Int) -> String {
        if component < dateColModelArray.count {
            let model = dateColModelArray[component]

            guard let colStringArray = model.colStringArray else { return "" }
            if row < colStringArray.count {
                return colStringArray[row]
            }
        }

        return ""
    }

    // MARK: Private

    // MARK: Private Property

    private var minYear: Int = 0

    private var maxYear: Int = 0

    /// 日的天数是否要改变
    /// - Parameters:
    ///   - component: 列
    ///   - row: 行
    /// - Returns: (是否要改变, 使用的天数)
    private func checkDayIsResetWhenChange(component: Int, row: Int) -> (Bool, Int) {
        let yearModel = dateColModelArray[0]
        let monthModel = dateColModelArray[1]
        let dayModel = dateColModelArray[2]

        let selectYearString: String = getString(colStringArray: yearModel.colStringArray, selectRow: yearModel.selectRow)
        let selectMonthString: String = getString(colStringArray: monthModel.colStringArray, selectRow: monthModel.selectRow)

        /// 当前用的天数
        let dayCount = dayModel.colStringArray!.count
        if component == 0 { // 改变的行
            var changeYearString = "0"
            if let yearColStringArray = yearModel.colStringArray, !yearColStringArray.isEmpty {
                changeYearString = getString(colStringArray: yearColStringArray, selectRow: row % yearColStringArray.count)
            }
            if selectYearString == changeYearString {
                return (false, dayCount)
            } else {
                /// 改变的天数
                let changeDayCount = getDay(year: Int(changeYearString), month: Int(selectMonthString))
                if dayCount == changeDayCount {
                    return (false, dayCount)
                } else {
                    return (true, changeDayCount)
                }
            }
        } else if component == 1 {
            var changeMonthString = "0"
            if let monthColStringArray = monthModel.colStringArray, !monthColStringArray.isEmpty {
                changeMonthString = getString(colStringArray: monthColStringArray, selectRow: row % monthColStringArray.count)
            }
            if selectMonthString == changeMonthString {
                return (false, dayCount)
            } else {
                /// 改变的天数
                let changeDayCount = getDay(year: Int(selectYearString), month: Int(changeMonthString))
                if dayCount == changeDayCount {
                    return (false, dayCount)
                } else {
                    return (true, changeDayCount)
                }
            }
        }
        return (false, dayCount)
    }
}

// MARK: SelectTime

extension IVDatePickerViewService {
    /// 处理选择时间的字符串
    /// - Returns: 时间字符串
    func dealSelectTime() -> String {
        var format = format
        for model in dateColModelArray {
            let selectRow = model.selectRow
            if model.type == .year {
                let yearString = getString(colStringArray: model.colStringArray, selectRow: selectRow)
                format = format.replacingOccurrences(of: "yyyy", with: yearString)
            } else if model.type == .month {
                format = format.replacingOccurrences(of: "MM", with: NSString(format: "%02ld", selectRow + 1) as String)
                format = format.replacingOccurrences(of: "M", with: "\(selectRow + 1)")
            } else if model.type == .day {
                format = format.replacingOccurrences(of: "dd", with: NSString(format: "%02ld", selectRow + 1) as String)
                format = format.replacingOccurrences(of: "d", with: "\(selectRow + 1)")
            } else if model.type == .hour {
                format = format.replacingOccurrences(of: "HH", with: NSString(format: "%02ld", selectRow) as String)
                format = format.replacingOccurrences(of: "H", with: "\(selectRow)")
            } else if model.type == .minute {
                format = format.replacingOccurrences(of: "mm", with: NSString(format: "%02ld", selectRow) as String)
                format = format.replacingOccurrences(of: "m", with: "\(selectRow)")
            } else if model.type == .second {
                format = format.replacingOccurrences(of: "ss", with: NSString(format: "%02ld", selectRow) as String)
                format = format.replacingOccurrences(of: "s", with: "\(selectRow)")
            }
        }

        return format
    }

    /// 设置选中的时间
    /// - Parameters:
    ///   - type: 时间类型
    ///   - value: 时间值字符串
    func setSelectTime(type: IVDatePickerColType, value: String) {
        setSelectTime(type: type, intValue: Int(value) ?? 0)
    }

    /// 设置选中的时间
    /// - Parameters:
    ///   - type: 时间类型
    ///   - intValue: 整型时间值
    func setSelectTime(type: IVDatePickerColType, intValue: Int) {
        for model in dateColModelArray {
            if model.type == type {
                let count: Int = model.colStringArray?.count ?? 0

                var row: Int = intValue
                if model.type == .month || model.type == .day {
                    row = intValue - 1
                } else if model.type == .year {
                    row = intValue - minYear
                }

                /// 如果超过范围 则重置到选中范围内
                if row < 0 {
                    row = 0
                } else if row > count, count > 0 {
                    row = row % count
                }

                model.selectRow = row
                model.selectDealRow = loopNumber / 2 * count + row
            }
        }
    }

    /// 设置选中时间
    /// - Parameter time: 跟format格式对应相同的时间字符串
    func setSelectTime(time: String) {
        let formatter = DateFormatter.global(format)
        if let date = formatter.date(from: time) {
            let calendar = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)

            var intValue: Int?
            for model in dateColModelArray {
                switch model.type {
                case .year:
                    intValue = calendar.year
                case .month:
                    intValue = calendar.month
                case .day:
                    intValue = calendar.day
                case .hour:
                    intValue = calendar.hour
                case .minute:
                    intValue = calendar.minute
                case .second:
                    intValue = calendar.second
                }
                setSelectTime(type: model.type, intValue: intValue ?? 0)
            }
        }
    }
}

// MARK: Key

extension IVDatePickerViewService {
    /// 根据IVDatePickerColKey 的key值返回相应的类型
    /// - Parameter key: IVDatePickerColKey 的key值
    /// - Returns: IVDatePickerColType 对应的类型
    func getColType(key: String) -> IVDatePickerColType {
        if key == IVDatePickerColKey.year {
            return .year
        } else if key == IVDatePickerColKey.month {
            return .month
        } else if key == IVDatePickerColKey.day {
            return .day
        } else if key == IVDatePickerColKey.hour {
            return .hour
        } else if key == IVDatePickerColKey.minute {
            return .minute
        } else if key == IVDatePickerColKey.second {
            return .second
        }
        return .second
    }

    /// 根据IVDatePickerColType的类型返回key
    /// - Parameter colType: IVDatePickerColType 类型
    /// - Returns: IVDatePickerColKey 对应的key
    func getKey(colType: IVDatePickerColType) -> String {
        switch colType {
        case .year:
            return IVDatePickerColKey.year
        case .month:
            return IVDatePickerColKey.month
        case .day:
            return IVDatePickerColKey.day
        case .hour:
            return IVDatePickerColKey.hour
        case .minute:
            return IVDatePickerColKey.minute
        case .second:
            return IVDatePickerColKey.second
        }
    }
}

// MARK: StringArray

extension IVDatePickerViewService {
    /// 返回年的字符串数组
    /// - Parameters:
    ///   - min: 最小的年
    ///   - max: 最大的年
    /// - Returns: 年的字符串数组
    func getYearArray(min: Int, max: Int) -> [String] {
        var array = [String]()
        if min < max {
            for i in min ... max {
                array.append("\(i)")
            }
        }
        return array
    }

    /// 返回月的字符串数组
    /// - Returns: 月的字符串数组
    func getMonthArray() -> [String] {
        var array = [String]()
        for i in 1 ... 12 {
            if isFillZero {
                array.append(NSString(format: "%02ld", i) as String)
            } else {
                array.append("\(i)")
            }
        }
        return array
    }

    /// 根据年月判断并返回天的字符串数组
    /// - Parameters:
    ///   - year: 年
    ///   - month: 月
    /// - Returns: 天的字符串数组
    func getDayArray(year: Int, month: Int) -> [String] {
        let day = getDay(year: year, month: month)
        return getDayArray(day: day)
    }

    /// 根据天数返回天的字符串数组
    /// - Parameter day: 天数
    /// - Returns: 天的字符串数组
    func getDayArray(day: Int) -> [String] {
        var array = [String]()
        if day >= 1 {
            for i in 1 ... day {
                if isFillZero {
                    array.append(NSString(format: "%02ld", i) as String)
                } else {
                    array.append("\(i)")
                }
            }
        }
        return array
    }

    /// 根据年月判断天数
    /// - Parameters:
    ///   - year: 年
    ///   - month: 月
    /// - Returns: 天数
    func getDay(year: Int, month: Int) -> Int {
        switch month {
        case 1, 3, 5, 7, 8, 10, 12:
            return 31
        case 4, 6, 9, 11:
            return 30
        case 2:
            let isLeapYear = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
            return isLeapYear ? 29 : 28
        default:
            fatalError("非法的月份:\(month)")
        }
    }

    /// 获取小时的字符串数组
    /// - Returns: 小时的字符串数组
    func getHourArray() -> [String] {
        let hour = 24
        var array = [String]()
        for i in 0 ..< hour {
            if isFillZero {
                array.append(NSString(format: "%02ld", i) as String)
            } else {
                array.append("\(i)")
            }
        }
        return array
    }

    /// 获取分的字符串数组
    /// - Returns: 分的字符串数组
    func getMinuteArray() -> [String] {
        let minute = 60
        var array = [String]()
        for i in 0 ..< minute {
            if isFillZero {
                array.append(NSString(format: "%02ld", i) as String)
            } else {
                array.append("\(i)")
            }
        }
        return array
    }

    /// 获取秒的字符串数组
    /// - Returns: 秒的字符串数组
    func getSecondArray() -> [String] {
        let second = 60
        var array = [String]()
        for i in 0 ..< second {
            if isFillZero {
                array.append(NSString(format: "%02ld", i) as String)
            } else {
                array.append("\(i)")
            }
        }
        return array
    }

    /// 获取model里面的数组在第几行的字符串
    /// - Parameters:
    ///   - colStringArray: 列字符串数组
    ///   - selectRow: 选中的行
    /// - Returns: 当前字符串
    func getString(colStringArray: [String]?, selectRow: Int) -> String {
        guard let colStringArray = colStringArray else { return "0" }
        if selectRow < colStringArray.count {
            return colStringArray[selectRow]
        }
        return "0"
    }
}

// MARK: String

extension IVDatePickerViewService {
    func dealAttributed(model: IVDatePickerModel,
                        isAppendTitle: Bool,
                        dateColor: UIColor?,
                        dateFont: UIFont?,
                        titleColor: UIColor?,
                        titleFont: UIFont?) -> NSAttributedString? {
        guard let dateColor = dateColor, let dateFont = dateFont else { return nil }
        /// 时间日期
        let dateString = getString(colStringArray: model.colStringArray, selectRow: model.selectRow)
        /// 年月日时分 的标题
        let title = isAppendTitle ? model.type.title : ""
        let attributedString = NSMutableAttributedString(string: "\(dateString)\(title)")
        let totalRange = NSRange(location: 0, length: attributedString.length)
        /// 设置总的字体颜色
        if let titleColor = titleColor {
            attributedString.addAttribute(.foregroundColor, value: titleColor, range: totalRange)
        }
        /// 设置总的字体大小
        if let titleFont = titleFont {
            attributedString.addAttribute(.font, value: titleFont, range: totalRange)
        }

        let dateRange = NSRange(location: 0, length: dateString.count)
        attributedString.addAttribute(.foregroundColor, value: dateColor, range: dateRange)
        attributedString.addAttribute(.font, value: dateFont, range: dateRange)

        return attributedString
    }
}
