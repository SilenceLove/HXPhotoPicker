//
//  PhotoAsset+Network.swift
//  HXPHPicker
//
//  Created by Slience on 2021/5/24.
//

import UIKit
#if canImport(Kingfisher)
import Kingfisher

public enum DonwloadURLType {
    case thumbnail
    case original
}
#endif

public extension PhotoAsset {
    
    #if canImport(Kingfisher)
    /// 获取网络图片的地址，编辑过就是本地地址，未编辑就是网络地址
    /// - Parameter resultHandler: 地址、是否为网络地址
    func getNetworkImageURL(resultHandler: @escaping (URL?, Bool) -> Void) {
        #if HXPICKER_ENABLE_EDITOR
        if let photoEdit = photoEdit {
            resultHandler(photoEdit.editedImageURL, false) 
            return
        }
        #endif
        resultHandler(networkImageAsset?.originalURL, true)
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
        let options: KingfisherOptionsInfo = isThumbnail ? .init([.onlyLoadFirstFrame, .cacheOriginalImage]) : .init([.backgroundDecode])
        
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
    /// - Parameter resultHandler: 地址、是否为网络地址
    func getNetworkVideoURL(resultHandler: @escaping (URL?, Bool) -> Void) {
        #if HXPICKER_ENABLE_EDITOR
        if let videoEdit = videoEdit {
            resultHandler(videoEdit.editedURL, false)
            return
        }
        #endif
        resultHandler(networkVideoAsset?.videoURL, true)
    }
}
