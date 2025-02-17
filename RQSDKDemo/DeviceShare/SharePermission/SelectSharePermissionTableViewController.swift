//
//  SelectPermissionTableViewController.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 19/6/2024.
//

import Foundation

extension SelectSharePermissionTableViewController {

    class TableViewCell: UITableViewCell {

        var permissionItem: DeviceShare.SharePermission? {
            didSet {
                guard let permissionItem = permissionItem else { return }
                self.label.text = permissionItem.type.description
                self.validationSwitch.state = permissionItem.isValid ? .on : .off
                self.validationSwitch.isEnabled = permissionItem.type.configurable
            }
        }

        lazy var label: UILabel = .init().then {
            $0.font = .systemFont(ofSize: 16)
            $0.textColor = R.color.text_000000_90()
        }

        lazy var validationSwitch: RQSwitch = .init().then {
            $0.uiswitch.onTintColor = R.color.brand()
        }

        lazy var customSeparator: UIView = .init().then {
            $0.backgroundColor = R.color.lineSeparator()
        }

        var extralAnyCancellables: [AnyCancellable] = []

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)

            self.contentView.addSubview(self.label)
            self.label.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(12)
                make.centerY.equalToSuperview()
            }

            self.contentView.addSubview(self.validationSwitch)
            self.validationSwitch.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-16)
                make.centerY.equalToSuperview()
            }

            self.contentView.addSubview(self.customSeparator)
            self.customSeparator.snp.makeConstraints { make in
                make.bottom.equalToSuperview()
                make.height.equalTo(0.5)
                make.leading.equalToSuperview().offset(16)
                make.trailing.equalToSuperview().offset(-16)
            }
        }
    }
    
}

protocol SelectSharePermissionTableViewControllerDelegate: AnyObject {
    func selectSharePermissionTableViewController(_ controller: SelectSharePermissionTableViewController, switchDidTapAtIndexPath indexPath: IndexPath)
}

/// SelectSharePermissionAlertViewController 和 DevicePermissionConfigurationViewController 是次 ViewController 的 Parent Controller
/// 此 ViewController 提供了 TableView 视图
class SelectSharePermissionTableViewController: BaseTableViewController {

    let dataSources: [[DeviceShare.SharePermission]]

    init(dataSources: [[DeviceShare.SharePermission]], style: UITableView.Style) {
        self.dataSources = dataSources
        super.init(style: style)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    weak var delegate: SelectSharePermissionTableViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.rowHeight = 56
        self.tableView.sectionHeaderHeight = 0.1
        self.tableView.sectionFooterHeight = 0.1
        self.tableView.allowsSelection = false
        self.tableView.showsVerticalScrollIndicator = false
        self.tableView.separatorColor = R.color.lineSeparator()
        self.tableView.separatorInset = .init(top: 0, left: 12, bottom: 0, right: 12)
        self.tableView.backgroundColor = R.color.background_FFFFFF_white()
        self.tableView.tableHeaderView = .init(frame: .zero)
        if #available(iOS 15.0, *) {
            self.tableView.sectionHeaderTopPadding = 0.0
        }
        self.tableView.register(TableViewCell.self, forCellReuseIdentifier: String.init(describing: TableViewCell.self))
        self.tableView.register(RQInsetGroupedTableViewHeader.self, forHeaderFooterViewReuseIdentifier: String.init(describing: RQInsetGroupedTableViewHeader.self))
    }

    override func numberOfSections(in tableView: UITableView) -> Int { self.dataSources.count }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { self.dataSources[section].count }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String.init(describing: TableViewCell.self), for: indexPath) as! TableViewCell
        cell.permissionItem = self.dataSources[indexPath.section][indexPath.row]
        cell.customSeparator.isHidden = tableView.style == .insetGrouped
        return cell
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: String.init(describing: RQInsetGroupedTableViewHeader.self)) as! RQInsetGroupedTableViewHeader
        header.text = self.dataSources[section].first?.serie.description
        return header
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 40 }
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { 8 }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? TableViewCell else { return }
        cell.extralAnyCancellables = []
        cell.validationSwitch.tapPublisher.sink { [weak self] state in
            guard let self else { return }
            self.delegate?.selectSharePermissionTableViewController(self, switchDidTapAtIndexPath: indexPath)
        }.store(in: &cell.extralAnyCancellables)
    }

    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? TableViewCell else { return }
        cell.extralAnyCancellables = []
    }

    /// 提供给外部调整 Swith 的 state
    func setSwitchState(_ state: RQSwitch.State, atIndexPath indexPath: IndexPath) {
        guard let cell = self.tableView.cellForRow(at: indexPath) as? TableViewCell else { return }
        cell.validationSwitch.setStateWithAnimate(state)
    }
}
