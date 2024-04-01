//
//  PhotoAsset+Video.swift
//  HXPhotoPicker
//
//  Created by Silence on 2024/3/27.
//  Copyright © 2024 Silence. All rights reserved.
//

import UIKit
import AVFoundation

extension PhotoAsset {
    func requestAssetVideoURL(
        toFile fileURL: URL? = nil,
        exportParameter: VideoExportParameter? = nil,
        exportSession: ((AVAssetExportSession) -> Void)? = nil,
        resultHandler: @escaping AssetURLCompletion
    ) {
        let toFile = fileURL == nil ? PhotoTools.getVideoTmpURL() : fileURL!
        #if HXPICKER_ENABLE_EDITOR
        if let videoEdit = videoEditedResult {
            if let fileURL = fileURL {
                if PhotoTools.copyFile(at: videoEdit.url, to: fileURL) {
                    resultHandler(.success(.init(url: fileURL, urlType: .local, mediaType: .video)))
                }else {
                    resultHandler(.failure(.fileWriteFailed))
                }
                return
            }
            resultHandler(.success(.init(url: videoEdit.url, urlType: .local, mediaType: .video)))
            return
        }
        #endif
        guard let phAsset = phAsset else {
            resultHandler(.failure(.invalidPHAsset))
            return
        }
        if mediaSubType == .livePhoto {
            if let exportParameter = exportParameter {
                AssetManager.exportVideoURL(
                    forVideo: phAsset,
                    toFile: toFile,
                    exportParameter: exportParameter,
                    exportSession: exportSession
                ) { (result) in
                    switch result {
                    case .success(let videoURL):
                        resultHandler(.success(.init(url: videoURL, urlType: .local, mediaType: .video)))
                    case .failure(let error):
                        resultHandler(.failure(error.error))
                    }
                }
                return
            }
            AssetManager.requestLivePhoto(
                videoURL: phAsset,
                toFile: toFile
            ) {
                switch $0 {
                case .success(let videoURL):
                    resultHandler(.success(.init(url: videoURL, urlType: .local, mediaType: .video)))
                case .failure(let error):
                    resultHandler(.failure(error.assetError))
                }
            }
        }else {
            if mediaType == .photo {
                resultHandler(.failure(.typeError))
                return
            }
            AssetManager.requestVideoURL(
                for: phAsset,
                toFile: toFile,
                exportParameter: exportParameter,
                exportSession: exportSession
            ) { (result) in
                switch result {
                case .success(let videoURL):
                    resultHandler(.success(.init(url: videoURL, urlType: .local, mediaType: .video)))
                case .failure(let error):
                    resultHandler(.failure(error))
                }
            }
        }
    }
    
    func getVideoCoverURL(
        toFile fileURL: URL? = nil,
        resultHandler: @escaping AssetURLCompletion
    ) {
        let coverURL = fileURL ?? PhotoTools.getImageTmpURL(.jpg)
        requestImageData { _, result in
            switch result {
            case .success(let dataResult):
                let imageData = dataResult.imageData
                DispatchQueue.global().async {
                    if let imageURL = PhotoTools.write(
                        toFile: coverURL,
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
                    }else {
                        DispatchQueue.main.async {
                            resultHandler(.failure(.fileWriteFailed))
                        }
                    }
                }
            case .failure(let error):
                resultHandler(.failure(error))
            }
        }
    }
    
    func updateVideoDuration(_ duration: TimeInterval) {
        pVideoDuration = duration
        pVideoTime = PhotoTools.transformVideoDurationToString(duration: duration)
    }
     
}
