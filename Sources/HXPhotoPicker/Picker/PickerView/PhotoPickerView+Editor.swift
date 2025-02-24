//
//  PhotoPickerView+Editor.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/9/17.
//

import UIKit

#if HXPICKER_ENABLE_EDITOR && HXPICKER_ENABLE_PICKER
extension PhotoPickerView: EditorViewControllerDelegate {
    public func editorViewController(
        _ editorViewController: EditorViewController,
        didFinish asset: EditorAsset
    ) {
        guard let photoAsset = asset.type.photoAsset else {
            return
        }
        photoAsset.editedResult = asset.result
        if asset.result != nil {
            if (photoAsset.mediaType == .video && videoLoadSingleCell) || !isMultipleSelect {
                if manager.canSelectAsset(for: photoAsset, showHUD: true) {
                    manager.addedPhotoAsset(photoAsset: photoAsset)
                    finishSelectionAsset([photoAsset])
                }
                return
            }
            if !photoAsset.isSelected {
                let cell = getCell(for: photoAsset)
                cell?.photoAsset = photoAsset
                if manager.addedPhotoAsset(photoAsset: photoAsset) {
                    updateCellSelectedTitle()
                }
            }else {
                reloadCell(for: photoAsset)
            }
        }else {
            if (photoAsset.mediaType == .video && videoLoadSingleCell) || !isMultipleSelect {
                if manager.canSelectAsset(for: photoAsset, showHUD: true) {
                    manager.addedPhotoAsset(photoAsset: photoAsset)
                    finishSelectionAsset([photoAsset])
                }
                return
            }
            let cell = getCell(for: photoAsset)
            cell?.photoAsset = photoAsset
            if !photoAsset.isSelected {
                if manager.addedPhotoAsset(photoAsset: photoAsset) {
                    updateCellSelectedTitle()
                }
            }
        }
    }
    
    public func editorViewController(
        _ editorViewController: EditorViewController,
        loadTitleChartlet response: @escaping EditorTitleChartletResponse
    ) {
        guard let delegate = delegate else {
            let titles = PhotoTools.defaultTitleChartlet()
            response(titles)
            return
        }
        delegate.photoPickerView(
            self,
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
        guard let delegate = delegate else {
            let chartletList = PhotoTools.defaultNetworkChartlet()
            response(titleIndex, chartletList)
            return
        }
        delegate.photoPickerView(
            self,
            loadChartletList: editorViewController,
            titleChartlet: titleChartlet,
            titleIndex: titleIndex,
            response: response
        )
    }
    
    public func editorViewController(shouldClickMusicTool editorViewController: EditorViewController) -> Bool {
        if let shouldClick = delegate?.photoPickerView(
            self,
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
        guard let delegate = delegate else {
            completionHandler(PhotoTools.defaultMusicInfos())
            return false
        }
        return delegate.photoPickerView(
            self,
            videoEditor: editorViewController,
            loadMusic: completionHandler
        )
    }
    
    public func editorViewController(
        _ editorViewController: EditorViewController,
        didSearchMusic text: String?,
        completionHandler: @escaping ([VideoEditorMusicInfo], Bool) -> Void
    ) {
        guard let delegate = delegate else {
            completionHandler([], false)
            return
        }
        delegate.photoPickerView(
            self,
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
        guard let delegate = delegate else {
            completionHandler([], false)
            return
        }
        delegate.photoPickerView(
            self,
            videoEditor: editorViewController,
            loadMore: text,
            completionHandler: completionHandler
        )
    }
}
#endif
