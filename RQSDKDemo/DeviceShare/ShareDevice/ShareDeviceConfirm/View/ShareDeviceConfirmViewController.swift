//
//  ShareDeviceConfirmViewController.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 13/6/2024.
//

import UIKit

class ShareDeviceConfirmViewController: BaseViewController {

    lazy var vm: ViewModel = .init(deviceId: self.deviceId)

    lazy var topContainer: UIView = .init().then {
        $0.backgroundColor = R.color.background_F2F3F6_thinGray()
    }

    private lazy var topLabel = UILabel().then {
        $0.backgroundColor = .clear
        $0.text = String.localization.localized("AA0148", note: "输入要共享设备的XXXXXXXX账号")
        $0.font = .systemFont(ofSize: 14, weight: .regular)
        $0.textColor = R.color.text_000000_90()
        $0.numberOfLines = 0
    }

    private lazy var accountTextField = UITextField().then {
        $0.backgroundColor = R.color.text_FFFFFF()
        $0.layer.cornerRadius = 12
        $0.clearButtonMode = .whileEditing
        $0.keyboardType = .asciiCapable
        $0.returnKeyType = .done
        $0.placeholder = String.localization.localized("AA0149", note: "请输入XXXXXXXX账号")
        $0.leftViewMode = .always
        $0.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: $0.height)) //左边距
        $0.delegate = self
    }

    lazy var tableViewDescriptionLabel: UILabel = .init().then {
        $0.backgroundColor = .clear
        $0.text = String.localization.localized("AA0150", note: "最近分享")
        $0.font = .systemFont(ofSize: 14, weight: .regular)
        $0.textColor = R.color.text_000000_90()
        $0.numberOfLines = 0
    }

    lazy var tableView: UITableView = .init(frame: .zero, style: .insetGrouped).then {
        $0.delegate = self
        $0.dataSource = self
        $0.rowHeight = UITableView.automaticDimension
        $0.sectionHeaderHeight = 0.1
        $0.sectionFooterHeight = 0.1
        $0.separatorInset = .init(top: 0, left: 60, bottom: 0, right: 12)
        $0.separatorColor = R.color.lineSeparator()
        $0.showsVerticalScrollIndicator = false
        $0.keyboardDismissMode = .onDrag
        $0.register(UserTableViewCell.self, forCellReuseIdentifier: String.init(describing: UserTableViewCell.self))
    }

    lazy var bottomContainer: UIView = .init().then {
        $0.backgroundColor = R.color.background_F2F3F6_thinGray()
    }

    lazy var shareBtn: UIButton = .init(type: .custom).then {
        $0.setBackgroundColor(R.color.brand()!, for: .normal)
        $0.setBackgroundColor(R.color.brandHighlighted()!, for: .selected)
        $0.setBackgroundColor(R.color.brandDisable()!, for: .disabled)
        $0.setTitle(String.localization.localized("AA0055", note: "共享"), for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 16)
        $0.setTitleColor(R.color.background_FFFFFF_white(), for: .normal)
        $0.layer.cornerRadius = 23
        $0.layer.masksToBounds = true
    }

    lazy var shareFace2FaceBtn: UIButton = .init(type: .custom).then {
        $0.setTitleColor(R.color.text_link_4A68A6(), for: .normal)
        $0.setTitle(String.localization.localized("AA0151", note: "面对面分享"), for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 16)
    }

    var anyCancellables: Set<AnyCancellable> = []

    var deviceId: String

    init(deviceId: String) {
        self.deviceId = deviceId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = String.localization.localized("AA0648", note: "添加共享好友")

        self.view.addSubview(self.topContainer)
        self.topContainer.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
        }

        self.topContainer.addSubview(self.topLabel)
        self.topLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        self.topContainer.addSubview(self.accountTextField)
        self.accountTextField.snp.makeConstraints { make in
            make.top.equalTo(self.topLabel.snp.bottom).offset(12)
            make.bottom.equalToSuperview().offset(-12)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(56)
        }

        self.view.addSubview(self.tableViewDescriptionLabel)
        self.tableViewDescriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(self.topContainer.snp.bottom).offset(36)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { make in
            make.top.equalTo(self.tableViewDescriptionLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
        }

        self.view.addSubview(self.bottomContainer)
        self.bottomContainer.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(self.tableView.snp.bottom)
        }

        self.bottomContainer.addSubview(self.shareBtn)
        self.shareBtn.snp.makeConstraints { make in
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-24)
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-24)
            make.height.equalTo(46)
        }

        self.bottomContainer.addSubview(self.shareFace2FaceBtn)
        self.shareFace2FaceBtn.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(self.shareBtn.snp.top).offset(-12)
        }

        self.accountTextField.publisher(for: \.text).sink { [weak self] text in
            self?.shareBtn.isEnabled = !(text?.isEmpty ?? true)
        }.store(in: &self.anyCancellables)

        self.vm.$status.sink { [weak self] status in
            // 最近分享
            if case .didFinishRequestRecentlyGuest = status {
                self?.tableView.reloadData()
            }
            // 通过输入的内容查询用户
            if case let .didCheckAccount(result) = status {
                self?.checkAccountResultHandling(result: result)
            }
            // 分享请求完成
            if case let .didFinishShareRequest(result) = status {
                self?.shareResultHandling(result)
            }
        }.store(in: &self.anyCancellables)

        self.shareBtn.tapPublisher.sink { [weak self] in
            guard let account = self?.accountTextField.text else { return }
            guard let deviceId = self?.deviceId else { return }
            self?.vm.event = .checkAccount(account: account, deviceId: deviceId)
        }.store(in: &self.anyCancellables)

        self.shareFace2FaceBtn.tapPublisher.sink { [weak self] in
            guard let vm = self?.vm, let deviceId = self?.deviceId else { return }
            let vc = ShareByFace2FaceViewController.init(vm: vm, deviceId: deviceId)
            self?.navigationController?.pushViewController(vc, animated: true)
        }.store(in: &self.anyCancellables)

        self.vm.event = .shareConfirmViewDidLoad
    }

}

extension ShareDeviceConfirmViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.vm.recentlyShareGuests.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String.init(describing: UserTableViewCell.self), for: indexPath) as! UserTableViewCell
        cell.guest = self.vm.recentlyShareGuests[indexPath.row]
        return cell
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 0.1 }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { 0.1 }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.accountTextField.text = self.vm.recentlyShareGuests[indexPath.row].account
    }
}

extension ShareDeviceConfirmViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let isValid = !string.containsChinese() //判断是否有中文
        if let selectedIndexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: selectedIndexPath, animated: false)
        }
        return isValid
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        if let selectedIndexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: selectedIndexPath, animated: false)
        }
        return true
    }
}

// MARK: Helper
extension ShareDeviceConfirmViewController {
    /// 分享第一步: 查询用户
    func checkAccountResultHandling(result: Result<[DeviceShare.GuestUser], Swift.Error>) {
        if case let .success(users) = result {
            // 如果用户只有一个, 直接发起分享请求
            if users.count == 1 {
                guard let user = users.first else { return }
                self.presentShareConfirmAlert(user)
            }else{
                // 多个用户, 弹出列表让用户选择
                self.presentUserSelectAlert(users)
            }
        }
        if case let .failure(err) = result {
            MBProgressHUD.showHUD_DispatchOnMainThread(text: err.localizedDescription)
        }
    }

    /// 分享第二步: 分享请求
    func shareResultHandling(_ result: Result<Void, Swift.Error>) {
        guard case let .failure(err) = result else {
            MBProgressHUD.showHUD_DispatchOnMainThread(text: String.localization.localized("AA0156", note: "分享成功"))
            self.navigationController?.popToRootViewController(animated: true)
            return
        }
        MBProgressHUD.showHUD_DispatchOnMainThread(text: err.localizedDescription)
    }

    /// 弹出确认分享框
    func presentShareConfirmAlert(_ user: DeviceShare.GuestUser) {
        let property = ReoqooPopupViewProperty()
        property.message = String.localization.localized("AA0154", note: "确定将设备分享给%@使用？", args: user.description)
        property.messageAlign = .left

        IVPopupView(property: property, actions: [
            IVPopupAction(title: String.localization.localized("AA0059", note: "取消"), style: .custom, color: R.color.text_link_4A68A6(), handler: {}),
            IVPopupAction(title: String.localization.localized("AA0058", note: "确定"), style: .custom, color: R.color.text_link_4A68A6(), handler: { [weak self] in
                guard let deviceId = self?.deviceId else { return }
                self?.vm.event = .share2User(user: user, deviceId: deviceId)
            })
        ])
        .show()
    }

    // 多个用户, 弹出列表让用户选择
    func presentUserSelectAlert(_ users: [DeviceShare.GuestUser]) {
        let cancelAction = IVPopupAction(title: String.localization.localized("AA0059", note: "取消"))

        let headerLabel = UILabel().then {
            $0.frame = .init(x: 0, y: 0, width: self.view.width, height: 64)
            $0.textAlignment = .center
            $0.textColor = R.color.text_000000_90()
            $0.font = .systemFont(ofSize: 18, weight: .medium)
            $0.text = String.localization.localized("AA0359", note: "查到多个账号，请选择")
        }

        IVPopover.show(headView: headerLabel, cellViewClass: IVPopoverTableCell.self, rowHeight: 56, models: users, actions: [cancelAction]) { view, model, row in

            guard let cell = view as? IVPopoverTableCell,
                  let visitorUser = model as? DeviceShare.GuestUser else { return }

            cell.accessoryType = .disclosureIndicator
            cell.titleAlignment = .left
            cell.title = visitorUser.description

        } tableViewDidSelect: { [weak self] view, model, row in
            guard let user = model as? DeviceShare.GuestUser else { return }
            // 弹出分享确认弹框
            self?.presentShareConfirmAlert(user)
        }
    }
}
