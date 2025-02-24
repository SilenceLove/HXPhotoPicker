//
//  PhotoAsset+Network.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/5/24.
//

import UIKit

public extension PhotoAsset {
    
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
                   PhotoManager.ImageView.isCached(forKey: PhotoManager.ImageView.getCacheKey(forURL: originalURL)) {
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
        progressBlock: ((CGFloat) -> Void)? = nil,
        resultHandler: @escaping (UIImage?, Data?) -> Void
    ) {
        #if HXPICKER_ENABLE_EDITOR
        if let photoEdit = photoEditedResult, !filterEditor {
            if urlType == .thumbnail {
                resultHandler(photoEdit.image, nil)
            }else {
                let image = UIImage.init(contentsOfFile: photoEdit.url.path)
                resultHandler(image, nil)
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
                resultHandler(coverImage, nil)
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
                resultHandler(nil, nil)
                return
            }
            PhotoTools.getVideoThumbnailImage(url: videoURL, atTime: 0.1) { _, image, _ in
                guard let image else {
                    resultHandler(nil, nil)
                    return
                }
                resultHandler(image, nil)
            }
            return
        }
        guard let url else {
            resultHandler(nil, nil)
            return
        }
        PhotoManager.ImageView.download(with: .init(downloadURL: url), options: [.onlyLoadFirstFrame, .cacheOriginalImage], progressHandler: progressBlock) {
            switch $0 {
            case .success(let result):
                var image = result.image
                if let data = result.imageData, let _image = UIImage(data: data) {
                    image = _image
                }
                resultHandler(image, result.imageData)
            case .failure:
                resultHandler(nil, nil)
            }
        }
    }
    
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
