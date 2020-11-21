//
//  UIDevice+HXPHPicker.swift
//  HXPHPickerExample
//
//  Created by 洪欣 on 2020/11/13.
//  Copyright © 2020 洪欣. All rights reserved.
//

import UIKit

extension UIDevice {
    class func hx_isPortrait() -> Bool {
        let orientation = UIApplication.shared.statusBarOrientation
        if  orientation == UIInterfaceOrientation.landscapeLeft ||
            orientation == UIInterfaceOrientation.landscapeRight {
            return false
        }
        return true
    }
    class func hx_navigationBarHeight() -> CGFloat {
        return hx_statusBarHeight() + 44
    }
    class func hx_statusBarHeight() -> CGFloat {
        let statusBarHeight : CGFloat;
        let window = UIApplication.shared.windows.first
        if #available(iOS 13.0, *) {
            statusBarHeight = (window?.windowScene?.statusBarManager?.statusBarFrame.size.height)!
        } else {
            // Fallback on earlier versions
            statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        }
        return statusBarHeight
    }
    class func hx_topMargin() -> CGFloat {
        if hx_isAllIPhoneX() {
            return hx_statusBarHeight()
        }
        return 0
    }
    class func hx_leftMargin() -> CGFloat {
        if hx_isAllIPhoneX() {
            if !hx_isPortrait() {
                return 44
            }
        }
        return 0
    }
    class func hx_rightMargin() -> CGFloat {
        if hx_isAllIPhoneX() {
            if !hx_isPortrait() {
                return 44
            }
        }
        return 0
    }
    class func hx_bottomMargin() -> CGFloat {
        if hx_isAllIPhoneX() {
            if hx_isPortrait() {
                return 34
            }else {
                return 21
            }
        }
        return 0
    }
    class func hx_isPad() -> Bool {
        return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad
    }
    class func hx_isAllIPhoneX() -> Bool {
        return (hx_isIPhoneX() || hx_isIPhoneXR() || hx_isIPhoneXsMax() || hx_isIPhoneXsMax() || hx_isIPhoneTwelveMini() || hx_isIPhoneTwelve() || hx_isIPhoneTwelveProMax())
    }
    class func hx_isIPhoneX() -> Bool {
        if  UIScreen.instancesRespond(to: Selector(("currentMode"))) == true &&
            hx_isPad() == false {
            if __CGSizeEqualToSize(CGSize(width: 1125, height: 2436), UIScreen.main.currentMode!.size) {
                return true
            }
        }
        return false
    }
    class func hx_isIPhoneXR() -> Bool {
        if  UIScreen.instancesRespond(to: Selector(("currentMode"))) == true &&
            hx_isPad() == false {
            if __CGSizeEqualToSize(CGSize(width: 828, height: 1792), UIScreen.main.currentMode!.size) {
                return true
            }
        }
        return false
    }
    class func hx_isIPhoneXsMax() -> Bool {
        if  UIScreen.instancesRespond(to: Selector(("currentMode"))) == true &&
            hx_isPad() == false {
            if __CGSizeEqualToSize(CGSize(width: 1242, height: 2688), UIScreen.main.currentMode!.size) {
                return true
            }
        }
        return false
    }
    class func hx_isIPhoneTwelveMini() -> Bool {
        if  UIScreen.instancesRespond(to: Selector(("currentMode"))) == true &&
            hx_isPad() == false {
            if __CGSizeEqualToSize(CGSize(width: 1080, height: 2340), UIScreen.main.currentMode!.size) {
                return true
            }
        }
        return false
    }
    class func hx_isIPhoneTwelve() -> Bool {
        if  UIScreen.instancesRespond(to: Selector(("currentMode"))) == true &&
            hx_isPad() == false {
            if __CGSizeEqualToSize(CGSize(width: 1170, height: 2532), UIScreen.main.currentMode!.size) {
                return true
            }
        }
        return false
    }
    class func hx_isIPhoneTwelveProMax() -> Bool {
        if  UIScreen.instancesRespond(to: Selector(("currentMode"))) == true &&
            hx_isPad() == false {
            if __CGSizeEqualToSize(CGSize(width: 1284, height: 2778), UIScreen.main.currentMode!.size) {
                return true
            }
        }
        return false
    }
}
