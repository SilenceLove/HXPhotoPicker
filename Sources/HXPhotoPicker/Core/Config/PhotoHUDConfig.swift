//
//  PhotoHUDConfig.swift
//  HXPhotoPicker
//
//  Created by Silence on 2024/4/3.
//  Copyright © 2024 Silence. All rights reserved.
//

import Foundation

public protocol PhotoHUDConfig {
    var hudView: PhotoHUDProtocol.Type { get set }
}

public extension PhotoHUDConfig {
    var hudView: PhotoHUDProtocol.Type {
        get { PhotoManager.HUDView }
        set { PhotoManager.HUDView = newValue }
    }
}
