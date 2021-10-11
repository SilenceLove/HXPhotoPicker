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
        present(imagePickerController, animated: true, completion: nil)
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
            addedCameraPhotoAsset(PhotoAsset(
                localImageAsset: .init(image: image)
            ))
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
        PhotoTools.exportEditVideo(
            for: avAsset,
            startTime: startTime,
            endTime: endTime,
            exportPreset: systemCamera.editExportPreset,
            videoQuality: systemCamera.editVideoQuality
        ) { (url, error) in
            guard let url = url, error == nil else {
                ProgressHUD.hide(forView: self.navigationController?.view, animated: false)
                ProgressHUD.showWarning(
                    addedTo: self.navigationController?.view,
                    text: "视频导出失败".localized,
                    animated: true,
                    delayHide: 1.5
                )
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
    func saveSystemAlbum(
        for asset: Any,
        mediaType: PHAssetMediaType,
        location: CLLocation? = nil,
        completion: (() -> Void)? = nil) {
        AssetManager.saveSystemAlbum(
            forAsset: asset,
            mediaType: mediaType,
            customAlbumName: config.customAlbumName,
            location: location
        ) { (phAsset) in
            if let phAsset = phAsset {
                self.addedCameraPhotoAsset(PhotoAsset(asset: phAsset), completion: completion)
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
        completion: (() -> Void)? = nil
    ) {
        func addPhotoAsset(_ photoAsset: PhotoAsset) {
            guard let picker = pickerController else { return }
            ProgressHUD.hide(forView: navigationController?.view, animated: true)
            if config.takePictureCompletionToSelected {
                if picker.addedPhotoAsset(photoAsset: photoAsset) {
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
                quickSelect(photoAsset)
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
        let didDismiss: Bool
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
                photoAsset = .init(localVideoAsset: .init(videoURL: videoURL))
            }
            var canSelect = false
            if !picker.canSelectAsset(for: photoAsset, showHUD: true) {
                if !didDismiss {
                    DispatchQueue.main.sync {
                        cameraController.dismiss(animated: true)
                    }
                }
                canSelect = true
            }
            if self.config.saveSystemAlbum {
                self.saveSystemAlbum(
                    for: asset,
                    mediaType: mediaType,
                    location: location
                ) { [weak self] in
                    self?.cameraControllerDismiss(canSelect)
                }
                return
            }
            self.addedCameraPhotoAsset(
                photoAsset
            ) { [weak self] in
                self?.cameraControllerDismiss(canSelect)
            }
        }
    }
    
    func cameraControllerDismiss(_ canSelect: Bool) {
        if let picker = pickerController,
           picker.config.selectMode == .single,
           config.finishSelectionAfterTakingPhoto,
           canSelect {
            presentingViewController?.dismiss(animated: true)
        }
    }
}
#endif
