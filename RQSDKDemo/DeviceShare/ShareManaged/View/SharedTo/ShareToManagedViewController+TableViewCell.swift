//
//  DeviceDidSharedDetailViewController+UserTableViewCell.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 17/6/2024.
//

import Foundation

extension ShareToManagedViewController {
    class UserTableViewCell: UITableViewCell {

        var guest: DeviceShare.GuestUser? {
            didSet {
                if let headerUrlPath = guest?.headUrl, let headerUrl = URL.init(string: headerUrlPath) {
                    let screen_scale = AppEntranceManager.shared.keyWindow?.screen.scale ?? 1
                    self.headerImageView.kf.setImage(with: headerUrl, placeholder: ReoqooImageLoadingPlaceholder(), options: [.processor(ResizingImageProcessor(referenceSize: .init(width: 36 * screen_scale, height: 36 * screen_scale)))])
                }else{
                    self.headerImageView.image = R.image.mine_photo()!
                }
                self.userNameLabel.text = (self.guest?.remarkName?.isEmpty ?? true) ? self.guest?.remarkName : self.guest?.account
                self.accountLabel.text = self.guest?.account
            }
        }

        lazy var headerImageView: UIImageView = .init()

        lazy var userNameLabel: UILabel = .init().then {
            $0.font = .systemFont(ofSize: 16)
            $0.textColor = R.color.text_000000_90()
        }

        lazy var accountLabel: UILabel = .init().then {
            $0.font = .systemFont(ofSize: 12)
            $0.textColor = R.color.text_000000_40()
        }

        lazy var removeBtn: UIButton = .init(type: .custom).then {
            $0.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
            $0.setTitleColor(R.color.brand(), for: .normal)
            $0.setTitle(String.localization.localized("AA0182", note: "移除"), for: .normal)
            $0.setBackgroundColor(R.color.background_000000_5()!, for: .normal)
            $0.contentEdgeInsets = .init(top: 5, left: 16, bottom: 5, right: 16)
            $0.layer.cornerRadius = 15
            $0.layer.masksToBounds = true
        }

        var tapOnRemoveBtnCancellable: Set<AnyCancellable> = []

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)

            self.selectionStyle = .none

            self.contentView.addSubview(self.headerImageView)
            self.headerImageView.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(12)
                make.centerY.equalToSuperview()
                make.width.height.equalTo(36)
                make.top.greaterThanOrEqualToSuperview()
                make.bottom.lessThanOrEqualToSuperview()
            }

            let labelsContainer = UIView.init()
            self.contentView.addSubview(labelsContainer)
            labelsContainer.snp.makeConstraints { make in
                make.leading.equalTo(self.headerImageView.snp.trailing).offset(12)
                make.top.equalToSuperview().offset(12)
                make.bottom.equalToSuperview().offset(-12)
            }

            labelsContainer.addSubview(self.userNameLabel)
            self.userNameLabel.snp.makeConstraints { make in
                make.top.leading.trailing.equalToSuperview()
            }

            labelsContainer.addSubview(self.accountLabel)
            self.accountLabel.snp.makeConstraints { make in
                make.bottom.leading.trailing.equalToSuperview()
                make.top.equalTo(self.userNameLabel.snp.bottom).offset(2)
            }

            self.contentView.addSubview(self.removeBtn)
            self.removeBtn.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-12)
                make.centerY.equalToSuperview()
                make.height.equalTo(30)
            }
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
        
    }

    class CommonTableViewCell: UITableViewCell {

        lazy var label: UILabel = .init().then {
            $0.font = .systemFont(ofSize: 16)
            $0.textColor = R.color.text_000000_90()
        }

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: .value2, reuseIdentifier: reuseIdentifier)
            self.accessoryView = UIImageView.init(image: R.image.commonArrowRightStyle1())
            self.contentView.addSubview(self.label)
            self.label.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(21)
                make.bottom.equalToSuperview().offset(-21)
                make.leading.equalToSuperview().offset(12)
            }
        }
        
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    }

    class DeviceTableViewCell: UITableViewCell {

        var imageURL: URL? {
            didSet {
                guard let imageURL = imageURL else {
                    self.deviceImageView.image = nil
                    return
                }
                let screen_scale = AppEntranceManager.shared.keyWindow?.screen.scale ?? 1
                self.deviceImageView.kf.setImage(with: imageURL, placeholder: ReoqooImageLoadingPlaceholder(), options: [
                    .processor(Kingfisher.ResizingImageProcessor(referenceSize: CGSize(width: 320 * screen_scale, height: 320 * screen_scale)))
                ])
            }
        }
        
        var name: String? {
            didSet {
                self.label.text = self.name
            }
        }

        lazy var deviceImageView: UIImageView = .init()
        lazy var label: UILabel = .init().then {
            $0.font = .systemFont(ofSize: 16)
            $0.textColor = R.color.text_000000_90()
        }

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            
            self.selectionStyle = .none

            self.contentView.addSubview(self.deviceImageView)
            self.deviceImageView.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(12)
                make.top.equalToSuperview().offset(12)
                make.bottom.equalToSuperview().offset(-12)
                make.height.width.equalTo(56)
            }

            self.contentView.addSubview(self.label)
            self.label.snp.makeConstraints { make in
                make.leading.equalTo(self.deviceImageView.snp.trailing).offset(4)
                make.centerY.equalToSuperview()
            }
        }
        
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    }
}
