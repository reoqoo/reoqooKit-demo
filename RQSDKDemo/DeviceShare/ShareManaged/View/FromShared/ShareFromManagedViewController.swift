//
//  ShareFromManagedViewController.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 17/6/2024.
//

import Foundation

class ShareFromManagedViewController: BaseViewController {

    lazy var vm: ViewModel = .init(deviceId: self.deviceId)

    let deviceId: String

    init(deviceId: String) {
        self.deviceId = deviceId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    lazy var deviceImageView: UIImageView = .init()
    lazy var deviceNameLabel: UILabel = .init().then {
        $0.textAlignment = .center
        $0.textColor = R.color.text_000000_90()
        $0.font = .systemFont(ofSize: 16, weight: .regular)
    }

    lazy var deviceDescriptionLabel: UILabel = .init().then {
        $0.textColor = R.color.text_000000_60()
        $0.font = .systemFont(ofSize: 16)
        $0.textAlignment = .center
        $0.numberOfLines = 0
    }

    lazy var removeDeviceBtn: UIButton = .init(type: .custom).then {
        $0.setStyle_0()
        $0.layer.cornerRadius = 23
        $0.layer.masksToBounds = true
        $0.setTitle(String.localization.localized("AA0183", note: "移除设备"), for: .normal)
    }

    var anyCancellables: Set<AnyCancellable> = []
    var disposeBag: DisposeBag = .init()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = String.localization.localized("AA0180", note: "我的分享")

        self.view.addSubview(self.deviceImageView)
        self.deviceImageView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.width.height.equalTo(252)
            make.centerX.equalToSuperview()
        }

        self.view.addSubview(self.deviceNameLabel)
        self.deviceNameLabel.snp.makeConstraints { make in
            make.top.equalTo(self.deviceImageView.snp.bottom)
            make.centerX.equalToSuperview()
        }

        self.view.addSubview(self.deviceDescriptionLabel)
        self.deviceDescriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(self.deviceNameLabel.snp.bottom).offset(14)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        self.view.addSubview(self.removeDeviceBtn)
        self.removeDeviceBtn.snp.makeConstraints { make in
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-24)
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-24)
            make.height.equalTo(46)
        }

        let dev = DeviceManager2.fetchDevice(self.deviceId)
        let screen_scale = AppEntranceManager.shared.keyWindow?.screen.scale ?? 1
        dev?.getImageURLObservable().flatMap { [weak self] url in
            let obs = self?.deviceImageView.kf.rx.setImage(with: url, placeholder: ReoqooImageLoadingPlaceholder(), options: [
                .processor(Kingfisher.ResizingImageProcessor(referenceSize: CGSize(width: 320 * screen_scale, height: 320 * screen_scale)))
            ])
            return obs ?? .error(ReoqooError.generalError(reason: .optionalTypeUnwrapped))
        }.subscribe(on: MainScheduler.asyncInstance).subscribe().disposed(by: self.disposeBag)

        self.deviceNameLabel.text = dev?.remarkName
        self.vm.$ownerInfo.sink { [weak self] info in
            self?.deviceDescriptionLabel.text = info?.description
        }.store(in: &self.anyCancellables)

        self.removeDeviceBtn.tapPublisher.sink { [weak self] _ in
            self?.vm.event = .deleteDevice
        }.store(in: &self.anyCancellables)

        self.vm.$status.sink { [weak self] status in
            if case let .deleteDeviceWithCompletion(result) = status {
                self?.deleteCompletionHandling(result)
            }
        }.store(in: &self.anyCancellables)
    }

    func deleteCompletionHandling(_ result: Result<String, Swift.Error>) {
        if case .success = result {
            MBProgressHUD.showHUD_DispatchOnMainThread(text: String.localization.localized("AA0186", note: "移除成功"))
            self.navigationController?.popViewController(animated: true)
        }
        if case let .failure(err) = result {
            MBProgressHUD.showHUD_DispatchOnMainThread(text: err.localizedDescription)
        }
    }

    func removeDevice() {
        let property = ReoqooPopupViewProperty()
        property.message = String.localization.localized("AA0561", note: "确定要移除设备吗？")

        let cancelAction = IVPopupAction(title: String.localization.localized("AA0059", note: "取消"), style: .custom, color: R.color.text_link_4A68A6(), handler: {})
        let okAction = IVPopupAction(title: String.localization.localized("AA0058", note: "确定"), style: .custom, color: R.color.button_destructive_FA2A2D(), handler: { [weak self] in
            self?.vm.event = .deleteDevice
        })
        let popupView = IVPopupView(property: property, actions: [cancelAction, okAction])
        popupView.show()
    }
}
