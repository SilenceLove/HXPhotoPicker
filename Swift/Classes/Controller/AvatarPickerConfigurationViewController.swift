//
//  AvatarPickerConfigurationViewController.swift
//  Example
//
//  Created by Slience on 2021/5/19.
//

import UIKit
import HXPHPicker

class AvatarPickerConfigurationViewController: UITableViewController {
    var config: PickerConfiguration = .init()
     
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Avatar Picker"
        config.selectMode = .single
        config.selectOptions = .photo
        config.photoList.finishSelectionAfterTakingPhoto = true
        config.photoSelectionTapAction = .openEditor
        config.photoEditor.fixedCropState = true
        config.photoEditor.cropping.isRoundCrop = true
        config.photoEditor.cropping.aspectRatioType = .ratio_1x1
        config.photoEditor.cropping.fixedRatio = true
        
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
        let aspectRatioType = config.photoEditor.cropping.aspectRatioType
        let fixedRatio = config.photoEditor.cropping.fixedRatio
        let fixedCropState = config.photoEditor.fixedCropState
        let isRoundCrop = config.photoEditor.cropping.isRoundCrop
        config.photoList.cameraType.customConfig?.photoEditor.cropping.aspectRatioType = aspectRatioType
        config.photoList.cameraType.customConfig?.photoEditor.cropping.fixedRatio = fixedRatio
        config.photoList.cameraType.customConfig?.photoEditor.fixedCropState = fixedCropState
        config.photoList.cameraType.customConfig?.photoEditor.cropping.isRoundCrop = isRoundCrop
        
        let vc = PhotoPickerController.init(config: config)
        vc.pickerDelegate = self
        vc.autoDismiss = false
        present(vc, animated: true, completion: nil)
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
        pickerController.dismiss(animated: true) {
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
            case .fixedCropState:
                return config.photoEditor.fixedCropState ? "true" : "false"
            case .isRoundCrop:
                return config.photoEditor.cropping.isRoundCrop ? "true" : "false"
            case .fixedRatio:
                return config.photoEditor.cropping.fixedRatio ? "true" : "false"
            case .aspectRatioType:
                return config.photoEditor.cropping.aspectRatioType.title
            case .maskType:
                switch config.photoEditor.cropping.maskType {
                case .blackColor:
                    return "blackColor"
                case .darkBlurEffect:
                    return "darkBlurEffect"
                case .lightBlurEffect:
                    return "lightBlurEffect"
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
        present(alert, animated: true, completion: nil)
    }
    func selectModeAction(_ indexPath: IndexPath) {
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
    func albumShowModeAction(_ indexPath: IndexPath) {
        let alert = UIAlertController.init(title: "albumShowMode", message: nil, preferredStyle: .alert)
        let titles = ["normal", "popup"]
        for title in titles {
            alert.addAction(UIAlertAction.init(title: title, style: .default, handler: { [weak self] (action) in
                guard let self = self else { return }
                self.config.albumShowMode = AlbumShowMode.init(rawValue: titles.firstIndex(of: action.title!)!)!
                self.tableView.reloadRows(at: [indexPath], with: .fade)
            }))
        }
        alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    func photoSelectionTapAction(_ indexPath: IndexPath) {
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
    func fixedCropStateAction(_ indexPath: IndexPath) {
        config.photoEditor.fixedCropState = !config.photoEditor.fixedCropState
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
    func isRoundCropAction(_ indexPath: IndexPath) {
        config.photoEditor.cropping.isRoundCrop = !config.photoEditor.cropping.isRoundCrop
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
    func fixedRatioAction(_ indexPath: IndexPath) {
        config.photoEditor.cropping.fixedRatio = !config.photoEditor.cropping.fixedRatio
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
            self.config.photoEditor.cropping.aspectRatioType = .custom(CGSize(width: widthRatio, height: heightRatio))
            self.tableView.reloadRows(at: [indexPath], with: .fade)
        }))
        alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
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
                    self.config.photoEditor.cropping.maskType = .blackColor
                case 1:
                    self.config.photoEditor.cropping.maskType = .darkBlurEffect
                case 2:
                    self.config.photoEditor.cropping.maskType = .lightBlurEffect
                default:
                    break
                }
                self.tableView.reloadRows(at: [indexPath], with: .fade)
            }))
        }
        alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
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
        case fixedCropState
        case isRoundCrop
        case fixedRatio
        case aspectRatioType
        case maskType
        var title: String {
            switch self {
            case .fixedCropState:
                return "固定裁剪状态"
            case .isRoundCrop:
                return "圆形裁剪框"
            case .fixedRatio:
                return "固定比例"
            case .aspectRatioType:
                return "默认宽高比"
            case .maskType:
                return "裁剪时遮罩类型"
            }
        }
        var detailTitle: String {
            if self == .fixedCropState {
                return "." + rawValue
            }
            return ".cropping." + rawValue
        }
        func getFunction<T>(
            _ controller: T
        ) -> ((IndexPath) -> Void) where T: UIViewController {
            guard let controller = controller as? AvatarPickerConfigurationViewController else {
                return { _ in }
            }
            switch self {
            case .fixedCropState:
                return controller.fixedCropStateAction(_:)
            case .isRoundCrop:
                return controller.isRoundCropAction(_:)
            case .fixedRatio:
                return controller.fixedRatioAction(_:)
            case .aspectRatioType:
                return controller.aspectRatioTypeAction(_:)
            case .maskType:
                return controller.maskTypeAction(_:)
            }
        }
    }
}

extension EditorCropSizeConfiguration.AspectRatioType {
    var title: String {
        switch self {
        case .ratio_1x1:
            return "1:1"
        case .ratio_2x3:
            return "2:3"
        case .ratio_3x2:
            return "3:2"
        case .ratio_3x4:
            return "3:4"
        case .ratio_4x3:
            return "4:3"
        case .ratio_9x16:
            return "9:16"
        case .ratio_16x9:
            return "16:9"
        case .custom(let ratio):
            if ratio.width == 0 || ratio.height == 0 {
                return "free"
            }
            return String(format: "%.0f:%.0f", ratio.width, ratio.height)
        default:
            return "free"
        }
    }
}
