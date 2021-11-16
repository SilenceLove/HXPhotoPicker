//
//  Editor+PhotoTools.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/9.
//

import UIKit
import ImageIO
import CoreImage
import CoreServices
import AVKit

extension PhotoTools {
    static func createAnimatedImage(
        images: [UIImage],
        delays: [Double]
    ) -> URL? {
        if images.isEmpty || delays.isEmpty {
            return nil
        }
        let frameCount = images.count
        let imageURL = getImageTmpURL(.gif)
        guard let destination = CGImageDestinationCreateWithURL(
                imageURL as CFURL,
                kUTTypeGIF as CFString,
                frameCount, nil
        ) else {
            return nil
        }
        let gifProperty = [
            kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFHasGlobalColorMap: true,
                kCGImagePropertyColorModel: kCGImagePropertyColorModelRGB,
                kCGImagePropertyDepth: 8,
                kCGImagePropertyGIFLoopCount: 0
            ]
        ]
        CGImageDestinationSetProperties(destination, gifProperty as CFDictionary)
        for (index, image) in images.enumerated() {
            let delay = delays[index]
            let framePreperty = [
                kCGImagePropertyGIFDictionary: [
                    kCGImagePropertyGIFDelayTime: delay
                ]
            ]
            if let cgImage = image.cgImage {
                CGImageDestinationAddImage(destination, cgImage, framePreperty as CFDictionary)
            }
        }
        if CGImageDestinationFinalize(destination) {
            return imageURL
        }
        removeFile(fileURL: imageURL)
        return nil
    }
    
    static func checkNetworkURL(for url: URL) -> Bool {
        if checkLocalURL(for: url.path) {
            return false
        }
        if let scheme = url.scheme {
            if scheme == "http" || scheme == "https" {
                return true
            }
        }
        return UIApplication.shared.canOpenURL(url)
    }
    
    static func checkLocalURL(for path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }
    
    static func getFrameDuration(from gifInfo: [String: Any]?) -> TimeInterval {
        let defaultFrameDuration = 0.1
        guard let gifInfo = gifInfo else { return defaultFrameDuration }
        
        let unclampedDelayTime = gifInfo[kCGImagePropertyGIFUnclampedDelayTime as String] as? NSNumber
        let delayTime = gifInfo[kCGImagePropertyGIFDelayTime as String] as? NSNumber
        let duration = unclampedDelayTime ?? delayTime
        
        guard let frameDuration = duration else { return defaultFrameDuration }
        return frameDuration.doubleValue > 0.011 ? frameDuration.doubleValue : defaultFrameDuration
    }

    static func getFrameDuration(
        from imageSource: CGImageSource,
        at index: Int
    ) -> TimeInterval {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, index, nil)
            as? [String: Any] else { return 0.0 }

        let gifInfo = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any]
        return getFrameDuration(from: gifInfo)
    }
    
    public static func defaultColors() -> [String] {
        ["#ffffff", "#2B2B2B", "#FA5150", "#FEC200", "#07C160", "#10ADFF", "#6467EF"]
    }
    static func defaultMusicInfos() -> [VideoEditorMusicInfo] {
        var infos: [VideoEditorMusicInfo] = []
        if let audioURL = URL(string: "http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/chartle/%E5%A4%A9%E5%A4%96%E6%9D%A5%E7%89%A9.mp3"), // swiftlint:disable:this line_length
           let lrc = "天外来物".lrc {
            let info = VideoEditorMusicInfo(
                audioURL: audioURL,
                lrc: lrc,
                urlType: .network
            )
            infos.append(info)
        }
        return infos
    }
    #if canImport(Kingfisher)
    public static func defaultTitleChartlet() -> [EditorChartlet] {
        let title = EditorChartlet(
            url: URL(string: "http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/chartle/xxy_s_highlighted.png")
        )
        return [title]
    }
    
    public static func defaultNetworkChartlet() -> [EditorChartlet] {
        var chartletList: [EditorChartlet] = []
        for index in 1...40 {
            let urlString = "http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/chartle/xxy" + String(index) + ".png"
            let chartlet = EditorChartlet(
                url: .init(string: urlString)
            )
            chartletList.append(chartlet)
        }
        return chartletList
    }
    #endif
    
    /// 默认滤镜
    public static func defaultFilters() -> [PhotoEditorFilterInfo] {
        [
            PhotoEditorFilterInfo(
                filterName: "老电影".localized,
                defaultValue: 1
            ) { (image, lastImage, value, event) in
                if event == .touchUpInside {
                    return oldMovie(image, value: value)
                }
                return nil
            },
            PhotoEditorFilterInfo(
                filterName: "怀旧".localized
            ) { (image, _, _, _) in
                image.filter(
                    name: "CIPhotoEffectInstant",
                    parameters: [:]
                )
            },
            PhotoEditorFilterInfo(
                filterName: "黑白".localized
            ) { (image, _, _, _) in
                image.filter(
                    name: "CIPhotoEffectNoir",
                    parameters: [:]
                )
            },
            PhotoEditorFilterInfo(
                filterName: "色调".localized
            ) { (image, _, _, _) in
                image.filter(
                    name: "CIPhotoEffectTonal",
                    parameters: [:]
                )
            },
            PhotoEditorFilterInfo(
                filterName: "模糊".localized,
                defaultValue: 0.5
            ) { (image, lastImage, value, event) in
                if event == .touchUpInside {
                    return image.filter(
                        name: "CIGaussianBlur",
                        parameters: [
                            kCIInputRadiusKey: NSNumber(value: 10 * value)
                        ]
                    )
                }
                return nil
            },
            PhotoEditorFilterInfo(
                filterName: "岁月".localized
            ) { (image, _, _, _) in
                image.filter(
                    name: "CIPhotoEffectTransfer",
                    parameters: [:]
                )
            },
            PhotoEditorFilterInfo(
                filterName: "单色".localized
            ) { (image, _, _, _) in
                image.filter(
                    name: "CIPhotoEffectMono",
                    parameters: [:]
                )
            },
            PhotoEditorFilterInfo(
                filterName: "褪色".localized
            ) { (image, _, _, _) in
                image.filter(
                    name: "CIPhotoEffectFade",
                    parameters: [:]
                )
            },
            PhotoEditorFilterInfo(
                filterName: "冲印".localized
            ) { (image, _, _, _) in
                image.filter(
                    name: "CIPhotoEffectProcess",
                    parameters: [:]
                )
            },
            PhotoEditorFilterInfo(
                filterName: "铬黄".localized
            ) { (image, _, _, _) in
                image.filter(
                    name: "CIPhotoEffectChrome",
                    parameters: [:]
                )
            }
        ]
    }
    
    static func oldMovie(
        _ image: UIImage,
        value: Float
    ) -> UIImage? {
        let inputImage = CIImage.init(image: image)!
        let sepiaToneFilter = CIFilter(name: "CISepiaTone")!
        sepiaToneFilter.setValue(inputImage, forKey: kCIInputImageKey)
        sepiaToneFilter.setValue(value, forKey: kCIInputIntensityKey)
        let whiteSpecksFilter = CIFilter(name: "CIColorMatrix")!
        whiteSpecksFilter.setValue(
            CIFilter(
                name: "CIRandomGenerator"
            )!.outputImage!.cropped(
                to: inputImage.extent
            ),
            forKey: kCIInputImageKey
        )
        whiteSpecksFilter.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputRVector")
        whiteSpecksFilter.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputGVector")
        whiteSpecksFilter.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputBVector")
        whiteSpecksFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBiasVector")
        let sourceOverCompositingFilter = CIFilter(name: "CISourceOverCompositing")!
        sourceOverCompositingFilter.setValue(whiteSpecksFilter.outputImage, forKey: kCIInputBackgroundImageKey)
        sourceOverCompositingFilter.setValue(sepiaToneFilter.outputImage, forKey: kCIInputImageKey)
        let affineTransformFilter = CIFilter(name: "CIAffineTransform")!
        affineTransformFilter.setValue(
            CIFilter(
                name: "CIRandomGenerator"
            )!.outputImage!.cropped(
                to: inputImage.extent
            ),
            forKey: kCIInputImageKey
        )
        affineTransformFilter.setValue(
            NSValue(
                cgAffineTransform: CGAffineTransform(scaleX: 1.5, y: 25)
            ),
            forKey: kCIInputTransformKey
        )
        let darkScratchesFilter = CIFilter(name: "CIColorMatrix")!
        darkScratchesFilter.setValue(affineTransformFilter.outputImage, forKey: kCIInputImageKey)
        darkScratchesFilter.setValue(CIVector(x: 4, y: 0, z: 0, w: 0), forKey: "inputRVector")
        darkScratchesFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputGVector")
        darkScratchesFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBVector")
        darkScratchesFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputAVector")
        darkScratchesFilter.setValue(CIVector(x: 0, y: 1, z: 1, w: 1), forKey: "inputBiasVector")
        let minimumComponentFilter = CIFilter(name: "CIMinimumComponent")!
        minimumComponentFilter.setValue(darkScratchesFilter.outputImage, forKey: kCIInputImageKey)
        let multiplyCompositingFilter = CIFilter(name: "CIMultiplyCompositing")!
        multiplyCompositingFilter.setValue(minimumComponentFilter.outputImage, forKey: kCIInputBackgroundImageKey)
        multiplyCompositingFilter.setValue(sourceOverCompositingFilter.outputImage, forKey: kCIInputImageKey)
        let outputImage = multiplyCompositingFilter.outputImage!
        let context = CIContext(options: nil)
        if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        return nil
    }
    
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
                        exportSession.fileLengthLimit = exportSessionFileLengthLimit(
                            seconds: avAsset.duration.seconds,
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
        
        if let originalVoiceTrack = mixComposition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) {
            if let audioTrack = videoAsset.tracks(withMediaType: .audio).first {
                originalVoiceTrack.preferredTransform = audioTrack.preferredTransform
                try originalVoiceTrack.insertTimeRange(videoTimeRange, of: audioTrack, at: .zero)
            }
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
        let videoComposition = AVMutableVideoComposition(propertiesOf: mixComposition)
        var renderSize = videoComposition.renderSize
        let cropRect = CGRect(
            x: renderSize.width * cropSizeData.cropRect.minX,
            y: renderSize.height * cropSizeData.cropRect.minY,
            width: renderSize.width * cropSizeData.cropRect.width,
            height: renderSize.height * cropSizeData.cropRect.height
        )
        
        let cropOrientation = cropOrientation(cropSizeData)
        let stickerInfos = cropSizeData.stickerInfos
        var drawImage: UIImage?
        if let image = cropSizeData.drawLayer?.convertedToImage() {
            cropSizeData.drawLayer?.contents = nil
            drawImage = image
        }
        
        if !stickerInfos.isEmpty || drawImage != nil {
            let bounds = CGRect(origin: .zero, size: renderSize)
            let overlaylayer = CALayer()
            if let drawImage = drawImage {
                let drawLayer = CALayer()
                drawLayer.contents = drawImage.cgImage
                drawLayer.frame = bounds
                drawLayer.contentsScale = UIScreen.main.scale
                overlaylayer.addSublayer(drawLayer)
            }
            for info in stickerInfos {
                let center = CGPoint(
                    x: info.centerScale.x * bounds.width,
                    y: bounds.height - info.centerScale.y * bounds.height
                )
                let size = CGSize(
                    width: info.sizeScale.width * bounds.width,
                    height: info.sizeScale.height * bounds.height
                )
                var transform = CATransform3DMakeScale(info.scale, info.scale, 1)
                transform = CATransform3DRotate(transform, info.angel, 0, 0, -1)
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
                        videoDuration: videoDuration)
                    textLayer.frame = CGRect(origin: .zero, size: size)
                    textLayer.transform = transform
                    textLayer.position = center
                    overlaylayer.addSublayer(textLayer)
                }else {
                    let imageLayer = animationLayer(
                        image: info.image,
                        beginTime: animationBeginTime,
                        videoDuration: videoDuration
                    )
                    imageLayer.frame = CGRect(origin: .zero, size: size)
                    imageLayer.transform = transform
                    imageLayer.position = center
                    imageLayer.shadowColor = UIColor.black.withAlphaComponent(0.6).cgColor
                    imageLayer.shadowOpacity = 0.5
                    imageLayer.shadowOffset = CGSize(width: 0, height: -1)
                    overlaylayer.addSublayer(imageLayer)
                }
            }
            overlaylayer.frame = getOverlayFrame(
                cropOrientation: cropOrientation,
                cropRect: cropRect,
                rect: bounds
            )
            
            /// 这种方式模拟器会崩溃
            /// https://developer.apple.com/forums/thread/133681
//            let videolayer = CALayer()
//            videolayer.frame = bounds
//
//            let parentLayer = CALayer()
//            parentLayer.frame = bounds
//            parentLayer.isGeometryFlipped = true
//            parentLayer.addSublayer(videolayer)
//            parentLayer.addSublayer(overlaylayer)
//
//            let animationTool = AVVideoCompositionCoreAnimationTool(
//                postProcessingAsVideoLayer: videolayer,
//                in: parentLayer
//            )
//            videoComposition.animationTool = animationTool
            
            let watermarkLayerTrackID = videoAsset.unusedTrackID()
            videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
                additionalLayer: overlaylayer,
                asTrackID: watermarkLayerTrackID
            )
            let watermarkLayerInstruction = AVMutableVideoCompositionLayerInstruction()
            watermarkLayerInstruction.trackID = watermarkLayerTrackID
            
            let videoInstruction = AVMutableVideoCompositionInstruction()
            videoInstruction.timeRange = CMTimeRange(
                start: CMTime.zero,
                duration: videoTrack.timeRange.duration
            )
            let videoLayerInstruction = AVMutableVideoCompositionLayerInstruction(
                assetTrack: videoTrack
            )
            videoInstruction.layerInstructions = [
                cropSizeData.canReset ? videoLayerInstructionFixed(
                    videoComposition: videoComposition,
                    videoLayerInstruction: watermarkLayerInstruction,
                    cropOrientation: cropOrientation,
                    cropRect: cropRect
                ) :
                watermarkLayerInstruction,
                cropSizeData.canReset ? videoLayerInstructionFixed(
                    videoComposition: videoComposition,
                    videoLayerInstruction: videoLayerInstruction,
                    cropOrientation: cropOrientation,
                    cropRect: cropRect
                ) : videoLayerInstruction
            ]
            videoComposition.instructions = [videoInstruction]
        }else {
            if cropSizeData.canReset {
                let videoInstruction = AVMutableVideoCompositionInstruction()
                videoInstruction.timeRange = CMTimeRange(
                    start: CMTime.zero,
                    duration: videoTrack.timeRange.duration
                )
                let videoLayerInstruction = AVMutableVideoCompositionLayerInstruction(
                    assetTrack: videoTrack
                )
                videoInstruction.layerInstructions = [
                    videoLayerInstructionFixed(
                        videoComposition: videoComposition,
                        videoLayerInstruction: videoLayerInstruction,
                        cropOrientation: cropOrientation,
                        cropRect: cropRect
                    )
                ]
                videoComposition.instructions = [videoInstruction]
            }
        }
        if cropSizeData.canReset {
            renderSize = cropRect.size
            switch cropOrientation {
            case .left, .leftMirrored, .right, .rightMirrored:
                renderSize = CGSize(width: renderSize.height, height: renderSize.width)
            default:
                break
            }
        }
        // https://stackoverflow.com/a/45013962
        renderSize = CGSize(
            width: floor(renderSize.width / 16) * 16,
            height: floor(renderSize.height / 16) * 16
        )
        videoComposition.renderScale = 1
        videoComposition.renderSize = renderSize
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 60)
        return videoComposition
    }
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
    static func getOverlayFrame(
        cropOrientation: UIImage.Orientation,
        cropRect: CGRect,
        rect: CGRect
    ) -> CGRect {
        rect
//        var x: CGFloat = 0
//        var y: CGFloat = 0
//        switch cropOrientation {
//        case .up:
////            x = -cropRect.minX
//            break
//        case .upMirrored:
//
//            break
//        case .left:
//
//            break
//        case .rightMirrored:
//
//            break
//        case .down:
//
//            break
//        case .downMirrored:
//
//            break
//        case .right:
//
//            break
//        case .leftMirrored:
//
//            break
//        }
//        return CGRect(x: x, y: y, width: rect.width, height: rect.height)
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
            y: textSize.height + 8 * animationScale,
            width: animationSize.width,
            height: animationSize.height
        )
        animationLayer.startAnimation()
        bgLayer.shadowColor = UIColor.black.withAlphaComponent(0.6).cgColor
        bgLayer.shadowOpacity = 0.5
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
} // swiftlint:disable:this file_length
