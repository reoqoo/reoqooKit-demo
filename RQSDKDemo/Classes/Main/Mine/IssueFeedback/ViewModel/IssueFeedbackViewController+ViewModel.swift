//
//  IssueFeedbackViewController+ViewModel.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 4/9/2023.
//

import Foundation
import RQImagePicker
import SSZipArchive
import IVDevTools

extension IssueFeedbackViewController {
    class ViewModel {

        /// 出现频率
        var selectedFrequency: FrequencyType?
        /// 用户从H5选择的问题类型
        var issueCategoryHelpCenterType: Int?
        /// 用户当前选择的问题分类
        @Published var issueCategory: IssueFeedbackViewController.IssueCatgory?
        /// 请求到的问题分类
        @Published var issueCategorys: [IssueFeedbackViewController.IssueCatgory] = []
        /// 设备
        @Published var deviceType: IssueFeedbackViewController.DeviceType?

        @Published var imageCollectionViewDataSources: [IssueFeedbackViewController.ImageCollectionViewDataSource] = [.add]

        // 默认选中7天前
        @Published var issueHappendTime: Date = Date().byAdding(.day, value: -7) ?? Date()

        /// 是否共享日志
        @Published var shareLogsCheckboxValue: Bool = true

        /// 获取问题分类请求的结果
        @Published var getCategorysResult: Result<[IssueFeedbackViewController.IssueCatgory], Swift.Error>?
        /// 提交反馈结果
        @Published var commitResult: Result<String, Swift.Error>?

        private var anyCancellables: Set<AnyCancellable> = []

        /// 插入新的 images
        func insertImages(_ images: [ImagePickerViewController.MediaItem]) {
            // 将 .add 干掉
            self.imageCollectionViewDataSources.removeAll(where: {
                if case .add = $0 { return true }
                return false
            })
            // 添加新的到末尾
            var result = self.imageCollectionViewDataSources + images.map({ .image($0) })
            // 如果小于 9 张, 后面加上 .add, 允许用户继续添加
            if result.count < IssueFeedbackTableViewController.limitOfImages { result += [.add] }

            self.imageCollectionViewDataSources = result
        }

        /// 移除 image
        func removeImage(at idx: Int) {
            print("哈哈哈", idx)
            // 安全移除
            guard let _ = self.imageCollectionViewDataSources[safe_: idx] else { return }
            // 先把 .add 干掉
            self.imageCollectionViewDataSources.removeAll(where: {
                if case .add = $0 { return true }
                return false
            })
            print("哈哈哈", self.imageCollectionViewDataSources)
            // 移除项目
            self.imageCollectionViewDataSources.remove(at: idx)
            self.imageCollectionViewDataSources += [.add]
        }

        /// 计算剩余可插入图片数量
        func remainderQuotaOfImages() -> Int {
            // 统计已用额度
            let flag = self.imageCollectionViewDataSources.filter({
                if case .image = $0 { return true }
                return false
            }).count
            return IssueFeedbackTableViewController.limitOfImages - flag
        }

        /// 获取问题分类列表
        func getIssueCategorys() {
            self.requestIssueCategoryPublisher().catch({ _ in
            let jsonStr =
"""
[{"helpCenterType":1,"id":14,"name":"添加设备","hot":100},{"helpCenterType":2,"id":15,"name":"监控异常","hot":95},{"helpCenterType":13,"id":16,"name":"智能守护","hot":90},{"helpCenterType":6,"id":17,"name":"云服务","hot":85},{"helpCenterType":5,"id":18,"name":"云录像","hot":80},{"helpCenterType":4,"id":19,"name":"卡录像","hot":75},{"helpCenterType":3,"id":20,"name":"报警功能","hot":70},{"helpCenterType":51,"id":21,"name":"流量充值","hot":70},{"helpCenterType":0,"id":22,"name":"其他问题","hot":60}]
"""
                let json = JSON.init(parseJSON: jsonStr)
                let categorys = try! json.decoded(as: [IssueFeedbackViewController.IssueCatgory].self)
                return Just.init(categorys)
            }).sink { [weak self] completion in
                guard case let .failure(err) = completion else { return }
                self?.getCategorysResult = .failure(err)
            } receiveValue: { [weak self] categorys in
                self?.issueCategorys = categorys
                self?.getCategorysResult = .success(categorys)
                // 设置默认选定项
                guard let issueCategoryHelpCenterType = self?.issueCategoryHelpCenterType else { return }
                self?.issueCategory = self?.issueCategorys.first(where: { $0.helpCenterType == issueCategoryHelpCenterType })
            }.store(in: &self.anyCancellables)
        }

        // 提交反馈
        func commit(description: String?, contact: String?) {

            if let contact = contact, !contact.isEmpty, (!contact.isValidEmail && !contact.isValidTelephoneNumber) {
                self.commitResult = .failure(IssueFeedbackViewController.Error.accountFormatError)
                return
            }

            guard let description = description else {
                self.commitResult = .failure(IssueFeedbackViewController.Error.descriptionIsEmpty)
                return
            }
            guard let _ = self.issueCategory else {
                self.commitResult = .failure(IssueFeedbackViewController.Error.issueCategoryIsEmpty)
                return
            }
            self.commitFeedbackPublisher(description: description, contact: contact).sink { [weak self] completion in
                guard case let .failure(err) = completion else { return }
                logError("提交反馈失败:", err)
                self?.commitResult = .failure(err)
            } receiveValue: { [weak self] json in
                let feedbackID = json["data"]["feedbackId"].stringValue
                self?.commitResult = .success(feedbackID)
            }.store(in: &self.anyCancellables)
        }

        // MARK: 发布者封装
        // 获取问题分类接口
        func requestIssueCategoryPublisher() -> AnyPublisher<[IssueFeedbackViewController.IssueCatgory], Swift.Error> {
            Combine.Future<JSON, Swift.Error>.init { promise in
                RQApi.Api.getIssuesType {
                    let result = ResponseHandler.responseHandling(jsonStr: $0, error: $1)
                    promise(result)
                }
            }
            .tryMap({ json in
                try json["data"]["insideData"].decoded(as: [IssueFeedbackViewController.IssueCatgory].self)
            })
            .eraseToAnyPublisher()
        }

        // 上传日志
        func uploadLogPublisher() -> AnyPublisher<String, Swift.Error> {
            // 压缩日志
            let startTime = self.issueHappendTime.timeIntervalSince1970
            let password = (AccountCenter.shared.currentUser?.basicInfo.userId ?? "0").md5
            let zipFilePublisher = Future<String, Swift.Error>.init { promise in
                IVLogger.zipLog(startTime: startTime, endTime: Date().timeIntervalSince1970, logTypes: [.crash, .log], password: password, aes: false) { result in
                    promise(result)
                }
            }
            // 上传日志
            return zipFilePublisher.flatMap({ path in
                guard let data = FileManager.default.contents(atPath: path) else {
                    return Combine.Fail<String, Swift.Error>(error: ReoqooError.generalError(reason: .optionalTypeUnwrapped)).eraseToAnyPublisher()
                }
                let fileName = (path as NSString).lastPathComponent
                return Future<String, Swift.Error>.init { promise in
                    RQCore.Agent.shared.ivVasMgr.uploadResource(data, fileName: fileName, resType: .appLog, resDesc: nil, keyWord: nil, expireTime: -1) {
                        let result = ResponseHandler.responseHandling(jsonStr: $0, error: $1)
                        if case let .failure(err) = result {
                            promise(.failure(err))
                        }
                        if case let .success(json) = result {
                            let resId = json["data"]["resId"].stringValue
                            promise(.success(resId))
                        }
                    }
                }.eraseToAnyPublisher()
            })
            .eraseToAnyPublisher()
        }

        // 上传图片
        func uploadImagesPublisher() -> AnyPublisher<String, Swift.Error> {
            // 压缩图片
            let imageURLs = self.imageCollectionViewDataSources.reduce(into: [URL](), { partialResult, dataItem in
                guard case let .image(mediaItem) = dataItem else { return }
                guard let url = mediaItem.imageDataURL else { return }
                partialResult.append(url)
            })
            let imagePaths = imageURLs.map({ $0.path })
            // 用户没有传图片, 直接返回 空字符串
            if imagePaths.isEmpty {
                return Just.init("").tryMap({ $0 }).eraseToAnyPublisher()
            }
            let zipDestination: String = URL.feedbackImagesZipDestination.path
            // 先删除
            try? FileManager.default.removeItem(atPath: zipDestination)
            let zipPassword = (AccountCenter.shared.currentUser?.basicInfo.userId ?? "0").md5
            // 压缩图片发布者
            let zipImagePublisher = Future<String, Swift.Error>.init { promise in
                if SSZipArchive.createZipFile(atPath: zipDestination, withFilesAtPaths: imagePaths, withPassword: zipPassword) {
                    promise(.success(zipDestination))
                }else{
                    promise(.failure(ReoqooError.generalError(reason: ReoqooError.GeneralErrorReason.zipFileFailure)))
                }
            }

            // 上传
            return zipImagePublisher.flatMap { zipDestination in
                guard let fileData = FileManager.default.contents(atPath: zipDestination) else {
                    return Combine.Fail<String, Swift.Error>(error: ReoqooError.generalError(reason: .optionalTypeUnwrapped)).eraseToAnyPublisher()
                }
                let fileName = (zipDestination as NSString).lastPathComponent
                return Future<String, Swift.Error>.init { promise in
                    RQCore.Agent.shared.ivVasMgr.uploadResource(fileData, fileName: fileName, resType: .commIcon, resDesc: nil, keyWord: nil, expireTime: -1) {
                        let result = ResponseHandler.responseHandling(jsonStr: $0, error: $1)
                        if case let .failure(err) = result {
                            promise(.failure(err))
                        }
                        if case let .success(json) = result {
                            let resId = json["data"]["resId"].stringValue
                            promise(.success(resId))
                        }
                    }
                }.eraseToAnyPublisher()
            }.eraseToAnyPublisher()
        }

        /// 提交反馈
        /// 将上传日志, 上传图片两个操作合并, 都成功后, 发起反馈请求
        func commitFeedbackPublisher(description: String, contact: String?) -> AnyPublisher<JSON, Swift.Error> {

            let uploadLogPublisher = self.uploadLogPublisher()
            let uploadImagePublisher = self.uploadImagesPublisher()

            // 上传图片操作
            var combineLatest = Publishers.CombineLatest.init(uploadImagePublisher, Just.init("").tryMap({ $0 }).eraseToAnyPublisher())
            // 勾选了共享日志
            if self.shareLogsCheckboxValue {
                combineLatest = Publishers.CombineLatest(uploadImagePublisher, uploadLogPublisher)
            }
            
            var deviceId = "0"
            var deviceVersion = "0"
            if case let .device(device) = self.deviceType {
                deviceId = device.deviceId
                deviceVersion = device.presentVersion ?? ""
            }

            let issueType = self.issueCategory?.id ?? 0
            let frequency = self.selectedFrequency?.ivType ?? .none
            let happendTime = self.issueHappendTime.timeIntervalSince1970
            
            // 上传图片完成 且 上传日志完成后, 提交反馈
            return combineLatest.flatMap { (uploadImagesResId, uploadLogsResId) in
                let imageResIds = uploadImagesResId.isEmpty ? [] : [uploadImagesResId]
                return Future<JSON, Swift.Error>.init { promise in
                    RQApi.Api.commitFeedback(deviceId: deviceId, questionTypeValue: issueType, frequency: frequency, happenTime: happendTime, description: description, contact: contact, deviceVersion: deviceVersion, logResourceIdString: uploadLogsResId, photoResourceIdStringArray: imageResIds) {
                        let result = ResponseHandler.responseHandling(jsonStr: $0, error: $1)
                        promise(result)
                    }
                }.eraseToAnyPublisher()
            }.eraseToAnyPublisher()
        }

    }
}
