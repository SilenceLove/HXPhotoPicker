//
//  EditorStickersTrashView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/7/22.
//

import UIKit

class EditorStickersTrashView: UIView {
    private var bgView: UIVisualEffectView!
    private var redView: UIView! 
    private var imageView: UIImageView!
    private var textLb: UILabel!
    
    var inArea: Bool = false {
        didSet {
            bgView.isHidden = inArea
            redView.isHidden = !inArea
            imageView.image = inArea ? .imageResource.editor.sticker.trashOpen.image : .imageResource.editor.sticker.trashClose.image
            imageView.size = imageView.image?.size ?? .zero
            imageView.centerX = width * 0.5
            textLb.text = inArea ? .textManager.editor.sticker.trashOpenTitle.text : .textManager.editor.sticker.trashCloseTitle.text
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        initViews()
        addSubview(bgView)
        addSubview(redView)
        addSubview(imageView)
        addSubview(textLb)
        layer.cornerRadius = 10
        layer.masksToBounds = true
    }
    
    private func initViews() {
        let effect = UIBlurEffect(style: .dark)
        bgView = UIVisualEffectView(effect: effect)
        
        redView = UIView()
        redView.isHidden = true
        redView.backgroundColor = "FF5653".color
        
        imageView = UIImageView(image: .imageResource.editor.sticker.trashClose.image)
        imageView.size = imageView.image?.size ?? .zero
        
        textLb = UILabel()
        textLb.text = .textManager.editor.sticker.trashCloseTitle.text
        textLb.textColor = .white
        textLb.textAlignment = .center
        textLb.font = UIFont.systemFont(ofSize: 14)
        textLb.adjustsFontSizeToFitWidth = true
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
