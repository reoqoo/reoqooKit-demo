//
//  IssueFeedbackViewController+CalendarSelectionViewController.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 8/9/2023.
//

import Foundation
import GWCalendarView

extension IssueFeedbackViewController.CalendarSelectionViewController {

    class CalendarContainer: UIView, GWCalendarViewDelegate {
        
        lazy var canledarViewUIConfigturation: GWCalendarUIConfig = .init().then {
            $0.monthViewParam.weekTitleColor = R.color.text_000000_60()!

            $0.dayButtonParam.selectButtonStatus.backgroundColor = R.color.brand()!
            $0.dayButtonParam.selectButtonStatus.textColor = R.color.text_FFFFFF()!
            $0.dayButtonParam.selectButtonStatus.backgroundLayerColor = .clear

            $0.dayButtonParam.defaultSelectButtonStatus.backgroundColor = R.color.brand()!
            $0.dayButtonParam.defaultSelectButtonStatus.textColor = R.color.text_FFFFFF()!
            $0.dayButtonParam.defaultSelectButtonStatus.backgroundLayerColor = .clear
            
            $0.dayButtonParam.defaultNormalButtonStatus.backgroundColor = R.color.brand()!.withAlphaComponent(0.2)
            $0.dayButtonParam.defaultNormalButtonStatus.textColor = R.color.brand()!
            $0.dayButtonParam.defaultNormalButtonStatus.backgroundLayerColor = .clear
        }

        lazy var canledarView: GWCalendarView = .init().then {
            $0.backgroundColor = R.color.background_FFFFFF_white()
            $0.scrollDirection = GWCalendarViewScrollDirectionHorizontal
            $0.collectionTitleStyle = GWCalendarCollectionTitleStyleNone
            $0.showScrollIndicator = false
            $0.service.isShowPreviousAndNextMonthDay = true
            $0.calendarUIConfig = self.canledarViewUIConfigturation
            $0.delegate = self
            $0.weekTitleArray = [String.localization.localized("AA0463", note: "日"), String.localization.localized("AA0462", note: "六"), String.localization.localized("AA0461", note: "五"), String.localization.localized("AA0460", note: "四"), String.localization.localized("AA0459", note: "三"), String.localization.localized("AA0458", note: "二"), String.localization.localized("AA0457", note: "一")]
        }

        lazy var topContainer: UIView = .init().then {
            $0.backgroundColor = R.color.background_FFFFFF_white()
        }

        lazy var nextMonthBtn: UIButton = .init().then {
            $0.setImage(R.image.commonArrowRightStyle0(), for: .normal)
        }

        lazy var previousMonthBtn: UIButton = .init().then {
            $0.setImage(R.image.commonArrowLeftStyle0(), for: .normal)
        }

        lazy var currrentMonthLabel: UILabel = .init().then {
            $0.textColor = R.color.text_000000_90()
            $0.font = .systemFont(ofSize: 16)
        }

        lazy var tickBtn: UIButton = .init(type: .system).then {
            $0.setImage(R.image.commonTick(), for: .normal)
            $0.tintColor = R.color.text_000000_90()
        }

        lazy var cancelBtn: UIButton = .init(type: .system).then {
            $0.setImage(R.image.commonCross(), for: .normal)
            $0.tintColor = R.color.text_000000_90()
        }

        lazy var tapOnBottomContainer: UITapGestureRecognizer = .init()
        lazy var bottomContainer: UIView = .init().then {
            $0.addGestureRecognizer(self.tapOnBottomContainer)
            $0.backgroundColor = R.color.background_FFFFFF_white()
        }

        lazy var selectTimeButton: IVButton = .init(.right).then {
            $0.setTitle("16:00", for: .normal)
            $0.isUserInteractionEnabled = false
            $0.setTitleColor(R.color.text_link_4A68A6(), for: .normal)
            $0.setImage(R.image.commonArrowRightStyle0(), for: .normal)
            $0.titleLabel?.font = .systemFont(ofSize: 14)
        }

        lazy var selectTimeLabel: UILabel = .init().then {
            $0.text = String.localization.localized("AA0260", note: "选择时间")
            $0.font = .systemFont(ofSize: 16)
            $0.textColor = R.color.text_000000_90()
        }

        override init(frame: CGRect) {
            super.init(frame: frame)

            self.backgroundColor = R.color.background_FFFFFF_white()

            self.addSubview(self.topContainer)
            self.topContainer.snp.makeConstraints { make in
                make.top.leading.trailing.equalToSuperview()
                make.height.equalTo(64)
            }

            self.topContainer.addSubview(self.currrentMonthLabel)
            self.currrentMonthLabel.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }

            self.topContainer.addSubview(self.previousMonthBtn)
            self.previousMonthBtn.snp.makeConstraints { make in
                make.trailing.equalTo(self.currrentMonthLabel.snp.leading)
                make.top.bottom.equalToSuperview()
                make.width.equalTo(44)
            }

            self.topContainer.addSubview(self.nextMonthBtn)
            self.nextMonthBtn.snp.makeConstraints { make in
                make.leading.equalTo(self.currrentMonthLabel.snp.trailing)
                make.top.bottom.equalToSuperview()
                make.width.equalTo(44)
            }

            self.topContainer.addSubview(self.tickBtn)
            self.tickBtn.snp.makeConstraints { make in
                make.trailing.equalToSuperview()
                make.centerY.equalToSuperview()
                make.width.equalTo(64)
                make.height.equalTo(48)
            }

            self.topContainer.addSubview(self.cancelBtn)
            self.cancelBtn.snp.makeConstraints { make in
                make.leading.equalToSuperview()
                make.centerY.equalToSuperview()
                make.width.height.equalTo(48)
            }

            self.insertSubview(self.canledarView, belowSubview: self.topContainer)
            self.canledarView.snp.makeConstraints { make in
                make.top.equalTo(self.topContainer.snp.bottom).offset(-60)
                make.trailing.leading.equalToSuperview()
                make.height.equalTo(300)
            }

            self.addSubview(self.bottomContainer)
            self.bottomContainer.snp.makeConstraints { make in
                make.bottom.equalTo(self.safeAreaLayoutGuide.snp.bottom).offset(-12)
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(56)
                make.top.equalTo(self.canledarView.snp.bottom)
            }

            self.bottomContainer.addSubview(self.selectTimeButton)
            self.selectTimeButton.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-8)
                make.centerY.equalToSuperview()
            }

            self.bottomContainer.addSubview(self.selectTimeLabel)
            self.selectTimeLabel.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(16)
                make.centerY.equalToSuperview()
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: GWCalendarViewDelegate
        func gwCalendarView(_ calendar: GWCalendarView, didSelect date: Date, isReset: Bool) {

        }

        func gwCalendarView(_ calendar: GWCalendarView, didScroll monthModel: GWCalendarMonthModel) {
            self.currrentMonthLabel.text = "\(monthModel.year)-\(monthModel.month)"
        }

    }

    class TimeSelectionContainer: UIView {
        lazy var datePickerView: IVCalendarTimeSelectView = .init()

        override init(frame: CGRect) {
            super.init(frame: frame)
            self.backgroundColor = R.color.background_FFFFFF_white()
            self.addSubview(self.datePickerView)
            self.datePickerView.snp.makeConstraints { make in
                make.top.leading.trailing.equalToSuperview()
                make.bottom.equalToSuperview().offset(-24)
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

extension IssueFeedbackViewController {
    class CalendarSelectionViewController: PageSheetStyleViewController {

        @Published var selectedTime: Date?

        lazy var calendarContainer: CalendarContainer = .init().then {
            $0.layer.masksToBounds = true
            $0.layer.cornerRadius = 12
        }

        lazy var timeSelectionContainer: TimeSelectionContainer = .init().then {
            $0.isHidden = true
            $0.layer.masksToBounds = true
            $0.layer.cornerRadius = 12
        }

        /// 指向当前正在显示的视图 calendarContainer / timeSelectionContainer
        lazy var displayingContent: UIView = self.calendarContainer

        var anyCancellables: Set<AnyCancellable> = []

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            UIView.animate(withDuration: 0.3) {
                self.displayingContent.transform = .identity
            }
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            UIView.animate(withDuration: 0.3) {
                self.displayingContent.transform = .init(translationX: 0, y: self.view.bounds.height)
            }
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            
            self.view.addSubview(self.calendarContainer)
            self.calendarContainer.snp.makeConstraints { make in
                make.trailing.leading.equalToSuperview()
                make.bottom.equalToSuperview().offset(12)
            }

            self.view.addSubview(self.timeSelectionContainer)
            self.timeSelectionContainer.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.bottom.equalToSuperview().offset(12)
                make.height.equalTo(320)
            }

            self.calendarContainer.cancelBtn.tapPublisher.sink(receiveValue: { [weak self] in
                self?.dismiss(animated: true)
            }).store(in: &self.anyCancellables)

            self.calendarContainer.tickBtn.tapPublisher.sink(receiveValue: { [weak self] in
                self?.didFinishSelectTime()
            }).store(in: &self.anyCancellables)

            self.calendarContainer.nextMonthBtn.tapPublisher.sink(receiveValue: { [weak self] in
                self?.calendarContainer.canledarView.loadNextMonth()
            }).store(in: &self.anyCancellables)

            self.calendarContainer.previousMonthBtn.tapPublisher.sink(receiveValue: { [weak self] in
                self?.calendarContainer.canledarView.loadPreviousMonth()
            }).store(in: &self.anyCancellables)

            self.calendarContainer.tapOnBottomContainer.tapPublisher.sink(receiveValue: { [weak self] _ in
                self?.switchContent()
            }).store(in: &self.anyCancellables)

            self.timeSelectionContainer.datePickerView.onBackHandler = { [weak self] _ in
                self?.switchContent()
            }

            self.timeSelectionContainer.datePickerView.onConfirmHandler = { [weak self] _ in
                self?.didFinishSelectTime()
            }

            self.calendarContainer.transform = .init(translationX: 0, y: self.view.bounds.height)
            self.timeSelectionContainer.transform = .init(translationX: 0, y: self.view.bounds.height)

            self.calendarContainer.canledarView.setSelectDateObj(self.selectedTime ?? Date())
            let hour = self.selectedTime?.string(with: "HH") ?? "00"
            let min = self.selectedTime?.string(with: "mm") ?? "00"
            self.timeSelectionContainer.datePickerView.timePickerView.setSelectTime(type: .hour, value: hour)
            self.timeSelectionContainer.datePickerView.timePickerView.setSelectTime(type: .minute, value: min)

            self.calendarContainer.selectTimeButton.setTitle("\(hour):\(min)", for: .normal)
        }

        override func layoutContentView() {
            super.layoutContentView()
            self.contentView.removeFromSuperview()
        }

        func switchContent() {
            let next: UIView = self.displayingContent == self.timeSelectionContainer ? self.calendarContainer : self.timeSelectionContainer
            next.isHidden = false
            UIView.animate(withDuration: 0.3) {
                self.displayingContent.transform = .init(translationX: 0, y: self.view.bounds.height)
                next.transform = .identity
            } completion: { fin in
                self.displayingContent.isHidden = true
                self.displayingContent = next
            }
        }

        func didFinishSelectTime() {
            let yearMonthDayStr = self.calendarContainer.canledarView.selectDate.string(with: "yyyy-MM-dd")
            let hour = self.timeSelectionContainer.datePickerView.timePickerView.getSelectTime(type: .hour)
            let min = self.timeSelectionContainer.datePickerView.timePickerView.getSelectTime(type: .minute)
            let date_str = "\(yearMonthDayStr) \(hour):\(min)"
            self.selectedTime = Date.init(string: date_str, dateFormat: "yyyy-MM-dd HH:mm")
            self.dismiss(animated: true)
        }
    }
}

