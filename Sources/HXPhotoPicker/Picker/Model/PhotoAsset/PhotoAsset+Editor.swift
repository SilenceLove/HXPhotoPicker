//
//  PhotoAsset+Editor.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/8/25.
//

import UIKit

extension PhotoAsset {
    #if HXPICKER_ENABLE_EDITOR
    func getEditedImageData() -> Data? {
        if let photoEdit = photoEditedResult {
            return try? Data(contentsOf: photoEdit.url)
        }
        if let videoEdit = videoEditedResult {
            return PhotoTools.getImageData(for: videoEdit.coverImage)
        }
        return nil
    }
    func getEditedImage() -> UIImage? {
        if let photoEdit = photoEditedResult {
            return .init(contentsOfFile: photoEdit.url.path)
        }
        if let videoEdit = videoEditedResult {
            return videoEdit.coverImage
        }
        return nil
    }
    func getEditedImageURL(
        toFile fileURL: URL? = nil,
        compressionQuality: CGFloat? = nil,
        resultHandler: @escaping AssetURLCompletion
    ) {
        func result(_ result: Result<AssetURLResult, AssetError>) {
            DispatchQueue.main.async {
                resultHandler(result)
            }
        }
        if let photoEdit = photoEditedResult {
            func completion(_ imageURL: URL) {
                let url: URL
                if let fileURL = fileURL {
                    if PhotoTools.copyFile(
                        at: imageURL,
                        to: fileURL
                    ) {
                        url = fileURL
                    }else {
                        result(.failure(.fileWriteFailed))
                        return
                    }
                }else {
                    url = imageURL
                }
                result(.success(
                    .init(
                        url: url, urlType: .local, mediaType: .photo
                    ))
                )
            }
            let imageURL = photoEdit.url
            if let compressionQuality = compressionQuality,
               photoEdit.imageType != .gif {
                DispatchQueue.global().async {
                    guard let imageData = try? Data(contentsOf: imageURL) else {
                        result(.failure(.imageCompressionFailed))
                        return
                    }
                    if let data = PhotoTools.imageCompress(
                        imageData,
                        compressionQuality: compressionQuality 
                    ),
                        let url = PhotoTools.write(
                        toFile: fileURL,
                        imageData: data
                    ) {
                        completion(url)
                    }else {
                        result(.failure(.imageCompressionFailed))
                    }
                }
            }else {
                completion(imageURL)
            }
        }else if let videoEdit = videoEditedResult {
            DispatchQueue.global().async {
                let imageData = PhotoTools.getImageData(
                    for: videoEdit.coverImage
                )
                if let imageData = imageData,
                   let imageURL = PhotoTools.write(
                    toFile: fileURL,
                    imageData: imageData
                   ) {
                    DispatchQueue.main.async {
                        resultHandler(
                            .success(
                                .init(
                                    url: imageURL,
                                    urlType: .local,
                                    mediaType: .photo
                                )
                            )
                        )
                    }
                    return
                }
                result(.failure(imageData == nil ? .invalidData : .fileWriteFailed))
            }
        }
    }
    func getEditedVideoURL(
        toFile fileURL: URL? = nil,
        resultHandler: AssetURLCompletion
    ) {
        guard let videoEdit = videoEditedResult else {
            resultHandler(
                .failure(
                    .invalidEditedData
                )
            )
            return
        }
        let url: URL
        if let fileURL = fileURL {
            if PhotoTools.copyFile(at: videoEdit.url, to: fileURL) {
                url = fileURL
            }else {
                resultHandler(
                    .failure(
                        .fileWriteFailed
                    )
                )
                return
            }
        }else {
            url = videoEdit.url
        }
        resultHandler(
            .success(
                .init(
                    url: url,
                    urlType: .network,
                    mediaType: .video
                )
            )
        )
    }
    #endif
}
