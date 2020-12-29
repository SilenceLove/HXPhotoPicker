//
//  UIFont+HXPHPicker.swift
//  HXPHPickerExample
//
//  Created by Silence on 2020/11/13.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

extension UIFont {
    
    class func hx_regularPingFang(size: CGFloat) -> UIFont {
        let font = UIFont.init(name: "PingFangSC-Regular", size: size)
        return font ?? UIFont.systemFont(ofSize: size)
    }
    
    class func hx_mediumPingFang(size: CGFloat) -> UIFont {
        let font = UIFont.init(name: "PingFangSC-Medium", size: size)
        return font ?? UIFont.systemFont(ofSize: size)
    }
    
    class func hx_semiboldPingFang(size: CGFloat) -> UIFont {
        let font = UIFont.init(name: "PingFangSC-Semibold", size: size)
        return font ?? UIFont.systemFont(ofSize: size)
    }
    
}
