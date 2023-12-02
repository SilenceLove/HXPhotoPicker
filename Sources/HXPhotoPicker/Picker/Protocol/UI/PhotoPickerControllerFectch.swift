//
//  PhotoPickerControllerFectch.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/10/11.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit

public protocol PhotoPickerControllerViewFectch: UIView {
    var pickerController: PhotoPickerController { get }
}
public extension PhotoPickerControllerViewFectch {
    var pickerController: PhotoPickerController {
        if !Thread.isMainThread {
            assertionFailure()
        }
        guard let controller = viewController?.navigationController as? PhotoPickerController else {
            return .init()
        }
        return controller
    }
}

public protocol PhotoPickerControllerFectch: UIViewController {
    var pickerController: PhotoPickerController { get }
}
public extension PhotoPickerControllerFectch {
    var pickerController: PhotoPickerController {
        if !Thread.isMainThread {
            assertionFailure()
        }
        guard let controller = navigationController as? PhotoPickerController else {
            return .init()
        }
        return controller
    }
}
