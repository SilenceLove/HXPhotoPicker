//
//  EditorView+UIImage.swift
//  HXPhotoPicker
//
//  Created by Slience on 2023/1/31.
//

import UIKit

extension Data {
    func animateCGImageFrame(
    ) -> (cgImages: [CGImage], delays: [Double], duration: Double)? { // swiftlint:disable:this large_tuple
        let imageData = self
        guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil) else {
            return nil
        }
        let frameCount = CGImageSourceGetCount(imageSource)
        if frameCount <= 1, !isGif {
            return nil
        }
        var images = [CGImage]()
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
            images.append(imageRef)
            delays.append(delay)
        }
        return (images, delays, gifDuration)
    }
    
    func animateImageFrame(
    ) -> (images: [UIImage], delays: [Double], duration: Double)? { // swiftlint:disable:this large_tuple
        guard let data = animateCGImageFrame() else { return nil }
        
        let cgImages = data.0
        let delays = data.1
        let gifDuration = data.2
        
        var images: [UIImage] = []
        for imageRef in cgImages {
            let image = UIImage(cgImage: imageRef, scale: 1, orientation: .up)
            images.append(image)
        }
        return (images, delays, gifDuration)
    }
}
extension UIImage {
    var ci_Image: CIImage? {
        guard let cgImage = self.cgImage else {
            return nil
        }
        return CIImage(cgImage: cgImage)
    }
    
    func convertBlackImage() -> UIImage? {
        let rect = CGRect(origin: .zero, size: size)
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = UIScreen._scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            UIColor.black.setFill()
            UIRectFill(rect)
            draw(in: rect, blendMode: .destinationOut, alpha: 1)
        }
        return image
    }
}
