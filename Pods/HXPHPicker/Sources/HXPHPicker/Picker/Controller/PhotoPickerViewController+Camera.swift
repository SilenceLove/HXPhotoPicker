//
//  PhotoPickerViewController+Camera.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/4.
//

import UIKit
import MobileCoreServices
import AVFoundation
import Photos

// MARK: UIImagePickerControllerDelegate
extension PhotoPickerViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func presentCameraViewController() {
        guard let pickerController = pickerController,
              pickerController.shouldPresentCamera() else {
            return
        }
        #if HXPICKER_ENABLE_CAMERA
        switch config.cameraType {
        case .custom(let camerConfig):
            let type: CameraController.CaptureType
            if pickerController.config.selectOptions.isPhoto &&
                pickerController.config.selectOptions.isVideo {
                type = .all
            }else if pickerController.config.selectOptions.isPhoto {
                type = .photo
            }else {
                type = .video
            }
            camerConfig.languageType = pickerController.config.languageType
            camerConfig.appearanceStyle = pickerController.config.appearanceStyle
            let vc = CameraController(
                config: camerConfig,
                type: type,
                delegate: self
            )
            vc.autoDismiss = false
            present(vc, animated: true)
            return
        default:
            break
        }
        #endif
        guard let camerConfig = config.cameraType.systemConfig else {
            return
        }
        let imagePickerController = SystemCameraViewController.init()
        imagePickerController.sourceType = .camera
        imagePickerController.delegate = self
        imagePickerController.videoMaximumDuration = camerConfig.videoMaximumDuration
        imagePickerController.videoQuality = camerConfig.videoQuality
        imagePickerController.allowsEditing = camerConfig.allowsEditing
        imagePickerController.cameraDevice = camerConfig.cameraDevice
        var mediaTypes: [String] = []
        if !camerConfig.mediaTypes.isEmpty {
            mediaTypes = camerConfig.mediaTypes
        }else {
            if pickerController.config.selectOptions.isPhoto {
                mediaTypes.append(kUTTypeImage as String)
            }
            if pickerController.config.selectOptions.isVideo {
                mediaTypes.append(kUTTypeMovie as String)
            }
        }
        imagePickerController.mediaTypes = mediaTypes
        imagePickerController.modalPresentationStyle = .fullScreen
        present(imagePickerController, animated: true)
    }
    
    public func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        ProgressHUD.showLoading(
            addedTo: self.navigationController?.view,
            animated: true
        )
        picker.dismiss(animated: true, completion: nil)
        DispatchQueue.global().async {
            let mediaType = info[.mediaType] as! String
            if mediaType == kUTTypeImage as String {
                self.pickingImage(info: info)
            }else {
                self.pickingVideo(info: info)
            }
        }
    }
    func pickingImage(info: [UIImagePickerController.InfoKey: Any]) {
        var image: UIImage? = (info[.editedImage] ?? info[.originalImage]) as? UIImage
        image = image?.scaleSuitableSize()
        if let image = image {
            if config.saveSystemAlbum {
                saveSystemAlbum(for: image, mediaType: .image)
                return
            }
            addedCameraPhotoAsset(
                PhotoAsset(
                    localImageAsset: .init(image: image)
                )
            )
            return
        }
        DispatchQueue.main.async {
            ProgressHUD.hide(
                forView: self.navigationController?.view,
                animated: false
            )
        }
    }
    func pickingVideo(info: [UIImagePickerController.InfoKey: Any]) {
        let startTime = info[
            UIImagePickerController.InfoKey(
                rawValue: "_UIImagePickerControllerVideoEditingStart"
            )
        ] as? TimeInterval
        let endTime = info[
            UIImagePickerController.InfoKey(
                rawValue: "_UIImagePickerControllerVideoEditingEnd"
            )
        ] as? TimeInterval
        let videoURL: URL? = info[.mediaURL] as? URL
        guard let videoURL = videoURL else {
            DispatchQueue.main.async {
                ProgressHUD.hide(
                    forView: self.navigationController?.view,
                    animated: false
                )
            }
            return
        }
        guard let startTime = startTime,
              let endTime = endTime  else {
            if config.saveSystemAlbum {
                saveSystemAlbum(for: videoURL, mediaType: .video)
                return
            }
            addedCameraPhotoAsset(
                PhotoAsset(
                    localVideoAsset: .init(videoURL: videoURL)
                )
            )
            return
        }
        guard let systemCamera = config.cameraType.systemConfig else {
            return
        }
        let avAsset = AVAsset.init(url: videoURL)
        avAsset.loadValuesAsynchronously(forKeys: ["tracks"]) {
            if avAsset.statusOfValue(forKey: "tracks", error: nil) != .loaded {
                DispatchQueue.main.async {
                    self.showExportFailed()
                }
                return
            }
            PhotoTools.exportEditVideo(
                for: avAsset,
                startTime: startTime,
                endTime: endTime,
                exportPreset: systemCamera.editExportPreset,
                videoQuality: systemCamera.editVideoQuality
            ) { (url, error) in
                guard let url = url, error == nil else {
                    self.showExportFailed()
                    return
                }
                if self.config.saveSystemAlbum {
                    self.saveSystemAlbum(for: url, mediaType: .video)
                    return
                }
                let phAsset: PhotoAsset = PhotoAsset.init(localVideoAsset: .init(videoURL: url))
                self.addedCameraPhotoAsset(phAsset)
            }
        }
    }
    func showExportFailed() {
        ProgressHUD.hide(forView: navigationController?.view, animated: false)
        ProgressHUD.showWarning(
            addedTo: navigationController?.view,
            text: "视频导出失败".localized,
            animated: true,
            delayHide: 1.5
        )
    }
    func saveSystemAlbum(
        for asset: Any,
        mediaType: PHAssetMediaType,
        location: CLLocation? = nil,
        isCapture: Bool = false,
        completion: (() -> Void)? = nil) {
        AssetManager.saveSystemAlbum(
            forAsset: asset,
            mediaType: mediaType,
            customAlbumName: config.customAlbumName,
            location: location
        ) { (phAsset) in
            if let phAsset = phAsset {
                self.addedCameraPhotoAsset(
                    PhotoAsset(asset: phAsset),
                    isCapture: isCapture,
                    completion: completion
                )
            }else {
                DispatchQueue.main.async {
                    ProgressHUD.hide(
                        forView: self.navigationController?.view,
                        animated: true
                    )
                    ProgressHUD.showWarning(
                        addedTo: self.navigationController?.view,
                        text: "保存失败".localized,
                        animated: true,
                        delayHide: 1.5
                    )
                    completion?()
                }
            }
        }
    }
    func addedCameraPhotoAsset(
        _ photoAsset: PhotoAsset,
        isCapture: Bool = false,
        completion: (() -> Void)? = nil
    ) {
        func addPhotoAsset(_ photoAsset: PhotoAsset) {
            guard let picker = pickerController else { return }
            ProgressHUD.hide(forView: navigationController?.view, animated: true)
            if config.takePictureCompletionToSelected {
                if picker.addedPhotoAsset(
                    photoAsset: photoAsset,
                    filterEditor: true
                ) {
                    updateCellSelectedTitle()
                }
            }
            picker.updateAlbums(coverImage: photoAsset.originalImage, count: 1)
            if photoAsset.isLocalAsset {
                picker.addedLocalCameraAsset(photoAsset: photoAsset)
            }
            if picker.config.albumShowMode == .popup {
                albumView.tableView.reloadData()
            }
            addedPhotoAsset(for: photoAsset)
            bottomView.updateFinishButtonTitle()
            setupEmptyView()
            if picker.config.selectMode == .single && config.finishSelectionAfterTakingPhoto {
                quickSelect(photoAsset, isCapture: isCapture)
            }
            completion?()
        }
        DispatchQueue.main.async {
            addPhotoAsset(photoAsset)
        }
    }
}

#if HXPICKER_ENABLE_CAMERA
extension PhotoPickerViewController: CameraControllerDelegate {
    public func cameraController(
        _ cameraController: CameraController,
        didFinishWithResult result: CameraController.Result,
        location: CLLocation?
    ) {
        guard let picker = pickerController else {
            cameraController.dismiss(animated: true)
            return
        }
        var didDismiss: Bool
        if picker.config.selectMode == .single &&
           config.finishSelectionAfterTakingPhoto {
            didDismiss = false
            ProgressHUD.showLoading(addedTo: cameraController.view, animated: true)
        }else {
            didDismiss = true
            cameraController.dismiss(animated: true)
        }
        ProgressHUD.showLoading(
            addedTo: self.navigationController?.view,
            animated: true
        )
        DispatchQueue.global().async {
            let asset: Any
            let mediaType: PHAssetMediaType
            let photoAsset: PhotoAsset
            switch result {
            case .image(let image):
                asset = image
                mediaType = .image
                photoAsset = .init(localImageAsset: .init(image: image))
            case .video(let videoURL):
                asset = videoURL
                mediaType = .video
                let videoDuration = PhotoTools.getVideoDuration(videoURL: videoURL)
                photoAsset = .init(localVideoAsset: .init(videoURL: videoURL, duration: videoDuration))
            }
            var canSelect = true
            if !picker.canSelectAsset(
                for: photoAsset,
                showHUD: true,
                filterEditor: true
            ) {
                if !didDismiss {
                    DispatchQueue.main.async {
                        cameraController.dismiss(animated: true)
                    }
                    didDismiss = true
                }
                canSelect = false
            }
            if !didDismiss && !picker.autoDismiss {
                DispatchQueue.main.async {
                    cameraController.dismiss(animated: true)
                }
                didDismiss = true
            }
            if self.config.saveSystemAlbum {
                self.saveSystemAlbum(
                    for: asset,
                    mediaType: mediaType,
                    location: location,
                    isCapture: true
                ) { [weak self] in
                    self?.cameraControllerDismiss(canSelect)
                }
                return
            }
            self.addedCameraPhotoAsset(
                photoAsset,
                isCapture: true
            ) { [weak self] in
                self?.cameraControllerDismiss(canSelect)
            }
        }
    }
    
    func cameraControllerDismiss(_ canSelect: Bool) {
        guard let picker = pickerController,
           picker.config.selectMode == .single,
           config.finishSelectionAfterTakingPhoto,
           canSelect else {
            return
        }
        if picker.autoDismiss {
            presentingViewController?.dismiss(animated: true)
        }
    }
}
#endif
