//
//  PhotoPickerViewController+Camera.swift
//  HXPhotoPicker
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
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            PhotoManager.HUDView.showInfo(with: .textPhotoList.cameraUnavailableHudTitle.text, delay: 1.5, animated: true, addedTo: pickerController.view)
            return
        }
        if !pickerController.shouldPresentCamera() {
            return
        }
        #if HXPICKER_ENABLE_CAMERA && !targetEnvironment(macCatalyst)
        switch config.cameraType {
        case .custom(var camerConfig):
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
            camerConfig.isSaveSystemAlbum = false
            camerConfig.isAutoBack = false
            let vc = CameraController(
                config: camerConfig,
                type: type,
                delegate: self
            )
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
        PhotoManager.HUDView.show(with: nil, delay: 0, animated: true, addedTo: navigationController?.view)
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
        var image: UIImage?
        if let pickerImage = info[.editedImage] as? UIImage {
            image = pickerImage
        }else if let pickerImage = info[.originalImage] as? UIImage {
            image = pickerImage
        }
        image = image?.scaleSuitableSize()
        if let image = image {
            if config.isSaveSystemAlbum {
                saveSystemAlbum(type: .image(image))
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
            PhotoManager.HUDView.dismiss(delay: 0, animated: false, for: self.navigationController?.view)
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
                PhotoManager.HUDView.dismiss(delay: 0, animated: false, for: self.navigationController?.view)
            }
            return
        }
        guard let startTime = startTime,
              let endTime = endTime  else {
            if config.isSaveSystemAlbum {
                saveSystemAlbum(type: .videoURL(videoURL))
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
        let avAsset = AVAsset(url: videoURL)
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
                if self.config.isSaveSystemAlbum {
                    self.saveSystemAlbum(type: .videoURL(url))
                    return
                }
                let phAsset: PhotoAsset = PhotoAsset.init(localVideoAsset: .init(videoURL: url))
                self.addedCameraPhotoAsset(phAsset)
            }
        }
    }
    func showExportFailed() {
        PhotoManager.HUDView.dismiss(delay: 0, animated: false, for: navigationController?.view)
        PhotoManager.HUDView.showInfo(with: .textPhotoList.videoExportFailedHudTitle.text, delay: 1.5, animated: true, addedTo: navigationController?.view)
    }
    func saveSystemAlbum(
        type: AssetSaveUtil.SaveType,
        location: CLLocation? = nil,
        isCapture: Bool = false,
        completion: (() -> Void)? = nil
    ) {
        AssetSaveUtil.save(
            type: type,
            albumType: config.saveSystemAlbumType,
            location: location
        ) {
            switch $0 {
            case .success(let phAsset):
                PhotoManager.shared.pickerCaptureTime = Date().timeIntervalSince1970
                self.addedCameraPhotoAsset(
                    PhotoAsset(asset: phAsset),
                    isCapture: isCapture,
                    completion: completion
                )
            case .failure:
                DispatchQueue.main.async {
                    PhotoManager.HUDView.dismiss(delay: 0, animated: true, for: self.navigationController?.view)
                    PhotoManager.HUDView.showInfo(with: .textPhotoList.saveSystemAlbumFailedHudTitle.text, delay: 1.5, animated: true, addedTo: self.navigationController?.view)
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
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.addedCameraPhotoAsset(photoAsset, isCapture: isCapture, completion: completion)
            }
            return
        }
        PhotoManager.HUDView.dismiss(delay: 0, animated: true, for: navigationController?.view)
        if config.takePictureCompletionToSelected {
            if pickerController.pickerData.append(
                photoAsset,
                isFilterEditor: true
            ) {
                listView.updateCellSelectedTitle()
                if isShowToolbar {
                    photoToolbar.insertSelectedAsset(photoAsset)
                    updateToolbarFrame()
                }
            }
        }
        if photoAsset.isLocalAsset {
            pickerController.pickerData.addedLocalCamera(photoAsset)
        }
        pickerController.updateAlbums(coverImage: photoAsset.originalImage, count: 1)
        listView.addedAsset(for: photoAsset)
        if pickerController.config.albumShowMode.isPopView {
            albumView.reloadData()
        }
        photoToolbar.selectedAssetDidChanged(pickerController.selectedAssetArray)
        finishItem?.selectedAssetDidChanged(pickerController.selectedAssetArray)
        requestSelectedAssetFileSize()
        if pickerController.config.selectMode == .single && config.finishSelectionAfterTakingPhoto {
            quickSelect(photoAsset, isCapture: isCapture)
        }
        completion?()
    }
}

#if HXPICKER_ENABLE_CAMERA && !targetEnvironment(macCatalyst)
extension PhotoPickerViewController: CameraControllerDelegate {
    public func cameraController(
        _ cameraController: CameraController,
        didFinishWithResult result: CameraController.Result,
        phAsset: PHAsset?,
        location: CLLocation?
    ) {
        var didDismiss: Bool
        if pickerConfig.selectMode == .single &&
           config.finishSelectionAfterTakingPhoto {
            didDismiss = false
            PhotoManager.HUDView.show(with: nil, delay: 0, animated: true, addedTo: cameraController.view)
        }else {
            didDismiss = true
            cameraController.dismiss(animated: true)
        }
        PhotoManager.HUDView.show(with: nil, delay: 0, animated: true, addedTo: self.navigationController?.view)
        let pickerController = pickerController
        DispatchQueue.global().async {
            let saveType: AssetSaveUtil.SaveType
            let photoAsset: PhotoAsset
            switch result {
            case .image(let image):
                saveType = .image(image)
                photoAsset = .init(localImageAsset: .init(image: image))
            case .video(let videoURL):
                saveType = .videoURL(videoURL)
                let videoDuration = PhotoTools.getVideoDuration(videoURL: videoURL)
                photoAsset = .init(localVideoAsset: .init(videoURL: videoURL, duration: videoDuration))
            }
            var canSelect = true
            if !pickerController.pickerData.canSelect(
                photoAsset,
                isShowHUD: true,
                isFilterEditor: true
            ) {
                if !didDismiss {
                    DispatchQueue.main.async {
                        cameraController.dismiss(animated: true)
                    }
                    didDismiss = true
                }
                canSelect = false
            }
            if !didDismiss && !pickerController.autoDismiss {
                DispatchQueue.main.async {
                    cameraController.dismiss(animated: true)
                }
                didDismiss = true
            }
            if self.config.isSaveSystemAlbum {
                self.saveSystemAlbum(
                    type: saveType,
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
        guard pickerConfig.selectMode == .single,
              config.finishSelectionAfterTakingPhoto,
              canSelect else {
            return
        }
        if pickerController.autoDismiss {
            presentingViewController?.dismiss(animated: true)
        }
    }
}
#endif
