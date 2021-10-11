//
//  UIImage+Extension.swift
//  Example
//
//  Created by Slience on 2021/1/13.
//

import UIKit

extension UIImage {
    
    class func image(for named: String?) -> UIImage? {
        return self.init(named: named!)
    }
    
    func scaleSuitableSize() -> UIImage? {
        var imageSize = self.size
        while imageSize.width * imageSize.height > 3 * 1000 * 1000 {
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
    
    class func gradualShadowImage(_ havingSize: CGSize) -> UIImage? {
        let layer = CAGradientLayer.init()
        layer.contentsScale = UIScreen.main.scale
        let blackColor = UIColor.black
        layer.colors = [blackColor.withAlphaComponent(0).cgColor,
                        blackColor.withAlphaComponent(0.3).cgColor,
                        blackColor.withAlphaComponent(0.4).cgColor,
                        blackColor.withAlphaComponent(0.5).cgColor,
                        blackColor.withAlphaComponent(0.6).cgColor]
        layer.startPoint = CGPoint(x: 0, y: 1)
        layer.endPoint = CGPoint(x: 0, y: 0)
        layer.locations = [0.1, 0.3, 0.5, 0.7, 0.9]
        layer.borderWidth = 0.0
        layer.frame = CGRect(origin: .zero, size: havingSize)
        UIGraphicsBeginImageContextWithOptions(havingSize, false, UIScreen.main.scale)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
