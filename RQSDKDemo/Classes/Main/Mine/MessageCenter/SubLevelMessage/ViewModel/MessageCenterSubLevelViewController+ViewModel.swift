//
//  MessageCenterSubLevelViewController+ViewModel.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 19/9/2023.
//

import Foundation

extension MessageCenterSubLevelViewController.ViewModel {
    enum Status {
        case idle
        // 刷新数据后, 通知视图是否还有更多数据, 以便UI更新上拉加载更多的控件
        case refreshHasMoreDataStatus(noMoreData: Bool)
    }

    enum Event {
        case viewDidLoad
        case refresh
        case loadMore
    }
}

extension MessageCenterSubLevelViewController {
    class ViewModel {

        let firstLevelMessageItem: MessageCenter.FirstLevelMessageItem
        init(firstLevelMessageItem: MessageCenter.FirstLevelMessageItem) {
            self.firstLevelMessageItem = firstLevelMessageItem
        }

        /// 二级消息模型
        @RxBehavioral var secondLevenMessageItems: [MessageCenter.SecondLevelMessageItem] = []

        @RxPublished var status: Status = .idle

        private let disposeBag: DisposeBag = .init()

        func processEvent(_ event: Event) {
            switch event {
            case .viewDidLoad, .refresh:
                self.loadData(lastId: nil)
            case .loadMore:
                self.loadData(lastId: self.secondLevenMessageItems.last?.id)
            }
        }

        func loadData(lastId: Int64?, size: Int = 15) {
            // 如果是固件升级消息, 从 MessageCenter 获取
            if self.firstLevelMessageItem.tag == MessageCenter.MessageTag.firmwareUpdate {
                self.requestFirmwareUpgradeMessageListObservable().bind { [weak self] messageItems in
                    self?.status = .refreshHasMoreDataStatus(noMoreData: true)
                    self?.secondLevenMessageItems = messageItems
                }.disposed(by: self.disposeBag)
            }else{
                self.requestSecondLevelMessageListObservable(self.firstLevelMessageItem.tag, lastId: lastId).subscribe { [weak self] messageItems in
                    // lastId == nil 表示 refresh 操作
                    if lastId == nil {
                        self?.secondLevenMessageItems = []
                    }
                    self?.secondLevenMessageItems.append(contentsOf: messageItems)
                    self?.status = .refreshHasMoreDataStatus(noMoreData: messageItems.isEmpty)
                } onFailure: { [weak self] err in
                    self?.status = .refreshHasMoreDataStatus(noMoreData: false)
                }.disposed(by: self.disposeBag)
            }
        }

        // MARK: 发布者封装
        /// 从 MessageCenter 获取 固件升级发布者
        func requestFirmwareUpgradeMessageListObservable() -> Observable<[MessageCenter.SecondLevelMessageItem]> {
            MessageCenter.shared.$deviceFirmwareMessages.map({
                $0.sorted(by: { $0.messageItem.time > $1.messageItem.time }).map({ $0.messageItem })
            })
        }

        /// 从服务器获取二级消息模型 发布者
        func requestSecondLevelMessageListObservable(_ tag: MessageCenter.MessageTag, lastId: Int64?, size: Int = 15) -> Single<[MessageCenter.SecondLevelMessageItem]> {
            Single<JSON>.create { observer in
                RQCore.Agent.shared.ivMsgMgr.secondMessageList(tag: tag.rawValue, lastId: lastId, size: size) {
                    let result = ResponseHandler.responseHandling(jsonStr: $0, error: $1)
                    observer(result)
                }
                return Disposables.create()
            }.map { json -> [MessageCenter.SecondLevelMessageItem] in
                let res = try json["data"]["list"].decoded(as: [MessageCenter.SecondLevelMessageItem].self)
                return res
            }
        }
    }
}
