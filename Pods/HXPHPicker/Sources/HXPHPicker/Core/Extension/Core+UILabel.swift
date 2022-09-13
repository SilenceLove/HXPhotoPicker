//
//  Core+UILabel.swift
//  HXPHPicker
//
//  Created by Slience on 2021/10/22.
//

import UIKit

extension UILabel {
    var textHeight: CGFloat {
        text?.height(ofFont: font, maxWidth: width > 0 ? width : CGFloat(MAXFLOAT)) ?? 0
    }
    var textWidth: CGFloat {
        text?.width(ofFont: font, maxHeight: height > 0 ? height : CGFloat(MAXFLOAT)) ?? 0
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
