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
//        videoConfig.music = .init(infos: musics)
        
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.register(ConfigurationViewCell.self, forCellReuseIdentifier: ConfigurationViewCell.reuseIdentifier)
        tableView.tableFooterView = UIView(frame: .zero)
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: showOpenEditorButton ? "打开编辑器" : "确定",
            style: .done,
            target: self,
            action: #selector(backClick)
        )
    }
    
    @objc func backClick() {
        if showOpenEditorButton {
            if editorType == 0 {
                if assetType == 0 {
                    let image = UIImage(
                        contentsOfFile: Bundle.main.path(
                            forResource: "picker_example_image",
                            ofType: ".JPG"
                        )!
                    )!
                    Photo.edit(
                        photo: image,
                        config: photoConfig
                    ) { [weak self] controller, result in
                        guard let self = self else { return }
                        let pickerResultVC = PickerResultViewController()
                        let pickerConfig = PickerConfiguration()
                        pickerConfig.photoEditor = self.photoConfig
                        pickerResultVC.config = pickerConfig
                        let localImageAsset = LocalImageAsset.init(image: controller.image)
                        let photoAsset = PhotoAsset(localImageAsset: localImageAsset)
                        photoAsset.photoEdit = result
                        pickerResultVC.selectedAssets = [photoAsset]
                        self.navigationController?.pushViewController(pickerResultVC, animated: true)
                    }

//                    let vc = EditorController.init(image: image, config: photoConfig)
//                    vc.photoEditorDelegate = self
//                    present(vc, animated: true, completion: nil)
                }else {
                    #if canImport(Kingfisher)
                    let networkURL = URL(
                        string:
                            "https://wx4.sinaimg.cn/large/a6a681ebgy1gojng2qw07g208c093qv6.gif"
                    )!
                    let vc = EditorController(
                        networkImageURL: networkURL,
                        config: photoConfig
                    )
                    vc.photoEditorDelegate = self
                    present(vc, animated: true, completion: nil)
                    #else
                    let image = UIImage(
                        contentsOfFile: Bundle.main.path(
                            forResource: "picker_example_image",
                            ofType: ".JPG"
                        )!
                    )!
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
                    let networkURL = URL(
                        string:
                            "http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/picker_examle_video.mp4"
                    )!
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
        return showOpenEditorButton ? EditorSection.allCases.count : EditorSection.allCases.count - 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let index: Int
        if showOpenEditorButton {
            index = section
        }else {
            index = section + 1
        }
        return EditorSection.allCases[index].allRowCase.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ConfigurationViewCell.reuseIdentifier,
            for: indexPath
        ) as! ConfigurationViewCell
        let index: Int
        if showOpenEditorButton {
            index = indexPath.section
        }else {
            index = indexPath.section + 1
        }
        let rowType = EditorSection.allCases[index].allRowCase[indexPath.row]
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
        let rowType = EditorSection.allCases[index].allRowCase[indexPath.row]
        rowType.getFunction(self)(indexPath)
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let index: Int
        if showOpenEditorButton {
            index = section
        }else {
            index = section + 1
        }
        return EditorSection.allCases[index].title
    }
}
extension EditorConfigurationViewController: PhotoEditorViewControllerDelegate {
    func photoEditorViewController(
        _ photoEditorViewController: PhotoEditorViewController,
        didFinish result: PhotoEditResult
    ) {
        let pickerResultVC = PickerResultViewController.init()
        let pickerConfig = PickerConfiguration.init()
        pickerConfig.photoEditor = photoConfig
        pickerResultVC.config = pickerConfig
        
        switch photoEditorViewController.sourceType {
        case .local:
            let localImageAsset = LocalImageAsset.init(image: photoEditorViewController.image)
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
        switch photoEditorViewController.sourceType {
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
    func getMusicInfos() -> [VideoEditorMusicInfo] {
        var musics: [VideoEditorMusicInfo] = []
//        let audioUrl1 = Bundle.main.url(forResource: "天外来物", withExtension: "mp3")!
        let lyricUrl1 = Bundle.main.url(forResource: "天外来物", withExtension: nil)!
        let lrc1 = try! String(contentsOfFile: lyricUrl1.path) // swiftlint:disable:this force_try
        let music1 = VideoEditorMusicInfo.init(audioURL: URL(string: "http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/chartle/%E5%A4%A9%E5%A4%96%E6%9D%A5%E7%89%A9.mp3")!, // swiftlint:disable:this line_length
                                               lrc: lrc1)
        musics.append(music1)
        let audioUrl2 = Bundle.main.url(forResource: "嘉宾", withExtension: "mp3")!
        let lyricUrl2 = Bundle.main.url(forResource: "嘉宾", withExtension: nil)!
        let lrc2 = try! String(contentsOfFile: lyricUrl2.path) // swiftlint:disable:this force_try
        let music2 = VideoEditorMusicInfo.init(audioURL: audioUrl2,
                                               lrc: lrc2)
        musics.append(music2)
        let audioUrl3 = Bundle.main.url(forResource: "少女的祈祷", withExtension: "mp3")!
        let lyricUrl3 = Bundle.main.url(forResource: "少女的祈祷", withExtension: nil)!
        let lrc3 = try! String(contentsOfFile: lyricUrl3.path) // swiftlint:disable:this force_try
        let music3 = VideoEditorMusicInfo.init(audioURL: audioUrl3,
                                               lrc: lrc3)
        musics.append(music3)
        let audioUrl4 = Bundle.main.url(forResource: "野孩子", withExtension: "mp3")!
        let lyricUrl4 = Bundle.main.url(forResource: "野孩子", withExtension: nil)!
        let lrc4 = try! String(contentsOfFile: lyricUrl4.path) // swiftlint:disable:this force_try
        let music4 = VideoEditorMusicInfo.init(audioURL: audioUrl4,
                                               lrc: lrc4)
        musics.append(music4)
        let audioUrl5 = Bundle.main.url(forResource: "无赖", withExtension: "mp3")!
        let lyricUrl5 = Bundle.main.url(forResource: "无赖", withExtension: nil)!
        let lrc5 = try! String(contentsOfFile: lyricUrl5.path) // swiftlint:disable:this force_try
        let music5 = VideoEditorMusicInfo.init(audioURL: audioUrl5,
                                               lrc: lrc5)
        musics.append(music5)
        let audioUrl6 = Bundle.main.url(forResource: "时光正好", withExtension: "mp3")!
        let lyricUrl6 = Bundle.main.url(forResource: "时光正好", withExtension: nil)!
        let lrc6 = try! String(contentsOfFile: lyricUrl6.path) // swiftlint:disable:this force_try
        let music6 = VideoEditorMusicInfo.init(audioURL: audioUrl6,
                                               lrc: lrc6)
        musics.append(music6)
        let audioUrl7 = Bundle.main.url(forResource: "世间美好与你环环相扣", withExtension: "mp3")!
        let lyricUrl7 = Bundle.main.url(forResource: "世间美好与你环环相扣", withExtension: nil)!
        let lrc7 = try! String(contentsOfFile: lyricUrl7.path) // swiftlint:disable:this force_try
        let music7 = VideoEditorMusicInfo.init(audioURL: audioUrl7,
                                               lrc: lrc7)
        musics.append(music7)
        let audioUrl8 = Bundle.main.url(forResource: "爱你", withExtension: "mp3")!
        let lyricUrl8 = Bundle.main.url(forResource: "爱你", withExtension: nil)!
        let lrc8 = try! String(contentsOfFile: lyricUrl8.path) // swiftlint:disable:this force_try
        let music8 = VideoEditorMusicInfo.init(audioURL: audioUrl8,
                                               lrc: lrc8)
        musics.append(music8)
        return musics
    }
    func videoEditorViewController(
        _ videoEditorViewController: VideoEditorViewController,
        loadMusic completionHandler: @escaping ([VideoEditorMusicInfo]
        ) -> Void) -> Bool {
        // 模仿延迟加加载数据
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completionHandler(self.getMusicInfos())
        }
        return true
    }
    func videoEditorViewController(
        _ videoEditorViewController: VideoEditorViewController,
        didSearch text: String?,
        completionHandler: @escaping ([VideoEditorMusicInfo], Bool) -> Void
    ) {
        // 模仿延迟加加载数据
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completionHandler(self.getMusicInfos(), true)
        }
    }
    func videoEditorViewController(
        _ videoEditorViewController: VideoEditorViewController,
        loadMore text: String?,
        completionHandler: @escaping ([VideoEditorMusicInfo], Bool) -> Void
    ) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completionHandler(self.getMusicInfos(), false)
        }
    }
    
    func videoEditorViewController(
        _ videoEditorViewController: VideoEditorViewController,
        didFinish result: VideoEditResult
    ) {
        let pickerResultVC = PickerResultViewController.init()
        let pickerConfig = PickerConfiguration.init()
        pickerConfig.videoEditor = videoConfig
        pickerResultVC.config = pickerConfig
        
        switch videoEditorViewController.sourceType {
        case .local:
            let photoAsset = PhotoAsset.init(localVideoAsset: .init(videoURL: videoURL))
            photoAsset.videoEdit = result
            pickerResultVC.selectedAssets = [photoAsset]
        case .network:
            let photoAsset = PhotoAsset(
                networkVideoAsset: .init(
                    videoURL: videoEditorViewController.networkVideoURL!
                )
            )
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
        switch videoEditorViewController.sourceType {
        case .local:
            let photoAsset = PhotoAsset(localVideoAsset: .init(videoURL: videoURL))
            pickerResultVC.selectedAssets = [photoAsset]
        case .network:
            let photoAsset = PhotoAsset(
                networkVideoAsset: .init(
                    videoURL: videoEditorViewController.networkVideoURL!
                )
            )
            pickerResultVC.selectedAssets = [photoAsset]
        default:
            break
        }
        self.navigationController?.pushViewController(pickerResultVC, animated: true)
    }
}
extension EditorConfigurationViewController {
    func getRowContent(_ rowType: ConfigRowTypeRule) -> String {
        if let rowType = rowType as? EditorTypeRow {
            switch rowType {
            case .type:
                return editorType == 0 ? "photo" : "video"
            case .assetType:
                return assetType == 0 ? "本地" : "网络"
            }
        }
        if let rowType = rowType as? PhotoEditorRow {
            switch rowType {
            case .state:
                return photoConfig.state.title
            case .fixedCropState:
                return photoConfig.fixedCropState ? "true" : "false"
            case .isRoundCrop:
                return photoConfig.cropping.isRoundCrop ? "true" : "false"
            case .fixedRatio:
                return photoConfig.cropping.fixedRatio ? "true" : "false"
            case .aspectRatioType:
                return photoConfig.cropping.aspectRatioType.title
            case .maskType:
                switch photoConfig.cropping.maskType {
                case .blackColor:
                    return "blackColor"
                case .darkBlurEffect:
                    return "darkBlurEffect"
                case .lightBlurEffect:
                    return "lightBlurEffect"
                }
            }
        }
        if let rowType = rowType as? VideoEditorRow {
            switch rowType {
            case .exportPresetName:
                switch videoConfig.exportPreset {
                case .lowQuality:
                    return "LowQuality"
                case .mediumQuality:
                    return "MediumQuality"
                case .highQuality:
                    return "HighestQuality"
                case .ratio_640x480:
                    return "640x480"
                case .ratio_960x540:
                    return "960x540"
                case .ratio_1280x720:
                    return "1280x720"
                }
            case .defaultState:
                return videoConfig.defaultState.title
            case .mustBeTailored:
                return videoConfig.mustBeTailored ? "true" : "false"
            case .maximumVideoCroppingTime:
                return String(Int(videoConfig.cropTime.maximumVideoCroppingTime))
            case .minimumVideoCroppingTime:
                return String(Int(videoConfig.cropTime.minimumVideoCroppingTime))
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
            alert.addAction(UIAlertAction.init(title: title, style: .default, handler: { [weak self] (action) in
                guard let self = self else { return }
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
        photoConfig.cropping.isRoundCrop = !photoConfig.cropping.isRoundCrop
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
    func fixedRatioAction(_ indexPath: IndexPath) {
        photoConfig.cropping.fixedRatio = !photoConfig.cropping.fixedRatio
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
        alert.addAction(
            UIAlertAction(
                title: "确定",
                style: .default,
                handler: { [weak self] (action) in
                    guard let self = self else { return }
            let widthTextFiled = alert.textFields?.first
            let widthRatioStr = widthTextFiled?.text ?? "0"
            let widthRatio = Int(widthRatioStr.count == 0 ? "0" : widthRatioStr)!
            let heightTextFiled = alert.textFields?.last
            let heightRatioStr = heightTextFiled?.text ?? "0"
            let heightRatio = Int(heightRatioStr.count == 0 ? "0" : heightRatioStr)!
            self.photoConfig.cropping.aspectRatioType = .custom(CGSize(width: widthRatio, height: heightRatio))
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
                    self.photoConfig.cropping.maskType = .blackColor
                case 1:
                    self.photoConfig.cropping.maskType = .darkBlurEffect
                case 2:
                    self.photoConfig.cropping.maskType = .lightBlurEffect
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
            alert.addAction(UIAlertAction.init(title: title, style: .default, handler: { [weak self] (action) in
                guard let self = self else { return }
                let index = titles.firstIndex(of: action.title!)!
                switch index {
                case 0:
                    self.videoConfig.exportPreset = .lowQuality
                case 1:
                    self.videoConfig.exportPreset = .mediumQuality
                case 2:
                    self.videoConfig.exportPreset = .highQuality
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
            alert.addAction(UIAlertAction.init(title: title, style: .default, handler: { [weak self] (action) in
                guard let self = self else { return }
                let index = titles.firstIndex(of: action.title!)!
                switch index {
                case 0:
                    self.videoConfig.defaultState = .normal
                case 1:
                    self.videoConfig.defaultState = .cropTime
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
        let maximumVideoCroppingTime: Int = Int(videoConfig.cropTime.maximumVideoCroppingTime)
        alert.addTextField { (textfield) in
            textfield.keyboardType = .numberPad
            textfield.text = String(maximumVideoCroppingTime)
        }
        alert.addAction(
            UIAlertAction(
                title: "确定",
                style: .default,
                handler: { [weak self] (action) in
                    guard let self = self else { return }
            let textFiled = alert.textFields?.first
            let time = Int(textFiled?.text ?? "0")!
            self.videoConfig.cropTime.maximumVideoCroppingTime = TimeInterval(time)
            self.tableView.reloadRows(at: [indexPath], with: .fade)
        }))
        alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    func minimumVideoCroppingTimeAction(_ indexPath: IndexPath) {
        let alert = UIAlertController.init(title: "maximumVideoCroppingTime", message: nil, preferredStyle: .alert)
        let minimumVideoCroppingTime: Int = Int(videoConfig.cropTime.minimumVideoCroppingTime)
        alert.addTextField { (textfield) in
            textfield.keyboardType = .numberPad
            textfield.text = String(minimumVideoCroppingTime)
        }
        alert.addAction(
            UIAlertAction(
                title: "确定",
                style: .default,
                handler: { [weak self] (action) in
                    guard let self = self else { return }
            let textFiled = alert.textFields?.first
            let time = Int(textFiled?.text ?? "0")!
            self.videoConfig.cropTime.minimumVideoCroppingTime = TimeInterval(time)
            self.tableView.reloadRows(at: [indexPath], with: .fade)
        }))
        alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
extension EditorConfigurationViewController {
    enum EditorSection: Int, CaseIterable {
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
                return EditorTypeRow.allCases
            case .photoOptions:
                return PhotoEditorRow.allCases
            case .videoOptions:
                return VideoEditorRow.allCases
            }
        }
    }
    enum EditorTypeRow: String, CaseIterable, ConfigRowTypeRule {
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
        func getFunction<T>(
            _ controller: T) -> (
                (IndexPath) -> Void
            ) where T: UIViewController {
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
    enum PhotoEditorRow: String, CaseIterable, ConfigRowTypeRule {
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
            return ".cropping." + rawValue
        }
        func getFunction<T>(
            _ controller: T) -> (
                (IndexPath) -> Void
            ) where T: UIViewController {
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
    enum VideoEditorRow: String, CaseIterable, ConfigRowTypeRule {
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
        
        func getFunction<T>(
            _ controller: T) -> (
                (IndexPath) -> Void
            ) where T: UIViewController {
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
        if self == .cropTime {
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
