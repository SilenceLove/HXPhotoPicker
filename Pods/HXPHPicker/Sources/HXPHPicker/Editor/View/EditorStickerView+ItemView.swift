//
//  EditorStickerView+ItemView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/25.
//

import UIKit

extension EditorStickerView: EditorStickerItemViewDelegate {
    func stickerItemView(
        _ itemView: EditorStickerItemView,
        updateStickerText item: EditorStickerItem
    ) {
        delegate?.stickerView(self, updateStickerText: item)
    }
    
    func stickerItemView(shouldTouchBegan itemView: EditorStickerItemView) -> Bool {
        if let selectView = selectView, itemView != selectView {
            return false
        }
        return true
    }
    
    func stickerItemView(didTouchBegan itemView: EditorStickerItemView) {
        touching = true
        delegate?.stickerView(touchBegan: self)
        if let selectView = selectView, selectView != itemView {
            selectView.isSelected = false
            self.selectView = itemView
        }else if selectView == nil {
            selectView = itemView
        }
        if !addWindowCompletion {
            windowAdd(itemView: itemView)
        }
        if !trashViewIsVisible {
            UIApplication.shared.keyWindow?.addSubview(trashView)
            showTrashView()
        }
    }
    
    func stickerItemView(touchEnded itemView: EditorStickerItemView) {
        delegate?.stickerView(touchEnded: self)
        if let selectView = selectView, selectView != itemView {
            selectView.isSelected = false
            self.selectView = itemView
        }else if selectView == nil {
            selectView = itemView
        }
        resetItemView(itemView: itemView)
        if trashViewIsVisible {
            hideTrashView()
        }
        touching = false
    }
    func stickerItemView(_ itemView: EditorStickerItemView, tapGestureRecognizerNotInScope point: CGPoint) {
        if let selectView = selectView, itemView == selectView {
            self.selectView = nil
            let cPoint = itemView.convert(point, to: self)
            for subView in subviews {
                if let itemView = subView as? EditorStickerItemView {
                    if itemView.frame.contains(cPoint) {
                        itemView.isSelected = true
                        self.selectView = itemView
                        bringSubviewToFront(itemView)
                        itemView.resetRotaion()
                        return
                    }
                }
            }
        }
    }
    
    func stickerItemView(_ itemView: EditorStickerItemView, panGestureRecognizerChanged panGR: UIPanGestureRecognizer) {
        let point = panGR.location(in: UIApplication.shared.keyWindow)
        if trashView.frame.contains(point) && !trashViewDidRemove {
            trashView.inArea = true
            if !hasImpactFeedback {
                UIView.animate(withDuration: 0.25) {
                    self.selectView?.alpha = 0.4
                }
                perform(#selector(hideTrashView), with: nil, afterDelay: 1.2)
                let shake = UIImpactFeedbackGenerator(style: .medium)
                shake.prepare()
                shake.impactOccurred()
                trashView.layer.removeAllAnimations()
                let animaiton = CAKeyframeAnimation(keyPath: "transform.scale")
                animaiton.duration = 0.3
                animaiton.values = [1.05, 0.95, 1.025, 0.975, 1]
                trashView.layer.add(animaiton, forKey: nil)
                hasImpactFeedback = true
            }
        }else {
            UIView.animate(withDuration: 0.2) {
                self.selectView?.alpha = 1
            }
            UIView.cancelPreviousPerformRequests(withTarget: self)
            hasImpactFeedback = false
            trashView.inArea = false
        }
    }
    func stickerItemView(_ itemView: EditorStickerItemView, moveToCenter rect: CGRect) -> Bool {
        if let moveToCenter = delegate?.stickerView(self, moveToCenter: rect) {
            return moveToCenter
        }
        return false
    }
    func stickerItemView(panGestureRecognizerEnded itemView: EditorStickerItemView) -> Bool {
        let inArea = trashView.inArea
        if inArea {
            addWindowCompletion = false
            trashView.inArea = false
            if itemView.item.music != nil {
                itemView.invalidateTimer()
                audioView = nil
                delegate?.stickerView(didRemoveAudio: self)
            }
            itemView.isDelete = true
            itemView.isEnabled = false
            UIView.animate(withDuration: 0.25) {
                itemView.alpha = 0
            } completion: { _ in
                itemView.removeFromSuperview()
            }
            selectView = nil
        }else {
            if let selectView = selectView, selectView != itemView {
                selectView.isSelected = false
                self.selectView = itemView
            }else if selectView == nil {
                selectView = itemView
            }
            resetItemView(itemView: itemView)
        }
        if addWindowCompletion {
            hideTrashView()
        }
        return inArea
    }
    func stickerItemView(_ itemView: EditorStickerItemView, maxScale itemSize: CGSize) -> CGFloat {
        if let maxScale = delegate?.stickerView(self, maxScale: itemSize) {
            return maxScale
        }
        return 5
    }
    
    func stickerItemView(_ itemView: EditorStickerItemView, minScale itemSize: CGSize) -> CGFloat {
        if let minScale = delegate?.stickerView(self, minScale: itemSize) {
            return minScale
        }
        return 0.2
    }
}
