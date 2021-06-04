//
//  EditorConfigurationViewController.swift
//  Example
//
//  Created by Slience on 2021/3/17.
//

import UIKit
import HXPHPicker
import AVFoundation

class EditorConfigurationViewController: UITableViewController {
    var photoConfig: PhotoEditorConfiguration = .init()
    var videoConfig: VideoEditorConfiguration = .init()
    var showOpenEditorButton: Bool = true
    let videoURL: URL = URL.init(fileURLWithPath: Bundle.main.path(forResource: "videoeditormatter", ofType: "MP4")!)
    
    var editorType = 0
    var assetType = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Editor"
        
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.register(ConfigurationViewCell.self, forCellReuseIdentifier: ConfigurationViewCell.reuseIdentifier)
        tableView.tableFooterView = UIView(frame: .zero)
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: showOpenEditorButton ? "打开编辑器" : "确定", style: .done, target: self, action: #selector(backClick))
    }
    
    @objc func backClick() {
        if showOpenEditorButton {
            if editorType == 0 {
                if assetType == 0 {
                    let image = UIImage.init(contentsOfFile: Bundle.main.path(forResource: "picker_example_image", ofType: ".JPG")!)!
                    let vc = EditorController.init(image: image, config: photoConfig)
                    vc.photoEditorDelegate = self
                    present(vc, animated: true, completion: nil)
                }else {
                    #if canImport(Kingfisher)
                    let networkURL = URL.init(string: "https://wx4.sinaimg.cn/large/a6a681ebgy1gojng2qw07g208c093qv6.gif")!
                    let vc = EditorController.init(networkImageURL: networkURL, config: photoConfig)
                    vc.photoEditorDelegate = self
                    present(vc, animated: true, completion: nil)
                    #else
                    let image = UIImage.init(contentsOfFile: Bundle.main.path(forResource: "picker_example_image", ofType: ".JPG")!)!
                    let vc = EditorController.init(image: image, config: photoConfig)
                    vc.photoEditorDelegate = self
                    present(vc, animated: true, completion: nil)
                    #endif
                }
            }else {
                if assetType == 0 {
                    let vc = EditorController.init(videoURL: videoURL, config: videoConfig)
                    vc.videoEditorDelegate = self
                    present(vc, animated: true, completion: nil)
                }else {
                    let networkURL = URL.init(string: "http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/picker_examle_video.mp4")!
                    let vc = EditorController.init(networkVideoURL: networkURL, config: videoConfig)
                    vc.videoEditorDelegate = self
                    present(vc, animated: true, completion: nil)
                }
            }
        }else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return showOpenEditorButton ? editorSection.allCases.count : editorSection.allCases.count - 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let index: Int
        if showOpenEditorButton {
            index = section
        }else {
            index = section + 1
        }
        return editorSection.allCases[index].allRowCase.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ConfigurationViewCell.reuseIdentifier, for: indexPath) as! ConfigurationViewCell
        let index: Int
        if showOpenEditorButton {
            index = indexPath.section
        }else {
            index = indexPath.section + 1
        }
        let rowType = editorSection.allCases[index].allRowCase[indexPath.row]
        cell.setupData(rowType, getRowContent(rowType))
        return cell
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        54
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let index: Int
        if showOpenEditorButton {
            index = indexPath.section
        }else {
            index = indexPath.section + 1
        }
        let rowType = editorSection.allCases[index].allRowCase[indexPath.row]
        rowType.getFunction(self)(indexPath)
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let index: Int
        if showOpenEditorButton {
            index = section
        }else {
            index = section + 1
        }
        return editorSection.allCases[index].title
    }
}
extension EditorConfigurationViewController: PhotoEditorViewControllerDelegate {
    func photoEditorViewController(_ photoEditorViewController: PhotoEditorViewController, didFinish result: PhotoEditResult) {
        let pickerResultVC = PickerResultViewController.init()
        let pickerConfig = PickerConfiguration.init()
        pickerConfig.photoEditor = photoConfig
        pickerResultVC.config = pickerConfig
        
        switch photoEditorViewController.assetType {
        case .local:
            var localImageAsset = LocalImageAsset.init(imageURL: result.editedImageURL)
            localImageAsset.image = result.editedImage
            let photoAsset = PhotoAsset.init(localImageAsset: localImageAsset)
            photoAsset.photoEdit = result
            pickerResultVC.selectedAssets = [photoAsset]
        #if canImport(Kingfisher)
        case .network:
            let url = photoEditorViewController.networkImageURL!
            let photoAsset = PhotoAsset.init(networkImageAsset: .init(thumbnailURL: url, originalURL: url))
            photoAsset.photoEdit = result
            pickerResultVC.selectedAssets = [photoAsset]
        #endif
        default:
            break
        }
        self.navigationController?.pushViewController(pickerResultVC, animated: true)
    }
    func photoEditorViewController(didFinishWithUnedited photoEditorViewController: PhotoEditorViewController) {
        let pickerResultVC = PickerResultViewController.init()
        let pickerConfig = PickerConfiguration.init()
        pickerConfig.photoEditor = photoConfig
        pickerResultVC.config = pickerConfig
        switch photoEditorViewController.assetType {
        case .local:
            let localImageAsset = LocalImageAsset.init(image: photoEditorViewController.image)
            let photoAsset = PhotoAsset.init(localImageAsset: localImageAsset)
            pickerResultVC.selectedAssets = [photoAsset]
        #if canImport(Kingfisher)
        case .network:
            let url = photoEditorViewController.networkImageURL!
            let photoAsset = PhotoAsset.init(networkImageAsset: .init(thumbnailURL: url, originalURL: url))
            pickerResultVC.selectedAssets = [photoAsset]
        #endif
        default:
            break
        }
        self.navigationController?.pushViewController(pickerResultVC, animated: true)
    }
}
extension EditorConfigurationViewController: VideoEditorViewControllerDelegate {
    func videoEditorViewController(_ videoEditorViewController: VideoEditorViewController, didFinish result: VideoEditResult) {
        let pickerResultVC = PickerResultViewController.init()
        let pickerConfig = PickerConfiguration.init()
        pickerConfig.videoEditor = videoConfig
        pickerResultVC.config = pickerConfig
        
        switch videoEditorViewController.assetType {
        case .local:
            let photoAsset = PhotoAsset.init(localVideoAsset: .init(videoURL: videoURL))
            photoAsset.videoEdit = result
            pickerResultVC.selectedAssets = [photoAsset]
        case .network:
            let photoAsset = PhotoAsset.init(networkVideoAsset: .init(videoURL: videoEditorViewController.networkVideoURL!))
            photoAsset.videoEdit = result
            pickerResultVC.selectedAssets = [photoAsset]
        default:
            break
        }
        self.navigationController?.pushViewController(pickerResultVC, animated: true)
    }
    func videoEditorViewController(didFinishWithUnedited videoEditorViewController: VideoEditorViewController) {
        let pickerResultVC = PickerResultViewController.init()
        let pickerConfig = PickerConfiguration.init()
        pickerConfig.videoEditor = videoConfig
        pickerResultVC.config = pickerConfig
        switch videoEditorViewController.assetType {
        case .local:
            let photoAsset = PhotoAsset.init(localVideoAsset: .init(videoURL: videoURL))
            pickerResultVC.selectedAssets = [photoAsset]
        case .network:
            let photoAsset = PhotoAsset.init(networkVideoAsset: .init(videoURL: videoEditorViewController.networkVideoURL!))
            pickerResultVC.selectedAssets = [photoAsset]
        default:
            break
        }
        self.navigationController?.pushViewController(pickerResultVC, animated: true)
    }
}
extension EditorConfigurationViewController {
    func getRowContent(_ rowType: ConfigRowTypeRule) -> String {
        if let rowType = rowType as? editorTypeRow {
            switch rowType {
            case .type:
                return editorType == 0 ? "photo" : "video"
            case .assetType:
                return assetType == 0 ? "本地" : "网络"
            }
        }
        if let rowType = rowType as? photoEditorRow {
            switch rowType {
            case .state:
                return photoConfig.state.title
            case .fixedCropState:
                return photoConfig.fixedCropState ? "true" : "false"
            case .isRoundCrop:
                return photoConfig.cropConfig.isRoundCrop ? "true" : "false"
            case .fixedRatio:
                return photoConfig.cropConfig.fixedRatio ? "true" : "false"
            case .aspectRatioType:
                return photoConfig.cropConfig.aspectRatioType.title
            case .maskType:
                switch photoConfig.cropConfig.maskType {
                case .blackColor:
                    return "blackColor"
                case .darkBlurEffect:
                    return "darkBlurEffect"
                case .lightBlurEffect:
                    return "lightBlurEffect"
                }
            }
        }
        if let rowType = rowType as? videoEditorRow {
            switch rowType {
            case .exportPresetName:
                switch videoConfig.exportPresetName {
                case AVAssetExportPresetLowQuality:
                    return "LowQuality"
                case AVAssetExportPresetMediumQuality:
                    return "MediumQuality"
                default:
                    return "HighestQuality"
                }
            case .defaultState:
                return videoConfig.defaultState.title
            case .mustBeTailored:
                return videoConfig.mustBeTailored ? "true" : "false"
            case .maximumVideoCroppingTime:
                return String(Int(videoConfig.cropping.maximumVideoCroppingTime))
            case .minimumVideoCroppingTime:
                return String(Int(videoConfig.cropping.minimumVideoCroppingTime))
            }
        }
        return ""
    }
    func editorTypeAction(_ indexPath: IndexPath) {
        editorType = editorType == 0 ? 1 : 0
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
    func assetTypeAction(_ indexPath: IndexPath) {
        assetType = assetType == 0 ? 1 : 0
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
    func stateAction(_ indexPath: IndexPath) {
        let alert = UIAlertController.init(title: "state", message: nil, preferredStyle: .alert)
        let titles = ["normal", "cropping"]
        for title in titles {
            alert.addAction(UIAlertAction.init(title: title, style: .default, handler: { (action) in
                let index = titles.firstIndex(of: action.title!)!
                switch index {
                case 0:
                    self.photoConfig.state = .normal
                case 1:
                    self.photoConfig.state = .cropping
                default:
                    break
                }
                self.tableView.reloadRows(at: [indexPath], with: .fade)
            }))
        }
        alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    func fixedCropStateAction(_ indexPath: IndexPath) {
        photoConfig.fixedCropState = !photoConfig.fixedCropState
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
    func isRoundCropAction(_ indexPath: IndexPath) {
        photoConfig.cropConfig.isRoundCrop = !photoConfig.cropConfig.isRoundCrop
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
    func fixedRatioAction(_ indexPath: IndexPath) {
        photoConfig.cropConfig.fixedRatio = !photoConfig.cropConfig.fixedRatio
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
        alert.addAction(UIAlertAction.init(title: "确定", style: .default, handler: { (action) in
            let widthTextFiled = alert.textFields?.first
            let widthRatioStr = widthTextFiled?.text ?? "0"
            let widthRatio = Int(widthRatioStr.count == 0 ? "0" : widthRatioStr)!
            let heightTextFiled = alert.textFields?.last
            let heightRatioStr = heightTextFiled?.text ?? "0"
            let heightRatio = Int(heightRatioStr.count == 0 ? "0" : heightRatioStr)!
            self.photoConfig.cropConfig.aspectRatioType = .custom(CGSize(width: widthRatio, height: heightRatio))
            self.tableView.reloadRows(at: [indexPath], with: .fade)
        }))
        alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    func maskTypeAction(_ indexPath: IndexPath) {
        let alert = UIAlertController.init(title: "maskTypeAction", message: nil, preferredStyle: .alert)
        let titles = ["blackColor", "darkBlurEffect", "lightBlurEffect"]
        for title in titles {
            alert.addAction(UIAlertAction.init(title: title, style: .default, handler: { (action) in
                let index = titles.firstIndex(of: action.title!)!
                switch index {
                case 0:
                    self.photoConfig.cropConfig.maskType = .blackColor
                case 1:
                    self.photoConfig.cropConfig.maskType = .darkBlurEffect
                case 2:
                    self.photoConfig.cropConfig.maskType = .lightBlurEffect
                default:
                    break
                }
                self.tableView.reloadRows(at: [indexPath], with: .fade)
            }))
        }
        alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    func exportPresetNameAction(_ indexPath: IndexPath) {
        let alert = UIAlertController.init(title: "exportPresetNameAction", message: nil, preferredStyle: .alert)
        let titles = ["lowQuality", "mediumQuality", "highestQuality"]
        for title in titles {
            alert.addAction(UIAlertAction.init(title: title, style: .default, handler: { (action) in
                let index = titles.firstIndex(of: action.title!)!
                switch index {
                case 0:
                    self.videoConfig.exportPresetName = AVAssetExportPresetLowQuality
                case 1:
                    self.videoConfig.exportPresetName = AVAssetExportPresetMediumQuality
                case 2:
                    self.videoConfig.exportPresetName = AVAssetExportPresetHighestQuality
                default:
                    break
                }
                self.tableView.reloadRows(at: [indexPath], with: .fade)
            }))
        }
        alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    func defaultStateAction(_ indexPath: IndexPath) {
        let alert = UIAlertController.init(title: "defaultState", message: nil, preferredStyle: .alert)
        let titles = ["normal", "cropping"]
        for title in titles {
            alert.addAction(UIAlertAction.init(title: title, style: .default, handler: { (action) in
                let index = titles.firstIndex(of: action.title!)!
                switch index {
                case 0:
                    self.videoConfig.defaultState = .normal
                case 1:
                    self.videoConfig.defaultState = .cropping
                default:
                    break
                }
                self.tableView.reloadRows(at: [indexPath], with: .fade)
            }))
        }
        alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    func mustBeTailoredAction(_ indexPath: IndexPath) {
        videoConfig.mustBeTailored = !videoConfig.mustBeTailored
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
    func maximumVideoCroppingTimeAction(_ indexPath: IndexPath) {
        let alert = UIAlertController.init(title: "maximumVideoCroppingTime", message: nil, preferredStyle: .alert)
        let maximumVideoCroppingTime: Int = Int(videoConfig.cropping.maximumVideoCroppingTime)
        alert.addTextField { (textfield) in
            textfield.keyboardType = .numberPad
            textfield.text = String(maximumVideoCroppingTime)
        }
        alert.addAction(UIAlertAction.init(title: "确定", style: .default, handler: { (action) in
            let textFiled = alert.textFields?.first
            let time = Int(textFiled?.text ?? "0")!
            self.videoConfig.cropping.maximumVideoCroppingTime = TimeInterval(time)
            self.tableView.reloadRows(at: [indexPath], with: .fade)
        }))
        alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    func minimumVideoCroppingTimeAction(_ indexPath: IndexPath) {
        let alert = UIAlertController.init(title: "maximumVideoCroppingTime", message: nil, preferredStyle: .alert)
        let minimumVideoCroppingTime: Int = Int(videoConfig.cropping.minimumVideoCroppingTime)
        alert.addTextField { (textfield) in
            textfield.keyboardType = .numberPad
            textfield.text = String(minimumVideoCroppingTime)
        }
        alert.addAction(UIAlertAction.init(title: "确定", style: .default, handler: { (action) in
            let textFiled = alert.textFields?.first
            let time = Int(textFiled?.text ?? "0")!
            self.videoConfig.cropping.minimumVideoCroppingTime = TimeInterval(time)
            self.tableView.reloadRows(at: [indexPath], with: .fade)
        }))
        alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
extension EditorConfigurationViewController {
    enum editorSection: Int, CaseIterable  {
        case editorType
        case photoOptions
        case videoOptions
        var title: String {
            switch self {
            case .editorType:
                 return "editorType"
            case .photoOptions:
                 return "PhotoOptions"
            case .videoOptions:
                 return "VideoOptions"
            }
        }
        var allRowCase: [ConfigRowTypeRule] {
            switch self {
            case .editorType:
                return editorTypeRow.allCases
            case .photoOptions:
                return photoEditorRow.allCases
            case .videoOptions:
                return videoEditorRow.allCases
            }
        }
    }
    enum editorTypeRow: String, CaseIterable, ConfigRowTypeRule {
        case type
        case assetType
        
        var title: String {
            switch self {
            case .type:
                return "编辑类型"
            case .assetType:
                return "资源类型"
            }
        }
        var detailTitle: String {
            return "." + self.rawValue
        }
        func getFunction<T>(_ controller: T) -> ((IndexPath) -> Void) where T : UIViewController {
            guard let controller = controller as? EditorConfigurationViewController else {
                return { _ in }
            }
            switch self {
            case .type:
                return controller.editorTypeAction(_:)
            case .assetType:
                return controller.assetTypeAction(_:)
            }
        }
    }
    enum photoEditorRow: String, CaseIterable, ConfigRowTypeRule {
        case state
        case fixedCropState
        case isRoundCrop
        case fixedRatio
        case aspectRatioType
        case maskType
        var title: String {
            switch self {
            case .state:
                return "初始状态"
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
            switch self {
            case .state, .fixedCropState:
                return "." + rawValue
            default: break
            }
            return ".cropConfig." + rawValue
        }
        func getFunction<T>(_ controller: T) -> ((IndexPath) -> Void) where T : UIViewController {
            guard let controller = controller as? EditorConfigurationViewController else {
                return { _ in }
            }
            switch self {
            case .state:
                return controller.stateAction(_:)
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
    enum videoEditorRow: String, CaseIterable, ConfigRowTypeRule {
        case exportPresetName
        case defaultState
        case mustBeTailored
        case maximumVideoCroppingTime
        case minimumVideoCroppingTime
        var title: String {
            switch self {
            case .exportPresetName:
                return "编辑后导出的质量"
            case .defaultState:
                return "当前默认的状态"
            case .mustBeTailored:
                return "默认裁剪状态下必须裁剪视频"
            case .maximumVideoCroppingTime:
                return "视频最大裁剪时长"
            case .minimumVideoCroppingTime:
                return "视频最小裁剪时长"
            }
        }
        var detailTitle: String {
            switch self {
            case .maximumVideoCroppingTime, .minimumVideoCroppingTime:
                return ".cropping." + self.rawValue
            default:
                break
            }
            return "." + self.rawValue
        }
        
        func getFunction<T>(_ controller: T) -> ((IndexPath) -> Void) where T : UIViewController {
            guard let controller = controller as? EditorConfigurationViewController else {
                return { _ in }
            }
            switch self {
            case .exportPresetName:
                return controller.exportPresetNameAction(_:)
            case .defaultState:
                return controller.defaultStateAction(_:)
            case .mustBeTailored:
                return controller.mustBeTailoredAction(_:)
            case .maximumVideoCroppingTime:
                return controller.maximumVideoCroppingTimeAction(_:)
            case .minimumVideoCroppingTime:
                return controller.minimumVideoCroppingTimeAction(_:)
            }
        }
    }
}

extension VideoEditorViewController.State {
    var title: String {
        if self == .cropping {
            return "裁剪"
        }
        return "正常"
    }
}

extension PhotoEditorViewController.State {
    var title: String {
        if self == .cropping {
            return "裁剪"
        }
        return "正常"
    }
}
