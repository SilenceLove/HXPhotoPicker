//
//  String+HXPHPicker.swift
//  HXPHPickerExample
//
//  Created by 洪欣 on 2020/11/13.
//  Copyright © 2020 洪欣. All rights reserved.
//

import UIKit

extension String {
    
    func hx_localized() -> String {
        return Bundle.hx_localizedString(for: self)
    }
    
    func hx_stringWidth(ofFont font: UIFont, maxHeight: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: CGFloat(MAXFLOAT), height: maxHeight)
        let boundingBox = self.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        return boundingBox.size.width
    }
    
    func hx_stringWidth(ofSize size: CGFloat, maxHeight: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: CGFloat(MAXFLOAT), height: maxHeight)
        let boundingBox = self.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: size)], context: nil)
        return boundingBox.size.width
    }
    
    func hx_stringHeight(ofFont font: UIFont, maxWidth: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: maxWidth, height: CGFloat(MAXFLOAT))
        let boundingBox = self.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        return boundingBox.size.height
    }
    
    func hx_stringHeight(ofSize size: CGFloat, maxWidth: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: maxWidth, height: CGFloat(MAXFLOAT))
        let boundingBox = self.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: size)], context: nil)
        return boundingBox.size.height
    }
}
