//
//  Core+UIBarButtonItem.swift
//  HXPhotoPickerExample
//
//  Created by Silence on 2025/6/22.
//  Copyright © 2025 Silence. All rights reserved.
//

import UIKit

extension UIBarButtonItem {
    
    static func initCustomView(customView: UIView) -> UIBarButtonItem {
        return .init(customView: customView).hidesShared()
    }
    
    @discardableResult
    func hidesShared() -> UIBarButtonItem {
#if canImport(UIKit.UIGlassEffect)
        if #available(iOS 26.0, *) {
            hidesSharedBackground = true
            sharesBackground = false
        }
#endif
        return self
    }
    
}
