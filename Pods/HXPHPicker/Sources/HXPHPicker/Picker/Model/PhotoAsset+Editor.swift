//
//  PhotoAsset+Editor.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/25.
//

import UIKit

extension PhotoAsset {
    #if HXPICKER_ENABLE_EDITOR
    func getEditedImageData() -> Data? {
        if let photoEdit = photoEdit {
            return try? Data(contentsOf: photoEdit.editedImageURL)
        }
        if let videoEdit = videoEdit {
            return PhotoTools.getImageData(for: videoEdit.coverImage)
        }
        return nil
    }
    func getEditedImage() -> UIImage? {
        if let photoEdit = photoEdit {
            return photoEdit.editedImage
        }
        if let videoEdit = videoEdit {
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
            if DispatchQueue.isMain {
                resultHandler(result)
            }else {
                DispatchQueue.main.async {
                    resultHandler(result)
                }
            }
        }
        if let photoEdit = photoEdit {
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
            let imageURL = photoEdit.editedImageURL
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
        }else if let videoEdit = videoEdit {
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
        guard let videoEdit = videoEdit else {
            resultHandler(
                .failure(
                    .invalidEditedData
                )
            )
            return
        }
        let url: URL
        if let fileURL = fileURL {
            if PhotoTools.copyFile(at: videoEdit.editedURL, to: fileURL) {
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
            url = videoEdit.editedURL
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
