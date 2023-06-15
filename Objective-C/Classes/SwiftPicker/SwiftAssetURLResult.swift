//
//  SwiftAssetURLResult.swift
//  HXPhotoPickerExample
//
//  Created by Silence on 2023/6/14.
//  Copyright © 2023 洪欣. All rights reserved.
//

import UIKit

class SwiftAssetURLResult: NSObject {
    
    @objc
    enum URLType: Int {
        case local
        case network
    }
    
    @objc
    enum MediaType: Int {
        case image
        case video
    }
    
    /// Contents of LivePhoto
    /// LivePhoto包含的内容
    class LivePhoto: NSObject {
        
        @objc
        let imageURL: URL
        @objc
        let imageURLType: URLType
        @objc
        let videoURL: URL
        @objc
        let videoURLType: URLType
        
        @objc
        init(
            imageURL: URL,
            imageURLType: URLType = .local,
            videoURL: URL,
            videoURLType: URLType = .local
        ) {
            self.imageURL = imageURL
            self.imageURLType = imageURLType
            self.videoURL = videoURL
            self.videoURLType = videoURLType
        }
    }
    @objc
    let url: URL
    @objc
    let urlType: URLType
    @objc
    let mediaType: MediaType
    
    /// LivePhoto里包含的资源
    /// selectOptions 需包含 livePhoto
    @objc
    let livePhoto: LivePhoto?
    
    @objc
    init(
        url: URL,
        urlType: URLType,
        mediaType: MediaType,
        livePhoto: LivePhoto? = nil
    ) {
        self.url = url
        self.urlType = urlType
        self.mediaType = mediaType
        self.livePhoto = livePhoto
    }
}
