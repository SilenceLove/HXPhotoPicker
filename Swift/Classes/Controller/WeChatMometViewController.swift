//
//  WeChatMometViewController.swift
//  Example
//
//  Created by Slience on 2021/7/28.
//

import UIKit
import HXPHPicker

class WeChatMometViewController: UIViewController {
    var isImage = false
    lazy var imageView: UIImageView = {
        let view = UIImageView(image: .init(named: "wx_head_icon"))
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didImageViewClick)))
        view.backgroundColor = .systemYellow
        return view
    }()
    @objc func didImageViewClick() {
        isImage = true
        let config = PhotoTools.getWXPickerConfig(isMoment: true)
        config.selectOptions = .photo
        config.selectMode = .single
        config.photoSelectionTapAction = .openEditor
        config.photoList.finishSelectionAfterTakingPhoto = true
        config.photoEditor.cropping.aspectRatioType = .ratio_1x1
        config.photoEditor.cropping.fixedRatio = true
        config.photoEditor.fixedCropState = true
        
        config.photoList.cameraType.customConfig?.photoEditor.cropping.aspectRatioType = .ratio_1x1
        config.photoList.cameraType.customConfig?.photoEditor.cropping.fixedRatio = true
        config.photoList.cameraType.customConfig?.photoEditor.fixedCropState = true
        
        presentPicker(config)
    }
    var localCachePath: String {
        var cachePath = PhotoTools.getSystemCacheFolderPath()
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
        let config = PhotoTools.getWXPickerConfig(
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
            picker.dismiss(animated: true)
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
