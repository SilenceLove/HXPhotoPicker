//
//  AssetResult.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/9/9.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit

public struct AssetResult {
    public let image: UIImage
    public var url: URL { urlReuslt.url }
    public let urlReuslt: AssetURLResult
    public let photoAsset: PhotoAsset
    
    public init(image: UIImage, urlReuslt: AssetURLResult, photoAsset: PhotoAsset) {
        self.image = image
        self.urlReuslt = urlReuslt
        self.photoAsset = photoAsset
    }
}

@available(iOS 13.0, *)
extension AssetResult: PhotoAssetObject {
    
    public static func fetchObject(
        _ photoAsset: PhotoAsset,
        toFile fileConfig: PhotoAsset.FileConfig?,
        compression: PhotoAsset.Compression?
    ) async throws -> Self {
        try await withCheckedThrowingContinuation { continuation in
            photoAsset.getAssetResult(toFile: fileConfig, compression: compression) {
                switch $0 {
                case .success(let result):
                    continuation.resume(with: .success(result))
                case .failure(let error):
                    continuation.resume(with: .failure(error))
                }
            }
        }
    }
}
