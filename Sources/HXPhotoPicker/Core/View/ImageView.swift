//
//  ImageView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/8/18.
//

import UIKit

#if canImport(Kingfisher)
import Kingfisher
typealias HXImageView = AnimatedImageView
#else
typealias HXImageView = GIFImageView
#endif

final class ImageView: HXImageView {
    
    #if canImport(Kingfisher)
    init() {
        super.init(frame: .zero)
        contentMode = .scaleAspectFill
        clipsToBounds = true
    }
    #else
    override init() {
        super.init(frame: .zero)
        contentMode = .scaleAspectFill
        clipsToBounds = true
    }
    #endif
    
    func setImage(_ image: UIImage?, animated: Bool) {
        if let image = image {
            self.image = image
            if animated {
                let transition: CATransition = .init()
                transition.type = .fade
                transition.duration = 0.2
                transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                layer.add(transition, forKey: nil)
            }
        }
    }
    
    func setImageData(_ imageData: Data?) {
        #if canImport(Kingfisher)
        guard let imageData = imageData else {
            image = nil
            return
        }
        let image: KFCrossPlatformImage? = DefaultImageProcessor.default.process(item: .data(imageData), options: .init([]))
        self.image = image
        #else
        guard let imageData = imageData else {
            gifImage = nil
            return
        }
        let image: GIFImage? = .init(data: imageData)
        gifImage = image
        #endif
    }
    
    func startAnimatedImage() {
        #if canImport(Kingfisher)
        startAnimating()
        #else
        setupDisplayLink()
        #endif
    }
    
    func stopAnimatedImage() {
        #if canImport(Kingfisher)
        stopAnimating()
        #else
        displayLink?.invalidate()
        gifImage = nil
        #endif
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
