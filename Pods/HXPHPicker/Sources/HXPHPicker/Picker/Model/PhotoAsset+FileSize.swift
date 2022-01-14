//
//  PhotoAsset+FileSize.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/25.
//

import UIKit
import Photos

extension PhotoAsset {
    func requestFileSize(
        result: @escaping (Int, PhotoAsset) -> Void
    ) {
        DispatchQueue.global().async {
            let fileSize = self.getFileSize()
            DispatchQueue.main.async {
                result(fileSize, self)
            }
        }
    }
    func getFileSize() -> Int {
        if let fileSize = pFileSize {
            return fileSize
        }
        let editedSize = getEditedFileSize()
        if editedSize >= 0 {
            return editedSize
        }
        let fileSize: Int
        if phAsset != nil {
            fileSize = getPHAssetFileSize()
        }else {
            fileSize = getLocalFileSize()
        }
        pFileSize = fileSize
        return fileSize
    }
    func getEditedFileSize() -> Int {
        #if HXPICKER_ENABLE_EDITOR
        if photoEdit != nil {
            if let imageData = getLocalImageData() {
                pFileSize = imageData.count
                return imageData.count
            }
            return 0
        }
        if let videoEdit = videoEdit {
            pFileSize = videoEdit.editedFileSize
            return videoEdit.editedFileSize
        }
        #endif
        return -1
    }
    func getPHAssetFileSize() -> Int {
        guard let photoAsset = phAsset else {
            return 0
        }
        var fileSize = 0
        if photoAsset.isImageAnimated && mediaSubType != .imageAnimated {
            if let imageData = PhotoTools.getImageData(for: originalImage) {
                fileSize = imageData.count
            }
            pFileSize = fileSize
            return fileSize
        }
        let assetResources = PHAssetResource.assetResources(for: photoAsset)
        let assetIsLivePhoto = photoAsset.isLivePhoto
        var livePhotoType: PHAssetResourceType = .photo
        var liveVideoType: PHAssetResourceType = .pairedVideo
        for assetResource in assetResources where
            assetResource.type == .adjustmentData {
            livePhotoType = .fullSizePhoto
            liveVideoType = .fullSizePairedVideo
            break
        }
        for assetResource in assetResources {
            if assetIsLivePhoto {
                if mediaSubType != .livePhoto {
                    if assetResource.type == .photo {
                        if let photoFileSize = assetResource.value(forKey: "fileSize") as? Int {
                            fileSize += photoFileSize
                        }
                    }
                }else {
                    switch assetResource.type {
                    case livePhotoType, liveVideoType:
                        if let photoFileSize = assetResource.value(forKey: "fileSize") as? Int {
                            fileSize += photoFileSize
                        }
                    default:
                        break
                    }
                }
            }else {
                if let photoFileSize = assetResource.value(forKey: "fileSize") as? Int {
                    fileSize += photoFileSize
                }
            }
        }
        return fileSize
    }
    func getLocalFileSize() -> Int {
        var fileSize = 0
        if mediaType == .photo {
            #if canImport(Kingfisher)
            if let networkImageAsset = networkImageAsset, fileSize == 0 {
                if networkImageAsset.fileSize > 0 {
                    fileSize = networkImageAsset.fileSize
                    pFileSize = fileSize
                }
                return fileSize
            }
            #endif
            if let livePhoto = localLivePhoto {
                fileSize += PhotoTools.fileSize(atPath: livePhoto.imageURL.path)
                fileSize += PhotoTools.fileSize(atPath: livePhoto.videoURL.path)
                return fileSize
            }
            if let imageData = getLocalImageData() {
                fileSize = imageData.count
            }
        }else {
            if let videoURL = localVideoAsset?.videoURL {
                fileSize = videoURL.fileSize
            }else if let networkVideoAsset = networkVideoAsset {
                if networkVideoAsset.fileSize > 0 {
                    fileSize = networkVideoAsset.fileSize
                }else {
                    let key = networkVideoAsset.videoURL.absoluteString
                    if PhotoTools.isCached(forVideo: key) {
                        let videoURL = PhotoTools.getVideoCacheURL(for: key)
                        fileSize = videoURL.fileSize
                    }
                }
            }
        }
        return fileSize
    }
    func getPFileSize() -> Int? {
        pFileSize
    }
    func updateFileSize(_ fileSize: Int) {
        pFileSize = fileSize
    }
}
