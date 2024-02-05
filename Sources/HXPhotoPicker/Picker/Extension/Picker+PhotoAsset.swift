//
//  Picker+PhotoAsset.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/6/8.
//

import UIKit
import Photos

public extension PhotoAsset {
    /// 保存到系统相册
    func saveToSystemAlbum(
        albumName: String? = nil,
        _ completion: ((PHAsset?) -> Void)? = nil
    ) {
        if mediaSubType == .localLivePhoto {
            requestLocalLivePhotoURL {
                switch $0 {
                case .success(let result):
                    guard let livePhoto = result.livePhoto else {
                        completion?(nil)
                        return
                    }
                    AssetManager.save(
                        type: .livePhoto(imageURL: livePhoto.imageURL, videoURL: livePhoto.videoURL),
                        customAlbumName: albumName
                    ) {
                        switch $0 {
                        case .success(let phAsset):
                            completion?(phAsset)
                        case .failure:
                            completion?(nil)
                        }
                    }
                default:
                    completion?(nil)
                }
            }
            return
        }
        func save(_ type: AssetManager.PhotoSaveType) {
            AssetManager.save(
                type: type,
                customAlbumName: albumName
            ) {
                switch $0 {
                case .success(let phAsset):
                    completion?(phAsset)
                case .failure:
                    completion?(nil)
                }
            }
        }
        getAssetURL { result in
            switch result {
            case .success(let response):
                if response.mediaType == .photo {
                    if response.urlType == .network {
                        #if canImport(Kingfisher)
                        PhotoTools.downloadNetworkImage(
                            with: response.url,
                            options: [],
                            completionHandler: { image in
                            if let image = image {
                                save(.image(image))
                            }else {
                                completion?(nil)
                            }
                        })
                        #endif
                    }else {
                        save(.imageURL(response.url))
                    }
                }else {
                    if response.urlType == .network {
                        PhotoManager.shared.downloadTask(
                            with: response.url,
                            progress: nil) { videoURL, _, _ in
                            if let videoURL = videoURL {
                                save(.videoURL(videoURL))
                            }else {
                                completion?(nil)
                            }
                        }
                    }else {
                        save(.videoURL(response.url))
                    }
                }
            case .failure:
                completion?(nil)
            }
        }
    }
}
public extension PhotoAsset {
    
    var inICloud: Bool {
        guard let phAsset = phAsset,
              downloadStatus != .succeed else {
            return false
        }
        if !phAsset.isLocallayAvailable {
            return true
        }
        return false
    }
    
    func checkICloundStatus(
        allowSyncPhoto: Bool,
        hudAddedTo view: UIView? = UIApplication.shared.keyWindow,
        completion: @escaping (PhotoAsset, Bool) -> Void
    ) -> Bool {
        guard let phAsset = phAsset,
              downloadStatus != .succeed else {
            return false
        }
        if mediaType == .photo && !allowSyncPhoto {
            return false
        }
        if phAsset.inICloud {
            syncICloud(
                hudAddedTo: view,
                completion: completion
            )
            return true
        }else {
            downloadStatus = .succeed
        }
        return false
    }
    
    /// 获取iCloud状态
    /// - Parameter completion: 是否在iCloud上
    /// - Returns: 请求ID
    func requestICloudState(completion: @escaping (PhotoAsset, Bool) -> Void) -> PHImageRequestID? {
        guard let phAsset = phAsset,
              downloadStatus != .succeed else {
            completion(self, false)
            return nil
        }
        if mediaType == .photo {
            let options = PHImageRequestOptions()
            options.isSynchronous = false
            options.deliveryMode = .fastFormat
            options.resizeMode = .fast
            return AssetManager.requestImageData(
                for: phAsset,
                options: options
            ) { (result) in
                switch result {
                case .failure(let error):
                    guard let info = error.info,
                          !info.isCancel else {
                        completion(self, false)
                        return
                    }
                    completion(self, info.inICloud)
                default:
                    self.downloadStatus = .succeed
                    completion(self, false)
                }
            }
        }
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = false
        options.deliveryMode = .highQualityFormat
        return AssetManager.requestAVAsset(
            for: phAsset,
            options: options
        ) { result in
            switch result {
            case .failure(let error):
                guard let info = error.info,
                      !info.isCancel else {
                    completion(self, false)
                    return
                }
                completion(self, info.inICloud)
            default:
                self.downloadStatus = .succeed
                completion(self, false)
            }
        }
    }
    
    @discardableResult
    func syncICloud(
        iCloudHandler: PhotoAssetICloudHandler?,
        progressHandler: PhotoAssetProgressHandler?,
        completionHandler: ( (PhotoAsset, Bool) -> Void)?
    ) -> PHImageRequestID {
        if mediaType == .photo {
            return requestImageData(
                iCloudHandler: iCloudHandler,
                progressHandler: progressHandler
            ) { [weak self] _, result in
                guard let self = self else { return }
                switch result {
                case .success:
                    completionHandler?(self, true)
                case .failure:
                    completionHandler?(self, false)
                }
            }
        }else {
            return requestAVAsset(
                deliveryMode: .highQualityFormat,
                iCloudHandler: iCloudHandler,
                progressHandler: progressHandler
            ) { [weak self] _, _, _ in
                guard let self = self else { return }
                completionHandler?(self, true)
            } failure: { [weak self] _, _, _ in
                guard let self = self else { return }
                completionHandler?(self, false)
            }
        }
    }
    
    /// 同步iCloud上的资源
    /// - Parameters:
    ///   - view: 提示框的父视图
    ///   - completion: 同步完成 - 是否成功
    func syncICloud(
        hudAddedTo view: UIView? = UIApplication.shared.keyWindow,
        completion: ((PhotoAsset, Bool) -> Void)? = nil
    ) {
        var loadingView: ProgressHUD?
        syncICloud { _, _ in
            loadingView = ProgressHUD.showProgress(
                addedTo: view,
                text: .textPhotoList.iCloudSyncHudTitle.text + "...",
                animated: true
            )
        } progressHandler: { _, progress in
            loadingView?.progress = CGFloat(progress)
        } completionHandler: { photoAsset, isSuccess in
            ProgressHUD.hide(forView: view, animated: isSuccess)
            if !isSuccess {
                ProgressHUD.showWarning(
                    addedTo: view,
                    text: .textPhotoList.iCloudSyncFailedHudTitle.text,
                    animated: true,
                    delayHide: 1.5
                )
            }
            loadingView = nil
            completion?(photoAsset, isSuccess)
        }
    }
}

extension LocalLivePhotoAsset {
    
    var jpgURL: URL {
        let imageCacheKey = imageIdentifier ?? imageURL.absoluteString
        let jpgPath = PhotoTools.getLivePhotoImageCachePath(for: imageCacheKey)
        return URL(fileURLWithPath: jpgPath)
    }

    var movURL: URL {
        let videoCacheKey = videoIdentifier ?? videoURL.absoluteString
        let movPath = PhotoTools.getLivePhotoVideoCachePath(for: videoCacheKey)
        return URL(fileURLWithPath: movPath)
    }
    
    var isCache: Bool {
        if FileManager.default.fileExists(atPath: jpgURL.path),
           FileManager.default.fileExists(atPath: movURL.path) {
            return true
        }
        return false
    }
}
