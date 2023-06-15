//
//  Picker+UIViewController.swift
//  照片选择器-Swift
//
//  Created by Silence on 2020/11/11.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

extension UIViewController {
    var pickerController: PhotoPickerController? {
        if self.navigationController is PhotoPickerController {
            return self.navigationController as? PhotoPickerController
        }
        return nil
    }
}
public extension HXPickerWrapper where Base: UIViewController {
    
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
