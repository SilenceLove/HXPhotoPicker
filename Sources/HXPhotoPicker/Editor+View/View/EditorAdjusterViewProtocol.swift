//
//  EditorAdjusterViewProtocol.swift
//  HXPhotoPicker
//
//  Created by Slience on 2022/11/30.
//

import UIKit
import AVFoundation
import PencilKit

protocol EditorAdjusterViewDelegate: AnyObject {
    /// 编辑状态发生改变
    func editorAdjusterView(willBeginEditing adjusterView: EditorAdjusterView)
    /// 编辑状态改变结束
    func editorAdjusterView(didEndEditing adjusterView: EditorAdjusterView)
    /// 即将进入编辑状态
    func editorAdjusterView(editWillAppear adjusterView: EditorAdjusterView)
    /// 已经进入编辑状态
    func editorAdjusterView(editDidAppear adjusterView: EditorAdjusterView)
    /// 即将结束编辑状态
    func editorAdjusterView(editWillDisappear adjusterView: EditorAdjusterView)
    /// 已经结束编辑状态
    func editorAdjusterView(editDidDisappear adjusterView: EditorAdjusterView)
    /// 画笔/涂鸦/贴图发生改变
    func editorAdjusterView(contentViewBeginDraw adjusterView: EditorAdjusterView)
    /// 画笔/涂鸦/贴图结束改变
    func editorAdjusterView(contentViewEndDraw adjusterView: EditorAdjusterView)
    /// 点击的贴纸
    func editorAdjusterView(_ adjusterView: EditorAdjusterView, didTapStickerItem itemView: EditorStickersItemView)
    /// 移除了贴纸
    func editorAdjusterView(_ adjusterView: EditorAdjusterView, didRemoveItem itemView: EditorStickersItemView)
    func editorAdjusterView(_ adjusterView: EditorAdjusterView, shouldRemoveItem itemView: EditorStickersItemView)
    func editorAdjusterView(_ adjusterView: EditorAdjusterView, resetItemViews itemViews: [EditorStickersItemBaseView])
    func editorAdjusterView(_ adjusterView: EditorAdjusterView, shouldAddAudioItem audio: EditorStickerAudio) -> Bool
      
    func editorAdjusterView(_ editorAdjusterView: EditorAdjusterView, videoDidPlayAt time: CMTime)
    func editorAdjusterView(_ editorAdjusterView: EditorAdjusterView, videoDidPauseAt time: CMTime)
    func editorAdjusterView(videoReadyForDisplay editorAdjusterView: EditorAdjusterView)
    func editorAdjusterView(videoResetPlay editorAdjusterView: EditorAdjusterView)
    func editorAdjusterView(_ editorAdjusterView: EditorAdjusterView, videoIsPlaybackLikelyToKeepUp: Bool)
    func editorAdjusterView(_ editorAdjusterView: EditorAdjusterView, videoReadyToPlay duration: CMTime)
    func editorAdjusterView(_ editorAdjusterView: EditorAdjusterView, videoDidChangedBufferAt time: CMTime)
    func editorAdjusterView(_ editorAdjusterView: EditorAdjusterView, videoDidChangedTimeAt time: CMTime)
    func editorAdjusterView(
        _ editorAdjusterView: EditorAdjusterView,
        videoControlDidChangedTimeAt time: TimeInterval,
        for event: VideoControlEvent
    )
    
    func editorAdjusterView(
        _ editorAdjusterView: EditorAdjusterView,
        videoApplyFilter sourceImage: CIImage,
        at time: CMTime
    ) -> CIImage
    
    
    @available(iOS 13.0, *)
    func editorAdjusterView(_ editorAdjusterView: EditorAdjusterView, toolPickerFramesObscuredDidChange toolPicker: PKToolPicker)
}
