//
//  Core+UIApplication.swift
//  HXPhotoPicker
//
//  Created by Slience on 2022/9/26.
//

import UIKit

extension UIApplication {
    
    public static var hx_windows: [UIWindow] {
        var windows: [UIWindow] = []
        if #available(iOS 13.0, *) {
            for scene in shared.connectedScenes {
                guard let windowScene = scene as? UIWindowScene, windowScene.session.role == .windowApplication else {
                    continue
                }
                windows = windowScene.windows
                break
            }
        }
        if windows.isEmpty {
            windows = shared.windows
        }
        return windows
    }
    
    public static var hx_delegateWindow: UIWindow? {
        var window: UIWindow?
        if #available(iOS 13.0, *) {
            for scene in shared.connectedScenes {
                guard let windowScene = scene as? UIWindowScene, windowScene.session.role == .windowApplication else {
                    continue
                }
                guard let windowDelegate = windowScene.delegate as? UIWindowSceneDelegate else {
                    continue
                }
                window = windowDelegate.window as? UIWindow
                break
            }
        }
        if window == nil {
            window = shared.delegate?.window as? UIWindow
        }
        return window
    }
    
    public static var hx_keyWindow: UIWindow? {
        var window = self.hx_windows.first(where: { $0.isKeyWindow && !$0.isHidden })
        if window == nil {
            window = self.hx_delegateWindow
        }
        return window
    }
    
    public static var hx_interfaceOrientation: UIInterfaceOrientation {
        if #available(iOS 13.0, *), Thread.isMainThread, let orientation = hx_keyWindow?.windowScene?.interfaceOrientation {
            return orientation
        }
        return shared.statusBarOrientation
    }
    
}

extension UIScreen {
    
    static var _scale: CGFloat {
        if #available(iOS 13.0, *), Thread.isMainThread,
           let scale = UIApplication.hx_keyWindow?.windowScene?.screen.scale {
            return scale
        }
        return main.scale
    }
    
    static var _width: CGFloat {
        if #available(iOS 13.0, *), Thread.isMainThread,
           let width = UIApplication.hx_keyWindow?.windowScene?.screen.bounds.width {
            return width
        }
        return main.bounds.width
    }
    
    static var _height: CGFloat {
        if #available(iOS 13.0, *), Thread.isMainThread,
           let height = UIApplication.hx_keyWindow?.windowScene?.screen.bounds.height {
            return height
        }
        return main.bounds.height
    }
    
    static var _size: CGSize {
        if #available(iOS 13.0, *), Thread.isMainThread,
           let size = UIApplication.hx_keyWindow?.windowScene?.screen.bounds.size {
            return size
        }
        return main.bounds.size
    }
    
}
