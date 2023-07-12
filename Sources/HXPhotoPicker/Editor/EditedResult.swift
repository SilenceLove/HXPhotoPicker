//
//  EditedResult.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/26.
//

import UIKit
import AVFoundation
 
public enum EditedResult {
    case image(ImageEditedResult, ImageEditedData)
    case video(VideoEditedResult, VideoEditedData)
    
    /// edited url
    /// 编辑后的地址
    public var url: URL {
        switch self {
        case .image(let imageEditedResult, _):
            return imageEditedResult.url
        case .video(let videoEditedResult, _):
            return videoEditedResult.url
        }
    }
    
    public var image: UIImage? {
        switch self {
        case .image(let imageEditedResult, _):
            return imageEditedResult.image
        case .video(let videoEditedResult, _):
            return videoEditedResult.coverImage
        }
    }
}

public struct ImageEditedData: Codable {
    
    /// Last filter parameters
    /// The corresponding filter will be obtained internally through the delegate
    /// 上一次滤镜参数
    /// 内部会通过 delegate 来获取对应的滤镜
    let filter: PhotoEditorFilter?
    
    /// Screen Adjustment Parameters
    /// 画面调整参数
    let filterEdit: EditorFilterEditFator?
    
    /// clipping parameters
    /// 裁剪参数
    let cropSize: EditorCropSizeFator?
    
    public init(
        filter: PhotoEditorFilter? = nil,
        filterEdit: EditorFilterEditFator? = nil,
        cropSize: EditorCropSizeFator?
    ) {
        self.filter = filter
        self.filterEdit = filterEdit
        self.cropSize = cropSize
    }
}

public struct VideoEditedData {
    
    /// audio parameters
    /// 音频参数
    public let music: VideoEditedMusic?
    
    /// Clipping Duration Parameters
    /// 裁剪时长参数
    public let cropTime: EditorVideoCropTime?
    
    /// Screen Adjustment Parameters
    /// 画面调整参数
    let filterEdit: EditorFilterEditFator?
    
    /// last filter effect
    /// The corresponding filter will be obtained internally through the delegate
    /// 上一次滤镜效果
    /// 内部会通过 delegate 来获取对应的滤镜
    let filter: VideoEditorFilter?
    
    /// clipping parameters
    /// 裁剪参数
    let cropSize: EditorCropSizeFator?
    
    public init(
        music: VideoEditedMusic? = nil,
        filterEdit: EditorFilterEditFator? = nil,
        filter: VideoEditorFilter? = nil,
        cropSize: EditorCropSizeFator? = nil
    ) {
        self.music = music
        self.filterEdit = filterEdit
        self.filter = filter
        self.cropSize = cropSize
        cropTime = nil
    }
    
    init(
        music: VideoEditedMusic?,
        cropTime: EditorVideoCropTime?,
        filterEdit: EditorFilterEditFator?,
        filter: VideoEditorFilter?,
        cropSize: EditorCropSizeFator?
    ) {
        self.music = music
        self.cropTime = cropTime
        self.filterEdit = filterEdit
        self.filter = filter
        self.cropSize = cropSize
    }
}

public struct VideoEditedMusic: Codable {
    
    /// Whether to include the original video audio
    /// 是否包含原视频音频
    public let hasOriginalSound: Bool
    
    /// Original video volume
    /// 原视频音量
    public let videoSoundVolume: Float
    
    /// background music url
    /// 背景音乐地址
    public let backgroundMusicURL: VideoEditorMusicURL?
    
    /// 背景音乐音量
    public let backgroundMusicVolume: Float
    
    let musicIdentifier: String?
    
    /// Soundtrack parameters
    /// 配乐参数
    let music: VideoEditorMusic?
    
    public init(
        hasOriginalSound: Bool,
        videoSoundVolume: Float,
        backgroundMusicURL: VideoEditorMusicURL?,
        backgroundMusicVolume: Float,
        musicIdentifier: String?,
        music: VideoEditorMusic?
    ) {
        self.hasOriginalSound = hasOriginalSound
        self.videoSoundVolume = videoSoundVolume
        self.backgroundMusicURL = backgroundMusicURL
        self.backgroundMusicVolume = backgroundMusicVolume
        self.musicIdentifier = musicIdentifier
        self.music = music
    }
}

public struct EditorVideoCropTime: Codable {
    
    /// Edit start time
    /// 编辑的开始时间
    public let startTime: TimeInterval
    
    /// edit end time
    /// 编辑的结束时间
    public let endTime: TimeInterval
    
    public let preferredTimescale: Int32
    
    let controlInfo: EditorVideoControlInfo
}
