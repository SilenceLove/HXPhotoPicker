//
//  VideoEditor+PhotoTools.swift
//  HXPHPicker
//
//  Created by Slience on 2021/12/2.
//

import UIKit
import AVKit

extension PhotoTools {
    
    /// 导出编辑视频
    /// - Parameters:
    ///   - avAsset: 视频对应的 AVAsset 数据
    ///   - outputURL: 指定视频导出的地址，为nil时默认为临时目录
    ///   - timeRang: 需要裁剪的时间区域，没有传 .zero
    ///   - stickerInfos: 贴纸数组
    ///   - audioURL: 需要添加的音频地址
    ///   - audioVolume: 需要添加的音频音量
    ///   - originalAudioVolume: 视频原始音频音量
    ///   - exportPreset: 导出的分辨率
    ///   - videoQuality: 导出的质量
    ///   - completion: 导出完成
    @discardableResult
    static func exportEditVideo(
        for avAsset: AVAsset,
        outputURL: URL? = nil,
        timeRang: CMTimeRange,
        cropSizeData: VideoEditorCropSizeData,
        audioURL: URL?,
        audioVolume: Float,
        originalAudioVolume: Float,
        exportPreset: ExportPreset,
        videoQuality: Int,
        completion: ((URL?, Error?) -> Void)?
    ) -> AVAssetExportSession? {
        var timeRang = timeRang
        let exportPresets = AVAssetExportSession.exportPresets(compatibleWith: avAsset)
        if exportPresets.contains(exportPreset.name) {
            do {
                guard let videoTrack = avAsset.tracks(withMediaType: .video).first else {
                    throw NSError(domain: "Video track is nil", code: 500, userInfo: nil)
                }
                let videoTotalSeconds = videoTrack.timeRange.duration.seconds
                if timeRang.start.seconds + timeRang.duration.seconds > videoTotalSeconds {
                    timeRang = CMTimeRange(
                        start: timeRang.start,
                        duration: CMTime(
                            seconds: videoTotalSeconds - timeRang.start.seconds,
                            preferredTimescale: timeRang.start.timescale
                        )
                    )
                }
                let videoURL = outputURL ?? PhotoTools.getVideoTmpURL()
                let mixComposition = try mixComposition(
                    for: avAsset,
                    videoTrack: videoTrack
                )
                var addVideoComposition = false
                let animationBeginTime: CFTimeInterval
                if timeRang == .zero {
                    animationBeginTime = AVCoreAnimationBeginTimeAtZero
                }else {
                    animationBeginTime = timeRang.start.seconds == 0 ?
                        AVCoreAnimationBeginTimeAtZero :
                        timeRang.start.seconds
                }
                let videoComposition = try videoComposition(
                    for: avAsset,
                    videoTrack: videoTrack,
                    mixComposition: mixComposition,
                    cropSizeData: cropSizeData,
                    animationBeginTime: animationBeginTime,
                    videoDuration: timeRang == .zero ? videoTrack.timeRange.duration.seconds : timeRang.duration.seconds
                )
                if videoComposition.renderSize.width > 0 {
                    addVideoComposition = true
                }
                let audioMix = try audioMix(
                    for: avAsset,
                    videoTrack: videoTrack,
                    mixComposition: mixComposition,
                    timeRang: timeRang,
                    audioURL: audioURL,
                    audioVolume: audioVolume,
                    originalAudioVolume: originalAudioVolume
                )
                if let exportSession = AVAssetExportSession(
                    asset: mixComposition,
                    presetName: exportPreset.name
                ) {
                    let supportedTypeArray = exportSession.supportedFileTypes
                    exportSession.outputURL = videoURL
                    if supportedTypeArray.contains(AVFileType.mp4) {
                        exportSession.outputFileType = .mp4
                    }else if supportedTypeArray.isEmpty {
                        completion?(nil, PhotoError.error(type: .exportFailed, message: "不支持导出该类型视频"))
                        return nil
                    }else {
                        exportSession.outputFileType = supportedTypeArray.first
                    }
                    exportSession.shouldOptimizeForNetworkUse = true
                    if addVideoComposition {
                        exportSession.videoComposition = videoComposition
                    }
                    if !audioMix.inputParameters.isEmpty {
                        exportSession.audioMix = audioMix
                    }
                    if timeRang != .zero {
                        exportSession.timeRange = timeRang
                    }
                    if videoQuality > 0 {
                        let seconds = timeRang != .zero ? timeRang.duration.seconds : videoTotalSeconds
                        exportSession.fileLengthLimit = exportSessionFileLengthLimit(
                            seconds: seconds,
                            exportPreset: exportPreset,
                            videoQuality: videoQuality
                        )
                    }
                    exportSession.exportAsynchronously(completionHandler: {
                        DispatchQueue.main.async {
                            switch exportSession.status {
                            case .completed:
                                completion?(videoURL, nil)
                            case .failed, .cancelled:
                                completion?(nil, exportSession.error)
                            default: break
                            }
                        }
                    })
                    return exportSession
                }else {
                    completion?(nil, PhotoError.error(type: .exportFailed, message: "不支持导出该类型视频"))
                }
            } catch {
                completion?(nil, PhotoError.error(type: .exportFailed, message: "导出失败：" + error.localizedDescription))
            }
        }else {
            completion?(nil, PhotoError.error(type: .exportFailed, message: "设备不支持导出：" + exportPreset.name))
        }
        return nil
    }
    
    static func mixComposition(
        for videoAsset: AVAsset,
        videoTrack: AVAssetTrack
    ) throws -> AVMutableComposition {
        let mixComposition = AVMutableComposition()
        let videoTimeRange = CMTimeRangeMake(
            start: .zero,
            duration: videoTrack.timeRange.duration
        )
        let compositionVideoTrack = mixComposition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        )
        compositionVideoTrack?.preferredTransform = videoTrack.preferredTransform
        try compositionVideoTrack?.insertTimeRange(
            videoTimeRange,
            of: videoTrack,
            at: .zero
        )
        return mixComposition
    }
    
    static func audioMix(
        for videoAsset: AVAsset,
        videoTrack: AVAssetTrack,
        mixComposition: AVMutableComposition,
        timeRang: CMTimeRange,
        audioURL: URL?,
        audioVolume: Float,
        originalAudioVolume: Float
    ) throws -> AVMutableAudioMix {
        let duration = videoTrack.timeRange.duration
        let videoTimeRange = CMTimeRangeMake(
            start: .zero,
            duration: duration
        )
        let audioMix = AVMutableAudioMix()
        var newAudioInputParams: AVMutableAudioMixInputParameters?
        if let audioURL = audioURL {
            // 添加背景音乐
            let audioAsset = AVURLAsset(
                url: audioURL
            )
            let newAudioTrack = mixComposition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid
            )
            if let audioTrack = audioAsset.tracks(withMediaType: .audio).first {
                newAudioTrack?.preferredTransform = audioTrack.preferredTransform
                let audioDuration = audioAsset.duration.seconds
                let videoDuration: Double
                let startTime: Double
                if timeRang == .zero {
                    startTime = 0
                    videoDuration = duration.seconds
                }else {
                    startTime = timeRang.start.seconds
                    videoDuration = timeRang.duration.seconds
                }
                if audioDuration < videoDuration {
                    let audioTimeRange = CMTimeRangeMake(
                        start: .zero,
                        duration: audioTrack.timeRange.duration
                    )
                    let divisor = Int(videoDuration / audioDuration)
                    var atTime = CMTimeMakeWithSeconds(
                        startTime,
                        preferredTimescale: audioAsset.duration.timescale
                    )
                    for index in 0..<divisor {
                        try newAudioTrack?.insertTimeRange(
                            audioTimeRange,
                            of: audioTrack,
                            at: atTime
                        )
                        atTime = CMTimeMakeWithSeconds(
                            startTime + Double(index + 1) * audioDuration,
                            preferredTimescale: audioAsset.duration.timescale
                        )
                    }
                    let remainder = videoDuration.truncatingRemainder(
                        dividingBy: audioDuration
                    )
                    if remainder > 0 {
                        let seconds = videoDuration - audioDuration * Double(divisor)
                        try newAudioTrack?.insertTimeRange(
                            CMTimeRange(
                                start: .zero,
                                duration: CMTimeMakeWithSeconds(
                                    seconds,
                                    preferredTimescale: audioAsset.duration.timescale
                                )
                            ),
                            of: audioTrack,
                            at: atTime
                        )
                    }
                }else {
                    let audioTimeRange: CMTimeRange
                    let atTime: CMTime
                    if timeRang != .zero {
                        audioTimeRange = CMTimeRangeMake(
                            start: .zero,
                            duration: timeRang.duration
                        )
                        atTime = timeRang.start
                    }else {
                        audioTimeRange = CMTimeRangeMake(
                            start: .zero,
                            duration: videoTimeRange.duration
                        )
                        atTime = .zero
                    }
                    try newAudioTrack?.insertTimeRange(
                        audioTimeRange,
                        of: audioTrack,
                        at: atTime
                    )
                }
            }
            newAudioInputParams = AVMutableAudioMixInputParameters(
                track: newAudioTrack
            )
            newAudioInputParams?.setVolumeRamp(
                fromStartVolume: audioVolume,
                toEndVolume: audioVolume,
                timeRange: CMTimeRangeMake(
                    start: .zero,
                    duration: duration
                )
            )
            newAudioInputParams?.trackID =  newAudioTrack?.trackID ?? kCMPersistentTrackID_Invalid
        }
        
        if let audioTrack = videoAsset.tracks(withMediaType: .audio).first,
           let originalVoiceTrack = mixComposition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) {
            originalVoiceTrack.preferredTransform = audioTrack.preferredTransform
            try originalVoiceTrack.insertTimeRange(videoTimeRange, of: audioTrack, at: .zero)
            let volume: Float = originalAudioVolume
            let originalAudioInputParams = AVMutableAudioMixInputParameters(track: originalVoiceTrack)
            originalAudioInputParams.setVolumeRamp(
                fromStartVolume: volume,
                toEndVolume: volume,
                timeRange: CMTimeRangeMake(
                    start: .zero,
                    duration: duration
                )
            )
            originalAudioInputParams.trackID = originalVoiceTrack.trackID
            if let newAudioInputParams = newAudioInputParams {
                audioMix.inputParameters = [newAudioInputParams, originalAudioInputParams]
            }else {
                audioMix.inputParameters = [originalAudioInputParams]
            }
        }else {
            if let newAudioInputParams = newAudioInputParams {
                audioMix.inputParameters = [newAudioInputParams]
            }
        }
        return audioMix
    }
    static func videoComposition(
        for videoAsset: AVAsset,
        videoTrack: AVAssetTrack,
        mixComposition: AVMutableComposition,
        cropSizeData: VideoEditorCropSizeData,
        animationBeginTime: CFTimeInterval,
        videoDuration: TimeInterval
    ) throws -> AVMutableVideoComposition {
        let videoComposition = videoFixed(
            composition: mixComposition,
            assetOrientation: videoAsset.videoOrientation
        )
        let renderSize = videoComposition.renderSize
        cropVideoSize(videoComposition, cropSizeData)
        let overlaySize = videoComposition.renderSize
        videoComposition.customVideoCompositorClass = VideoFilterCompositor.self
        // https://stackoverflow.com/a/45013962
//        renderSize = CGSize(
//            width: floor(renderSize.width / 16) * 16,
//            height: floor(renderSize.height / 16) * 16
//        )
        let stickerInfos = cropSizeData.stickerInfos
        var drawImage: UIImage?
        if let image = cropSizeData.drawLayer?.convertedToImage() {
            cropSizeData.drawLayer?.contents = nil
            drawImage = image
        }
        var watermarkLayerTrackID: CMPersistentTrackID?
        if !stickerInfos.isEmpty || drawImage != nil {
            let bounds = CGRect(origin: .zero, size: renderSize)
            let overlaylayer = CALayer()
            let bgLayer = CALayer()
            if let drawImage = drawImage {
                let drawLayer = CALayer()
                drawLayer.contents = drawImage.cgImage
                drawLayer.frame = bounds
                drawLayer.contentsScale = UIScreen.main.scale
                bgLayer.addSublayer(drawLayer)
            }
            for info in stickerInfos {
                let center = CGPoint(
                    x: info.centerScale.x * bounds.width,
                    y: info.centerScale.y * bounds.height
                )
                let size = CGSize(
                    width: info.sizeScale.width * bounds.width,
                    height: info.sizeScale.height * bounds.height
                )
                let transform = stickerLayerOrientation(cropSizeData, info)
                if let music = info.music,
                   let subMusic = music.music {
                    let textLayer = textAnimationLayer(
                        music: subMusic,
                        size: size,
                        fontSize: music.fontSizeScale * bounds.width,
                        animationScale: bounds.width / info.viewSize.width,
                        animationSize: CGSize(
                            width: music.animationSizeScale.width * bounds.width,
                            height: music.animationSizeScale.height * bounds.height
                        ),
                        beginTime: animationBeginTime,
                        videoDuration: videoDuration
                    )
                    textLayer.frame = CGRect(origin: .zero, size: size)
                    textLayer.position = center
                    bgLayer.addSublayer(textLayer)
                    textLayer.transform = transform
                }else {
                    let imageLayer = animationLayer(
                        image: info.image,
                        beginTime: animationBeginTime,
                        videoDuration: videoDuration
                    )
                    imageLayer.frame = CGRect(origin: .zero, size: size)
                    imageLayer.position = center
                    imageLayer.shadowOpacity = 0.4
                    imageLayer.shadowOffset = CGSize(width: 0, height: -1)
                    bgLayer.addSublayer(imageLayer)
                    imageLayer.transform = transform
                }
            }
            if cropSizeData.canReset {
                let contentLayer = CALayer()
                let width = renderSize.width * cropSizeData.cropRect.width
                let height = renderSize.height * cropSizeData.cropRect.height
                let x = renderSize.width * cropSizeData.cropRect.minX
                let y = renderSize.height * cropSizeData.cropRect.minY
                bgLayer.frame = .init(
                    x: -x, y: -y,
                    width: bounds.width, height: bounds.height
                )
                contentLayer.addSublayer(bgLayer)
                contentLayer.frame = .init(
                    x: -(width - overlaySize.width) * 0.5,
                    y: -(height - overlaySize.height) * 0.5,
                    width: width, height: height
                )
                overlaylayer.addSublayer(contentLayer)
                layerOrientation(contentLayer, cropSizeData)
            }else {
                bgLayer.frame = bounds
                overlaylayer.addSublayer(bgLayer)
            }
            overlaylayer.isGeometryFlipped = true
            overlaylayer.frame = .init(origin: .zero, size: overlaySize)
            
            let trackID = videoAsset.unusedTrackID()
            videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
                additionalLayer: overlaylayer,
                asTrackID: trackID
            )
            watermarkLayerTrackID = trackID
        }
        var newInstructions: [AVVideoCompositionInstructionProtocol] = []
        
        for instruction in videoComposition.instructions where instruction is AVVideoCompositionInstruction {
            let videoInstruction = instruction as! AVVideoCompositionInstruction
            let layerInstructions = videoInstruction.layerInstructions
            var sourceTrackIDs: [NSValue] = []
            for layerInstruction in layerInstructions {
                sourceTrackIDs.append(layerInstruction.trackID as NSValue)
            }
            let newInstruction = CustomVideoCompositionInstruction(
                sourceTrackIDs: sourceTrackIDs,
                watermarkTrackID: watermarkLayerTrackID,
                timeRange: instruction.timeRange,
                videoOrientation: videoAsset.videoOrientation,
                cropSizeData: cropSizeData.canReset ? cropSizeData : nil,
                filterInfo: cropSizeData.filter,
                filterValue: cropSizeData.filterValue
            )
            newInstructions.append(newInstruction)
        }
        if newInstructions.isEmpty {
            var sourceTrackIDs: [NSValue] = []
            sourceTrackIDs.append(videoTrack.trackID as NSValue)
            let newInstruction = CustomVideoCompositionInstruction(
                sourceTrackIDs: sourceTrackIDs,
                watermarkTrackID: watermarkLayerTrackID,
                timeRange: videoTrack.timeRange,
                videoOrientation: videoAsset.videoOrientation,
                cropSizeData: cropSizeData.canReset ? cropSizeData : nil,
                filterInfo: cropSizeData.filter,
                filterValue: cropSizeData.filterValue
            )
            newInstructions.append(newInstruction)
        }
        videoComposition.instructions = newInstructions
        videoComposition.renderScale = 1
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        return videoComposition
    }
    static func cropVideoSize(
        _ videoComposition: AVMutableVideoComposition,
        _ cropSizeData: VideoEditorCropSizeData
    ) {
        if !cropSizeData.canReset {
            return
        }
        let width = videoComposition.renderSize.width * cropSizeData.cropRect.width
        let height = videoComposition.renderSize.height * cropSizeData.cropRect.height
        let orientation = cropOrientation(cropSizeData)
        switch orientation {
        case .up, .upMirrored, .down, .downMirrored:
            videoComposition.renderSize = .init(width: width, height: height)
        default:
            videoComposition.renderSize = .init(width: height, height: width)
        }
    }
    private static func layerOrientation(
        _ layer: CALayer,
        _ cropSizeData: VideoEditorCropSizeData
    ) {
        if cropSizeData.canReset {
            let orientation = cropOrientation(cropSizeData)
            switch orientation {
            case .upMirrored:
                layer.transform = CATransform3DMakeScale(-1, 1, 1)
            case .left:
                layer.transform = CATransform3DMakeRotation(-CGFloat.pi * 0.5, 0, 0, 1)
            case .leftMirrored:
                var transform = CATransform3DMakeScale(-1, 1, 1)
                transform = CATransform3DRotate(transform, -CGFloat.pi * 0.5, 0, 0, 1)
                layer.transform = transform
            case .right:
                layer.transform = CATransform3DMakeRotation(CGFloat.pi * 0.5, 0, 0, 1)
            case .rightMirrored:
                var transform = CATransform3DMakeRotation(CGFloat.pi * 0.5, 0, 0, 1)
                transform = CATransform3DScale(transform, 1, -1, 1)
                layer.transform = transform
            case .down:
                layer.transform = CATransform3DMakeRotation(CGFloat.pi, 0, 0, 1)
            case .downMirrored:
                layer.transform = CATransform3DMakeScale(1, -1, 1)
            default:
                break
            }
        }
    }
    private static func stickerLayerOrientation(
        _ cropSizeData: VideoEditorCropSizeData,
        _ info: EditorStickerInfo
    ) -> CATransform3D {
        var transform: CATransform3D
        switch stickerOrientation(info) {
        case .upMirrored:
            transform = CATransform3DMakeScale(-info.scale, info.scale, 1)
        case .leftMirrored:
            transform = CATransform3DMakeScale(-info.scale, info.scale, 1)
        case .rightMirrored:
            transform = CATransform3DMakeScale(info.scale, -info.scale, 1)
        case .downMirrored:
            transform = CATransform3DMakeScale(-info.scale, info.scale, 1)
        default:
            transform = CATransform3DMakeScale(info.scale, info.scale, 1)
        }
        transform = CATransform3DRotate(transform, info.angel, 0, 0, 1)
        return transform
    }
    static func textAnimationLayer(
        music: VideoEditorMusic,
        size: CGSize,
        fontSize: CGFloat,
        animationScale: CGFloat,
        animationSize: CGSize,
        beginTime: CFTimeInterval,
        videoDuration: TimeInterval
    ) -> CALayer {
        var textSize = size
        let bgLayer = CALayer()
        for (index, lyric) in music.lyrics.enumerated() {
            let textLayer = CATextLayer()
            textLayer.string = lyric.lyric
            let font = UIFont.boldSystemFont(ofSize: fontSize)
            let lyricHeight = lyric.lyric.height(ofFont: font, maxWidth: size.width)
            if textSize.height < lyricHeight {
                textSize.height = lyricHeight + 1
            }
            textLayer.font = font
            textLayer.fontSize = fontSize
            textLayer.isWrapped = true
            textLayer.truncationMode = .end
            textLayer.contentsScale = UIScreen.main.scale
            textLayer.alignmentMode = .left
            textLayer.foregroundColor = UIColor.white.cgColor
            textLayer.frame = CGRect(origin: .zero, size: textSize)
            textLayer.shadowOpacity = 0.4
            textLayer.shadowOffset = CGSize(width: 0, height: -1)
            if index > 0 || lyric.startTime > 0 {
                textLayer.opacity = 0
            }else {
                textLayer.opacity = 1
            }
            bgLayer.addSublayer(textLayer)
            if lyric.startTime > videoDuration {
                continue
            }
            let startAnimation: CABasicAnimation?
            if index > 0 || lyric.startTime > 0 {
                startAnimation = CABasicAnimation(keyPath: "opacity")
                startAnimation?.fromValue = 0
                startAnimation?.toValue = 1
                startAnimation?.duration = 0.01
                if lyric.startTime == 0 {
                    startAnimation?.beginTime = beginTime
                }else {
                    startAnimation?.beginTime = beginTime + lyric.startTime
                }
                startAnimation?.isRemovedOnCompletion = false
                startAnimation?.fillMode = .forwards
            }else {
                startAnimation = nil
            }
            
            if lyric.endTime + 0.01 > videoDuration {
                if let start = startAnimation {
                    textLayer.add(start, forKey: nil)
                }
                continue
            }
            let endAnimation = CABasicAnimation(keyPath: "opacity")
            endAnimation.fromValue = 1
            endAnimation.toValue = 0
            endAnimation.duration = 0.01
            if lyric.endTime == 0 {
                endAnimation.beginTime = AVCoreAnimationBeginTimeAtZero
            }else {
                if lyric.endTime + 0.01 < videoDuration {
                    endAnimation.beginTime = beginTime + lyric.endTime
                }else {
                    endAnimation.beginTime = beginTime + videoDuration
                }
            }
            endAnimation.isRemovedOnCompletion = false
            endAnimation.fillMode = .forwards
            
            if let time = music.time, time < videoDuration {
                let group = CAAnimationGroup()
                if let start = startAnimation {
                    group.animations = [start, endAnimation]
                }else {
                    group.animations = [endAnimation]
                }
                group.beginTime = beginTime
                group.isRemovedOnCompletion = false
                group.fillMode = .forwards
                group.duration = time
                group.repeatCount = MAXFLOAT
                textLayer.add(group, forKey: nil)
            }else {
                if let start = startAnimation {
                    textLayer.add(start, forKey: nil)
                }
                textLayer.add(endAnimation, forKey: nil)
            }
        }
        let animationLayer = VideoEditorMusicAnimationLayer(
            hexColor: "#ffffff",
            scale: animationScale
        )
        animationLayer.animationBeginTime = beginTime
        animationLayer.frame = CGRect(
            x: 2 * animationScale,
            y: -(8 * animationScale + animationSize.height),
            width: animationSize.width,
            height: animationSize.height
        )
        animationLayer.startAnimation()
        bgLayer.contentsScale = UIScreen.main.scale
        bgLayer.shadowOpacity = 0.4
        bgLayer.shadowOffset = CGSize(width: 0, height: -1)
        bgLayer.addSublayer(animationLayer)
        return bgLayer
    }
    static func animationLayer(
        image: UIImage,
        beginTime: CFTimeInterval,
        videoDuration: TimeInterval
    ) -> CALayer {
        let animationLayer = CALayer()
        animationLayer.contentsScale = UIScreen.main.scale
        animationLayer.contents = image.cgImage
        guard let gifResult = image.animateCGImageFrame() else {
            return animationLayer
        }
        let frames = gifResult.0
        if frames.isEmpty {
            return animationLayer
        }
        let delayTimes = gifResult.1
         
        var currentTime: Double = 0
        var animations = [CAAnimation]()
        for (index, frame) in frames.enumerated() {
            let delayTime = delayTimes[index]
            let animation = CABasicAnimation(keyPath: "contents")
            animation.toValue = frame
            animation.duration = 0.001
            animation.beginTime = AVCoreAnimationBeginTimeAtZero + currentTime
            animation.isRemovedOnCompletion = false
            animation.fillMode = .forwards
            animations.append(animation)
            currentTime += delayTime
            if currentTime + 0.01 > videoDuration {
                break
            }
        }
        let group = CAAnimationGroup()
        group.animations = animations
        group.beginTime = beginTime
        group.isRemovedOnCompletion = false
        group.fillMode = .forwards
        group.duration = currentTime + 0.01
        group.repeatCount = MAXFLOAT
        animationLayer.add(group, forKey: nil)
        return animationLayer
    }
    
    static func videoFixed(
        composition: AVMutableComposition,
        assetOrientation: AVCaptureVideoOrientation
    ) -> AVMutableVideoComposition {
        let videoComposition = AVMutableVideoComposition(propertiesOf: composition)
        guard assetOrientation != .landscapeRight else {
            return videoComposition
        }
        guard let videoTrack = composition.tracks(withMediaType: .video).first else {
            return videoComposition
        }
        let naturalSize = videoTrack.naturalSize
        if assetOrientation == .portrait {
            // 顺时针旋转90°
            videoComposition.renderSize = CGSize(width: naturalSize.height, height: naturalSize.width)
        } else if assetOrientation == .landscapeLeft {
            // 顺时针旋转180°
            videoComposition.renderSize = CGSize(width: naturalSize.width, height: naturalSize.height)
        } else if assetOrientation == .portraitUpsideDown {
            // 顺时针旋转270°
            videoComposition.renderSize = CGSize(width: naturalSize.height, height: naturalSize.width)
        }
        return videoComposition
    }
    
    static func createPixelBuffer(_ size: CGSize) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let pixelBufferAttributes = [kCVPixelBufferIOSurfacePropertiesKey: [:]]
        CVPixelBufferCreate(
            nil,
            Int(size.width),
            Int(size.height),
            kCVPixelFormatType_32BGRA,
            pixelBufferAttributes as CFDictionary,
            &pixelBuffer
        )
        return pixelBuffer
    }
    
    static func cropOrientation(
        _ cropSizeData: VideoEditorCropSizeData
    ) -> UIImage.Orientation {
        getOrientation(
            cropSizeData.angle,
            cropSizeData.mirrorType
        )
    }
    static func stickerOrientation(
        _ info: EditorStickerInfo
    ) -> UIImage.Orientation {
        getOrientation(
            info.initialAngle,
            info.initialMirrorType
        )
    }
    private static func getOrientation(
        _ angle: CGFloat,
        _ mirrorType: EditorImageResizerView.MirrorType
    ) -> UIImage.Orientation {
        var rotate = CGFloat.pi * angle / 180
        if rotate != 0 {
            rotate = CGFloat.pi * 2 + rotate
        }
        let isHorizontal = mirrorType == .horizontal
        if rotate > 0 || isHorizontal {
            let angle = Int(angle)
            switch angle {
            case 0, 360, -360:
                if isHorizontal {
                    return .upMirrored
                }
            case 90, -270:
                if !isHorizontal {
                    return .right
                }else {
                    return .rightMirrored
                }
            case 180, -180:
                if !isHorizontal {
                    return .down
                }else {
                    return .downMirrored
                }
            case 270, -90:
                if !isHorizontal {
                    return .left
                }else {
                    return .leftMirrored
                }
            default:
                break
            }
        }
        return .up
    }
}
