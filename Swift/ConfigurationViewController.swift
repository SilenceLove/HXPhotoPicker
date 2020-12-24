//
//  ConfigurationViewController.swift
//  HXPHPickerExample
//
//  Created by Slience on 2020/12/23.
//  Copyright © 2020 Slience. All rights reserved.
//

import UIKit

protocol ConfigurationViewControllerDelegate: NSObjectProtocol {
    func ConfigurationViewControllerDidSave(_ config: HXPHConfiguration)
}

class ConfigurationViewController: UIViewController, UIScrollViewDelegate {
    weak var delegate: ConfigurationViewControllerDelegate?
    
    @IBOutlet weak var topMarginConstraint: NSLayoutConstraint!
    @IBOutlet weak var languageControl: UISegmentedControl!
    @IBOutlet weak var selectTypeControl: UISegmentedControl!
    @IBOutlet weak var selectModeControl: UISegmentedControl!
    @IBOutlet weak var albumShowModeControl: UISegmentedControl!
    @IBOutlet weak var appearanceStyleControl: UISegmentedControl!
    @IBOutlet weak var allowTogetherSelectedSwitch: UISwitch!
    @IBOutlet weak var allowLoadPhotoLibrarySwitch: UISwitch!
    @IBOutlet weak var createdDateSwitch: UISwitch!
    @IBOutlet weak var sortControl: UISegmentedControl!
    @IBOutlet weak var photoListAddCameraSwitch: UISwitch!
    @IBOutlet weak var showGifControl: UISwitch!
    @IBOutlet weak var showLivePhotoSwitch: UISwitch!
    @IBOutlet weak var photoMaxField: UITextField!
    @IBOutlet weak var videoMaxField: UITextField!
    @IBOutlet weak var totalMaxField: UITextField!
    @IBOutlet weak var videoMinDurationField: UITextField!
    @IBOutlet weak var videoMaxDurationField: UITextField!
    @IBOutlet weak var photoMaxFileSizeField: UITextField!
    @IBOutlet weak var videoMaxFileSizeField: UITextField!
    
    var config: HXPHConfiguration
    
    init(config: HXPHConfiguration) {
        self.config = config
        super.init(nibName:"ConfigurationViewController",bundle: nil)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        languageControl.selectedSegmentIndex = config.languageType.rawValue
        selectTypeControl.selectedSegmentIndex = config.selectType.rawValue
        selectModeControl.selectedSegmentIndex = config.selectMode.rawValue
        albumShowModeControl.selectedSegmentIndex = config.albumShowMode.rawValue
        appearanceStyleControl.selectedSegmentIndex = config.appearanceStyle.rawValue
        allowTogetherSelectedSwitch.isOn = config.allowSelectedTogether
        allowLoadPhotoLibrarySwitch.isOn = config.allowLoadPhotoLibrary
        createdDateSwitch.isOn = config.creationDate
        sortControl.selectedSegmentIndex = config.reverseOrder ? 1 : 0
        photoListAddCameraSwitch.isOn = config.photoList.allowAddCamera
        showGifControl.isOn = config.showImageAnimated
        showLivePhotoSwitch.isOn = config.showLivePhoto
        photoMaxField.text = String(config.maximumSelectedPhotoCount)
        videoMaxField.text = String(config.maximumSelectedVideoCount)
        totalMaxField.text = String(config.maximumSelectedCount)
        videoMinDurationField.text = String(config.minimumSelectedVideoDuration)
        videoMaxDurationField.text = String(config.maximumSelectedVideoDuration)
        photoMaxFileSizeField.text = String(config.maximumSelectedPhotoFileSize)
        videoMaxFileSizeField.text = String(config.maximumSelectedVideoFileSize)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem.init(title: "取消", style: .done, target: self, action: #selector(didCancelButtonClick))
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: "保存", style: .done, target: self, action: #selector(didSaveButtonClick))
        if let nav = navigationController {
            if nav.modalPresentationStyle == .fullScreen {
                topMarginConstraint.constant = UIDevice.current.hx_navigationBarHeight + 5
            }else {
                topMarginConstraint.constant = nav.navigationBar.hx_height + 5
            }
        }
    }
    @objc func didCancelButtonClick() {
        dismiss(animated: true, completion: nil)
    }
    @objc func didSaveButtonClick() {
        config.languageType = HXPHPicker.LanguageType.init(rawValue: languageControl.selectedSegmentIndex)!
        config.selectType = HXPHPicker.SelectType.init(rawValue: selectTypeControl.selectedSegmentIndex)!
        config.selectMode = HXPHPicker.SelectMode.init(rawValue: selectModeControl.selectedSegmentIndex)!
        config.albumShowMode = HXPHPicker.Album.ShowMode.init(rawValue: albumShowModeControl.selectedSegmentIndex)!
        config.appearanceStyle = HXPHPicker.AppearanceStyle.init(rawValue: appearanceStyleControl.selectedSegmentIndex)!
        config.allowSelectedTogether = allowTogetherSelectedSwitch.isOn
        config.allowLoadPhotoLibrary = allowLoadPhotoLibrarySwitch.isOn
        config.creationDate = createdDateSwitch.isOn
        config.reverseOrder = sortControl.selectedSegmentIndex == 1
        config.photoList.allowAddCamera = photoListAddCameraSwitch.isOn
        config.showImageAnimated = showGifControl.isOn
        config.showLivePhoto = showLivePhotoSwitch.isOn
        
        config.maximumSelectedPhotoCount = Int(photoMaxField.text ?? "0") ?? 0
        config.maximumSelectedVideoCount = Int(videoMaxField.text ?? "0") ?? 0
        config.maximumSelectedCount = Int(totalMaxField.text ?? "0") ?? 0
        config.minimumSelectedVideoDuration = Int(videoMinDurationField.text ?? "0") ?? 0
        config.maximumSelectedVideoDuration = Int(videoMaxDurationField.text ?? "0") ?? 0
        config.maximumSelectedPhotoFileSize = Int(photoMaxFileSizeField.text ?? "0") ?? 0
        config.maximumSelectedVideoFileSize = Int(videoMaxFileSizeField.text ?? "0") ?? 0
        
        delegate?.ConfigurationViewControllerDidSave(config)
        dismiss(animated: true, completion: nil)
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        view.endEditing(true)
    }
    required init?(coder aDecoder: NSCoder) {
        self.config = HXPHConfiguration.init()
        super.init(coder: aDecoder)
    }
}
