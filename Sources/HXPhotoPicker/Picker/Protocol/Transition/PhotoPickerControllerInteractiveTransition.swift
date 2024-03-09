//
//  PhotoPickerControllerInteractiveTransition.swift
//  HXPhotoPicker
//
//  Created by Silence on 2024/2/24.
//  Copyright © 2024 Silence. All rights reserved.
//

import UIKit

open class PhotoPickerControllerInteractiveTransition: UIPercentDrivenInteractiveTransition {
    
    public let type: InteractiveTransitionType
    public weak var pickerController: PhotoPickerController?
    /// 手势触发范围
    public let triggerRange: CGFloat
    /// 是否可以手势返回
    public var canInteration: Bool = false
    /// 返回手势
    open var gestureRecognizer: UIGestureRecognizer? { nil }
    
    public required init(
        type: InteractiveTransitionType,
        pickerController: PhotoPickerController,
        triggerRange: CGFloat
    ) {
        self.type = type
        self.pickerController = pickerController
        self.triggerRange = triggerRange
        super.init()
    }
    
    public enum InteractiveTransitionType {
        case pop
        case dismiss
    }
}
