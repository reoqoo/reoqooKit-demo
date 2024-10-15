//
//  UIButton+.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 25/7/2023.
//

import UIKit

// IVButton 太臃肿了, 放在StackView时出现些很诡异的显示情况, 不得不用这个简单的解决方案
extension UIButton {
    func moveTitleLabel2Bottom(margin: CGFloat) {
        let titleSize = self.titleLabel?.text?.sizeWithFont(self.titleLabel?.font ?? .systemFont(ofSize: 14)) ?? .zero
        let imgSize = self.currentImage?.size ?? .zero
        
        self.imageEdgeInsets = UIEdgeInsets.init(top: -(titleSize.height + margin), left: 0, bottom: 0, right: -titleSize.width)
        self.titleEdgeInsets = UIEdgeInsets.init(top: 0, left: -imgSize.width, bottom: -(imgSize.height + margin), right: 0)
        let edgeOffset = abs(titleSize.height - imgSize.height) * 0.5
        self.contentEdgeInsets = UIEdgeInsets.init(top: edgeOffset, left: 0, bottom: edgeOffset, right: 0)
    }
    
    func exchangedPoistionWithTitleLabelAndImageView(margin: CGFloat) {
        let titleSize = self.titleLabel?.text?.sizeWithFont(self.titleLabel?.font ?? .systemFont(ofSize: 14)) ?? .zero
        let imageSize = self.currentImage?.size ?? .zero
        self.imageEdgeInsets = UIEdgeInsets.init(top: 0, left: titleSize.width + margin / 2, bottom: 0, right: -titleSize.width - margin / 2)
        self.titleEdgeInsets = UIEdgeInsets.init(top: 0, left: -imageSize.width - margin / 2, bottom: 0, right: imageSize.width + margin / 2)
        self.contentEdgeInsets = UIEdgeInsets.init(top: 0, left: margin, bottom: 0, right: margin)
    }
}
