//
//  IssueFeedbackViewController+Header.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 8/11/2023.
//

import Foundation

extension IssueFeedbackTableViewController {
    class TableViewSectionHeader: UITableViewHeaderFooterView {
        lazy var label: UILabel = .init().then {
            $0.font = .systemFont(ofSize: 14)
            $0.textColor = R.color.text_000000_60()
        }

        override init(reuseIdentifier: String?) {
            super.init(reuseIdentifier: reuseIdentifier)
            self.contentView.addSubview(self.label)
            self.label.snp.makeConstraints { make in
                make.leading.equalToSuperview()
                make.bottom.equalToSuperview().offset(-12)
                make.top.equalToSuperview().offset(12)
                make.trailing.equalToSuperview().offset(-16)
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
