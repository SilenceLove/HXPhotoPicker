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
        if  orientation == .landscapeLeft ||
            orientation == .landscapeRight {
            return false
        }
        return true
    }
    class var orientation: UIInterfaceOrientation {
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
        let statusBarHeight : CGFloat;
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
        UI_USER_INTERFACE_IDIOM() == .pad
    }
    class var isAllIPhoneX: Bool {
        (isIPhoneX || isIPhoneXR || isIPhoneXsMax || isIPhoneXsMax || isIPhoneTwelveMini || isIPhoneTwelve || isIPhoneTwelveProMax)
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
}
