//
//  CameraViewController+BottomView.swift
//  CameraViewController+BottomView
//
//  Created by Slience on 2021/10/19.
//

import UIKit

#if !targetEnvironment(macCatalyst)
extension CameraViewController: CameraBottomViewDelegate {
    func bottomView(beganTakePictures bottomView: CameraBottomView) {
        if !cameraManager.session.isRunning {
            return
        }
        bottomView.isGestureEnable = false
        cameraManager.capturePhoto {
            
        } completion: { [weak self] data in
            guard let self = self else { return }
            if let data = data,
               let image = UIImage(data: data) {
                self.capturePhotoCompletion(image: image)
            }else {
                self.capturePhotoCompletion(image: nil)
            }
        }
    }
    func capturePhotoCompletion(image: UIImage?) {
        if let image = image?.normalizedImage() {
            resetZoom()
            cameraManager.stopRunning()
            if config.cameraType == .metal {
                previewView.resetMask(image)
            }else {
                normalPreviewView.resetMask(image)
            }
            bottomView.isGestureEnable = false
            saveCameraImage(image)
            #if HXPICKER_ENABLE_EDITOR
            if config.allowsEditing {
                openPhotoEditor(image)
            }else {
                openPhotoResult(image)
            }
            #else
            openPhotoResult(image)
            #endif
        }else {
            bottomView.isGestureEnable = true
            PhotoManager.HUDView.showInfo(with: .textManager.camera.captureFailedHudTitle.text, delay: 1.5, animated: true, addedTo: view)
        }
    }
    func bottomView(beganRecording bottomView: CameraBottomView) {
        cameraManager.startRecording { [weak self] duration in
            self?.bottomView.startTakeMaskLayerPath(duration: duration)
        } progress: { [weak self] _, time in
            self?.bottomView.updateVideoTime(time)
        } completion: { [weak self] videoURL, error in
            guard let self = self else { return }
            self.recordingCompletion(videoURL: videoURL, error: error)
        }
    }
    func recordingCompletion(videoURL: URL?, error: Error?) {
        bottomView.stopRecord()
        if error == nil, let videoURL = videoURL {
            resetZoom()
            let image = PhotoTools.getVideoThumbnailImage(videoURL: videoURL, atTime: 0.1)
            cameraManager.stopRunning()
            if config.cameraType == .metal {
                previewView.resetMask(image)
            }else {
                normalPreviewView.resetMask(image)
            }
            bottomView.isGestureEnable = false
            saveCameraVideo(videoURL)
            #if HXPICKER_ENABLE_EDITOR
            if config.allowsEditing {
                openVideoEditor(videoURL)
            }else {
                openVideoResult(videoURL)
            }
            #else
            openVideoResult(videoURL)
            #endif
        }else {
            let text: String
            if let error = error as NSError?,
               error.code == 110 {
                text = String(
                    format: "拍摄时长不足%d秒".localized,
                    arguments: [Int(config.videoMinimumDuration)]
                )
            }else {
                text = .textManager.camera.captureFailedHudTitle.text
            }
            PhotoManager.HUDView.showInfo(with: text, delay: 1.5, animated: true, addedTo: view)
        }
    }
    func bottomView(endRecording bottomView: CameraBottomView) {
        cameraManager.stopRecording()
    }
    func bottomView(longPressDidBegan bottomView: CameraBottomView) {
        if config.cameraType == .metal {
            currentZoomFacto = previewView.effectiveScale
        }else {
            currentZoomFacto = normalPreviewView.effectiveScale
        }
    }
    func bottomView(_ bottomView: CameraBottomView, longPressDidChanged scale: CGFloat) {
        let remaining: CGFloat
        if config.cameraType == .metal {
            remaining = previewView.maxScale - currentZoomFacto
        }else {
            remaining = normalPreviewView.maxScale - currentZoomFacto
        }
        let zoomScale = currentZoomFacto + remaining * scale
        cameraManager.zoomFacto = zoomScale
    }
    func bottomView(longPressDidEnded bottomView: CameraBottomView) {
        if config.cameraType == .metal {
            previewView.effectiveScale = cameraManager.zoomFacto
        }else {
            normalPreviewView.effectiveScale = cameraManager.zoomFacto
        }
    }
    func bottomView(didBackButton bottomView: CameraBottomView) {
        backClick(true)
    }
    func bottomView(
        _ bottomView: CameraBottomView,
        didChangeTakeType takeType: CameraBottomViewTakeType
    ) {
        
    }
    func openPhotoResult(_ image: UIImage) {
        let vc = CameraResultViewController(
            image: image,
            tintColor: config.tintColor
        )
        vc.delegate = self
        navigationController?.pushViewController(vc, animated: false)
    }
    func openVideoResult(_ videoURL: URL) {
        let vc = CameraResultViewController(
            videoURL: videoURL,
            tintColor: config.tintColor
        )
        vc.delegate = self
        navigationController?.pushViewController(vc, animated: false)
    }
}
#endif
