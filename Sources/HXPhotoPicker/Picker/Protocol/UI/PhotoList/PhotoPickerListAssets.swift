//
//  PhotoPickerListAssets.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/10/11.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit

public protocol PhotoPickerListAssets {
    var filterOptions: PhotoPickerFilterSection.Options { get set }
    var assetResult: PhotoFetchAssetResult { get set }
    var assets: [PhotoAsset] { get set }
    var photoCount: Int { get set }
    var videoCount: Int { get set }
}

public protocol PhotoPickerListFetchAssets: PhotoPickerListAssets, PhotoPickerListCondition {
    func getAsset(for index: Int) -> PhotoAsset
}

public extension PhotoPickerListFetchAssets {
    func getAsset(for index: Int) -> PhotoAsset {
        let photoAsset: PhotoAsset
        if needOffset {
            photoAsset = assets[index - offsetIndex]
        }else {
            photoAsset = assets[index]
        }
        return photoAsset
    }
}
