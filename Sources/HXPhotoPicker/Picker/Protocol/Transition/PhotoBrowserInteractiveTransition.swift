//
//  PhotoBrowserInteractiveTransition.swift
//  HXPhotoPicker
//
//  Created by Silence on 2024/2/25.
//  Copyright © 2024 Silence. All rights reserved.
//

import UIKit

open class PhotoBrowserInteractiveTransition: UIPercentDrivenInteractiveTransition {
    public weak var pickerController: PhotoPickerController?
    /// 是否可以手势返回
    public var canInteration: Bool = false
    
    public required init(pickerController: PhotoPickerController) {
        self.pickerController = pickerController
        super.init()
    }
}
