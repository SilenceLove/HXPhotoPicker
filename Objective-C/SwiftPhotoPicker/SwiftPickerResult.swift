//
//  SwiftPickerResult.swift
//  HXPhotoPickerExample
//
//  Created by Silence on 2023/6/14.
//  Copyright © 2023 洪欣. All rights reserved.
//

import UIKit
import HXPhotoPicker
import AVFoundation

class SwiftPickerResult: NSObject {
    let assets: [PhotoAsset]
    
    @objc
    let photoAssets: [SwiftPhotoAsset]
    
    @objc
    let isOriginal: Bool
    
    @objc
    var compression: SwiftCompression? = .init(
        imageCompressionQuality: 0.6,
        videoExportParameter: .init(
            preset: .ratio_960x540,
            quality: 6
        )
    )
    
    init(photoAssets: [PhotoAsset], isOriginal: Bool) {
        self.assets = photoAssets
        var array: [SwiftPhotoAsset] = []
        for photoAsset in photoAssets {
            array.append(.init(photoAsset))
        }
        self.photoAssets = array
        self.isOriginal = isOriginal
    }
    
    @objc
    func getImage(
        compressionScale: CGFloat = 0.5,
        imageHandler: ((UIImage?, Int) -> Void)? = nil,
        completionHandler: @escaping ([UIImage]) -> Void
    ) {
        assets.getImage(compressionScale: compressionScale) { image, _, index in
            imageHandler?(image, index)
        } completionHandler: {
            completionHandler($0)
        }
    }
    
    @objc
    func getVideoURL(
        exportSession: ((AVAssetExportSession, Int) -> Void)? = nil,
        videoURLHandler: ((SwiftAssetURLResult?, Int) -> Void)? = nil,
        completionHandler: @escaping ([URL]) -> Void
    ) {
        assets.getVideoURL(
            exportParameter: isOriginal ? nil : compression?.videoExportParameter?.toHX,
            toFile: nil
        ) { session, _, index in
            exportSession?(session, index)
        } videoURLHandler: { result, _, index in
            switch result {
            case .success(let urlResult):
                videoURLHandler?(urlResult.toOC, index)
            case .failure:
                videoURLHandler?(nil, index)
            }
        } completionHandler: {
            completionHandler($0)
        }
    }
    
    @objc
    func getURLs(
        options: Options = .any,
        completion: @escaping ([URL]) -> Void
    ) {
        assets.getURLs(
            options: options.toHX,
            compression: isOriginal ? nil : compression?.toHX
        ) {
            completion($0)
        }
    }
    
    @objc
    func getURLs(
        options: Options = .any,
        urlReceivedHandler handler: ((SwiftAssetURLResult?, Int) -> Void)? = nil,
        completionHandler: @escaping ([URL]) -> Void
    ) {
        assets.getURLs(
            options: options.toHX,
            compression: isOriginal ? nil : compression?.toHX,
            toFile: nil
        ) { result, _, index in
            switch result {
            case .success(let urlResult):
                handler?(urlResult.toOC, index)
            case .failure:
                handler?(nil, index)
            }
        } completionHandler: {
            completionHandler($0)
        }
    }
    
    @objc
    enum Options: Int {
        case photo
        case video
        case any
        
        var toHX: PickerResult.Options {
            switch self {
            case .photo:
                return .photo
            case .video:
                return .video
            case .any:
                return .any
            }
        }
    }
}

extension AssetURLResult {
    var toOC: SwiftAssetURLResult {
        let urlResult = self
        let urlType: SwiftAssetURLResult.URLType
        switch urlResult.urlType {
        case .local:
            urlType = .local
        case .network:
            urlType = .network
        }
        let mediaType: SwiftAssetURLResult.MediaType
        switch urlResult.mediaType {
        case .photo:
            mediaType = .image
        default:
            mediaType = .video
        }
        var livePhoto: SwiftAssetURLResult.LivePhoto?
        if let _livePhoto = urlResult.livePhoto {
            let livePhotoImageUrlType: SwiftAssetURLResult.URLType
            switch _livePhoto.imageURLType {
            case .local:
                livePhotoImageUrlType = .local
            case .network:
                livePhotoImageUrlType = .network
            }
            let livePhotoVideoUrlType: SwiftAssetURLResult.URLType
            switch _livePhoto.videoURLType {
            case .local:
                livePhotoVideoUrlType = .local
            case .network:
                livePhotoVideoUrlType = .network
            }
            livePhoto = .init(
                imageURL: _livePhoto.imageURL,
                imageURLType: livePhotoImageUrlType,
                videoURL: _livePhoto.videoURL,
                videoURLType: livePhotoVideoUrlType
            )
        }
        
        return .init(url: urlResult.url, urlType: urlType, mediaType: mediaType, livePhoto: livePhoto)
    }
}

/// 压缩参数
class SwiftCompression: NSObject {
    
    @objc
    let imageCompressionQuality: CGFloat
    
    @objc
    let videoExportParameter: SwiftVideoExportParameter?
    
    /// 压缩图片
    /// - Parameter imageCompressionQuality: 图片压缩质量 [0 - 1]
    @objc
    public init(
        imageCompressionQuality: CGFloat
    ) {
        self.imageCompressionQuality = imageCompressionQuality
        self.videoExportParameter = nil
    }
    
    /// 压缩视频
    /// - Parameter videoExportParameter: 视频压缩参数
    @objc
    public init(
        videoExportParameter: SwiftVideoExportParameter
    ) {
        self.imageCompressionQuality = -1
        self.videoExportParameter = videoExportParameter
    }
    
    /// 压缩图片、视频
    /// - Parameters:
    ///   - imageCompressionQuality: 图片压缩质量 [0 - 1]
    ///   - videoExportParameter: 视频压缩参数
    @objc
    public init(
        imageCompressionQuality: CGFloat,
        videoExportParameter: SwiftVideoExportParameter
    ) {
        self.imageCompressionQuality = imageCompressionQuality
        self.videoExportParameter = videoExportParameter
    }
    
    var toHX: PhotoAsset.Compression? {
        if let videoExportParameter = videoExportParameter, imageCompressionQuality >= 0 {
            return .init(
                imageCompressionQuality: imageCompressionQuality,
                videoExportParameter: videoExportParameter.toHX
            )
        }else if let videoExportParameter = videoExportParameter {
            return .init(videoExportParameter: videoExportParameter.toHX)
        }else if imageCompressionQuality >= 0 {
            return .init(imageCompressionQuality: imageCompressionQuality)
        }
        return nil
    }
}

class SwiftVideoExportParameter: NSObject {
    /// 视频导出的分辨率
    @objc
    let preset: SwiftExportPreset
    /// 视频质量 [1 - 10]
    @objc
    let quality: Int
    
    /// 设置视频导出参数
    /// - Parameters:
    ///   - preset: 视频导出的分辨率
    ///   - quality: 视频质量 [1 - 10]
    @objc
    init(
        preset: SwiftExportPreset,
        quality: Int
    ) {
        self.preset = preset
        self.quality = quality
    }
    
    var toHX: VideoExportParameter {
        let present: ExportPreset
        switch preset {
        case .lowQuality:
            present = .lowQuality
        case .mediumQuality:
            present = .mediumQuality
        case .highQuality:
            present = .highQuality
        case .ratio_640x480:
            present = .ratio_640x480
        case .ratio_960x540:
            present = .ratio_960x540
        case .ratio_1280x720:
            present = .ratio_1280x720
        }
        return .init(preset: present, quality: quality)
    }
}

@objc
enum SwiftExportPreset: Int {
    case lowQuality
    case mediumQuality
    case highQuality
    case ratio_640x480
    case ratio_960x540
    case ratio_1280x720
    
    var name: String {
        switch self {
        case .lowQuality:
            return AVAssetExportPresetLowQuality
        case .mediumQuality:
            return AVAssetExportPresetMediumQuality
        case .highQuality:
            return AVAssetExportPresetHighestQuality
        case .ratio_640x480:
            return AVAssetExportPreset640x480
        case .ratio_960x540:
            return AVAssetExportPreset960x540
        case .ratio_1280x720:
            return AVAssetExportPreset1280x720
        }
    }
}
