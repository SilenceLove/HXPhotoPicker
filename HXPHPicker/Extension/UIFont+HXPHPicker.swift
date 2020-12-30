//
//  UIFont+HXPHPicker.swift
//  HXPHPickerExample
//
//  Created by Silence on 2020/11/13.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

public extension UIFont {
    
    class func regularPingFang(ofSize size: CGFloat) -> UIFont {
        let font = UIFont.init(name: "PingFangSC-Regular", size: size)
        return font ?? UIFont.systemFont(ofSize: size)
    }
    
    class func mediumPingFang(ofSize size: CGFloat) -> UIFont {
        let font = UIFont.init(name: "PingFangSC-Medium", size: size)
        return font ?? UIFont.systemFont(ofSize: size)
    }
    
    class func semiboldPingFang(ofSize size: CGFloat) -> UIFont {
        let font = UIFont.init(name: "PingFangSC-Semibold", size: size)
        return font ?? UIFont.systemFont(ofSize: size)
    }
    
}
