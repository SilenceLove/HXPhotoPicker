//
//  EditorView+PhotoTools.swift
//  HXPhotoPicker
//
//  Created by Slience on 2023/1/31.
//

import UIKit
import ImageIO
import CoreImage
import CoreServices

extension PhotoTools {
    
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
    
    static func createAnimatedImage(
        images: [UIImage],
        delays: [Double],
        toFile filePath: URL? = nil
    ) -> URL? {
        if images.isEmpty || delays.isEmpty {
            return nil
        }
        let frameCount = images.count
        let imageURL = filePath == nil ? getImageTmpURL(.gif) : filePath!
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
            ] as [CFString: Any]
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
    
    static func getBasicAnimation(
        _ keyPath: String,
        _ fromValue: Any?,
        _ toValue: Any?
    ) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: keyPath)
        animation.fromValue = fromValue
        animation.toValue = toValue
        animation.duration = 0.3
        animation.fillMode = .backwards
        animation.timingFunction = .init(name: .easeOut)
        return animation
    }
    
    static func cropImage(
        _ inputImage: UIImage?,
        cropFactor: EditorAdjusterView.CropFactor
    ) -> UIImage? {
        guard let inputImage = inputImage?.normalizedImage(), let imageRef = inputImage.cgImage else {
            return nil
        }
        if cropFactor.sizeRatio.equalTo(.init(x: 1, y: 1)),
           cropFactor.mirrorScale.equalTo(.init(x: 1, y: 1)),
           cropFactor.angle == 0,
           !cropFactor.isRound,
           cropFactor.maskImage == nil {
            return inputImage
        }
        let width = CGFloat(imageRef.width)
        let height = CGFloat(imageRef.height)
        let rendWidth = width * cropFactor.sizeRatio.x
        let rendHeight = height * cropFactor.sizeRatio.y
        
        let centerX = width * cropFactor.centerRatio.x
        let centerY = height * cropFactor.centerRatio.y
        
        let translationX = -(centerX - width * 0.5)
        let translationY = -(height * 0.5 - centerY)
        
        var bitmapRawValue = CGBitmapInfo.byteOrder32Little.rawValue
        let alphaInfo = imageRef.alphaInfo
        if alphaInfo == .premultipliedLast ||
            alphaInfo == .premultipliedFirst ||
            alphaInfo == .last ||
            alphaInfo == .first ||
            cropFactor.isRound ||
            cropFactor.maskImage != nil {
            bitmapRawValue += CGImageAlphaInfo.premultipliedFirst.rawValue
        } else {
            bitmapRawValue += CGImageAlphaInfo.noneSkipFirst.rawValue
        }
        
        guard let context = CGContext(
            data: nil,
            width: Int(rendWidth),
            height: Int(rendHeight),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapRawValue
        ) else {
            return nil
        }
        context.setShouldAntialias(true)
        context.setAllowsAntialiasing(true)
        context.interpolationQuality = .high
        
        context.translateBy(x: rendWidth * 0.5, y: rendHeight * 0.5)
        context.scaleBy(x: cropFactor.mirrorScale.x, y: cropFactor.mirrorScale.y)
        context.rotate(by: -cropFactor.angle.radians)
        
        let transform = CGAffineTransform(translationX: translationX, y: translationY)
        context.concatenate(transform)
        if cropFactor.isRound {
            context.addArc(
                center: .init(x: -translationX, y: -translationY),
                radius: max(rendWidth, rendHeight) * 0.5,
                startAngle: 0,
                endAngle: .pi * 2,
                clockwise: true
            )
            context.clip()
        }
        let rect = CGRect(origin: .init(x: -width * 0.5, y: -height * 0.5), size: CGSize(width: width, height: height))
        context.draw(imageRef, in: rect)
        guard let newImageRef = context.makeImage() else {
            return nil
        }
        let image: UIImage?
        if let maskImage = cropFactor.maskImage?.convertBlackImage()?.cgImage {
            guard let context = CGContext(
                data: nil,
                width: Int(rendWidth),
                height: Int(rendHeight),
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: bitmapRawValue
            ) else {
                return nil
            }
            context.setShouldAntialias(true)
            context.setAllowsAntialiasing(true)
            context.interpolationQuality = .high
            context.translateBy(x: rendWidth * 0.5, y: rendHeight * 0.5)
            context.clip(
                to: .init(x: -rendWidth * 0.5, y: -rendHeight * 0.5, width: rendWidth, height: rendHeight),
                mask: maskImage
            )
            let rect = CGRect(
                origin: .init(x: -rendWidth * 0.5, y: -rendHeight * 0.5),
                size: CGSize(width: rendWidth, height: rendHeight)
            )
            context.draw(newImageRef, in: rect)
            guard let newImageRef = context.makeImage() else {
                return nil
            }
            image = .init(cgImage: newImageRef)
        }else {
            image = .init(cgImage: newImageRef)
        }
        return image
    }
}
