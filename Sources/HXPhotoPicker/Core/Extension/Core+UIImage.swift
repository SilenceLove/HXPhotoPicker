//
//  Core+UIImage.swift
//  HXPhotoPicker
//
//  Created by Silence on 2020/11/15.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit
import ImageIO
import CoreGraphics
import MobileCoreServices
import AVFoundation

extension UIImage {
    var width: CGFloat { size.width }
    var height: CGFloat { size.height }
    
    static func image(for named: String?) -> UIImage? {
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
    
    static var imageResource: HX.ImageResource {
        HX.ImageResource.shared
    }
    
    func scaleSuitableSize() -> UIImage? {
        var imageSize = self.size
        while imageSize.width * imageSize.height > 3 * 1000 * 1000 {
            imageSize.width *= 0.5
            imageSize.height *= 0.5
        }
        return self.scaleToFillSize(size: imageSize)
    }
    
    func scaleToFillSize(size: CGSize, mode: HX.ImageTargetMode = .fill, scale: CGFloat = 0) -> UIImage? {
        if self.size == size {
            return self
        }
        let rect: CGRect
        let rendererSize: CGSize
        if mode == .fill {
            let isEqualRatio = size.width / size.height == width / height
            if isEqualRatio {
                rendererSize = size
                rect = CGRect(origin: .zero, size: size)
            }else {
                let scale = size.width / width
                var scaleHeight = scale * height
                var scaleWidth = size.width
                if scaleHeight < size.height {
                    scaleWidth = size.height / scaleHeight * size.width
                    scaleHeight = size.height
                }
                rendererSize = .init(width: scaleWidth, height: scaleHeight)
                rect = .init(origin: .zero, size: rendererSize)
            }
        }else {
            rendererSize = size
            if mode == .fit {
                rect = CGRect(origin: .zero, size: size)
            }else {
                var x: CGFloat = 0
                var y: CGFloat = 0
                let scale = size.width / width
                var scaleWidth = size.width
                var scaleHeight = scale * height
                if scaleHeight < size.height {
                    scaleWidth = size.height / scaleHeight * scaleWidth
                    scaleHeight = size.height
                }
                if scaleWidth < size.width {
                    scaleHeight = size.width / scaleWidth * scaleHeight
                    scaleWidth = size.width
                }
                x = -(scaleWidth - size.width) / 2
                y = -(scaleHeight - size.height) / 2
                rect = CGRect(
                    x: x,
                    y: y,
                    width: scaleWidth,
                    height: scaleHeight
                )
            }
        }
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = scale == 0 ? self.scale : scale
        let renderer = UIGraphicsImageRenderer(size: rendererSize, format: format)
        let image = renderer.image { context in
            draw(in: rect)
        }
        return image
    }
    func scaleImage(toScale: CGFloat) -> UIImage? {
        if toScale == 1 {
            return self
        }
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width * toScale, height: height * toScale), format: format)
        let image = renderer.image { context in
            draw(in: CGRect(x: 0, y: 0, width: width * toScale, height: height * toScale))
        }
        return image
    }
    static func image(
        for color: UIColor?,
        havingSize: CGSize,
        radius: CGFloat = 0,
        scale: CGFloat = UIScreen._scale
    ) -> UIImage? {
        if let color = color {
            let rect: CGRect
            if havingSize.equalTo(CGSize.zero) {
                rect = CGRect(x: 0, y: 0, width: 1, height: 1)
            }else {
                rect = CGRect(x: 0, y: 0, width: havingSize.width, height: havingSize.height)
            }
            let format = UIGraphicsImageRendererFormat()
            format.opaque = false
            format.scale = scale
            let renderer = UIGraphicsImageRenderer(size: rect.size, format: format)
            let image = renderer.image { context in
                let cgContext = context.cgContext
                cgContext.setFillColor(color.cgColor)
                let path = UIBezierPath(roundedRect: rect, cornerRadius: radius).cgPath
                cgContext.addPath(path)
                cgContext.fillPath()
            }
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
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }
        return image
    }
    func roundCropping() -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        let newImage = renderer.image { context in
            let width = min(size.width, size.height)
            let rect = CGRect(x: (size.width - width) * 0.5, y: (size.height - width) * 0.5, width: width, height: width)
            let path = UIBezierPath(ovalIn: rect)
            path.addClip()
            draw(at: .zero)
        }
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
            let renderer = UIGraphicsImageRenderer(size: bnds.size)
            let newImage = renderer.image { context in
                let cgContext = context.cgContext
                switch orientation {
                case .left, .leftMirrored, .right, .rightMirrored:
                    cgContext.scaleBy(x: -1, y: 1)
                    cgContext.translateBy(x: -rect.height, y: 0)
                default:
                    cgContext.scaleBy(x: 1, y: -1)
                    cgContext.translateBy(x: 0, y: -rect.height)
                }
                cgContext.concatenate(trans)
                cgContext.draw(cgImage, in: rect)
            }
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
    func merge(_ image: UIImage, origin: CGPoint, opaque: Bool = false, isJPEG: Bool = false, scale: CGFloat = UIScreen._scale) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = opaque
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let mergeImage = renderer.image { context in
            image.draw(in: CGRect(origin: origin, size: size))
        }
        return mergeImage
    }
    func merge(
        images: [UIImage],
        opaque: Bool = false,
        isJPEG: Bool = false,
        compressionQuality: CGFloat = 1,
        scale: CGFloat = UIScreen._scale
    ) -> UIImage? {
        if images.isEmpty {
            return self
        }
        let format = UIGraphicsImageRendererFormat()
        format.opaque = opaque
        format.scale = scale
        if #available(iOS 12.0, *) {
            format.preferredRange = .standard
        }
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        if isJPEG {
            let data = renderer.jpegData(withCompressionQuality: compressionQuality) { context in
                draw(in: CGRect(origin: .zero, size: size))
                for image in images {
                    image.draw(in: CGRect(origin: .zero, size: size))
                }
            }
            return .init(data: data)
        }
        let mergeImage = renderer.image { context in
            draw(in: CGRect(origin: .zero, size: size))
            for image in images {
                image.draw(in: CGRect(origin: .zero, size: size))
            }
        }
        return mergeImage
    }
    
    static func merge(images: [UIImage], scale: CGFloat? = nil) -> UIImage? {
        if images.isEmpty {
            return nil
        }
        if images.count == 1 {
            return images.first
        }
        var _scale: CGFloat = 1
        if let scale = scale {
            _scale = scale
        }else {
            if !Thread.isMainThread {
                DispatchQueue.main.sync {
                    _scale = UIScreen._scale
                }
            }else {
                _scale = UIScreen._scale
            }
        }
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = _scale
        if #available(iOS 12.0, *) {
            format.preferredRange = .standard
        }
        let renderer = UIGraphicsImageRenderer(size: images.first!.size, format: format)
        let mergeImage = renderer.image { context in
            for image in images {
                image.draw(in: CGRect(origin: .zero, size: image.size))
            }
        }
        return mergeImage
    }
    static func gradualShadowImage(_ havingSize: CGSize) -> UIImage? {
        let layer = PhotoTools.getGradientShadowLayer(true)
        layer.frame = CGRect(origin: .zero, size: havingSize)
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = UIScreen._scale
        let renderer = UIGraphicsImageRenderer(size: havingSize, format: format)
        let image = renderer.image { context in
            layer.render(in: context.cgContext)
        }
        return image
    }
    
    static func HDRDecoded(_ data: Data) -> UIImage? {
        guard let sourceRef = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        let properties = CGImageSourceCopyPropertiesAtIndex(sourceRef, 0, nil) as? [AnyHashable: Any]
        let exifOrientation = {
            guard let orientation = properties?[kCGImagePropertyOrientation] as? UInt32 else {
                return CGImagePropertyOrientation.up
            }
            return CGImagePropertyOrientation(rawValue: orientation) ?? .up
        }()
        
        var decodingOptions: [AnyHashable: Any] = [
            kCGImageSourceShouldCacheImmediately: false
        ]
        if #available(macOS 14, iOS 17, tvOS 17, watchOS 10, *) {
            decodingOptions[kCGImageSourceDecodeRequest] = kCGImageSourceDecodeToHDR
        }
        guard let imageRef = CGImageSourceCreateImageAtIndex(sourceRef, 0, decodingOptions as CFDictionary) else {
            return nil
        }
        
        let image = UIImage(cgImage: imageRef, scale: 1.0, orientation: exifOrientation.imageOrientation)
        return image
    }
    
}

extension CGImagePropertyOrientation {
    var imageOrientation: UIImage.Orientation {
        switch self {
        case .up:
            return .up
        case .upMirrored:
            return .upMirrored
        case .down:
            return .down
        case .downMirrored:
            return .downMirrored
        case .left:
            return .left
        case .leftMirrored:
            return .leftMirrored
        case .right:
            return .right
        case .rightMirrored:
            return .rightMirrored
        default:
            return .up
        }
    }
}
