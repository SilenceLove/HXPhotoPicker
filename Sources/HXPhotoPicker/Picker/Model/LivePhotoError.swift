//
//  LivePhotoError.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/1/7.
//

import Foundation

public enum LivePhotoError: Error {
    case imageError(AssetError)
    case videoError(AssetError)
    case allError(AssetError)
    
    var assetError: AssetError {
        switch self {
        case .imageError(let error):
            return error
        case .videoError(let error):
            return error
        case .allError(let error):
            return error
        }
    }
}
