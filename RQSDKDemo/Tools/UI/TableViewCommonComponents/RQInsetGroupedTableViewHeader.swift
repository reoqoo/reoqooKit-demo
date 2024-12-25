//
//  RQInsetGroupedTableViewHeader.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 24/7/2024.
//

import Foundation

/// 系统 InsetGroupedTableView 的 Header 会比较靠右, 但是UI要求对齐, 为了统一样式设计此通用Header
class RQInsetGroupedTableViewHeader: UITableViewHeaderFooterView {

    var text: String? {
        didSet {
            self.label.text = self.text
        }
    }

    lazy var label: UILabel = .init().then {
        $0.font = .systemFont(ofSize: 14)
        $0.textColor = R.color.text_000000_60()
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        self.contentView.addSubview(self.label)
        self.label.snp.makeConstraints { make in
            make.top.bottom.trailing.equalToSuperview()
            make.leading.equalToSuperview().offset(12)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
