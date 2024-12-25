//
//  IssueFeedbackViewController+IssueTypeSelectionViewController.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 8/9/2023.
//

import Foundation

extension IssueFeedbackViewController.IssueTypeSelectionViewController {
    class TableViewCell: UITableViewCell {

        var issueType: IssueFeedbackViewController.IssueCatgory? {
            didSet {
                self.textLabel?.text = issueType?.name
            }
        }

        lazy var checkBox: UIButton = .init(type: .custom).then {
            $0.isUserInteractionEnabled = false
            $0.setImage(R.image.commonCheckbox_1Deselect(), for: .normal)
            $0.setImage(R.image.commonCheckbox_1Selected(), for: .selected)
        }

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)

            self.selectionStyle = .none
            
            self.textLabel?.font = .systemFont(ofSize: 16)
            self.textLabel?.textColor = R.color.text_000000_90()
            
            self.contentView.addSubview(self.checkBox)
            self.checkBox.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-16)
                make.centerY.equalToSuperview()
                make.height.width.equalTo(24)
            }

            let separator = UIView.init()
            separator.backgroundColor = R.color.lineSeparator()!
            self.contentView.addSubview(separator)
            separator.snp.makeConstraints { make in
                make.bottom.equalToSuperview()
                make.leading.equalTo(12)
                make.trailing.equalTo(-12)
                make.height.equalTo(0.5)
            }
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override var isSelected: Bool {
            didSet {
                self.checkBox.isSelected = self.isSelected
            }
        }
    }
}

extension IssueFeedbackViewController {
    class IssueTypeSelectionViewController: PageSheetStyleViewController, UITableViewDataSource, UITableViewDelegate {

        init(issueCategorys: [IssueFeedbackViewController.IssueCatgory]) {
            super.init(nibName: nil, bundle: nil)
            self.tableViewDataSources = issueCategorys
        }
        
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        @Published var selectedIssueCategory: IssueFeedbackViewController.IssueCatgory? {
            didSet {
                guard let selectedIssueCategory = self.selectedIssueCategory else { return }
                guard let idx = self.tableViewDataSources.firstIndex(of: selectedIssueCategory) else { return }
                self.tableView.selectRow(at: IndexPath.init(row: idx, section: 0), animated: false, scrollPosition: .none)
            }
        }

        private(set) var tableViewDataSources: [IssueFeedbackViewController.IssueCatgory] = []

        private lazy var tableView: UITableView = .init().then {
            $0.rowHeight = 56
            $0.delegate = self
            $0.dataSource = self
            $0.separatorStyle = .none
            $0.separatorInset = .init(top: 0, left: 16, bottom: 0, right: 16)
            $0.showsVerticalScrollIndicator = false
            $0.register(TableViewCell.self, forCellReuseIdentifier: String.init(describing: TableViewCell.self))
        }

        private lazy var cancelBtnContainer: UIView = .init().then {
            $0.backgroundColor = R.color.background_FFFFFF_white()
        }

        private lazy var cancelBtn: UIButton = .init(type: .system).then {
            $0.setTitle(String.localization.localized("AA0059", note: "取消"), for: .normal)
            $0.titleLabel?.font = .systemFont(ofSize: 16)
            $0.tintColor = R.color.text_000000_90()
        }

        var anyCancellables: Set<AnyCancellable> = []

        override func viewDidLoad() {
            super.viewDidLoad()

            self.contentView.addSubview(self.tableView)
            self.tableView.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(12)
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(300)
            }

            let separator = UIView.init()
            separator.backgroundColor = R.color.background_000000_5()
            self.contentView.addSubview(separator)
            separator.snp.makeConstraints { make in
                make.top.equalTo(self.tableView.snp.bottom)
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(8)
            }

            self.contentView.addSubview(self.cancelBtnContainer)
            self.cancelBtnContainer.snp.makeConstraints { make in
                make.top.equalTo(separator.snp.bottom)
                make.bottom.leading.trailing.equalToSuperview()
            }

            self.cancelBtnContainer.addSubview(self.cancelBtn)
            self.cancelBtn.snp.makeConstraints { make in
                make.top.leading.trailing.equalToSuperview()
                make.height.equalTo(56)
                make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-12)
            }

            self.tableView.publisher(for: \.contentSize).map({ $0.height }).sink(receiveValue: { [weak self] height in
                self?.tableView.snp.updateConstraints({ make in
                    make.height.equalTo(height)
                })
            }).store(in: &self.anyCancellables)

            self.cancelBtn.tapPublisher.sink(receiveValue: { [weak self] in
                self?.dismiss(animated: true)
            }).store(in: &self.anyCancellables)
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
            cell.issueType = self.tableViewDataSources[indexPath.row]
            return cell
        }

        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            self.selectedIssueCategory = self.tableViewDataSources[safe_: indexPath.row]
            self.dismiss(animated: true)
        }
    }
}
