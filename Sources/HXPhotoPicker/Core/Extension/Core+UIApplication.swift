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
