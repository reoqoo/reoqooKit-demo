//
//  UserProfileTableViewController+ViewModel.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 14/9/2023.
//

import Foundation
import IVAccountMgr

extension UserProfileTableViewController.ViewModel {

    enum Status {
        case idle
        case didCompleteModifyUserInfo(Result<Void, Swift.Error>)
    }

    enum Event {
        case modifyUserInfo(header: String?, nick: String?, oldPassword: String?, newPassword: String?)
    }
}

extension UserProfileTableViewController {

    class ViewModel {

        @RxPublished var status: Status = .idle

        let disposeBag = DisposeBag()

        func processEvent(_ event: Event) {
            switch event {
            case let .modifyUserInfo(header, nick, oldPassword, newPassword):
                // 检查 昵称 格式是否正确
                if let nick = nick, nick.isContainEmoji {
                    self.status = .didCompleteModifyUserInfo(.failure(ReoqooError.accountError(reason: .nickNameContainInvalidCharacter)))
                    return
                }
                AccountCenter.shared.currentUser?.modifyUserInfoObservable(header: header, nick: nick, oldPassword: oldPassword, newPassword: newPassword).subscribe(onSuccess: { [weak self] _ in
                    self?.status = .didCompleteModifyUserInfo(.success(()))
                }, onFailure: { [weak self] err in
                    self?.status = .didCompleteModifyUserInfo(.failure(err))
                }).disposed(by: self.disposeBag)
            }
        }

        // MARK: 发布者封装
        
    }
}
