//
//  PhotoTools.swift
//  照片选择器-Swift
//
//  Created by Silence on 2019/6/29.
//  Copyright © 2019年 Silence. All rights reserved.
//

import UIKit
import Photos
import ImageIO

public struct PhotoTools {
    
    /// 转换视频时长为 mm:ss 格式的字符串
    public static func transformVideoDurationToString(
        duration: TimeInterval
    ) -> String {
        let time = Int(round(Double(duration)))
        if time < 10 {
            return String.init(format: "00:0%d", arguments: [time])
        }else if time < 60 {
            return String.init(format: "00:%d", arguments: [time])
        }else {
            var min = Int(time / 60)
            let sec = time - (min * 60)
            if min < 60 {
                if sec < 10 {
                    return String(format: "%d:0%d", arguments: [min, sec])
                }else {
                    return String(format: "%d:%d", arguments: [min, sec])
                }
            }else {
                let hour = Int(min / 60)
                min -= hour * 60
                if hour < 10 {
                    if min < 10 {
                        if sec < 10 {
                            return String(format: "0%d:0%d:0%d", arguments: [hour, min, sec])
                        }else {
                            return String(format: "0%d:0%d:%d", arguments: [hour, min, sec])
                        }
                    }else {
                        if sec < 10 {
                            return String(format: "0%d:%d:0%d", arguments: [hour, min, sec])
                        }else {
                            return String(format: "0%d:%d:%d", arguments: [hour, min, sec])
                        }
                    }
                }
                if min < 10 {
                    if sec < 10 {
                        return String(format: "%d:0%d:0%d", arguments: [hour, min, sec])
                    }else {
                        return String(format: "%d:0%d:%d", arguments: [hour, min, sec])
                    }
                }else {
                    if sec < 10 {
                        return String(format: "%d:%d:0%d", arguments: [hour, min, sec])
                    }else {
                        return String(format: "%d:%d:%d", arguments: [hour, min, sec])
                    }
                }
            }
        }
    }
    
    /// 根据视频地址获取视频时长
    public static func getVideoDuration(
        videoURL: URL?
    ) -> TimeInterval {
        guard let videoURL = videoURL else {
            return 0
        }
        let options = [AVURLAssetPreferPreciseDurationAndTimingKey: false]
        let urlAsset = AVURLAsset.init(url: videoURL, options: options)
//        let second = TimeInterval(urlAsset.duration.value) / TimeInterval(urlAsset.duration.timescale)
        return TimeInterval(round(urlAsset.duration.seconds))
    }
    
    /// 根据视频时长(00:00:00)获取秒
    static func getVideoTime(forVideo duration: String) -> TimeInterval {
        var m = 0
        var s = 0
        var ms = 0
        let components = duration.components(
            separatedBy: CharacterSet.init(charactersIn: ":.")
        )
        if components.count >= 2 {
            if let i = Int(components[0]) {
                m = i
            }else {
                m = 0
            }
            if let i = Int(components[1]) {
                s = i
            }else {
                s = 0
            }
            if components.count == 3 {
                if let i = Int(components[2]) {
                    ms = i
                }else {
                    ms = 0
                }
            }
        }else {
            s = Int(INT_MAX)
        }
        return TimeInterval(CGFloat(m * 60) + CGFloat(s) + CGFloat(ms) * 0.001)
    }
    
    /// 根据视频地址获取视频封面
    public static func getVideoThumbnailImage(
        videoURL: URL?,
        atTime: TimeInterval
    ) -> UIImage? {
        guard let videoURL = videoURL else {
            return nil
        }
        return getVideoThumbnailImage(avAsset: .init(url: videoURL), atTime: atTime)
    }
    
    /// 根据视频地址获取视频封面
    public static func getVideoThumbnailImage(
        avAsset: AVAsset?,
        atTime: TimeInterval
    ) -> UIImage? {
        guard let avAsset = avAsset else {
            return nil
        }
        return avAsset.getImage(at: atTime)
    }
    
    /// 获视频缩略图
    @discardableResult
    public static func getVideoThumbnailImage(
        url: URL,
        atTime: TimeInterval,
        imageGenerator: ((AVAssetImageGenerator) -> Void)? = nil,
        completion: @escaping (URL, UIImage?, AVAssetImageGenerator.Result) -> Void
    ) -> AVAsset {
        let asset = AVURLAsset(url: url)
        asset.loadValuesAsynchronously(forKeys: ["duration"]) {
            if asset.statusOfValue(forKey: "duration", error: nil) != .loaded {
                DispatchQueue.main.async {
                    completion(url, nil, .failed)
                }
                return
            }
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            let time = CMTime(value: CMTimeValue(atTime), timescale: asset.duration.timescale)
            let array = [NSValue(time: time)]
            generator.generateCGImagesAsynchronously(
                forTimes: array
            ) { (_, cgImage, _, result, _) in
                if let image = cgImage, result == .succeeded {
                    var image = UIImage(cgImage: image)
                    if image.imageOrientation != .up,
                       let img = image.normalizedImage() {
                        image = img
                    }
                    DispatchQueue.main.async {
                        completion(url, image, result)
                    }
                }else {
                    DispatchQueue.main.async {
                        completion(url, nil, result)
                    }
                }
            }
            DispatchQueue.main.async {
                imageGenerator?(generator)
            }
        }
        return asset
    }
    
    static func transformImageSize(
        _ imageSize: CGSize,
        to view: UIView
    ) -> CGRect {
        return transformImageSize(
            imageSize,
            toViewSize: view.size
        )
    }
    
    public static func transformImageSize(
        _ imageSize: CGSize,
        toViewSize viewSize: CGSize,
        directions: [PhotoToolsTransformImageSizeDirections] = [.horizontal, .vertical]
    ) -> CGRect {
        var size: CGSize = .zero
        var center: CGPoint = .zero
        
        func handleVertical(
            _ imageSize: CGSize,
            _ viewSize: CGSize
        ) -> (CGSize, CGPoint) {
            let aspectRatio = viewSize.width / imageSize.width
            let contentWidth = viewSize.width
            let contentHeight = imageSize.height * aspectRatio
            let _size = CGSize(width: contentWidth, height: contentHeight)
            if contentHeight < viewSize.height {
                let center = CGPoint(x: viewSize.width * 0.5, y: viewSize.height * 0.5)
                return (_size, center)
            }
            return (_size, .zero)
        }
        func handleHorizontal(
            _ imageSize: CGSize,
            _ viewSize: CGSize
        ) -> (CGSize, CGPoint) {
            let aspectRatio = viewSize.height / imageSize.height
            var contentWidth = imageSize.width * aspectRatio
            var contentHeight = viewSize.height
            if contentWidth > viewSize.width {
                contentHeight = viewSize.width / contentWidth * contentHeight
                contentWidth = viewSize.width
            }
            let _size = CGSize(width: contentWidth, height: contentHeight)
            if contentHeight < viewSize.height {
                let center = CGPoint(x: viewSize.width * 0.5, y: viewSize.height * 0.5)
                return (_size, center)
            }
            return (_size, .zero)
        }
        
        if directions.contains(.horizontal) && directions.contains(.vertical) {
            if UIDevice.isPortrait {
                let content = handleVertical(imageSize, viewSize)
                size = content.0
                center = content.1
            }else {
                let content = handleHorizontal(imageSize, viewSize)
                size = content.0
                if !content.1.equalTo(.zero) {
                    center = content.1
                }
            }
        }else if directions.contains(.horizontal) {
            let content = handleHorizontal(imageSize, viewSize)
            size = content.0
            center = content.1
        }else if directions.contains(.vertical) {
            let content = handleVertical(imageSize, viewSize)
            size = content.0
            center = content.1
        }
        var rectY: CGFloat
        if center.equalTo(.zero) {
            rectY = 0
        }else {
            rectY = (viewSize.height - size.height) * 0.5
        }
        return CGRect(x: (viewSize.width - size.width) * 0.5, y: rectY, width: size.width, height: size.height)
    }
    
    static func exportSessionFileLengthLimit(
        seconds: Double,
        maxSize: Int? = nil,
        exportPreset: ExportPreset,
        videoQuality: Int
    ) -> Int64 {
        if videoQuality > 0 {
            let quality = Double(min(videoQuality, 10))
            if let maxSize = maxSize {
                return Int64(Double(maxSize) * (quality / 10))
            }
            var ratioParam: Double = 0
            if exportPreset == .ratio_640x480 {
                ratioParam = 0.02
            }else if exportPreset == .ratio_960x540 {
                ratioParam = 0.04
            }else if exportPreset == .ratio_1280x720 {
                ratioParam = 0.08
            }
            return Int64(seconds * ratioParam * quality * 1000 * 1000)
        }
        return 0
    }
    
    static func imageCompress(
        _ data: Data,
        compressionQuality: CGFloat
    ) -> Data? {
        guard var resultImage = UIImage(data: data)?.normalizedImage() else {
            return nil
        }
        let compression = max(0, min(1, compressionQuality))
        let maxLength = Int(CGFloat(data.count) * compression)
        let widthHeightRatio = resultImage.width / resultImage.height
        var data = data
        
        var lastDataLength = 0
        while data.count > maxLength && data.count != lastDataLength {
            let dataCount = data.count
            lastDataLength = dataCount
            let maxRatio: CGFloat
            if widthHeightRatio < 0.2 {
                maxRatio = 1
            }else {
                maxRatio = min(5000 / resultImage.width, 5000 / resultImage.height)
            }
            let ratio = min(max(CGFloat(maxLength) / CGFloat(dataCount), compression), maxRatio)
            let size = CGSize(
                width: Int(resultImage.width * ratio),
                height: Int(resultImage.height * ratio)
            )
            guard let image = resultImage.scaleToFillSize(size: size),
                  let imageData = image.jpegData(compressionQuality: 0.5) else {
                return data
            }
            resultImage = image
            data = imageData
        }
        return data
    }
    
    static func compressImageData(
        _ imageData: Data,
        compressionQuality: CGFloat?,
        queueLabel: String,
        completion: @escaping (Data?) -> Void
    ) {
        guard let compressionQuality else {
            completion(imageData)
            return
        }
        guard let resultImage = UIImage(data: imageData)?.normalizedImage() else {
            completion(imageData)
            return
        }
        let serialQueue = DispatchQueue(
            label: queueLabel,
            qos: .userInitiated,
            attributes: [],
            autoreleaseFrequency: .workItem,
            target: nil
        )
        let compression = max(0, min(1, compressionQuality))
        let maxLength = Int(CGFloat(imageData.count) * compression)
        let widthHeightRatio = resultImage.width / resultImage.height
        let data = imageData
        
        serialQueue.async {
            compressImageData(
                data,
                resultImage: resultImage,
                compression: compressionQuality,
                maxLength: maxLength,
                widthHeightRatio: widthHeightRatio
            ) {
                completion($0)
            }
        }
    }
     
    private static func compressImageData(
        _ data: Data,
        resultImage: UIImage,
        compression: CGFloat,
        maxLength: Int,
        lastDataLength: Int = 0,
        widthHeightRatio: CGFloat,
        completionHandler: @escaping (Data) -> Void
    ) {
        autoreleasepool {
            var lastDataLength = lastDataLength
            let dataCount = data.count
            lastDataLength = dataCount
            let maxRatio: CGFloat
            if widthHeightRatio < 0.2 {
                maxRatio = 1
            }else {
                maxRatio = min(5000 / resultImage.width, 5000 / resultImage.height)
            }
            let ratio = min(max(CGFloat(maxLength) / CGFloat(dataCount), compression), maxRatio)
            let size = CGSize(
                width: Int(resultImage.width * ratio),
                height: Int(resultImage.height * ratio)
            )
            guard let image = resultImage.scaleToFillSize(size: size),
                  let imageData = image.jpegData(compressionQuality: 0.5) else {
                completionHandler(data)
                return
            }
            if data.count > maxLength && data.count != lastDataLength {
                self.compressImageData(
                    imageData,
                    resultImage: image,
                    compression: compression,
                    maxLength: maxLength,
                    lastDataLength: lastDataLength,
                    widthHeightRatio: widthHeightRatio,
                    completionHandler: completionHandler
                )
                return
            }
            completionHandler(imageData)
        }
    }
    
    static func getBasicAnimation(
        _ keyPath: String,
        _ fromValue: Any?,
        _ toValue: Any?,
        _ duration: TimeInterval,
        _ timingFunctionName: CAMediaTimingFunctionName = .linear
    ) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: keyPath)
        animation.fromValue = fromValue
        animation.toValue = toValue
        animation.duration = duration
        animation.fillMode = .backwards
        animation.timingFunction = .init(name: timingFunctionName)
        return animation
    }
    
    static func getGradientShadowLayer(
        _ isTop: Bool,
        colors: [CGColor] = [UIColor.black.withAlphaComponent(0).cgColor,
                             UIColor.black.withAlphaComponent(0.2).cgColor,
                             UIColor.black.withAlphaComponent(0.3).cgColor,
                             UIColor.black.withAlphaComponent(0.4).cgColor,
                             UIColor.black.withAlphaComponent(0.5).cgColor],
        locations: [NSNumber] = [0.1, 0.3, 0.5, 0.7, 0.9]
    ) -> CAGradientLayer {
        getGradientShadowLayer(
            startPoint: isTop ? CGPoint(x: 0, y: 1) : CGPoint(x: 0, y: 0),
            endPoint: isTop ? CGPoint(x: 0, y: 0) : CGPoint(x: 0, y: 1),
            colors: colors,
            locations: locations
        )
    }
    
    static func getGradientShadowLayer(
        startPoint: CGPoint,
        endPoint: CGPoint,
        colors: [CGColor] = [UIColor.black.withAlphaComponent(0).cgColor,
                             UIColor.black.withAlphaComponent(0.2).cgColor,
                             UIColor.black.withAlphaComponent(0.3).cgColor,
                             UIColor.black.withAlphaComponent(0.4).cgColor,
                             UIColor.black.withAlphaComponent(0.5).cgColor],
        locations: [NSNumber] = [0.1, 0.3, 0.5, 0.7, 0.9]
    ) -> CAGradientLayer {
        let layer = CAGradientLayer()
        layer.contentsScale = UIScreen._scale
        layer.colors = colors
        layer.startPoint = startPoint
        layer.endPoint = endPoint
        layer.locations = locations
        layer.borderWidth = 0.0
        return layer
    }
    
    #if HXPICKER_ENABLE_EDITOR || HXPICKER_ENABLE_EDITOR_VIEW || HXPICKER_ENABLE_CAMERA
    static func getColor(red: Int, green: Int, blue: Int, alpha: Int = 255) -> CIColor {
        return CIColor(red: CGFloat(Double(red) / 255.0),
                       green: CGFloat(Double(green) / 255.0),
                       blue: CGFloat(Double(blue) / 255.0),
                       alpha: CGFloat(Double(alpha) / 255.0))
    }
    
    static func getColorImage(red: Int, green: Int, blue: Int, alpha: Int = 255, rect: CGRect) -> CIImage {
        let color = self.getColor(red: red, green: green, blue: blue, alpha: alpha)
        return CIImage(color: color).cropped(to: rect)
    }
    
    
    static func createPixelBuffer(_ size: CGSize) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let pixelBufferAttributes = [kCVPixelBufferIOSurfacePropertiesKey: [:] as [String: Any]]
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
    #endif
     
    private init() { }
}

public enum PhotoToolsTransformImageSizeDirections {
    case horizontal
    case vertical
}
