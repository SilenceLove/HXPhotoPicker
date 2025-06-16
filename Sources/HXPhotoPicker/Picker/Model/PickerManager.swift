//
//  PickerManager.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/9/17.
//

import UIKit
import Photos

public class PickerManager: NSObject {
    
    /// 配置
    public var config: PickerConfiguration = .init()
    
    /// fetch Assets 时的选项配置
    public var options: PHFetchOptions = .init()
    
    /// 默认0，不限制
    public var fetchLimit: Int = 0
    
    /// 当前被选择的资源对应的 PhotoAsset 对象数组
    public var selectedAssetArray: [PhotoAsset] = [] {
        didSet { setupSelectedArray() }
    }
    
    /// 本地资源数组
    /// 创建本地资源的PhotoAsset然后赋值即可添加到照片列表，如需选中也要添加到selectedAssetArray中
    public var localAssetArray: [PhotoAsset] = []
    
    /// 相机拍摄存在本地的资源数组（通过相机拍摄的但是没有保存到系统相册）
    /// 可以通过 pickerControllerDidDismiss 得到上一次相机拍摄的资源，然后赋值即可显示上一次相机拍摄的资源
    public var localCameraAssetArray: [PhotoAsset] = []
    
    fileprivate var selectOptions: PickerAssetOptions {
        config.selectOptions
    }
    fileprivate var singleVideo: Bool {
        if config.selectMode == .multiple &&
            !config.allowSelectedTogether &&
            config.maximumSelectedVideoCount == 1 &&
            config.selectOptions.isPhoto && config.selectOptions.isVideo &&
            config.photoList.cell.isHiddenSingleVideoSelect {
            return true
        }
        return false
    }
    
    fileprivate var cameraAssetCollection: PhotoAssetCollection?
    fileprivate var selectedPhotoAssetArray: [PhotoAsset] = []
    fileprivate var selectedVideoAssetArray: [PhotoAsset] = []
    fileprivate var canAddAsset: Bool = true
    fileprivate var requestAssetBytesQueue: OperationQueue!
    fileprivate var fetchAssetQueue: OperationQueue!
    
    var fetchAssetsCompletion: (([PhotoAsset], PhotoAsset?) -> Void)?
    var reloadAssetCollection: (() -> Void)?
    var willSelectAsset: ((PhotoAsset, Int) -> Void)?
    var didSelectAsset: ((PhotoAsset, Int) -> Void)?
    var willDeselectAsset: ((PhotoAsset, Int) -> Void)?
    var didDeselectAsset: ((PhotoAsset, Int) -> Void)?
    
    public override init() {
        super.init()
        requestAssetBytesQueue = OperationQueue()
        requestAssetBytesQueue.maxConcurrentOperationCount = 1
        
        fetchAssetQueue = OperationQueue()
        fetchAssetQueue.maxConcurrentOperationCount = 1
    }
    
    deinit {
        cancelFetchAssetQueue()
        cancelRequestAssetFileSize()
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
}

extension PickerManager {
    fileprivate func setupSelectedArray() {
        if config.selectMode == .single {
            return
        }
        if !canAddAsset {
            canAddAsset = true
            return
        }
        
        let array = selectedAssetArray
        for photoAsset in array {
            if photoAsset.mediaType == .photo {
                selectedPhotoAssetArray.append(photoAsset)
            }else if photoAsset.mediaType == .video {
                if singleVideo {
                    if let index = selectedAssetArray.firstIndex(of: photoAsset) {
                        canAddAsset = false
                        selectedAssetArray.remove(at: index)
                    }
                }else {
                    selectedVideoAssetArray.append(photoAsset)
                }
            }
        }
    }
    
    func requestAuthorization(
        with handler: @escaping (PHAuthorizationStatus) -> Void
    ) {
        AssetPermissionsUtil.requestAuthorization { status in
            if status != .denied {
                PHPhotoLibrary.shared().register(self)
            }
            handler(status)
        }
    }
    
    func reloadCameraAsset() {
        fetchPhotoAssets(assetCollection: cameraAssetCollection)
    }
    
    func fetchAssets(
        completion: (([PhotoAsset], PhotoAsset?) -> Void)?
    ) {
        fetchAssetsCompletion = completion
        fetchCameraAssetCollection { [weak self] assetCollection in
            guard let self = self else {
                completion?([], nil)
                return
            }
            self.fetchPhotoAssets(
                assetCollection: assetCollection
            )
        }
    }
    
    /// 获取相机胶卷资源集合
    func fetchCameraAssetCollection(
        completion: ((PhotoAssetCollection) -> Void)?
    ) {
        if !config.allowLoadPhotoLibrary {
            let collection: PhotoAssetCollection
            if let assetCollection = cameraAssetCollection {
                collection = assetCollection
            }else {
                collection = PhotoAssetCollection(
                    albumName: .textManager.picker.albumList.emptyAlbumName.text,
                    coverImage: config.emptyCoverImageName.image
                )
                cameraAssetCollection = collection
            }
            completion?(collection)
            return
        }
        if config.creationDate {
            options.sortDescriptors = [
                NSSortDescriptor(key: "creationDate", ascending: config.creationDate)
            ]
        }
        DispatchQueue.global().async {
            let fetchAssetCollection = self.config.fetchAssetCollection
            let assetCollection: PhotoAssetCollection
            if let collection = fetchAssetCollection.fetchCameraAssetCollection(self.config, options: self.options) {
                assetCollection = collection
            }else {
                assetCollection = PhotoAssetCollection(
                    albumName: .textManager.picker.albumList.emptyAlbumName.text,
                    coverImage: self.config.emptyCoverImageName.image
                )
            }
            self.cameraAssetCollection = assetCollection
            completion?(assetCollection)
        }
    }
    
    /// 获取相册里的资源
    /// - Parameters:
    ///   - assetCollection: 相册
    ///   - completion: 完成回调
    func fetchPhotoAssets(
        assetCollection: PhotoAssetCollection?
    ) {
        cancelFetchAssetQueue()
        let operation = BlockOperation()
        operation.addExecutionBlock { [unowned operation, weak self] in
            guard let self = self else { return }
            for photoAsset in self.localAssetArray {
                photoAsset.isSelected = false
            }
            for photoAsset in self.localCameraAssetArray {
                photoAsset.isSelected = false
            }
            let result = self.getSelectAsset()
            let selectedAssets = result.0
            let selectedPhotoAssets = result.1
            var localAssets: [PhotoAsset] = []
            if operation.isCancelled {
                return
            }
            localAssets.append(contentsOf: self.localCameraAssetArray.reversed())
            localAssets.append(contentsOf: self.localAssetArray)
            var photoAssets = [PhotoAsset]()
            photoAssets.reserveCapacity(assetCollection?.count ?? 10)
            var lastAsset: PhotoAsset?
            assetCollection?
                .enumerateAssets(
                    options: self.fetchLimit > 0 ? .reverse : .concurrent,
                    usingBlock: { [weak self] (photoAsset, index, stop) in
                guard let self = self, !operation.isCancelled else {
                    stop.pointee = true
                    return
                }
                if self.selectOptions.contains(.gifPhoto) {
                    if photoAsset.phAsset!.isImageAnimated {
                        photoAsset.mediaSubType = .imageAnimated
                    }
                }
                if self.config.selectOptions.contains(.livePhoto) {
                    if photoAsset.phAsset!.isLivePhoto {
                        photoAsset.mediaSubType = .livePhoto
                    }
                }
                if self.config.selectOptions.contains(.HDRPhoto) {
                    if photoAsset.mediaSubType == .image && photoAsset.phAsset!.isHDR {
                        photoAsset.mediaSubType = .HDRPhoto
                    }
                }
                photoAsset.isDisableHDR = self.config.isDisableHDR
                photoAsset.isDisableLivePhoto = self.config.isDisableLivePhoto
                photoAsset.isLivePhotoMuted = self.config.isLivePhotoMuted
                        
                switch photoAsset.mediaType {
                case .photo:
                    if !self.selectOptions.isPhoto {
                        return
                    }
                case .video:
                    if !self.selectOptions.isVideo {
                        return
                    }
                }
                var asset = photoAsset
                if selectedAssets.contains(asset.phAsset!) {
                    let index = selectedAssets.firstIndex(of: asset.phAsset!)!
                    let phAsset: PhotoAsset = selectedPhotoAssets[index]
                    asset = phAsset
                    lastAsset = phAsset
                }
                photoAssets.append(asset)
                if self.fetchLimit > 0 && photoAssets.count > self.fetchLimit {
                    stop.pointee = true
                }
            })
            if self.config.photoList.sort == .desc {
                if self.fetchLimit == 0 {
                    photoAssets.reverse()
                }
                photoAssets.insert(contentsOf: localAssets, at: 0)
            }else {
                photoAssets.append(contentsOf: localAssets.reversed())
            }
            if operation.isCancelled {
                return
            }
            DispatchQueue.main.async {
                self.fetchAssetsCompletion?(photoAssets, lastAsset)
            }
        }
        fetchAssetQueue.addOperation(operation)
    }
    private func cancelFetchAssetQueue() {
        fetchAssetQueue.cancelAllOperations()
    }
    private func getSelectAsset() -> ([PHAsset], [PhotoAsset]) {
        var selectedAssets = [PHAsset]()
        var selectedPhotoAssets: [PhotoAsset] = []
        var localIndex = -1
        for (index, photoAsset) in selectedAssetArray.enumerated() {
            if config.selectMode == .single {
                break
            }
            photoAsset.selectIndex = index
            photoAsset.isSelected = true
            if let phAsset = photoAsset.phAsset {
                selectedAssets.append(phAsset)
                selectedPhotoAssets.append(photoAsset)
            }else {
                let inLocal = self
                    .localAssetArray
                    .contains { (localAsset) -> Bool in
                    if localAsset.isEqual(photoAsset) {
                        localAssetArray[localAssetArray.firstIndex(of: localAsset)!] = photoAsset
                        return true
                    }
                    return false
                }
                let inLocalCamera = localCameraAssetArray
                    .contains(where: { (localAsset) -> Bool in
                    if localAsset.isEqual(photoAsset) {
                        localCameraAssetArray[
                            localCameraAssetArray.firstIndex(of: localAsset)!
                        ] = photoAsset
                        return true
                    }
                    return false
                })
                if !inLocal && !inLocalCamera {
                    if photoAsset.localIndex > localIndex {
                        localIndex = photoAsset.localIndex
                        self.localAssetArray.insert(photoAsset, at: 0)
                    }else {
                        if localIndex == -1 {
                            localIndex = photoAsset.localIndex
                            localAssetArray.insert(photoAsset, at: 0)
                        }else {
                            localAssetArray.insert(photoAsset, at: 1)
                        }
                    }
                }
            }
        }
        return (selectedAssets, selectedPhotoAssets)
    }
}

public extension PickerManager {
    
    /// 获取已选资源的总大小
    /// - Parameters:
    ///   - completion: 完成回调
    func requestSelectedAssetFileSize(
        completion: @escaping (Int, String) -> Void
    ) {
        cancelRequestAssetFileSize()
        if selectedAssetArray.isEmpty {
            completion(0, "")
            return
        }
        let operation = BlockOperation()
        operation.addExecutionBlock { [unowned operation, weak self] in
            guard let self = self else { return }
            var totalFileSize = 0
            for photoAsset in self.selectedAssetArray {
                if operation.isCancelled {
                    return
                }
                if let fileSize = photoAsset.getPFileSize() {
                    totalFileSize += fileSize
                    continue
                }
                totalFileSize += photoAsset.fileSize
            }
            DispatchQueue.main.async {
                completion(
                    totalFileSize,
                    totalFileSize.bytesString
                )
            }
        }
        requestAssetBytesQueue.addOperation(operation)
    }
    
    /// 取消获取资源文件大小
    func cancelRequestAssetFileSize() {
        requestAssetBytesQueue.cancelAllOperations()
    }
}

extension PickerManager {
    
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
    func addedPhotoAsset(photoAsset: PhotoAsset) -> Bool {
//        if singleVideo && photoAsset.mediaType == .video {
//            return false
//        }
//        if config.selectMode == .single {
//            // 单选模式不可添加
//            return false
//        }
        if selectedAssetArray.contains(photoAsset) {
            photoAsset.isSelected = true
            return true
        }
        let canSelect = canSelectAsset(for: photoAsset, showHUD: true)
        if canSelect {
            willSelectAsset?(photoAsset, selectedAssetArray.count)
            canAddAsset = false
            photoAsset.isSelected = true
            photoAsset.selectIndex = selectedAssetArray.count
            if photoAsset.mediaType == .photo {
                selectedPhotoAssetArray.append(photoAsset)
            }else if photoAsset.mediaType == .video {
                selectedVideoAssetArray.append(photoAsset)
            }
            selectedAssetArray.append(photoAsset)
            didSelectAsset?(photoAsset, selectedAssetArray.count - 1)
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
        photoAsset.isSelected = false
        willDeselectAsset?(photoAsset, selectedAssetArray.count)
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
        didDeselectAsset?(photoAsset, selectedAssetArray.count + 1)
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
    
    /// 是否能够选择Asset
    /// - Parameters:
    ///   - photoAsset: 对应的PhotoAsset
    ///   - showHUD: 是否显示HUD
    /// - Returns: 结果
    func canSelectAsset(
        for photoAsset: PhotoAsset,
        showHUD: Bool
    ) -> Bool {
        var canSelect = true
        var text: String?
        if photoAsset.mediaType == .photo {
            if config.maximumSelectedPhotoFileSize > 0 {
                if photoAsset.fileSize > config.maximumSelectedPhotoFileSize {
                    text = .textManager.picker.maximumSelectedPhotoFileSizeHudTitle.text + config.maximumSelectedPhotoFileSize.bytesString
                    canSelect = false
                }
            }
            if !config.allowSelectedTogether {
                if selectedVideoAssetArray.count > 0 {
                    text = .textManager.picker.photoTogetherSelectHudTitle.text
                    canSelect = false
                }
            }
            if config.maximumSelectedPhotoCount > 0 {
                if selectedPhotoAssetArray.count >= config.maximumSelectedPhotoCount {
                    text = String.init(format: .textManager.picker.maximumSelectedPhotoHudTitle.text, arguments: [config.maximumSelectedPhotoCount])
                    canSelect = false
                }
            }else {
                if selectedAssetArray.count >= config.maximumSelectedCount && config.maximumSelectedCount > 0 {
                    text = .textManager.picker.maximumSelectedHudTitle.text
                    canSelect = false
                }
            }
        }else if photoAsset.mediaType == .video {
            if config.maximumSelectedVideoFileSize > 0 {
                if photoAsset.fileSize > config.maximumSelectedVideoFileSize {
                    text = .textManager.picker.maximumSelectedVideoFileSizeHudTitle.text + config.maximumSelectedVideoFileSize.bytesString
                    canSelect = false
                }
            }
            if config.maximumSelectedVideoDuration > 0 {
                if round(photoAsset.videoDuration) > Double(config.maximumSelectedVideoDuration) {
                    #if HXPICKER_ENABLE_EDITOR
                    if !config.editorOptions.contains(.video) {
                        text = String(
                            format: .textManager.picker.maximumSelectedVideoDurationHudTitle.text,
                            arguments: [config.maximumSelectedVideoDuration]
                        )
                        canSelect = false
                    }else {
                        if config.maximumVideoEditDuration > 0 &&
                            round(photoAsset.videoDuration) > Double(config.maximumVideoEditDuration) {
                            text = String(
                                format: .textManager.picker.maximumVideoEditDurationHudTitle.text,
                                arguments: [config.maximumVideoEditDuration]
                            )
                            canSelect = false
                        }
                    }
                    #else
                    text = String(
                        format: .textManager.picker.maximumSelectedVideoDurationHudTitle.text,
                        arguments: [config.maximumSelectedVideoDuration]
                    )
                    canSelect = false
                    #endif
                }
            }
            if config.minimumSelectedVideoDuration > 0 {
                if round(photoAsset.videoDuration) < Double(config.minimumSelectedVideoDuration) {
                    text = String(
                        format: .textManager.picker.minimumSelectedVideoDurationHudTitle.text,
                        arguments: [config.minimumSelectedVideoDuration]
                    )
                    canSelect = false
                }
            }
            if !config.allowSelectedTogether {
                if selectedPhotoAssetArray.count > 0 {
                    text = .textManager.picker.videoTogetherSelectHudTitle.text
                    canSelect = false
                }
            }
            if config.maximumSelectedVideoCount > 0 {
                if selectedVideoAssetArray.count >= config.maximumSelectedVideoCount {
                    text = String.init(format: .textManager.picker.maximumSelectedVideoHudTitle.text, arguments: [config.maximumSelectedVideoCount])
                    canSelect = false
                }
            }else {
                if selectedAssetArray.count >= config.maximumSelectedCount && config.maximumSelectedCount > 0 {
                    text = .textManager.picker.maximumSelectedHudTitle.text
                    canSelect = false
                }
            }
        }
        if let text = text, !canSelect, showHUD {
            PhotoManager.HUDView.showInfo(with: text, delay: 1.5, animated: true, addedTo: UIApplication.shared.keyWindow)
        }
        return canSelect
    }
    
    /// 视频时长是否超过最大限制
    /// - Parameter photoAsset: 对应的PhotoAsset对象
    func videoDurationExceedsTheLimit(photoAsset: PhotoAsset) -> Bool {
        if photoAsset.mediaType == .video {
            if config.maximumSelectedVideoDuration > 0 {
                if round(photoAsset.videoDuration) > Double(config.maximumSelectedVideoDuration) {
                    return true
                }
            }
        }
        return false
    }
    
    /// 选择数是否达到最大
    func selectArrayIsFull() -> Bool {
        if selectedAssetArray.count >= config.maximumSelectedCount && config.maximumSelectedCount > 0 {
            return true
        }
        return false
    }
    
    public func deselectAll() {
        for photoAsset in selectedAssetArray {
            photoAsset.isSelected = false
        }
        removeSelectedAssets()
    }
    
    public func removeSelectedAssets() {
        selectedAssetArray.removeAll()
        selectedPhotoAssetArray.removeAll()
        selectedVideoAssetArray.removeAll()
    }
}

// MARK: PHPhotoLibraryChangeObserver
extension PickerManager: PHPhotoLibraryChangeObserver {
    
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        if !AssetPermissionsUtil.isLimitedAuthorizationStatus || !config.allowLoadPhotoLibrary {
            return
        }
        var needReload = false
        if let collection = cameraAssetCollection {
            needReload = resultHasChanges(
                for: changeInstance,
                assetCollection: collection
            )
        }else {
            needReload = true
        }
        if needReload {
            DispatchQueue.main.async {
                self.reloadAssetCollection?()
                if self.cameraAssetCollection?.result == nil {
                    self.fetchCameraAssetCollection { [weak self] collection in
                        self?.fetchPhotoAssets(
                            assetCollection: collection
                        )
                    }
                }else {
                    self.fetchPhotoAssets(
                        assetCollection: self.cameraAssetCollection
                    )
                }
            }
        }
    }
    private func resultHasChanges(
        for changeInstance: PHChange,
        assetCollection: PhotoAssetCollection
    ) -> Bool {
        if assetCollection.result == nil {
            if assetCollection == self.cameraAssetCollection {
                return true
            }
            return false
        }
        let changeResult: PHFetchResultChangeDetails? = changeInstance.changeDetails(
            for: assetCollection.result!
        )
        if changeResult != nil {
            if !changeResult!.hasIncrementalChanges {
                let result = changeResult!.fetchResultAfterChanges
                assetCollection.updateResult(for: result)
                return true
            }
        }
        return false
    }
}
