//
//  SelectSharePermissionAlertViewController.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 19/6/2024.
//

import Foundation

class SelectSharePermissionAlertViewController: BaseViewController {

    let deviceId: String

    init(deviceId: String) {
        self.deviceId = deviceId
        super.init(nibName: nil, bundle: nil)
        self.modalTransitionStyle = .crossDissolve
        self.modalPresentationStyle = .custom
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// 外部监听选择完的结果
    lazy var didFinishedSelectPermissionPublisher: Combine.PassthroughSubject<[DeviceShare.SharePermission], Never> = .init()

    lazy var contentView: UIView = .init().then {
        $0.layer.cornerRadius = 16
        $0.layer.masksToBounds = true
        $0.backgroundColor = R.color.background_FFFFFF_white()
    }

    lazy var titleLabel: UILabel = .init().then {
        $0.textAlignment = .center
        $0.font = .systemFont(ofSize: 18, weight: .medium)
        $0.text = String.localization.localized("#", note: "配置访客权限")
    }

    lazy var contentTableViewController: SelectSharePermissionTableViewController = .init(dataSources: [], style: .grouped)

    lazy var bottomStackView: UIStackView = .init().then {
        $0.axis = .horizontal
        $0.distribution = .fillEqually
        $0.backgroundColor = R.color.background_FFFFFF_white()
    }

    lazy var cancelBtn: UIButton = .init(type: .custom).then {
        $0.setTitle(String.localization.localized("AA0059", note: "取消"), for: .normal)
        $0.setTitleColor(R.color.text_link_4A68A6(), for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
    }

    lazy var okBtn: UIButton = .init(type: .custom).then {
        $0.setTitle(String.localization.localized("AA0058", note: "确定"), for: .normal)
        $0.setTitleColor(R.color.text_link_4A68A6(), for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
    }

    var anyCancellables: Set<AnyCancellable> = []

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIView.animate(withDuration: 0.3) {
            self.view.backgroundColor = R.color.background_000000_40()
            self.contentView.transform = .identity
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        UIView.animate(withDuration: 0.3) {
            self.view.backgroundColor = .clear
            self.contentView.transform = .init(translationX: 0, y: self.view.size.height)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .clear

        self.contentView.transform = .init(translationX: 0, y: self.view.size.height)

        self.addChild(self.contentTableViewController)
        
        self.view.addSubview(self.contentView)
        self.contentView.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(16)
            make.leading.trailing.equalToSuperview()
        }

        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(25)
            make.centerX.equalToSuperview()
        }

        self.contentView.addSubview(self.contentTableViewController.view)
        self.contentTableViewController.view.snp.makeConstraints { make in
            make.top.equalTo(self.titleLabel.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(self.view).multipliedBy(0.6)
        }

        self.contentTableViewController.tableView.separatorStyle = .none

        self.bottomStackView.addArrangedSubview(self.cancelBtn)
        self.bottomStackView.addArrangedSubview(self.okBtn)
        self.contentView.addSubview(self.bottomStackView)
        self.bottomStackView.snp.makeConstraints { make in
            make.height.equalTo(56)
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(self.contentTableViewController.view.snp.bottom)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }

        let btnSeparator = UIView.init()
        btnSeparator.backgroundColor = R.color.lineSeparator()
        self.bottomStackView.addSubview(btnSeparator)
        btnSeparator.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(0.5)
            make.height.equalToSuperview().multipliedBy(0.6)
        }

        self.cancelBtn.tapPublisher.sink { [weak self] in
            self?.dismiss(animated: true)
        }.store(in: &self.anyCancellables)

        // 点击了确认按钮
        self.okBtn.tapPublisher.sink { [weak self] in
            // 取出数据, flatMap
            guard let dataSources = self?.contentTableViewController.dataSources else { return }
            let result = dataSources.flatMap({ $0 })
            // dismiss后, 往外发布选择后的结果
            self?.dismiss(animated: true, completion: {
                self?.didFinishedSelectPermissionPublisher.send(result)
                self?.didFinishedSelectPermissionPublisher.send(completion: .finished)
            })
        }.store(in: &self.anyCancellables)
    }
}
