//
//  GIFImageView.swift
//  HXPhotoPickerExample
//
//  Created by Silence on 2025/2/26.
//  Copyright © 2025 Silence. All rights reserved.
//

#if canImport(SwiftyGif) && HXPICKER_ENABLE_CORE
import UIKit
import SwiftyGif

public class GIFImageView: UIImageView, HXImageViewProtocol {
    
    public func setImageData(_ imageData: Data?) {
        guard let imageData else {
            clear()
            SwiftyGifManager.defaultManager.deleteImageView(self)
            image = nil
            return
        }
        if let image = try? UIImage(gifData: imageData) {
            setGifImage(image)
        }else {
            image = .init(data: imageData)
        }
    }
    
    public func _startAnimating() {
        startAnimatingGif()
    }
    
    public func _stopAnimating() {
        stopAnimatingGif()
    }
}
#endif
