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
