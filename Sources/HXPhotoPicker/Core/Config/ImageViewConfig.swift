//
//  ImageViewConfig.swift
//  HXPhotoPickerExample
//
//  Created by Silence on 2025/2/21.
//  Copyright © 2025 Silence. All rights reserved.
//


import Foundation

public protocol ImageViewConfig {
    var imageViewProtocol: HXImageViewProtocol.Type { get set }
    static var imageViewProtocol: HXImageViewProtocol.Type { get set }
}

public extension ImageViewConfig {
    var imageViewProtocol: HXImageViewProtocol.Type {
        get { PhotoManager.ImageView }
        set { PhotoManager.ImageView = newValue }
    }
    static var imageViewProtocol: HXImageViewProtocol.Type {
        get { PhotoManager.ImageView }
        set { PhotoManager.ImageView = newValue }
    }
}
