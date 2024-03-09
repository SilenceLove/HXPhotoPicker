//
//  PhotoAsset+Network.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/5/24.
//

import UIKit
#if canImport(Kingfisher)
import Kingfisher
#endif

public extension PhotoAsset {
    
    #if canImport(Kingfisher)
    
    /// 加载原图，只在预览界面有效
    func loadNetworkOriginalImage(_ completion: ((PhotoAsset) -> Void)? = nil) {
        loadNetworkImageHandler?(completion)
    }
    
    /// 获取网络图片的地址，编辑过就是本地地址，未编辑就是网络地址
    /// - Parameter resultHandler: 图片地址、是否为网络地址
    func getNetworkImageURL(resultHandler: AssetURLCompletion) {
        #if HXPICKER_ENABLE_EDITOR
        if let photoEdit = photoEditedResult {
            resultHandler(.success(.init(url: photoEdit.url, urlType: .local, mediaType: .photo)))
            return
        }
        #endif
        if let networkImage = networkImageAsset {
            if networkImage.originalLoadMode == .alwaysThumbnail {
                if let originalURL = networkImage.originalURL,
                   ImageCache.default.isCached(forKey: originalURL.cacheKey) {
                    resultHandler(.success(.init(url: originalURL, urlType: .network, mediaType: .photo)))
                    return
                }else if let thumbnailURL = networkImage.thumbnailURL {
                    resultHandler(.success(.init(url: thumbnailURL, urlType: .network, mediaType: .photo)))
                    return
                }
            }else if let originalURL = networkImage.originalURL {
                resultHandler(.success(.init(url: originalURL, urlType: .network, mediaType: .photo)))
                return
            }
        }else {
            resultHandler(.failure(.networkURLIsEmpty))
        }
    }
    
    /// 获取网络图片
    /// - Parameters:
    ///   - filterEditor: 过滤编辑的数据
    ///   - resultHandler: 获取结果
    func getNetworkImage(
        urlType: DonwloadURLType = .original,
        filterEditor: Bool = false,
        progressBlock: DownloadProgressBlock? = nil,
        resultHandler: @escaping (UIImage?) -> Void
    ) {
        #if HXPICKER_ENABLE_EDITOR
        if let photoEdit = photoEditedResult, !filterEditor {
            if urlType == .thumbnail {
                resultHandler(photoEdit.image)
            }else {
                let image = UIImage.init(contentsOfFile: photoEdit.url.path)
                resultHandler(image)
            }
            return
        }
        #endif
        let isThumbnail = urlType == .thumbnail
        var url: URL?
        if let networkImage = networkImageAsset {
            url = isThumbnail ? networkImage.thumbnailURL : networkImage.originalURL
        }else if let livePhoto = localLivePhoto, !livePhoto.imageURL.isFileURL {
            url = livePhoto.imageURL
        }else if let videoAsset = networkVideoAsset {
            let videoURL: URL?
            if let coverImage = videoAsset.coverImage {
                resultHandler(coverImage)
                return
            }else if let coverImageURL = videoAsset.coverImageURL {
                videoURL = coverImageURL
            }else {
                if let key = videoAsset.videoURL?.absoluteString,
                   PhotoTools.isCached(forVideo: key) {
                    videoURL = PhotoTools.getVideoCacheURL(for: key)
                }else {
                    videoURL = videoAsset.videoURL
                }
            }
            guard let videoURL else {
                resultHandler(nil)
                return
            }
            let provider = AVAssetImageDataProvider(assetURL: videoURL, seconds: 0.1)
            provider.assetImageGenerator.appliesPreferredTrackTransform = true
            _ = KingfisherManager.shared.retrieveImage(with: .provider(provider)) { result in
                switch result {
                case .success(let result):
                    resultHandler(result.image)
                case .failure:
                    resultHandler(nil)
                }
            }
            return
        }
        guard let url else {
            resultHandler(nil)
            return
        }
        let options: KingfisherOptionsInfo = isThumbnail ?
            .init(
                [.onlyLoadFirstFrame,
             .cacheOriginalImage]
            )
            :
            .init(
                [.backgroundDecode]
            )
        
        PhotoTools.downloadNetworkImage(with: url, options: options, progressBlock: progressBlock) { (image) in
            if let image = image {
                resultHandler(image)
            }else {
                resultHandler(nil)
            }
        }
    }
    #endif
    
    /// 获取网络视频的地址，编辑过就是本地地址，未编辑就是网络地址
    /// - Parameter resultHandler: 视频地址、是否为网络地址
    func getNetworkVideoURL(resultHandler: AssetURLCompletion) {
        #if HXPICKER_ENABLE_EDITOR
        if let videoEdit = videoEditedResult {
            resultHandler(.success(.init(url: videoEdit.url, urlType: .local, mediaType: .video)))
            return
        }
        #endif
        if let url = networkVideoAsset?.videoURL {
            resultHandler(.success(.init(url: url, urlType: .network, mediaType: .video)))
        }else {
            resultHandler(.failure(.networkURLIsEmpty))
        }
    }
}
