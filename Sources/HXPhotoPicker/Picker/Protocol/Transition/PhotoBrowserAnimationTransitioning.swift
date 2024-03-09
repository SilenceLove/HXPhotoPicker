//
//  PhotoBrowserBrowserAnimationTransitioning.swift
//  HXPhotoPicker
//
//  Created by Silence on 2024/2/24.
//  Copyright © 2024 Silence. All rights reserved.
//

import UIKit

public enum PhotoBrowserAnimationTransitionType {
    case present
    case dismiss
}

public protocol PhotoBrowserAnimationTransitioning: UIViewControllerAnimatedTransitioning {
    init(type: PhotoBrowserAnimationTransitionType)
}

