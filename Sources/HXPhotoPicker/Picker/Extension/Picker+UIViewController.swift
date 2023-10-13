//
//  Picker+UIViewController.swift
//  照片选择器-Swift
//
//  Created by Silence on 2020/11/11.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

extension UIViewController: HXPickerCompatible {
    
}

public extension HXPickerWrapper where Base: UIViewController {
    
    @available(iOS 13.0, *)
    func picker<T: PhotoAssetObject>(
        _ config: PickerConfiguration,
        delegate: PhotoPickerControllerDelegate? = nil,
        compression: PhotoAsset.Compression? = nil,
        toFile fileConfig: PickerResult.FileConfigHandler? = nil
    ) async throws -> [T] {
        try await PhotoPickerController.picker(
            config,
            delegate: delegate,
            compression: compression,
            fromVC: base,
            toFile: fileConfig
        )
    }
    
    @available(iOS 13.0, *)
    func picker(
        _ config: PickerConfiguration,
        delegate: PhotoPickerControllerDelegate? = nil,
        fromVC: UIViewController? = nil
    ) async throws -> PickerResult {
        try await PhotoPickerController.picker(config, delegate: delegate, fromVC: base)
    }
    
    @discardableResult
    func present(
        picker config: PickerConfiguration,
        selectedAssets: [PhotoAsset] = [],
        delegate: PhotoPickerControllerDelegate? = nil,
        finish: PhotoPickerController.FinishHandler? = nil,
        cancel: PhotoPickerController.CancelHandler? = nil
    ) -> PhotoPickerController {
        let pickerController = PhotoPickerController(
            picker: config,
            delegate: delegate
        )
        pickerController.selectedAssetArray = selectedAssets
        pickerController.finishHandler = finish
        pickerController.cancelHandler = cancel
        base.present(
            pickerController,
            animated: true
        )
        return pickerController
    }
    
    @discardableResult
    func present(
        preview assets: [PhotoAsset],
        pageIndex: Int = 0,
        config: PickerConfiguration,
        modalPresentationStyle: UIModalPresentationStyle = .fullScreen,
        delegate: PhotoPickerControllerDelegate? = nil
    ) -> PhotoPickerController {
        let previewController = PhotoPickerController(
            preview: config,
            previewAssets: assets,
            currentIndex: pageIndex,
            modalPresentationStyle: modalPresentationStyle,
            delegate: delegate
        )
        base.present(
            previewController,
            animated: true
        )
        return previewController
    }
}
