//
//  Core+UIImage.swift
//  HXPHPickerExample
//
//  Created by Silence on 2020/11/15.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit
import ImageIO
import CoreGraphics
import MobileCoreServices
#if canImport(Kingfisher)
import Kingfisher
#endif

extension UIImage {
    var width : CGFloat {
        get {
            return size.width
        }
    }
    var height : CGFloat {
        get {
            return size.height
        }
    }
    
    class func image(for named: String?) -> UIImage? {
        if named == nil {
            return nil
        }
        let bundle = PhotoManager.shared.bundle
        var image : UIImage?
        if bundle != nil {
            var path = bundle?.path(forResource: "images", ofType: nil)
            if path != nil {
                path! += "/" + named!
                image = self.init(named: path!)
            }
        }
        if image == nil {
            image = self.init(named: named!)
        }
        return image
    }
    
    func scaleSuitableSize() -> UIImage? {
        var imageSize = self.size
        while (imageSize.width * imageSize.height > 3 * 1000 * 1000) {
            imageSize.width *= 0.5
            imageSize.height *= 0.5
        }
        return self.scaleToFillSize(size: imageSize)
    }
    func scaleToFillSize(size: CGSize) -> UIImage? {
        if __CGSizeEqualToSize(self.size, size) {
            return self
        }
        UIGraphicsBeginImageContextWithOptions(size, false, self.scale)
        self.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    class func image(for color: UIColor?, havingSize: CGSize) -> UIImage? {
        if let color = color {
            let rect: CGRect
            if havingSize.equalTo(CGSize.zero) {
                rect = CGRect(x: 0, y: 0, width: 1, height: 1)
            }else {
                rect = CGRect(x: 0, y: 0, width: havingSize.width, height: havingSize.height)
            }
            UIGraphicsBeginImageContext(rect.size)
            let context = UIGraphicsGetCurrentContext()
            context?.setFillColor(color.cgColor)
            context?.fill(rect)
        
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image
        }
        return nil
    }
    
    func normalizedImage() -> UIImage? {
        if imageOrientation == .up {
            return self
        }
        return repaintImage()
    }
    func repaintImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    func roundCropping() -> UIImage? {
        UIGraphicsBeginImageContext(size)
        let path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        path.addClip()
        draw(at: .zero)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    func cropImage(toRect cropRect: CGRect, viewWidth: CGFloat, viewHeight: CGFloat) -> UIImage? {
        let imageViewScale = max(size.width / viewWidth,
                                 size.height / viewHeight)

        // Scale cropRect to handle images larger than shown-on-screen size
        let cropZone = CGRect(x:cropRect.origin.x * imageViewScale,
                              y:cropRect.origin.y * imageViewScale,
                              width:cropRect.size.width * imageViewScale,
                              height:cropRect.size.height * imageViewScale)

        // Perform cropping in Core Graphics
        guard let cutImageRef: CGImage = cgImage?.cropping(to:cropZone)
        else {
            return nil
        }

        // Return image to UIImage
        let croppedImage: UIImage = UIImage(cgImage: cutImageRef)
        return croppedImage
    }
    
    func rotation(to orientation: UIImage.Orientation) -> UIImage? {
        if let cgImage = cgImage {
            func swapWidthAndHeight(_ toRect: CGRect) -> CGRect {
                var rect = toRect
                let swap = rect.width
                rect.size.width = rect.height
                rect.size.height = swap
                return rect
            }
            var rect = CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height)
            while rect.width * rect.height > 3 * 1000 * 1000 {
                rect.size.width = rect.width * 0.5
                rect.size.height = rect.height * 0.5
            }
            var trans: CGAffineTransform
            var bnds = rect
            switch orientation {
            case .up:
                return self
            case .upMirrored:
                trans = .init(translationX: rect.width, y: 0)
                trans = trans.scaledBy(x: -1, y: 1)
            case .down:
                trans = .init(translationX: rect.width, y: rect.height)
                trans = trans.rotated(by: CGFloat.pi)
            case .downMirrored:
                trans = .init(translationX: 0, y: rect.height)
                trans = trans.scaledBy(x: 1, y: -1)
            case .left:
                bnds = swapWidthAndHeight(bnds)
                trans = .init(translationX: 0, y: rect.width)
                trans = trans.rotated(by: 3 * CGFloat.pi * 0.5)
            case .leftMirrored:
                bnds = swapWidthAndHeight(bnds)
                trans = .init(translationX: rect.height, y: rect.width)
                trans = trans.scaledBy(x: -1, y: 1)
                trans = trans.rotated(by: 3 * CGFloat.pi * 0.5)
            case .right:
                bnds = swapWidthAndHeight(bnds)
                trans = .init(translationX: rect.height, y: 0)
                trans = trans.rotated(by: CGFloat.pi * 0.5)
            case .rightMirrored:
                bnds = swapWidthAndHeight(bnds)
                trans = .init(scaleX: -1, y: 1)
                trans = trans.rotated(by: CGFloat.pi * 0.5)
            default:
                return self
            }
            UIGraphicsBeginImageContext(bnds.size)
            let context = UIGraphicsGetCurrentContext()
            switch orientation {
            case .left, .leftMirrored, .right, .rightMirrored:
                context?.scaleBy(x: -1, y: 1)
                context?.translateBy(x: -rect.height, y: 0)
            default:
                context?.scaleBy(x: 1, y: -1)
                context?.translateBy(x: 0, y: -rect.height)
            }
            context?.concatenate(trans)
            context?.draw(cgImage, in: rect)
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return newImage
        }
        return nil
    }
    func rotation(angle: Int, isHorizontal: Bool) -> UIImage? {
        switch angle {
        case 0, 360:
            if isHorizontal {
                return rotation(to: .upMirrored)
            }
        case 90:
            if !isHorizontal {
                return rotation(to: .left)
            }else {
                return rotation(to: .rightMirrored)
            }
        case 180:
            if !isHorizontal {
                return rotation(to: .down)
            }else {
                return rotation(to: .downMirrored)
            }
        case 270:
            if !isHorizontal {
                return rotation(to: .right)
            }else {
                return rotation(to: .leftMirrored)
            }
        default:
            break
        }
        return self
    }
    func animateImageFrame() -> ([UIImage], [Double], Double)? {
        #if canImport(Kingfisher)
        if let imageData = kf.gifRepresentation() {
//            let info: [String: Any] = [
//                kCGImageSourceShouldCache as String: true,
//                kCGImageSourceTypeIdentifierHint as String: kUTTypeGIF
//            ]
            guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil) else {
                return nil
            }
            let frameCount = CGImageSourceGetCount(imageSource)
            
            var images = [UIImage]()
            var delays = [Double]()
            var gifDuration = 0.0
            
            for i in 0 ..< frameCount {
                guard let imageRef = CGImageSourceCreateImageAtIndex(imageSource, i, nil) else {
                    return nil
                }
                var delay: Double
                if frameCount == 1 {
                    delay = .infinity
                    gifDuration = .infinity
                } else {
                    // Get current animated GIF frame duration
                    delay = PhotoTools.getFrameDuration(from: imageSource, at: i)
                    gifDuration += delay
                }
                let image = UIImage.init(cgImage: imageRef, scale: 1, orientation: .up)
                images.append(image)
                delays.append(delay)
            }
            return (images, delays, gifDuration)
        }
        #endif
        return nil
    }
}
