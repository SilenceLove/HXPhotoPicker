//
//  CameraViewController+Preview.swift
//  CameraViewController+Preview
//
//  Created by Slience on 2021/10/19.
//

import UIKit

#if !targetEnvironment(macCatalyst)
extension CameraViewController: CameraPreviewViewDelegate {
    func previewView(didPreviewing previewView: CameraPreviewView) {
        bottomView.hiddenTip()
        if !config.videoFilters.isEmpty && firstShowFilterName && cameraManager.filterIndex > 0 {
            if config.changeFilterShowName {
                previewView.showFilterName(
                    cameraManager.videoFilter.currentFilterName,
                    true
                )
            }
            firstShowFilterName = false
        }
        bottomView.isGestureEnable = true
    }
    func previewView(_ previewView: CameraPreviewView, pinchGestureScale scale: CGFloat) {
        cameraManager.zoomFacto = scale
    }
    
    func previewView(_ previewView: CameraPreviewView, tappedToFocusAt point: CGPoint) {
        try? cameraManager.expose(at: point)
    }
    
    func previewView(didLeftSwipe previewView: CameraPreviewView) {
        if !config.videoFilters.isEmpty {
            cameraManager.filterIndex += 1
            if config.changeFilterShowName {
                previewView.showFilterName(
                    cameraManager.videoFilter.currentFilterName,
                    false
                )
            }
        }
    }
    
    func previewView(didRightSwipe previewView: CameraPreviewView) {
        if !config.videoFilters.isEmpty {
            cameraManager.filterIndex -= 1
            if config.changeFilterShowName {
                previewView.showFilterName(
                    cameraManager.videoFilter.currentFilterName,
                    true
                )
            }
        }
    }
}
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
