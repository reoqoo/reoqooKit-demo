//
//  IssueFeedbackViewController+CollectionViewCell.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 4/9/2023.
//

import Foundation

extension IssueFeedbackTableViewController {

    class AddImageCollectionViewCell: UICollectionViewCell {
        lazy var imageView: UIImageView = .init(image: R.image.commonAddStyle0()).then {
            $0.contentMode = .scaleAspectFill
        }

        override init(frame: CGRect) {
            super.init(frame: frame)

            self.contentView.addSubview(self.imageView)
            self.imageView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    class ImageCollectionViewCell: UICollectionViewCell {

        var imageItem: IssueFeedbackViewController.ImageCollectionViewDataSource? {
            didSet {
                guard case let .image(mediaItem) = imageItem else { return }
                self.imageView.kf.setImage(with: mediaItem.imageDataURL, options: [.processor(ResizingImageProcessor(referenceSize: .init(width: 120, height: 120)))])
            }
        }

        let deleteBtnTapPublisher: Combine.PassthroughSubject<Void, Never> = .init()
        var externalAnyCancellables: Set<AnyCancellable> = []
        private var anyCancellables: Set<AnyCancellable> = []

        lazy var imageView: UIImageView = .init().then {
            $0.contentMode = .scaleAspectFill
            $0.clipsToBounds = true
            $0.layer.cornerRadius = 4
        }

        lazy var deleteBtn: UIButton = .init(type: .custom).then {
            $0.setImage(R.image.commonDeleteStyle0(), for: .normal)
        }

        private let disposeBag: DisposeBag = .init()

        override init(frame: CGRect) {
            super.init(frame: frame)

            self.contentView.addSubview(self.imageView)
            self.imageView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }

            self.contentView.addSubview(self.deleteBtn)
            self.deleteBtn.snp.makeConstraints { make in
                make.centerX.equalTo(self.contentView.snp.trailing)
                make.centerY.equalTo(self.contentView.snp.top)
            }

            self.deleteBtn.tapPublisher.sink { [weak self] in
                self?.deleteBtnTapPublisher.send(())
            }.store(in: &self.anyCancellables)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // 重写 hisTest 以扩大 deleteBtn 的点击范围
        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            let rect = CGRect.init(x: 0, y: -24, width: self.bounds.width + 24, height: self.bounds.height + 24)
            if !rect.contains(point) { return nil }
            // 判断触摸点是否在 DeleteBtn 上
            if self.deleteBtn.frame.contains(point) {
                return self.deleteBtn
            }
            // 否则返回 self
            return self
        }
    }

    class FrequencyCollectionViewCell: UICollectionViewCell {
        var frequencyType: IssueFeedbackViewController.FrequencyType? {
            didSet {
                self.label.text = self.frequencyType?.description
            }
        }

        lazy var label: UILabel = .init().then {
            $0.font = .systemFont(ofSize: 14)
            $0.textColor = R.color.text_000000_90()
            $0.textAlignment = .center
        }

        override init(frame: CGRect) {
            super.init(frame: frame)

            self.backgroundColor = .clear

            self.contentView.backgroundColor = R.color.background_000000_5()
            self.contentView.layer.cornerRadius = 15
            self.contentView.layer.masksToBounds = true

            self.contentView.addSubview(self.label)
            self.label.snp.makeConstraints { make in
                make.edges.equalTo(UIEdgeInsets.init(top: 0, left: 12, bottom: 0, right: 12))
                make.height.equalTo(30)
            }
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override var isSelected: Bool {
            didSet {
                self.contentView.backgroundColor = self.isSelected ? R.color.brand()?.withAlphaComponent(0.2) : R.color.background_000000_5()
            }
        }
    }
}
