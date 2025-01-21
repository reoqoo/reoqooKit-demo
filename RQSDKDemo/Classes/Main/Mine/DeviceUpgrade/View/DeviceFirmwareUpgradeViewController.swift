//
//  DeviceUpgradeViewController.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 7/10/2023.
//

import Foundation
import RTRootNavigationController

class DeviceFirmwareUpgradeViewController: BaseViewController {

    let vm: ViewModel = .init()

    /// 如果从小豚插件进入, 需要传入插件对应的设备的ID
    var targetDeviceId: String?

    lazy var tableView: UITableView = .init(frame: .zero, style: .insetGrouped).then {
        $0.delegate = self
        $0.dataSource = self
        $0.allowsSelection = false
        $0.emptyDataSetSource = self
        $0.emptyDataSetDelegate = self
        $0.showsVerticalScrollIndicator = false
        $0.showsHorizontalScrollIndicator = false
        $0.sectionHeaderHeight = 0.1
        $0.sectionFooterHeight = 12
        $0.rowHeight = UITableView.automaticDimension
        $0.contentInset = .init(top: 0, left: 0, bottom: 88, right: 0)
        $0.register(DeviceTableViewCell.self, forCellReuseIdentifier: String.init(describing: DeviceTableViewCell.self))
    }

    lazy var checkUpgradeBtn: UIButton = .init(type: .custom).then {
        $0.layer.cornerRadius = 23
        $0.layer.masksToBounds = true
        $0.setStyle_0()
        $0.setTitleColor(R.color.text_FFFFFF(), for: .normal)
        $0.setTitle(String.localization.localized("AA0341", note: "检查更新"), for: .normal)
    }

    lazy var updateAllBtn: UIButton = .init(type: .custom).then {
        $0.layer.cornerRadius = 23
        $0.layer.masksToBounds = true
        $0.setStyle_0()
        $0.setTitleColor(R.color.text_FFFFFF(), for: .normal)
        $0.setTitle(String.localization.localized("AA0346", note: "全部升级"), for: .normal)
    }

    var showTipsHeader: Bool = false {
        didSet {
            if self.showTipsHeader == oldValue { return }
            if self.showTipsHeader {
                let header = UpgradeTipsHeader()
                self.tableView.tableHeaderView = header
                header.snp.makeConstraints { make in
                    make.width.equalToSuperview()
                }
                self.tableView.performBatchUpdates {}
            }else{
                self.tableView.tableHeaderView = UIView.init(frame: .init(x: 0, y: 0, width: 0, height: 16))
                self.tableView.performBatchUpdates {}
            }
        }
    }

    let disposeBag: DisposeBag = .init()

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
    }

    override func viewDidLoad() {

        self.title = String.localization.localized("AA0219", note: "设备升级")

        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.view.addSubview(self.updateAllBtn)
        self.updateAllBtn.snp.makeConstraints { make in
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-24)
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-24)
            make.height.equalTo(46)
        }

        self.view.addSubview(self.checkUpgradeBtn)
        self.checkUpgradeBtn.snp.makeConstraints { make in
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-24)
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-24)
            make.height.equalTo(46)
        }

        // 检查更新按钮点击
        self.checkUpgradeBtn.rx.tap.bind { [weak self] in
            self?.startCheck()
        }.disposed(by: self.disposeBag)

        // 更新全部按钮点击
        self.updateAllBtn.rx.tap.bind { [weak self] in
            self?.vm.updateAll()
        }.disposed(by: self.disposeBag)
        
        // 监听vm状态
        self.vm.$status.bind { [weak self] status in
            switch status {
            case let .didFinishCheckingDevicesUpgrade(result):
                self?.finishCheckingDeviceUpgradeWithResult(result)
            case let .deviceDidStartUpgrade(deviceId):
                self?.removeViewControllerIfNeed(deviceId: deviceId)
            case let .deviceFirmwareUpgradeSuccess(device):
                let toast = device.remarkName + String.localization.localized("AA0538", note: "升级成功")
                MBProgressHUD.showHUD_DispatchOnMainThread(text: toast)
            case let .deviceFirmwareUpgradeFailure(device, description):
                let toast = device.remarkName + String.localization.localized("AA0539", note: "升级失败，请稍后重试")
                MBProgressHUD.showHUD_DispatchOnMainThread(text: toast)
            case .idle:
                break
            }
        }.disposed(by: self.disposeBag)
        
        // 监听当前是否有设备正在升级
        self.vm.updatingDevicesObservable
            .delay(.milliseconds(500), scheduler: MainScheduler.asyncInstance)
            .map({ !$0.isEmpty }).bind { [weak self] isAnyDeviceUpdating in
                self?.showTipsHeader = isAnyDeviceUpdating
            }.disposed(by: self.disposeBag)
        
        // 控制 "更新全部" 按钮 enable 状态
        Observable.combineLatest(self.vm.updatingDevicesObservable, FirmwareUpgradeCenter.shared.$tasks).map({
            $0.0.count < $0.1.count
        }).bind(to: self.updateAllBtn.rx.isEnabled).disposed(by: self.disposeBag)
        
        // 监听 View 状态, didAppear 时才执行 startCheck, 否则执行太快屏幕会闪一下
        self.$viewStatus.filter({ $0 == .didAppear }).first().subscribe { [weak self] _ in
            // 开始检查新版本
            self?.startCheck()
        }.disposed(by: self.disposeBag)

        // 监听tableView数据源变化
        self.vm.$tableViewDataSources.subscribe { [weak self] items in
            self?.tableView.reloadData()
        }.disposed(by: self.disposeBag)
    }

}

// MARK: Helper
extension DeviceFirmwareUpgradeViewController {
    func startCheck() {
        MBProgressHUD.showLoadingHUD_DispatchOnMainThread(text: String.localization.localized("AA0340", note: "正在检测新版本..."), isMask: true, autoDismissAfter: 1, tag: 100)
        self.vm.processEvent(.startCheck)
    }

    func finishCheckingDeviceUpgradeWithResult(_ result: Result<[TableViewCellItem], Swift.Error>) {
        self.checkUpgradeBtn.isHidden = false
        self.updateAllBtn.isHidden = true
        if case let .success(items) = result {
            self.updateAllBtn.isHidden = items.isEmpty
            self.checkUpgradeBtn.isHidden = !items.isEmpty
        }
        if case let .failure(err) = result {
            MBProgressHUD.showHUD_DispatchOnMainThread(text: err.localizedDescription)
        }
    }
}

extension DeviceFirmwareUpgradeViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { self.vm.tableViewDataSources.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String.init(describing: DeviceTableViewCell.self), for: indexPath) as! DeviceTableViewCell
        cell.item = self.vm.tableViewDataSources[indexPath.section]
        return cell
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? DeviceTableViewCell else { return }
        // 展开折叠按钮点击
        cell.versionBtnClickedObservable.bind { [weak self] _ in
            self?.vm.tableViewDataSources[indexPath.section].isExpanded.toggle()
            self?.tableView.performBatchUpdates({
                self?.tableView.reloadRows(at: [indexPath], with: .automatic)
            })
        }.disposed(by: cell.extraDisposeBag)
        // 升级按钮点击
        cell.upgradeBtnClickedObservable.bind { [weak self] in
            // 发起升级
            self?.vm.processEvent(.updateDeviceAtIndex(indexPath.section))
        }.disposed(by: cell.extraDisposeBag)
        // 重试按钮点击
        cell.retryBtnClickedObservable.bind { [weak self] in
            self?.presentRetryAlertAtIndex(indexPath.section)
        }.disposed(by: cell.extraDisposeBag)
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? DeviceTableViewCell else { return }
        cell.extraDisposeBag = .init()
    }
}

extension DeviceFirmwareUpgradeViewController: EmptyDataSetSource, EmptyDataSetDelegate {

    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? { R.image.mineDeviceUpgradeEmpty() }

    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let res = NSMutableAttributedString.init(string: String.localization.localized("AA0342", note: "所有设备已是最新版本"))
        res.addAttributes([.font: UIFont.systemFont(ofSize: 14), .foregroundColor: R.color.text_000000_60()!], range: .init(location: 0, length: res.length))
        return res
    }

    func verticalOffset(forEmptyDataSet scrollView: UIScrollView) -> CGFloat { -88 }
    
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView) -> Bool { true }

}

// MARK: Helper
extension DeviceFirmwareUpgradeViewController {
    func presentRetryAlertAtIndex(_ index: Int) {
        guard let device = self.vm.tableViewDataSources[safe_: index]?.device else { return }
        let alertContent = device.remarkName + String.localization.localized("AA0539", note: "升级失败，请稍后重试")
        let cancelAction = IVPopupAction.init(title: String.localization.localized("AA0059", note: "取消"), style: .custom, color: R.color.text_link_4A68A6(), font: .systemFont(ofSize: 16, weight: .medium))
        let retryAction = IVPopupAction.init(title: String.localization.localized("AA0352", note: "重新升级"), style: .custom, color: R.color.text_link_4A68A6(), font: .systemFont(ofSize: 16, weight: .medium)) { [weak self] in
            self?.vm.processEvent(.updateDeviceAtIndex(index))
        }
        let vc = ReoqooAlertViewController(alertContent: .string(alertContent), actions: [cancelAction, retryAction])
        self.present(vc, animated: true)
    }

    /// 点击升级后, 检查视图栈中是否有非 Reoqoo原生页面, 如有, 将他们移除
    func removeViewControllerIfNeed(deviceId: String) {
        guard self.targetDeviceId == deviceId else { return }
        var targets: [UIViewController] = []
        self.rt_navigationController.viewControllers.forEach({
            guard let contentViewController = ($0 as? RTContainerController)?.contentViewController else { return }
            if !contentViewController.isKind(of: BaseViewController.self) &&
                !contentViewController.isKind(of: BaseTableViewController.self) &&
                !contentViewController.isKind(of: BasicTabbarController.self) {
                targets.append($0)
            }
        })
        var viewControllers = self.rt_navigationController.viewControllers
        viewControllers.removeAll(where: { targets.contains($0) })
        self.rt_navigationController.viewControllers = viewControllers
    }
}
