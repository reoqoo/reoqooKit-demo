//
//  DeviceUpgradeViewController+Model.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 7/10/2023.
//

import Foundation

extension DeviceFirmwareUpgradeViewController {

    class TableViewCellItem {

        var task: FirmwareUpgradeTask
        var isExpanded: Bool

        var device: DeviceEntity? {
            DeviceManager2.fetchDevice(self.task.deviceId)
        }

        init(task: FirmwareUpgradeTask, isExpanded: Bool) {
            self.task = task
            self.isExpanded = isExpanded
        }
    }

}
