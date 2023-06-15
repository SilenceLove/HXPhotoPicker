//
//  EditorFrameView+Control.swift
//  HXPhotoPicker
//
//  Created by Slience on 2022/11/13.
//

import UIKit

extension EditorFrameView: EditorControlViewDelegate {
    func controlView(beganChanged controlView: EditorControlView, _ rect: CGRect) {
        if !controlView.isUserInteractionEnabled {
            return
        }
        hideMaskBgView()
        maskLinesView.hideGridGraylinesView(animated: true)
        stopControlTimer()
        delegate?.frameView(beganChanged: self, rect)
        hideVideoSilder(true)
    }
    
    func controlView(didChanged controlView: EditorControlView, _ rect: CGRect) {
        if !controlView.isUserInteractionEnabled {
            return
        }
        stopControlTimer()
        maskBgView.updateLayers(rect, false)
        customMaskView.updateLayers(rect, false)
        maskLinesView.updateLayers(rect, false)
        updateVideoSlider(to: rect, animated: false)
        delegate?.frameView(didChanged: self, rect)
    }
    
    func controlView(endChanged controlView: EditorControlView, _ rect: CGRect) {
        if !controlView.isUserInteractionEnabled {
            return
        }
        startControlTimer()
    }
}
