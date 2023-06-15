//
//  Core+UILabel.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/10/22.
//

import UIKit

extension UILabel {
    var textHeight: CGFloat {
        text?.height(ofFont: font, maxWidth: width > 0 ? width : .max) ?? 0
    }
    var textWidth: CGFloat {
        text?.width(ofFont: font, maxHeight: height > 0 ? height : .max) ?? 0
    }
    var textSize: CGSize {
        text?.size(ofFont: font, maxWidth: .max, maxHeight: .max) ?? .zero
    }
}

public extension HXPickerWrapper where Base: UILabel {
    var textWidth: CGFloat {
        base.textWidth
    }
    var textHeight: CGFloat {
        base.textHeight
    }
}
