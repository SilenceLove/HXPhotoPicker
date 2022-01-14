//
//  HXPHPicker.swift
//  PhotoPicker-Swift
//
//  Created by Silence on 2020/11/9.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

class HXPHPicker {}

#if HXPICKER_ENABLE_PICKER || HXPICKER_ENABLE_CAMERA || HXPICKER_ENABLE_EDITOR
public enum Photo {
    
    #if HXPICKER_ENABLE_PICKER
    /// 照片选择器
    /// - Parameters:
    ///   - config: 配置
    ///   - selectedAssets: 当前选择的 PhotoAsset 对象数组
    ///   - sender: 跳转的控制器
    ///   - delegate: 代理
    ///   - finish: 完成
    ///   - cancel: 取消
    /// - Returns: 对应的 PhotoPickerController 对象
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
        photo image: UIImage,
        config: PhotoEditorConfiguration,
        editResult: PhotoEditResult? = nil,
        sender: UIViewController? = nil,
        finished: PhotoEditorViewController.FinishHandler? = nil,
        cancelled: PhotoEditorViewController.CancelHandler? = nil
    ) -> EditorController {
        let controller = EditorController(
            image: image,
            editResult: editResult,
            config: config,
            finished: finished,
            cancelled: cancelled
        )
        (sender ?? UIViewController.topViewController)?.present(
            controller,
            animated: true
        )
        return controller
    }
    
    @discardableResult
    public static func edit(
        video url: URL,
        config: VideoEditorConfiguration,
        editResult: VideoEditResult? = nil,
        sender: UIViewController? = nil,
        finished: VideoEditorViewController.FinishHandler? = nil,
        cancelled: VideoEditorViewController.CancelHandler? = nil
    ) -> EditorController {
        let controller = EditorController(
            videoURL: url,
            editResult: editResult,
            config: config,
            finished: finished,
            cancelled: cancelled
        )
        (sender ?? UIViewController.topViewController)?.present(
            controller,
            animated: true
        )
        return controller
    }
    #endif
    
    #if HXPICKER_ENABLE_PICKER && HXPICKER_ENABLE_EDITOR
    @discardableResult
    public static func edit(
        photo photoAsset: PhotoAsset,
        config: PhotoEditorConfiguration,
        editResult: PhotoEditResult? = nil,
        sender: UIViewController? = nil,
        finished: PhotoEditorViewController.FinishHandler? = nil,
        cancelled: PhotoEditorViewController.CancelHandler? = nil
    ) -> EditorController {
        let controller = EditorController(
            photoAsset: photoAsset,
            editResult: editResult,
            config: config,
            finished: finished,
            cancelled: cancelled
        )
        (sender ?? UIViewController.topViewController)?.present(
            controller,
            animated: true
        )
        return controller
    }
    
    @discardableResult
    public static func edit(
        video photoAsset: PhotoAsset,
        config: VideoEditorConfiguration,
        editResult: VideoEditResult? = nil,
        sender: UIViewController? = nil,
        finished: VideoEditorViewController.FinishHandler? = nil,
        cancelled: VideoEditorViewController.CancelHandler? = nil
    ) -> EditorController {
        let controller = EditorController(
            photoAsset: photoAsset,
            editResult: editResult,
            config: config,
            finished: finished,
            cancelled: cancelled
        )
        (sender ?? UIViewController.topViewController)?.present(
            controller,
            animated: true
        )
        return controller
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
