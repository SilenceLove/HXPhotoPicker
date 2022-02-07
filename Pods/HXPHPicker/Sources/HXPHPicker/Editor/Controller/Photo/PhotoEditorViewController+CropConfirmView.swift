//
//  PhotoEditorViewController+CropConfirmView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/11/15.
//

import UIKit

// MARK: EditorCropConfirmViewDelegate
extension PhotoEditorViewController: EditorCropConfirmViewDelegate {
    
    /// 点击完成按钮
    /// - Parameter cropConfirmView: 裁剪视图
    func cropConfirmView(didFinishButtonClick cropConfirmView: EditorCropConfirmView) {
        if config.fixedCropState {
            imageView.imageResizerView.finishCropping(false, completion: nil, updateCrop: false)
            if config.cropping.isRoundCrop {
                imageView.imageResizerView.layer.cornerRadius = 1
            }
            exportResources()
            return
        }
        pState = .normal
        imageView.finishCropping(true)
        croppingAction()
    }
    
    /// 点击还原按钮
    /// - Parameter cropConfirmView: 裁剪视图
    func cropConfirmView(didResetButtonClick cropConfirmView: EditorCropConfirmView) {
        cropConfirmView.resetButton.isEnabled = false
        imageView.reset(true)
        cropToolView.reset(animated: true)
    }
    
    /// 点击取消按钮
    /// - Parameter cropConfirmView: 裁剪视图
    func cropConfirmView(didCancelButtonClick cropConfirmView: EditorCropConfirmView) {
        if config.fixedCropState {
            transitionalImage = image
            cancelHandler?(self)
            didBackClick(true)
            return
        }
        pState = .normal
        imageView.cancelCropping(true)
        croppingAction()
    }
}
