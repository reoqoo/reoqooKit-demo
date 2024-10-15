//
//  ViewModel.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 10/8/2023.
//

import Foundation
import Vision

extension QRCodeScanningViewController.ViewModel {
    enum Event {
        // 成功识别到二维码
        case didSucceedRecognizeQRCodePayload(value: String?)
        // 请求设备id
        case requestDeviceInfo(sn: String)
        // 捕获到视频数据, 用于AI分析
        case didCaptureVideoDataPixelBuffer(CVImageBuffer)
        // 对一张图片进行AI分析
        case analyzeImage(UIImage)
    }

    enum Status {
        case idle
        /// 二维码不支持
        case QRCodeNotSupported
        /// 识别图片中的二维码失败, 没有二维码
        case cannotRecognizeAnythingFromImage
        /// Vision 成功识别到二维码
        case didDetectedQRCode(results: [VNBarcodeObservation])
        /// 成功识别设备配网二维码
        case didSucceedRecognizeDevice(sn: String, productModule: String)
        /// 通过设备sn换取设备id结果
        case requestDeviceIdWithResult(_ result: Result<PreconnectDevice, Swift.Error>)
        /// 成功识别设备分享二维码
        case didSucceedRecognizeShare(model: ShareQRCodeInfo)
    }

    /// 访客面对面扫码接受分享model
    struct ShareQRCodeInfo {
        /// 设备id
        var deviceID: String = ""
        /// 邀请码
        var inviteCode: String = ""
        /// 权限
        var permission: String = ""
        /// 过期时间
        var expireTime: Int = 0
        /// 产品id
        var productId: String = ""
        /// 产品名称
        var productName: String = ""
    }

}

extension QRCodeScanningViewController {

    enum QRCodeFrom {
        case album
        case camera
    }

    class ViewModel {

        var disposeBag: DisposeBag = .init()

        var anyCancellables: Set<AnyCancellable> = []

        @DidSetPublished var status: Status = .idle
        
        // Vision AI识别视频二维码请求
        private lazy var videoDataDetectQRCodeRequest: VNDetectBarcodesRequest = .init(completionHandler: { [weak self] request, err in
            // 识别结果回调
            if let err = err {
                logError("[图像识别] AI识别二维码发生错误", err)
                return
            }
            guard let results = request.results as? [VNBarcodeObservation], results.count != 0 else { return }
            self?.status = .didDetectedQRCode(results: results)
            self?.qrCodeFrom = .camera
        }).then {
            $0.symbologies = [.qr]
        }

        // Vision AI识别图片二维码请求
        private lazy var imageDetectQRCodeRequest: VNDetectBarcodesRequest = .init(completionHandler: { [weak self] request, err in
            // 识别结果回调
            if let err = err {
                logError("[图像识别] AI识别二维码发生错误", err)
                return
            }
            guard let results = request.results as? [VNBarcodeObservation], results.count != 0 else {
                self?.status = .cannotRecognizeAnythingFromImage
                return
            }
            self?.status = .didDetectedQRCode(results: results)
            self?.qrCodeFrom = .album
        }).then {
            $0.symbologies = [.qr]
        }

        /// 用于记录二维码的来源, 埋点用, 非业务
        private(set) var qrCodeFrom: DeviceAdditionFlowItem.QRCodeFrom = .camera
        
        func processEvent(_ event: Event) {
            switch event {
            case .didSucceedRecognizeQRCodePayload(let value):
                self.searchDeviceTemplateFromRecognizeQRCodeValue(value)
            case .requestDeviceInfo(let sn):
                self.requestDeviceInfo(sn: sn)
            case .didCaptureVideoDataPixelBuffer(let sampleBuffer):
                self.qrcodeAiAnalyze(sampleBuffer)
            case .analyzeImage(let img):
                self.qrcodeAiAnalyze(img)
            }
        }

        // MARK: Helper
        /// 对扫描到的二维码信息进行识别, 分离出 PIN码, 设备id, 型号, 尝试从产品模板中找出匹配型号
        func searchDeviceTemplateFromRecognizeQRCodeValue(_ value: String?) {
            QRRecognizer.recognizePublisher(value).sink { [weak self] completion in
                guard case .failure = completion else { return }
                // 既非配网 亦非 分享码
                self?.status = .QRCodeNotSupported
            } receiveValue: { [weak self] result in
                switch result {
                case let .addDevice(sn, model):
                    self?.status = .didSucceedRecognizeDevice(sn: sn, productModule: model)
                case let .acceptedDeviceShareInvite(deviceID, inviteCode, permission, expireTime, productID, productName):
                    var model = ShareQRCodeInfo()
                    model.productId = productID
                    model.deviceID = deviceID
                    model.inviteCode = inviteCode
                    model.permission = permission
                    model.expireTime = Int(expireTime)
                    model.productName = productName
                    self?.status = .didSucceedRecognizeShare(model: model)
                }
            }.store(in: &self.anyCancellables)
        }

        /// 发起请求 获取设备信息
        /// 1. 用 sn 换 productid 和 设备id
        /// 2. 用 productid 换设备模板信息
        func requestDeviceInfo(sn: String) {
            let sn = sn.uppercased()
            // 1. 用 sn 换 productid 和 设备id
            self.requestDeviceInfoFromSNObservable(sn: sn).flatMap({ result in
                // 2.用 productId 匹配设备模板
                ProductTemplate.allSupportedProductTemplateObservable.map { productId_deviceTemplate_mapping -> (String, ProductTemplate) in
                    // 尝试从配置表中找对应的设备模板
                    guard let deviceTemplate = productId_deviceTemplate_mapping[result.productId] else {
                        throw ReoqooError.deviceConnectError(reason: .matchableProductTemplateNotFound)
                    }
                    // 比对 app 版本是否支持
                    if Bundle.majorVersion.compareAsVersionString(deviceTemplate.iOSMinVersion) == .older {
                        throw ReoqooError.deviceConnectError(reason: .appVersionNotSupport)
                    }
                    return (result.deviceId, deviceTemplate)
                }
            }).observe(on: MainScheduler.instance).subscribe { [weak self] result in
                let preconnectDevice = PreconnectDevice.init(sn: sn, deviceId: result.0, template: result.1)
                self?.status = .requestDeviceIdWithResult(.success(preconnectDevice))
            } onFailure: { [weak self] err in
                self?.status = .requestDeviceIdWithResult(.failure(err))
            }.disposed(by: self.disposeBag)
        }

        // MARK: Vision framework 分析
        /// 分析视频数据流
        func qrcodeAiAnalyze(_ sampleBuffer: CVPixelBuffer) {
            let imageRequestHandler = VNImageRequestHandler.init(cvPixelBuffer: sampleBuffer)
            do {
                try imageRequestHandler.perform([self.videoDataDetectQRCodeRequest])
            }catch let err {
                logInfo("[图像识别] AI识别视频中的二维码失败了", err)
            }
        }

        /// 分析一张图片
        func qrcodeAiAnalyze(_ image: UIImage) {
            guard let cgImage = image.cgImage else { return }
            let imageRequestHandler = VNImageRequestHandler.init(cgImage: cgImage)
            do {
                try imageRequestHandler.perform([self.imageDetectQRCodeRequest])
            }catch let err {
                logInfo("[图像识别] AI识别图片中的二维码失败了", err)
            }
        }

        // MARK: Observable封装

        typealias DeviceInfoFromSNResult = (productId: String, deviceId: String)
        /// 通过 SN 获取设备信息
        func requestDeviceInfoFromSNObservable(sn: String) -> Single<DeviceInfoFromSNResult> {
            Single.create { observer in
                RQApi.Api.getDevInfoBySN(sn) {
                    let res = ResponseHandler.responseHandling(jsonStr: $0, error: $1)
                    if case let .failure(err) = res {
                        observer(.failure(err))
                    }
                    if case let .success(json) = res {
                        let productId = json["data"]["productId"].stringValue
                        let deviceId = json["data"]["deviceId"].stringValue
                        observer(.success((productId, deviceId)))
                    }
                }
                return Disposables.create()
            }
        }
    }
}
