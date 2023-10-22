//
//  Core+CALayer.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/7/14.
//

import UIKit

extension CALayer {
    func convertedToImage(
        size: CGSize = .zero,
        scale: CGFloat = UIScreen._scale
    ) -> UIImage? {
        var toSize: CGSize
        if size.equalTo(.zero) {
            toSize = frame.size
        }else {
            toSize = size
        }
        UIGraphicsBeginImageContextWithOptions(toSize, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
