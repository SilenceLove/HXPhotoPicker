//
//  UIImage+HXPHPicker.swift
//  HXPHPickerExample
//
//  Created by 洪欣 on 2020/11/15.
//  Copyright © 2020 洪欣. All rights reserved.
//

import UIKit

extension UIImage {
    
    class func hx_named(named: String) -> UIImage? {
        let bundle = HXPHManager.shared.bundle
        var image : UIImage?
        if bundle != nil {
            let path = bundle?.path(forResource: "images/" + named, ofType: nil)
            if path != nil {
                image = self.init(named: path!)
            }
        }
        if image == nil {
            image = self.init(named: named)
        }
        return image
    }
    
    func hx_scaleSuitableSize() -> UIImage? {
        var imageSize = self.size
        while (imageSize.width * imageSize.height > 3 * 1000 * 1000) {
            imageSize.width *= 0.5
            imageSize.height *= 0.5
        }
        return self.hx_scaleToFillSize(size: imageSize)
    }
    func hx_scaleToFillSize(size: CGSize) -> UIImage? {
        if __CGSizeEqualToSize(self.size, size) {
            return self
        }
        UIGraphicsBeginImageContextWithOptions(size, false, self.scale)
        self.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    class func hx_image(for color: UIColor, havingSize: CGSize) -> UIImage? {
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
    
}
