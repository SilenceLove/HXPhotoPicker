//
//  VideoEditedResult.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/26.
//

import UIKit

public struct VideoEditedResult {
    
    /// 编辑后的视频地址
    public var url: URL {
        urlConfig.url
    }
    
    public let urlConfig: EditorURLConfig
    
    /// 编辑后的视频封面
    public let coverImage: UIImage?

    /// 编辑后的视频大小
    public let fileSize: Int
    
    /// 视频时长 格式：00:00
    public let videoTime: String
    
    /// 视频时长 秒
    public let videoDuration: TimeInterval
    
    /// 编辑视图的状态
    public let data: EditAdjustmentData?
    
    public init(data: EditAdjustmentData? = nil) {
        self.data = data
        urlConfig = .empty
        coverImage = nil
        fileSize = 0
        videoTime = "00:00"
        videoDuration = 0
    }
    
    init(
        urlConfig: EditorURLConfig,
        coverImage: UIImage?,
        fileSize: Int,
        videoTime: String,
        videoDuration: TimeInterval,
        data: EditAdjustmentData?
    ) {
        self.urlConfig = urlConfig
        self.coverImage = coverImage
        self.fileSize = fileSize
        self.videoTime = videoTime
        self.videoDuration = videoDuration
        self.data = data
    }
}
