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
        scale: CGFloat? = nil
    ) -> UIImage? {
        var toSize: CGSize
        if size.equalTo(.zero) {
            toSize = frame.size
        }else {
            toSize = size
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
        let renderer = UIGraphicsImageRenderer(size: toSize, format: format)
        let image = renderer.image { context in
            render(in: context.cgContext)
        }
        return image
    }
}
