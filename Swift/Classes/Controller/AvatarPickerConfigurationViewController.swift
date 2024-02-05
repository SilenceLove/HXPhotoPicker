//
//  AvatarPickerConfigurationViewController.swift
//  Example
//
//  Created by Slience on 2021/5/19.
//

import UIKit
import HXPhotoPicker

class AvatarPickerConfigurationViewController: UITableViewController {
    var config: PickerConfiguration = .init()
     
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Avatar Picker"
        config.selectMode = .single
        config.selectOptions = .photo
        config.photoList.finishSelectionAfterTakingPhoto = true
        config.photoSelectionTapAction = .openEditor
        config.editor.isFixedCropSizeState = true
        config.editor.cropSize.isRoundCrop = true
        config.editor.cropSize.aspectRatios = []
        config.editor.cropSize.isFixedRatio = true
        config.editor.cropSize.isResetToOriginal = false
        
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.register(ConfigurationViewCell.self, forCellReuseIdentifier: ConfigurationViewCell.reuseIdentifier)
        tableView.tableFooterView = UIView(frame: .zero)
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "打开选择器",
            style: .done,
            target: self,
            action: #selector(openPickerController)
        )
    }
    
    @objc func openPickerController() {
        #if !targetEnvironment(macCatalyst)
        if #available(iOS 14.0, *), ProcessInfo.processInfo.isiOSAppOnMac {
    
        }else {
            var cameraConfig = CameraConfiguration()
            cameraConfig.editor.isFixedCropSizeState = config.editor.isFixedCropSizeState
            cameraConfig.editor.cropSize.isRoundCrop = config.editor.cropSize.isRoundCrop
            cameraConfig.editor.cropSize.aspectRatios = config.editor.cropSize.aspectRatios
            cameraConfig.editor.cropSize.isFixedRatio = config.editor.cropSize.isFixedRatio
            cameraConfig.editor.cropSize.isResetToOriginal = config.editor.cropSize.isResetToOriginal
            config.photoList.cameraType = .custom(cameraConfig)
        }
        #endif
        if UIDevice.isPad {
            let picker = PhotoPickerController(splitPicker: config)
            picker.pickerDelegate = self
            picker.autoDismiss = false
            let split = PhotoSplitViewController(picker: picker)
            present(split, animated: true, completion: nil)
        }else {
            let vc = PhotoPickerController.init(config: config)
            vc.pickerDelegate = self
            vc.autoDismiss = false
            present(vc, animated: true, completion: nil)
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return AvatarPickerSection.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return AvatarPickerSection.allCases[section].allRowCase.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ConfigurationViewCell.reuseIdentifier,
            for: indexPath
        ) as! ConfigurationViewCell
        let rowType = AvatarPickerSection.allCases[indexPath.section].allRowCase[indexPath.row]
        cell.setupData(rowType, getRowContent(rowType))
        return cell
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        54
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let rowType = AvatarPickerSection.allCases[indexPath.section].allRowCase[indexPath.row]
        rowType.getFunction(self)(indexPath)
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return AvatarPickerSection.allCases[section].title
    }
}
extension AvatarPickerConfigurationViewController: PhotoPickerControllerDelegate {
    func pickerController(_ pickerController: PhotoPickerController, didFinishSelection result: PickerResult) {
        pickerController.dismiss(true) {
            let pickerResultVC = PickerResultViewController.init()
            pickerResultVC.config = pickerController.config
            pickerResultVC.selectedAssets = result.photoAssets
            pickerResultVC.isOriginal = result.isOriginal
            self.navigationController?.pushViewController(pickerResultVC, animated: true)
        }
    }
    func pickerController(didCancel pickerController: PhotoPickerController) {
        pickerController.dismiss(animated: true, completion: nil)
    }
}
extension AvatarPickerConfigurationViewController {
    func getRowContent(_ rowType: ConfigRowTypeRule) -> String {
        if let rowType = rowType as? PickerOptionsRow {
            switch rowType {
            case .selectOptions:
                return config.selectOptions.title
            case .selectMode:
                return config.selectMode.title
            case .albumShowMode:
                return config.albumShowMode.title
            case .photoSelectionTapAction:
                return config.photoSelectionTapAction.title
            }
        }
        if let rowType = rowType as? PhotoEditorRow {
            switch rowType {
            case .isFixedCropSizeState:
                return config.editor.isFixedCropSizeState ? "true" : "false"
            case .isRoundCrop:
                return config.editor.cropSize.isRoundCrop ? "true" : "false"
            case .isFixedRatio:
                return config.editor.cropSize.isFixedRatio ? "true" : "false"
            case .aspectRatioType:
                return config.editor.cropSize.aspectRatio.title
            case .aspectRatios:
                return config.editor.cropSize.aspectRatios.isEmpty ? "true": "false"
            case .defaultSeletedIndex:
                return String(config.editor.cropSize.defaultSeletedIndex)
            case .maskType:
                switch config.editor.cropSize.maskType {
                case .blurEffect(_):
                    return "blurEffect"
                case .customColor(_):
                    return "Color"
                }
            }
        }
        return ""
    }
    
    func selectOptionsAction(_ indexPath: IndexPath) {
        let alert = UIAlertController.init(title: "selectOptions", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "photo", style: .default, handler: { [weak self] (action) in
            guard let self = self else { return }
            self.config.selectOptions = .photo
            self.tableView.reloadRows(at: [indexPath], with: .fade)
        }))
        alert.addAction(UIAlertAction.init(title: "gif+photo", style: .default, handler: { [weak self] (action) in
            guard let self = self else { return }
            self.config.selectOptions = [.gifPhoto]
            self.tableView.reloadRows(at: [indexPath], with: .fade)
        }))
        alert.addAction(UIAlertAction.init(title: "livePhoto+photo", style: .default, handler: { [weak self] (action) in
            guard let self = self else { return }
            self.config.selectOptions = [.livePhoto]
            self.tableView.reloadRows(at: [indexPath], with: .fade)
        }))
        alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: nil))
        presendAlert(alert)
    }
    func selectModeAction(_ indexPath: IndexPath) {
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
    func albumShowModeAction(_ indexPath: IndexPath) {
        let alert = UIAlertController.init(title: "albumShowMode", message: nil, preferredStyle: .alert)
        let titles = ["normal", "popup", "present"]
        for title in titles {
            alert.addAction(UIAlertAction.init(title: title, style: .default, handler: { [weak self] (action) in
                guard let self = self else { return }
                let index = titles.firstIndex(of: action.title!)!
                if index == 0 {
                    self.config.albumShowMode = .normal
                }else if index == 1 {
                    self.config.albumShowMode = .popup
                }else {
                    if #available(iOS 13.0, *) {
                        self.config.albumShowMode = .present(.automatic)
                    } else {
                        self.config.albumShowMode = .present(.fullScreen)
                    }
                }
                self.tableView.reloadRows(at: [indexPath], with: .fade)
            }))
        }
        alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: nil))
        presendAlert(alert)
    }
    func photoSelectionTapAction(_ indexPath: IndexPath) {
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
    func fixedCropStateAction(_ indexPath: IndexPath) {
        config.editor.isFixedCropSizeState = !config.editor.isFixedCropSizeState
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
    func isRoundCropAction(_ indexPath: IndexPath) {
        config.editor.cropSize.isRoundCrop = !config.editor.cropSize.isRoundCrop
        config.editor.cropSize.isResetToOriginal = config.editor.cropSize.isRoundCrop
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
    func fixedRatioAction(_ indexPath: IndexPath) {
        config.editor.cropSize.isFixedRatio = !config.editor.cropSize.isFixedRatio
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
    func aspectRatioTypeAction(_ indexPath: IndexPath) {
        let alert = UIAlertController.init(title: "aspectRatioTypeAction", message: nil, preferredStyle: .alert)
        alert.addTextField { (textfield) in
            textfield.keyboardType = .numberPad
            textfield.placeholder = "输入宽度比"
        }
        alert.addTextField { (textfield) in
            textfield.keyboardType = .numberPad
            textfield.placeholder = "输入高度比"
        }
        alert.addAction(UIAlertAction.init(title: "确定", style: .default, handler: { [weak self] (action) in
            guard let self = self else { return }
            let widthTextFiled = alert.textFields?.first
            let widthRatioStr = widthTextFiled?.text ?? "0"
            let widthRatio = Int(widthRatioStr.count == 0 ? "0" : widthRatioStr)!
            let heightTextFiled = alert.textFields?.last
            let heightRatioStr = heightTextFiled?.text ?? "0"
            let heightRatio = Int(heightRatioStr.count == 0 ? "0" : heightRatioStr)!
            self.config.editor.cropSize.aspectRatio = CGSize(width: widthRatio, height: heightRatio)
            self.config.editor.cropSize.defaultSeletedIndex = 0
            self.tableView.reloadData()
        }))
        alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: nil))
        presendAlert(alert)
    }
    func aspectRatiosAction(_ indexPath: IndexPath) {
        if config.editor.cropSize.aspectRatios.isEmpty {
            config.editor.cropSize.aspectRatios = [
                .init(title: .localized("自由格式"), ratio: .init(width: 0, height: 0)),
                .init(title: .localized("正方形"), ratio: .init(width: 1, height: 1)),
                .init(title: .localized("3:2"), ratio: .init(width: 3, height: 2)),
                .init(title: .localized("2:3"), ratio: .init(width: 2, height: 3)),
                .init(title: .localized("4:3"), ratio: .init(width: 4, height: 3)),
                .init(title: .localized("3:4"), ratio: .init(width: 3, height: 4)),
                .init(title: .localized("16:9"), ratio: .init(width: 16, height: 9)),
                .init(title: .localized("9:16"), ratio: .init(width: 9, height: 16))
            ]
        }else {
            config.editor.cropSize.aspectRatios = []
        }
        config.editor.cropSize.aspectRatio = .zero
        config.editor.cropSize.defaultSeletedIndex = 0
        tableView.reloadData()
    }
    func defaultSeletedIndexAction(_ indexPath: IndexPath) {
        let alert = UIAlertController.init(title: "defaultSeletedIndexAction", message: nil, preferredStyle: .alert)
        alert.addTextField { (textfield) in
            textfield.keyboardType = .numberPad
            textfield.placeholder = "请输入默认下标"
        }
        alert.addAction(
            UIAlertAction(
                title: "确定",
                style: .default,
                handler: { [weak self] (action) in
                    guard let self = self else { return }
            let textFiled = alert.textFields?.first
            let str = textFiled?.text ?? "0"
            let index = Int(str.count == 0 ? "0" : str)!
            if self.config.editor.cropSize.aspectRatios.isEmpty {
                self.config.editor.cropSize.defaultSeletedIndex = 0
                self.config.editor.cropSize.isFixedRatio = false
            }else {
                self.config.editor.cropSize.defaultSeletedIndex = index
                self.config.editor.cropSize.isFixedRatio = index != 0
                
                let aspectRatio = self.config.editor.cropSize.aspectRatios[index]
                self.config.editor.cropSize.aspectRatio = aspectRatio.ratio
            }
            self.tableView.reloadData()
        }))
        alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: nil))
        presendAlert(alert)
    }
    func maskTypeAction(_ indexPath: IndexPath) {
        let alert = UIAlertController.init(title: "maskTypeAction", message: nil, preferredStyle: .alert)
        let titles = ["blackColor", "darkBlurEffect", "lightBlurEffect"]
        for title in titles {
            alert.addAction(UIAlertAction.init(title: title, style: .default, handler: { [weak self] (action) in
                guard let self = self else { return }
                let index = titles.firstIndex(of: action.title!)!
                switch index {
                case 0:
                    self.config.editor.cropSize.maskType = .customColor(color: .black)
                case 1:
                    self.config.editor.cropSize.maskType = .blurEffect(style: .dark)
                case 2:
                    self.config.editor.cropSize.maskType = .blurEffect(style: .light)
                default:
                    break
                }
                self.tableView.reloadRows(at: [indexPath], with: .fade)
            }))
        }
        alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: nil))
        presendAlert(alert)
    }
}
extension AvatarPickerConfigurationViewController {
    enum AvatarPickerSection: Int, CaseIterable {
        case pickerOptions
        case photoEditOptions
        var title: String {
            switch self {
            case .pickerOptions:
                 return "pickerOptions"
            case .photoEditOptions:
                 return "photoEditOptions"
            }
        }
        var allRowCase: [ConfigRowTypeRule] {
            switch self {
            case .pickerOptions:
                return PickerOptionsRow.allCases
            case .photoEditOptions:
                return PhotoEditorRow.allCases
            }
        }
    }
    enum PickerOptionsRow: String, CaseIterable, ConfigRowTypeRule {
        case selectOptions
        case selectMode
        case albumShowMode
        case photoSelectionTapAction
        
        var title: String {
            switch self {
            case .selectOptions:
                return "资源类型"
            case .selectMode:
                return "选择模式"
            case .albumShowMode:
                return "相册展示模式"
            case .photoSelectionTapAction:
                return "列表照片Cell点击动作"
            }
        }
        var detailTitle: String {
            return "." + self.rawValue
        }
        func getFunction<T>(
            _ controller: T
        ) -> ((IndexPath) -> Void) where T: UIViewController {
            guard let controller = controller as? AvatarPickerConfigurationViewController else {
                return { _ in }
            }
            switch self {
            case .selectOptions:
                return controller.selectOptionsAction(_:)
            case .selectMode:
                return controller.selectModeAction(_:)
            case .albumShowMode:
                return controller.albumShowModeAction(_:)
            case .photoSelectionTapAction:
                return controller.photoSelectionTapAction(_:)
            }
        }
    }
    enum PhotoEditorRow: String, CaseIterable, ConfigRowTypeRule {
        case isFixedCropSizeState
        case isRoundCrop
        case isFixedRatio
        case aspectRatioType
        case aspectRatios
        case defaultSeletedIndex
        case maskType
        var title: String {
            switch self {
            case .isFixedCropSizeState:
                return "固定裁剪状态"
            case .isRoundCrop:
                return "圆形裁剪框"
            case .isFixedRatio:
                return "固定比例"
            case .aspectRatioType:
                return "默认宽高比"
            case .defaultSeletedIndex:
                return "宽高比数组默认下标"
            case .aspectRatios:
                return "清空宽高比数组"
            case .maskType:
                return "裁剪时遮罩类型"
            }
        }
        var detailTitle: String {
            if self == .isFixedCropSizeState {
                return "." + rawValue
            }
            return ".cropSize." + rawValue
        }
        func getFunction<T>(
            _ controller: T
        ) -> ((IndexPath) -> Void) where T: UIViewController {
            guard let controller = controller as? AvatarPickerConfigurationViewController else {
                return { _ in }
            }
            switch self {
            case .isFixedCropSizeState:
                return controller.fixedCropStateAction(_:)
            case .isRoundCrop:
                return controller.isRoundCropAction(_:)
            case .isFixedRatio:
                return controller.fixedRatioAction(_:)
            case .aspectRatioType:
                return controller.aspectRatioTypeAction(_:)
            case .defaultSeletedIndex:
                return controller.defaultSeletedIndexAction(_:)
            case .aspectRatios:
                return controller.aspectRatiosAction(_:)
            case .maskType:
                return controller.maskTypeAction(_:)
            }
        }
    }
}
