//
//  DeviceUpgradeViewController+Subviews.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 7/10/2023.
//

import Foundation

extension DeviceFirmwareUpgradeViewController {
    // MARK: 设备升级TableViewCell
    class DeviceTableViewCell: UITableViewCell {
        
        var item: TableViewCellItem? {
            didSet {

                if self.item === oldValue { return }
                guard let item = item else { return }

                // 重建 self.taskMonitorDisposeBag
                self.taskMonitorDisposeBag = .init()
                
                // 对 UI 基础数据展示赋值
                self.deviceNameLabel.text = item.device?.remarkName
                // 4段式版本号, 用于展示
                let newVersion = DeviceNewVersionInfoEntity.convert3ComponentsVersionNumTo4ComponentsVersionNum(versionOf3Components: item.task.targetVersion)
                self.versionBtn.setTitle(String.localization.localized("AA0343", note: "新版本") + ":" + newVersion, for: .normal)
                item.device?.getImageURLPublisher().compactMap({ $0 }).sink(receiveValue: { [weak self] url in
                    self?.devImageView.kf.setImage(with: url, placeholder: ReoqooImageLoadingPlaceholder())
                }).store(in: &self.anyCancellables)
                self.newVersionDescriptionLabel.text = item.device?.newVersionInfo?.upgDescs
                
                // 是否展开
                self.versionBtn.isSelected = item.isExpanded
                if item.isExpanded {
                    self.expand()
                }else{
                    self.collapse()
                }

                // 对设备更新状态进行监听
                // 决定 "升级按钮" 是否显示, "升级进度", "安装失败" 按钮是否显示, "安装中" 标识是否显示...
                self.item?.task.upgradeStatusObservable.bind { [weak self] taskStatus in
                    switch taskStatus {
                    case .idle:
                        // 显示升级按钮
                        self?.updateBtn.isHidden = false
                        self?.installingBtn.isHidden = true
                        self?.retryBtn.isHidden = true
                        self?.upgradeProgressView.isHidden = true
                    // 设备(主动)检查新版本 (step 1)
                    case .checkingNewVersion:
                        // 显示进度
                        self?.updateBtn.isHidden = true
                        self?.installingBtn.isHidden = true
                        self?.retryBtn.isHidden = true
                        self?.upgradeProgressView.isHidden = false
                        self?.upgradeProgressView.progress.completedUnitCount = 0
                    // 客户端接收到 `设备主动检查新版本` 动作的结果
                    case .didConfirmNewVersion:
                        // 显示进度
                        self?.updateBtn.isHidden = true
                        self?.installingBtn.isHidden = true
                        self?.retryBtn.isHidden = true
                        self?.upgradeProgressView.isHidden = false
                        self?.upgradeProgressView.progress.completedUnitCount = 0
                    // 设备发送了更新请求 (step 2)
                    case .sendingUpdateRequest:
                        // 显示进度
                        self?.updateBtn.isHidden = true
                        self?.installingBtn.isHidden = true
                        self?.retryBtn.isHidden = true
                        self?.upgradeProgressView.isHidden = false
                        self?.upgradeProgressView.progress.completedUnitCount = 0
                    // 更新中
                    case .updating(let progress):
                        // 显示进度
                        self?.updateBtn.isHidden = true
                        self?.installingBtn.isHidden = true
                        self?.retryBtn.isHidden = true
                        self?.upgradeProgressView.isHidden = progress >= 80
                        self?.upgradeProgressView.progress.completedUnitCount = Int64(progress)
                        // 当进度 >= 80%, 显示 "安装中" 按钮
                        self?.installingBtn.isHidden = progress < 80
                    // 更新成功
                    case .success:
                        break
                    // 更新失败 (由于要写本地, 所以仅记录错误码和错误描述)
                    case .failure:
                        // 显示重试
                        // 显示进度
                        self?.updateBtn.isHidden = true
                        self?.installingBtn.isHidden = true
                        self?.retryBtn.isHidden = false
                        self?.upgradeProgressView.isHidden = true
                    }
                }.disposed(by: self.taskMonitorDisposeBag)
            }
        }
        
        /// 展开折叠按钮点击
        var versionBtnClickedObservable: RxSwift.PublishSubject<Void> = .init()
        
        /// 点击升级按钮
        var upgradeBtnClickedObservable: RxSwift.PublishSubject<Void> = .init()
        
        /// 重试按钮
        var retryBtnClickedObservable: RxSwift.PublishSubject<Void> = .init()

        /// 供外部使用的 disposeBag
        var extraDisposeBag: DisposeBag = .init()

        /// 任务状态监听 disposeBag
        private var taskMonitorDisposeBag: DisposeBag = .init()

        /// 设备图片
        private var devImageView: UIImageView = .init()
        /// 约束, 为 "折叠" 功能准备
        private var devImageViewBottom2SuperViewConstraint: Constraint?

        private var deviceNameLabel: UILabel = .init().then {
            $0.font = .systemFont(ofSize: 16, weight: .regular)
            $0.textColor = R.color.text_000000_90()
        }

        private var versionBtn: IVButton = .init(.right).then {
            $0.titleLabel?.font = .systemFont(ofSize: 14)
            $0.setTitleColor(R.color.text_000000_60(), for: .normal)
            $0.setImage(R.image.commonArrowBottomStyle1(), for: .normal)
            $0.setImage(R.image.commonArrowTopStyle1(), for: .selected)
            $0.titleLabel?.numberOfLines = 1
        }

        private var updateBtn: UIButton = .init(type: .system).then {
            $0.isHidden = true
            $0.layer.cornerRadius = 15
            $0.layer.masksToBounds = true
            $0.titleLabel?.textAlignment = .center
            $0.titleLabel?.font = .systemFont(ofSize: 14)
            // 根据文案长度缩小字体
            $0.titleLabel?.adjustsFontSizeToFitWidth = true
            $0.titleLabel?.minimumScaleFactor = 0.4
            $0.setTitle(String.localization.localized("AA0345", note: "升级"), for: .normal)
            $0.setBackgroundColor(R.color.background_000000_5()!, for: .normal)
            $0.setTitleColor(R.color.brand(), for: .normal)
            $0.contentEdgeInsets = .init(top: 0, left: 4, bottom: 0, right: 4)
        }

        /// "安装中" 标识
        private var installingBtn: UIButton = .init(type: .system).then {
            $0.isUserInteractionEnabled = false
            $0.isHidden = true
            $0.layer.cornerRadius = 15
            $0.layer.masksToBounds = true
            $0.setBackgroundColor(R.color.brand()!, for: .normal)
            $0.setTitleColor(R.color.text_FFFFFF(), for: .normal)
            $0.titleLabel?.font = .systemFont(ofSize: 14)
            $0.setTitle(String.localization.localized("AA0347", note: "安装中"), for: .normal)
            $0.titleLabel?.textAlignment = .center
            // 根据文案长度缩小字体
            $0.titleLabel?.adjustsFontSizeToFitWidth = true
            $0.titleLabel?.minimumScaleFactor = 0.4
            $0.contentEdgeInsets = .init(top: 0, left: 4, bottom: 0, right: 4)
        }

        /// "升级失败" 按钮
        private var retryBtn: UIButton = .init(type: .system).then {
            $0.isHidden = true
            $0.layer.cornerRadius = 15
            $0.layer.masksToBounds = true
            $0.titleLabel?.font = .systemFont(ofSize: 14)
            $0.setTitle(String.localization.localized("AA0348", note: "升级失败"), for: .normal)
            $0.setBackgroundColor(R.color.background_000000_5()!, for: .normal)
            $0.setTitleColor(R.color.brand(), for: .normal)
            $0.titleLabel?.textAlignment = .center
            // 根据文案长度缩小字体
            $0.titleLabel?.adjustsFontSizeToFitWidth = true
            $0.titleLabel?.minimumScaleFactor = 0.4
            $0.contentEdgeInsets = .init(top: 0, left: 4, bottom: 0, right: 4)
        }

        private var upgradeProgressView: ProgressView = .init().then {
            $0.isHidden = true
        }

        // MARK: 新版本说明
        private var newVersionDescriptionView: UIView = .init().then {
            $0.isHidden = false
        }

        private var newVersionDescriptionViewTopConstraint: Constraint?

        private var newVersionDescriptionLabel: UILabel = .init().then {
            $0.numberOfLines = 0
            $0.font = .systemFont(ofSize: 12)
            $0.textColor = R.color.text_000000_38()
        }

        private let disposeBag: DisposeBag = .init()
        private var anyCancellables: Set<AnyCancellable> = []

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)

            self.contentView.addSubview(self.devImageView)
            self.devImageView.snp.makeConstraints { make in
                make.width.height.equalTo(56)
                make.leading.top.equalToSuperview().offset(12)
                self.devImageViewBottom2SuperViewConstraint = make.bottom.equalToSuperview().offset(-12).priority(.init(999)).constraint
            }

            let nameLabel_versionBtn_container: UIView = .init()
            nameLabel_versionBtn_container.backgroundColor = .clear
            self.contentView.addSubview(nameLabel_versionBtn_container)
            nameLabel_versionBtn_container.snp.makeConstraints { make in
                make.top.equalTo(self.devImageView.snp.top).offset(4)
                make.leading.equalTo(self.devImageView.snp.trailing).offset(8)
            }

            nameLabel_versionBtn_container.addSubview(self.deviceNameLabel)
            self.deviceNameLabel.snp.makeConstraints { make in
                make.top.leading.trailing.equalToSuperview()
            }

            nameLabel_versionBtn_container.addSubview(self.versionBtn)
            self.versionBtn.snp.makeConstraints { make in
                make.top.equalTo(self.deviceNameLabel.snp.bottom).offset(6)
                make.leading.bottom.equalToSuperview()
                make.trailing.lessThanOrEqualToSuperview()
            }

            self.contentView.addSubview(self.updateBtn)
            self.updateBtn.snp.makeConstraints { make in
                make.centerY.equalTo(self.devImageView.snp.centerY)
                make.trailing.equalToSuperview().offset(-12)
                make.leading.greaterThanOrEqualTo(nameLabel_versionBtn_container.snp.trailing).offset(8)
                make.width.equalTo(88)
                make.height.equalTo(30)
            }

            self.contentView.addSubview(self.installingBtn)
            self.installingBtn.snp.makeConstraints { make in
                make.centerY.equalTo(self.devImageView.snp.centerY)
                make.trailing.equalToSuperview().offset(-12)
                make.width.equalTo(88)
                make.height.greaterThanOrEqualTo(30)
            }

            self.contentView.addSubview(self.retryBtn)
            self.retryBtn.snp.makeConstraints { make in
                make.centerY.equalTo(self.devImageView.snp.centerY)
                make.trailing.equalToSuperview().offset(-12)
                make.width.equalTo(88)
                make.height.greaterThanOrEqualTo(30)
            }

            self.contentView.addSubview(self.upgradeProgressView)
            self.upgradeProgressView.snp.makeConstraints { make in
                make.centerY.equalTo(self.devImageView.snp.centerY)
                make.trailing.equalToSuperview().offset(-12)
                make.width.equalTo(88)
                make.height.equalTo(30)
            }

            self.contentView.addSubview(self.newVersionDescriptionView)
            self.newVersionDescriptionView.snp.makeConstraints { make in
                self.newVersionDescriptionViewTopConstraint = make.top.equalTo(self.devImageView.snp.bottom).offset(12).priority(.init(249)).constraint
                make.trailing.equalToSuperview()
                make.bottom.equalToSuperview()
                make.leading.equalTo(self.devImageView.snp.trailing).offset(4)
            }

            let separator: UIView = .init()
            separator.backgroundColor = R.color.text_000000_10()
            self.newVersionDescriptionView.addSubview(separator)
            separator.snp.makeConstraints { make in
                make.top.equalToSuperview()
                make.height.equalTo(0.5)
                make.leading.equalToSuperview()
                make.trailing.equalToSuperview().offset(-12)
            }

            let descriptionTitleLabel: UILabel = .init()
            descriptionTitleLabel.font = .systemFont(ofSize: 12)
            descriptionTitleLabel.text = String.localization.localized("AA0344", note: "新版本说明")
            self.newVersionDescriptionView.addSubview(descriptionTitleLabel)
            descriptionTitleLabel.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(12)
            }

            self.newVersionDescriptionView.addSubview(self.newVersionDescriptionLabel)
            self.newVersionDescriptionLabel.snp.makeConstraints { make in
                make.top.equalTo(descriptionTitleLabel.snp.bottom).offset(6)
                make.trailing.bottom.equalToSuperview().offset(-12)
                make.leading.equalToSuperview()
            }

            self.versionBtn.rx.tap.bind(to: self.versionBtnClickedObservable).disposed(by: self.disposeBag)
            self.updateBtn.rx.tap.bind(to: self.upgradeBtnClickedObservable).disposed(by: self.disposeBag)
            self.retryBtn.rx.tap.bind(to: self.retryBtnClickedObservable).disposed(by: self.disposeBag)
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        func expand() {
            self.versionBtn.isSelected = true
            self.newVersionDescriptionView.isHidden = false
            self.devImageViewBottom2SuperViewConstraint?.update(priority: .init(249))
            self.newVersionDescriptionViewTopConstraint?.update(priority: .init(999))
        }

        func collapse() {
            self.versionBtn.isSelected = false
            self.newVersionDescriptionView.isHidden = true
            self.devImageViewBottom2SuperViewConstraint?.update(priority: .init(999))
            self.newVersionDescriptionViewTopConstraint?.update(priority: .init(249))
        }
    }

}
