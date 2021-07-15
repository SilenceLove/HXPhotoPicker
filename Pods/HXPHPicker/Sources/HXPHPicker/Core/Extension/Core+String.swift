//
//  Core+String.swift
//  HXPHPickerExample
//
//  Created by Silence on 2020/11/13.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit
import CommonCrypto

extension String {
    
    var localized: String {
        get {
            Bundle.localizedString(for: self)
        }
    }
    
    var color: UIColor {
        get {
            UIColor.init(hexString: self)
        }
    }
    
    var image: UIImage? {
        get {
            UIImage.image(for: self)
        }
    }
    
    static func fileName(suffix: String) -> String {
        var uuid = UUID().uuidString
        uuid = uuid.replacingOccurrences(of: "-", with: "").lowercased()
        var fileName = uuid
        let nowDate = Date().timeIntervalSince1970
        
        fileName.append(String(format: "%d", arguments: [nowDate]))
        fileName.append(String(format: "%d", arguments: [arc4random()%10000]))
        return fileName.md5() + "." + suffix
    }
    func md5() -> String {
        let str = self.cString(using: String.Encoding.utf8)
        let strLen = CUnsignedInt(self.lengthOfBytes(using: String.Encoding.utf8))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<UInt8>.allocate(capacity: 16)
        CC_MD5(str!, strLen, result)
        let hash = NSMutableString()
        for i in 0 ..< digestLen {
            hash.appendFormat("%02x", result[i])
        }
        free(result)
        return String(format: hash as String)
    }
    
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
    
    subscript(_ indexs: ClosedRange<Int>) -> String {
            let beginIndex = index(startIndex, offsetBy: indexs.lowerBound)
            let endIndex = index(startIndex, offsetBy: indexs.upperBound)
            return String(self[beginIndex...endIndex])
        }
        
    subscript(_ indexs: Range<Int>) -> String {
        let beginIndex = index(startIndex, offsetBy: indexs.lowerBound)
        let endIndex = index(startIndex, offsetBy: indexs.upperBound)
        return String(self[beginIndex..<endIndex])
    }
    
    subscript(_ indexs: PartialRangeThrough<Int>) -> String {
        let endIndex = index(startIndex, offsetBy: indexs.upperBound)
        return String(self[startIndex...endIndex])
    }
    
    subscript(_ indexs: PartialRangeFrom<Int>) -> String {
        let beginIndex = index(startIndex, offsetBy: indexs.lowerBound)
        return String(self[beginIndex..<endIndex])
    }
    
    subscript(_ indexs: PartialRangeUpTo<Int>) -> String {
        let endIndex = index(startIndex, offsetBy: indexs.upperBound)
        return String(self[startIndex..<endIndex])
    }
}
