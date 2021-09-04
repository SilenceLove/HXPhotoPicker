//
//  PickerCamerViewCell.swift
//  HXPHPickerExample
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit
import AVKit

class PickerCamerViewCell: UICollectionViewCell {
    lazy var captureView: CaptureVideoPreviewView = {
        let view = CaptureVideoPreviewView(isCell: true)
        return view
    }()
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView.init()
        return imageView
    }()
    
    var config: PhotoListCameraCellConfiguration? {
        didSet {
            configProperty()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(captureView)
        contentView.addSubview(imageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func configProperty() {
        let isCache = PhotoManager.shared.cameraPreviewImage != nil
        if (captureView.previewLayer?.session != nil || isCache) && canPreview() {
            imageView.image = UIImage.image(for: config?.cameraDarkImageName)
        }else {
            imageView.image = UIImage.image(
                for: PhotoManager.isDark ?
                    config?.cameraDarkImageName :
                    config?.cameraImageName
            )
        }
        backgroundColor = PhotoManager.isDark ? config?.backgroundDarkColor : config?.backgroundColor
        imageView.size = imageView.image?.size ?? .zero
        if let allowPreview = config?.allowPreview, allowPreview == true {
            requestCameraAccess()
        }
    }
    func canPreview() -> Bool {
        if !UIImagePickerController.isSourceTypeAvailable(.camera) ||
            AssetManager.cameraAuthorizationStatus() == .denied {
            return false
        }
        return true
    }
    func requestCameraAccess() {
        if !canPreview() {
            captureView.isHidden = true
            return
        }
        AssetManager.requestCameraAccess { (granted) in
            if granted {
                self.startSeesion()
            }else {
                PhotoTools.showNotCameraAuthorizedAlert(
                    viewController: self.viewController()
                )
            }
        }
    }
    func startSeesion() {
        captureView.startSession { [weak self] isFinished in
            if isFinished {
                self?.imageView.image = UIImage.image(
                    for: self?.config?.cameraDarkImageName
                )
            }
        }
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        captureView.frame = bounds
        imageView.center = CGPoint(x: width * 0.5, y: height * 0.5)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                configProperty()
            }
        }
    }
    deinit {
        captureView.stopSession()
    }
}
