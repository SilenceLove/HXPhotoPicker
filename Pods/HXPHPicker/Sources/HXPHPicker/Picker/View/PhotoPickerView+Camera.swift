//
//  PhotoPickerView+Camera.swift
//  HXPHPicker
//
//  Created by Slience on 2021/9/17.
//

import UIKit
import MobileCoreServices
import AVFoundation
import Photos

extension PhotoPickerView: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func presentCameraViewController() {
        #if HXPICKER_ENABLE_CAMERA
        switch config.cameraType {
        case .custom(let camerConfig):
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
            camerConfig.appearanceStyle = manager.config.appearanceStyle
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
        ProgressHUD.hide(forView: self, animated: false)
        ProgressHUD.showWarning(
            addedTo: self,
            text: "视频导出失败".localized,
            animated: true,
            delayHide: 1.5
        )
    }
    func saveSystemAlbum(
        for asset: Any,
        mediaType: PHAssetMediaType,
        location: CLLocation? = nil) {
        AssetManager.saveSystemAlbum(
            forAsset: asset,
            mediaType: mediaType,
            customAlbumName: config.customAlbumName,
            location: location
        ) { (phAsset) in
            if let phAsset = phAsset {
                self.addedCameraPhotoAsset(PhotoAsset(asset: phAsset))
            }else {
                DispatchQueue.main.async {
                    ProgressHUD.hide(
                        forView: self,
                        animated: true
                    )
                    ProgressHUD.showWarning(
                        addedTo: self,
                        text: "保存失败".localized,
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

#if HXPICKER_ENABLE_CAMERA
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
            if self.config.saveSystemAlbum {
                self.saveSystemAlbum(
                    for: asset,
                    mediaType: mediaType,
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
