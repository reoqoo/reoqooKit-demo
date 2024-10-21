//
//  RQSDKDelegate.swift
//  RQSDK_Demo_Internal
//
//  Created by xiaojuntao on 24/9/2024.
//

import Foundation

class RQSDKDelegate {
    static let shared: RQSDKDelegate = .init()
    private init() {}

    /// IoTVideoSDK连接状态，外部可监听该状态变化
    @RxPublished var linkStatus: IVLinkStatus = .unregistering

    /// p2p在线消息内容，外部可监听该状态变化
    @RxPublished var p2pOnlineMsg: RQCore.P2POnlineMsg = .init()
}

extension RQSDKDelegate: RQCore.Delegate {

    func reoqooSDKAskForUpdateAccessToken(_ agent: RQCore.Agent) {
        AccountCenter.shared.currentUser?.tryRefreshToken()
    }

    func reoqooSDKRequestDevices(_ agent: RQCore.Agent) -> [any RQCore.Device] {
        DeviceManager2.shared.devices.toArray()
    }
    
    func reoqooSDKRequestDevice(_ agent: RQCore.Agent, deviceId: String) -> (any RQCore.Device)? {
        DeviceManager2.fetchDevice(deviceId)
    }
    
    func reoqooSDKDidRenameDevice(_ agent: RQCore.Agent, deviceId: String, result: Result<String, Error>) {
        guard let newName = result.value else { return }
        DeviceManager2.db_updateDevicesWithContext { _ in
            let dev = DeviceManager2.fetchDevice(deviceId)
            dev?.remarkName = newName
        }
    }
    
    func reoqooSDKDidDeletedDevice(_ agent: RQCore.Agent, deviceId: String, result: Result<Void, Error>) {
        guard let dev = DeviceManager2.fetchDevice(deviceId) else { return }
        DeviceManager2.shared.db_markDevicesAsDeleted(devices: [dev], deleteOperationFrom: .reoqooSDK)
    }
    
    func reoqooSDKDeviceStatusDidChanged(_ agent: RQCore.Agent, status: RQCore.DeviceStatus, deviceId: String) {
        DeviceManager2.db_updateDevicesWithContext { db in
            let dev = DeviceManager2.fetchDevice(deviceId)
            dev?.status = status
        }
    }
    
    func reoqooSDK(_ agent: RQCore.Agent, shouldJumpToDestination destination: JumpDestinationType, deviceId: String, properties: [String: AnyHashable]?) {
        let navigationVC = AppEntranceManager.shared.keyWindow?.rootViewController as! UINavigationController
        navigationVC.setNavigationBarHidden(false, animated: true)

        switch (destination) {
        case .firmwareUpdate:
            let vc = DeviceFirmwareUpgradeViewController.init()
            vc.targetDeviceId = deviceId
            navigationVC.pushViewController(vc, animated: true)
        case .deviceShare:
            let vc = ShareToManagedViewController(deviceId: deviceId)
            navigationVC.pushViewController(vc, animated: true)
        case .cloudServices:
            let device = DeviceManager2.fetchDevice(deviceId)
            let vc = VASServiceWebViewController.init(url: StandardConfiguration.shared.vasH5URL, device: device)
            vc.statisticsProperties = properties
            navigationVC.pushViewController(vc, animated: true)
        case .simCardServices:
            let device = DeviceManager2.fetchDevice(deviceId)
            let vc = VASServiceWebViewController.init(url: StandardConfiguration.shared.fourGFluxH5URL, device: device)
            vc.statisticsProperties = properties
            navigationVC.pushViewController(vc, animated: true)
        default: break
        }
    }
    
    func reoqooSDK(_ agent: RQCore.Agent, isDeviceUpdating deviceId: String) -> Bool {
        FirmwareUpgradeCenter.shared.tasks.contains(where: { $0.deviceId == deviceId && $0.upgradeStatus.isUpdating })
    }
    
    func reoqooSDK(_ agent: RQCore.Agent, deviceId: String, updateProgressDidChanged progress: Int) {
        // 接收到更新进度, 通知到 FirmwareUpgradeCenter
        FirmwareUpgradeCenter.shared.handOutProgress(deviceId: deviceId, progress: progress)
    }
    
    func reoqooSDK(_ agent: RQCore.Agent, deviceId: String, didConfirmNewVersion newVersion: String) {
        // 设备(主动)检查新版本后, Iotvideo 会传输 "Action._otaVersion" 消息到客户端, 当客户端接收到该消息后, 表示设备可以升级了
        // 所以调用此方法, 告知设备可以升级了
        FirmwareUpgradeCenter.shared.didConfirmNewVersion(deviceId: deviceId)
    }
    
    func reoqooSDK(_ agent: RQCore.Agent, didReceivedP2PMsg msg: RQCore.P2POnlineMsg) {
        self.p2pOnlineMsg = msg
    }

    func reoqooSDK(_ agent: RQCore.Agent, iotVideoLinkStatusDidChanged linkStatus: IVLinkStatus) {
        self.linkStatus = linkStatus
    }

    func reoqooSDK(_ agent: RQCore.Agent, toStatisticEvent event: String, properties: [String : AnyHashable]) {}
}

extension RQSDKDelegate: RQDeviceAddition.Delegate {
    func reoqooDeviceAddition(_ agent: RQDeviceAddition.Agent, didFinishAddDeviceWithId deviceId: String, deviceName: String) {
        DeviceManager2.shared.addDevice(deviceId: deviceId, deviceName: deviceName, deviceRole: .master, permission: nil, needTiggerPresent: true)
    }
}
