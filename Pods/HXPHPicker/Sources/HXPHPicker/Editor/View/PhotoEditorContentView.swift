//
//  PhotoEditorContentView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/3/26.
//

import UIKit
#if canImport(Kingfisher)
import Kingfisher
#endif

protocol PhotoEditorContentViewDelegate: AnyObject {
    
}

class PhotoEditorContentView: UIView {
    
    lazy var imageView: UIImageView = {
        var imageView: UIImageView
        #if canImport(Kingfisher)
        imageView = AnimatedImageView.init()
        #else
        imageView = UIImageView.init()
        #endif
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    var image: UIImage? {
        get {
            imageView.image
        }
    }
    
    init() {
        super.init(frame: .zero)
        addSubview(imageView)
    }
    
    
    func setImage(_ image: UIImage) {
        #if canImport(Kingfisher)
        let view = imageView as! AnimatedImageView
        view.image = image
        #else
        imageView.image = image
        #endif
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
