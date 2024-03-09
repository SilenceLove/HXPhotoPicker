//
//  PickerAnimationTransitioning.swift
//  HXPhotoPicker
//
//  Created by Silence on 2024/2/24.
//  Copyright © 2024 Silence. All rights reserved.
//

import UIKit

public enum PhotoPickerControllerTransitionType {
    case push
    case pop
    case dismiss
}

public protocol PhotoPickerControllerAnimationTransitioning: UIViewControllerAnimatedTransitioning {
    init(type: PhotoPickerControllerTransitionType)
}


