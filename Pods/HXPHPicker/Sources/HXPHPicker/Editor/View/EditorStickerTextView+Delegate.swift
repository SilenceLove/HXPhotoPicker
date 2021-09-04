//
//  EditorStickerTextView+Delegate.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/25.
//

import UIKit

extension EditorStickerTextView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        textView.typingAttributes = typingAttributes
        if textIsDelete {
            drawTextBackgroudColor()
            textIsDelete = false
        }
        if !textView.text.isEmpty {
            if textView.text.count > config.maximumLimitTextLength &&
                config.maximumLimitTextLength > 0 {
                let text = textView.text[..<config.maximumLimitTextLength]
                textView.text = text
            }
        }else {
            textLayer?.frame = .zero
        }
    }
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text.isEmpty {
            textIsDelete = true
        }
        return true
    }
}

extension EditorStickerTextView: NSLayoutManagerDelegate {
    func layoutManager(
        _ layoutManager: NSLayoutManager,
        didCompleteLayoutFor textContainer: NSTextContainer?,
        atEnd layoutFinishedFlag: Bool
    ) {
        if layoutFinishedFlag {
            drawTextBackgroudColor()
        }
    }
}

class EditorStickerTextLayer: CAShapeLayer {
}
