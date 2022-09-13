//
//  Core+UIView.swift
//  HXPhotoPickerSwift
//
//  Created by Silence on 2020/11/12.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

extension UIView: HXPickerCompatible {
    var x: CGFloat {
        get { frame.origin.x }
        set {
            var rect = frame
            rect.origin.x = newValue
            frame = rect
        }
    }
    var y: CGFloat {
        get { frame.origin.y }
        set {
            var rect = frame
            rect.origin.y = newValue
            frame = rect
        }
    }
    var width: CGFloat {
        get { frame.width }
        set {
            var rect = frame
            rect.size.width = newValue
            frame = rect
        }
    }
    var height: CGFloat {
        get { frame.height }
        set {
            var rect = frame
            rect.size.height = newValue
            frame = rect
        }
    }
    var size: CGSize {
        get { frame.size }
        set {
            var rect = frame
            rect.size = newValue
            frame = rect
        }
    }
    var centerX: CGFloat {
        get { center.x }
        set {
            var point = center
            point.x = newValue
            center = point
        }
    }
    var centerY: CGFloat {
        get { center.y }
        set {
            var point = center
            point.y = newValue
            center = point
        }
    }
    
    var viewController: UIViewController? {
        var next = superview
        while next != nil {
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

public extension HXPickerWrapper where Base: UIView {
    var x: CGFloat {
        get { base.x }
        set { base.x = newValue }
    }
    var y: CGFloat {
        get { base.y }
        set { base.y = newValue }
    }
    var width: CGFloat {
        get { base.width }
        set { base.width = newValue }
    }
    var height: CGFloat {
        get { base.height }
        set { base.height = newValue }
    }
    var size: CGSize {
        get { base.size }
        set { base.size = newValue }
    }
    var centerX: CGFloat {
        get { base.centerX }
        set { base.centerX = newValue }
    }
    var centerY: CGFloat {
        get { base.centerY }
        set { base.centerY = newValue }
    }
    var viewController: UIViewController? {
        base.viewController
    }
    
    func show(
        text: String? = nil,
        delayShow: TimeInterval = 0,
        indicatorType: BaseConfiguration.IndicatorType = .system,
        animated: Bool = true
    ) {
        ProgressHUD.showLoading(
            addedTo: base,
            text: text,
            afterDelay: delayShow,
            animated: animated,
            indicatorType: indicatorType
        )
    }
    func showWarning(
        text: String? = nil,
        delayHide: TimeInterval,
        animated: Bool = true
    ) {
        ProgressHUD.showWarning(
            addedTo: base,
            text: text,
            animated: animated,
            delayHide: delayHide
        )
    }
    func showSuccess(
        text: String? = nil,
        delayHide: TimeInterval,
        animated: Bool = true
    ) {
        ProgressHUD.showSuccess(
            addedTo: base,
            text: text,
            animated: animated,
            delayHide: delayHide
        )
    }
    func hide(
        delay: TimeInterval = 0,
        animated: Bool = true
    ) {
        ProgressHUD.hide(
            forView: base,
            animated: animated,
            afterDelay: delay
        )
    }
}
