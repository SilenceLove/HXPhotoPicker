//
//  Editor+PhotoTools.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/9.
//

import Foundation
import ImageIO
import CoreServices

extension PhotoTools {
    class func createAnimatedImageURL(images: [UIImage],
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
}
