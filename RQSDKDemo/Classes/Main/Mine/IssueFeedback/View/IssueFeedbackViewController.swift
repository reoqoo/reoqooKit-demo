//
//  IssueFeedbackViewController.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 27/3/2024.
//

import Foundation

class IssueFeedbackViewController: BaseViewController {

    static func fromStoryboard() -> IssueFeedbackViewController {
        let sb = UIStoryboard(name: R.storyboard.issueFeedbackViewController.name, bundle: nil)
        return sb.instantiateViewController(withIdentifier: String.init(describing: Self.self)) as! IssueFeedbackViewController
    }

    let vm: IssueFeedbackViewController.ViewModel = .init()

    var tableViewController: IssueFeedbackTableViewController!

    lazy var rightBarButtonItem: UIBarButtonItem = .init(image: R.image.mineFeedbackList()!, style: .plain, target: nil, action: nil)

    @IBOutlet weak var commitBtn: UIButton!
    @IBOutlet weak var emailSendingIntroductionTextView: UITextView!
    @IBOutlet weak var emailSendingIntroductionTextViewHeightConstraint: NSLayoutConstraint!

    /// 底部 attributedString
    let emailSendingIntroductionAttributeString: NSMutableAttributedString = {
        let content = String.localization.localized("AA0412", note: "问题比较紧急?您还可以发邮件反馈") + "\n" + "c-service@reoqoo.com"
        let res = NSMutableAttributedString.init(string: content)
        let paragraphStyle = NSMutableParagraphStyle.init()
        paragraphStyle.alignment = .center
        res.addAttributes([.foregroundColor: R.color.text_000000_38()!, .font: UIFont.systemFont(ofSize: 12), .paragraphStyle: paragraphStyle], range: .init(location: 0, length: content.count))
        let emailRange = (content as NSString).range(of: "c-service@reoqoo.com")
        let emailAsURL = URL.init(string: "c-service@reoqoo.com")!
        res.addAttributes([.link: emailAsURL], range: emailRange)
        return res
    }()

    var anyCancellables: Set<AnyCancellable> = []

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        guard let tableViewController = segue.destination as? IssueFeedbackTableViewController else { return }
        tableViewController.vm = self.vm
        self.tableViewController = tableViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = String.localization.localized("AA0222", note: "问题反馈")
        
        self.navigationItem.rightBarButtonItem = self.rightBarButtonItem

        self.commitBtn.layer.cornerRadius = 23
        self.commitBtn.layer.masksToBounds = true
        self.commitBtn.setTitle(String.localization.localized("AA0263", note: "提交"), for: .normal)
        self.commitBtn.setBackgroundColor(R.color.brand()!, for: .normal)
        self.commitBtn.setBackgroundColor(R.color.brandDisable()!, for: .disabled)
        self.commitBtn.setTitleColor(R.color.text_FFFFFF()!, for: .normal)
        self.commitBtn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)

        // 控制 commitBtn 的 isEnabled 状态
        Publishers.CombineLatest3(self.vm.$deviceType, self.vm.$issueCategory, self.tableViewController.questionDescriptionTextView.textPublisher).map({
            if $0.0 == nil { return false }
            if $0.1 == nil { return false }
            guard let description = $0.2 else { return false }
            if description.count < 10 { return false }
            return true
        }).sink { [weak self] enable in
            self?.commitBtn.isEnabled = enable
        }.store(in: &self.anyCancellables)

        // 监听获取问题分类列表成功
        self.vm.$getCategorysResult.sink(receiveValue: { result in
            MBProgressHUD.fromTag(99)?.hideDispatchOnMainThread()
            guard case let .failure(err) = result else { return }
            MBProgressHUD.showHUD_DispatchOnMainThread(text: err.localizedDescription)
        }).store(in: &self.anyCancellables)

        // 监听提交结果
        self.vm.$commitResult.compactMap({ $0 }).receive(on: DispatchQueue.main).sink(receiveValue: { [weak self] result in
            self?.commitResultHandling(result)
        }).store(in: &self.anyCancellables)

        // RightBarButton 按钮点击
        self.rightBarButtonItem.tapPublisher.sink(receiveValue: { [weak self] _ in
            let vc = WebViewController.init(url: StandardConfiguration.shared.feedbackListURL)
            self?.navigationController?.pushViewController(vc, animated: true)
        }).store(in: &self.anyCancellables)

        // 监听 textView 的 contentSize.height
        self.emailSendingIntroductionTextView.publisher(for: \.contentSize).map({ $0.height }).sink { [weak self] height in
            self?.emailSendingIntroductionTextViewHeightConstraint.constant = height
            self?.view.updateConstraintsIfNeeded()
        }.store(in: &self.anyCancellables)

        self.emailSendingIntroductionTextView.attributedText = self.emailSendingIntroductionAttributeString

        // 请求问题分类列表
        self.vm.getIssueCategorys()
        MBProgressHUD.showLoadingHUD_DispatchOnMainThread(tag: 99)
    }

    @IBAction func commitBtnOnClick(_ sender: UIButton) {
        MBProgressHUD.showLoadingHUD_DispatchOnMainThread(isMask: true, tag: 100)
        self.vm.commit(description: self.tableViewController.questionDescriptionTextView.text, contact: self.tableViewController.contactWayTextField.text)
    }
}

// MARK: Helper
extension IssueFeedbackViewController {
    // 提交结果处理
    func commitResultHandling(_ result: Result<String, Swift.Error>) {
        MBProgressHUD.fromTag(100)?.hideDispatchOnMainThread()
        if case let .failure(err) = result {
            MBProgressHUD.showHUD_DispatchOnMainThread(text: err.localizedDescription)
            return
        }
        if case let .success(feedbackID) = result {
            let vc = FeedbackCommitSuccessViewController.init(feedbackID: feedbackID)
            let nav = BaseNavigationController.init(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            self.navigationController?.present(nav, animated: true, completion: { [weak self] in
                self?.navigationController?.popViewController(animated: false)
            })
        }
    }
}

// MARK: UITextViewDelegate
extension IssueFeedbackViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if textView != self.emailSendingIntroductionTextView { return false }
        guard let _ = self.emailSendingIntroductionTextView else { return true }
        UIPasteboard.general.string = "c-service@reoqoo.com"
        MBProgressHUD.showHUD_DispatchOnMainThread(text: "c-service@reoqoo.com" + String.localization.localized("AA0268", note: "复制成功"))
        return false
    }
}
