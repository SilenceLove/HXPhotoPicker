//
//  Core+PHAssetCollection.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/7.
//

import UIKit
import Photos

extension PHAssetCollection: HXPickerCompatible {
    
    /// 是否相机胶卷
    var isCameraRoll: Bool {
        var versionStr = UIDevice.current.systemVersion.replacingOccurrences(of: ".", with: "")
        if versionStr.count <= 1 {
            versionStr.append("00")
        }else if versionStr.count <= 2 {
            versionStr.append("0")
        }
        let version = Int(versionStr) ?? 0
        if version >= 800 && version <= 802 {
            return assetCollectionSubtype == .smartAlbumRecentlyAdded
        }else {
            return assetCollectionSubtype == .smartAlbumUserLibrary
        }
    }
}

public extension HXPickerWrapper where Base: PHAssetCollection {
    var isCameraRoll: Bool {
        base.isCameraRoll
    }
}
