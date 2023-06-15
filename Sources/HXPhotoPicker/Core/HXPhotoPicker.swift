//
//  HXPhotoPicker.swift
//  PhotoPicker-Swift
//
//  Created by Silence on 2020/11/9.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

class HXPhotoPicker {}

#if HXPICKER_ENABLE_PICKER || HXPICKER_ENABLE_CAMERA || HXPICKER_ENABLE_EDITOR
public enum Photo {
    
    #if HXPICKER_ENABLE_PICKER
    @discardableResult
    public static func picker(
        _ config: PickerConfiguration,
        selectedAssets: [PhotoAsset] = [],
        sender: UIViewController? = nil,
        delegate: PhotoPickerControllerDelegate? = nil,
        finish: PhotoPickerController.FinishHandler? = nil,
        cancel: PhotoPickerController.CancelHandler? = nil
    ) -> PhotoPickerController {
        let controller = PhotoPickerController(
            picker: config,
            delegate: delegate
        )
        controller.selectedAssetArray = selectedAssets
        controller.finishHandler = finish
        controller.cancelHandler = cancel
        (sender ?? UIViewController.topViewController)?.present(
            controller,
            animated: true
        )
        return controller
    }
    #endif
    
    #if HXPICKER_ENABLE_EDITOR
    @discardableResult
    public static func edit(
        asset: EditorAsset,
        config: EditorConfiguration,
        sender: UIViewController? = nil,
        finished: EditorViewController.FinishHandler? = nil,
        cancelled: EditorViewController.CancelHandler? = nil
    ) -> EditorViewController {
        let vc = EditorViewController(
            asset,
            config: config,
            finish: finished,
            cancel: cancelled
        )
        (sender ?? UIViewController.topViewController)?.present(
            vc,
            animated: true
        )
        return vc
    }
    #endif
    
    #if HXPICKER_ENABLE_CAMERA
    @discardableResult
    public static func capture(
        _ config: CameraConfiguration,
        type: CameraController.CaptureType = .all,
        sender: UIViewController? = nil,
        completion: @escaping CameraController.CaptureCompletion
    ) -> CameraController {
        CameraController.capture(
            config: config,
            type: type,
            fromVC: sender,
            completion: completion
        )
    }
    #endif
    
}
#endif

public struct HXPickerWrapper<Base> {
    public let base: Base
    public init(_ base: Base) {
        self.base = base
    }
}
public protocol HXPickerCompatible: AnyObject { }
public protocol HXPickerCompatibleValue {}
extension HXPickerCompatible {
    public var hx: HXPickerWrapper<Self> {
        get { return HXPickerWrapper(self) }
        set { } // swiftlint:disable:this unused_setter_value
    }
}
extension HXPickerCompatibleValue {
    public var hx: HXPickerWrapper<Self> {
        get { return HXPickerWrapper(self) }
        set { } // swiftlint:disable:this unused_setter_value
    }
}
