//
//  EditorStickerTrashView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/7/22.
//

import UIKit

class EditorStickerTrashView: UIView {
    lazy var bgView: UIVisualEffectView = {
        let effect = UIBlurEffect(style: .dark)
        let view = UIVisualEffectView(effect: effect)
        return view
    }()
    
    lazy var redView: UIView = {
        let view = UIView()
        view.isHidden = true
        view.backgroundColor = "FF5653".color
        return view
    }()
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView(image: "hx_editor_photo_trash_close".image)
        imageView.size = imageView.image?.size ?? .zero
        return imageView
    }()
    
    lazy var textLb: UILabel = {
        let textLb = UILabel()
        textLb.text = "拖动到此处删除".localized
        textLb.textColor = .white
        textLb.textAlignment = .center
        textLb.font = UIFont.systemFont(ofSize: 14)
        textLb.adjustsFontSizeToFitWidth = true
        return textLb
    }()
    
    var inArea: Bool = false {
        didSet {
            bgView.isHidden = inArea
            redView.isHidden = !inArea
            imageView.image = inArea ? "hx_editor_photo_trash_open".image : "hx_editor_photo_trash_close".image
            imageView.size = imageView.image?.size ?? .zero
            imageView.centerX = width * 0.5
            textLb.text = inArea ? "松手即可删除".localized : "拖动到此处删除".localized
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(bgView)
        addSubview(redView)
        addSubview(imageView)
        addSubview(textLb)
        layer.cornerRadius = 10
        layer.masksToBounds = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        bgView.frame = bounds
        redView.frame = bounds
        imageView.y = height * 0.5 - imageView.height
        imageView.centerX = width * 0.5
        
        textLb.y = height * 0.5 + 8
        textLb.x = 5
        textLb.width = width - 10
        textLb.height = 15
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
