//
//  AppDelegate.swift
//  RQSDK_Demo_Internal
//
//  Created by xiaojuntao on 23/9/2024.
//

import UIKit
import RQImagePicker

let appName = "xxxxxxx"
let appPkgName = "xxxxxxx"
let appID = "xxxxxx"
let appToken = "xxxxxx"
let privacyPolicyURL = URL.init(string: "https://www.google.com")!
let userAgreementURL = URL.init(string: "https://www.google.com")!

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // 推送注册
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, err in
            if granted {
                logInfo("用户允许APNS远程推送服务")
            }else{
                logInfo("用户拒绝APNS远程推送服务")
            }
        }

        // RQSDK init
        let initialInfo = InitialInfo.init(appName: appName, pkgName: appPkgName, appID: appID, appToken: appToken, language: RQLanguageCode.current, versionPrefix: "8.1", privacyPolicyURL: privacyPolicyURL, userAgreementURL: userAgreementURL, requestHost: .default, superVipId: nil)
        RQCore.Agent.shared.initialze(initialInfo: initialInfo, delegate: RQSDKDelegate.shared, launchOptions: launchOptions)
        // set watermarkImage, this is an optional parameter
        RQCore.Agent.shared.watermarkImage = UIColor.red.pureImage(size: .init(width: 135, height: 36))
        RQDeviceAddition.Agent.shared.delegate = RQSDKDelegate.shared

        RQImagePicker.ImagePickerViewController.localizableStringSetter = {
            switch $0 {
            case .camera:
                return String.localization.localized("AA0546", note: "相机")
            case .photo:
                return String.localization.localized("AA0547", note: "相片")
            case .video:
                return String.localization.localized("AA0548", note: "视频")
            case .select:
                return String.localization.localized("AA0230", note: "选择")
            case .authorizationToAccessMoreAssets:
                return String.localization.localized("AA0609", note: "访问更多")
            case .jump2SystemSettingCauseAuthorizationLimit:
                return String.localization.localized("AA0610", note: "XXXXXXXX只能存取相册部分相片, 建议允许存取`所有相片`, 点击去设置")
            case .jump2SystemSettingCauseAuthorizationDeined:
                return String.localization.localized("AA0611", note: "XXXXXXXX没有相册访问权限, 点击去设置")
            }
        }

        // 固件更新器
        FirmwareUpgradeCenter.shared.observerDeviceList()

        // Start Observe
        RQSDKDelegate.shared.startObserve()

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    /// 成功取得远程推送token
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map({ String.init(format: "%02.2hhx", $0) }).joined()
        logInfo("取得远程推送token: ", token)
        // 同步 APNS token 到服务器
        AccountCenter.shared.currentUser?.syncAPNSToken(token)
    }

    /// 获取远程推送token失败
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        logError("获取远程推送token失败: ", error)
    }

}

extension AppDelegate: UNUserNotificationCenterDelegate {
    // 前台接收到通知
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        logInfo("前台收到推送", userInfo)
        // completionHandler 参数决定是否播放声音和展示推送通知于系统通知栏中
//        completionHandler([.alert, .sound])
        completionHandler([])
        // 推送跳转处理
        Router.apnsHandling(notification: notification, receiveFrom: .front)
    }

    // 点击通知进入app
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        logInfo("点击推送进入app", userInfo)
        completionHandler()
        // 推送跳转处理
        Router.apnsHandling(notification: response.notification, receiveFrom: .background)
    }
}
