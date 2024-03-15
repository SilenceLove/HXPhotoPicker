//
//  EditorViewController+EditorView.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/17.
//

import UIKit
import AVFoundation

extension EditorViewController: EditorViewDelegate {
    
    @objc
    func didTapClick() {
        if isShowFilterParameter {
            hideFilterParameterView()
            return
        }
        if let selectedTool = selectedTool {
            switch selectedTool.type {
            case .graffiti:
                if editorView.drawType == .canvas {
                    return
                }
            case .cropSize:
                return
            case .music:
                if isShowVolume {
                    hideVolumeView()
                    return
                }
                self.selectedTool = lastSelectedTool
                checkSelectedTool()
                hideMusicView()
                showToolsView()
                return
            default:
                break
            }
        }
        if isToolsDisplay {
            hideToolsView()
        }else {
            showToolsView()
        }
        isToolsDisplay = !isToolsDisplay
    }
    
    func checkSelectedTool() {
        guard let tool = self.selectedTool else {
            editorView.isStickerEnabled = true
            return
        }
        switch tool.type {
        case .graffiti:
            editorView.isStickerEnabled = false
            editorView.isDrawEnabled = true
        case .mosaic:
            editorView.isStickerEnabled = false
            editorView.isMosaicEnabled = true
        default:
            editorView.isStickerEnabled = true
        }
    }
    
    var isReset: Bool {
        if editorView.maskImage != nil {
            return true
        }
        return editorView.canReset
    }
    
    /// 编辑状态将要发生改变
    public func editorView(willBeginEditing editorView: EditorView) {
        
    }
    /// 编辑状态改变已经结束
    public func editorView(didEndEditing editorView: EditorView) {
        resetButton.isEnabled = isReset
    }
    /// 即将进入编辑状态
    public func editorView(editWillAppear editorView: EditorView) {
        
    }
    /// 已经进入编辑状态
    public func editorView(editDidAppear editorView: EditorView) {
        resetButton.isEnabled = isReset
    }
    /// 即将结束编辑状态
    public func editorView(editWillDisappear editorView: EditorView) {
    }
    /// 已经结束编辑状态
    public func editorView(editDidDisappear editorView: EditorView) {
        resetButton.isEnabled = isReset
        checkFinishButtonState()
    }
    /// 画笔/涂鸦/贴图发生改变
    public func editorView(contentViewBeginDraw editorView: EditorView) {
        if let type = selectedTool?.type {
            switch type {
            case .graffiti:
                if editorView.drawType == .canvas {
                    checkCanvasButtons()
                    checkFinishButtonState()
                    return
                }else {
                    if config.brush.isHideStickersDuringDrawing {
                        editorView.hideStickersView()
                    }
                }
            case .mosaic:
                if config.mosaic.isHideStickersDuringDrawing {
                    editorView.hideStickersView()
                }
            default:
                break
            }
        }
        hideToolsView()
        checkFinishButtonState()
    }
    /// 画笔/涂鸦/贴图结束改变
    public func editorView(contentViewEndDraw editorView: EditorView) {
        if let type = selectedTool?.type {
            switch type {
            case .graffiti:
                if editorView.drawType == .canvas {
                    checkCanvasButtons()
                    checkFinishButtonState()
                    return
                }else {
                    if config.brush.isHideStickersDuringDrawing {
                        editorView.showStickersView()
                    }
                }
            case .mosaic:
                if config.mosaic.isHideStickersDuringDrawing {
                    editorView.showStickersView()
                }
            default:
                break
            }
        }
        brushColorView.canUndo = editorView.isCanUndoDraw
        mosaicToolView.canUndo = editorView.isCanUndoMosaic
        checkFinishButtonState()
        if isShowVolume {
            return
        }
        if let tool = selectedTool {
            if tool.type == .music || tool.type == .cropSize {
                return
            }
        }
        if isToolsDisplay {
            showToolsView()
        }
    }
    /// 点击了贴纸
    /// 选中之后再次点击才会触发
    public func editorView(_ editorView: EditorView, didTapStickerItem itemView: EditorStickersItemBaseView) {
        presentText(itemView.text)
    }
    
    public func editorView(_ editorView: EditorView, shouldRemoveStickerItem itemView: EditorStickersItemBaseView) {
        if let musicPlayer = musicPlayer, musicPlayer.itemView == itemView {
            audioSticker = nil
            musicView.showLyricButton.isSelected = false
        }
    }
    /// 移除了贴纸
    public func editorView(_ editorView: EditorView, didRemoveStickerItem itemView: EditorStickersItemBaseView) {
        checkFinishButtonState()
    }
    public func editorView(_ editorView: EditorView, resetItemViews itemViews: [EditorStickersItemBaseView]) {
        for itemView in itemViews {
            if itemView.audio != nil, itemView.audio == musicPlayer?.audio {
                musicPlayer?.itemView = itemView
                audioSticker = itemView
                break
            }
        }
        checkFinishButtonState()
    }
    public func editorView(_ editorView: EditorView, shouldAddAudioItem audio: EditorStickerAudio) -> Bool {
        if let musicPlayer = musicPlayer, musicPlayer.audio == audio {
            return true
        }
        return false
    }
    
    // MARK: Video
    public func editorView(videoReadyForDisplay editorView: EditorView) {
        if selectedAsset.result == nil, config.video.isAutoPlay, !didEnterPlayGround { 
            editorView.playVideo()
        }
    }
    /// 视频开始播放
    public func editorView(_ editorView: EditorView, videoDidPlayAt time: CMTime) {
        videoControlView.isPlaying = true
        startPlayVideo()
        if videoCoverView != nil {
            videoCoverView?.removeFromSuperview()
            videoCoverView = nil
        }
    }
    /// 视频暂停播放
    public func editorView(_ editorView: EditorView, videoDidPauseAt time: CMTime) {
        videoControlView.isPlaying = false
        stopPlayVideo()
        
    }
    /// 视频滑动进度条发生了改变
    public func editorView(
        _ editorView: EditorView,
        videoControlDidChangedTimeAt time: TimeInterval,
        for event: VideoControlEvent
    ) {
        videoControlView.updateLineViewFrame(at: time)
    }
    
    public func editorView(
        _ editorView: EditorView,
        videoApplyFilter sourceImage: CIImage,
        at time: CMTime
    ) -> CIImage {
        var ciImage = sourceImage
        if filterEditFator.isApply {
            if let image = ciImage.apply(filterEditFator) {
                ciImage = image
            }else {
                ciImage = sourceImage
            }
        }
        guard let videoFilter = videoFilter,
              let videoFilterInfo = videoFilterInfo else {
            return ciImage
        }
        guard let resultImage = videoFilterInfo.videoFilterHandler?(
            ciImage.clampedToExtent(),
            videoFilter.parameters
        ) else {
            return sourceImage
        }
        return resultImage
    }
}
