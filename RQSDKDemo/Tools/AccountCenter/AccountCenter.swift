//
//  AccountCenter.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 18/7/2023.
//

import Foundation
import CryptoSwift

class AccountCenter {

    /// 1. 当网络请求拦截到 10902013 错误, 会发送此通知
    /// 2. 当用户手动注销账号, 也会发送此通知
    static let accountDidCloseNotification: Notification.Name = .init("Reoqoo.User.AccountDidCloseNotfication")
    /// accountDidCloseNotification 的 userInfoKey 是否主动注销账号 (其他端注销: False, 本端主动注销: True)
    static let accountDidCloseNotificationUserInfoKey_IsManual: String = "Reoqoo.User.AccountDidCloseNotfication.UserInfo.isManual"

    /// AccessToken 过期通知
    /// 当网络请求拦截到 10026 发送此通知
    static let accessTokenDidExpiredNotification: Notification.Name = .init("Reoqoo.User.AccessTokenDidExpiredNotfication")

    static let shared: AccountCenter = .init()
    
    private init() {
        // 监听 user 被注销的通知
        self.observerAccountDidClosed()
        // 监听用户密码被修改事件
        self.observerAccountPasswordDidModify()
        // 监听AccessToken过期, 登出用户
        self.observerAccessTokenDidExpired()
        // 尝试从本地加载 User 信息
        self.tryLoadUserFromLocal()
    }
    
    /// 如果用户登出/未登录, 此值为 nil
    @RxBehavioral private(set) var currentUser: User?

    private var disposeBag: DisposeBag = .init()
    private var anyCancellables: Set<AnyCancellable> = []

    /// 尝试从本地加载 User 信息
    /// - 无, 退出函数
    /// - 有, 检查token是否过期
    ///     - 过期, 退出函数
    ///     - 未过期, 登入
    private func tryLoadUserFromLocal() {
        guard let enumerator: FileManager.DirectoryEnumerator = FileManager.default.enumerator(at: URL.init(fileURLWithPath: Self.usersInfoFolder), includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsPackageDescendants]) else { return }

        var user: User?

        while var url = enumerator.nextObject() as? URL {

            url.appendPathComponent(AccountCenter.userInfoFileName)

            guard let jsonData = try? Data.init(contentsOf: url),
                  let encryptContent = String.init(data: jsonData, encoding: .utf8),
                  let decryptContent = try? encryptContent.decryptBase64ToString(cipher: AES(key: User.storeSalt.bytes, blockMode: ECB()))
            else { continue }

            let user_ = decryptContent.decode(User.self)
            if user_?.isLogin == true {
                user = user_
                break
            }
        }

        // 本地加载不到数据
        guard let user = user else { return }

        // token 过期了
        if Date().timeIntervalSince1970 > user.basicInfo.expireTime {
            self.userDidLogout()
            return
        }

        // 登入了
        self.userDidLogin(user: user, isFromLocalData: true)
        
        // 刷新token
        user.tryRefreshToken()
    }

    /// 在 登录/注册 请求成功后调用
    /// - Parameters:
    ///   - fromLocalData: 区分是从本地持久化登录的还是网络请求登录的(注册登录接口)
    private func userDidLogin(user: User, isFromLocalData: Bool) {
        user.isLogin = true
        self.currentUser = user
        // 注册远程推送
        UIApplication.shared.registerForRemoteNotifications()
        // 使用户更新 profile info
        self.currentUser?.updateUserProfileInfo()
        // 是否从网络请求登录成功, 如果是, 1.将 User 存起来 2.更新 token 更新时间
        if !isFromLocalData {
            // 数据持久化
            self.currentUser?.store()
            // 更新 accessToken 更新时间
            user.userDefault?.set(Date().timeIntervalSince1970, forKey: UserDefaults.UserKey.Reoqoo_LatestUpdateAccessTokenTime.rawValue)
            user.userDefault?.synchronize()
        }
    }

    /// 在 用户登出接口请求成功 / token过期被踢出 后调用
    private func userDidLogout() {
        self.currentUser?.isLogin = false
        self.currentUser?.store()
        self.currentUser = nil
        self.sweepUserAccessoryInfo()
    }

    /// 用户注销了账户
    /// 包含用户主动注销 以及 接收到 10902013 错误码
    /// 在收到 accountDidCloseNotification 时此方法被调用
    private func userDidCloseAccount() {
        self.currentUser?.isLogin = false
        self.currentUser?.deleteStored()
        self.currentUser = nil
        self.sweepUserAccessoryInfo()
    }

    /// 用户登出后需要做的后续操作
    private func sweepUserAccessoryInfo() {
        // 注销APNS推送服务
        UIApplication.shared.unregisterForRemoteNotifications()
        // 用户登出后, 将系统推送列表清除
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        if #available(iOS 16.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(0)
        } else {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }

    /// 监听账号被注销通知
    private func observerAccountDidClosed() {
        NotificationCenter.default.rx.notification(AccountCenter.accountDidCloseNotification, object: nil).bind { [weak self] notification in
            let isManual = notification.userInfo?[AccountCenter.accountDidCloseNotificationUserInfoKey_IsManual] as? Bool ?? false
            if !isManual { logInfo("[AccountCenter] 由于账号被注销, 退出当前登录用户") }
            self?.userDidCloseAccount()
        }.disposed(by: self.disposeBag)
    }

    /// 监听账号密码被修改
    private func observerAccountPasswordDidModify() {
        RQSDKDelegate.shared.$p2pOnlineMsg.bind { [weak self] in
            guard $0.topic == "ModifyPwd" else { return }
            logInfo("[AccountCenter] 由于用户密码被修改, 退出当前登录用户")
            self?.logoutCurrentUser()
        }.disposed(by: self.disposeBag)
    }

    /// 监听AccessToken过期
    private func observerAccessTokenDidExpired() {
        NotificationCenter.default.publisher(for: AccountCenter.accessTokenDidExpiredNotification).sink { [weak self] _ in
            logInfo("[AccountCenter] 收到10026, AccessToken过期, 退出当前登录用户")
            self?.logoutCurrentUser()
        }.store(in: &self.anyCancellables)
    }
}

// MARK: Public
extension AccountCenter {
    // MARK: 退出登录
    func logoutCurrentUser() {
        self.logoutRequestObservable().subscribe { _ in

        } onFailure: { err in

        }.disposed(by: self.disposeBag)
        // 不校验登录接口是否调成功, 直接登出
        self.userDidLogout()
    }
}

// MARK: Const
extension AccountCenter {

    // 用户信息持久化路径为: ~/Library/Application Support/com.reoqoo/users/"UserID"/inf

    static let userInfoFileName = "inf"

    static let usersInfoFolder: String = {
        // 如果文件夹 /ReoqooUsers 不存在, 就创建
        if !FileManager.default.fileExists(atPath: UIApplication.usersInfoDirectoryPath) {
            do {
                try FileManager.default.createDirectory(atPath: UIApplication.usersInfoDirectoryPath, withIntermediateDirectories: true)
            } catch let err {
                fatalError(err.localizedDescription)
            }
        }
        logDebug("[AccountCenter] User持久化路径: \(UIApplication.usersInfoDirectoryPath)")
        return UIApplication.usersInfoDirectoryPath
    }()
}

// MARK: Request RxSwift Wrapped
extension AccountCenter {
    // MARK: 登录接口
    func loginRequestObservable(accountType: RQApi.AccountType, password: String) -> RxSwift.Single<User> {
        // 创建 Single 发布者, 对登录请求进行包装
        let loginObservable = RxSwift.Single<JSON>.create { observer in
            RQApi.Api.login(accountType: accountType, password: password) {
                let result = ResponseHandler.responseHandling(jsonStr: $0, error: $1)
                observer(result)
            }
            return Disposables.create()
        }.map { json in
            let userInf = try json["data"].decoded(as: RQCore.LoginInfo.self)
            // 组建 User
            let user = User(userInfo: userInf)
            return user
        }

        // 拦截登录成功, 执行登录成功的默认操作
        return loginObservable.do { [weak self] user in
            self?.userDidLogin(user: user, isFromLocalData: false)
            logInfo("[AccountCenter] 发起登录请求成功")
        } onError: { err in
            logError("[AccountCenter] 发起登录请求失败: ", err)
        } onSubscribed: {
            logInfo("[AccountCenter] 发起登录请求: ", accountType, password)
        }
    }

    // MARK: 注册相关接口
    // 获取邮箱验证码
    private func getEmailOneTimeCodeRequestObservable(email: String, for forWhat: RQApi.OneTimeCodeFor) -> RxSwift.Single<Void> {
        let observable = RxSwift.Single<Void>.create { single in
            RQApi.Api.sendOneTimeCodeTo(email: email, forWhat: forWhat) {
                let res = ResponseHandler.responseHandling(jsonStr: $0, error: $1)
                if case let .failure(failure) = res {
                    single(.failure(failure))
                }
                if case .success = res {
                    single(.success(()))
                }
            }
            return Disposables.create()
        }

        return observable.do { _ in
            logInfo("[AccountCenter] 发起获取邮箱验证码请求成功")
        } onError: { err in
            logError("[AccountCenter] 发送邮箱验证码请求发生错误", err)
        } onSubscribed: {
            logInfo("[AccountCenter] 发起获取邮箱验证码请求: ", forWhat, email)
        }
    }

    /// 获取手机验证码
    private func getTelephoneOneTimeCodeRequestObservable(telephone: String, regionCode: String, for: RQApi.OneTimeCodeFor) -> RxSwift.Single<Void> {
        let observable = RxSwift.Single<Void>.create { single in
            RQApi.Api.sendOneTimeCodeTo(telephone: telephone, forWhat: `for`, regionCode: regionCode) {
                let res = ResponseHandler.responseHandling(jsonStr: $0, error: $1)
                if case let .failure(failure) = res {
                    single(.failure(failure))
                }
                if case .success = res {
                    single(.success(()))
                }
            }
            return Disposables.create()
        }

        return observable.do { _ in
            logInfo("[AccountCenter] 发起获取手机验证码请求成功")
        } onError: { err in
            logError("[AccountCenter] 发送手机验证码请求发生错误", err)
        } onSubscribed: {
            logInfo("[AccountCenter] 发起获取手机验证码请求: ", `for`, regionCode, telephone)
        }
    }

    /// 针对获取验证码的两种渠道 以及 目的(注册), 整合
    func getOneTimeCodeForRegisterRequestObservable(accountType: RQApi.AccountType) -> RxSwift.Single<Void> {
        if case let .email(email) = accountType {
            return self.getEmailOneTimeCodeRequestObservable(email: email, for: .registerOrBind)
        }
        if case let .mobile(telephone, mobileArea: regionCode) = accountType {
            return self.getTelephoneOneTimeCodeRequestObservable(telephone: telephone, regionCode: regionCode, for: .registerOrBind)
        }
        fatalError("[AccountCenter] 调用获取验证码接口时收到错误的 IVAccountType 类型")
    }

    // MARK: 验证验证码
    func verifyOneTimeCodeRequestObservable(accountType: RQApi.AccountType, code: String) -> RxSwift.Single<Void> {
        let observable = RxSwift.Single<Void>.create { single in
            RQApi.Api.verifyOneTimeCode(code, account: accountType, responseHandler: {
                let res = ResponseHandler.responseHandling(jsonStr: $0, error: $1)
                if case .success = res {
                    single(.success(()))
                }
                if case .failure(let err) = res {
                    single(.failure(err))
                }
            })
            return Disposables.create()
        }

        return observable.do { _ in
            logInfo("[AccountCenter] 发起验证验证码请求成功")
        } onError: { err in
            logError("[AccountCenter] 发送验证验证码请求发生错误", err)
        } onSubscribed: {
            logInfo("[AccountCenter] 发起验证验证码请求: ", accountType, code)
        }
    }

    /// 手机号注册(设置密码)
    /// - Parameters:
    ///   - telephone: 手机号
    ///   - regionCode: 地区码(86)
    ///   - regionNameCode: 地区二字码(CN)
    ///   - password: 密码
    ///   - verificationCode: 验证码
    /// - Returns: 发布者
    private func registerRequestObservable(telephone: String, regionCode: String, regionNameCode: String, password: String, oneTimeCode: String) -> RxSwift.Single<User> {
        let observable = RxSwift.Single<JSON>.create { single in
            RQApi.Api.registerBy(telephone: telephone, regionCode: regionCode, regionNameCode: regionNameCode, password: password, oneTimeCode: oneTimeCode) {
                let res = ResponseHandler.responseHandling(jsonStr: $0, error: $1)
                single(res)
            }
            return Disposables.create()
        }.map { json in
            let userBasicInfo = try json["data"].decoded(as: RQCore.LoginInfo.self)
            let user = User.init(userInfo: userBasicInfo)
            return user
        }

        return observable.do { [weak self] user in
            self?.userDidLogin(user: user, isFromLocalData: false)
            logInfo("[AccountCenter] 发起注册请求成功")
        } onError: { err in
            logError("[AccountCenter] 发送注册请求发生错误", err)
        } onSubscribed: {
            logInfo("[AccountCenter] 发起注册请求请求: ", telephone, regionCode, regionNameCode, password, oneTimeCode)
        }
    }

    /// 邮箱注册(设置密码)
    /// - Parameters:
    ///   - telephone: 手机号
    ///   - regionCode: 地区码(86)
    ///   - regionNameCode: 地区二字码(CN)
    ///   - password: 密码
    ///   - verificationCode: 验证码
    /// - Returns: 发布者
    private func registerRequestObservable(email: String, regionNameCode: String, password: String, oneTimeCode: String) -> RxSwift.Single<User> {
        let observable = RxSwift.Single<JSON>.create { single in
            RQApi.Api.registerBy(email: email, regionNameCode: regionNameCode, password: password, oneTimeCode: oneTimeCode) {
                let res = ResponseHandler.responseHandling(jsonStr: $0, error: $1)
                single(res)
            }
            return Disposables.create()
        }.map { json in
            let userBasicInfo = try json["data"].decoded(as: RQCore.LoginInfo.self)
            let user = User.init(userInfo: userBasicInfo)
            return user
        }

        return observable.do { [weak self] user in
            self?.userDidLogin(user: user, isFromLocalData: false)
            logInfo("[AccountCenter] 发起注册请求成功")
        } onError: { err in
            logError("[AccountCenter] 发送注册请求发生错误", err)
        } onSubscribed: {
            logInfo("[AccountCenter] 发起注册请求请求: ", email, regionNameCode, password, oneTimeCode)
        }
    }

    // 邮箱 / 手机号 注册整合
    func registerRequestObservable(accountType: RQApi.AccountType, regionNameCode: String, password: String, oneTimeCode: String) -> RxSwift.Single<User> {
        if case let .email(email) = accountType {
            return self.registerRequestObservable(email: email, regionNameCode: regionNameCode, password: password, oneTimeCode: oneTimeCode)
        }
        if case let .mobile(telephone, mobileArea: regionCode) = accountType {
            return self.registerRequestObservable(telephone: telephone, regionCode: regionCode, regionNameCode: regionNameCode, password: password, oneTimeCode: oneTimeCode)
        }
        fatalError("[AccountCenter] 调用注册接口时收到错误的 IVAccountType 类型")
    }

    // MARK: 找回密码
    /// 针对找回密码需求, 请求发送验证码. 整合邮箱和手机号验证码两种方式
    func getVerificationCodeForFindPasswordRequestObservable(accountType: RQApi.AccountType) -> RxSwift.Single<Void> {
        if case let .email(email) = accountType {
            return self.getEmailOneTimeCodeRequestObservable(email: email, for: .findBackPassword)
        }
        if case let .mobile(telephone, mobileArea: regionCode) = accountType {
            return self.getTelephoneOneTimeCodeRequestObservable(telephone: telephone, regionCode: regionCode, for: .findBackPassword)
        }
        fatalError("[AccountCenter] 调用获取验证码接口时收到错误的 IVAccountType 类型")
    }

    // 找回密码
    func findPasswordRequestObservable(accountType: RQApi.AccountType, password: String, code: String) -> RxSwift.Single<Void> {
        let observable = RxSwift.Single<Void>.create { single in
            RQApi.Api.resetPassword(password, oneTimeCode: code, account: accountType) {
                let res = ResponseHandler.responseHandling(jsonStr: $0, error: $1)
                if case .success = res {
                    single(.success(()))
                }
                if case .failure(let err) = res {
                    single(.failure(err))
                }
            }
            return Disposables.create()
        }

        return observable.do { _ in
            logInfo("[AccountCenter] 发起找回密码请求成功")
        } onError: { err in
            logError("[AccountCenter] 发送找回密码请求发生错误", err)
        } onSubscribed: {
            logInfo("[AccountCenter] 发起找回密码请求: ", accountType, code)
        }
    }

    private func logoutRequestObservable() -> Single<Void> {
        guard let terminalId = self.currentUser?.basicInfo.terminalId else { return Single<Void>.error(ReoqooError.generalError(reason: .optionalTypeUnwrapped)) }
        let observable = Single<Void>.create { single in
            RQApi.Api.logout(terminalId: terminalId) {
                let res = ResponseHandler.responseHandling(jsonStr: $0, error: $1)
                if case .success = res {
                    single(.success(()))
                }
                if case .failure(let err) = res {
                    single(.failure(err))
                }
            }
            return Disposables.create()
        }
        return observable.do { _ in
            logInfo("[AccountCenter] 发起登出请求成功")
        } onError: { err in
            logError("[AccountCenter] 发送登出请求发生错误", err)
        } onSubscribed: {
            logInfo("[AccountCenter] 发起登出请求")
        }
    }

    // MARK: 注销账户
    func closeAccountObservable(password: String?, reasonType: Int, reasonDesc: String?) -> Single<Void> {
        guard let userId = self.currentUser?.basicInfo.userId, let password = password, let sessionId = self.currentUser?.basicInfo.sessionId else {
            return Single.error(ReoqooError.generalError(reason: .optionalTypeUnwrapped))
        }
        return Single.create { single in
            RQApi.Api.unregister(userId: userId, password: password, sessionId: sessionId, reasonType: reasonType, reasonDesc: reasonDesc) {
                let res = ResponseHandler.responseHandling(jsonStr: $0, error: $1)
                if case .success = res {
                    single(.success(()))
                }
                if case .failure(let err) = res {
                    single(.failure(err))
                }
            }
            return Disposables.create()
        }
    }
}
