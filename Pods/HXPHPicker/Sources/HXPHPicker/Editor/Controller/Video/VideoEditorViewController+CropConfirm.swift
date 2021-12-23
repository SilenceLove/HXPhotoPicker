//
//  VideoEditorViewController+CropConfirm.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/6.
//

import UIKit

// MARK: EditorCropConfirmViewDelegate
extension VideoEditorViewController: EditorCropConfirmViewDelegate {
    
    /// 点击完成按钮
    /// - Parameter cropConfirmView: 裁剪视图
    func cropConfirmView(didFinishButtonClick cropConfirmView: EditorCropConfirmView) {
        videoView.stickerEnabled = true
        if onceState == .cropTime {
            onceState = .normal
        }
        if state == .cropTime {
            didEdited = true
            pState = .normal
            cropView.stopScroll(nil)
            currentCropOffset = cropView.collectionView.contentOffset
            currentValidRect = cropView.frameMaskView.validRect
            videoView.playerView.playStartTime = cropView.getStartTime(real: true)
            videoView.playerView.playEndTime = cropView.getEndTime(real: true)
            videoView.playerView.play()
            hiddenCropConfirmView()
            videoView.cancelCropTime(true)
        }else if state == .cropSize {
            pState = .normal
            videoView.finishCropping(true)
            toolCropSizeAnimation()
        }
    }
    
    func cropConfirmView(didResetButtonClick cropConfirmView: EditorCropConfirmView) {
        cropConfirmView.resetButton.isEnabled = false
        videoView.reset(true)
        cropToolView.reset(animated: true)
    }
    
    /// 点击取消按钮
    /// - Parameter cropConfirmView: 裁剪视图
    func cropConfirmView(didCancelButtonClick cropConfirmView: EditorCropConfirmView) {
        videoView.stickerEnabled = true
        if onceState == .cropTime {
            didBackClick()
            return
        }
        if state == .cropTime {
            cancelCropTime(true)
        }else if state == .cropSize {
            pState = .normal
            videoView.cancelCropping(true)
            toolCropSizeAnimation()
        }
    }
    
    func cancelCropTime(_ animation: Bool) {
        pState = .normal
        cropView.stopScroll(currentCropOffset)
        if currentValidRect.equalTo(.zero) {
            cropView.resetValidRect()
        }else {
            cropView.frameMaskView.validRect = currentValidRect
        }
        cropView.stopLineAnimation()
        videoView.playerView.playStartTime = beforeStartTime
        videoView.playerView.playEndTime = beforeEndTime
        hiddenCropConfirmView()
        videoView.cancelCropTime(animation)
        
        cropView.stopLineAnimation()
        videoView.playerView.resetPlay()
        if let startTime = beforeStartTime, let endTime = beforeEndTime {
            startPlayTimer(startTime: startTime, endTime: endTime)
        }else {
            stopPlayTimer()
        }
    }
    
    func hiddenCropConfirmView() {
        showTopView()
        UIView.animate(withDuration: 0.25) {
            self.cropView.alpha = 0
            self.cropConfirmView.alpha = 0
        } completion: { (isFinished) in
            self.cropView.isHidden = true
            self.cropConfirmView.isHidden = true
        }
    }
}
