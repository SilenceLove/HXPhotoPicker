//
//  UIDevice+Extension.swift
//  Example
//
//  Created by Slience on 2021/1/13.
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
        if #available(iOS 13.0, *),
           let height = window?.windowScene?.statusBarManager?.statusBarFrame.size.height {
            statusBarHeight = height
        } else {
            statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        }
        return statusBarHeight
    }
    class var topMargin: CGFloat {
        if isAllIPhoneX {
            return statusBarHeight
        }
        return safeAreaInsets.top
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
            return UIApplication.hx_keyWindow?.safeAreaInsets ?? .zero
        }
        return .zero
    }
    
    class var screenSize: CGSize {
        if #available(iOS 14.0, *), ProcessInfo.processInfo.isiOSAppOnMac {
            return UIApplication.hx_keyWindow?.frame.size ?? UIScreen.main.bounds.size
        }
        return UIScreen.main.bounds.size
    }
}
