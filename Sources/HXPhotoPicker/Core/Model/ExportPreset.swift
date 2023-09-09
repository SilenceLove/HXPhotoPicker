//
//  ExportPreset.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/8/18.
//

import UIKit
import AVFoundation

public struct VideoExportParameter {
    /// 视频导出的分辨率
    public let preset: ExportPreset
    /// 视频质量 [1 - 10]
    public let quality: Int
    
    /// 设置视频导出参数
    /// - Parameters:
    ///   - exportPreset: 视频导出的分辨率
    ///   - videoQuality: 视频质量 [1 - 10]
    public init(
        preset: ExportPreset,
        quality: Int
    ) {
        self.preset = preset
        self.quality = quality
    }
}

public enum ExportPreset {
    case lowQuality
    case mediumQuality
    case highQuality
    case ratio_640x480
    case ratio_960x540
    case ratio_1280x720
    
    public var name: String {
        switch self {
        case .lowQuality:
            return AVAssetExportPresetLowQuality
        case .mediumQuality:
            return AVAssetExportPresetMediumQuality
        case .highQuality:
            return AVAssetExportPresetHighestQuality
        case .ratio_640x480:
            return AVAssetExportPreset640x480
        case .ratio_960x540:
            return AVAssetExportPreset960x540
        case .ratio_1280x720:
            return AVAssetExportPreset1280x720
        }
    }
}
