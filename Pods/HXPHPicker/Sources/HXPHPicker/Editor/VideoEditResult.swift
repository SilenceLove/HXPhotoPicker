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
    
    /// 原视频音量
    public let videoSoundVolume: Float
    
    /// 背景音乐地址
    public let backgroundMusicURL: URL?
    
    /// 背景音乐音量
    public let backgroundMusicVolume: Float
    
    /// 裁剪数据
    public let cropData: VideoCropData?
    
    /// 贴纸数据
    let stickerData: EditorStickerData?
    
    init(
        editedURL: URL,
        cropData: VideoCropData?,
        videoSoundVolume: Float,
        backgroundMusicURL: URL?,
        backgroundMusicVolume: Float,
        stickerData: EditorStickerData?
    ) {
        editedFileSize = editedURL.fileSize
        
        videoDuration = PhotoTools.getVideoDuration(videoURL: editedURL)
        videoTime = PhotoTools.transformVideoDurationToString(duration: videoDuration)
        coverImage = PhotoTools.getVideoThumbnailImage(videoURL: editedURL, atTime: 0.1)
        self.editedURL = editedURL
        self.cropData = cropData
        self.videoSoundVolume = videoSoundVolume
        self.backgroundMusicURL = backgroundMusicURL
        self.backgroundMusicVolume = backgroundMusicVolume
        self.stickerData = stickerData
    }
}

public struct VideoCropData: Codable {
    
    /// 编辑的开始时间
    public let startTime: TimeInterval
    
    /// 编辑的结束时间
    public let endTime: TimeInterval
    
    public let preferredTimescale: Int32
    
    /// 已经确定的裁剪数据
    /// 0：offsetX ，CollectionView的offset.x
    /// 1：validX ，裁剪框的x
    /// 2：validWidth ，裁剪框的宽度
    let cropingData: CropData
    
    /// 裁剪框的位置大小比例
    /// 0：offsetX ，CollectionView的offset.x
    /// 1：validX ，裁剪框的x
    /// 2：validWidth ，裁剪框的宽度
    let cropRectData: CropData
    
    init(
        startTime: TimeInterval,
        endTime: TimeInterval,
        preferredTimescale: Int32,
        cropingData: CropData,
        cropRectData: CropData
    ) {
        self.startTime = startTime
        self.endTime = endTime
        self.preferredTimescale = preferredTimescale
        self.cropingData = cropingData
        self.cropRectData = cropRectData
    }
    
    struct CropData: Codable {
        let offsetX: CGFloat
        let validX: CGFloat
        let validWidth: CGFloat
    }
}

extension VideoEditResult: Codable {
    
    enum CodingKeys: String, CodingKey {
        case editedURL
        case coverImage
        case editedFileSize
        case videoTime
        case videoDuration
        case videoSoundVolume
        case backgroundMusicURL
        case backgroundMusicVolume
        case cropData
        case stickerData
    }
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        editedURL = try container.decode(URL.self, forKey: .editedURL)
        if let coverImageData = try container.decodeIfPresent(Data.self, forKey: .coverImage) {
            coverImage = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(coverImageData) as? UIImage
        }else {
            coverImage = nil
        }
        editedFileSize = try container.decode(Int.self, forKey: .editedFileSize)
        videoTime = try container.decode(String.self, forKey: .videoTime)
        videoDuration = try container.decode(TimeInterval.self, forKey: .videoDuration)
        videoSoundVolume = try container.decode(Float.self, forKey: .videoSoundVolume)
        backgroundMusicURL = try container.decodeIfPresent(URL.self, forKey: .backgroundMusicURL)
        backgroundMusicVolume = try container.decode(Float.self, forKey: .backgroundMusicVolume)
        cropData = try container.decodeIfPresent(VideoCropData.self, forKey: .cropData)
        stickerData = try container.decodeIfPresent(EditorStickerData.self, forKey: .stickerData)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(editedURL, forKey: .editedURL)
        try container.encode(editedFileSize, forKey: .editedFileSize)
        try container.encode(videoTime, forKey: .videoTime)
        try container.encode(videoDuration, forKey: .videoDuration)
        try container.encode(videoSoundVolume, forKey: .videoSoundVolume)
        try container.encode(backgroundMusicURL, forKey: .backgroundMusicURL)
        try container.encode(backgroundMusicVolume, forKey: .backgroundMusicVolume)
        try container.encodeIfPresent(cropData, forKey: .cropData)
        try container.encodeIfPresent(stickerData, forKey: .stickerData)
        
        if let image = coverImage {
            if #available(iOS 11.0, *) {
                let imageData = try NSKeyedArchiver.archivedData(withRootObject: image, requiringSecureCoding: false)
                try container.encodeIfPresent(imageData, forKey: .coverImage)
            } else {
                // Fallback on earlier versions
                let imageData = NSKeyedArchiver.archivedData(withRootObject: image)
                try container.encodeIfPresent(imageData, forKey: .coverImage)
            }
        }
    }
}
