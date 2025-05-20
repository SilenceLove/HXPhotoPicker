//
//  EditorAsset.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/17.
//

import UIKit
import AVFoundation

public struct EditorAsset {
    
    /// edit object
    /// 编辑对象
    public let type: AssetType
    
    /// edit result
    /// 编辑结果
    public var result: EditedResult?
    
    public var url: URL? { result?.url }
    
    public var image: UIImage? { result?.image }
    
    public init(type: AssetType, result: EditedResult? = nil) {
        self.type = type
        self.result = result
    }
}

extension EditorAsset {
    public enum AssetType {
        case image(UIImage)
        case imageData(Data)
        case video(URL)
        case videoAsset(AVAsset)
        case networkVideo(URL)
        case networkImage(URL)
        #if HXPICKER_ENABLE_PICKER
        case photoAsset(PhotoAsset)
        
        public var photoAsset: PhotoAsset? {
            switch self {
            case .photoAsset(let photoAsset):
                return photoAsset
            default:
                return nil
            }
        }
        #endif
         
        public var image: UIImage? {
            switch self {
            case .image(let image):
                return image
            default:
                return nil
            }
        }
        
        public var videoURL: URL? {
            switch self {
            case .video(let url):
                return url
            default:
                return nil
            }
        }
        
        public var networkVideoURL: URL? {
            switch self {
            case .networkVideo(let url):
                return url
            default:
                return nil
            }
        }
        
        public var networkImageURL: URL? {
            switch self {
            case .networkImage(let url):
                return url
            default:
                return nil
            }
        }
        
        public var contentType: EditorContentViewType {
            switch self {
            case .image, .imageData:
                return .image
            case .networkImage:
                return .image
            case .video, .networkVideo, .videoAsset:
                return .video
            #if HXPICKER_ENABLE_PICKER
            case .photoAsset(let asset):
                if asset.mediaType == .photo {
                    return .image
                }
                return .video
            #endif
            }
        }
    }
    
    public var contentType: EditorContentViewType {
        type.contentType
    }
}
