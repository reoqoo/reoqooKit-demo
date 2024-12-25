//
//  ShareDevicesListViewController.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 13/6/2024.
//

import UIKit

class ShareDevicesListViewController: BaseViewController {
    
    private lazy var emptyView = CommonEmptyView(image: R.image.empty()!, text: String.localization.localized("AA0177", note: "暂无分享的设备"))
    
    lazy var topContainer: UIView = .init().then {
        $0.backgroundColor = R.color.background_F2F3F6_thinGray()
    }

    lazy var topLabel: UILabel = .init().then {
        $0.font = .systemFont(ofSize: 14)
        $0.textColor = R.color.text_000000_90()
        $0.numberOfLines = 0
        $0.text = String.localization.localized("AA0145", note: "选择要分享的设备")
    }

    lazy var tableView: UITableView = .init(frame: .zero, style: .insetGrouped).then {
        $0.delegate = self
        $0.dataSource = self
        $0.emptyDataSetSource = self
        $0.emptyDataSetDelegate = self
        $0.rowHeight = UITableView.automaticDimension
        $0.sectionHeaderHeight = 0.1
        $0.sectionFooterHeight = 0.1
        $0.separatorStyle = .none
        $0.register(DeviceTableViewCell.self, forCellReuseIdentifier: String.init(describing: DeviceTableViewCell.self))
    }

    lazy var bottomContainer: UIView = .init().then {
        $0.backgroundColor = R.color.background_F2F3F6_thinGray()
    }

    lazy var nextBtn: UIButton = .init(type: .custom).then {
        $0.setBackgroundColor(R.color.brand()!, for: .normal)
        $0.setBackgroundColor(R.color.brandHighlighted()!, for: .selected)
        $0.setBackgroundColor(R.color.brandDisable()!, for: .disabled)
        $0.setTitle(String.localization.localized("AA0377", note: "下一步"), for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 16)
        $0.setTitleColor(R.color.background_FFFFFF_white(), for: .normal)
        $0.layer.cornerRadius = 23
        $0.layer.masksToBounds = true
    }

    var devices: [DeviceEntity] = []

    var anyCancellables: Set<AnyCancellable> = []
    var disposeBag: DisposeBag = .init()

    var targetDeviceId: String?

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    init(targetDeviceId: String) {
        super.init(nibName: nil, bundle: nil)
        self.targetDeviceId = targetDeviceId
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = String.localization.localized("AA0050", note: "分享设备")

        self.view.addSubview(self.topContainer)
        self.topContainer.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
        }

        self.topContainer.addSubview(self.topLabel)
        self.topLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-12)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { make in
            make.top.equalTo(self.topContainer.snp.bottom)
            make.leading.trailing.equalToSuperview()
        }

        self.view.addSubview(self.bottomContainer)
        self.bottomContainer.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(self.tableView.snp.bottom)
        }

        self.bottomContainer.addSubview(self.nextBtn)
        self.nextBtn.snp.makeConstraints { make in
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-24)
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-24)
            make.top.equalToSuperview().offset(24)
            make.height.equalTo(46)
        }

        DeviceManager2.shared.generateDevicesObservable(keyPaths: [\.deviceId]).subscribe { [weak self] devices in
            self?.devices = devices?.toArray().filter({ $0.role == .master }) ?? []
            let idx = self?.devices.firstIndex(where: { $0.deviceId == self?.targetDeviceId }) ?? 0
            self?.tableView.reloadData()
            if self?.devices.isEmpty ?? true { return }
            DispatchQueue.main.async {
                self?.tableView.selectRow(at: .init(row: 0, section: idx), animated: false, scrollPosition: .middle)
            }
        }.disposed(by: self.disposeBag)

        self.nextBtn.tapPublisher.sink { [weak self] in
            let idx = self?.tableView.indexPathForSelectedRow?.section ?? 0
            guard let devId = self?.devices[safe_: idx]?.deviceId else { return }
            // 跳转到该设备的分享管理页
            let vc = ShareToManagedViewController.init(deviceId: devId)
            self?.navigationController?.pushViewController(vc, animated: true)
        }.store(in: &self.anyCancellables)
    }

}

extension ShareDevicesListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }

    func numberOfSections(in tableView: UITableView) -> Int { self.devices.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String.init(describing: DeviceTableViewCell.self), for: indexPath) as! DeviceTableViewCell
        cell.device = self.devices[indexPath.section]
        return cell
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 0.1 }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { 16 }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { UITableView.automaticDimension }
}

extension ShareDevicesListViewController: EmptyDataSetSource, EmptyDataSetDelegate {
    func customView(forEmptyDataSet scrollView: UIScrollView) -> UIView? { self.emptyView }
}
