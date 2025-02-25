//
//  Core+UILabel.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/10/22.
//

import UIKit

extension UILabel {
    var textHeight: CGFloat {
        if let textHeight = text?.height(ofFont: font, maxWidth: width > 0 ? width : .max) {
            return textHeight
        }
        return 0
    }
    var textWidth: CGFloat {
        if let textWidth = text?.width(ofFont: font, maxHeight: height > 0 ? height : .max) {
            return textWidth
        }
        return 0
    }
    var textSize: CGSize {
        if let textSize = text?.size(ofFont: font, maxWidth: .max, maxHeight: .max) {
            return textSize
        }
        return .zero
    }
}

extension UILabel {
    /// 文本对齐方向
    var hxpicker_alignment: NSTextAlignment {
        set {
            switch newValue {
            case .left:
                textAlignment = PhotoManager.isRTL ? .right : .left
            case .right:
                textAlignment = PhotoManager.isRTL ? .left : .right
            default:
                textAlignment = newValue
            }
        }
        
        get {
            switch textAlignment {
            case .left:
                return PhotoManager.isRTL ? .right : textAlignment
            case .right:
                return PhotoManager.isRTL ? .left : textAlignment
            default:
                return textAlignment
            }
        }
    }
}
