//
//  VideoEditResult.swift
//  HXPHPicker
//
//  Created by Slience on 2021/3/8.
//

import UIKit
import AVFoundation

public struct VideoEditResult {
    
    /// 编辑后的视频地址
    public let editedURL: URL
    
    /// 编辑后的视频封面
    public let coverImage: UIImage?

    /// 编辑后的视频大小
    public let editedFileSize: Int
    
    /// 视频时长 格式：00:00
    public let videoTime: String
    
    /// 视频时长 秒
    public let videoDuration: TimeInterval
    
    /// 裁剪数据
    public let cropData: VideoCropData
    
    public init(editedURL: URL,
                cropData: VideoCropData) {
        editedFileSize = editedURL.fileSize
        
        videoDuration = PhotoTools.getVideoDuration(videoURL: editedURL)
        videoTime = PhotoTools.transformVideoDurationToString(duration: videoDuration)
        coverImage = PhotoTools.getVideoThumbnailImage(videoURL: editedURL, atTime: 0.1)
        self.editedURL = editedURL
        self.cropData = cropData
    }
}

public struct VideoCropData {
    
    /// 编辑的开始时间
    public let startTime: TimeInterval
    
    /// 编辑的结束时间
    public let endTime: TimeInterval
    
    public let preferredTimescale: Int32
    
    /// 已经确定的裁剪数据
    /// 0：offsetX ，CollectionView的offset.x
    /// 1：validX ，裁剪框的x
    /// 2：validWidth ，裁剪框的宽度
    public let cropingData: (CGFloat, CGFloat, CGFloat)
    
    /// 裁剪框的位置大小比例
    /// 0：offsetX ，CollectionView的offset.x
    /// 1：validX ，裁剪框的x
    /// 2：validWidth ，裁剪框的宽度
    public let cropRectData: (CGFloat, CGFloat, CGFloat)
    
    public init(startTime: TimeInterval,
                endTime: TimeInterval,
                preferredTimescale: Int32,
                cropingData: (CGFloat, CGFloat, CGFloat),
                cropRectData: (CGFloat, CGFloat, CGFloat)) {
        self.startTime = startTime
        self.endTime = endTime
        self.preferredTimescale = preferredTimescale
        self.cropingData = cropingData
        self.cropRectData = cropRectData
    }
}
