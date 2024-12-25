//
//  IssueFeedbackViewController.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 4/9/2023.
//

import UIKit
import RQImagePicker

class IssueFeedbackTableViewController: BaseTableViewController, ScrollBaseViewAndKeyboardMatchable {

    var scrollable: UIScrollView { self.tableView }

    var rxDisposeBag: RxSwift.DisposeBag { self.disposeBag }

    var vm: IssueFeedbackViewController.ViewModel!
    private let disposeBag: DisposeBag = .init()
    var anyCancellables: Set<AnyCancellable> = []

    static var limitOfImages: Int = 9

    /// 问题描述输入框
    @IBOutlet weak var questionDescriptionTextView: UITextView!
    /// 问题输入框 Placeholder
    @IBOutlet weak var questionDescriptionTextViewPlaceholderLabel: UILabel!
    /// 问题描述图片 collectionView
    @IBOutlet weak var questionDescriptionImageCollectionView: UICollectionView!
    /// 问题描述输入字数
    @IBOutlet weak var lenghtOfIssueDescriptionLabel: UILabel!

    @IBOutlet weak var selectQuestionCategoryBtn: UIButton!
    @IBOutlet weak var questionCategoryTitleLabel: UILabel!

    @IBOutlet weak var selectDeviceBtn: UIButton!
    @IBOutlet weak var deviceSelectionTitleLabel: UILabel!
    
    /// "共享APP/设备日志"
    @IBOutlet weak var shareLogLabel: UILabel!
    /// "便于准确定位问题"
    @IBOutlet weak var shareLogDescLabel: UILabel!
    /// "共享应用及设备日志信息，以准确定位问题"
    @IBOutlet weak var shareDeviceInfoSwitch: UISwitch!

    /// 问题时间
    @IBOutlet weak var issueTimeLabel: UILabel!
    @IBOutlet weak var selectIssueTimeBtn: UIButton!

    @IBOutlet weak var contactWayTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.shareLogLabel.text = String.localization.localized("AA0606", note: "共享APP/设备日志")
        self.shareLogDescLabel.text = String.localization.localized("AA0607", note: "便于准确定位问题")
        
        self.tableView.allowsSelection = false
        self.tableView.estimatedRowHeight = 128
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.backgroundColor = R.color.background_F2F3F6_thinGray()
        self.tableView.tableHeaderView = .init(frame: .init(x: 0, y: 0, width: 0, height: 12))
        self.tableView.separatorColor = R.color.lineSeparator()!
        self.tableView.register(TableViewSectionHeader.self, forHeaderFooterViewReuseIdentifier: String.init(describing: TableViewSectionHeader.self))
        
        // CollectionView 注册 Cell
        self.questionDescriptionImageCollectionView.register(ImageCollectionViewCell.self, forCellWithReuseIdentifier: String.init(describing: ImageCollectionViewCell.self))
        self.questionDescriptionImageCollectionView.register(AddImageCollectionViewCell.self, forCellWithReuseIdentifier: String.init(describing: AddImageCollectionViewCell.self))

        self.questionDescriptionTextViewPlaceholderLabel.text = String.localization.localized("AA0612", note: "请详细描述您的建议或遇到的问题")
        
        self.contactWayTextField.placeholder = String.localization.localized("AA0262", note: "请留下您的电话或邮箱")

        self.questionDescriptionTextView.textPublisher.compactMap({ $0?.count }).sink { [weak self] length in
            if length < 10 {
                self?.lenghtOfIssueDescriptionLabel.textColor = UIColor.red
                self?.lenghtOfIssueDescriptionLabel.text = String.localization.localized("AA0608", note: "最少10个字")
            }else{
                self?.lenghtOfIssueDescriptionLabel.textColor = R.color.text_000000_38()!
                self?.lenghtOfIssueDescriptionLabel.text = String(length) + "/500"
            }
        }.store(in: &self.anyCancellables)

        self.selectQuestionCategoryBtn.tapPublisher.sink(receiveValue: { [weak self] _ in
            self?.selectIssueType()
        }).store(in: &self.anyCancellables)

        self.selectDeviceBtn.tapPublisher.sink(receiveValue: { [weak self] _ in
            self?.selectDevice()
        }).store(in: &self.anyCancellables)

        self.shareDeviceInfoSwitch.isOnPublisher.sink(receiveValue: { [weak self] isOn in
            self?.vm.shareLogsCheckboxValue = isOn
        }).store(in: &self.anyCancellables)

        self.selectIssueTimeBtn.tapPublisher.sink(receiveValue: { [weak self] _ in
            self?.selectTime()
        }).store(in: &self.anyCancellables)

        /// 使 "共享日志" CheckBox 绑定 vm 对应的模型
        self.vm.$shareLogsCheckboxValue.sink(receiveValue: { [weak self] isOn in
            self?.shareDeviceInfoSwitch.isOn = isOn
        }).store(in: &self.anyCancellables)

        // 绑定 "请选择设备" label
        self.vm.$deviceType.sink { [weak self] deviceType in
            if let deviceType = deviceType {
                self?.deviceSelectionTitleLabel.text = deviceType.description
            }else{
                let attributedStr = NSMutableAttributedString.init(string: String.localization.localized("AA0249", note: "设备分类"), attributes: [NSAttributedString.Key.foregroundColor: R.color.background_000000_40()!])
                attributedStr.append(NSMutableAttributedString(string: "*", attributes: [NSAttributedString.Key.foregroundColor: UIColor.red]))
                self?.deviceSelectionTitleLabel.attributedText = attributedStr
            }
        }.store(in: &self.anyCancellables)

        // 绑定 "请选择问题分类" label
        self.vm.$issueCategory.sink { [weak self] issueCategory in
            if let issueCategory = issueCategory {
                self?.questionCategoryTitleLabel.text = issueCategory.name
            }else{
                let attributedStr = NSMutableAttributedString.init(string: String.localization.localized("AA0241", note: "问题分类"), attributes: [NSAttributedString.Key.foregroundColor: R.color.background_000000_40()!])
                attributedStr.append(NSMutableAttributedString(string: "*", attributes: [NSAttributedString.Key.foregroundColor: UIColor.red]))
                self?.questionCategoryTitleLabel.attributedText = attributedStr
            }
        }.store(in: &self.anyCancellables)

        // 绑定 "发生时间" label
        self.vm.$issueHappendTime.map({
            $0.string(with: "yyyy-MM-dd HH:mm")
        }).sink(receiveValue: { [weak self] text in
            self?.issueTimeLabel.text = text
        }).store(in: &self.anyCancellables)

        // 绑定数据源变化, 刷新 CollectionView. debounce 以及 throttle 以节省算力
        self.vm.$imageCollectionViewDataSources.debounce(for: .milliseconds(300), scheduler: DispatchQueue.main).throttle(for: .microseconds(300), scheduler: DispatchQueue.main, latest: true).sink { [weak self] imageItems in
            self?.questionDescriptionImageCollectionView.reloadData()
        }.store(in: &self.anyCancellables)
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.contentView.backgroundColor = R.color.background_FFFFFF_white()!
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == 0 else { return nil }
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: String.init(describing: TableViewSectionHeader.self)) as? TableViewSectionHeader
        let attributedStr = NSMutableAttributedString.init(string: String.localization.localized("AA0251", note: "问题与建议"), attributes: [NSAttributedString.Key.foregroundColor: R.color.background_000000_40()!])
        attributedStr.append(NSMutableAttributedString(string: "*", attributes: [NSAttributedString.Key.foregroundColor: UIColor.red]))
        header?.label.attributedText = attributedStr
        return header
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { nil }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { 0.1 }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { UITableView.automaticDimension }
    
}

extension IssueFeedbackTableViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.vm.imageCollectionViewDataSources.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let imageItem = self.vm.imageCollectionViewDataSources[indexPath.item]
        // 添加按钮 样式
        if case .add = imageItem {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String.init(describing: AddImageCollectionViewCell.self), for: indexPath) as! AddImageCollectionViewCell
            return cell
        }
        // 展示图片样式
        if case .image = imageItem {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String.init(describing: ImageCollectionViewCell.self), for: indexPath) as! ImageCollectionViewCell
            return cell
        }
        fatalError("没有匹配的项目")
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? ImageCollectionViewCell {
            let imageItem = self.vm.imageCollectionViewDataSources[indexPath.item]
            cell.externalAnyCancellables = []
            cell.imageItem = imageItem
            cell.deleteBtnTapPublisher.sink(receiveValue: { [weak self] _ in
                self?.vm.removeImage(at: indexPath.item)
            }).store(in: &cell.externalAnyCancellables)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? ImageCollectionViewCell {
            cell.externalAnyCancellables = []
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == self.questionDescriptionImageCollectionView, case .add = self.vm.imageCollectionViewDataSources[indexPath.item] {
            // 添加图片
            self.selectAlbumImages()
        }
    }
}

// MARK: UITextViewDelegate
extension IssueFeedbackTableViewController: UITextViewDelegate {

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if textView != self.questionDescriptionTextView { return true }
        let result = (textView.text as NSString).replacingCharacters(in: range, with: text)
        self.questionDescriptionTextViewPlaceholderLabel.isHidden = !result.isEmpty
        if result.count >= 500 {
            MBProgressHUD.showHUD_DispatchOnMainThread(text: String.localization.localized("AA0265", note: "最多支持500个字符"))
        }
        return result.count <= 500
    }
}

// MARK: UITextFieldDelegate
extension IssueFeedbackTableViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return true
    }
}

// MARK: Helper
extension IssueFeedbackTableViewController {
    func selectAlbumImages() {
        let vc = ImagePickerViewController.init(mediaTypes: [.image], selectLimit: .maxLimit(self.vm.remainderQuotaOfImages()))
        vc.delegate = self
        self.present(vc, animated: true)
    }

    func selectIssueType() {
        let vc = IssueFeedbackViewController.IssueTypeSelectionViewController.init(issueCategorys: self.vm.issueCategorys)
        vc.selectedIssueCategory = self.vm.issueCategory
        self.present(vc, animated: true)
        vc.$selectedIssueCategory.sink(receiveValue: { [weak self] category in
            self?.vm.issueCategory = category
        }).store(in: &self.anyCancellables)
    }

    func selectDevice() {
        let vc = IssueFeedbackViewController.DeviceSelectionViewController.init()
        vc.deviceType = self.vm.deviceType
        self.present(vc, animated: true)
        vc.$deviceType.sink(receiveValue: { [weak self] deviceType in
            self?.vm.deviceType = deviceType
        }).store(in: &self.anyCancellables)
    }

    func selectTime() {
        let vc = IssueFeedbackViewController.CalendarSelectionViewController.init()
        vc.selectedTime = self.vm.issueHappendTime
        self.present(vc, animated: true)
        vc.$selectedTime.sink(receiveValue: { [weak self] time in
            self?.vm.issueHappendTime = time ?? Date()
        }).store(in: &self.anyCancellables)
    }
}

// MARK: ImagePickerViewControllerDelegate
extension IssueFeedbackTableViewController: ImagePickerViewControllerDelegate {
    func imagePickerViewController(_ controller: ImagePickerViewController, didFinishTackingMedia media: ImagePickerViewController.MediaItem) {
        self.vm.insertImages([media])
        controller.dismiss(animated: true)
    }

    func imagePickerViewController(_ controller: ImagePickerViewController, didFinishSelectedAssets assets: [ImagePickerViewController.MediaItem]) {
        self.vm.insertImages(assets)
        controller.dismiss(animated: true)
    }

    // 达到最大选择量限制
    func imagePickerViewControllerDidTriggeringMaxSelectLimit(_ controller: ImagePickerViewController) {
        
    }
}
