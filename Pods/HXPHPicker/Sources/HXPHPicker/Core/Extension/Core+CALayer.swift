//
//  Core+CALayer.swift
//  HXPHPicker
//
//  Created by Slience on 2021/7/14.
//

import UIKit

extension CALayer {
    func convertedToImage(
        size: CGSize = .zero,
        scale: CGFloat = UIScreen.main.scale
    ) -> UIImage? {
        var toSize: CGSize
        if size.equalTo(.zero) {
            toSize = frame.size
        }else {
            toSize = size
        }
        UIGraphicsBeginImageContextWithOptions(toSize, false, scale)
        let context = UIGraphicsGetCurrentContext()
        render(in: context!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
