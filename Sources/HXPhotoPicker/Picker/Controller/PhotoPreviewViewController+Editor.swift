//
//  PhotoPreviewViewController+Editor.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/8/6.
//

import UIKit

#if HXPICKER_ENABLE_EDITOR && HXPICKER_ENABLE_PICKER

extension PhotoPreviewViewController: EditorViewControllerDelegate {
    public func editorViewController(_ editorViewController: EditorViewController, didFinish asset: EditorAsset) {
        guard let picker = pickerController else { return }
        guard let photoAsset = asset.type.photoAsset else {
            return
        }
        PhotoManager.shared.appearanceStyle = picker.config.appearanceStyle
        if let result = asset.result {
            photoAsset.editedResult = result
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
                reloadCell(for: currentPreviewIndex)
                if !photoAsset.isSelected {
                    didSelectBoxControlClick()
                }
            }
            picker.didEditAsset(photoAsset: photoAsset, atIndex: currentPreviewIndex)
        }else {
            let beforeHasEdit = photoAsset.editedResult != nil
            photoAsset.editedResult = nil
            if beforeHasEdit {
                picker.didEditAsset(photoAsset: photoAsset, atIndex: currentPreviewIndex)
            }
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
            if !photoAsset.isSelected {
                didSelectBoxControlClick()
            }
            if beforeHasEdit {
                reloadCell(for: currentPreviewIndex)
            }
        }
        delegate?.previewViewController(self, editAssetFinished: photoAsset)
    }
    
    public func editorViewController(didCancel editorViewController: EditorViewController) {
        guard let picker = pickerController else { return }
        PhotoManager.shared.appearanceStyle = picker.config.appearanceStyle
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
    
    public func editorViewController(_ editorViewController: EditorViewController, loadMoreMusic text: String?, completionHandler: @escaping ([VideoEditorMusicInfo], Bool) -> Void) {
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
        getCell(for: currentPreviewIndex)?.scrollContentView.imageView.image
    }
    
    public func editorViewController(_ editorViewController: EditorViewController, transitionDuration mode: EditorTransitionMode) -> TimeInterval {
        0.35
    }
    
    public func editorViewController(transitioStartPreviewView editorViewController: EditorViewController) -> UIView? {
        getCell(for: currentPreviewIndex)?.scrollContentView
    }
    
    public func editorViewController(transitioEndPreviewView editorViewController: EditorViewController) -> UIView? {
        getCell(for: currentPreviewIndex)?.scrollContentView
    }
}
#endif
