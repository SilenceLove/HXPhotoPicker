//
//  PhotoPickerViewController+Editor.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/8/4.
//

import UIKit

#if HXPICKER_ENABLE_EDITOR && HXPICKER_ENABLE_PICKER
extension PhotoPickerViewController: EditorViewControllerDelegate {
    public func editorViewController(_ editorViewController: EditorViewController, didFinish asset: EditorAsset) {
        guard let picker = pickerController else { return }
        guard let photoAsset = asset.type.photoAsset else {
            return
        }
        if let result = asset.result {
            photoAsset.editedResult = result
            picker.didEditAsset(photoAsset: photoAsset, atIndex: assets.firstIndex(of: photoAsset) ?? 0)
            if (photoAsset.mediaType == .video && videoLoadSingleCell) || !isMultipleSelect {
                if picker.canSelectAsset(for: photoAsset, showHUD: true) {
                    picker.singleFinishCallback(for: photoAsset)
                }
                return
            }
            if !photoAsset.isSelected {
                let cell = getCell(for: photoAsset)
                cell?.isRequestDirectly = true
                cell?.photoAsset = photoAsset
                if picker.addedPhotoAsset(photoAsset: photoAsset) {
                    updateCellSelectedTitle()
                }
            }else {
                reloadCell(for: photoAsset)
            }
            bottomView.updateFinishButtonTitle()
        }else {
            let beforeHasEdit = photoAsset.editedResult != nil
            photoAsset.editedResult = nil
            if beforeHasEdit {
                picker.didEditAsset(photoAsset: photoAsset, atIndex: assets.firstIndex(of: photoAsset) ?? 0)
            }
            if (photoAsset.mediaType == .video && videoLoadSingleCell) || !isMultipleSelect {
                if picker.canSelectAsset(for: photoAsset, showHUD: true) {
                    picker.singleFinishCallback(for: photoAsset)
                }
                return
            }
            let cell = getCell(for: photoAsset)
            cell?.isRequestDirectly = true
            cell?.photoAsset = photoAsset
            if !photoAsset.isSelected {
                if picker.addedPhotoAsset(photoAsset: photoAsset) {
                    updateCellSelectedTitle()
                }
                bottomView.updateFinishButtonTitle()
            }
        }
    }
    
    public func editorViewController(
        _ editorViewController: EditorViewController,
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
            loadTitleChartlet: editorViewController,
            response: response
        )
    }
    
    public func editorViewController(
        _ editorViewController: EditorViewController,
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
            loadChartletList: editorViewController,
            titleChartlet: titleChartlet,
            titleIndex: titleIndex,
            response: response
        )
    }
    
    public func editorViewController(shouldClickMusicTool editorViewController: EditorViewController) -> Bool {
        if let pickerController = pickerController,
           let shouldClick = pickerController.pickerDelegate?.pickerController(
            pickerController,
            videoEditorShouldClickMusicTool: editorViewController
           ) {
            return shouldClick
        }
        return true
    }
    
    public func editorViewController(
        _ editorViewController: EditorViewController,
        loadMusic completionHandler: @escaping ([VideoEditorMusicInfo]) -> Void
    ) -> Bool {
        guard let pickerController = pickerController,
              let pickerDelegate = pickerController.pickerDelegate else {
            completionHandler(PhotoTools.defaultMusicInfos())
            return false
        }
        return pickerDelegate.pickerController(
            pickerController,
            videoEditor: editorViewController,
            loadMusic: completionHandler
        )
    }
    
    public func editorViewController(
        _ editorViewController: EditorViewController,
        didSearchMusic text: String?,
        completionHandler: @escaping ([VideoEditorMusicInfo], Bool) -> Void
    ) {
        guard let pickerController = pickerController,
              let pickerDelegate = pickerController.pickerDelegate else {
            completionHandler([], false)
            return
        }
        pickerDelegate.pickerController(
            pickerController,
            videoEditor: editorViewController,
            didSearch: text,
            completionHandler: completionHandler
        )
    }
    
    public func editorViewController(
        _ editorViewController: EditorViewController,
        loadMoreMusic text: String?,
        completionHandler: @escaping ([VideoEditorMusicInfo], Bool) -> Void
    ) {
        guard let pickerController = pickerController,
              let pickerDelegate = pickerController.pickerDelegate else {
            completionHandler([], false)
            return
        }
        pickerDelegate.pickerController(
            pickerController,
            videoEditor: editorViewController,
            loadMore: text,
            completionHandler: completionHandler
        )
    }
    
    public func editorViewController(transitionPreviewImage editorViewController: EditorViewController) -> UIImage? {
        guard let photoAsset = editorViewController.selectedAsset.type.photoAsset else {
            return nil
        }
        return getCell(for: photoAsset)?.photoView.image
    }
    
    public func editorViewController(transitioStartPreviewView editorViewController: EditorViewController) -> UIView? {
        guard let photoAsset = editorViewController.selectedAsset.type.photoAsset else {
            return nil
        }
        return getCell(for: photoAsset)
    }
    
    public func editorViewController(transitioEndPreviewView editorViewController: EditorViewController) -> UIView? {
        guard let photoAsset = editorViewController.selectedAsset.type.photoAsset else {
            return nil
        }
        return getCell(for: photoAsset)
    }
}
#endif
