//
//  DeviceFirmwareUpgradeViewController+ProgressView.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 10/10/2023.
//

import Foundation

extension DeviceFirmwareUpgradeViewController {

    // MARK: 设备升级TableViewHeader
    class UpgradeTipsHeader: UIView {

        override init(frame: CGRect) {
            super.init(frame: frame)

            let contentView: UIView = .init()
            contentView.layer.cornerRadius = 12
            contentView.layer.masksToBounds = true
            contentView.backgroundColor = R.color.background_FF582A_20()
            self.addSubview(contentView)
            contentView.snp.makeConstraints { make in
                make.edges.equalTo(UIEdgeInsets.init(top: 16, left: 16, bottom: 16, right: 16))
            }

            let iconImageView = UIImageView.init(image: R.image.mineDeviceUpgradeWarning())
            contentView.addSubview(iconImageView)
            iconImageView.snp.makeConstraints { make in
                make.top.leading.equalToSuperview().offset(12)
            }

            let label = UILabel.init()
            label.numberOfLines = 0
            label.font = .systemFont(ofSize: 13)
            label.textColor = R.color.text_FF582A()
            label.text = String.localization.localized("AA0349", note: "升级大约需要5－10分钟，必须保持摄像机全程不断电！否则可能会导致摄像机无法使用。（升级过程中摄像机将处于离线状态）")
            contentView.addSubview(label)
            label.snp.makeConstraints { make in
                make.leading.equalTo(iconImageView.snp.trailing).offset(8)
                make.top.equalToSuperview().offset(12)
                make.bottom.trailing.equalToSuperview().offset(-12)
            }

        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    }

    // MARK: ProgressView
    class ProgressView: UIView {

        let progress: Progress = .init(totalUnitCount: 100)

        lazy var label: UILabel = .init().then {
            $0.text = "0%"
            $0.textAlignment = .center
            $0.textColor = R.color.text_000000_90()
            $0.font = .systemFont(ofSize: 14, weight: .medium)
        }

        lazy var progressBg: UIView = .init().then {
            $0.backgroundColor = R.color.brand()?.withAlphaComponent(0.16)
        }

        let disposeBag: DisposeBag = .init()

        override init(frame: CGRect) {
            super.init(frame: frame)

            self.layer.cornerRadius = 15
            self.layer.masksToBounds = true
            self.layer.borderColor = R.color.brand()?.cgColor
            self.layer.borderWidth = 1

            self.backgroundColor = R.color.background_FFFFFF_white()

            self.addSubview(self.progressBg)
            self.progressBg.snp.makeConstraints { make in
                make.leading.top.bottom.equalToSuperview()
                make.width.equalToSuperview().multipliedBy(0)
            }

            self.addSubview(self.label)
            self.label.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }

            // 监听 progress
            self.progress.rx.observe(\.fractionCompleted).bind { [weak self] fractionCompleted in
                self?.progressBg.snp.remakeConstraints { make in
                    make.leading.top.bottom.equalToSuperview()
                    make.width.equalToSuperview().multipliedBy(fractionCompleted)
                }
                self?.label.text = String.init(format: "%.1f%%", fractionCompleted * 100)
            }.disposed(by: self.disposeBag)
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    }
}
