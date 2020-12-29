//
//  HXPHPickerCamerViewCell.swift
//  HXPHPickerExample
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit
import AVKit

class HXPHPickerCamerViewCell: UICollectionViewCell {
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    var previewLayer: AVCaptureVideoPreviewLayer?
    var startSeesionCompletion: Bool = false
    lazy var imageView: UIImageView = {
        let imageView = UIImageView.init()
        return imageView
    }()
    
    var config: HXPHPhotoListCameraCellConfiguration? {
        didSet {
            configProperty()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        previewLayer = layer as? AVCaptureVideoPreviewLayer
        previewLayer?.videoGravity = .resizeAspectFill
        contentView.addSubview(imageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func configProperty() {
        imageView.image = UIImage.hx_named(named: HXPHManager.shared.isDark ? config?.cameraDarkImageName : config?.cameraImageName)
        backgroundColor = HXPHManager.shared.isDark ? config?.backgroundDarkColor : config?.backgroundColor
        imageView.hx_size = imageView.image?.size ?? .zero
        if let allowPreview = config?.allowPreview, allowPreview == true {
            requestCameraAccess()
        }
    }
    func requestCameraAccess() {
        if startSeesionCompletion {
            return
        }
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
//            HXPHProgressHUD.showWarningHUD(addedTo: hx_viewController()?.view, text: "相机不可用!".hx_localized, animated: true, delay: 1.5)
            return
        }
        HXPHAssetManager.requestCameraAccess { (granted) in
            if granted {
                self.startSeesion()
            }else {
                HXPHTools.showNotCameraAuthorizedAlert(viewController: self.hx_viewController())
            }
        }
    }
    func startSeesion() {
        self.startSeesionCompletion = true
        DispatchQueue.global().async {
            let session = AVCaptureSession.init()
            session.beginConfiguration()
            if session.canSetSessionPreset(AVCaptureSession.Preset.high) {
                session.sessionPreset = .high
            }
            if let videoDevice = AVCaptureDevice.default(for: .video) {
                do {
                    let videoInput = try AVCaptureDeviceInput.init(device: videoDevice)
                    session.addInput(videoInput)
                    session.commitConfiguration()
                    session.startRunning()
                    self.previewLayer?.session = session
                }catch {}
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.center = CGPoint(x: hx_width * 0.5, y: hx_height * 0.5)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                configProperty()
            }
        }
    }
}
