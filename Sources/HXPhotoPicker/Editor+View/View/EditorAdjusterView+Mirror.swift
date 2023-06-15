//
//  EditorAdjusterView+Mirror.swift
//  HXPhotoPicker
//
//  Created by Slience on 2022/11/27.
//

import UIKit

extension EditorAdjusterView {
    
    func mirrorHorizontally(animated: Bool, completion: (() -> Void)? = nil) {
        if state == .normal {
            completion?()
            return
        }
//        if rotating {
//            return
//        }
//        mirroring = true
        delegate?.editorAdjusterView(willBeginEditing: self)
        if animated {
            UIView.animate {
                self.mirrorHorizontallyHandler()
            } completion: { (_) in
                self.changedMaskRectCompletion(animated)
//                self.mirroring = false
                completion?()
            }
        }else {
            mirrorHorizontallyHandler()
            changedMaskRectCompletion(animated)
//            mirroring = false
            completion?()
        }
    }
    
    func mirrorHorizontallyHandler() {
        let transform = adjustedFactor.mirrorTransform
        mirrorView.transform = transform.scaledBy(x: 1, y: -1)
        adjustedFactor.mirrorTransform = mirrorView.transform
        contentView.stickerView.mirrorHorizontallyHandler()
    }
    
    func mirrorVertically(animated: Bool, completion: (() -> Void)? = nil) {
        if state == .normal {
            completion?()
            return
        }
//        if rotating {
//            return
//        }
//        mirroring = true
        delegate?.editorAdjusterView(willBeginEditing: self)
        if animated {
            UIView.animate {
                self.mirrorVerticallyHandler()
            } completion: { (_) in
                self.changedMaskRectCompletion(animated)
//                self.mirroring = false
                completion?()
            }
        }else {
            mirrorVerticallyHandler()
            changedMaskRectCompletion(animated)
//            mirroring = false
            completion?()
        }
    }
    
    func mirrorVerticallyHandler() {
        let transform = adjustedFactor.mirrorTransform
        mirrorView.transform = transform.scaledBy(x: -1, y: 1)
        adjustedFactor.mirrorTransform = mirrorView.transform
        contentView.stickerView.mirrorVerticallyHandler()
    }
}
