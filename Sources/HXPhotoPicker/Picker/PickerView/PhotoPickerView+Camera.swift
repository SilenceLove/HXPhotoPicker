//
//  PhotoPickerView+Camera.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/9/17.
//

import UIKit
import MobileCoreServices
import AVFoundation
import Photos

extension PhotoPickerView: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func presentCameraViewController() {
        #if HXPICKER_ENABLE_CAMERA && !targetEnvironment(macCatalyst)
        switch config.cameraType {
        case .custom(var camerConfig):
            let type: CameraController.CaptureType
            if manager.config.selectOptions.isPhoto &&
                manager.config.selectOptions.isVideo {
                type = .all
            }else if manager.config.selectOptions.isPhoto {
                type = .photo
            }else {
                type = .video
            }
            camerConfig.languageType = manager.config.languageType
            let vc = CameraController(
                config: camerConfig,
                type: type,
                delegate: self
            )
            vc.autoDismiss = false
            viewController?.present(vc, animated: true)
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
            if manager.config.selectOptions.isPhoto {
                mediaTypes.append(kUTTypeImage as String)
            }
            if manager.config.selectOptions.isVideo {
                mediaTypes.append(kUTTypeMovie as String)
            }
        }
        imagePickerController.mediaTypes = mediaTypes
        viewController?.present(imagePickerController, animated: true)
    }
    
    public func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        ProgressHUD.showLoading(
            addedTo: self,
            animated: true
        )
        picker.dismiss(animated: true)
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
        if let editedImage = info[.editedImage] as? UIImage {
            image = editedImage
        }else {
            image = info[.originalImage] as? UIImage
        }
        image = image?.scaleSuitableSize()
        if let image = image {
            if config.isSaveSystemAlbum {
                saveSystemAlbum(type: .image(image))
                return
            }
            addedCameraPhotoAsset(PhotoAsset(
                localImageAsset: .init(image: image)
            ))
            return
        }
        DispatchQueue.main.async {
            ProgressHUD.hide(
                forView: self,
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
                    forView: self,
                    animated: false
                )
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
        ProgressHUD.hide(forView: self, animated: false)
        ProgressHUD.showWarning(
            addedTo: self,
            text: .textPhotoList.videoExportFailedHudTitle.text,
            animated: true,
            delayHide: 1.5
        )
    }
    func saveSystemAlbum(
        type: AssetManager.PhotoSaveType,
        location: CLLocation? = nil
    ) {
        AssetManager.save(
            type: type,
            customAlbumName: config.customAlbumName,
            location: location
        ) {
            switch $0 {
            case .success(let phAsset):
                self.addedCameraPhotoAsset(PhotoAsset(asset: phAsset))
            case .failure:
                DispatchQueue.main.async {
                    ProgressHUD.hide(
                        forView: self,
                        animated: true
                    )
                    ProgressHUD.showWarning(
                        addedTo: self,
                        text: .textPhotoList.saveSystemAlbumFailedHudTitle.text,
                        animated: true,
                        delayHide: 1.5
                    )
                }
            }
        }
    }
    func addedCameraPhotoAsset(
        _ photoAsset: PhotoAsset
    ) {
        DispatchQueue.main.async {
            ProgressHUD.hide(forView: self, animated: true)
            if self.config.takePictureCompletionToSelected {
                if self.manager.config.selectMode == .multiple &&
                    (photoAsset.mediaType == .photo ||
                        (photoAsset.mediaType == .video &&
                            !self.videoLoadSingleCell
                        )
                    ) {
                    if self.manager.addedPhotoAsset(photoAsset: photoAsset) {
                        self.updateCellSelectedTitle()
                    }
                }
            }
            if photoAsset.isLocalAsset {
                self.manager.addedLocalCameraAsset(photoAsset: photoAsset)
            }
            self.addedPhotoAsset(for: photoAsset)
            self.setupEmptyView()
        }
    }
}

#if HXPICKER_ENABLE_CAMERA && !targetEnvironment(macCatalyst)
extension PhotoPickerView: CameraControllerDelegate {
    public func cameraController(
        _ cameraController: CameraController,
        didFinishWithResult result: CameraController.Result,
        location: CLLocation?
    ) {
        cameraController.dismiss(animated: true)
        ProgressHUD.showLoading(
            addedTo: self,
            animated: true
        )
        DispatchQueue.global().async {
            let saveType: AssetManager.PhotoSaveType
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
            if self.config.isSaveSystemAlbum {
                self.saveSystemAlbum(
                    type: saveType,
                    location: location
                )
                return
            }
            self.addedCameraPhotoAsset(
                photoAsset
            )
        }
    }
}
#endif
