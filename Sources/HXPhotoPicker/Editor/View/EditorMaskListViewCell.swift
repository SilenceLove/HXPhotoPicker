//
//  EditorMaskListViewCell.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/6/11.
//

import UIKit

class EditorMaskListViewCell: UICollectionViewCell {
    lazy var titleLb: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    var config: EditorConfiguration.CropSize.MaskType? {
        didSet {
            guard let config = config else {
                return
            }
            switch config {
            case .image(let image):
                imageView.image = image.withRenderingMode(.alwaysTemplate)
                imageView.isHidden = false
                titleLb.isHidden = true
            case .imageName(let imageName):
                imageView.image = imageName.image?.withRenderingMode(.alwaysTemplate)
                imageView.isHidden = false
                titleLb.isHidden = true
            case .text(let text, let font):
                titleLb.text = text
                titleLb.font = font
                imageView.isHidden = true
                titleLb.isHidden = false
            }
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        initViews()
    }
    
    func initViews() {
        contentView.addSubview(titleLb)
        contentView.addSubview(imageView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        titleLb.frame = bounds
        imageView.frame = bounds
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
