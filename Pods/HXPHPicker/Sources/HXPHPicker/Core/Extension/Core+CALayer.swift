//
//  Core+CALayer.swift
//  HXPHPicker
//
//  Created by Slience on 2021/7/14.
//

import UIKit

extension CALayer {
    func convertedToImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(frame.size, false, UIScreen.main.scale)
        let context = UIGraphicsGetCurrentContext()
        render(in: context!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
