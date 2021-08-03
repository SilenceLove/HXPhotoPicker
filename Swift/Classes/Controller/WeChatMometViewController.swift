//
//  WeChatMometViewController.swift
//  Example
//
//  Created by Slience on 2021/7/28.
//

import UIKit
import HXPHPicker

class WeChatMometViewController: UIViewController, PhotoPickerControllerDelegate {
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
        config.photoEditor.cropping.aspectRatioType = .ratio_1x1
        config.photoEditor.cropping.fixedRatio = true
        config.photoEditor.fixedCropState = true
        
        let pickerController = PhotoPickerController(
            picker: config,
            delegate: self
        )
        
        present(pickerController, animated: true, completion: nil)
    }
    
    func pickerController(_ pickerController: PhotoPickerController,
                          didFinishSelection result: PickerResult) {
        if isImage {
            imageView.image = result.photoAssets.first?.originalImage
        }else {
            pickerController.dismiss(animated: true) {
                let vc = PickerResultViewController()
                vc.isPublish = true
                vc.selectedAssets = result.photoAssets
                vc.isOriginal = result.isOriginal
                let nav = UINavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                self.present(nav, animated: true, completion: nil)
            }
        }
    }
    func pickerController(didCancel pickerController: PhotoPickerController) {
        pickerController.dismiss(animated: true, completion: nil)
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
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "camera_overturn"), style: .done, target: self, action: #selector(didPublishClick))
    }
    
    @objc func didPublishClick() {
        if FileManager.default.fileExists(atPath: localURL.path)  {
            let vc = PickerResultViewController()
            vc.isPublish = true
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            self.present(nav, animated: true, completion: nil)
            return
        }
        isImage = false
        let config = PhotoTools.getWXPickerConfig(isMoment: true)
        config.maximumSelectedVideoDuration = 60
        let pickerController = PhotoPickerController(picker: config, delegate: self)
        pickerController.autoDismiss = false
        present(pickerController, animated: true, completion: nil)
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        imageView.frame = CGRect(x: 0, y: navigationController?.navigationBar.frame.maxY ?? 0, width: view.width, height: view.width)
    }
}
