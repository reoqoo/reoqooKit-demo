//
//  IVBLENetCfgManager+Combine.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 5/9/2024.
//

import Foundation
import IVBLE

extension IVBLENetCfgManager {
    // 对权限 检查 和 获取 进行封装 SwiftCombine
    func bleAuthorityCheckingPublisher(config: IVConfiguration) -> AnyPublisher<CBManagerState, Never> {
        Publishers.Create { [weak self] subscriber in
            self?.prepare(config: config, stateChangedHandler: {
                subscriber.send($0)
                subscriber.send(completion: .finished)
            })
            return AnyCancellable.init({
                self?.stopScan()
            })
        }.eraseToAnyPublisher()
    }

    // 对搜索设备操作进行封装
    func bleSearchingPublisher(searchingDuration: TimeInterval = 10) -> AnyPublisher<IVPeripheral, Swift.Error> {
        Publishers.Create<IVPeripheral, Swift.Error> { [weak self] subscriber in
            self?.startScan(duration: searchingDuration, shouldAllowDuplicates: false, clearData: true, discoverPeripheralHandler: { peripheral in
                subscriber.send(peripheral)
            }, onScanTimeOverHandler: {
                // 当 timeOver 时, 抛出错误
                subscriber.send(completion: .failure(ReoqooError.deviceConnectError(reason: .bluetoothPeripheralScanningTimeOver)))
            })
            return AnyCancellable({
                self?.stopScan()
            })
        }.eraseToAnyPublisher()
    }
}
