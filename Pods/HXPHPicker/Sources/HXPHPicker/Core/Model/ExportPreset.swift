//
//  ExportPreset.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/18.
//

import UIKit
import AVKit

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
