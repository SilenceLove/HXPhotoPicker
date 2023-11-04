//
//  PhotoPickerDataStatus.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/10/22.
//  Copyright © 2023 Silence. All rights reserved.
//

import Foundation

public protocol PhotoPickerDataStatus {
    func selectedAssetDidChanged(_ photoAssets: [PhotoAsset])
}
