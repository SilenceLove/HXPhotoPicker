//
//  EditorAdjusterView+ContentView.swift
//  Example
//
//  Created by Slience on 2023/1/19.
//

import UIKit
import AVFoundation
import PencilKit

extension EditorAdjusterView {
    
    var drawType: EditorDarwType {
        get { contentView.drawType }
        set { contentView.drawType = newValue }
    }
    
    var isDrawEnabled: Bool {
        get { contentView.isDrawEnabled }
        set {
            if state == .edit, newValue {
                contentView.isDrawEnabled = false
                return
            }
            contentView.isDrawEnabled = newValue
        }
    }
    var drawLineWidth: CGFloat {
        get { contentView.drawLineWidth }
        set { contentView.drawLineWidth = newValue }
    }
    
    var drawLineColor: UIColor {
        get { contentView.drawLineColor }
        set { contentView.drawLineColor = newValue }
    }
    
    var isCanUndoDraw: Bool {
        contentView.isCanUndoDraw
    }
    
    func undoDraw() {
        contentView.undoDraw()
    }
    
    func undoAllDraw() {
        contentView.undoAllDraw()
    }
    
    var isMosaicEnabled: Bool {
        get { contentView.isMosaicEnabled }
        set {
            if state == .edit, newValue {
                contentView.isMosaicEnabled = false
                return
            }
            contentView.isMosaicEnabled = newValue
        }
    }
    var mosaicWidth: CGFloat {
        get { contentView.mosaicWidth }
        set { contentView.mosaicWidth = newValue }
    }
    var smearWidth: CGFloat {
        get { contentView.smearWidth }
        set { contentView.smearWidth = newValue }
    }
    var mosaicType: EditorMosaicType {
        get { contentView.mosaicType }
        set { contentView.mosaicType = newValue }
    }
    var isCanUndoMosaic: Bool {
        contentView.isCanUndoMosaic
    }
    func undoMosaic() {
        contentView.undoMosaic()
    }
    func undoAllMosaic() {
        contentView.undoAllMosaic()
    }
    
    var isStickerEnabled: Bool {
        get { contentView.isStickerEnabled }
        set {
            if state == .edit, newValue {
                contentView.isStickerEnabled = false
                return
            }
            contentView.isStickerEnabled = newValue
        }
    }
    
    var stickerCount: Int {
        contentView.stickerCount
    }
    var isStickerShowTrash: Bool {
        get { contentView.isStickerShowTrash }
        set { contentView.isStickerShowTrash = newValue }
    }
    
    func addSticker(
        _ item: EditorStickerItem,
        isSelected: Bool = false
    ) -> EditorStickersItemBaseView {
        contentView.addSticker(item, isSelected: isSelected)
    }
    
    func removeSticker(at itemView: EditorStickersItemBaseView) {
        contentView.removeSticker(at: itemView)
    }
    
    func removeAllSticker() {
        contentView.removeAllSticker()
    }
    
    func updateSticker(
        _ text: EditorStickerText
    ) {
        contentView.updateSticker(text)
    }
    
    func deselectedSticker() {
        contentView.deselectedSticker()
    }
    func showStickersView() {
        contentView.showStickersView()
    }
    
    func hideStickersView() {
        contentView.hideStickersView()
    }
    
    var isVideoPlayToEndTimeAutoPlay: Bool {
        get { contentView.isVideoPlayToEndTimeAutoPlay}
        set { contentView.isVideoPlayToEndTimeAutoPlay = newValue }
    }
}

extension EditorAdjusterView: EditorContentViewDelegate {
    
    func contentView(rotateVideo contentView: EditorContentView) {
        resetVideoRotate(true)
    }
    func contentView(resetVideoRotate contentView: EditorContentView) {
        resetVideoRotate(false)
    }
    func contentView(_ contentView: EditorContentView, shouldAddAudioItem audio: EditorStickerAudio) -> Bool {
        if let shouldAddAudioItem = delegate?.editorAdjusterView(self, shouldAddAudioItem: audio) {
            return shouldAddAudioItem
        }
        return true
    }
    
    func contentView(_ contentView: EditorContentView, videoDidPlayAt time: CMTime) {
        frameView.videoSliderView.isPlaying = true
        delegate?.editorAdjusterView(self, videoDidPlayAt: time)
    }
    func contentView(_ contentView: EditorContentView, videoDidPauseAt time: CMTime) {
        frameView.videoSliderView.isPlaying = false
        delegate?.editorAdjusterView(self, videoDidPauseAt: time)
    }
    func contentView(videoReadyForDisplay contentView: EditorContentView) {
        delegate?.editorAdjusterView(videoReadyForDisplay: self)
        updateControlScaleSize()
    }
    func contentView(resetPlay contentView: EditorContentView) {
        delegate?.editorAdjusterView(videoResetPlay: self)
        frameView.videoSliderView.setPlayDuration(0, isAnimation: false)
    }
    func contentView(_ contentView: EditorContentView, isPlaybackLikelyToKeepUp: Bool) {
        delegate?.editorAdjusterView(self, videoIsPlaybackLikelyToKeepUp: isPlaybackLikelyToKeepUp)
    }
    func contentView(_ contentView: EditorContentView, readyToPlay duration: CMTime) {
        if let startTime = videoStartTime, let endTime = videoEndTime {
            frameView.videoSliderView.videoDuration = endTime.seconds - startTime.seconds
        }else if let startTime = videoStartTime {
            frameView.videoSliderView.videoDuration = duration.seconds - startTime.seconds
        }else if let endTime = videoEndTime {
            frameView.videoSliderView.videoDuration = endTime.seconds
        }else {
            frameView.videoSliderView.videoDuration = duration.seconds
        }
        delegate?.editorAdjusterView(self, videoReadyToPlay: duration)
    }
    func contentView(_ contentView: EditorContentView, didChangedBuffer time: CMTime) {
        if let startTime = videoStartTime, let endTime = videoEndTime {
            frameView.videoSliderView.bufferDuration = min(
                max(0, time.seconds - startTime.seconds),
                endTime.seconds - startTime.seconds
            )
        }else if let startTime = videoStartTime {
            let videoDuration = videoDuration.seconds
            frameView.videoSliderView.bufferDuration = min(
                max(0, time.seconds - startTime.seconds),
                videoDuration - startTime.seconds
            )
        }else if let endTime = videoEndTime {
            frameView.videoSliderView.bufferDuration = min(time.seconds, endTime.seconds)
        }else {
            frameView.videoSliderView.bufferDuration = time.seconds
        }
        delegate?.editorAdjusterView(self, videoDidChangedBufferAt: time)
    }
    func contentView(_ contentView: EditorContentView, didChangedTimeAt time: CMTime) {
        var duration: Double
        if let startTime = videoStartTime, videoEndTime != nil {
            duration = time.seconds - startTime.seconds
        }else if let startTime = videoStartTime {
            let videoDuration = videoDuration.seconds
            duration = (videoDuration - startTime.seconds) * ((time.seconds - startTime.seconds) / videoDuration)
        }else {
            duration = time.seconds
        }
        frameView.videoSliderView.setPlayDuration(duration, isAnimation: true)
        delegate?.editorAdjusterView(self, videoDidChangedTimeAt: time)
    }
    
    func contentView(drawViewBeginDraw contentView: EditorContentView) {
        delegate?.editorAdjusterView(contentViewBeginDraw: self)
    }
    func contentView(drawViewEndDraw contentView: EditorContentView) {
        delegate?.editorAdjusterView(contentViewEndDraw: self)
    }
    func contentView(
        _ contentView: EditorContentView,
        stickersView: EditorStickersView,
        moveToCenter itemView: EditorStickersItemView
    ) -> Bool {
        guard let inControlRect = itemView.superview?.convert(itemView.frame, to: frameView.controlView) else {
            return true
        }
        let controlRect = frameView.controlView.bounds
        if inControlRect.minX > controlRect.width - 40 {
            return true
        }
        if inControlRect.minX < -(inControlRect.width - 40) {
            return true
        }
        if inControlRect.minY > controlRect.height - 40 {
            return true
        }
        if inControlRect.minY < -(inControlRect.height - 40) {
            return true
        }
        return false
    }
    
    func contentView(_ contentView: EditorContentView, stickerMaxScale itemSize: CGSize) -> CGFloat {
        let rect = frameView.controlView.frame.inset(by: .init(top: -30, left: -30, bottom: -30, right: -30))
        let maxScale = max(rect.width / itemSize.width, rect.height / itemSize.height)
        return maxScale
    }
    
    func contentView(_ contentView: EditorContentView, didTapSticker itemView: EditorStickersItemView) {
        delegate?.editorAdjusterView(self, didTapStickerItem: itemView)
    }
    
    func contentView(_ contentView: EditorContentView, didRemovedSticker itemView: EditorStickersItemView) {
        delegate?.editorAdjusterView(self, didRemoveItem: itemView)
    }
    
    func contentView(_ contentView: EditorContentView, shouldRemoveSticker itemView: EditorStickersItemView) {
        delegate?.editorAdjusterView(self, shouldRemoveItem: itemView)
    }
    
    func contentView(_ contentView: EditorContentView, resetItemViews itemViews: [EditorStickersItemBaseView]) {
        delegate?.editorAdjusterView(self, resetItemViews: itemViews)
    }
    
    func contentView(_ contentView: EditorContentView, stickerItemCenter stickersView: EditorStickersView) -> CGPoint? {
//        if let window = UIApplication.hx_keyWindow {
//            let windowRect = window.convert(contentView.frame, from: self)
//            let centerHeight: CGFloat
//            if windowRect.height < window.height {
//                centerHeight = windowRect.height
//            }else {
//                centerHeight = window.height
//            }
//            let centerRect = CGRect(x: 0, y: windowRect.minY, width: window.width, height: centerHeight)
//            let contentRect = contentView.convert(centerRect, from: window)
//            return .init(x: contentRect.midX, y: contentRect.midY)
//        }
        return frameView.convert(frameView.controlView.center, to: stickersView)
    }
    
    func contentView(
        _ contentView: EditorContentView,
        videoApplyFilter sourceImage: CIImage,
        at time: CMTime
    ) -> CIImage {
        if let image = delegate?.editorAdjusterView(self, videoApplyFilter: sourceImage, at: time) {
            return image
        }
        return sourceImage
    }
    
    @available(iOS 13.0, *)
    func contentView(_ contentView: EditorContentView, toolPickerFramesObscuredDidChange toolPicker: PKToolPicker) {
        delegate?.editorAdjusterView(self, toolPickerFramesObscuredDidChange: toolPicker)
    }
}

@available(iOS 13.0, *)
extension EditorAdjusterView {
    
    var canvasImage: UIImage {
        contentView.canvasImage
    }
    
    var isCanvasEmpty: Bool {
        contentView.isCanvasEmpty
    }
    
    var isCanvasCanUndo: Bool {
        contentView.isCanvasCanUndo
    }
    
    var isCanvasCanRedo: Bool {
        contentView.isCanvasCanRedo
    }
    
    func canvasRedo() {
        contentView.canvasRedo()
    }
    
    func canvasUndo() {
        contentView.canvasUndo()
    }
    
    func canvasUndoCurrentAll() {
        contentView.canvasUndoCurrentAll()
    }
    
    func canvasUndoAll() {
        contentView.canvasUndoAll()
    }
    
    func startCanvasDrawing() -> PKToolPicker? {
        contentView.startCanvasDrawing()
    }
    
    func finishCanvasDrawing() {
        contentView.finishCanvasDrawing()
    }
     
    func cancelCanvasDrawing() {
        contentView.cancelCanvasDrawing()
    }
    
    func enterCanvasDrawing() -> PKToolPicker? {
        contentView.enterCanvasDrawing()
    }
    
    func quitCanvasDrawing() {
        contentView.quitCanvasDrawing()
    }
}

