//
//  PhotoPickerController+Internal.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/8/25.
//

import UIKit
import AVFoundation
import Photos

// MARK: ViewControllers function
extension PhotoPickerController {
    func finishCallback() {
        #if HXPICKER_ENABLE_EDITOR
        pickerData.removeAllEditedPhotoAsset()
        #endif
        let result = PickerResult(
            photoAssets: selectedAssetArray,
            isOriginal: isOriginal
        )
        finishHandler?(result, self)
        pickerDelegate?.pickerController(
            self,
            didFinishSelection: result
        )
        if previewType == .picker {
            disablesCustomDismiss = true
        }
        isDismissed = true
        if autoDismiss {
            dismiss(true)
        }
    }
    func singleFinishCallback(for photoAsset: PhotoAsset) {
        #if HXPICKER_ENABLE_EDITOR
        pickerData.removeAllEditedPhotoAsset()
        #endif
        let result = PickerResult(
            photoAssets: [photoAsset],
            isOriginal: isOriginal
        )
        finishHandler?(result, self)
        pickerDelegate?.pickerController(
            self,
            didFinishSelection: result
        )
        if previewType == .picker {
            disablesCustomDismiss = true
        }
        isDismissed = true
        if autoDismiss {
            dismiss(true)
        }
    }
    func cancelCallback() {
        #if HXPICKER_ENABLE_EDITOR
        pickerData.resetEditedAssets()
        #endif
        isDismissed = true
        cancelHandler?(self)
        pickerDelegate?.pickerController(didCancel: self)
        if autoDismiss {
            dismiss(animated: true, completion: nil)
        }else {
            if pickerDelegate == nil && cancelHandler == nil {
                dismiss(animated: true, completion: nil)
            }
        }
    }
    func originalButtonCallback() {
        pickerDelegate?.pickerController(
            self,
            didOriginalButton: isOriginal
        )
    }
    func shouldPresentCamera() -> Bool {
        if let shouldPresent = pickerDelegate?.pickerController(
            shouldPresentCamera: self
        ) {
            return shouldPresent
        }
        return true
    }
    func previewUpdateCurrentlyDisplayedAsset(
        photoAsset: PhotoAsset,
        index: Int
    ) {
        pickerDelegate?.pickerController(
            self,
            previewUpdateCurrentlyDisplayedAsset: photoAsset,
            atIndex: index
        )
    }
    func shouldClickCell(
        photoAsset: PhotoAsset,
        index: Int
    ) -> Bool {
        if let shouldClick = pickerDelegate?.pickerController(
            self,
            shouldClickCell: photoAsset,
            atIndex: index
        ) {
            return shouldClick
        }
        return true
    }
    func cellTapAction(
        photoAsset: PhotoAsset,
        index: Int
    ) -> SelectionTapAction? {
        pickerDelegate?.pickerController(
            self,
            cellTapAction: photoAsset,
            at: index
        )
    }
    func shouldEditAsset(
        photoAsset: PhotoAsset,
        atIndex: Int
    ) -> Bool {
        if let shouldEditAsset = pickerDelegate?.pickerController(
            self,
            shouldEditAsset: photoAsset,
            atIndex: atIndex
        ) {
            return shouldEditAsset
        }
        return true
    }
    
    #if HXPICKER_ENABLE_EDITOR
    func shouldEditPhotoAsset(
        photoAsset: PhotoAsset,
        editorConfig: EditorConfiguration,
        atIndex: Int
    ) -> EditorConfiguration? {
        if let config = pickerDelegate?.pickerController(
            self,
            shouldEditPhotoAsset: photoAsset,
            editorConfig: editorConfig,
            atIndex: atIndex
        ) {
            return config
        }
        return editorConfig
    }
    func shouldEditVideoAsset(
        videoAsset: PhotoAsset,
        editorConfig: EditorConfiguration,
        atIndex: Int
    ) -> EditorConfiguration? {
        if let config = pickerDelegate?.pickerController(
            self,
            shouldEditVideoAsset: videoAsset,
            editorConfig: editorConfig,
            atIndex: atIndex
        ) {
            return config
        }
        return editorConfig
    }
    #endif
    
    func didEditAsset(
        photoAsset: PhotoAsset,
        atIndex: Int
    ) {
        pickerDelegate?.pickerController(
            self,
            didEditAsset: photoAsset,
            atIndex: atIndex
        )
    }
    func previewShouldDeleteAsset(
        photoAsset: PhotoAsset,
        index: Int
    ) -> Bool {
        if let previewShouldDeleteAsset = pickerDelegate?.pickerController(
            self,
            previewShouldDeleteAsset: photoAsset,
            atIndex: index
        ) {
            return previewShouldDeleteAsset
        }
        return true
    }
    func viewControllersWillAppear(_ viewController: UIViewController) {
        pickerDelegate?.pickerController(
            self,
            viewControllersWillAppear: viewController
        )
    }
    func viewControllersDidAppear(_ viewController: UIViewController) {
        pickerDelegate?.pickerController(
            self,
            viewControllersDidAppear: viewController
        )
    }
    func viewControllersWillDisappear(_ viewController: UIViewController) {
        pickerDelegate?.pickerController(
            self,
            viewControllersWillDisappear: viewController
        )
    }
    func viewControllersDidDisappear(_ viewController: UIViewController) {
        pickerDelegate?.pickerController(
            self,
            viewControllersDidDisappear: viewController
        )
    }
    
    func updateAlbums(coverImage: UIImage?, count: Int) {
        fetchData.updateAlbums(coverImage: coverImage, count: count)
        reloadAlbumData()
    }
    
}

extension PhotoPickerController: PhotoControllerEvent {
    public func photoControllerDidCancel() {
        cancelCallback()
    }
    
    public func photoControllerDidFinish() {
        finishCallback()
    }
}
