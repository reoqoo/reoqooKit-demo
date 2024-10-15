//
//  FamilyViewController2+InviteBanner.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 17/2/2024.
//

import Foundation

protocol FamilyViewControllerBanner: UIView {
    /// 类型
    var type: FamilyViewController2.BannerType { get }

    /// 唯一标识符
    /// 当 唯一标识符 非空, 插入banner时, 会先判断 BannerContainer 内是否已有同样标识符的 banner, 如有, 先移除已存在的banner, 再显示新的banner
    var uniqueTag: String? { get }
}

extension FamilyViewController2 {

    enum BannerType: Int {
        // 公告
        case Notice
        // 添加设备引导Banner
        case AddDeviceGuide
        // 分享邀请
        case ShareInvite

        /// 展示权限, 当展示时, 权限越高则优先展示
        var priority: Int {
            return self.rawValue
        }
    }

    /// Banner 容器
    class BannerContainer: UIView {

        private var _banners: [FamilyViewControllerBanner] = []

        var banners: [FamilyViewControllerBanner] {
            // 根据 prioriry 排序 banners, priority 越大越靠后
            self._banners.sorted { $0.type.priority < $1.type.priority }
        }

        /// 插入 banner, 当此方法被调用后, 并不会马上执行 addSubview, 而是移除 _banners 中的元素
        /// 在任意时刻内, self.subViews 仅有一个 banner 作为子视图, 这是为了移除 / 添加动画更方便而设计
        public func insertBanner(_ banner: FamilyViewControllerBanner) {
            // 先检查 _banners 中是否有 uniqueTag 相同的 banner, 如有, 先移除
            if let duplicateBanner = self._banners.filter({ $0.uniqueTag == banner.uniqueTag }).first {
                self.removeBanner(duplicateBanner)
            }
            self._banners.append(banner)
        }
        
        /// 移除banner, 同 inserBanner() 方法, 并不会马上执行 removeFromSuperView, 而是移除 _banners 中的元素
        public func removeBanner(_ banner: FamilyViewControllerBanner) {
            let bs = self._banners.filter({ $0 == banner })
            self._banners.removeAll { b in
                bs.contains { $0 == b }
            }
        }
        

        /// addBanner() 以及 removeBanner() 都不会马上影响到视图显示情况, 需执行此方法才会马上将做出影响视图显示的操作
        /// - Returns: 当前正在显示的Banner, 以便外部控制显示动画
        @discardableResult public func updateDisplayIfNeed() -> FamilyViewControllerBanner? {
            // 移除当前正在显示的 banner
            self.subviews.last?.removeFromSuperview()
            // 将 banner 添加到视图
            guard let targetBanner = self.banners.last else { return nil }
            self.addSubview(targetBanner)
            targetBanner.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            return targetBanner
        }
    }
    
    // MARK: Banner 类型
    /// 设备分享邀请banner
    class ShareInviteBanner: UIView, FamilyViewControllerBanner {
        
        // MARK: FamilyViewControllerBanner
        /// 类型
        var type: FamilyViewController2.BannerType = .ShareInvite

        var uniqueTag: String? { self.inviteModel.shareToken }

        let inviteModel: MessageCenter.DeviceShareInviteModel

        let externalDisposeBag: DisposeBag = .init()
        
        init(inviteModel: MessageCenter.DeviceShareInviteModel) {
            self.inviteModel = inviteModel
            super.init(frame: .zero)
            self.setupUI()

            self.descriptionLabel.text = String.localization.localized("AA0161", note: "收到%@分享的设备", args: inviteModel.inviteAccount)
            self.ignoreBtn.setTitle(String.localization.localized("AA0162", note: "忽略"), for: .normal)
            self.checkBtn.setTitle(String.localization.localized("AA0163", note: "查看"), for: .normal)
        }
        
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        lazy var descriptionLabel: UILabel = .init().then {
            $0.backgroundColor = .clear
            $0.numberOfLines = 0
            $0.font = .systemFont(ofSize: 14, weight: .regular)
            $0.textColor = R.color.text_000000_90()
            $0.textAlignment = .left
        }

        private(set) lazy var ignoreBtn: UIButton = .init().then {
            $0.backgroundColor = .clear
            $0.contentEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
            $0.titleLabel!.font = .systemFont(ofSize: 14, weight: .medium)
            $0.setTitleColor(R.color.text_link_4A68A6(), for: .normal)
        }

        private(set) lazy var checkBtn: UIButton = .init().then {
            $0.backgroundColor = .clear
            $0.contentEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
            $0.titleLabel!.font = .systemFont(ofSize: 14, weight: .medium)
            $0.setTitleColor(R.color.text_link_4A68A6(), for: .normal)
        }

        func setupUI() {
            self.layer.cornerRadius = 12
            self.backgroundColor = R.color.text_FFFFFF()

            self.addSubview(self.descriptionLabel)
            self.descriptionLabel.snp.makeConstraints { make in
                make.top.left.equalTo(16)
                make.right.equalTo(-16)
            }

            self.addSubview(self.checkBtn)
            self.checkBtn.snp.makeConstraints { make in
                make.top.equalTo(self.descriptionLabel.snp.bottom).offset(8)
                make.trailing.equalToSuperview().offset(-16)
                make.bottom.equalToSuperview().offset(-8)
            }

            self.addSubview(self.ignoreBtn)
            self.ignoreBtn.snp.makeConstraints { make in
                make.top.equalTo(self.checkBtn.snp.top)
                make.trailing.equalTo(self.checkBtn.snp.leading).offset(-8)
            }
        }
    }
}
