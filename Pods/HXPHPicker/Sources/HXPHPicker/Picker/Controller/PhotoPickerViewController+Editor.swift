//
//  PhotoPickerViewController+Editor.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/4.
//

import UIKit

#if HXPICKER_ENABLE_EDITOR && HXPICKER_ENABLE_PICKER
// MARK: PhotoEditorViewControllerDelegate
extension PhotoPickerViewController: PhotoEditorViewControllerDelegate {
    public func photoEditorViewController(
        _ photoEditorViewController: PhotoEditorViewController,
        didFinish result: PhotoEditResult
    ) {
        guard let picker = pickerController else { return }
        let photoAsset = photoEditorViewController.photoAsset!
        photoAsset.photoEdit = result
        picker.didEditAsset(photoAsset: photoAsset, atIndex: assets.firstIndex(of: photoAsset) ?? 0)
        if !isMultipleSelect {
            if picker.canSelectAsset(for: photoAsset, showHUD: true) {
                picker.singleFinishCallback(for: photoAsset)
            }
            return
        }
        if !photoAsset.isSelected {
            let cell = getCell(for: photoAsset)
            cell?.photoAsset = photoAsset
            if picker.addedPhotoAsset(photoAsset: photoAsset) {
                updateCellSelectedTitle()
            }
        }else {
            reloadCell(for: photoAsset)
        }
        bottomView.updateFinishButtonTitle()
    }
    public func photoEditorViewController(
        didFinishWithUnedited photoEditorViewController: PhotoEditorViewController
    ) {
        guard let picker = pickerController else { return }
        let photoAsset = photoEditorViewController.photoAsset!
        let beforeHasEdit = photoAsset.photoEdit != nil
        photoAsset.photoEdit = nil
        if beforeHasEdit {
            picker.didEditAsset(photoAsset: photoAsset, atIndex: assets.firstIndex(of: photoAsset) ?? 0)
        }
        if !isMultipleSelect {
            if picker.canSelectAsset(for: photoAsset, showHUD: true) {
                picker.singleFinishCallback(for: photoAsset)
            }
            return
        }
        let cell = getCell(for: photoAsset)
        cell?.photoAsset = photoAsset
        if !photoAsset.isSelected {
            if picker.addedPhotoAsset(photoAsset: photoAsset) {
                updateCellSelectedTitle()
            }
            bottomView.updateFinishButtonTitle()
        }
    }
    public func photoEditorViewController(
        _ photoEditorViewController: PhotoEditorViewController,
        loadTitleChartlet response: @escaping ([EditorChartlet]) -> Void) {
        guard let pickerController = pickerController,
              let pickerDelegate = pickerController.pickerDelegate else {
            #if canImport(Kingfisher)
            let titles = PhotoTools.defaultTitleChartlet()
            response(titles)
            #else
            response([])
            #endif
            return
        }
        pickerDelegate.pickerController(
            pickerController,
            loadTitleChartlet: photoEditorViewController,
            response: response
        )
    }
    public func photoEditorViewController(
        _ photoEditorViewController: PhotoEditorViewController,
        titleChartlet: EditorChartlet,
        titleIndex: Int,
        loadChartletList response: @escaping (Int, [EditorChartlet]) -> Void) {
        guard let pickerController = pickerController,
              let pickerDelegate = pickerController.pickerDelegate else {
            #if canImport(Kingfisher)
            let chartletList = PhotoTools.defaultNetworkChartlet()
            response(titleIndex, chartletList)
            #else
            response(titleIndex, [])
            #endif
            return
        }
        pickerDelegate.pickerController(
            pickerController,
            loadChartletList: photoEditorViewController,
            titleChartlet: titleChartlet,
            titleIndex: titleIndex,
            response: response
        )
    }
    public func photoEditorViewController(didCancel photoEditorViewController: PhotoEditorViewController) {
        
    }
    
    public func photoEditorViewController(
        transitionPreviewImage photoEditorViewController: PhotoEditorViewController
    ) -> UIImage? {
        guard let photoAsset = photoEditorViewController.photoAsset else {
            return nil
        }
        return getCell(for: photoAsset)?.photoView.image
    }
    
    public func photoEditorViewController(
        transitioBegenPreviewView photoEditorViewController: PhotoEditorViewController
    ) -> UIView? {
        guard let photoAsset = photoEditorViewController.photoAsset else {
            return nil
        }
        return getCell(for: photoAsset)
    }
    
    public func photoEditorViewController(
        transitioEndPreviewView photoEditorViewController: PhotoEditorViewController
    ) -> UIView? {
        guard let photoAsset = photoEditorViewController.photoAsset else {
            return nil
        }
        return getCell(for: photoAsset)
    }
}
// MARK: VideoEditorViewControllerDelegate
extension PhotoPickerViewController: VideoEditorViewControllerDelegate {
    public func videoEditorViewController(
        _ videoEditorViewController: VideoEditorViewController,
        loadTitleChartlet response: @escaping EditorTitleChartletResponse) {
        guard let pickerController = pickerController,
              let pickerDelegate = pickerController.pickerDelegate else {
            #if canImport(Kingfisher)
            let titles = PhotoTools.defaultTitleChartlet()
            response(titles)
            #else
            response([])
            #endif
            return
        }
        pickerDelegate.pickerController(
            pickerController,
            loadTitleChartlet: videoEditorViewController,
            response: response
        )
    }
    public func videoEditorViewController(
        _ videoEditorViewController: VideoEditorViewController,
        titleChartlet: EditorChartlet,
        titleIndex: Int,
        loadChartletList response: @escaping EditorChartletListResponse) {
        guard let pickerController = pickerController,
              let pickerDelegate = pickerController.pickerDelegate else {
            #if canImport(Kingfisher)
            let chartletList = PhotoTools.defaultNetworkChartlet()
            response(titleIndex, chartletList)
            #else
            response(titleIndex, [])
            #endif
            return
        }
        pickerDelegate.pickerController(
            pickerController,
            loadChartletList: videoEditorViewController,
            titleChartlet: titleChartlet,
            titleIndex: titleIndex,
            response: response
        )
    }
    public func videoEditorViewController(
        shouldClickMusicTool videoEditorViewController: VideoEditorViewController
    ) -> Bool {
        if let pickerController = pickerController,
           let shouldClick = pickerController.pickerDelegate?.pickerController(
            pickerController,
            videoEditorShouldClickMusicTool: videoEditorViewController
           ) {
            return shouldClick
        }
        return true
    }
    public func videoEditorViewController(
        _ videoEditorViewController: VideoEditorViewController,
        loadMusic completionHandler: @escaping ([VideoEditorMusicInfo]) -> Void
    ) -> Bool {
        guard let pickerController = pickerController,
              let pickerDelegate = pickerController.pickerDelegate else {
            completionHandler(PhotoTools.defaultMusicInfos())
            return false
        }
        return pickerDelegate.pickerController(
            pickerController,
            videoEditor: videoEditorViewController,
            loadMusic: completionHandler
        )
    }
    public func videoEditorViewController(
        _ videoEditorViewController: VideoEditorViewController,
        didSearch text: String?,
        completionHandler: @escaping ([VideoEditorMusicInfo], Bool) -> Void
    ) {
        guard let pickerController = pickerController,
              let pickerDelegate = pickerController.pickerDelegate else {
            completionHandler([], false)
            return
        }
        pickerDelegate.pickerController(
            pickerController,
            videoEditor: videoEditorViewController,
            didSearch: text,
            completionHandler: completionHandler
        )
    }
    public func videoEditorViewController(
        _ videoEditorViewController: VideoEditorViewController,
        loadMore text: String?,
        completionHandler: @escaping ([VideoEditorMusicInfo], Bool) -> Void
    ) {
        guard let pickerController = pickerController,
              let pickerDelegate = pickerController.pickerDelegate else {
            completionHandler([], false)
            return
        }
        pickerDelegate.pickerController(
            pickerController,
            videoEditor: videoEditorViewController,
            loadMore: text,
            completionHandler: completionHandler
        )
    }
    public func videoEditorViewController(
        _ videoEditorViewController: VideoEditorViewController,
        didFinish result: VideoEditResult
    ) {
        guard let picker = pickerController else { return }
        let photoAsset = videoEditorViewController.photoAsset!
        photoAsset.videoEdit = result
        picker.didEditAsset(
            photoAsset: photoAsset,
            atIndex: assets.firstIndex(of: photoAsset) ?? 0
        )
        if (photoAsset.mediaType == .video && videoLoadSingleCell) || !isMultipleSelect {
            if picker.canSelectAsset(for: photoAsset, showHUD: true) {
                picker.singleFinishCallback(for: photoAsset)
            }
            return
        }
        if !photoAsset.isSelected {
            let cell = getCell(for: photoAsset)
            cell?.photoAsset = photoAsset
            if picker.addedPhotoAsset(photoAsset: photoAsset) {
                updateCellSelectedTitle()
            }
        }else {
            reloadCell(for: photoAsset)
        }
        bottomView.updateFinishButtonTitle()
    }
    public func videoEditorViewController(
        didCancel videoEditorViewController: VideoEditorViewController
    ) {
        
    }
    public func videoEditorViewController(
        didFinishWithUnedited videoEditorViewController: VideoEditorViewController
    ) {
        guard let picker = pickerController else { return }
        let photoAsset = videoEditorViewController.photoAsset!
        let beforeHasEdit = photoAsset.videoEdit != nil
        photoAsset.videoEdit = nil
        if beforeHasEdit {
            picker.didEditAsset(
                photoAsset: photoAsset,
                atIndex: assets.firstIndex(of: photoAsset) ?? 0
            )
        }
        if (photoAsset.mediaType == .video && videoLoadSingleCell) || !isMultipleSelect {
            if picker.canSelectAsset(for: photoAsset, showHUD: true) {
                picker.singleFinishCallback(for: photoAsset)
            }
            return
        }
        if beforeHasEdit {
            let cell = getCell(for: photoAsset)
            cell?.photoAsset = photoAsset
        }
        if !photoAsset.isSelected {
            if picker.addedPhotoAsset(photoAsset: photoAsset) {
                updateCellSelectedTitle()
            }
            bottomView.updateFinishButtonTitle()
        }
    }
    
    public func videoEditorViewController(
        transitionPreviewImage videoEditorViewController: VideoEditorViewController
    ) -> UIImage? {
        guard let photoAsset = videoEditorViewController.photoAsset else {
            return nil
        }
        return getCell(for: photoAsset)?.photoView.image
    }
    
    public func videoEditorViewController(
        transitioBegenPreviewView videoEditorViewController: VideoEditorViewController
    ) -> UIView? {
        guard let photoAsset = videoEditorViewController.photoAsset else {
            return nil
        }
        return getCell(for: photoAsset)
    }
    
    public func videoEditorViewController(
        transitioEndPreviewView videoEditorViewController: VideoEditorViewController
    ) -> UIView? {
        guard let photoAsset = videoEditorViewController.photoAsset else {
            return nil
        }
        return getCell(for: photoAsset)
    }
}
#endif
