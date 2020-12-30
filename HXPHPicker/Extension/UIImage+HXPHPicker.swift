//
//  UIImage+HXPHPicker.swift
//  HXPHPickerExample
//
//  Created by Silence on 2020/11/15.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

public extension UIImage {
    
    class func image(for named: String?) -> UIImage? {
        if named == nil {
            return nil
        }
        let bundle = HXPHManager.shared.bundle
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
    
    class func image(for color: UIColor, havingSize: CGSize) -> UIImage? {
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
}
