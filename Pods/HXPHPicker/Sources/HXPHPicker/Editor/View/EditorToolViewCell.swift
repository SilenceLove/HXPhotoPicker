//
//  EditorToolViewCell.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/9.
//

import UIKit

class EditorToolViewCell: UICollectionViewCell {
    lazy var boxView: SelectBoxView = {
        let view = SelectBoxView.init(frame: CGRect(x: 0, y: 0, width: 12, height: 12))
        view.isHidden = true
        view.config.style = .tick
        view.config.tickWidth = 1
        view.config.tickColor = .white
        view.config.tickDarkColor = .white
        view.isUserInteractionEnabled = false
        return view
    }()
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView.init()
        return imageView
    }()
    
    var showBox: Bool = false {
        didSet {
            boxView.isSelected = showBox
            boxView.isHidden = !showBox
        }
    }
    var boxColor: UIColor! {
        didSet {
            boxView.config.selectedBackgroundColor = boxColor
            boxView.config.selectedBackgroudDarkColor = boxColor
        }
    }
    
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
        addSubview(boxView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.size = imageView.image?.size ?? .zero
        imageView.center = CGPoint(x: width * 0.5, y: height * 0.5)
        
        boxView.x = imageView.frame.maxX - boxView.width * 0.5
        boxView.y = imageView.frame.maxY - boxView.height + 3
    }
}
