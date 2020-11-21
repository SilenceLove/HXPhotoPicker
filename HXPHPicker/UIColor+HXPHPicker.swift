//
//  UIColor+HXPHPicker.swift
//  HXPHPickerExample
//
//  Created by 洪欣 on 2020/11/13.
//  Copyright © 2020 洪欣. All rights reserved.
//

import UIKit

extension UIColor {
    
    convenience init(hx_hexString: String) {
        let hexString = hx_hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        let scanner = Scanner(string: hexString)
        if hexString.hasPrefix("#") {
            scanner.scanLocation = 1
        }
        var color: UInt32 = 0
        scanner.scanHexInt32(&color)
        let mask = 0x000000FF
        let r = Int(color >> 16) & mask
        let g = Int(color >> 8) & mask
        let b = Int(color) & mask
        let red   = CGFloat(r) / 255.0
        let green = CGFloat(g) / 255.0
        let blue  = CGFloat(b) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: 1)
    }
    
}
