//
//  EditorView+GestureRecognizer.swift
//  HXPhotoPicker
//
//  Created by Slience on 2022/11/13.
//

import UIKit

extension EditorView: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer is UIPanGestureRecognizer {
            if isDrawEnabled || isMosaicEnabled {
                return false
            }
        }
        return true
    }
}
