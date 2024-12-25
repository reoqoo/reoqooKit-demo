//
//  ShareDeviceConfirmUserTableViewCell.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 13/6/2024.
//

import UIKit

extension ShareDeviceConfirmViewController {
    class UserTableViewCell: UITableViewCell {
        
        var guest: DeviceShare.GuestUser? {
            didSet {
                if let headerUrlPath = guest?.headUrl, let headerUrl = URL.init(string: headerUrlPath) {
                    let screen_scale = AppEntranceManager.shared.keyWindow?.screen.scale ?? 1
                    self.headerImageView.kf.setImage(with: headerUrl, placeholder: ReoqooImageLoadingPlaceholder(), options: [.processor(ResizingImageProcessor(referenceSize: .init(width: 36 * screen_scale, height: 36 * screen_scale)))])
                }else{
                    self.headerImageView.image = R.image.mine_photo()!
                }
                self.userNameLabel.text = (self.guest?.remarkName?.isEmpty ?? true) ? self.guest?.account : self.guest?.remarkName
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

        lazy var tickImageView: UIImageView = .init(image: R.image.commonTick()!)

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

            self.contentView.addSubview(self.tickImageView)
            self.tickImageView.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.trailing.equalToSuperview().offset(-12)
                make.leading.greaterThanOrEqualTo(labelsContainer.snp.trailing).offset(8)
            }
        }
        
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override func setSelected(_ selected: Bool, animated: Bool) {
            super.setSelected(selected, animated: animated)
            self.tickImageView.isHidden = !selected
        }

    }
}
