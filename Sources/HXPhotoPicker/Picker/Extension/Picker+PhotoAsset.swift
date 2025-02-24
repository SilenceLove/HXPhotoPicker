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
        albumType: AssetSaveUtil.AlbumType = .displayName,
        _ completion: ((Result<PHAsset, Error>) -> Void)? = nil
    ) {
        if mediaSubType == .localLivePhoto {
            requestLocalLivePhotoURL {
                switch $0 {
                case .success(let result):
                    guard let livePhoto = result.livePhoto else {
                        completion?(.failure(AssetError.localLivePhotoIsEmpty))
                        return
                    }
                    AssetSaveUtil.save(
                        type: .livePhoto(imageURL: livePhoto.imageURL, videoURL: livePhoto.videoURL),
                        albumType: albumType
                    ) {
                        switch $0 {
                        case .success(let phAsset):
                            completion?(.success(phAsset))
                        case .failure(let error):
                            completion?(.failure(error))
                        }
                    }
                case .failure(let error):
                    completion?(.failure(error))
                }
            }
            return
        }
        func save(_ type: AssetSaveUtil.SaveType) {
            AssetSaveUtil.save(
                type: type,
                albumType: albumType
            ) {
                switch $0 {
                case .success(let phAsset):
                    completion?(.success(phAsset))
                case .failure(let error):
                    completion?(.failure(error))
                }
            }
        }
        getAssetURL { result in
            switch result {
            case .success(let response):
                if response.mediaType == .photo {
                    if response.urlType == .network {
                        PhotoManager.ImageView.download(with: .init(downloadURL: response.url), options: nil, progressHandler: nil) {
                            switch $0 {
                            case .success(let result):
                                if let image = result.image {
                                    save(.image(image))
                                }else if let imageData = result.imageData {
                                    DispatchQueue.global().async {
                                        do {
                                            let tmpURL = PhotoTools.getTmpURL(for: imageData.imageContentType.rawValue)
                                            try imageData.write(to: tmpURL)
                                            DispatchQueue.main.async {
                                                save(.imageURL(tmpURL))
                                            }
                                        }catch {
                                            DispatchQueue.main.async {
                                                completion?(.failure(AssetError.imageDownloadFailed))
                                            }
                                        }
                                    }
                                }
                            case .failure:
                                completion?(.failure(AssetError.imageDownloadFailed))
                            }
                        }
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
                                completion?(.failure(AssetError.videoDownloadFailed))
                            }
                        }
                    }else {
                        save(.videoURL(response.url))
                    }
                }
            case .failure(let error):
                completion?(.failure(error))
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
    @discardableResult
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
        var loadingView: PhotoHUDProtocol?
        syncICloud { _, _ in
            loadingView = PhotoManager.HUDView.showProgress(with: .textPhotoList.iCloudSyncHudTitle.text + "...", progress: 0, animated: true, addedTo: view)
        } progressHandler: { _, progress in
            loadingView?.setProgress(CGFloat(progress))
        } completionHandler: { photoAsset, isSuccess in
            PhotoManager.HUDView.dismiss(delay: 0, animated: isSuccess, for: view)
            if !isSuccess {
                PhotoManager.HUDView.showInfo(with: .textPhotoList.iCloudSyncFailedHudTitle.text, delay: 1.5, animated: true, addedTo: view)
            }
            loadingView = nil
            completion?(photoAsset, isSuccess)
        }
    }
}

@available(iOS 13.0, *)
public extension PhotoAsset {
    
    /// 保存到系统相册
    @discardableResult
    func saveAlbum(_  albumType: AssetSaveUtil.AlbumType = .displayName) async throws -> PHAsset {
        try await withCheckedThrowingContinuation { continuation in
            saveToSystemAlbum(albumType: albumType) { result in
                switch result {
                case .success(let phAsset):
                    continuation.resume(returning: phAsset)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func inIClound() async -> Bool {
        await withCheckedContinuation { continuation in
            requestICloudState { _, inIClound in
                continuation.resume(returning: inIClound)
            }
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
