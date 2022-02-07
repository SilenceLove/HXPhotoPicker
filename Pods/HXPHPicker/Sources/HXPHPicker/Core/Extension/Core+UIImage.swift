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
    var width: CGFloat {
        size.width
    }
    var height: CGFloat {
        size.height
    }
    
    class func image(for named: String?) -> UIImage? {
        if named == nil {
            return nil
        }
        let bundle = PhotoManager.shared.bundle
        var image: UIImage?
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
        while imageSize.width * imageSize.height > 3 * 1000 * 1000 {
            imageSize.width *= 0.5
            imageSize.height *= 0.5
        }
        return self.scaleToFillSize(size: imageSize)
    }
    func scaleToFillSize(size: CGSize, equalRatio: Bool = false, scale: CGFloat = 0) -> UIImage? {
        if __CGSizeEqualToSize(self.size, size) {
            return self
        }
        let scale = scale == 0 ? self.scale : scale
        let rect: CGRect
        if size.width / size.height != width / height && equalRatio {
            let scale = size.width / width
            var scaleHeight = scale * height
            var scaleWidth = size.width
            if scaleHeight < size.height {
                scaleWidth = size.height / scaleHeight * size.width
                scaleHeight = size.height
            }
            rect = CGRect(
                x: -(scaleWidth - size.height) * 0.5,
                y: -(scaleHeight - size.height) * 0.5,
                width: scaleWidth,
                height: scaleHeight
            )
        }else {
            rect = CGRect(origin: .zero, size: size)
        }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        self.draw(in: rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    func scaleImage(toScale: CGFloat) -> UIImage? {
        if toScale == 1 {
            return self
        }
        UIGraphicsBeginImageContextWithOptions(
            CGSize(width: width * toScale, height: height * toScale),
            false,
            self.scale
        )
        self.draw(in: CGRect(x: 0, y: 0, width: width * toScale, height: height * toScale))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    class func image(for color: UIColor?, havingSize: CGSize, radius: CGFloat = 0) -> UIImage? {
        if let color = color {
            let rect: CGRect
            if havingSize.equalTo(CGSize.zero) {
                rect = CGRect(x: 0, y: 0, width: 1, height: 1)
            }else {
                rect = CGRect(x: 0, y: 0, width: havingSize.width, height: havingSize.height)
            }
            UIGraphicsBeginImageContextWithOptions(rect.size, false, UIScreen.main.scale)
            let context = UIGraphicsGetCurrentContext()
            context?.setFillColor(color.cgColor)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: radius).cgPath
            context?.addPath(path)
            context?.fillPath()
        
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
        if cropRect.isEmpty {
            return self
        }
        let imageViewScale = max(size.width / viewWidth,
                                 size.height / viewHeight)

        // Scale cropRect to handle images larger than shown-on-screen size
        let cropZone = CGRect(
            x: cropRect.origin.x * imageViewScale,
            y: cropRect.origin.y * imageViewScale,
            width: cropRect.size.width * imageViewScale,
            height: cropRect.size.height * imageViewScale
        )

        // Perform cropping in Core Graphics
        guard let cutImageRef: CGImage = cgImage?.cropping(to: cropZone)
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
        case 0, 360, -360:
            if isHorizontal {
                return rotation(to: .upMirrored)
            }
        case 90, -270:
            if !isHorizontal {
                return rotation(to: .right)
            }else {
                return rotation(to: .rightMirrored)
            }
        case 180, -180:
            if !isHorizontal {
                return rotation(to: .down)
            }else {
                return rotation(to: .downMirrored)
            }
        case 270, -90:
            if !isHorizontal {
                return rotation(to: .left)
            }else {
                return rotation(to: .leftMirrored)
            }
        default:
            break
        }
        return self
    }
    func merge(_ image: UIImage, origin: CGPoint, scale: CGFloat = UIScreen.main.scale) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        image.draw(in: CGRect(origin: origin, size: size))
        let mergeImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return mergeImage
    }
    func merge(images: [UIImage], scale: CGFloat = UIScreen.main.scale) -> UIImage? {
        if images.isEmpty {
            return self
        }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        for image in images {
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        let mergeImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return mergeImage
    }
    
    class func merge(images: [UIImage], scale: CGFloat = UIScreen.main.scale) -> UIImage? {
        if images.isEmpty {
            return nil
        }
        if images.count == 1 {
            return images.first
        }
        UIGraphicsBeginImageContextWithOptions(images.first!.size, false, scale)
        for image in images {
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
        let mergeImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return mergeImage
    }
    class func gradualShadowImage(_ havingSize: CGSize) -> UIImage? {
        let layer = PhotoTools.getGradientShadowLayer(true)
        layer.frame = CGRect(origin: .zero, size: havingSize)
        UIGraphicsBeginImageContextWithOptions(havingSize, false, UIScreen.main.scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        layer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
