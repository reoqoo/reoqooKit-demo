//
//  FeedbackCommitSuccessViewController.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 11/9/2023.
//

import UIKit

class FeedbackCommitSuccessViewController: BaseViewController {

    lazy var imageView: UIImageView = .init(image: R.image.mineFeedbackSuccess()).then {
        $0.contentMode = .center
    }

    lazy var label: UILabel = .init().then {
        $0.text = String.localization.localized("AA0270", note: "提交成功，非常感谢您的反馈")
        $0.textColor = R.color.text_000000_90()
        $0.font = .systemFont(ofSize: 16)
        $0.textAlignment = .center
        $0.numberOfLines = 0
    }

    lazy var copyFeedbackIDBtn: UIButton = .init(type: .custom).then {
        $0.setImage(R.image.mineFeedbackList(), for: .normal)
        $0.setTitle(String.localization.localized("AA0599", note: "反馈单号") + ": " + self.feedbackID, for: .normal)
        $0.setTitleColor(R.color.text_000000_60(), for: .normal)
        $0.titleLabel?.numberOfLines = 0
        $0.titleLabel?.font = .systemFont(ofSize: 14)
        $0.exchangedPoistionWithTitleLabelAndImageView(margin: 4)
    }

    lazy var closeBtn: UIButton = .init(type: .custom).then {
        $0.setStyle_1()
        $0.layer.cornerRadius = 23
        $0.layer.masksToBounds = true
        $0.titleLabel!.font = .systemFont(ofSize: 16, weight: .regular)
        $0.setTitle(String.localization.localized("AA0271", note: "关闭"), for: .normal)
    }
    
    private let feedbackID: String

    private let disposeBag: DisposeBag = .init()

    lazy var rightBarButtonItem: UIBarButtonItem = .init(image: R.image.mineFeedbackList()!, style: .plain, target: nil, action: nil)

    init(feedbackID: String) {
        self.feedbackID = feedbackID
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = String.localization.localized("AA0222", note: "问题反馈")

        self.setNavigationBarBackground(.clear)

        let leftBarButtonItem = UIBarButtonItem.init(image: R.image.commonNavigationBack(), style: .done, target: nil, action: nil)
        self.navigationItem.leftBarButtonItem = leftBarButtonItem
        leftBarButtonItem.rx.tap.bind { [weak self] _ in
            self?.dismiss(animated: true)
        }.disposed(by: self.disposeBag)

        self.navigationItem.rightBarButtonItem = self.rightBarButtonItem
        self.rightBarButtonItem.rx.tap.bind { [weak self] _ in
            let vc = WebViewController.init(url: StandardConfiguration.shared.feedbackListURL)
            self?.navigationController?.pushViewController(vc, animated: true)
        }.disposed(by: self.disposeBag)

        self.view.addSubview(self.imageView)
        self.imageView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(48)
            make.centerX.equalToSuperview()
        }

        self.view.addSubview(self.label)
        self.label.snp.makeConstraints { make in
            make.top.equalTo(self.imageView.snp.bottom).offset(26)
            make.leading.equalTo(12)
            make.trailing.equalTo(-12)
        }

        self.view.addSubview(self.copyFeedbackIDBtn)
        self.copyFeedbackIDBtn.snp.makeConstraints { make in
            make.top.equalTo(self.label.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
        }
        self.copyFeedbackIDBtn.rx.tap.bind { [weak self] _ in
            UIPasteboard.general.string = self?.feedbackID
            MBProgressHUD.showHUD_DispatchOnMainThread(text: String.localization.localized("AA0268", note: "复制成功"))
        }.disposed(by: self.disposeBag)

        self.view.addSubview(self.closeBtn)
        self.closeBtn.snp.makeConstraints { make in
            make.top.equalTo(self.copyFeedbackIDBtn.snp.bottom).offset(48)
            make.width.equalTo(200)
            make.height.equalTo(46)
            make.centerX.equalToSuperview()
        }

        self.closeBtn.rx.tap.bind { [weak self] _ in
            self?.dismiss(animated: true)
        }.disposed(by: self.disposeBag)
    }

}
