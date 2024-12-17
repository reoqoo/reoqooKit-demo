//
//  IssueFeedbackViewController+Model.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 4/9/2023.
//

import Foundation
import RQImagePicker

extension IssueFeedbackViewController {

    enum Error: LocalizedError {
        case accountFormatError
        case descriptionIsEmpty
        case deviceIsEmpty
        case issueCategoryIsEmpty

        var errorDescription: String? {
            switch self {
            case .accountFormatError:
                return String.localization.localized("AA0564", note: "手机号/邮箱格式错误")
            case .descriptionIsEmpty:
                return String.localization.localized("AA0455", note: "请输入问题与建议")
            case .deviceIsEmpty:
                return String.localization.localized("AA0250", note: "请选择设备")
            case .issueCategoryIsEmpty:
                return String.localization.localized("AA0242", note: "请选择问题分类")
            }
        }
    }
    
    /// 设备分类: 设备 / 非设备问题
    enum DeviceType: CustomStringConvertible {
        case none
        case device(DeviceEntity)

        var description: String {
            switch self {
            case let .device(device):
                return device.remarkName
            case .none:
                return String.localization.localized("AA0454", note: "不选择设备")
            }
        }
    }

    /// 对图片选择CollectionView的描述
    enum ImageCollectionViewDataSource {
        case add
        case image(ImagePickerViewController.MediaItem)
    }

    /// 出现频率
    enum FrequencyType: Int, CaseIterable, CustomStringConvertible {
        /// 很少出现
        case rare
        /// 每天一次(狗头)
        case oncePerDay
        /// 每天多次(狗头)
        case multiPerDay
        /// 经常出现
        case always

        var description: String {
            let descriptions: [String] = [
                String.localization.localized("AA0255", note: "很少出现"),
                String.localization.localized("AA0256", note: "一天一次"),
                String.localization.localized("AA0257", note: "一天多次"),
                String.localization.localized("AA0258", note: "一直出现"),
            ]
            return descriptions[self.rawValue]
        }

        var ivType: IVFeedbackFrequency {
            let arr: [IVFeedbackFrequency] = [.seldom, .onceDay, .manyTimesDay, .alway]
            return arr[self.rawValue]
        }
    }

    /// 问题分类模型
    struct IssueCatgory: Codable, Equatable {
        /// H5传来的问题类型
        var helpCenterType: Int
        /// 热度
        var hot: Int
        /// 问题类型id, 提交反馈时用
        var id: Int
        /// 名称
        var name: String
    }
}
