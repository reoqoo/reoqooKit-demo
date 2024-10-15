//
//  DevicePermissionConfigurationViewController.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 19/6/2024.
//

import Foundation

class DevicePermissionConfigurationViewController: BaseViewController {

    let deviceId: String

    init(deviceId: String) {
        self.deviceId = deviceId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    var anyCancellables: [AnyCancellable] = []

    lazy var dataSources: [[DeviceShare.SharePermission]] = [
        [.init(type: .live, serie: .surveillance, isValid: true),
         .init(type: .intercom, serie: .surveillance, isValid: false),
         .init(type: .consoleControl, serie: .surveillance, isValid: false)],

        [.init(type: .playback, serie: .playback, isValid: false)],
        
        [.init(type: .surveillanceConfiguration, serie: .configuration, isValid: false),
         .init(type: .deviceConfiguration, serie: .configuration, isValid: false)]
    ]

    lazy var contentViewController: SelectSharePermissionTableViewController = .init(dataSources: self.dataSources, style: .insetGrouped).then {
        $0.delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = String.localization.localized("AA0647", note: "设备权限")

        self.addChild(self.contentViewController)
        self.view.addSubview(self.contentViewController.view)
        self.contentViewController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        self.contentViewController.tableView.backgroundColor = .systemGroupedBackground
        
        let hud = MBProgressHUD.showLoadingHUD_DispatchOnMainThread()
        RQCore.Agent.shared.getDeviceSharedPermission(deviceId: deviceId) { [weak self] _, _, sharePermission in
            self?.dataSources[0][0].isValid = true
            self?.dataSources[0][1].isValid = sharePermission?.enableSpeakPermission ?? false
            self?.dataSources[0][2].isValid = sharePermission?.enablePtzPermission ?? false

            self?.dataSources[1][0].isValid = sharePermission?.enablePlaybackPermission ?? false

            self?.dataSources[2][0].isValid = sharePermission?.enableSmartGuardPermission ?? false
            self?.dataSources[2][1].isValid = sharePermission?.enableDevConfigPermission ?? false

            self?.contentViewController.tableView.reloadData()
            hud.hideDispatchOnMainThread(afterDelay: 0)
        }
    }
}

// MARK: SelectSharePermissionTableViewControllerDelegate
extension DevicePermissionConfigurationViewController: SelectSharePermissionTableViewControllerDelegate {
    func selectSharePermissionTableViewController(_ controller: SelectSharePermissionTableViewController, switchDidTapAtIndexPath indexPath: IndexPath) {
        // 赋值到 dataSources
        self.dataSources[indexPath.section][indexPath.row].isValid.toggle()
        // 组建 DHSharedPermission
        let permission = RQCore.DeviceSharePermission.init(enableSpeakPermission: self.dataSources[0][1].isValid, enablePtzPermission: self.dataSources[0][2].isValid, enablePlaybackPermission: self.dataSources[1][0].isValid, enableSmartGuardPermission: self.dataSources[2][0].isValid, enableDevConfigPermission: self.dataSources[2][1].isValid)
        // 进入等待状态
        controller.setSwitchState(.wait, atIndexPath: indexPath)
        // 发起修改请求

        RQCore.Agent.shared.setDeviceSharedPermission(sharePermission: permission) { [weak self] code, desc, permission in
            if code != 0 {
                // 出错了, 复位 isValid 值
                self?.dataSources[indexPath.section][indexPath.row].isValid.toggle()
                MBProgressHUD.showHUD_DispatchOnMainThread(text: desc ?? "")
            }
            controller.tableView.reloadData()
        }
    }
}
