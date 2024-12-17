//
//  DevicesViewController+CollectionViewCell.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 1/2/2024.
//

import Foundation

extension DevicesViewController2 {
    class DeviceCollectionViewCell: UICollectionViewCell {
        
        public lazy var powerButtonClickedObservable: RxSwift.PublishSubject<(String, Bool)> = .init()

        public weak var device: DeviceEntity? {
            didSet {

                self.deviceInfoObservableDisposeBag = .init()
                
                guard let device = self.device else { return }

                self.roleButton.setTitle(device.role.description, for: .normal)
                self.roleButton.isHidden = device.role == .master
                self.powerButton.isHidden = device.role != .master
                self.cloudImageView.isHidden = !device.isSupportCloud

                device.observable(\.role, whenErrorOccur: .master).bind { [weak self] role in
                    self?.roleButton.isHidden = role == .master
                }.disposed(by: self.deviceInfoObservableDisposeBag)

                device.observable(\.vss, whenErrorOccur: nil).bind { [weak self] vss in
                    self?.isBuyCloud = vss?.isBuyCloud ?? false
                }.disposed(by: self.deviceInfoObservableDisposeBag)

                device.observable(\.remarkName, whenErrorOccur: "").bind { [weak self] name in
                    self?.nameLabel.text = name
                }.disposed(by: self.deviceInfoObservableDisposeBag)

                // 监听设备状态 及 设备角色 以控制 UI 显示
                Observable.combineLatest(device.observable(\.status, whenErrorOccur: .offline), device.observable(\.role, whenErrorOccur: .master), device.observable(\.isSupportCloud, whenErrorOccur: false))
                    .bind { [weak self] status, role, isSupportCloud in
                        self?.statusDotLabel.backgroundColor = status.color
                        self?.statusLabel.text = status.description + (isSupportCloud ? "  |  " : "")
                        self?.powerButton.setBackgroundImage(status.image, for: .normal)
                        
                        // 如果设备状态是 在线 / 关机 / 在线, 隐藏开关机动画
                        self?.powerButton.isHidden = !(status == .online || status == .offline || status == .shutdown) || role != .master
                        self?.turnOnAnimationView.isHidden = status != .turningOn || role != .master
                        self?.turnOffAnimationView.isHidden = status != .turningOff || role != .master

                        if status == .turningOff {
                            self?.turnOffAnimationView.play()
                        }

                        if status == .turningOn {
                            self?.turnOnAnimationView.play()
                        }
                    }.disposed(by: self.deviceInfoObservableDisposeBag)

                /// 设备图片显示
                device.getImageURLObservable().flatMap { [weak self] url in
                    let obs = self?.devImageView.kf.rx.setImage(with: url, placeholder: ReoqooImageLoadingPlaceholder(), options: [
                        .processor(Kingfisher.ResizingImageProcessor(referenceSize: CGSize(width: 240, height: 240)))
                    ])
                    return obs ?? .error(ReoqooError.generalError(reason: .optionalTypeUnwrapped))
                }.subscribe(on: MainScheduler.asyncInstance).subscribe().disposed(by: self.disposeBag)
            }
        }

        public var extraDisposeBag: DisposeBag = .init()
        private let disposeBag: DisposeBag = .init()
        private var deviceInfoObservableDisposeBag: DisposeBag = .init()

        /// 设备在线状态
        private var status: RQCore.DeviceStatus = .offline

        /// 是否已有生效的付费云存
        private var isBuyCloud: Bool = false {
            didSet {
                self.cloudImageView.image = self.cloudImage
            }
        }

        /// 设备云存开通状态图片
        private var cloudImage: UIImage? {
            if isBuyCloud {
                return R.image.family_cloud_on()
            } else {
                return R.image.family_cloud_off()
            }
        }

        /// 设备名称文本组件
        private lazy var nameLabel = UILabel().then {
            $0.font = .systemFont(ofSize: 14, weight: .medium)
            $0.textAlignment = .left
            $0.textColor = R.color.text_000000_90()
        }

        /// 设备缩略图组件
        private lazy var devImageView = UIImageView()

        /// 设备拥有者角色组件
        private lazy var roleButton = UIButton(type: .custom).then {
            $0.backgroundColor = R.color.background_FFFFFF_white()!.withAlphaComponent(0.8)
            $0.isUserInteractionEnabled = false
            $0.layer.cornerRadius = 3
            $0.layer.borderWidth = 0.5
            $0.layer.borderColor = R.color.text_979797()?.cgColor
            $0.setTitleColor(R.color.text_000000_60(), for: .normal)
            $0.titleLabel?.font = .systemFont(ofSize: 10, weight: .regular)
            $0.contentEdgeInsets = UIEdgeInsets(top: 2, left: 3, bottom: 2, right: 2)
        }

        /// 设备在线状态圆点组件
        private lazy var statusDotLabel = UILabel()

        /// 设备在线状态文本组件
        private lazy var statusLabel = UILabel().then {
            $0.font = .systemFont(ofSize: 12, weight: .regular)
            $0.textAlignment = .left
            $0.textColor = R.color.text_000000_60()
        }

        /// 设备云存状态图片组件
        private lazy var cloudImageView = UIImageView().then {
            $0.image = self.cloudImage
        }

        /// 设备开关机按钮组件
        private lazy var powerButton = UIButton(type: .custom).then {
            $0.backgroundColor = .clear
        }

        private lazy var turnOnAnimationView: Lottie.AnimationView = .init(name: R.file.family_power_onJson.name)

        private lazy var turnOffAnimationView: Lottie.AnimationView = .init(name: R.file.family_power_offJson.name)

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override init(frame: CGRect) {
            super.init(frame: frame)

            self.backgroundColor = .white
            self.layer.cornerRadius = 16

            self.contentView.addSubview(self.nameLabel)
            self.nameLabel.snp.makeConstraints { make in
                make.top.left.equalTo(12)
                make.right.equalTo(-12)
                make.height.equalTo(20)
            }

            self.contentView.addSubview(self.devImageView)
            self.devImageView.snp.makeConstraints { make in
                make.left.equalTo(self.nameLabel)
                make.bottom.equalTo(-12)
                make.width.height.equalTo(self.snp.height).multipliedBy(0.44)
            }

            self.contentView.addSubview(self.roleButton)
            self.roleButton.snp.makeConstraints { make in
                make.left.bottom.equalTo(self.devImageView)
            }

            self.contentView.addSubview(self.statusDotLabel)
            let dotWidth = 4.0
            self.statusDotLabel.layer.masksToBounds = true
            self.statusDotLabel.layer.cornerRadius = dotWidth / 2.0
            self.statusDotLabel.snp.makeConstraints { make in
                make.top.equalTo(self.nameLabel.snp.bottom).offset(2+(18-dotWidth)/2)
                make.left.equalTo(12)
                make.width.height.equalTo(dotWidth)
            }

            self.contentView.addSubview(self.statusLabel)
            self.statusLabel.snp.makeConstraints { make in
                make.top.equalTo(self.nameLabel.snp.bottom).offset(2)
                make.left.equalTo(self.statusDotLabel.snp.right).offset(7)
                make.height.equalTo(18)
            }

            self.contentView.addSubview(self.cloudImageView)
            self.cloudImageView.snp.makeConstraints { make in
                make.top.equalTo(self.statusLabel)
                make.left.equalTo(self.statusLabel.snp.right)
                make.width.height.equalTo(self.statusLabel.snp.height)
            }

            self.contentView.addSubview(self.powerButton)
            let powerBtnHeight = 30.0
            self.powerButton.layer.cornerRadius = powerBtnHeight / 2.0
            self.powerButton.snp.makeConstraints { make in
                make.right.bottom.equalTo(-12)
                make.width.height.equalTo(powerBtnHeight)
            }

            self.contentView.addSubview(self.turnOnAnimationView)
            self.turnOnAnimationView.snp.makeConstraints { make in
                make.center.equalTo(self.powerButton)
                make.width.height.equalTo(powerBtnHeight)
            }

            self.contentView.addSubview(self.turnOffAnimationView)
            self.turnOffAnimationView.snp.makeConstraints { make in
                make.center.equalTo(self.powerButton)
                make.width.height.equalTo(powerBtnHeight)
            }

            // MARK: Action
            self.powerButton.rx.tap.bind { [weak self] in
                guard let devId = self?.device?.deviceId, let status = self?.device?.status else { return }
                // 如果设备已离线, 不响应按钮点击
                if status == .offline { return }
                self?.powerButtonClickedObservable.onNext((devId, status != .online))
            }.disposed(by: self.disposeBag)
        }
    }
    
}
