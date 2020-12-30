//
//  UIDevice+HXPHPicker.swift
//  HXPHPickerExample
//
//  Created by Silence on 2020/11/13.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

public extension UIDevice {
    var isPortrait: Bool {
        get {
            let orientation = UIApplication.shared.statusBarOrientation
            if  orientation == .landscapeLeft ||
                orientation == .landscapeRight {
                return false
            }
            return true
        }
    }
    var navigationBarHeight: CGFloat {
        get {
            return statusBarHeight + 44
        }
    }
    var statusBarHeight: CGFloat {
        get {
            let statusBarHeight : CGFloat;
            let window = UIApplication.shared.windows.first
            if #available(iOS 13.0, *) {
                statusBarHeight = (window?.windowScene?.statusBarManager?.statusBarFrame.size.height)!
            } else {
                // Fallback on earlier versions
//                if UIApplication.shared.isStatusBarHidden {
//                    return isAllIPhoneX ? 44 : 20
//                }
                statusBarHeight = UIApplication.shared.statusBarFrame.size.height
            }
            return statusBarHeight
        }
    }
    var topMargin: CGFloat {
        get {
            if isAllIPhoneX {
                return statusBarHeight
            }
            return 0
        }
    }
    var leftMargin: CGFloat {
        get {
            if isAllIPhoneX {
                if !isPortrait {
                    return 44
                }
            }
            return 0
        }
    }
    var rightMargin: CGFloat {
        get {
            if isAllIPhoneX {
                if !isPortrait {
                    return 44
                }
            }
            return 0
        }
    }
    var bottomMargin: CGFloat {
        get {
            if isAllIPhoneX {
                if isPortrait {
                    return 34
                }else {
                    return 21
                }
            }
            return 0
        }
    }
    var isPad: Bool {
        get {
            return UI_USER_INTERFACE_IDIOM() == .pad
        }
    }
    var isAllIPhoneX: Bool {
        get {
            return (isIPhoneX || isIPhoneXR || isIPhoneXsMax || isIPhoneXsMax || isIPhoneTwelveMini || isIPhoneTwelve || isIPhoneTwelveProMax)
        }
    }
    var isIPhoneX: Bool {
        get {
            if  UIScreen.instancesRespond(to: Selector(("currentMode"))) == true &&
                isPad == false {
                if __CGSizeEqualToSize(CGSize(width: 1125, height: 2436), UIScreen.main.currentMode!.size) {
                    return true
                }
            }
            return false
        }
    }
    var isIPhoneXR: Bool {
        get {
            if  UIScreen.instancesRespond(to: Selector(("currentMode"))) == true &&
                isPad == false {
                if __CGSizeEqualToSize(CGSize(width: 828, height: 1792), UIScreen.main.currentMode!.size) {
                    return true
                }
            }
            return false
        }
    }
    var isIPhoneXsMax: Bool {
        get {
            if  UIScreen.instancesRespond(to: Selector(("currentMode"))) == true &&
                isPad == false {
                if __CGSizeEqualToSize(CGSize(width: 1242, height: 2688), UIScreen.main.currentMode!.size) {
                    return true
                }
            }
            return false
        }
    }
    var isIPhoneTwelveMini: Bool {
        get {
            if  UIScreen.instancesRespond(to: Selector(("currentMode"))) == true &&
                isPad == false {
                if __CGSizeEqualToSize(CGSize(width: 1080, height: 2340), UIScreen.main.currentMode!.size) {
                    return true
                }
            }
            return false
        }
    }
    var isIPhoneTwelve: Bool {
        get {
            if  UIScreen.instancesRespond(to: Selector(("currentMode"))) == true &&
                isPad == false {
                if __CGSizeEqualToSize(CGSize(width: 1170, height: 2532), UIScreen.main.currentMode!.size) {
                    return true
                }
            }
            return false
        }
    }
    var isIPhoneTwelveProMax: Bool {
        get {
            if  UIScreen.instancesRespond(to: Selector(("currentMode"))) == true &&
                isPad == false {
                if __CGSizeEqualToSize(CGSize(width: 1284, height: 2778), UIScreen.main.currentMode!.size) {
                    return true
                }
            }
            return false
        }
    }
}
