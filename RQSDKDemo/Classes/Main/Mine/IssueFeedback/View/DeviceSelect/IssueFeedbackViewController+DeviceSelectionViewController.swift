//
//  IssueFeedbackViewController+DeviceSelectionViewController.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 8/9/2023.
//

import Foundation

extension IssueFeedbackViewController {
    class DeviceSelectionViewController: PageSheetStyleViewController, UITableViewDataSource, UITableViewDelegate {

        class TableViewCell: UITableViewCell {
            
            var item: IssueFeedbackViewController.DeviceType? {
                didSet {
                    if case let .device(device) = self.item {
                        self.deviceNameLabel.text = device.remarkName
                        self.deviceIDLabel.text = String.localization.localized("AA0556", note: "设备ID：") + (device.deviceId)
                    }else{
                        self.deviceNameLabel.text = String.localization.localized("AA0454", note: "不选择设备")
                    }
                }
            }

            lazy var deviceNameLabel: UILabel = .init().then {
                $0.font = .systemFont(ofSize: 16)
                $0.textColor = R.color.text_000000_90()
            }

            lazy var deviceIDLabel: UILabel = .init().then {
                $0.font = .systemFont(ofSize: 14)
                $0.textColor = R.color.text_000000_60()
            }

            lazy var checkBox: UIButton = .init(type: .custom).then {
                $0.isUserInteractionEnabled = false
                $0.setImage(R.image.commonCheckbox_1Deselect(), for: .normal)
                $0.setImage(R.image.commonCheckbox_1Selected(), for: .selected)
            }

            override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
                super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)

                self.selectionStyle = .none
                
                let stackView: UIStackView = .init(arrangedSubviews: [self.deviceNameLabel, self.deviceIDLabel])
                stackView.axis = .vertical

                self.contentView.addSubview(stackView)
                stackView.snp.makeConstraints { make in
                    make.leading.equalToSuperview().offset(16)
                    make.centerY.equalToSuperview()
                    make.bottom.lessThanOrEqualToSuperview()
                    make.top.greaterThanOrEqualToSuperview()
                }

                self.contentView.addSubview(self.checkBox)
                self.checkBox.snp.makeConstraints { make in
                    make.trailing.equalToSuperview().offset(-16)
                    make.centerY.equalToSuperview()
                    make.height.width.equalTo(24)
                    make.leading.equalTo(stackView.snp.trailing).offset(12)
                }

                let separator = UIView.init()
                separator.backgroundColor = R.color.lineSeparator()!
                self.contentView.addSubview(separator)
                separator.snp.makeConstraints { make in
                    make.bottom.equalToSuperview()
                    make.leading.equalTo(16)
                    make.trailing.equalTo(-16)
                    make.height.equalTo(0.5)
                }
            }

            required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
            
            override func setSelected(_ selected: Bool, animated: Bool) {
                super.setSelected(selected, animated: animated)
                self.checkBox.isSelected = selected
            }
        }

        @Published var deviceType: IssueFeedbackViewController.DeviceType? {
            didSet {
                guard let _ = self.deviceType else { return }
                if case let .device(device) = self.deviceType {
                    guard let idx = DeviceManager2.shared.devices.firstIndex(of: device) else { return }
                    self.tableView.selectRow(at: IndexPath.init(row: idx, section: 0), animated: false, scrollPosition: .none)
                }else{
                    let row = self.tableViewDataSources.count - 1
                    self.tableView.selectRow(at: .init(row: row, section: 0), animated: false, scrollPosition: .none)
                }
            }
        }

        private var tableViewDataSources: [IssueFeedbackViewController.DeviceType] = DeviceManager2.shared.devices.map({ .device($0) }) + [.none]

        private lazy var tableView: UITableView = .init().then {
            $0.delegate = self
            $0.dataSource = self
            $0.showsVerticalScrollIndicator = false
            $0.register(TableViewCell.self, forCellReuseIdentifier: String.init(describing: TableViewCell.self))
            $0.separatorStyle = .none
        }

        private lazy var cancelBtnContainer: UIView = .init().then {
            $0.backgroundColor = R.color.background_FFFFFF_white()
        }

        private lazy var cancelBtn: UIButton = .init(type: .system).then {
            $0.setTitle(String.localization.localized("AA0059", note: "取消"), for: .normal)
            $0.titleLabel?.font = .systemFont(ofSize: 16)
            $0.tintColor = R.color.text_000000_90()
        }

        private let disposeBag: DisposeBag = .init()

        override func viewDidLoad() {
            super.viewDidLoad()
            self.contentView.addSubview(self.tableView)
            self.tableView.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(12)
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(216)
            }

            let separator = UIView.init()
            separator.backgroundColor = R.color.background_F2F3F6_thinGray()
            self.contentView.addSubview(separator)
            separator.snp.makeConstraints { make in
                make.top.equalTo(self.tableView.snp.bottom)
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(8)
            }

            self.contentView.addSubview(self.cancelBtnContainer)
            self.cancelBtnContainer.snp.makeConstraints { make in
                make.bottom.leading.trailing.equalToSuperview()
                make.top.equalTo(separator.snp.bottom)
            }

            self.cancelBtnContainer.addSubview(self.cancelBtn)
            self.cancelBtn.snp.makeConstraints { make in
                make.top.leading.trailing.equalToSuperview()
                make.height.equalTo(56)
                make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-12)
            }

            self.cancelBtn.rx.tap.bind { [weak self] _ in
                self?.dismiss(animated: true)
            }.disposed(by: self.disposeBag)
        }

        override func layoutContentView() {
            self.contentView.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.bottom.equalToSuperview().offset(16)
            }
        }

        // MARK: TableViewDataSource, Delegate
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { self.tableViewDataSources.count }

        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: String.init(describing: TableViewCell.self), for: indexPath) as! TableViewCell
            cell.item = self.tableViewDataSources[indexPath.row]
            return cell
        }

        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            self.deviceType = self.tableViewDataSources[safe_: indexPath.row]
            self.dismiss(animated: true)
        }

        func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            if indexPath.row == self.tableViewDataSources.count - 1 {
                return 56
            }
            return 80
        }
    }
}
