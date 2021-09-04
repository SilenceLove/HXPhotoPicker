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
        resultHandler: @escaping AssetURLCompletion
    ) {
        if let photoEdit = photoEdit {
            let url: URL
            if let fileURL = fileURL {
                if PhotoTools.copyFile(
                    at: photoEdit.editedImageURL,
                    to: fileURL
                ) {
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
                url = photoEdit.editedImageURL
            }
            resultHandler(
                .success(
                    .init(
                        url: url,
                        urlType: .local,
                        mediaType: .photo
                    )
                )
            )
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
                DispatchQueue.main.async {
                    resultHandler(
                        .failure(
                            imageData == nil ? .invalidData : .fileWriteFailed
                        )
                    )
                }
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
