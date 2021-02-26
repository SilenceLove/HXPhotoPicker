//
//  Core+String.swift
//  HXPHPickerExample
//
//  Created by Silence on 2020/11/13.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

extension String {
    /// 字符串宽度
    /// - Parameters:
    ///   - size: 字体大小
    ///   - maxHeight: 最大高度
    /// - Returns: 字符串宽度
    func width(ofSize size: CGFloat, maxHeight: CGFloat) -> CGFloat {
        return width(ofFont: UIFont.systemFont(ofSize: size), maxHeight: maxHeight)
    }
    
    /// 字符串宽度
    /// - Parameters:
    ///   - font: 字体
    ///   - maxHeight: 最大高度
    /// - Returns: 字符串宽度
    func width(ofFont font: UIFont, maxHeight: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: CGFloat(MAXFLOAT), height: maxHeight)
        let boundingBox = self.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        return boundingBox.size.width
    }
    
    /// 字符串高度
    /// - Parameters:
    ///   - size: 字体大小
    ///   - maxWidth: 最大宽度
    /// - Returns: 高度
    func height(ofSize size: CGFloat, maxWidth: CGFloat) -> CGFloat {
        return height(ofFont: UIFont.systemFont(ofSize: size), maxWidth: maxWidth)
    }
    
    /// 字符串高度
    /// - Parameters:
    ///   - font: 字体
    ///   - maxWidth: 最大宽度
    /// - Returns: 高度
    func height(ofFont font: UIFont, maxWidth: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: maxWidth, height: CGFloat(MAXFLOAT))
        let boundingBox = self.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        return boundingBox.size.height
    }
}
