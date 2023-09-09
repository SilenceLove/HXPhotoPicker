//
//  String+Extension.swift
//  Example
//
//  Created by 洪欣 on 2023/5/2.
//

import UIKit

extension String {
    
    static func fileName(suffix: String) -> String {
        var uuid = UUID().uuidString
        uuid = uuid.replacingOccurrences(of: "-", with: "").lowercased()
        var fileName = uuid
        let nowDate = Date().timeIntervalSince1970
        
        fileName.append(String(format: "%d", arguments: [nowDate]))
        fileName.append(String(format: "%d", arguments: [Int.random(in: 0..<10000)]))
        return suffix.isEmpty ? fileName : fileName + "." + suffix
    }
    
    func boundingRect(ofAttributes attributes: [NSAttributedString.Key: Any], size: CGSize) -> CGRect {
        let boundingBox = boundingRect(
            with: size,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )
        return boundingBox
    }
    
    func size(ofAttributes attributes: [NSAttributedString.Key: Any], maxWidth: CGFloat, maxHeight: CGFloat) -> CGSize {
        boundingRect(ofAttributes: attributes, size: .init(width: maxWidth, height: maxHeight)).size
    }
    
    func size(ofFont font: UIFont, maxWidth: CGFloat, maxHeight: CGFloat) -> CGSize {
        let constraintRect = CGSize(width: maxWidth, height: maxHeight)
        let boundingBox = boundingRect(
            with: constraintRect,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        return boundingBox.size
    }
    
    func width(ofSize size: CGFloat, maxHeight: CGFloat) -> CGFloat {
        width(
            ofFont: .systemFont(ofSize: size),
            maxHeight: maxHeight
        )
    }
    
    func width(ofFont font: UIFont, maxHeight: CGFloat) -> CGFloat {
        size(
            ofAttributes: [NSAttributedString.Key.font: font],
            maxWidth: CGFloat(MAXFLOAT),
            maxHeight: maxHeight
        ).width
    }
    
    func height(ofSize size: CGFloat, maxWidth: CGFloat) -> CGFloat {
        height(
            ofFont: .systemFont(ofSize: size),
            maxWidth: maxWidth
        )
    }
    
    func height(ofFont font: UIFont, maxWidth: CGFloat) -> CGFloat {
        size(
            ofAttributes: [NSAttributedString.Key.font: font],
            maxWidth: maxWidth,
            maxHeight: CGFloat(MAXFLOAT)
        ).height
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
