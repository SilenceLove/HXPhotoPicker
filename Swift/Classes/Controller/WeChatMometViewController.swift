//
//  WeChatMometViewController.swift
//  Example
//
//  Created by Slience on 2021/7/28.
//

import UIKit
import HXPhotoPicker

class WeChatMometViewController: UIViewController {
    var isImage = false
    lazy var imageView: UIImageView = {
        let view = UIImageView(image: .init(named: "wx_bg_image"))
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didImageViewClick)))
        view.backgroundColor = .systemYellow
        return view
    }()
    @objc func didImageViewClick() {
        isImage = true
        var config = PhotoTools.getWXPickerConfig(isMoment: true)
        config.selectOptions = .photo
        config.selectMode = .single
        config.photoSelectionTapAction = .openEditor
        config.photoList.finishSelectionAfterTakingPhoto = true
        config.editor.cropSize.aspectRatio = .init(width: 1, height: 1)
        config.editor.cropSize.isFixedRatio = true
        config.editor.cropSize.aspectRatios = []
        config.editor.cropSize.isResetToOriginal = false
        config.editor.isFixedCropSizeState = true
        #if !targetEnvironment(macCatalyst)
        if #available(iOS 14.0, *), ProcessInfo.processInfo.isiOSAppOnMac {
            
        }else {
            var cameraConfig = CameraConfiguration()
            cameraConfig.editor.cropSize.aspectRatio = .init(width: 1, height: 1)
            cameraConfig.editor.cropSize.isFixedRatio = true
            cameraConfig.editor.cropSize.aspectRatios = []
            cameraConfig.editor.cropSize.isResetToOriginal = false
            cameraConfig.editor.isFixedCropSizeState = true
            config.photoList.cameraType = .custom(cameraConfig)
        }
        #endif
        
        presentPicker(config)
    }
    var localCachePath: String {
        var cachePath = HXPickerWrapper<FileManager>.cachesPath
        cachePath.append(contentsOf: "/com.silence.WeChat_Moment")
        return cachePath
    }
    var localURL: URL {
        var cachePath = localCachePath
        cachePath.append(contentsOf: "/PhotoAssets")
        return URL.init(fileURLWithPath: cachePath)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Moment"
        view.backgroundColor = .white
        view.addSubview(imageView)
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "camera_overturn"),
            style: .done,
            target: self,
            action: #selector(didPublishClick)
        )
    }
    
    @objc func didPublishClick() {
        isImage = false
        if FileManager.default.fileExists(atPath: localURL.path) {
            let vc = PickerResultViewController()
            vc.isPublish = true
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true, completion: nil)
            return
        }
        var config = PhotoTools.getWXPickerConfig(
            isMoment: true
        )
        config.maximumSelectedVideoDuration = 60
        presentPicker(config)
    }
    func presentPicker(_ config: PickerConfiguration) {
        let pickerController = Photo.picker(
            config
        ) { [weak self] result, picker in
            guard let self = self else { return }
            let completion: (() -> Void)?
            if self.isImage {
                self.imageView.image = result.photoAssets.first?.originalImage
                completion = nil
            }else {
                completion = {
                    let vc = PickerResultViewController()
                    vc.isPublish = true
                    vc.selectedAssets = result.photoAssets
                    vc.isOriginal = result.isOriginal
                    let nav = UINavigationController(rootViewController: vc)
                    nav.modalPresentationStyle = .fullScreen
                    self.present(nav, animated: true)
                }
            }
            picker.dismiss(animated: true, completion: completion)
        } cancel: { picker in
            picker.dismiss(true)
        }
        pickerController.autoDismiss = false
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        imageView.frame = CGRect(
            x: 0,
            y: navigationController?.navigationBar.frame.maxY ?? 0,
            width: view.hx.width,
            height: view.hx.width
        )
    }
}
