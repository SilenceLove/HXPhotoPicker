//
//  Editor+UIImage.swift
//  HXPHPicker
//
//  Created by Slience on 2021/6/25.
//

import UIKit

extension UIImage {
    /// 生成马赛克图片
    func mosaicImage(level: CGFloat) -> UIImage? {
        let screenScale = level / max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        let scale = width * screenScale
        return filter(name: "CIPixellate", parameters: [kCIInputScaleKey: scale])
    }
    var ci_Image: CIImage? {
        guard let cgImage = self.cgImage else {
            return nil
        }
        return CIImage(cgImage: cgImage)
    }
    func filter(name: String, parameters: [String: Any]) -> UIImage? {
        guard let image = self.cgImage else {
            return nil
        }
    
        // 输入
        let input = CIImage(cgImage: image)
        // 输出
        let output = input.applyingFilter(name, parameters: parameters)

        // 渲染图片
        guard let cgimage = CIContext(options: nil).createCGImage(output, from: input.extent) else {
            return nil
        }
        return UIImage(cgImage: cgimage)
    }
    
    func animateCGImageFrame() -> ([CGImage], [Double], Double)? { // swiftlint:disable:this large_tuple
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
        #endif
        return nil
    }
    func animateImageFrame() -> ([UIImage], [Double], Double)? { // swiftlint:disable:this large_tuple
        guard let data = animateCGImageFrame() else { return nil }
        
        let cgImages = data.0
        let delays = data.1
        let gifDuration = data.2
        
        var images: [UIImage] = []
        for imageRef in cgImages {
            let image = UIImage.init(cgImage: imageRef, scale: 1, orientation: .up)
            images.append(image)
        }
        return (images, delays, gifDuration)
    }
}
