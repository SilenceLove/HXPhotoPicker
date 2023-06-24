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
        removeAllEditedPhotoAsset()
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
        if isExternalPickerPreview {
            disablesCustomDismiss = true
        }
        if autoDismiss {
            dismiss(animated: true, completion: nil)
        }
    }
    func singleFinishCallback(for photoAsset: PhotoAsset) {
        #if HXPICKER_ENABLE_EDITOR
        removeAllEditedPhotoAsset()
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
        if isExternalPickerPreview {
            disablesCustomDismiss = true
        }
        if autoDismiss {
            dismiss(true)
        }
    }
    func cancelCallback() {
        #if HXPICKER_ENABLE_EDITOR
        editedPhotoAssetArray.forEach {
            $0.editedResult = $0.initialEditedResult
        }
        editedPhotoAssetArray.removeAll()
        #endif
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
    
    /// 获取已选资源的总大小
    /// - Parameters:
    ///   - isPreview: 是否是预览界面获取
    ///   - completion: 完成回调
    func requestSelectedAssetFileSize(
        isPreview: Bool,
        completion: @escaping (Int, String) -> Void
    ) {
        cancelRequestAssetFileSize(isPreview: isPreview)
        let operation = BlockOperation()
        operation.addExecutionBlock { [unowned operation] in
            var totalFileSize = 0
            for photoAsset in self.selectedAssetArray {
                if operation.isCancelled { return }
                if let fileSize = photoAsset.getPFileSize() {
                    totalFileSize += fileSize
                    continue
                }
                totalFileSize += photoAsset.fileSize
            }
            if operation.isCancelled { return }
            DispatchQueue.main.async {
                completion(
                    totalFileSize,
                    totalFileSize.bytesString
                )
            }
        }
        if isPreview {
            previewRequestAssetBytesQueue.addOperation(operation)
        }else {
            requestAssetBytesQueue.addOperation(operation)
        }
    }
    
    /// 取消获取资源文件大小
    /// - Parameter isPreview: 是否预览界面
    func cancelRequestAssetFileSize(isPreview: Bool) {
        if isPreview {
            previewRequestAssetBytesQueue.cancelAllOperations()
        }else {
            requestAssetBytesQueue.cancelAllOperations()
        }
    }
    
    /// 更新相册资源
    /// - Parameters:
    ///   - coverImage: 封面图片
    ///   - count: 需要累加的数量
    func updateAlbums(coverImage: UIImage?, count: Int) {
        for assetCollection in assetCollectionsArray {
            if assetCollection.realCoverImage != nil {
                assetCollection.realCoverImage = coverImage
            }
            assetCollection.count += count
        }
        reloadAlbumData()
    }
    
    /// 添加根据本地资源生成的PhotoAsset对象
    /// - Parameter photoAsset: 对应的PhotoAsset对象
    func addedLocalCameraAsset(photoAsset: PhotoAsset) {
        photoAsset.localIndex = localCameraAssetArray.count
        localCameraAssetArray.append(photoAsset)
    }
    
    /// 添加PhotoAsset对象到已选数组
    /// - Parameter photoAsset: 对应的PhotoAsset对象
    /// - Returns: 添加结果
    @discardableResult
    func addedPhotoAsset(
        photoAsset: PhotoAsset,
        filterEditor: Bool = false
    ) -> Bool {
        if singleVideo && photoAsset.mediaType == .video {
            return false
        }
        if config.selectMode == .single {
            // 单选模式不可添加
            return false
        }
        if selectedAssetArray.contains(photoAsset) {
            photoAsset.isSelected = true
            return true
        }
        let canSelect = canSelectAsset(
            for: photoAsset,
            showHUD: true,
            filterEditor: filterEditor
        )
        if canSelect {
            pickerDelegate?.pickerController(
                self,
                willSelectAsset: photoAsset,
                atIndex: selectedAssetArray.count
            )
            canAddAsset = false
            photoAsset.isSelected = true
            photoAsset.selectIndex = selectedAssetArray.count
            if photoAsset.mediaType == .photo {
                selectedPhotoAssetArray.append(photoAsset)
            }else if photoAsset.mediaType == .video {
                selectedVideoAssetArray.append(photoAsset)
            }
            canAddAsset = false
            selectedAssetArray.append(photoAsset)
            pickerDelegate?.pickerController(
                self,
                didSelectAsset: photoAsset,
                atIndex: selectedAssetArray.count - 1
            )
        }
        return canSelect
    }
    
    /// 移除已选的PhotoAsset对象
    /// - Parameter photoAsset: 对应PhotoAsset对象
    /// - Returns: 移除结果
    @discardableResult
    func removePhotoAsset(photoAsset: PhotoAsset) -> Bool {
        if selectedAssetArray.isEmpty || !selectedAssetArray.contains(photoAsset) {
            return false
        }
        canAddAsset = false
        pickerDelegate?.pickerController(
            self,
            willUnselectAsset: photoAsset,
            atIndex: selectedAssetArray.count
        )
        photoAsset.isSelected = false
        if photoAsset.mediaType == .photo {
            selectedPhotoAssetArray.remove(
                at: selectedPhotoAssetArray.firstIndex(of: photoAsset)!
            )
        }else if photoAsset.mediaType == .video {
            selectedVideoAssetArray.remove(
                at: selectedVideoAssetArray.firstIndex(of: photoAsset)!
            )
        }
        canAddAsset = false
        selectedAssetArray.remove(at: selectedAssetArray.firstIndex(of: photoAsset)!)
        for (index, asset) in selectedAssetArray.enumerated() {
            asset.selectIndex = index
        }
        pickerDelegate?.pickerController(
            self,
            didUnselectAsset: photoAsset,
            atIndex: selectedAssetArray.count
        )
        return true
    }
    
    func movePhotoAsset(fromIndex: Int, toIndex: Int) {
        canAddAsset = false
        let fromAsset = selectedAssetArray[fromIndex]
        selectedAssetArray.remove(at: fromIndex)
        canAddAsset = false
        selectedAssetArray.insert(fromAsset, at: toIndex)
        for (index, asset) in selectedAssetArray.enumerated() {
            asset.selectIndex = index
        }
    }
    
    private func canSelectPhoto(_ photoAsset: PhotoAsset) -> (Bool, String?) {
        var canSelect = true
        var text: String?
        if photoAsset.mediaType == .photo {
            if config.maximumSelectedPhotoFileSize > 0 {
                if photoAsset.fileSize > config.maximumSelectedPhotoFileSize {
                    text = "照片大小超过最大限制".localized + config.maximumSelectedPhotoFileSize.bytesString
                    canSelect = false
                }
            }
            if !config.allowSelectedTogether {
                if selectedVideoAssetArray.count > 0 {
                    text = "照片和视频不能同时选择".localized
                    canSelect = false
                }
            }
            if config.maximumSelectedPhotoCount > 0 {
                if selectedPhotoAssetArray.count >= config.maximumSelectedPhotoCount {
                    text = String.init(format: "最多只能选择%d张照片".localized, arguments: [config.maximumSelectedPhotoCount])
                    canSelect = false
                }
            }else {
                if selectedAssetArray.count >= config.maximumSelectedCount && config.maximumSelectedCount > 0 {
                    text = String.init(format: "已达到最大选择数".localized, arguments: [config.maximumSelectedPhotoCount])
                    canSelect = false
                }
            }
        }
        return (canSelect, text)
    }
    
    private func canSelectVideo(
        _ photoAsset: PhotoAsset,
        filterEditor: Bool
    ) -> (Bool, String?) {
        var canSelect = true
        var text: String?
        if photoAsset.mediaType == .video {
            if config.maximumSelectedVideoFileSize > 0 {
                if photoAsset.fileSize > config.maximumSelectedVideoFileSize {
                    text = "视频大小超过最大限制".localized + config.maximumSelectedVideoFileSize.bytesString
                    canSelect = false
                }
            }
            if config.maximumSelectedVideoDuration > 0 {
                if round(photoAsset.videoDuration) > Double(config.maximumSelectedVideoDuration) {
                    #if HXPICKER_ENABLE_EDITOR
                    if !config.editorOptions.contains(.video) || filterEditor {
                        text = String(
                            format: "视频最大时长为%d秒，无法选择".localized,
                            arguments: [config.maximumSelectedVideoDuration]
                        )
                        canSelect = false
                    }else {
                        if config.maximumVideoEditDuration > 0 &&
                            round(photoAsset.videoDuration) > Double(config.maximumVideoEditDuration) {
                            text = String(
                                format: "视频可编辑最大时长为%d秒，无法编辑".localized,
                                arguments: [config.maximumVideoEditDuration]
                            )
                            canSelect = false
                        }
                    }
                    #else
                    text = String(
                        format: "视频最大时长为%d秒，无法选择".localized,
                        arguments: [config.maximumSelectedVideoDuration]
                    )
                    canSelect = false
                    #endif
                }
            }
            if config.minimumSelectedVideoDuration > 0 {
                if round(photoAsset.videoDuration) < Double(config.minimumSelectedVideoDuration) {
                    text = String(
                        format: "视频最小时长为%d秒，无法选择".localized,
                        arguments: [config.minimumSelectedVideoDuration]
                    )
                    canSelect = false
                }
            }
            if !config.allowSelectedTogether {
                if selectedPhotoAssetArray.count > 0 {
                    text = "视频和照片不能同时选择".localized
                    canSelect = false
                }
            }
            if config.maximumSelectedVideoCount > 0 {
                if selectedVideoAssetArray.count >= config.maximumSelectedVideoCount {
                    text = String.init(format: "最多只能选择%d个视频".localized, arguments: [config.maximumSelectedVideoCount])
                    canSelect = false
                }
            }else {
                if selectedAssetArray.count >= config.maximumSelectedCount && config.maximumSelectedCount > 0 {
                    text = String.init(format: "已达到最大选择数".localized, arguments: [config.maximumSelectedPhotoCount])
                    canSelect = false
                }
            }
        }
        return (canSelect, text)
    }
    
    /// 是否能够选择Asset
    /// - Parameters:
    ///   - photoAsset: 对应的PhotoAsset
    ///   - showHUD: 是否显示HUD
    /// - Returns: 结果
    func canSelectAsset(
        for photoAsset: PhotoAsset,
        showHUD: Bool,
        filterEditor: Bool = false
    ) -> Bool {
        var canSelect = true
        var text: String?
        if photoAsset.mediaType == .photo {
            let result = canSelectPhoto(photoAsset)
            canSelect = result.0
            text = result.1
        }else if photoAsset.mediaType == .video {
            let result = canSelectVideo(photoAsset, filterEditor: filterEditor)
            canSelect = result.0
            text = result.1
        }
        if let shouldSelect = pickerDelegate?.pickerController(
            self,
            shouldSelectedAsset: photoAsset,
            atIndex: selectedAssetArray.count
        ) {
            if canSelect {
                canSelect = shouldSelect
            }
        }
        if let text = text, !canSelect, showHUD {
            DispatchQueue.main.async {
                ProgressHUD.showWarning(addedTo: self.view, text: text, animated: true, delayHide: 1.5)
            }
        }
        return canSelect
    }
    
    /// 视频时长是否超过最大限制
    /// - Parameter photoAsset: 对应的PhotoAsset对象
    func videoDurationExceedsTheLimit(photoAsset: PhotoAsset) -> Bool {
        photoAsset.mediaType == .video &&
           config.maximumSelectedVideoDuration > 0 &&
           round(photoAsset.videoDuration) > Double(config.maximumSelectedVideoDuration)
    }
    
    /// 选择数是否达到最大
    func selectArrayIsFull() -> Bool {
        selectedAssetArray.count >= config.maximumSelectedCount && config.maximumSelectedCount > 0
    }
    
    #if HXPICKER_ENABLE_EDITOR
    func addedEditedPhotoAsset(_ photoAsset: PhotoAsset) {
        if editedPhotoAssetArray.contains(photoAsset) {
            return
        }
        editedPhotoAssetArray.append(photoAsset)
    }
    func removeAllEditedPhotoAsset() {
        if editedPhotoAssetArray.isEmpty {
            return
        }
        for photoAsset in editedPhotoAssetArray {
            photoAsset.initialEditedResult = nil
        }
        editedPhotoAssetArray.removeAll()
    }
    #endif
}
