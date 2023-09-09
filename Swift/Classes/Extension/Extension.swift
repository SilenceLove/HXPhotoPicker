//
//  Extension.swift
//  HXPhotoPickerExample
//
//  Created by Silence on 2023/9/3.
//  Copyright © 2023 洪欣. All rights reserved.
//

import UIKit

#if canImport(Kingfisher)
import Kingfisher
#endif

extension UIView {
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
}

extension URL {
    
    #if canImport(Kingfisher)
    var isCache: Bool {
        ImageCache.default.isCached(forKey: cacheKey)
    }
    #endif
}

extension FileManager {
    class var documentPath: String {
        guard let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last else {
            return ""
        }
        return documentPath
    }
    class var cachesPath: String {
        guard let cachesPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).last else {
            return ""
        }
        return cachesPath
    }
    class var tempPath: String {
        NSTemporaryDirectory()
    }
}


extension UIViewController {
    func presendAlert(_ alert: UIAlertController) {
        if UIDevice.isPad {
            let pop = alert.popoverPresentationController
            pop?.permittedArrowDirections = .any
            pop?.sourceView = view
            pop?.sourceRect = CGRect(
                x: view.width * 0.5,
                y: view.height,
                width: 0,
                height: 0
            )
        }
        present(alert, animated: true)
    }
}

extension CGSize {
    var title: String {
        if width == 0 || height == 0 {
            return "free"
        }
        return String(format: "%.0f:%.0f", width, height)
    }
}
