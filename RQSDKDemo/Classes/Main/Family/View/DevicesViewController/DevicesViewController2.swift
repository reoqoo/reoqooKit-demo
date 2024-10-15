//
//  DevicesViewController2.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 1/2/2024.
//

import UIKit

class DevicesViewController2: BaseViewController {

    lazy var layout = UICollectionViewFlowLayout().then {
        $0.minimumLineSpacing = self.cellMargin
    }
    
    private let cellMargin: Double = 16

    lazy var collectionView = InfiltrateCollectionView(frame: .zero, collectionViewLayout: layout).then {
        $0.delegate = self
        $0.dataSource = self
        $0.dragDelegate = self
        $0.dropDelegate = self
        $0.dragInteractionEnabled = true
        $0.reorderingCadence = .immediate
        $0.bounces = false
        $0.backgroundColor = .clear
        $0.showsHorizontalScrollIndicator = false
        $0.showsVerticalScrollIndicator = false
        $0.contentInsetAdjustmentBehavior = .never
        $0.contentInset = UIEdgeInsets(top: self.cellMargin, left: self.cellMargin, bottom: self.cellMargin, right: self.cellMargin)
        $0.register(DeviceCollectionViewCell.self, forCellWithReuseIdentifier: String.init(describing: DeviceCollectionViewCell.self))
    }

    var devices: [DeviceEntity] = []

    lazy var emptyView: EmptyDevicesPlaceholder = .init().then {
        $0.isHidden = true
    }

    /// 指向当前正在展示的长按菜单
    weak var longPressMenu: PopoverListView?

    private let disposeBag: DisposeBag = .init()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(self.collectionView)
        self.collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 2024/2/22 用 EmptyDataSet 显示 emptyView 总是会偏移不居中, 所以不使用 EmptyDataSet 方案了
        self.view.addSubview(self.emptyView)
        self.emptyView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        // 监听设备以构建设备列表
        DeviceManager2.shared.generateDevicesObservable(keyPaths: [\.deviceListSortID, \.deviceId])
            .map({ $0?.sorted(by: \.deviceListSortID, ascending: true).toArray() ?? [] })
            .bind { [weak self] devs in
                self?.emptyView.isHidden = devs.count != 0
                self?.devices = devs
                self?.collectionView.reloadData()
            }.disposed(by: self.disposeBag)

        // emptyView 点击了新增设备按钮
        self.emptyView.addDeviceBtnOnClickObservable.bind { [weak self] in
            let vc = QRCodeScanningViewController.init(for: .addDevice)
            self?.navigationController?.pushViewController(vc, animated: true)
        }.disposed(by: self.disposeBag)
    }
    
}

// MARK: FamilyViewControllerChildren
extension DevicesViewController2: FamilyViewControllerChildren {
    func pullToRefresh(completion: (()->())?) {
        DeviceManager2.shared.requestDevicesObservable().subscribe(onNext: { devs in
            completion?()
        }, onError: { err in
            completion?()
        }).disposed(by: self.disposeBag)
    }

    var mainScrollView: UIScrollView? { self.collectionView }
}

extension DevicesViewController2: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.devices.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String.init(describing: DeviceCollectionViewCell.self), for: indexPath) as! DeviceCollectionViewCell
        let device = self.devices[safe_: indexPath.item]
        cell.device = device
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? DeviceCollectionViewCell else { return }
        cell.powerButtonClickedObservable.bind { [weak self] devID, on in
            self?.presentTurningPowerAlert(devID, on: on)
        }.disposed(by: cell.extraDisposeBag)
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? DeviceCollectionViewCell else { return }
        cell.extraDisposeBag = .init()
    }
}

extension DevicesViewController2: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let device = self.devices[safe_: indexPath.item], let tabBarController = self.tabBarController else { return }
        RQCore.Agent.shared.openSurveillance(device: device, triggerViewController: tabBarController)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width  = (UIScreen.width - self.cellMargin * 3) / 2
        let height = width * 0.76
        return CGSize(width: width, height: height)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let parent = self.parent as? FamilyViewController2 else { return }
        parent.childViewControllerScrollViewDidScroll(scrollView)
    }
}

extension DevicesViewController2: UICollectionViewDragDelegate {

    /// 识别到拖动
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        logDebug("device cell recognize drap: \(indexPath)")

        if let cell = collectionView.cellForItem(at: indexPath), let device = self.devices[safe_: indexPath.item] {
            self.longPress(device: device, cell: cell)
        }

        let itemProvider = NSItemProvider(object: "\(indexPath)" as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = self.devices[indexPath.item]
        return [dragItem]
    }

    /// 添加拖动任务
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        logDebug("device cell will drap: \(indexPath)")
        let itemProvider = NSItemProvider(object: "\(indexPath)" as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = self.devices[indexPath.item]
        return [dragItem]
    }

    /// 开始拖动
    func collectionView(_ collectionView: UICollectionView, dragSessionWillBegin session: UIDragSession) {
        logDebug("device cell begin drap: \(session)")
        self.longPressMenu?.popoverView.dismiss()
    }

    /// 结束拖动
    func collectionView(_ collectionView: UICollectionView, dragSessionDidEnd session: UIDragSession) {
        logDebug("device cell end drap: \(session)")
    }
}

extension DevicesViewController2: UICollectionViewDropDelegate {

    /// 放置权限
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return true
    }

    /// 放置的策略
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        /**
         放置的策略. 一般有 4 类
         move 移动，copy 拷贝，
         forbidden 禁止， 即不能放置
         cancel, 用户取消
         细分选项有
         .insertAtDestinationIndexPath， 挤到一边去
         .insertIntoDestinationIndexPath， 取代
         */
        // 确保放置的item是来自本app 且 仅为当前Collectionview
        guard let _ = session.localDragSession, collectionView.hasActiveDrag else { return .init(operation: .forbidden) }
        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }

    /// 结束放置, 重排元素及cell
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let destinationIndexPath = coordinator.destinationIndexPath else { return }
        guard case .move = coordinator.proposal.operation, let item = coordinator.items.first, let sourceIndexPath = item.sourceIndexPath, let sourceDevice = item.dragItem.localObject as? DeviceEntity else { return }

        logDebug("sourceIndexPath = \(sourceIndexPath.item), destinationIndexPath = \(destinationIndexPath.item)")

        // 更新cell
        collectionView.performBatchUpdates ({
            self.devices.remove(at: sourceIndexPath.item)
            self.devices.insert(sourceDevice, at: destinationIndexPath.item)
            collectionView.deleteItems(at: [sourceIndexPath])
            collectionView.insertItems(at: [destinationIndexPath])
        })
        
        coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidEnd session: UIDropSession) {
        logDebug("func collectionView(_ collectionView: UICollectionView, dropSessionDidEnd session: UIDropSession)")
        // 整个拖拽事件结束, 对排序后的结果写库
        DeviceManager2.db_updateDevicesWithContext { [weak self] _ in
            self?.devices.enumerated().forEach({ idx, dev in
                dev.deviceListSortID = idx
            })
        }
    }
}

// MARK: Helper
extension DevicesViewController2 {
    func presentTurningPowerAlert(_ deviceId: String, on: Bool) {
        let property = ReoqooPopupViewProperty()
        if on {
            property.message = String.localization.localized("AA0061", note: "确定开启设备吗？")
        } else {
            property.message = String.localization.localized("AA0060", note: "确定关闭设备吗？")
        }

        let popupView = IVPopupView(property: property, actions: [
            IVPopupAction(title: String.localization.localized("AA0059", note: "取消"), style: .custom, color: R.color.text_link_4A68A6(), handler: {}),
            IVPopupAction(title: String.localization.localized("AA0058", note: "确定"), style: .custom, color: R.color.button_destructive_FA2A2D(), handler: {
                DeviceManager2.shared.turnOnDevice(deviceId, on: on)
            })
        ])

        popupView.show()
    }

    func longPress(device: DeviceEntity, cell: UICollectionViewCell) {
        let popoverOptions: [PopoverOption] = [.arrowSize(.init(width: 24, height: 12)), .type(.down), .animationIn(0.2), .animationOut(0), .cornerRadius(16), .springDamping(1), .initialSpringVelocity(1), .showBlackOverlay(false), .shadowOffset(.init(width: 2, height: 2)), .shadowRadius(8), .type(.verticalAuto)]

        let deviceId = device.deviceId
        let shareItem: PopoverListView.Item = .init(image: R.image.family_share(), title: String.localization.localized("AA0050", note: "分享设备"), handler: {
            let vc = ShareToManagedViewController.init(deviceId: deviceId)
            self.navigationController?.pushViewController(vc, animated: true)
        })
        let deleteItem: PopoverListView.Item = .init(image: R.image.family_delete(), title: String.localization.localized("AA0056", note: "删除设备"), handler: {
            let property = ReoqooPopupViewProperty()
            property.message = String.localization.localized("AA0173", note: "确定要删除设备吗？")
            IVPopupView(property: property, actions: [
                IVPopupAction(title: String.localization.localized("AA0059", note: "取消"), style: .custom, color: R.color.text_link_4A68A6(), handler: {}),
                IVPopupAction(title: String.localization.localized("AA0058", note: "确定"), style: .custom, color: R.color.button_destructive_FA2A2D(), handler: {
                    DeviceManager2.shared.deleteDevice(device, deleteOperationFrom: .app)
                })]).show()
        })

        var items: [PopoverListView.Item] = []
        if device.role == .master { items.append(shareItem) }
        items.append(deleteItem)

        let listView = PopoverListView.init(options: popoverOptions, items: items, frame: .init(x: 0, y: 12, width: 160, height: 50 * items.count), rowHeight: 50)
        listView.tableView.separatorInset = .init(top: 0, left: 48, bottom: 0, right: 16)
        listView.show(fromView: cell, inView: AppEntranceManager.shared.keyWindow!)
        self.longPressMenu = listView
    }

}
