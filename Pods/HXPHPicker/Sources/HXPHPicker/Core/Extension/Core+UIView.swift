//
//  Core+UIView.swift
//  HXPhotoPickerSwift
//
//  Created by Silence on 2020/11/12.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

extension UIView {
    var x : CGFloat {
        get {
            return frame.origin.x
        }
        set {
            var rect = frame
            rect.origin.x = newValue
            frame = rect
        }
    }
    var y : CGFloat {
        get {
            return frame.origin.y
        }
        set {
            var rect = frame
            rect.origin.y = newValue
            frame = rect
        }
    }
    var width : CGFloat {
        get {
            return frame.width
        }
        set {
            var rect = frame
            rect.size.width = newValue
            frame = rect
        }
    }
    var height : CGFloat {
        get {
            return frame.height
        }
        set {
            var rect = frame
            rect.size.height = newValue
            frame = rect
        }
    }
    var size : CGSize {
        get {
            return frame.size
        }
        set {
            var rect = frame
            rect.size = newValue
            frame = rect
        }
    }
    var centerX : CGFloat {
        get {
            return center.x
        }
        set {
            var point = center
            point.x = newValue
            center = point
        }
    }
    var centerY : CGFloat {
        get {
            return center.y
        }
        set {
            var point = center
            point.y = newValue
            center = point
        }
    }
    
    func viewController() -> UIViewController? {
        var next = superview
        while (next != nil) {
            let nextResponder = next?.next
            if nextResponder is UINavigationController ||
                nextResponder is UIViewController {
                return nextResponder as? UIViewController
            }
            next = next?.superview
        }
        return nil
    }
    
    /// UIView转UIImage
    /// - Returns: UIImage
    func convertedToImage(rect: CGRect = .zero) -> UIImage? {
        var size = bounds.size
        var origin = bounds.origin
        if !size.equalTo(rect.size) && !rect.isEmpty {
            size = rect.size
            origin = CGPoint(x: -rect.minX, y: -rect.minY)
        }
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        drawHierarchy(in: CGRect(origin: origin, size: bounds.size), afterScreenUpdates: true)
//        let context = UIGraphicsGetCurrentContext()
//        layer.render(in: context!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
