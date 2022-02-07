//
//  PhotoEditorViewController+UIGestureRecognizer.swift
//  HXPHPicker
//
//  Created by Slience on 2021/11/15.
//

import UIKit

extension PhotoEditorViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view is EditorStickerContentView {
            return false
        }
        if let isDescendant = touch.view?.isDescendant(of: imageView), isDescendant {
            return true
        }
        return false
    }
    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        if otherGestureRecognizer is UILongPressGestureRecognizer &&
            otherGestureRecognizer.view is PhotoEditorContentView {
            return false
        }
        return true
    }
}
