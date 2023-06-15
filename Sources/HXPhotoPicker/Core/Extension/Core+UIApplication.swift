//
//  Core+UIApplication.swift
//  HXPhotoPicker
//
//  Created by Slience on 2022/9/26.
//

import UIKit

extension UIApplication {
    class var _keyWindow: UIWindow? {
        var window: UIWindow?
        if #available(iOS 13.0, *) {
            window = shared.windows.filter({ $0.isKeyWindow }).last
        } else {
            window = shared.delegate?.window ?? shared.keyWindow
        }
        return window
    }
}
