//
//  EditorView+AdjusterView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2022/11/30.
//

import UIKit
import AVFoundation
import PencilKit

extension EditorView: EditorAdjusterViewDelegate {
    func editorAdjusterView(_ adjusterView: EditorAdjusterView, shouldAddAudioItem audio: EditorStickerAudio) -> Bool {
        if let shouldAddAudioItem = editDelegate?.editorView(self, shouldAddAudioItem: audio) {
            return shouldAddAudioItem
        }
        return true
    }
    
    func editorAdjusterView(willBeginEditing adjusterView: EditorAdjusterView) {
        editDelegate?.editorView(willBeginEditing: self)
    }
    
    func editorAdjusterView(didEndEditing adjusterView: EditorAdjusterView) {
        editDelegate?.editorView(didEndEditing: self)
    }
    
    func editorAdjusterView(editWillAppear adjusterView: EditorAdjusterView) {
        editDelegate?.editorView(editWillAppear: self)
    }
    
    func editorAdjusterView(editDidAppear adjusterView: EditorAdjusterView) {
        editDelegate?.editorView(editDidAppear: self)
    }
    
    func editorAdjusterView(editWillDisappear adjusterView: EditorAdjusterView) {
        editDelegate?.editorView(editWillDisappear: self)
    }
    
    func editorAdjusterView(editDidDisappear adjusterView: EditorAdjusterView) {
        editDelegate?.editorView(editDidDisappear: self)
    }
    
    func editorAdjusterView(contentViewBeginDraw adjusterView: EditorAdjusterView) {
        editDelegate?.editorView(contentViewBeginDraw: self)
    }
    
    func editorAdjusterView(contentViewEndDraw adjusterView: EditorAdjusterView) {
        editDelegate?.editorView(contentViewEndDraw: self)
    }
    
    func editorAdjusterView(_ adjusterView: EditorAdjusterView, didTapStickerItem itemView: EditorStickersItemView) {
        editDelegate?.editorView(self, didTapStickerItem: itemView)
    }
    func editorAdjusterView(_ adjusterView: EditorAdjusterView, didRemoveItem itemView: EditorStickersItemView) {
        editDelegate?.editorView(self, didRemoveStickerItem: itemView)
    }
    func editorAdjusterView(_ adjusterView: EditorAdjusterView, shouldRemoveItem itemView: EditorStickersItemView) {
        editDelegate?.editorView(self, shouldRemoveStickerItem: itemView)
    }
    func editorAdjusterView(
        _ adjusterView: EditorAdjusterView,
        resetItemViews itemViews: [EditorStickersItemBaseView]
    ) {
        editDelegate?.editorView(self, resetItemViews: itemViews)
    }
    
    func editorAdjusterView(_ editorAdjusterView: EditorAdjusterView, videoDidPlayAt time: CMTime) {
        editDelegate?.editorView(self, videoDidPlayAt: time)
    }
    func editorAdjusterView(_ editorAdjusterView: EditorAdjusterView, videoDidPauseAt time: CMTime) {
        editDelegate?.editorView(self, videoDidPauseAt: time)
    }
    func editorAdjusterView(videoReadyForDisplay editorAdjusterView: EditorAdjusterView) {
        if reloadContent || layoutContent {
            layoutContent = true
            reloadContent = false
            layoutSubviews()
        }
        editDelegate?.editorView(videoReadyForDisplay: self)
    }
    func editorAdjusterView(videoResetPlay editorAdjusterView: EditorAdjusterView) {
        editDelegate?.editorView(videoResetPlay: self)
    }
    func editorAdjusterView(_ editorAdjusterView: EditorAdjusterView, videoIsPlaybackLikelyToKeepUp: Bool) {
        editDelegate?.editorView(self, videoIsPlaybackLikelyToKeepUp: videoIsPlaybackLikelyToKeepUp)
    }
    func editorAdjusterView(_ editorAdjusterView: EditorAdjusterView, videoReadyToPlay duration: CMTime) {
        editDelegate?.editorView(self, videoReadyToPlay: duration)
    }
    func editorAdjusterView(_ editorAdjusterView: EditorAdjusterView, videoDidChangedBufferAt time: CMTime) {
        editDelegate?.editorView(self, videoDidChangedBufferAt: time)
    }
    func editorAdjusterView(_ editorAdjusterView: EditorAdjusterView, videoDidChangedTimeAt time: CMTime) {
        editDelegate?.editorView(self, videoDidChangedTimeAt: time)
    }
    func editorAdjusterView(
        _ editorAdjusterView: EditorAdjusterView,
        videoControlDidChangedTimeAt time: TimeInterval,
        for event: VideoControlEvent
    ) {
        editDelegate?.editorView(self, videoControlDidChangedTimeAt: time, for: event)
    }
    func editorAdjusterView(
        _ editorAdjusterView: EditorAdjusterView,
        videoApplyFilter sourceImage: CIImage,
        at time: CMTime
    ) -> CIImage {
        if let image = editDelegate?.editorView(self, videoApplyFilter: sourceImage, at: time) {
            return image
        }
        return sourceImage
    }
    
    @available(iOS 13.0, *)
    func editorAdjusterView(_ editorAdjusterView: EditorAdjusterView, toolPickerFramesObscuredDidChange toolPicker: PKToolPicker) {
        editDelegate?.editorView(self, toolPickerFramesObscuredDidChange: toolPicker)
    }
}
