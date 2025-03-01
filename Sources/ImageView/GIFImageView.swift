//
//  GIFImageView.swift
//  HXPhotoPickerExample
//
//  Created by Silence on 2025/2/26.
//  Copyright © 2025 Silence. All rights reserved.
//

#if canImport(Gifu)
import UIKit
import Gifu

public class GIFImageView: UIImageView, HXImageViewProtocol, GIFAnimatable {
    public lazy var animator: Animator? = {
        return Animator(withDelegate: self)
    }()

    override public func display(_ layer: CALayer) {
        super.display(layer)
        updateImageIfNeeded()
    }
    
    public func setImageData(_ imageData: Data?) {
        guard let imageData else { return }
        animate(withGIFData: imageData)
    }
    
    public func _startAnimating() {
        startAnimatingGIF()
    }
    
    public func _stopAnimating() {
        stopAnimatingGIF()
    }
}
#endif
