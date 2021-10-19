//
//  ImageView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/18.
//

import UIKit

#if canImport(Kingfisher)
import Kingfisher
#endif

final class ImageView: UIView {
    lazy var imageView: UIImageView = {
        var imageView: UIImageView
        #if canImport(Kingfisher)
        imageView = AnimatedImageView.init()
        #else
        imageView = GIFImageView.init()
        #endif
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    var image: UIImage? {
        get {
            my.image
        }
        set {
            setImage(newValue, animated: false)
        }
    }
    
    #if canImport(Kingfisher)
    var my: AnimatedImageView {
        imageView as! AnimatedImageView
    }
    #else
    var my: GIFImageView {
        imageView as! GIFImageView
    }
    #endif
    
    init() {
        super.init(frame: .zero)
        addSubview(imageView)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
    }
    
    func setImage(_ image: UIImage?, animated: Bool) {
        if let image = image {
            my.image = image
            if animated {
                let transition = CATransition()
                transition.type = .fade
                transition.duration = 0.2
                transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                my.layer.add(transition, forKey: nil)
            }
        }
    }
    
    func setImage(_ img: UIImage) {
        #if canImport(Kingfisher)
        let image = DefaultImageProcessor.default.process(item: .image(img), options: .init([]))
        my.image = image
        #else
        my.image = img
        #endif
    }
    
    func setImageData(_ imageData: Data) {
        #if canImport(Kingfisher)
        let image = DefaultImageProcessor.default.process(item: .data(imageData), options: .init([]))
        my.image = image
        #else
        let image = GIFImage.init(data: imageData)
        my.gifImage = image
        #endif
    }
    
    func startAnimatedImage() {
        #if canImport(Kingfisher)
        my.startAnimating()
        #else
        my.setupDisplayLink()
        #endif
    }
    
    func stopAnimatedImage() {
        #if canImport(Kingfisher)
        my.stopAnimating()
        #else
        my.displayLink?.invalidate()
        my.gifImage = nil
        #endif
    }
}
