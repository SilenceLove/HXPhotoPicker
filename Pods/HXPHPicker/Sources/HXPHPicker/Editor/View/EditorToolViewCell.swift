//
//  EditorToolViewCell.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/9.
//

import UIKit

class EditorToolViewCell: UICollectionViewCell {
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView.init()
        return imageView
    }()
    
    var model: EditorToolOptions! {
        didSet {
            imageView.image = UIImage.image(for: model.imageName)?.withRenderingMode(.alwaysTemplate)
            imageView.tintColor = .white
        }
    }
    
    var selectedColor: UIColor?
    
    var isSelectedImageView: Bool = false {
        didSet {
            imageView.tintColor = isSelectedImageView ? selectedColor : .white
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
        imageView.size = imageView.image?.size ?? .zero
        imageView.center = CGPoint(x: width * 0.5, y: height * 0.5)
    }
}
