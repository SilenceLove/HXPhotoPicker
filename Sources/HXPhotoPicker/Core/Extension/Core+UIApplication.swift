//
//  Core+UIApplication.swift
//  HXPhotoPicker
//
//  Created by Slience on 2022/9/26.
//

import UIKit

extension UIApplication {
    static var _keyWindow: UIWindow? {
        if #available(iOS 13.0, *), Thread.isMainThread,
           let window = shared.windows.filter({ $0.isKeyWindow }).last {
            return window
        }
        guard let window = shared.delegate?.window else {
            return shared.keyWindow
        }
        return window
    }
    
    static var interfaceOrientation: UIInterfaceOrientation {
        if #available(iOS 13.0, *), Thread.isMainThread,
           let orientation = _keyWindow?.windowScene?.interfaceOrientation {
            return orientation
        }
        return shared.statusBarOrientation
    }
}

extension UIScreen {
    
    static var _scale: CGFloat {
        if #available(iOS 13.0, *), Thread.isMainThread,
           let scale = UIApplication._keyWindow?.windowScene?.screen.scale {
            return scale
        }
        return main.scale
    }
    
    static var _width: CGFloat {
        if #available(iOS 13.0, *), Thread.isMainThread,
           let width = UIApplication._keyWindow?.windowScene?.screen.bounds.width {
            return width
        }
        return main.bounds.width
    }
    
    static var _height: CGFloat {
        if #available(iOS 13.0, *), Thread.isMainThread,
           let height = UIApplication._keyWindow?.windowScene?.screen.bounds.height {
            return height
        }
        return main.bounds.height
    }
    
    static var _size: CGSize {
        if #available(iOS 13.0, *), Thread.isMainThread,
           let size = UIApplication._keyWindow?.windowScene?.screen.bounds.size {
            return size
        }
        return main.bounds.size
    }
    
}
