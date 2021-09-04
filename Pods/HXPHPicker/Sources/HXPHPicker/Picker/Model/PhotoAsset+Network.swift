//
//  PhotoAsset+Network.swift
//  HXPHPicker
//
//  Created by Slience on 2021/5/24.
//

import UIKit
#if canImport(Kingfisher)
import Kingfisher
#endif

public extension PhotoAsset {
    
    #if canImport(Kingfisher)
    /// 获取网络图片的地址，编辑过就是本地地址，未编辑就是网络地址
    /// - Parameter resultHandler: 图片地址、是否为网络地址
    func getNetworkImageURL(resultHandler: AssetURLCompletion) {
        #if HXPICKER_ENABLE_EDITOR
        if let photoEdit = photoEdit {
            resultHandler(.success(.init(url: photoEdit.editedImageURL, urlType: .local, mediaType: .photo)))
            return
        }
        #endif
        if let url = networkImageAsset?.originalURL {
            resultHandler(.success(.init(url: url, urlType: .network, mediaType: .photo)))
        }else {
            resultHandler(.failure(.networkURLIsEmpty))
        }
    }
    
    /// 获取网络图片
    /// - Parameters:
    ///   - filterEditor: 过滤编辑的数据
    ///   - resultHandler: 获取结果
    func getNetworkImage(urlType: DonwloadURLType = .original,
                         filterEditor: Bool = false,
                         progressBlock: DownloadProgressBlock? = nil,
                         resultHandler: @escaping (UIImage?) -> Void) {
        #if HXPICKER_ENABLE_EDITOR
        if let photoEdit = photoEdit, !filterEditor {
            if urlType == .thumbnail {
                resultHandler(photoEdit.editedImage)
            }else {
                let image = UIImage.init(contentsOfFile: photoEdit.editedImageURL.path)
                resultHandler(image)
            }
            return
        }
        #endif
        let isThumbnail = urlType == .thumbnail
        let url = isThumbnail ? networkImageAsset!.thumbnailURL : networkImageAsset!.originalURL
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
        if let videoEdit = videoEdit {
            resultHandler(.success(.init(url: videoEdit.editedURL, urlType: .local, mediaType: .video)))
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
