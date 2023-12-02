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
        guard let photoAsset = asset.type.photoAsset else {
            return
        }
        PhotoManager.shared.appearanceStyle = pickerConfig.appearanceStyle
        if let result = asset.result {
            photoAsset.editedResult = result
            if previewType == .browser {
                replacePhotoAsset(at: currentPreviewIndex, with: photoAsset)
            }else {
                if (pickerConfig.isSingleVideo && photoAsset.mediaType == .video) || !pickerConfig.isMultipleSelect {
                    if pickerController.pickerData.canSelect(photoAsset, isShowHUD: true) {
                        if previewType == .picker {
                            delegate?.previewViewController(
                                self,
                                didSelectBox: photoAsset,
                                isSelected: true,
                                updateCell: false
                            )
                        }
                        delegate?.previewViewController(didFinishButton: self, photoAssets: [photoAsset])
                        pickerController.singleFinishCallback(for: photoAsset)
                    }
                    return
                }
                reloadCell(for: currentPreviewIndex)
                if isShowToolbar {
                    photoToolbar.previewListReload([photoAsset])
                }
                if !photoAsset.isSelected {
                    didSelectBoxControlClick()
                }
            }
            pickerController.didEditAsset(photoAsset: photoAsset, atIndex: currentPreviewIndex)
        }else {
            let beforeHasEdit = photoAsset.editedResult != nil
            photoAsset.editedResult = nil
            if beforeHasEdit {
                pickerController.didEditAsset(photoAsset: photoAsset, atIndex: currentPreviewIndex)
            }
            if (pickerConfig.isSingleVideo && photoAsset.mediaType == .video) || !pickerConfig.isMultipleSelect {
                if pickerController.pickerData.canSelect(photoAsset, isShowHUD: true) {
                    if previewType == .picker {
                        delegate?.previewViewController(
                            self,
                            didSelectBox: photoAsset,
                            isSelected: true,
                            updateCell: false
                        )
                    }
                    delegate?.previewViewController(didFinishButton: self, photoAssets: [photoAsset])
                    pickerController.singleFinishCallback(for: photoAsset)
                }
                return
            }
            if !photoAsset.isSelected {
                didSelectBoxControlClick()
            }
            if beforeHasEdit {
                reloadCell(for: currentPreviewIndex)
                if isShowToolbar {
                    photoToolbar.previewListReload([photoAsset])
                }
            }
        }
        delegate?.previewViewController(self, editAssetFinished: photoAsset)
    }
    
    public func editorViewController(didCancel editorViewController: EditorViewController) {
        PhotoManager.shared.appearanceStyle = pickerConfig.appearanceStyle
    }
    
    public func editorViewController(
        _ editorViewController: EditorViewController,
        loadTitleChartlet response: @escaping EditorTitleChartletResponse
    ) {
        guard let pickerDelegate = pickerController.pickerDelegate else {
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
        guard let pickerDelegate = pickerController.pickerDelegate else {
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
    
    public func editorViewController(
        transitionPreviewImage editorViewController: EditorViewController
    ) -> UIImage? {
        getCell(for: currentPreviewIndex)?.scrollContentView.imageView.image
    }
    
    public func editorViewController(
        _ editorViewController: EditorViewController,
        transitionDuration mode: EditorTransitionMode
    ) -> TimeInterval {
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
