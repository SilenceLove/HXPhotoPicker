//
//  EditorType.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/14.
//

import UIKit

public extension EditorController {
    enum EditorType {
        case photo
        case video
    }
    
    enum SourceType {
        /// 本地
        case local
        /// 网络
        case network
        /// 通过picker跳转过来的
        case picker
    }
}

/// 照片编辑控制器的状态
public extension PhotoEditorViewController {
    enum State: Int {
        /// 正常状态
        case normal
        /// 裁剪状态
        case cropping
    }
}

/// 视频编辑控制器的状态
public extension VideoEditorViewController {
    enum State: Int {
        /// 正常状态
        case normal
        /// 裁剪时长状态
        case cropTime
        /// 裁剪尺寸状态
        case cropSize
    }
}

/// 编辑工具
public extension EditorToolOptions {
    enum `Type` {
        /// 涂鸦
        case graffiti
        
        /// 贴图
        case chartlet
        
        /// 文本
        case text
        
        /// photo - 马赛克
        case mosaic
        
        /// photo - 滤镜
        case filter
        
        /// video - 配乐
        case music
        
        /// 尺寸裁剪
        case cropSize
        
        /// video - 时长裁剪
        case cropTime
    }
}

extension EditorToolView {
    
    struct Options: OptionSet {
        static let graffiti = Options(rawValue: 1 << 0)
        static let chartlet = Options(rawValue: 1 << 1)
        static let text = Options(rawValue: 1 << 2)
        static let mosaic = Options(rawValue: 1 << 3)
        static let filter = Options(rawValue: 1 << 4)
        static let music = Options(rawValue: 1 << 5)
        static let cropSize = Options(rawValue: 1 << 6)
        static let cropTime = Options(rawValue: 1 << 6)
        let rawValue: Int
        
        var isSticker: Bool {
            if self.contains(.chartlet) || self.contains(.text) {
                return true
            }
            return false
        }
        init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
}

/// 裁剪时遮罩类型
public extension EditorImageResizerMaskView {
    enum MaskType {
        /// 半透明黑色
        case blackColor
        /// 深色毛玻璃
        case darkBlurEffect
        /// 浅色毛玻璃
        case lightBlurEffect
    }
}

/// 默认宽高比类型
public extension EditorCropSizeConfiguration {
    enum AspectRatioType: Equatable {
        /// 原始宽高比
        case original
        /// 1:1
        case ratio_1x1
        /// 2:3
        case ratio_2x3
        /// 3:2
        case ratio_3x2
        /// 3:4
        case ratio_3x4
        /// 4: 3
        case ratio_4x3
        /// 9:16
        case ratio_9x16
        /// 16:9
        case ratio_16x9
        /// 自定义宽高比
        case custom(CGSize)
    }
}

extension PhotoEditorView {
    enum State {
        case normal
        case cropping
    }
}

extension EditorImageResizerView {
    enum MirrorType: Int, Codable {
        case none
        case horizontal
    }
}

extension VideoEditorConfiguration {
    func mutableCopy() -> Any {
        let config = VideoEditorConfiguration()
        config.exportPreset = exportPreset
        config.videoQuality = videoQuality
        config.defaultState = defaultState
        config.videoExportURL = videoExportURL
        config.mustBeTailored = mustBeTailored
        config.brush = brush
        config.chartlet = chartlet
        config.text = text
        config.music = music
        config.cropTime = cropTime
        config.cropSize = cropSize
        config.cropConfirmView = cropConfirmView
        config.toolView = toolView
        config.filter = filter
        return config
    }
}
