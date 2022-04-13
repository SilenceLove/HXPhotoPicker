//
//  Core+UIDevice.swift
//  HXPHPickerExample
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
        isAllIPhoneX ? 44 : 20
    }
    class var statusBarHeight: CGFloat {
        let statusBarHeight: CGFloat
        let window = UIApplication.shared.windows.first
        if #available(iOS 13.0, *) {
            statusBarHeight = (window?.windowScene?.statusBarManager?.statusBarFrame.size.height)!
        } else {
            statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        }
        return statusBarHeight
    }
    class var topMargin: CGFloat {
        if isAllIPhoneX {
            return statusBarHeight
        }
        return 0
    }
    class var leftMargin: CGFloat {
        if isAllIPhoneX {
            if !isPortrait {
                return 44
            }
        }
        return 0
    }
    class var rightMargin: CGFloat {
        if isAllIPhoneX {
            if !isPortrait {
                return 44
            }
        }
        return 0
    }
    class var bottomMargin: CGFloat {
        if isAllIPhoneX {
            if isPortrait {
                return 34
            }else {
                return 21
            }
        }
        return 0
    }
    class var isPad: Bool {
        current.userInterfaceIdiom == .pad
    }
    class var isAllIPhoneX: Bool {
        (isIPhoneX ||
            isIPhoneXR ||
            isIPhoneXsMax ||
            isIPhoneXsMax ||
            isIPhoneTwelveMini ||
            isIPhoneTwelve || isIPhoneTwelveProMax
        )
    }
    class var isIPhoneX: Bool {
        if  UIScreen.instancesRespond(to: Selector(("currentMode"))) == true &&
            isPad == false {
            if __CGSizeEqualToSize(CGSize(width: 1125, height: 2436), UIScreen.main.currentMode!.size) {
                return true
            }
        }
        return false
    }
    class var isIPhoneXR: Bool {
        if  UIScreen.instancesRespond(to: Selector(("currentMode"))) == true &&
            isPad == false {
            if __CGSizeEqualToSize(CGSize(width: 828, height: 1792), UIScreen.main.currentMode!.size) {
                return true
            }
        }
        return false
    }
    class var isIPhoneXsMax: Bool {
        if  UIScreen.instancesRespond(to: Selector(("currentMode"))) == true &&
            isPad == false {
            if __CGSizeEqualToSize(CGSize(width: 1242, height: 2688), UIScreen.main.currentMode!.size) {
                return true
            }
        }
        return false
    }
    class var isIPhoneTwelveMini: Bool {
        if  UIScreen.instancesRespond(to: Selector(("currentMode"))) == true &&
            isPad == false {
            if __CGSizeEqualToSize(CGSize(width: 1080, height: 2340), UIScreen.main.currentMode!.size) {
                return true
            }
        }
        return false
    }
    class var isIPhoneTwelve: Bool {
        if  UIScreen.instancesRespond(to: Selector(("currentMode"))) == true &&
            isPad == false {
            if __CGSizeEqualToSize(CGSize(width: 1170, height: 2532), UIScreen.main.currentMode!.size) {
                return true
            }
        }
        return false
    }
    class var isIPhoneTwelveProMax: Bool {
        if  UIScreen.instancesRespond(to: Selector(("currentMode"))) == true &&
            isPad == false {
            if __CGSizeEqualToSize(CGSize(width: 1284, height: 2778), UIScreen.main.currentMode!.size) {
                return true
            }
        }
        return false
    }
    class var belowIphone7: Bool {
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
        switch identifier {
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
