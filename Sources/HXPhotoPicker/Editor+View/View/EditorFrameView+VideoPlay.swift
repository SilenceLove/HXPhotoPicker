//
//  EditorFrameView+VideoPlay.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/4.
//

import UIKit

extension EditorFrameView: VideoPlaySliderViewDelegate {
    
    func videoSliderView(
        _ videoSliderView: VideoPlaySliderView,
        didChangedPlayDuration duration: CGFloat,
        state: VideoControlEvent
    ) {
        delegate?.frameView(self, didChangedPlayTime: duration, for: state)
    }
    
    func videoSliderView(
        _ videoSliderView: VideoPlaySliderView,
        didPlayButtonClick isSelected: Bool
    ) {
        delegate?.frameView(self, didPlayButtonClick: isSelected)
    }
}
