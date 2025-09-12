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
        if #available(iOS 14.0, *), ProcessInfo.processInfo.isiOSAppOnMac {
            return true
        }
        if isPad {
            return true
        }
        let statusBarOrientation = UIApplication.hx_interfaceOrientation
        if  statusBarOrientation == .landscapeLeft ||
            statusBarOrientation == .landscapeRight {
            return false
        }
        return true
    }
    class var navigationBarHeight: CGFloat {
        if #available(iOS 12, *), isPad {
            return statusBarHeight + 50
        }
        return statusBarHeight + 44
    }
    class var navBarHeight: CGFloat {
        if #available(iOS 12, *), isPad {
            return  50
        }
        return 44
    }
    class var generalStatusBarHeight: CGFloat {
        if isPad {
            return 24
        }
        if isIPhoneXR || isIPhone11 {
            return 48
        }
        if isIPhone12 || isIPhone12Pro || isIPhone12ProMax ||
            isIPhone13 || isIPhone13Pro || isIPhone13ProMax ||
            isIPhone14 || isIPhone14Plus {
            return 47
        }
        if isIPhone12Mini || isIPhone13Mini {
            return 50
        }
        if isIPhone14Pro || isIPhone14ProMax || isIPhone15 {
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
        if UIDevice.isPad {
            #if HXPICKER_ENABLE_PICKER
            if let controller = UIViewController.topViewController?.navigationController as? PhotoPickerController,
               controller.modalPresentationStyle == .pageSheet {
                return 0
            }else if let controller = UIViewController.topViewController as? PhotoSplitViewController,
                     controller.modalPresentationStyle == .formSheet {
                return 0
            }
            #endif
        }
        return safeAreaInsets.bottom
    }
    class var isPad: Bool {
        if #available(iOS 14.0, *), ProcessInfo.processInfo.isiOSAppOnMac {
            return true
        }
        return current.userInterfaceIdiom == .pad
    }
    class var screenSize: CGSize {
        if #available(iOS 14.0, *), ProcessInfo.processInfo.isiOSAppOnMac {
            if !Thread.isMainThread {
                return UIScreen._size
            }
            if let size = UIApplication.hx_keyWindow?.size {
                return size
            }
        }
        return UIScreen._size
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
            if let safeAreaInsets = UIApplication.hx_keyWindow?.safeAreaInsets {
                return safeAreaInsets
            }
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
        phoneIdentifier == "iPhone11,8"
    }
    class var isIPhone11: Bool {
        phoneIdentifier == "iPhone12,1"
    }
    class var isIPhone12Mini: Bool {
        phoneIdentifier == "iPhone13,1"
    }
    class var isIPhone12: Bool {
        phoneIdentifier == "iPhone13,2"
    }
    class var isIPhone12Pro: Bool {
        phoneIdentifier == "iPhone13,3"
    }
    class var isIPhone12ProMax: Bool {
        phoneIdentifier == "iPhone13,4"
    }
    class var isIPhone13: Bool {
        phoneIdentifier == "iPhone14,5"
    }
    class var isIPhone13Mini: Bool {
        phoneIdentifier == "iPhone14,4"
    }
    class var isIPhone13Pro: Bool {
        phoneIdentifier == "iPhone14,2"
    }
    class var isIPhone13ProMax: Bool {
        phoneIdentifier == "iPhone14,3"
    }
    class var isIPhone14: Bool {
        phoneIdentifier == "iPhone14,7"
    }
    class var isIPhone14Plus: Bool {
        phoneIdentifier == "iPhone14,8"
    }
    class var isIPhone14Pro: Bool {
        phoneIdentifier == "iPhone15,2"
    }
    class var isIPhone14ProMax: Bool {
        phoneIdentifier == "iPhone15,3"
    }
    class var isIPhone15: Bool {
        phoneIdentifier == "iPhone15,4" || phoneIdentifier == "iPhone15,5" ||
        phoneIdentifier == "iPhone16,1" || phoneIdentifier == "iPhone16,2"
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
