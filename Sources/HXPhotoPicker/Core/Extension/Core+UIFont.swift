//
//  Core+UIFont.swift
//  HXPhotoPicker
//
//  Created by Silence on 2020/11/13.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

extension UIFont: HXPickerCompatibleValue {
    
    static var textManager: HX.TextManager {
        HX.TextManager.shared
    }
    
    #if HXPICKER_ENABLE_PICKER || HXPICKER_ENABLE_CAMERA
    static var textNotAuthorized: HX.TextManager.Picker.NotAuthorized {
        textManager.picker.notAuthorized
    }
    #endif
    
    #if HXPICKER_ENABLE_PICKER
    static var textPhotoList: HX.TextManager.Picker.PhotoList {
        textManager.picker.photoList
    }
    
    static var textPreview: HX.TextManager.Picker.Preview {
        textManager.picker.preview
    }
    #endif
    
    static func regularPingFang(ofSize size: CGFloat) -> UIFont {
        if let font = UIFont.init(name: "PingFangSC-Regular", size: size) {
            return font
        }
        return .systemFont(ofSize: size, weight: .regular)
    }
    
    static func mediumPingFang(ofSize size: CGFloat) -> UIFont {
        if let font = UIFont.init(name: "PingFangSC-Medium", size: size) {
            return font
        }
        return .systemFont(ofSize: size, weight: .medium)
    }
    
    static func semiboldPingFang(ofSize size: CGFloat) -> UIFont {
        if let font = UIFont.init(name: "PingFangSC-Semibold", size: size) {
            return font
        }
        return .systemFont(ofSize: size, weight: .semibold)
    }
}

public extension HXPickerWrapper where Base == UIFont {
    
    static func regularPingFang(ofSize size: CGFloat) -> UIFont {
        Base.regularPingFang(ofSize: size)
    }
    
    static func mediumPingFang(ofSize size: CGFloat) -> UIFont {
        Base.mediumPingFang(ofSize: size)
    }
    
    static func semiboldPingFang(ofSize size: CGFloat) -> UIFont {
        Base.semiboldPingFang(ofSize: size)
    }
}
