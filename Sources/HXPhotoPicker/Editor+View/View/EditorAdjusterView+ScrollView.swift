//
//  EditorAdjusterView+ScrollView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2022/11/12.
//

import UIKit

extension EditorAdjusterView: UIScrollViewDelegate {
    func didScroll() {
        if state != .edit || frameView.isControlPanning {
            return
        }
        frameView.stopControlTimer()
        if !isMaskBgViewShowing {
            frameView.hideMaskBgView()
            frameView.hideVideoSilder(true)
        }
    }
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        didScroll()
        delegate?.editorAdjusterView(willBeginEditing: self)
    }
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        didScroll()
        delegate?.editorAdjusterView(willBeginEditing: self)
    }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            scrollDidEnd()
        }
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollDidEnd()
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        contentView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        setScrollViewContentInset(frameView.controlView.frame)
        updateControlScaleSize()
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        if state != .edit {
            return
        }
        frameView.stopControlTimer()
        if !isMaskBgViewShowing {
            frameView.hideMaskBgView()
        }
    }
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        if state != .edit {
            return
        }
        zoomScale = scale
        scrollDidEnd()
        updateControlScaleSize()
    }
    
    func scrollDidEnd() {
        if state != .edit || frameView.isControlPanning {
            return
        }
        if frameView.inControlTimer {
            frameView.startControlTimer()
        }else {
            delegate?.editorAdjusterView(didEndEditing: self)
            frameView.startShowMaskBgTimer()
        }
    }
    
    func resetState() {
        setScrollViewEnabled(state == .edit)
    }
}
