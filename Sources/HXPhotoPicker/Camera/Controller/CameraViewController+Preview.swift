//
//  CameraViewController+Preview.swift
//  CameraViewController+Preview
//
//  Created by Slience on 2021/10/19.
//

import UIKit

#if !targetEnvironment(macCatalyst)
extension CameraViewController: CameraNormalPreviewViewDelegate {
    func previewView(didPreviewing previewView: CameraNormalPreviewView) {
        bottomView.hiddenTip()
        bottomView.isGestureEnable = true
    }
    
    func previewView(_ previewView: CameraNormalPreviewView, pinchGestureScale scale: CGFloat) {
        cameraManager.zoomFacto = scale
    }
    
    func previewView(_ previewView: CameraNormalPreviewView, tappedToFocusAt point: CGPoint) {
        try? cameraManager.expose(at: point)
    }
}
#endif
