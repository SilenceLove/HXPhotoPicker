//
//  UIDevice+HXPHPicker.swift
//  HXPHPickerExample
//
//  Created by Silence on 2020/11/13.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

public extension UIDevice {
    var hx_isPortrait: Bool {
        get {
            let orientation = UIApplication.shared.statusBarOrientation
            if  orientation == .landscapeLeft ||
                orientation == .landscapeRight {
                return false
            }
            return true
        }
    }
    var hx_navigationBarHeight: CGFloat {
        get {
            return hx_statusBarHeight + 44
        }
    }
    var hx_statusBarHeight: CGFloat {
        get {
            let statusBarHeight : CGFloat;
            let window = UIApplication.shared.windows.first
            if #available(iOS 13.0, *) {
                statusBarHeight = (window?.windowScene?.statusBarManager?.statusBarFrame.size.height)!
            } else {
                // Fallback on earlier versions
//                if UIApplication.shared.isStatusBarHidden {
//                    return hx_isAllIPhoneX ? 44 : 20
//                }
                statusBarHeight = UIApplication.shared.statusBarFrame.size.height
            }
            return statusBarHeight
        }
    }
    var hx_topMargin: CGFloat {
        get {
            if hx_isAllIPhoneX {
                return hx_statusBarHeight
            }
            return 0
        }
    }
    var hx_leftMargin: CGFloat {
        get {
            if hx_isAllIPhoneX {
                if !hx_isPortrait {
                    return 44
                }
            }
            return 0
        }
    }
    var hx_rightMargin: CGFloat {
        get {
            if hx_isAllIPhoneX {
                if !hx_isPortrait {
                    return 44
                }
            }
            return 0
        }
    }
    var hx_bottomMargin: CGFloat {
        get {
            if hx_isAllIPhoneX {
                if hx_isPortrait {
                    return 34
                }else {
                    return 21
                }
            }
            return 0
        }
    }
    var hx_isPad: Bool {
        get {
            return UI_USER_INTERFACE_IDIOM() == .pad
        }
    }
    var hx_isAllIPhoneX: Bool {
        get {
            return (hx_isIPhoneX || hx_isIPhoneXR || hx_isIPhoneXsMax || hx_isIPhoneXsMax || hx_isIPhoneTwelveMini || hx_isIPhoneTwelve || hx_isIPhoneTwelveProMax)
        }
    }
    var hx_isIPhoneX: Bool {
        get {
            if  UIScreen.instancesRespond(to: Selector(("currentMode"))) == true &&
                hx_isPad == false {
                if __CGSizeEqualToSize(CGSize(width: 1125, height: 2436), UIScreen.main.currentMode!.size) {
                    return true
                }
            }
            return false
        }
    }
    var hx_isIPhoneXR: Bool {
        get {
            if  UIScreen.instancesRespond(to: Selector(("currentMode"))) == true &&
                hx_isPad == false {
                if __CGSizeEqualToSize(CGSize(width: 828, height: 1792), UIScreen.main.currentMode!.size) {
                    return true
                }
            }
            return false
        }
    }
    var hx_isIPhoneXsMax: Bool {
        get {
            if  UIScreen.instancesRespond(to: Selector(("currentMode"))) == true &&
                hx_isPad == false {
                if __CGSizeEqualToSize(CGSize(width: 1242, height: 2688), UIScreen.main.currentMode!.size) {
                    return true
                }
            }
            return false
        }
    }
    var hx_isIPhoneTwelveMini: Bool {
        get {
            if  UIScreen.instancesRespond(to: Selector(("currentMode"))) == true &&
                hx_isPad == false {
                if __CGSizeEqualToSize(CGSize(width: 1080, height: 2340), UIScreen.main.currentMode!.size) {
                    return true
                }
            }
            return false
        }
    }
    var hx_isIPhoneTwelve: Bool {
        get {
            if  UIScreen.instancesRespond(to: Selector(("currentMode"))) == true &&
                hx_isPad == false {
                if __CGSizeEqualToSize(CGSize(width: 1170, height: 2532), UIScreen.main.currentMode!.size) {
                    return true
                }
            }
            return false
        }
    }
    var hx_isIPhoneTwelveProMax: Bool {
        get {
            if  UIScreen.instancesRespond(to: Selector(("currentMode"))) == true &&
                hx_isPad == false {
                if __CGSizeEqualToSize(CGSize(width: 1284, height: 2778), UIScreen.main.currentMode!.size) {
                    return true
                }
            }
            return false
        }
    }
}
