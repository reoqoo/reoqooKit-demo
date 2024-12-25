//
//  ShareManagedViewController+DeviceTableViewCell.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 13/6/2024.
//

import Foundation

extension ShareDevicesListViewController {
    class DeviceTableViewCell: UITableViewCell {

        var device: DeviceEntity? {
            didSet {
                self.disposeBag = .init()

                guard let dev = self.device else {
                    self.deviceImageView.image = nil
                    self.deviceNameLabel.text = nil
                    return
                }
                
                dev.getImageURLObservable().flatMap { [weak self] url in
                    let obs = self?.deviceImageView.kf.rx.setImage(with: url, placeholder: ReoqooImageLoadingPlaceholder(), options: [
                        .processor(Kingfisher.ResizingImageProcessor(referenceSize: CGSize(width: 200, height: 200)))
                    ])
                    return obs ?? .error(ReoqooError.generalError(reason: .optionalTypeUnwrapped))
                }.subscribe(on: MainScheduler.asyncInstance).subscribe().disposed(by: self.disposeBag)

                self.deviceNameLabel.text = dev.remarkName
            }
        }

        lazy var deviceImageView: UIImageView = .init()
        lazy var deviceNameLabel: UILabel = .init().then {
            $0.font = .systemFont(ofSize: 16)
            $0.textColor = R.color.text_000000_90()
        }

        lazy var checkBox: UIButton = .init(type: .custom).then {
            $0.setImage(R.image.commonCheckbox_1Deselect(), for: .normal)
            $0.setImage(R.image.commonCheckbox_1Selected(), for: .selected)
        }

        var disposeBag: DisposeBag = .init()

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            
            self.selectionStyle = .none

            self.contentView.addSubview(self.deviceImageView)
            self.deviceImageView.snp.makeConstraints { make in
                make.top.leading.equalToSuperview().offset(12)
                make.bottom.equalToSuperview().offset(-12)
                make.width.height.equalTo(56)
            }

            self.contentView.addSubview(self.deviceNameLabel)
            self.deviceNameLabel.snp.makeConstraints { make in
                make.leading.equalTo(self.deviceImageView.snp.trailing).offset(4)
                make.centerY.equalToSuperview()
            }

            self.contentView.addSubview(self.checkBox)
            self.checkBox.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-12)
                make.centerY.equalToSuperview()
                make.leading.greaterThanOrEqualTo(self.deviceNameLabel.snp.trailing).offset(4)
            }
        }
        
        override func setSelected(_ selected: Bool, animated: Bool) {
            super.setSelected(selected, animated: animated)
            self.checkBox.isSelected = self.isSelected
        }
        
    }
}
