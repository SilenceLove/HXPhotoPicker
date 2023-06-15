//
//  Core+UIDevice.swift
//  HXPhotoPicker
//
//  Created by Silence on 2020/11/13.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

extension UIDevice {
    class var isPortrait: Bool {
        if isPad {
            return true
        }
        if  statusBarOrientation == .landscapeLeft ||
                statusBarOrientation == .landscapeRight {
            return false
        }
        return true
    }
    class var statusBarOrientation: UIInterfaceOrientation {
        UIApplication.shared.statusBarOrientation
    }
    class var navigationBarHeight: CGFloat {
        if isPad {
            if #available(iOS 12, *) {
                return statusBarHeight + 50
            }
        }
        return statusBarHeight + 44
    }
    class var generalStatusBarHeight: CGFloat {
        if isIPhoneXR || isIPhone11 {
            return 48
        }
        if isIPhone12 || isIPhone12Pro || isIPhone12ProMax || isIPhone13 || isIPhone13Pro || isIPhone13ProMax || isIPhone14 || isIPhone14Plus {
            return 47
        }
        if isIPhone12Mini || isIPhone13Mini {
            return 50
        }
        if isIPhone14Pro || isIPhone14ProMax {
            return 54
        }
        return isAllIPhoneX ? 44 : 20
    }
    class var statusBarHeight: CGFloat {
        let statusBarHeight: CGFloat
        let window = UIApplication.shared.windows.first
        if #available(iOS 13.0, *),
           let height = window?.windowScene?.statusBarManager?.statusBarFrame.size.height {
            statusBarHeight = height
        } else {
            statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        }
        return statusBarHeight
    }
    class var topMargin: CGFloat {
        safeAreaInsets.top
    }
    class var leftMargin: CGFloat {
        safeAreaInsets.left
    }
    class var rightMargin: CGFloat {
        safeAreaInsets.right
    }
    class var bottomMargin: CGFloat {
        safeAreaInsets.bottom
    }
    class var isPad: Bool {
        current.userInterfaceIdiom == .pad
    }
    class var isAllIPhoneX: Bool {
        let safeArea = safeAreaInsets
        let margin: CGFloat
        if isPortrait {
            margin = safeArea.bottom
        }else {
            margin = safeArea.left
        }
        return margin != 0
    }
    
    class var safeAreaInsets: UIEdgeInsets {
        if #available(iOS 11.0, *) {
            return UIApplication._keyWindow?.safeAreaInsets ?? .zero
        }
        return .zero
    }
    
    class var phoneIdentifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        
        let identifier = machineMirror
            .children.reduce("") { identifier, element in
                guard let value = element.value as? Int8,
                      value != 0 else {
                    return identifier
                }
                return identifier + String(UnicodeScalar(UInt8(value)))
            }
        return identifier
    }
    
    class var isIPhoneXR: Bool {
        switch phoneIdentifier { case "iPhone11,8": return true default: return false }
    }
    class var isIPhone11: Bool {
        switch phoneIdentifier { case "iPhone12,1": return true default: return false }
    }
    class var isIPhone12Mini: Bool {
        switch phoneIdentifier { case "iPhone13,1": return true default: return false }
    }
    class var isIPhone12: Bool {
        switch phoneIdentifier { case "iPhone13,2": return true default: return false }
    }
    class var isIPhone12Pro: Bool {
        switch phoneIdentifier { case "iPhone13,3": return true default: return false }
    }
    class var isIPhone12ProMax: Bool {
        switch phoneIdentifier { case "iPhone13,4": return true default: return false }
    }
    class var isIPhone13: Bool {
        switch phoneIdentifier { case "iPhone14,5": return true default: return false }
    }
    class var isIPhone13Mini: Bool {
        switch phoneIdentifier { case "iPhone14,4": return true default: return false }
    }
    class var isIPhone13Pro: Bool {
        switch phoneIdentifier { case "iPhone14,2": return true default: return false }
    }
    class var isIPhone13ProMax: Bool {
        switch phoneIdentifier { case "iPhone14,3": return true default: return false }
    }
    class var isIPhone14: Bool {
        switch phoneIdentifier { case "iPhone14,7": return true default: return false }
    }
    class var isIPhone14Plus: Bool {
        switch phoneIdentifier { case "iPhone14,8": return true default: return false }
    }
    class var isIPhone14Pro: Bool {
        switch phoneIdentifier { case "iPhone15,2": return true default: return false }
    }
    class var isIPhone14ProMax: Bool {
        switch phoneIdentifier { case "iPhone15,3": return true default: return false }
    }
    
    class var belowIphone7: Bool {
        switch phoneIdentifier {
        case "iPhone1,1":
            return true
        case "iPhone1,2":
            return true
        case "iPhone2,1":
            return true
        case "iPhone3,1":
            return true
        case "iPhone4,1":
            return true
        case "iPhone5,1":
            return true
        case "iPhone5,2":
            return true
        case "iPhone5,3":
            return true
        case "iPhone5,4":
            return true
        case "iPhone6,1":
            return true
        case "iPhone6,2":
            return true
        case "iPhone7,1":
            return true
        case "iPhone7,2":
            return true
        case "iPhone8,1":
            return true
        case "iPhone8,2":
            return true
        case "iPhone8,4":
            return true
        default:
            return false
        }
    }
}
