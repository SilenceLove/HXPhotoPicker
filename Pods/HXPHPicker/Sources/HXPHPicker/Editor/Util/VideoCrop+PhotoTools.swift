//
//  VideoCrop+PhotoTools.swift
//  HXPHPicker
//
//  Created by Slience on 2022/1/11.
//

import UIKit
import AVKit
import VideoToolbox

extension PhotoTools {
    
    static func videoLayerInstructionFixed(
        videoComposition: AVMutableVideoComposition,
        videoLayerInstruction: AVMutableVideoCompositionLayerInstruction,
        cropOrientation: UIImage.Orientation,
        cropRect: CGRect
    ) -> AVMutableVideoCompositionLayerInstruction {
        let videoSize = videoComposition.renderSize
        let renderRect = cropRect
        var renderSize = renderRect.size
        // https://stackoverflow.com/a/45013962
        renderSize = CGSize(
            width: floor(renderSize.width / 16) * 16,
            height: floor(renderSize.height / 16) * 16
        )
        var trans: CGAffineTransform
        switch cropOrientation {
        case .upMirrored:
            trans = .init(translationX: videoSize.width, y: 0)
            trans = trans.scaledBy(x: -1, y: 1)
        case .left:
            trans = .init(translationX: 0, y: videoSize.width)
            trans = trans.rotated(by: 3 * CGFloat.pi * 0.5)
        case .rightMirrored:
            trans = .init(scaleX: -1, y: 1)
            trans = trans.rotated(by: CGFloat.pi * 0.5)
        case .down:
            trans = .init(translationX: videoSize.width, y: videoSize.height)
            trans = trans.rotated(by: CGFloat.pi)
        case .downMirrored:
            trans = .init(translationX: 0, y: videoSize.height)
            trans = trans.scaledBy(x: 1, y: -1)
        case .right:
            trans = .init(translationX: videoSize.height, y: 0)
            trans = trans.rotated(by: CGFloat.pi * 0.5)
        case .leftMirrored:
            trans = .init(translationX: videoSize.height, y: videoSize.width)
            trans = trans.scaledBy(x: -1, y: 1)
            trans = trans.rotated(by: 3 * CGFloat.pi * 0.5)
        default:
            trans = .identity
        }
//        trans = trans.translatedBy(x: -renderRect.minX, y: -renderRect.minY)
//        videoLayerInstruction.setTransform(trans, at: .zero)
        return videoLayerInstruction
    }
    static func cropOrientation(
        _ cropSizeData: VideoEditorCropSizeData
    ) -> UIImage.Orientation {
        let angle = cropSizeData.angle
        let mirrorType = cropSizeData.mirrorType
        
        var rotate = CGFloat.pi * angle / 180
        if rotate != 0 {
            rotate = CGFloat.pi * 2 + rotate
        }
        let isHorizontal = mirrorType == .horizontal
        if rotate > 0 || isHorizontal {
            let angle = labs(Int(angle))
            switch angle {
            case 0, 360:
                if isHorizontal {
                    // upMirrored
                    return .upMirrored
                }
            case 90:
                if !isHorizontal {
                    // left
                    return .left
                }else {
                    // rightMirrored
                    return .rightMirrored
                }
            case 180:
                if !isHorizontal {
                    // down
                    return .down
                }else {
                    // downMirrored
                    return .downMirrored
                }
            case 270:
                if !isHorizontal {
                    // right
                    return .right
                }else {
                    // leftMirrored
                    return .leftMirrored
                }
            default:
                break
            }
        }
        return .up
    }
}
