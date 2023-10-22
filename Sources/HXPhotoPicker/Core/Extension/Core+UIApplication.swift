//
//  Core+UIApplication.swift
//  HXPhotoPicker
//
//  Created by Slience on 2022/9/26.
//

import UIKit

extension UIApplication {
    class var _keyWindow: UIWindow? {
        if #available(iOS 13.0, *) {
            return shared.windows.filter({ $0.isKeyWindow }).last
        }
        guard let window = shared.delegate?.window else {
            return shared.keyWindow
        }
        return window
    }
}

extension UIScreen {
    
    static var _scale: CGFloat {
        let scale = main.scale
        if #available(iOS 13.0, *) {
            return UIApplication._keyWindow?.windowScene?.screen.scale ?? scale
        }
        return scale
    }
    
    static var _width: CGFloat {
        let width = UIScreen.main.bounds.width
        if #available(iOS 13.0, *) {
            return UIApplication._keyWindow?.windowScene?.screen.bounds.width ?? width
        }
        return width
    }
    
    static var _height: CGFloat {
        let height = UIScreen.main.bounds.height
        if #available(iOS 13.0, *) {
            return UIApplication._keyWindow?.windowScene?.screen.bounds.height ?? height
        }
        return height
    }
    
    static var _size: CGSize {
        let size = UIScreen.main.bounds.size
        if #available(iOS 13.0, *) {
            return UIApplication._keyWindow?.windowScene?.screen.bounds.size ?? size
        }
        return size
    }
    
}
