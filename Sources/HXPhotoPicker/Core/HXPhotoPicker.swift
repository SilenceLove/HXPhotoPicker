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
    
    @available(iOS 13.0, *)
    @MainActor
    public static func picker<T: PhotoAssetObject>(
        _ config: PickerConfiguration,
        selectedAssets: [PhotoAsset] = [],
        delegate: PhotoPickerControllerDelegate? = nil,
        compression: PhotoAsset.Compression? = nil,
        fromVC: UIViewController? = nil,
        toFile fileConfig: PickerResult.FileConfigHandler? = nil
    ) async throws -> [T] {
        try await PhotoPickerController.picker(
            config,
            selectedAssets: selectedAssets,
            delegate: delegate,
            compression: compression,
            fromVC: fromVC,
            toFile: fileConfig
        )
    }
    
    @available(iOS 13.0, *)
    @MainActor
    public static func picker(
        _ config: PickerConfiguration,
        selectedAssets: [PhotoAsset] = [],
        delegate: PhotoPickerControllerDelegate? = nil,
        fromVC: UIViewController? = nil
    ) async throws -> PickerResult {
        try await PhotoPickerController.picker(
            config,
            selectedAssets: selectedAssets,
            delegate: delegate,
            fromVC: fromVC
        )
    }
    
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
        var presentVC: UIViewController?
        if let sender = sender {
            presentVC = sender
        }else {
            presentVC = UIViewController.topViewController
        }
        presentVC?.present(
            controller,
            animated: true
        )
        return controller
    }
    #endif
    
    #if HXPICKER_ENABLE_EDITOR
    
    @available(iOS 13.0, *)
    @discardableResult
    @MainActor
    public static func edit(
        _ asset: EditorAsset,
        config: EditorConfiguration = .init(),
        delegate: EditorViewControllerDelegate? = nil,
        fromVC: UIViewController? = nil
    ) async throws -> EditorAsset {
        try await EditorViewController.edit(asset, config: config, delegate: delegate, fromVC: fromVC)
    }
    
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
        var presentVC: UIViewController?
        if let sender = sender {
            presentVC = sender
        }else {
            presentVC = UIViewController.topViewController
        }
        presentVC?.present(
            vc,
            animated: true
        )
        return vc
    }
    #endif
    
    #if HXPICKER_ENABLE_CAMERA && !targetEnvironment(macCatalyst)
    
    @available(iOS 13.0, *)
    @MainActor
    public static func capture(
        _ config: CameraConfiguration = .init(),
        type: CameraController.CaptureType = .all,
        delegate: CameraControllerDelegate? = nil,
        fromVC: UIViewController? = nil
    ) async throws -> CameraController.CaptureResult {
        try await CameraController.capture(config, type: type, delegate: delegate, fromVC: fromVC)
    }
    
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

public enum HX {
    
    #if HXPICKER_ENABLE_PICKER
    @available(iOS 13.0, *)
    @MainActor
    public static func picker<T: PhotoAssetObject>(
        _ config: PickerConfiguration,
        selectedAssets: [PhotoAsset] = [],
        delegate: PhotoPickerControllerDelegate? = nil,
        compression: PhotoAsset.Compression? = nil,
        fromVC: UIViewController? = nil,
        toFile fileConfig: PickerResult.FileConfigHandler? = nil
    ) async throws -> [T] {
        try await Photo.picker(
            config,
            selectedAssets: selectedAssets,
            delegate: delegate,
            compression: compression,
            fromVC: fromVC,
            toFile: fileConfig
        )
    }
    
    @available(iOS 13.0, *)
    @MainActor
    public static func picker(
        _ config: PickerConfiguration,
        selectedAssets: [PhotoAsset] = [],
        delegate: PhotoPickerControllerDelegate? = nil,
        fromVC: UIViewController? = nil
    ) async throws -> PickerResult {
        try await Photo.picker(
            config,
            selectedAssets: selectedAssets,
            delegate: delegate,
            fromVC: fromVC
        )
    }
    #endif
    
    #if HXPICKER_ENABLE_EDITOR
    @available(iOS 13.0, *)
    @discardableResult
    @MainActor
    public static func edit(
        _ asset: EditorAsset,
        config: EditorConfiguration = .init(),
        delegate: EditorViewControllerDelegate? = nil,
        fromVC: UIViewController? = nil
    ) async throws -> EditorAsset {
        try await Photo.edit(asset, config: config, delegate: delegate, fromVC: fromVC)
    }
    #endif
    
    #if HXPICKER_ENABLE_CAMERA
    @available(iOS 13.0, *)
    @MainActor
    public static func capture(
        _ config: CameraConfiguration = .init(),
        type: CameraController.CaptureType = .all,
        delegate: CameraControllerDelegate? = nil,
        fromVC: UIViewController? = nil
    ) async throws -> CameraController.CaptureResult {
        try await Photo.capture(config, type: type, delegate: delegate, fromVC: fromVC)
    }
    #endif
    
    public enum ImageTargetMode {
        /// 与原图宽高比一致，高度会根据`targetSize`计算
        case fill
        /// 根据`targetSize`拉伸/缩放
        case fit
        /// 如果`targetSize`的比例与原图不一样则居中显示
        case center
    }
}

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
