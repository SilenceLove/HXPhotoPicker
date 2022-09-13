//
//  Core+UIColor.swift
//  HXPHPickerExample
//
//  Created by Silence on 2020/11/13.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

extension UIColor: HXPickerCompatible {
    
    convenience init(hexString: String) {
        let hexString = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
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
    class var systemTintColor: UIColor {
        UIColor.init(red: 0, green: 0.47843137254901963, blue: 1, alpha: 1)
    }
    
    var isWhite: Bool {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: nil)
        if red >= 0.99 && green >= 0.99 && blue >= 0.99 {
            return true
        }
        return false
    }
    
    func image(
        for color: UIColor?,
        havingSize: CGSize,
        radius: CGFloat = 0
    ) -> UIImage? {
        .image(
            for: color,
            havingSize: havingSize,
            radius: radius
        )
    }
}

public extension HXPickerWrapper where Base: UIColor {
    static var systemTintColor: UIColor {
        Base.systemTintColor
    }
    
    func image(
        for color: UIColor?,
        havingSize: CGSize,
        radius: CGFloat = 0
    ) -> UIImage? {
        return base.image(
            for: color,
            havingSize: havingSize,
            radius: radius
        )
    }
}
