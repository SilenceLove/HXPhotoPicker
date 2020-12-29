//
//  String+HXPHPicker.swift
//  HXPHPickerExample
//
//  Created by Silence on 2020/11/13.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit
import CommonCrypto

public extension String {
    
    var hx_localized: String {
        get {
            return Bundle.hx_localizedString(for: self)
        }
    }
    
    var hx_color: UIColor {
        get {
            return UIColor.init(hx_hexString: self)
        }
    }
    
    var hx_image: UIImage? {
        get {
            return UIImage.hx_named(named: self)
        }
    }
    static func hx_fileName(suffix: String) -> String {
        var uuid = UUID().uuidString
        uuid = uuid.replacingOccurrences(of: "-", with: "").lowercased()
        var fileName = uuid
        let nowDate = Date().timeIntervalSince1970
        
        fileName.append(String(format: "%d", arguments: [nowDate]))
        fileName.append(String(format: "%d", arguments: [arc4random()%10000]))
        return fileName.md5() + "." + suffix
    }
    private func md5() -> String {
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
