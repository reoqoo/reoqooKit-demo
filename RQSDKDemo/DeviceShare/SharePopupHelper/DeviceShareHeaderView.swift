//
//  DeviceShareHeaderView.swift
//  RQSDKDemo
//
//  Created by chenchangxin on 2023/8/24.
//

import Foundation

extension DeviceShareHeaderView {
    enum Style {
        /// 默认类型：image + name
        case `default`
        /// 描述类型：image + name + desc
        case desc
    }
}

/// 设备分享头部视图
class DeviceShareHeaderView: UIView {
    // MARK: public
    /// 设备图片
    var image: UIImage? {
        didSet {
            imageView.image = image
        }
    }

    /// 设备名称
    var name: String = "" {
        didSet {
            nameLabel.text = name
        }
    }

    /// 详细描述
    var desc: String = "" {
        didSet {
            if style == .desc {
                descLabel.text = desc
            }
        }
    }

    // MARK: private
    private lazy var imageView = UIImageView().then {
        $0.backgroundColor = .clear
        $0.image = image
    }

    private lazy var nameLabel = UILabel().then {
        $0.backgroundColor = .clear
        $0.textAlignment = .center
        $0.textColor = R.color.text_000000_90()
        $0.font = .systemFont(ofSize: 16, weight: .regular)
    }

    private lazy var descLabel = UILabel().then {
        $0.backgroundColor = .clear
        $0.textAlignment = .center
        $0.textColor = R.color.text_000000_60()
        $0.font = .systemFont(ofSize: 16, weight: .regular)
    }

    private var style: DeviceShareHeaderView.Style = .default

    private let disposeBag = DisposeBag()
    private var anyCancellables: Set<AnyCancellable> = []

    init(style: DeviceShareHeaderView.Style, frame: CGRect) {
        super.init(frame: frame)
        self.style = style

        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear

        addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.6)
            make.height.equalTo(self.snp.width).multipliedBy(0.6)
        }

        addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(22)
        }

        if style == .desc {
            addSubview(descLabel)
            descLabel.snp.makeConstraints { make in
                make.top.equalTo(nameLabel.snp.bottom).offset(8)
                make.left.right.height.equalTo(nameLabel)
            }
        }
    }
}

extension DeviceShareHeaderView {

    /// 根据产品id设置产品图片
    /// - Parameter productId: 产品id
    func setImage(productId: String) {
        let screen_scale = AppEntranceManager.shared.keyWindow?.screen.scale ?? 1
        ProductTemplate.getProductImageURLPublisher(pid: productId).receive(on: DispatchQueue.main).sink { [weak self] url in
            self?.imageView.kf.setImage(with: url, placeholder: ReoqooImageLoadingPlaceholder(), options: [.processor(ResizingImageProcessor(referenceSize: .init(width: 320 *  screen_scale, height: 320 * screen_scale)))])
        }.store(in: &self.anyCancellables)
    }

    /// 根据产品设置产品默认名称
    /// - Parameter productId: 产品id
    func setProductName(productId: String) {
        ProductTemplate.getProductNamePublisher(pid: productId).receive(on: DispatchQueue.main).sink { [weak self] productName in
            self?.name = productName ?? ""
        }.store(in: &self.anyCancellables)
    }
}
