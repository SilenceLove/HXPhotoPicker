//
//  ImageViewConfig.swift
//  HXPhotoPickerExample
//
//  Created by Silence on 2025/2/21.
//  Copyright © 2025 Silence. All rights reserved.
//


import Foundation

public protocol ImageViewConfig {
    var imageViewClass: HXImageViewProtocol.Type { get set }
    static var imageViewClass: HXImageViewProtocol.Type { get set }
}

public extension ImageViewConfig {
    var imageViewClass: HXImageViewProtocol.Type {
        get { PhotoManager.ImageView }
        set { PhotoManager.ImageView = newValue }
    }
    static var imageViewClass: HXImageViewProtocol.Type {
        get { PhotoManager.ImageView }
        set { PhotoManager.ImageView = newValue }
    }
}
