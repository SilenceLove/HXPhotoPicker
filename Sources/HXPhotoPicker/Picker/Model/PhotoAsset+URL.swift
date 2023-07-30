//
//  PhotoAsset+URL.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/7/19.
//

import UIKit
import AVFoundation

public extension PhotoAsset {
    
    typealias AssetURLCompletion = (Result<AssetURLResult, AssetError>) -> Void
    
    /// 获取image，视频为封面图片
    /// - Parameters:
    ///   - compressionQuality: 压缩参数 0-1
    ///   - completion: 获取完成
    func getImage(
        compressionQuality: CGFloat? = nil,
        completion: @escaping (UIImage?) -> Void
    ) {
        #if canImport(Kingfisher)
        let hasEdited: Bool
        #if HXPICKER_ENABLE_EDITOR
        hasEdited = editedResult != nil
        #else
        hasEdited = false
        #endif
        if isNetworkAsset && !hasEdited {
            getNetworkImage { image in
                if let compressionQuality {
                    DispatchQueue.global().async {
                        guard let imageData = PhotoTools.getImageData(for: image),
                              let data = PhotoTools.imageCompress(
                                imageData,
                                  compressionQuality: compressionQuality
                              ),
                              let image = UIImage(data: data)?.normalizedImage()
                        else {
                            DispatchQueue.main.async {
                                completion(nil)
                            }
                            return
                        }
                        DispatchQueue.main.async {
                            completion(image)
                        }
                    }
                }else {
                    completion(image)
                }
            }
            return
        }
        #endif
        requestImage(compressionScale: compressionQuality) { image, _ in
            completion(image)
        }
    }
    
    /// 获取url
    /// PhotoManager.shared.isConverHEICToPNG = true 内部自动将HEIC格式转换成PNG格式
    /// - Parameters:
    ///   - fileURL: 指定地址，只支持本地、系统相册里的资源
    ///   - compression: 压缩参数，nil - 原图
    ///   - completion: 获取完成
    func getURL(
        toFile fileURL: URL? = nil,
        compression: Compression? = nil,
        completion: @escaping AssetURLCompletion
    ) {
        getAssetURL(compression: compression, completion: completion)
    }
    
    /// PhotoManager.shared.isConverHEICToPNG = true 内部自动将HEIC格式转换成PNG格式
    func getAssetURL(
        toFile fileURL: URL? = nil,
        compression: Compression? = nil,
        completion: @escaping AssetURLCompletion
    ) {
        if mediaType == .photo {
            if mediaSubType == .livePhoto ||
                mediaSubType == .localLivePhoto {
                getLivePhotoURL(
                    completion: completion
                )
                return
            }
            getImageURL(
                toFile: fileURL,
                compressionQuality: compression?.imageCompressionQuality,
                completion: completion
            )
        }else {
            getVideoURL(
                toFile: fileURL,
                exportParameter: compression?.videoExportParameter,
                completion: completion
            )
        }
    }
    
    /// 获取图片url
    /// PhotoManager.shared.isConverHEICToPNG = true 内部自动将HEIC格式转换成PNG格式
    /// - Parameters:
    ///   - fileURL: 指定地址，只支持本地、系统相册里的资源
    ///   - compressionQuality: 压缩比例，不传就是原图。gif不会压缩
    ///   - completion: 获取完成
    func getImageURL(
        toFile fileURL: URL? = nil,
        compressionQuality: CGFloat? = nil,
        completion: @escaping AssetURLCompletion
    ) {
        #if canImport(Kingfisher)
        if isNetworkAsset {
            getNetworkImageURL(
                resultHandler: completion
            )
            return
        }
        #endif
        requestImageURL(
            toFile: fileURL,
            compressionQuality: compressionQuality,
            resultHandler: completion
        )
    }
    
    /// 获取视频url
    /// - Parameters:
    ///   - fileURL: 指定地址，只支持本地、系统相册里的资源
    ///   - exportParameter: 导出参数，nil 为原始视频
    ///   - exportSession: 导出视频时对应的 AVAssetExportSession
    ///   - completion: 获取完成
    func getVideoURL(
        toFile fileURL: URL? = nil,
        exportParameter: VideoExportParameter? = nil,
        exportSession: ((AVAssetExportSession) -> Void)? = nil,
        completion: @escaping AssetURLCompletion
    ) {
        if isNetworkAsset {
            getNetworkVideoURL(
                resultHandler: completion
            )
            return
        }
        requestVideoURL(
            toFile: fileURL,
            exportParameter: exportParameter,
            exportSession: exportSession,
            resultHandler: completion
        )
    }
    
    /// 获取LivePhoto里的图片和视频URL
    /// - Parameters:
    ///   - compression: 压缩参数，nil - 原图
    ///   - completion: 获取完成
    func getLivePhotoURL(
        compression: Compression? = nil,
        completion: @escaping AssetURLCompletion
    ) {
        requestLivePhotoURL(
            compression: compression,
            completion: completion
        )
    }
}

public extension PhotoAsset {
    /// 压缩参数
    struct Compression {
        let imageCompressionQuality: CGFloat?
        let videoExportParameter: VideoExportParameter?
        
        /// 压缩图片
        /// - Parameter imageCompressionQuality: 图片压缩质量 [0 - 1]
        public init(
            imageCompressionQuality: CGFloat
        ) {
            self.imageCompressionQuality = imageCompressionQuality
            self.videoExportParameter = nil
        }
        
        /// 压缩视频
        /// - Parameters:
        ///   - quality: 视频质量 [1-10]
        public init(
            videoExportParameter: VideoExportParameter
        ) {
            self.imageCompressionQuality = nil
            self.videoExportParameter = videoExportParameter
        }
        
        /// 压缩图片、视频
        /// - Parameters:
        ///   - imageCompressionQuality: 图片压缩质量 [0 - 1]
        ///   - preset: 视频分辨率
        ///   - quality: 视频质量 [1-10]
        public init(
            imageCompressionQuality: CGFloat,
            videoExportParameter: VideoExportParameter
        ) {
            self.imageCompressionQuality = imageCompressionQuality
            self.videoExportParameter = videoExportParameter
        }
    }
}

@available(iOS 13.0, *)
public protocol PhotoAssetObject {
    static func fetchObject(_ photoAsset: PhotoAsset, compression: PhotoAsset.Compression?) async throws -> Self
}

@available(iOS 13.0, *)
extension URL: PhotoAssetObject {
    
    public static func fetchObject(
        _ photoAsset: PhotoAsset,
        compression: PhotoAsset.Compression?
    ) async throws -> Self {
        try await withCheckedThrowingContinuation { continuation in
            photoAsset.getURL(compression: compression) {
                switch $0 {
                case .success(let result):
                    continuation.resume(with: .success(result.url))
                case .failure(let error):
                    continuation.resume(with: .failure(PickerError.urlFetchFaild(error)))
                }
            }
        }
    }
}

@available(iOS 13.0, *)
extension UIImage: PhotoAssetObject {
    
    public static func fetchObject(
        _ photoAsset: PhotoAsset,
        compression: PhotoAsset.Compression?
    ) async throws -> Self {
        try await photoAsset.image(compression?.imageCompressionQuality) as! Self
    }
}

@available(iOS 13.0, *)
extension AssetURLResult: PhotoAssetObject {
    public static func fetchObject(
        _ photoAsset: PhotoAsset,
        compression: PhotoAsset.Compression?
    ) async throws -> Self {
        try await withCheckedThrowingContinuation { continuation in
            photoAsset.getURL(compression: compression) {
                switch $0 {
                case .success(let reuslt):
                    continuation.resume(with: .success(reuslt))
                case .failure(let error):
                    continuation.resume(with: .failure(PickerError.urlResultFetchFaild(error)))
                }
            }
        }
    }
}

@available(iOS 13.0, *)
extension PhotoAsset {
    
    /// - Parameter compression: 压缩参数
    public func image(_ compression: PhotoAsset.Compression? = nil) async throws -> UIImage {
        try await .fetchObject(self, compression: compression)
    }
    
    /// PhotoManager.shared.isConverHEICToPNG = true 内部自动将HEIC格式转换成PNG格式
    public func url(_ compression: PhotoAsset.Compression? = nil) async throws -> URL {
        try await .fetchObject(self, compression: compression)
    }
    
    /// PhotoManager.shared.isConverHEICToPNG = true 内部自动将HEIC格式转换成PNG格式
    public func urlResult(_ compression: PhotoAsset.Compression? = nil) async throws -> AssetURLResult {
        try await .fetchObject(self, compression: compression)
    }
    
    /// PhotoManager.shared.isConverHEICToPNG = true 内部自动将HEIC格式转换成PNG格式
    public func object<T: PhotoAssetObject>(_ compression: PhotoAsset.Compression? = nil) async throws -> T {
        try await T.fetchObject(self, compression: compression)
    }
    
    fileprivate func image(_ compressionQuality: CGFloat?) async throws -> UIImage {
       try await withCheckedThrowingContinuation { continuation in
           getImage(compressionQuality: compressionQuality) { image in
               if let image = image {
                   continuation.resume(with: .success(image))
               }else {
                   continuation.resume(with: .failure(PickerError.imageFetchFaild))
               }
           }
       }
   }
}
