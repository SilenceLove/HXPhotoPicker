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
    class func createAnimatedImage(images: [UIImage],
                                   delays: [Double]) -> URL? {
        if images.isEmpty || delays.isEmpty {
            return nil
        }
        let frameCount = images.count
        let imageURL = getImageTmpURL(.gif)
        guard let destination = CGImageDestinationCreateWithURL(imageURL as CFURL, kUTTypeGIF as CFString, frameCount, nil) else {
            return nil
        }
        let gifProperty = [
            kCGImagePropertyGIFDictionary : [
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
                kCGImagePropertyGIFDictionary : [
                    kCGImagePropertyGIFDelayTime : delay
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
    
    class func getFrameDuration(from gifInfo: [String: Any]?) -> TimeInterval {
        let defaultFrameDuration = 0.1
        guard let gifInfo = gifInfo else { return defaultFrameDuration }
        
        let unclampedDelayTime = gifInfo[kCGImagePropertyGIFUnclampedDelayTime as String] as? NSNumber
        let delayTime = gifInfo[kCGImagePropertyGIFDelayTime as String] as? NSNumber
        let duration = unclampedDelayTime ?? delayTime
        
        guard let frameDuration = duration else { return defaultFrameDuration }
        return frameDuration.doubleValue > 0.011 ? frameDuration.doubleValue : defaultFrameDuration
    }

    class func getFrameDuration(from imageSource: CGImageSource,
                                at index: Int) -> TimeInterval {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, index, nil)
            as? [String: Any] else { return 0.0 }

        let gifInfo = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any]
        return getFrameDuration(from: gifInfo)
    }
    
    public class func defaultColors() -> [String] {
        ["#ffffff", "#2B2B2B", "#FA5150", "#FEC200", "#07C160", "#10ADFF", "#6467EF"]
    }
    
    #if canImport(Kingfisher)
    public class func defaultTitleChartlet() -> [EditorChartlet] {
        let title = EditorChartlet(
            url: URL(string: "http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/chartle/xxy_s_highlighted.png")
        )
        return [title]
    }
    
    public class func defaultNetworkChartlet() -> [EditorChartlet] {
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
    public class func defaultFilters() -> [PhotoEditorFilterInfo] {
        return [
            PhotoEditorFilterInfo(
                filterName: "老电影".localized,
                defaultValue: 1
            ) {
                (image, lastImage, value, event) in
                if event == .touchUpInside {
                    return oldMovie(image, value: value)
                }
                return nil
            },
            PhotoEditorFilterInfo(
                filterName: "怀旧".localized,
                defaultValue: -1
            ) {
                (image, _, _, _) in
                image.filter(name: "CIPhotoEffectInstant",
                             parameters: [:]
                )
            },
            PhotoEditorFilterInfo(
                filterName: "黑白".localized,
                defaultValue: -1) {
                (image, _, _, _) in
                image.filter(name: "CIPhotoEffectNoir",
                             parameters: [:]
                )
            },
            PhotoEditorFilterInfo(
                filterName: "色调".localized,
                defaultValue: -1
            ) {
                (image, _, _, _) in
                image.filter(name: "CIPhotoEffectTonal",
                             parameters: [:]
                )
            },
            PhotoEditorFilterInfo(
                filterName: "模糊".localized,
                defaultValue: 0.5
            ) {
                (image, lastImage, value, event) in
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
                filterName: "岁月".localized,
                defaultValue: -1
            ) {
                (image, _, _, _) in
                image.filter(
                    name: "CIPhotoEffectTransfer",
                    parameters: [:]
                )
            },
            PhotoEditorFilterInfo(
                filterName: "单色".localized,
                defaultValue: -1
            ) {
                (image, _, _, _) in
                image.filter(
                    name: "CIPhotoEffectMono",
                    parameters: [:]
                )
            },
            PhotoEditorFilterInfo(
                filterName: "褪色".localized,
                defaultValue: -1
            ) {
                (image, _, _, _) in
                image.filter(
                    name: "CIPhotoEffectFade",
                    parameters: [:]
                )
            },
            PhotoEditorFilterInfo(
                filterName: "冲印".localized,
                defaultValue: -1
            ) {
                (image, _, _, _) in
                image.filter(
                    name: "CIPhotoEffectProcess",
                    parameters: [:]
                )
            },
            PhotoEditorFilterInfo(
                filterName: "铬黄".localized,
                defaultValue: -1
            ) {
                (image, _, _, _) in
                image.filter(
                    name: "CIPhotoEffectChrome",
                    parameters: [:]
                )
            }
        ]
    }
    
    class func oldMovie(_ image: UIImage,
                        value: Float) -> UIImage? {
        let inputImage = CIImage.init(image: image)!
        let sepiaToneFilter = CIFilter(name: "CISepiaTone")!
        sepiaToneFilter.setValue(inputImage, forKey: kCIInputImageKey)
        sepiaToneFilter.setValue(value, forKey: kCIInputIntensityKey)
        let whiteSpecksFilter = CIFilter(name: "CIColorMatrix")!
        whiteSpecksFilter.setValue(CIFilter(name: "CIRandomGenerator")!.outputImage!.cropped(to: inputImage.extent), forKey: kCIInputImageKey)
        whiteSpecksFilter.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputRVector")
        whiteSpecksFilter.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputGVector")
        whiteSpecksFilter.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputBVector")
        whiteSpecksFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBiasVector")
        let sourceOverCompositingFilter = CIFilter(name: "CISourceOverCompositing")!
        sourceOverCompositingFilter.setValue(whiteSpecksFilter.outputImage, forKey: kCIInputBackgroundImageKey)
        sourceOverCompositingFilter.setValue(sepiaToneFilter.outputImage, forKey: kCIInputImageKey)
        let affineTransformFilter = CIFilter(name: "CIAffineTransform")!
        affineTransformFilter.setValue(CIFilter(name: "CIRandomGenerator")!.outputImage!.cropped(to: inputImage.extent), forKey: kCIInputImageKey)
        affineTransformFilter.setValue(NSValue(cgAffineTransform: CGAffineTransform(scaleX: 1.5, y: 25)), forKey: kCIInputTransformKey)
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
    
    /// 视频添加背景音乐
    /// - Parameters:
    ///   - videoURL: 视频地址
    ///   - audioURL: 需要添加的音频地址
    ///   - audioVolume: 需要添加的音频音量
    ///   - originalAudioVolume: 视频原始音频音量
    ///   - presentName: 导出质量
    ///   - completion: 添加完成
    class func videoAddBackgroundMusic(forVideo videoURL: URL,
                                       audioURL: URL?,
                                       audioVolume: Float,
                                       originalAudioVolume: Float,
                                       presentName: String,
                                       completion: @escaping (URL?) -> Void) {
        let outputURL = getVideoTmpURL()
        do {
            let mixComposition = AVMutableComposition()
            let videoAsset = AVURLAsset(url: videoURL)
            let videoTimeRange = CMTimeRangeMake(start: .zero, duration: videoAsset.duration)
            let compositionVideoTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
                if let videoTrack = videoAsset.tracks(withMediaType: .video).first {
                    try compositionVideoTrack?.insertTimeRange(videoTimeRange, of: videoTrack, at: .zero)
                }
            
            let audioMix = AVMutableAudioMix()
            var newAudioInputParams: AVMutableAudioMixInputParameters?
            if let audioURL = audioURL {
                let audioAsset = AVURLAsset(url: audioURL)
                let newAudioTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
                if let audioTrack = audioAsset.tracks(withMediaType: .audio).first {
                    let audioDuration = audioAsset.duration.seconds
                    let videoDuration = videoAsset.duration.seconds
                    if audioDuration < videoDuration {
                        let audioTimeRange = CMTimeRangeMake(start: .zero, duration: audioAsset.duration)
                        let divisor = Int(videoDuration / audioDuration)
                        var atTime: CMTime = .zero
                        for index in 0..<divisor {
                            try newAudioTrack?.insertTimeRange(audioTimeRange, of: audioTrack, at: atTime)
                            atTime = CMTimeMakeWithSeconds(Double(index + 1) * audioDuration, preferredTimescale: audioAsset.duration.timescale)
                        }
                        let remainder = videoDuration.truncatingRemainder(dividingBy: audioDuration)
                        if remainder > 0 {
                            let seconds = videoDuration - audioDuration * Double(divisor)
                            try newAudioTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: CMTimeMakeWithSeconds(seconds, preferredTimescale: audioAsset.duration.timescale)), of: audioTrack, at: atTime)
                        }
                    }else {
                        let audioTimeRange = CMTimeRangeMake(start: .zero, duration: videoTimeRange.duration)
                        try newAudioTrack?.insertTimeRange(audioTimeRange, of: audioTrack, at: .zero)
                    }
                }
                newAudioInputParams = AVMutableAudioMixInputParameters(track: newAudioTrack)
                newAudioInputParams?.setVolumeRamp(fromStartVolume: audioVolume, toEndVolume: audioVolume, timeRange: CMTimeRangeMake(start: .zero, duration: videoAsset.duration))
                newAudioInputParams?.trackID =  newAudioTrack?.trackID ?? kCMPersistentTrackID_Invalid
            }
            
            if let originalVoiceTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
                if let audioTrack = videoAsset.tracks(withMediaType: .audio).first {
                    try originalVoiceTrack.insertTimeRange(videoTimeRange, of: audioTrack, at: .zero)
                }
                let volume: Float = originalAudioVolume
                let originalAudioInputParams = AVMutableAudioMixInputParameters(track: originalVoiceTrack)
                originalAudioInputParams.setVolumeRamp(fromStartVolume: volume, toEndVolume: volume, timeRange: CMTimeRangeMake(start: .zero, duration: videoAsset.duration))
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
            if AVAssetExportSession.allExportPresets().contains(presentName) {
                if let exportSession = AVAssetExportSession.init(asset: mixComposition, presetName: presentName) {
                    let supportedTypeArray = exportSession.supportedFileTypes
                    exportSession.outputURL = outputURL
                    if supportedTypeArray.contains(AVFileType.mp4) {
                        exportSession.outputFileType = .mp4
                    }else if supportedTypeArray.isEmpty {
                        completion(nil)
                        return
                    }else {
                        exportSession.outputFileType = supportedTypeArray.first
                    }
                    exportSession.shouldOptimizeForNetworkUse = true
                    if !audioMix.inputParameters.isEmpty {
                        exportSession.audioMix = audioMix
                    }
                    exportSession.exportAsynchronously(completionHandler: {
                        DispatchQueue.main.async {
                            switch exportSession.status {
                            case .completed:
                                completion(outputURL)
                                break
                            case .failed, .cancelled:
                                completion(nil)
                                break
                            default: break
                            }
                        }
                    })
                    return
                }
            }
            completion(nil)
        } catch {
            completion(nil)
        }
    }
}
