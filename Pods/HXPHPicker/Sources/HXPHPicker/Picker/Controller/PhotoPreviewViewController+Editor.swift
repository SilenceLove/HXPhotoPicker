//
//  PhotoPreviewViewController+Editor.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/6.
//

import UIKit

#if HXPICKER_ENABLE_EDITOR && HXPICKER_ENABLE_PICKER
// MARK: PhotoEditorViewControllerDelegate
extension PhotoPreviewViewController: PhotoEditorViewControllerDelegate {
    public func photoEditorViewController(
        _ photoEditorViewController: PhotoEditorViewController,
        didFinish result: PhotoEditResult
    ) {
        guard let picker = pickerController else { return }
        let photoAsset = photoEditorViewController.photoAsset!
        photoAsset.photoEdit = result
        if isExternalPreview {
            replacePhotoAsset(at: currentPreviewIndex, with: photoAsset)
        }else {
            if (videoLoadSingleCell && photoAsset.mediaType == .video) || !isMultipleSelect {
                if picker.canSelectAsset(for: photoAsset, showHUD: true) {
                    if isExternalPickerPreview {
                        delegate?.previewViewController(
                            self,
                            didSelectBox: photoAsset,
                            isSelected: true,
                            updateCell: false
                        )
                    }
                    delegate?.previewViewController(didFinishButton: self)
                    picker.singleFinishCallback(for: photoAsset)
                }
                return
            }
            reloadCell(for: photoAsset)
            if !photoAsset.isSelected {
                didSelectBoxControlClick()
            }
        }
        delegate?.previewViewController(self, editAssetFinished: photoAsset)
        picker.didEditAsset(photoAsset: photoAsset, atIndex: currentPreviewIndex)
    }
    public func photoEditorViewController(
        didFinishWithUnedited photoEditorViewController: PhotoEditorViewController
    ) {
        guard let picker = pickerController else { return }
        let photoAsset = photoEditorViewController.photoAsset!
        let beforeHasEdit = photoAsset.photoEdit != nil
        photoAsset.photoEdit = nil
        if beforeHasEdit {
            picker.didEditAsset(photoAsset: photoAsset, atIndex: currentPreviewIndex)
        }
        if !isMultipleSelect {
            if picker.canSelectAsset(for: photoAsset, showHUD: true) {
                if isExternalPickerPreview {
                    delegate?.previewViewController(
                        self,
                        didSelectBox: photoAsset,
                        isSelected: true,
                        updateCell: false
                    )
                }
                delegate?.previewViewController(didFinishButton: self)
                picker.singleFinishCallback(for: photoAsset)
            }
            return
        }
        if !photoAsset.isSelected {
            didSelectBoxControlClick()
        }
        if beforeHasEdit {
            reloadCell(for: photoAsset)
        }
        delegate?.previewViewController(self, editAssetFinished: photoAsset)
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
        return getCell(for: photoAsset)?.scrollContentView.imageView.image
    }
    public func photoEditorViewController(
        _ photoEditorViewController: PhotoEditorViewController,
        transitionDuration mode: EditorTransitionMode
    ) -> TimeInterval {
        0.35
    }
    
    public func photoEditorViewController(
        transitioBegenPreviewView photoEditorViewController: PhotoEditorViewController
    ) -> UIView? {
        guard let photoAsset = photoEditorViewController.photoAsset else {
            return nil
        }
        return getCell(for: photoAsset)?.scrollContentView
    }
    
    public func photoEditorViewController(
        transitioEndPreviewView photoEditorViewController: PhotoEditorViewController
    ) -> UIView? {
        guard let photoAsset = photoEditorViewController.photoAsset else {
            return nil
        }
        return getCell(for: photoAsset)?.scrollContentView
    }
}
// MARK: VideoEditorViewControllerDelegate
extension PhotoPreviewViewController: VideoEditorViewControllerDelegate {
    public func videoEditorViewController(
        _ videoEditorViewController: VideoEditorViewController,
        loadTitleChartlet response: @escaping EditorTitleChartletResponse
    ) {
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
        loadChartletList response: @escaping EditorChartletListResponse
    ) {
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
        completionHandler: @escaping ([VideoEditorMusicInfo], Bool) -> Void) {
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
        guard let picker = pickerController,
              let photoAsset = videoEditorViewController.photoAsset else { return }
        photoAsset.videoEdit = result
        if isExternalPreview {
            replacePhotoAsset(at: currentPreviewIndex, with: photoAsset)
        }else {
            if videoLoadSingleCell || !isMultipleSelect {
                if picker.canSelectAsset(for: photoAsset, showHUD: true) {
                    if isExternalPickerPreview {
                        delegate?.previewViewController(
                            self,
                            didSelectBox: photoAsset,
                            isSelected: true,
                            updateCell: false
                        )
                    }
                    delegate?.previewViewController(didFinishButton: self)
                    picker.singleFinishCallback(for: photoAsset)
                }
                return
            }
            reloadCell(for: photoAsset)
            if !photoAsset.isSelected {
                didSelectBoxControlClick()
            }
        }
        delegate?.previewViewController(self, editAssetFinished: photoAsset)
        picker.didEditAsset(photoAsset: photoAsset, atIndex: currentPreviewIndex)
    }
    public func videoEditorViewController(
        didFinishWithUnedited videoEditorViewController: VideoEditorViewController
    ) {
        guard let picker = pickerController,
              let photoAsset = videoEditorViewController.photoAsset else { return }
        let beforeHasEdit = photoAsset.videoEdit != nil
        photoAsset.videoEdit = nil
        if beforeHasEdit {
            picker.didEditAsset(photoAsset: photoAsset, atIndex: currentPreviewIndex)
        }
        if videoLoadSingleCell || !isMultipleSelect {
            if picker.canSelectAsset(for: photoAsset, showHUD: true) {
                if isExternalPickerPreview {
                    delegate?.previewViewController(
                        self,
                        didSelectBox: photoAsset,
                        isSelected: true,
                        updateCell: false
                    )
                }
                delegate?.previewViewController(didFinishButton: self)
                picker.singleFinishCallback(for: photoAsset)
            }
            return
        }
        if beforeHasEdit {
            reloadCell(for: photoAsset)
        }
        if !photoAsset.isSelected {
            didSelectBoxControlClick()
        }
        delegate?.previewViewController(self, editAssetFinished: photoAsset)
    }
    public func videoEditorViewController(didCancel videoEditorViewController: VideoEditorViewController) {
        
    }
    public func videoEditorViewController(
        transitionPreviewImage videoEditorViewController: VideoEditorViewController
    ) -> UIImage? {
        guard let photoAsset = videoEditorViewController.photoAsset else {
            return nil
        }
        return getCell(for: photoAsset)?.scrollContentView.imageView.image
    }
    
    public func videoEditorViewController(
        _ videoEditorViewController: VideoEditorViewController,
        transitionDuration mode: EditorTransitionMode
    ) -> TimeInterval {
        0.35
    }
    
    public func videoEditorViewController(
        transitioBegenPreviewView videoEditorViewController: VideoEditorViewController
    ) -> UIView? {
        guard let photoAsset = videoEditorViewController.photoAsset else {
            return nil
        }
        return getCell(for: photoAsset)?.scrollContentView
    }
    
    public func videoEditorViewController(
        transitioEndPreviewView videoEditorViewController: VideoEditorViewController
    ) -> UIView? {
        guard let photoAsset = videoEditorViewController.photoAsset else {
            return nil
        }
        return getCell(for: photoAsset)?.scrollContentView
    }
}
#endif
