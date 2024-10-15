//
//  DeviceDidSharedDetailViewController.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 17/6/2024.
//

import Foundation

extension ShareToManagedViewController {
    struct TopTableViewItem {
        var imageURL: URL?
        var text: String
        var indicator: Bool = true
        var cellClass: AnyClass
    }
}

class ShareToManagedViewController: BaseViewController {

    lazy var vm: ViewModel = .init(deviceId: self.deviceId)

    let deviceId: String
    
    init(deviceId: String) {
        self.deviceId = deviceId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    lazy var topTableViewItems: [TopTableViewItem] = {
        let dev = DeviceManager2.fetchDevice(self.deviceId)
        let devName = dev?.remarkName ?? ""
        var items: [TopTableViewItem] = [
            .init(text: devName, cellClass: DeviceTableViewCell.self),
            .init(text: String.localization.localized("AA0648", note: "添加共享好友"), cellClass: CommonTableViewCell.self),
            .init(text: String.localization.localized("AA0647", note: "设备权限"), cellClass: CommonTableViewCell.self)
        ]
        return items
    }()

    lazy var topTableView: UITableView = .init(frame: .zero, style: .insetGrouped).then {
        $0.delegate = self
        $0.dataSource = self
        $0.separatorInset = .init(top: 0, left: 12, bottom: 0, right: 12)
        $0.separatorColor = R.color.lineSeparator()
        $0.sectionHeaderHeight = 0.1
        $0.sectionFooterHeight = 0.1
        $0.register(CommonTableViewCell.self, forCellReuseIdentifier: String.init(describing: CommonTableViewCell.self))
        $0.register(DeviceTableViewCell.self, forCellReuseIdentifier: String.init(describing: DeviceTableViewCell.self))
        $0.estimatedRowHeight = 88
        $0.isScrollEnabled = false
    }

    lazy var midLabel: UILabel = .init().then {
        $0.text = String.localization.localized("AA0159", note: "已经分享的好友")
        $0.font = .systemFont(ofSize: 16)
        $0.textColor = R.color.text_000000_60()
    }

    lazy var guestTableView: UITableView = .init(frame: .zero, style: .insetGrouped).then {
        $0.delegate = self
        $0.dataSource = self
        $0.separatorInset = .init(top: 0, left: 60, bottom: 0, right: 12)
        $0.separatorColor = R.color.lineSeparator()
        $0.sectionHeaderHeight = 0.1
        $0.sectionFooterHeight = 0.1
        $0.register(UserTableViewCell.self, forCellReuseIdentifier: String.init(describing: UserTableViewCell.self))
    }

    lazy var stopShareAllBtn: UIButton = .init(type: .custom).then {
        $0.setStyle_0()
        $0.layer.cornerRadius = 23
        $0.layer.masksToBounds = true
        $0.setTitle(String.localization.localized("AA0649", note: "全部移除"), for: .normal)
    }

    var anyCancellables: Set<AnyCancellable> = []
    var disposeBag: DisposeBag = .init()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = String.localization.localized("AA0180", note: "我的分享")
        
        self.view.addSubview(self.topTableView)
        self.topTableView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(16)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(224)
        }

        self.view.addSubview(self.midLabel)
        self.midLabel.snp.makeConstraints { make in
            make.top.equalTo(self.topTableView.snp.bottom).offset(18)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        self.view.addSubview(self.guestTableView)
        self.guestTableView.snp.makeConstraints { make in
            make.top.equalTo(self.midLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
        }

        self.view.addSubview(self.stopShareAllBtn)
        self.stopShareAllBtn.snp.makeConstraints { make in
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-24)
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-24)
            make.height.equalTo(46)
            make.top.equalTo(self.guestTableView.snp.bottom).offset(12)
        }

        self.vm.$situation.sink { [weak self] situation in
            self?.guestTableView.reloadData()
        }.store(in: &self.anyCancellables)

        self.vm.$status.sink { [weak self] status in
            switch status {
            case .willRequestSharedSituation:
                MBProgressHUD.showLoadingHUD_DispatchOnMainThread(tag: 100)
            case .didFinishedRequestSharedSituation:
                MBProgressHUD.fromTag(100)?.hide(animated: true)
            case let .didFinishedRemoveGuest(result):
                self?.didFinishedRemoveGuestHandling(result)
            default: break
            }
        }.store(in: &self.anyCancellables)

        self.stopShareAllBtn.tapPublisher.sink { [weak self] _ in
            self?.stopShareAll()
        }.store(in: &self.anyCancellables)

        let tableViewContentSizeChangedPublisher = self.topTableView.publisher(for: \.contentSize)
            .map({
                CGSize.init(width: floor($0.width), height: floor($0.height))
            })
            .throttle(for: 0.3, scheduler: DispatchQueue.main, latest: true)
            .removeDuplicates()

        let tableViewContentInsetChangedPublisher = self.topTableView.publisher(for: \.adjustedContentInset)
            .map({
                UIEdgeInsets(top: floor($0.top), left: floor($0.left), bottom: floor($0.bottom), right: floor($0.right))
            })
            .throttle(for: 0.3, scheduler: DispatchQueue.main, latest: true)
            .removeDuplicates()

        Publishers.CombineLatest.init(tableViewContentSizeChangedPublisher, tableViewContentInsetChangedPublisher)
            .throttle(for: 0.3, scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] (size, inset) in
                self?.topTableView.snp.updateConstraints({ make in
                    make.height.equalTo(size.height + inset.top)
                })
                self?.topTableView.beginUpdates()
                self?.view.layoutIfNeeded()
                self?.topTableView.endUpdates()
            }.store(in: &self.anyCancellables)
    }
}

extension ShareToManagedViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.topTableView {
            return self.topTableViewItems.count
        }
        if tableView == self.guestTableView {
            return self.vm.situation?.guestList.count ?? 0
        }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == self.topTableView {
            let item = self.topTableViewItems[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: String.init(describing: item.cellClass), for: indexPath)
            return cell
        }
        if tableView == self.guestTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: String.init(describing: UserTableViewCell.self), for: indexPath) as! UserTableViewCell
            cell.guest = self.vm.situation?.guestList[indexPath.row]
            return cell
        }
        fatalError("没有匹配的cell")
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? UserTableViewCell, let guestId = self.vm.situation?.guestList[indexPath.row].guestId {
            cell.tapOnRemoveBtnCancellable = []
            cell.removeBtn.tapPublisher.sink { [weak self] _ in
                self?.stopShare2User(guestId: guestId)
            }.store(in: &cell.tapOnRemoveBtnCancellable)
        }
        if let cell = cell as? DeviceTableViewCell {
            let dev = DeviceManager2.fetchDevice(self.deviceId)
            cell.name = dev?.remarkName
            dev?.getImageURLObservable().subscribe(onSuccess: { url in
                cell.imageURL = url
            }).disposed(by: self.disposeBag)
        }
        if let cell = cell as? CommonTableViewCell {
            cell.label.text = self.topTableViewItems[indexPath.row].text
        }
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? UserTableViewCell else { return }
        cell.tapOnRemoveBtnCancellable = []
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 0.1 }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { 0.1 }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if tableView == self.topTableView {
            let item = self.topTableViewItems[indexPath.row]
            if item.text == String.localization.localized("AA0648", note: "添加共享好友") {
                self.addGuest()
            }
            if item.text == String.localization.localized("AA0647", note: "设备权限") {
                let vc = DevicePermissionConfigurationViewController.init(deviceId: self.deviceId)
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
}

// MARK: Helper
extension ShareToManagedViewController {

    func addGuest() {
        // 先检查是否分享达到上限
        guard let situation = self.vm.situation, let maxCount = self.vm.situation?.guestCount, let currentCount = self.vm.situation?.guestList.count else { return }
        if maxCount <= currentCount {
            self.alertToShareManaged(sharedSituation: situation)
            return
        }
        // 跳转到分享设备页面
        let vc = ShareDeviceConfirmViewController(deviceId: self.deviceId)
        self.navigationController?.pushViewController(vc, animated: true)
    }

    func didFinishedRemoveGuestHandling(_ result: Result<DeviceShare.DeviceShareSituation, Swift.Error>) {
        if case let .failure(err) = result {
            MBProgressHUD.showHUD_DispatchOnMainThread(text: err.localizedDescription)
        }
        if case let .success(situation) = result {
            MBProgressHUD.showHUD_DispatchOnMainThread(text: String.localization.localized("AA0189", note: "停止共享成功"))
            if situation.guestList.isEmpty {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }

    /// 点击了移除目标访客
    func stopShare2User(guestId: String) {
        let property = ReoqooPopupViewProperty()
        property.message = String.localization.localized("AA0185", note: "确定要移除该分享好友吗？")
        let cancelAction = IVPopupAction(title: String.localization.localized("AA0059", note: "取消"), style: .custom, color: R.color.text_link_4A68A6(), handler: {})
        let okAction = IVPopupAction(title: String.localization.localized("AA0058", note: "确定"), style: .custom, color: R.color.button_destructive_FA2A2D(), handler: { [weak self] in
            self?.vm.removeGuest(guestId: guestId)
        })
        IVPopupView(property: property, actions: [cancelAction, okAction]).show()
    }

    /// 点击了停止共享
    func stopShareAll() {
        let property = ReoqooPopupViewProperty()
        property.message = String.localization.localized("AA0650", note: "确定要全部移除吗？")

        let cancelAction = IVPopupAction(title: String.localization.localized("AA0059", note: "取消"), style: .custom, color: R.color.text_link_4A68A6(), handler: {})
        let okAction = IVPopupAction(title: String.localization.localized("AA0058", note: "确定"), style: .custom, color: R.color.button_destructive_FA2A2D(), handler: { [weak self] in
            self?.vm.event = .removeAllGuest
        })
        let popupView = IVPopupView(property: property, actions: [cancelAction, okAction])
        popupView.show()
    }

    /// 弹框提示访客已满
    func alertToShareManaged(sharedSituation: DeviceShare.DeviceShareSituation) {
        let property = ReoqooPopupViewProperty()
        property.message = String.localization.localized("AA0146", note: "最多只能添加%@个访客，如果要继续分享给其他人，请先删除部分访客!", args: String(sharedSituation.guestCount))
        property.messageAlign = .left

        let cancelAction = IVPopupAction(title: String.localization.localized("AA0131", note: "知道了"), style: .custom, color: R.color.text_link_4A68A6(), handler: {})
        let popupView = IVPopupView(property: property, actions: [cancelAction])
        popupView.show()
    }

}
