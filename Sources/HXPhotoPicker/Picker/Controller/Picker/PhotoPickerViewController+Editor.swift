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
        guard let photoAsset = asset.type.photoAsset else { return }
        let atIndex: Int
        if let index = listView.assets.firstIndex(of: photoAsset) {
            atIndex = index
        }else {
            atIndex = 0
        }
        if let result = asset.result {
            photoAsset.editedResult = result
            pickerController.didEditAsset(photoAsset: photoAsset, atIndex: atIndex)
            if (photoAsset.mediaType == .video && pickerConfig.isSingleVideo) || !pickerConfig.isMultipleSelect {
                if pickerController.pickerData.canSelect(photoAsset, isShowHUD: true) {
                    pickerController.singleFinishCallback(for: photoAsset)
                }
                return
            }
            if !photoAsset.isSelected {
                let cell = listView.getCell(for: photoAsset)
                cell?.updatePhotoAsset(photoAsset)
                if pickerController.pickerData.append(photoAsset) {
                    listView.updateCellSelectedTitle()
                    if isShowToolbar {
                        photoToolbar.insertSelectedAsset(photoAsset)
                        updateToolbarFrame()
                    }
                }
            }else {
                if pickerController.pickerData.canSelect(photoAsset, isShowHUD: true) {
                    listView.reloadCell(for: photoAsset)
                }else {
                    deselectedAsset(photoAsset)
                }
            }
            photoToolbar.selectedAssetDidChanged(pickerController.selectedAssetArray)
            finishItem?.selectedAssetDidChanged(pickerController.selectedAssetArray)
            requestSelectedAssetFileSize()
        }else {
            let beforeHasEdit = photoAsset.editedResult != nil
            photoAsset.editedResult = nil
            if beforeHasEdit {
                pickerController.didEditAsset(photoAsset: photoAsset, atIndex: atIndex)
            }
            if (photoAsset.mediaType == .video && pickerConfig.isSingleVideo) || !pickerConfig.isMultipleSelect {
                if pickerController.pickerData.canSelect(photoAsset, isShowHUD: true) {
                    pickerController.singleFinishCallback(for: photoAsset)
                }
                return
            }
            let cell = listView.getCell(for: photoAsset)
            cell?.updatePhotoAsset(photoAsset)
            if !photoAsset.isSelected {
                if pickerController.pickerData.append(photoAsset) {
                    listView.updateCellSelectedTitle()
                    if isShowToolbar {
                        photoToolbar.insertSelectedAsset(photoAsset)
                        updateToolbarFrame()
                    }
                }
                photoToolbar.selectedAssetDidChanged(pickerController.selectedAssetArray)
                finishItem?.selectedAssetDidChanged(pickerController.selectedAssetArray)
                requestSelectedAssetFileSize()
            }else {
                if !pickerController.pickerData.canSelect(photoAsset, isShowHUD: true) {
                    deselectedAsset(photoAsset)
                }
            }
            if listView.filterOptions.contains(.edited) {
                listView.reloadData()
            }
        }
        if isShowToolbar {
            photoToolbar.reloadSelectedAsset(photoAsset)
        }
    }
    
    public func editorViewController(
        _ editorViewController: EditorViewController,
        loadTitleChartlet response: @escaping EditorTitleChartletResponse
    ) {
        guard let pickerDelegate = pickerController.pickerDelegate else {
            let titles = PhotoTools.defaultTitleChartlet()
            response(titles)
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
        guard let pickerDelegate = pickerController.pickerDelegate else {
            let chartletList = PhotoTools.defaultNetworkChartlet()
            response(titleIndex, chartletList)
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
        if let shouldClick = pickerController.pickerDelegate?.pickerController(
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
        guard let pickerDelegate = pickerController.pickerDelegate else {
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
        guard let pickerDelegate = pickerController.pickerDelegate else {
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
        guard let pickerDelegate = pickerController.pickerDelegate else {
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
        return listView.getCell(for: photoAsset)?.photoView.image
    }
    
    public func editorViewController(transitioStartPreviewView editorViewController: EditorViewController) -> UIView? {
        guard let photoAsset = editorViewController.selectedAsset.type.photoAsset else {
            return nil
        }
        return listView.getCell(for: photoAsset)
    }
    
    public func editorViewController(transitioEndPreviewView editorViewController: EditorViewController) -> UIView? {
        guard let photoAsset = editorViewController.selectedAsset.type.photoAsset else {
            return nil
        }
        return listView.getCell(for: photoAsset)
    }
}
#endif
