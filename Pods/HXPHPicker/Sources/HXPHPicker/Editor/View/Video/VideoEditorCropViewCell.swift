//
//  VideoEditorCropViewCell.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/9.
//

import UIKit

class VideoEditorCropViewCell: UICollectionViewCell {
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView.init()
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    var image: UIImage? {
        didSet {
            imageView.setImage(image, animated: true)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(imageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
    }
}
