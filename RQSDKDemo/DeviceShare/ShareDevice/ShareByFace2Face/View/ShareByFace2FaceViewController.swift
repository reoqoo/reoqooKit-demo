//
//  ShareByFace2FaceViewController.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 13/6/2024.
//

import Foundation

class ShareByFace2FaceViewController: BaseViewController {

    let deviceId: String
    let vm: ShareDeviceConfirmViewController.ViewModel

    init(vm: ShareDeviceConfirmViewController.ViewModel, deviceId: String) {
        self.vm = vm
        self.deviceId = deviceId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    lazy var qrcodeContainer: UIView = .init().then {
        $0.backgroundColor = R.color.background_FFFFFF_white()
        $0.layer.cornerRadius = 12
        $0.layer.masksToBounds = true
    }

    lazy var qrcodeImageView: UIImageView = .init().then {
        $0.backgroundColor = R.color.background_F2F3F6_thinGray()
    }

    lazy var qrcodeLoadingAss: UIActivityIndicatorView = .init(style: .large).then {
        $0.hidesWhenStopped = true
    }

    lazy var refreshQRCodeBtnOnImageView: UIButton = .init(type: .custom).then {
        $0.setImage(R.image.share_update_big(), for: .normal)
        $0.isHidden = true
    }

    lazy var validityDateContainer: UIView = .init().then {
        $0.backgroundColor = .clear
    }

    /// 有效期至 XXXX
    lazy var validityDateLabel: UILabel = .init().then {
        $0.font = .systemFont(ofSize: 12)
        $0.textColor = R.color.text_000000_60()
        $0.numberOfLines = 0
    }

    lazy var refreshQRCodeBtn: UIButton = .init(type: .custom).then {
        $0.setImage(R.image.share_update(), for: .normal)
    }

    lazy var usageDescriptionLabel: UILabel = .init().then {
        $0.font = .systemFont(ofSize: 14)
        $0.textColor = R.color.text_000000_90()
        $0.text = String.localization.localized("AA0158", note: "使用XXXXXXXX APP扫描上方二维码共享设备")
        $0.textAlignment = .center
    }

    lazy var userListContainer: UIView = .init().then {
        $0.isHidden = true
    }

    lazy var userListHeaderLabel: UILabel = .init().then {
        $0.font = .systemFont(ofSize: 12)
        $0.textColor = R.color.text_000000_60()
        $0.text = String.localization.localized("AA0159", note: "已经分享的好友")
    }

    lazy var userListTableView: UITableView = .init(frame: .zero, style: .insetGrouped).then { 
        $0.delegate = self
        $0.dataSource = self
        $0.rowHeight = UITableView.automaticDimension
        $0.sectionHeaderHeight = 0.1
        $0.sectionFooterHeight = 0.1
        $0.separatorStyle = .none
        $0.register(UserTableViewCell.self, forCellReuseIdentifier: String.init(describing: UserTableViewCell.self))
    }

    var anyCancellables: Set<AnyCancellable> = []

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = String.localization.localized("AA0151", note: "面对面分享")

        self.view.addSubview(self.qrcodeContainer)
        self.qrcodeContainer.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(16)
            if UIDevice.current.userInterfaceIdiom == .phone {
                make.leading.equalToSuperview().offset(44)
                make.trailing.equalToSuperview().offset(-44)
                make.width.equalTo(self.qrcodeContainer.snp.height)
            }else{
                make.width.height.equalTo(290)
            }
            make.centerX.equalToSuperview()
        }

        self.qrcodeContainer.addSubview(self.qrcodeImageView)
        self.qrcodeImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(30)
            make.leading.equalToSuperview().offset(34)
            make.trailing.equalToSuperview().offset(-34)
            make.bottom.equalToSuperview().offset(-40)
        }

        self.qrcodeContainer.addSubview(self.refreshQRCodeBtnOnImageView)
        self.refreshQRCodeBtnOnImageView.snp.makeConstraints { make in
            make.center.equalTo(self.qrcodeImageView)
        }

        self.qrcodeContainer.addSubview(self.qrcodeLoadingAss)
        self.qrcodeLoadingAss.snp.makeConstraints { make in
            make.center.equalTo(self.qrcodeImageView)
        }

        self.qrcodeContainer.addSubview(self.validityDateContainer)
        self.validityDateContainer.snp.makeConstraints { make in
            make.top.equalTo(self.qrcodeImageView.snp.bottom)
            make.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
        }

        self.validityDateContainer.addSubview(self.validityDateLabel)
        self.validityDateLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview()
        }

        self.validityDateContainer.addSubview(self.refreshQRCodeBtn)
        self.refreshQRCodeBtn.snp.makeConstraints { make in
            make.leading.equalTo(self.validityDateLabel.snp.trailing).offset(8)
            make.top.bottom.trailing.equalToSuperview()
        }

        self.view.addSubview(self.usageDescriptionLabel)
        self.usageDescriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(self.qrcodeContainer.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
        }

        self.view.addSubview(self.userListContainer)
        self.userListContainer.snp.makeConstraints { make in
            make.top.equalTo(self.usageDescriptionLabel.snp.bottom).offset(14)
            make.leading.trailing.bottom.equalToSuperview()
        }

        self.userListContainer.addSubview(self.userListHeaderLabel)
        self.userListHeaderLabel.snp.makeConstraints { make in
            make.leading.equalTo(16)
            make.top.equalToSuperview()
        }

        self.userListContainer.addSubview(self.userListTableView)
        self.userListTableView.snp.makeConstraints { make in
            make.top.equalTo(self.userListHeaderLabel.snp.bottom).offset(14)
            make.leading.trailing.bottom.equalToSuperview()
        }

        self.vm.$deviceSharedSituation.sink { [weak self] situation in
//            self?.userListContainer.isHidden = situation?.guestList.isEmpty ?? true
            self?.userListTableView.reloadData()
        }.store(in: &self.anyCancellables)

        // 发起定时轮询, 在二维码超时前 20 秒刷新二维码
        Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] date in
            guard let item = self?.vm.latestQRCodeItem else { return }
            if case .willRequestQRCode = self?.vm.status { return }
            // 有, 比对时间
            if item.expireTime - 20 <= Date.init().timeIntervalSince1970 {
                self?.vm.event = .refreshQRCode
            }
        }.store(in: &self.anyCancellables)

        self.vm.$status.sink { [weak self] status in
            // 即将要请求二维码
            if case .willRequestQRCode  = status {
                self?.qrcodeLoadingAss.startAnimating()
                self?.validityDateContainer.isHidden = true
                self?.validityDateLabel.text = nil
                self?.qrcodeImageView.image = nil
            }
            // 请求二维码完成
            if case let .didFinishRequestQRCode(result) = status {
                self?.validityDateContainer.isHidden = false
                self?.qrcodeLoadingAss.stopAnimating()
                if case let .success(item) = result {
                    self?.refreshQRCodeBtnOnImageView.isHidden = true
                    self?.qrcodeImageView.image = self?.generateQRCodeFromLink(item.shareLink)
                    self?.validityDateLabel.text = String.localization.localized("AA0157", note: "有效期至") + Date.init(timeIntervalSince1970: item.expireTime).string(with: "yyyy-MM-dd HH:mm:ss")
                }
                if case .failure = result {
                    self?.refreshQRCodeBtnOnImageView.isHidden = false
                }
            }
        }.store(in: &self.anyCancellables)

        // 刷新按钮点击, 有两个刷新按钮, 点任意一个都进这里
        self.refreshQRCodeBtnOnImageView.tapPublisher.prepend(())
            .combineLatest(self.refreshQRCodeBtn.tapPublisher)
            .sink { [weak self] _ in
                self?.vm.event = .refreshQRCode
            }.store(in: &self.anyCancellables)

        self.vm.event = .refreshQRCode
        self.vm.event = .requestDeviceSituation
    }
    
}

extension ShareByFace2FaceViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { self.vm.deviceSharedSituation?.guestList.count ?? 0 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String.init(describing: UserTableViewCell.self), for: indexPath) as! UserTableViewCell
        cell.guest = self.vm.deviceSharedSituation?.guestList[indexPath.row]
        return cell
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 0.1 }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { 16 }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { UITableView.automaticDimension }
}

// MARK: Helper
extension ShareByFace2FaceViewController {
    func generateQRCodeFromLink(_ link: String) -> UIImage? {
        IVQRCodeHelper.createQRCode(with: link, qrSize: .init(width: 290 * 3, height: 290 * 3))
    }
}
