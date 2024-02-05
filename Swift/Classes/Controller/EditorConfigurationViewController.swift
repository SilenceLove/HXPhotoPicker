//
//  EditorConfigurationViewController.swift
//  Example
//
//  Created by Slience on 2021/3/17.
//

import UIKit
import HXPhotoPicker
import AVFoundation

class EditorConfigurationViewController: UITableViewController {
    
    var config: EditorConfiguration = .init()
    var didDoneHandler: ((EditorConfiguration) -> Void)?
    
    var showOpenEditorButton: Bool = true
    let videoURL: URL = URL.init(fileURLWithPath: Bundle.main.path(forResource: "c81", ofType: "mp4")!)
    
    var editedResult: EditedResult?
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
                            forResource: "livephoto_image",
                            ofType: "jpeg"
                        )!
                    )!
                    let vc = EditorViewController(.init(type: .image(image), result: editedResult), config: config)
                    vc.delegate = self
                    present(vc, animated: true, completion: nil)
                }else {
                    #if canImport(Kingfisher)
                    let networkURL = URL(
                        string:
                            "https://wx4.sinaimg.cn/large/a6a681ebgy1gojng2qw07g208c093qv6.gif"
                    )!
                    let vc = EditorViewController(.init(type: .networkImage(networkURL), result: editedResult), config: config)
                    vc.delegate = self
                    present(vc, animated: true, completion: nil)
                    #else
                    let image = UIImage(
                        contentsOfFile: Bundle.main.path(
                            forResource: "livephoto_image",
                            ofType: "jpeg"
                        )!
                    )!
                    let vc = EditorViewController(.init(type: .image(image)), config: config)
                    vc.delegate = self
                    present(vc, animated: true, completion: nil)
                    #endif
                }
            }else {
                if assetType == 0 {
                    let vc = EditorViewController(.init(type: .video(videoURL), result: editedResult), config: config)
                    vc.delegate = self
                    present(vc, animated: true, completion: nil)
                }else {
                    let networkURL = URL(
                        string:
                            "http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/picker_examle_video.mp4"
                    )!
                    let vc = EditorViewController(.init(type: .networkVideo(networkURL), result: editedResult), config: config)
                    vc.delegate = self
                    present(vc, animated: true, completion: nil)
                }
            }
        }else {
            didDoneHandler?(config)
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
extension EditorConfigurationViewController: EditorViewControllerDelegate {
    
    /// 完成编辑
    /// - Parameters:
    ///   - editorViewController: 对应的 EditorViewController
    ///   - result: 编辑后的数据
    func editorViewController(
        _ editorViewController: EditorViewController,
        didFinish asset: EditorAsset
    ) {
        #if OCEXAMPLE
        if asset.contentType == .image {
            let pickerResultVC = PickerResultViewController.init()
            var pickerConfig = PickerConfiguration.init()
            pickerConfig.editor = config
            pickerResultVC.config = pickerConfig
            switch asset.type {
            case .image(let image):
                let localImageAsset = LocalImageAsset.init(image: image)
                let photoAsset = PhotoAsset.init(localImageAsset: localImageAsset)
                photoAsset.editedResult = asset.result
                pickerResultVC.selectedAssets = [photoAsset]
            #if canImport(Kingfisher)
            case .networkImage(let url):
                let photoAsset = PhotoAsset.init(networkImageAsset: .init(thumbnailURL: url, originalURL: url))
                photoAsset.editedResult = asset.result
                pickerResultVC.selectedAssets = [photoAsset]
            #endif
            default:
                break
            }
            self.navigationController?.pushViewController(pickerResultVC, animated: true)
        }else {
            let pickerResultVC = PickerResultViewController.init()
            var pickerConfig = PickerConfiguration.init()
            pickerConfig.editor = config
            pickerResultVC.config = pickerConfig
            
            switch asset.type {
            case .video(let url):
                let photoAsset = PhotoAsset.init(localVideoAsset: .init(videoURL: url))
                photoAsset.editedResult = asset.result
                pickerResultVC.selectedAssets = [photoAsset]
            case .networkVideo(let url):
                let photoAsset = PhotoAsset(
                    networkVideoAsset: .init(
                        videoURL: url
                    )
                )
                photoAsset.editedResult = asset.result
                pickerResultVC.selectedAssets = [photoAsset]
            default:
                break
            }
            self.navigationController?.pushViewController(pickerResultVC, animated: true)
        }
        #endif
    }
    
    
    /// 取消编辑
    /// - Parameter photoEditorViewController: 对应的 PhotoEditorViewController
    func editorViewController(
        didCancel editorViewController: EditorViewController
    ) {
        
    }
    
    /// 加载贴图标题资源
    /// - Parameters:
    ///   - editorViewController: 对应的`EditorViewController`
    ///   - loadTitleChartlet: 传入标题数组
    func editorViewController(
        _ editorViewController: EditorViewController,
        loadTitleChartlet response: @escaping EditorTitleChartletResponse
    ) {
        // 模仿延迟加加载数据
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            response(self.getChartletTitles())
        }
    }
    
    /// 加载贴图资源
    /// - Parameters:
    ///   - editorViewController: 对应的`EditorViewController`
    ///   - titleChartlet: 对应配置的 title
    ///   - titleIndex: 对应配置的 title 的位置索引
    ///   - response: 传入 title索引 和 贴图数据
    func editorViewController(
        _ editorViewController: EditorViewController,
        titleChartlet: EditorChartlet,
        titleIndex: Int,
        loadChartletList response: @escaping EditorChartletListResponse
    ) {
        response(titleIndex, getChartletList(index: titleIndex))
    }
    
    
    /// 加载配乐信息，当music.infos为空时触发
    /// 返回 true 内部会显示加载状态，调用 completionHandler 后恢复
    /// - Parameters:
    ///   - editorViewController: 对应的 EditorViewController
    ///   - completionHandler: 传入配乐信息
    func editorViewController(
        _ editorViewController: EditorViewController,
        loadMusic completionHandler: @escaping ([VideoEditorMusicInfo]) -> Void
    ) -> Bool {
        // 模仿延迟加加载数据
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completionHandler(Tools.musicInfos)
        }
        return true
    }
    
    /// 搜索配乐信息
    /// - Parameters:
    ///   - editorViewController: 对应的 EditorViewController
    ///   - text: 搜索的文字内容
    ///   - completion: 传入配乐信息，是否需要加载更多
    func editorViewController(
        _ editorViewController: EditorViewController,
        didSearchMusic text: String?,
        completionHandler: @escaping ([VideoEditorMusicInfo], Bool) -> Void
    ) {
        // 模仿延迟加加载数据
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completionHandler(Tools.musicInfos, true)
        }
    }
    
    /// 加载更多配乐信息
    /// - Parameters:
    ///   - editorViewController: 对应的 EditorViewController
    ///   - text: 搜索的文字内容
    ///   - completion: 传入配乐信息，是否还有更多数据
    func editorViewController(
        _ editorViewController: EditorViewController,
        loadMoreMusic text: String?,
        completionHandler: @escaping ([VideoEditorMusicInfo], Bool) -> Void
    ) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completionHandler(Tools.musicInfos, false)
        }
    }
    
    func getChartletTitles() -> [EditorChartlet] {
        var titles = PhotoTools.defaultTitleChartlet()
        let localTitleChartlet = EditorChartlet(image: UIImage(named: "hx_sticker_cover"))
        titles.append(localTitleChartlet)
        let gifTitleChartlet = EditorChartlet(
            url: URL(
                string:
                    "https://i.postimg.cc/bNCDrtXF/giftitle.gif"
            )
        )
        titles.append(gifTitleChartlet)
        return titles
    }
    func getChartletList(index: Int) -> [EditorChartlet] {
        if index == 0 {
            return PhotoTools.defaultNetworkChartlet()
        }else if index == 1 {
            let imageNameds = [
                "hx_sticker_haoxinqing",
                "hx_sticker_housailei",
                "hx_sticker_jintianfenkeai",
                "hx_sticker_keaibiaoq",
                "hx_sticker_kehaixing",
                "hx_sticker_saihong",
                "hx_sticker_wow",
                "hx_sticker_woxiangfazipai",
                "hx_sticker_xiaochuzhujiao",
                "hx_sticker_yuanqimanman",
                "hx_sticker_yuanqishaonv",
                "hx_sticker_zaizaijia"
            ]
            var list: [EditorChartlet] = []
            for imageNamed in imageNameds {
                let chartlet = EditorChartlet(
                    image: UIImage(
                        contentsOfFile: Bundle.main.path(
                            forResource: imageNamed,
                            ofType: "png"
                        )!
                    )
                )
                list.append(chartlet)
            }
            return list
        }else {
            return gifChartlet()
        }
    }
    func gifChartlet() -> [EditorChartlet] {
        var gifs: [EditorChartlet] = []
        gifs.append(.init(url: URL(string: "https://img95.699pic.com/photo/40112/1849.gif_wh860.gif")))
        gifs.append(.init(url: URL(string: "https://img95.699pic.com/photo/40112/1680.gif_wh860.gif")))
        gifs.append(.init(url: URL(string: "https://img95.699pic.com/photo/40110/3660.gif_wh860.gif")))
        gifs.append(.init(url: URL(string: "https://pic.qqtn.com/up/2017-10/2017102615224886590.gif")))
        gifs.append(.init(url: URL(string: "https://img.99danji.com/uploadfile/2021/0220/20210220103405450.gif")))
        gifs.append(.init(url: URL(string: "https://imgo.youxihezi.net/img2021/2/20/11/2021022051733236.gif")))
        gifs.append(
            .init(
                url: URL(
                    string:
                        "https://qqpublic.qpic.cn/qq_public/0/0-2868806511-17879434A38D4DCC1A378F9528C76152/0?fmt=gif&size=136&h=431&w=480&ppv=1.gif" // swiftlint:disable:this line_length
                )
            )
        )
        gifs.append(
            .init(
                url: URL(
                    string:
                        "http://qqpublic.qpic.cn/qq_public/0/0-464434317-3A491192B7B04D124C793264F3E7DAE4/0?fmt=gif&size=335&h=361&w=450&ppv=1.gif" // swiftlint:disable:this line_length
                )
            )
        )
        gifs.append(.init(url: URL(string: "http://pic.qqtn.com/up/2017-5/2017053118074857711.gif")))
        gifs.append(.init(url: URL(string: "https://pic.diydoutu.com/bq/1493.gif")))
        return gifs
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
            case .defaultSelectedToolOption:
                return config.photo.defaultSelectedToolOption == .cropSize ? "裁剪" : "正常"
            case .isFixedCropSizeState:
                return config.isFixedCropSizeState ? "true" : "false"
            case .isRoundCrop:
                return config.cropSize.isRoundCrop ? "true" : "false"
            case .isFixedRatio:
                return config.cropSize.isFixedRatio ? "true" : "false"
            case .aspectRatioType:
                return config.cropSize.aspectRatio.title
            case .aspectRatios:
                if config.cropSize.aspectRatios.isEmpty {
                    return "空数组"
                }else {
                    return "默认数组"
                }
            case .defaultSeletedIndex:
                return String(config.cropSize.defaultSeletedIndex)
            case .resetToOriginal:
                return config.cropSize.isResetToOriginal ? "true" : "false"
            case .maskType:
                switch config.cropSize.maskType {
                case .blurEffect(_):
                    return "BlurEffect"
                case .customColor(_):
                    return "Color"
                }
            }
        }
        if let rowType = rowType as? VideoEditorRow {
            switch rowType {
            case .preset:
                switch config.video.preset {
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
            case .defaultSelectedToolOption:
                return config.video.defaultSelectedToolOption == .cropSize ? "裁剪" : "正常"
            case .maximumTime:
                return String(Int(config.video.cropTime.maximumTime))
            case .minimumTime:
                return String(Int(config.video.cropTime.minimumTime))
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
                    self.config.photo.defaultSelectedToolOption = nil
                    self.config.video.defaultSelectedToolOption = nil
                case 1:
                    self.config.photo.defaultSelectedToolOption = .cropSize
                    self.config.video.defaultSelectedToolOption = .cropSize
                default:
                    break
                }
                self.tableView.reloadRows(at: [indexPath], with: .fade)
            }))
        }
        alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: nil))
        presendAlert(alert)
    }
    func fixedCropStateAction(_ indexPath: IndexPath) {
        config.isFixedCropSizeState = !config.isFixedCropSizeState
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
    func isRoundCropAction(_ indexPath: IndexPath) {
        config.cropSize.isRoundCrop = !config.cropSize.isRoundCrop
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
    func fixedRatioAction(_ indexPath: IndexPath) {
        config.cropSize.isFixedRatio = !config.cropSize.isFixedRatio
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
            self.config.cropSize.aspectRatio = CGSize(width: widthRatio, height: heightRatio)
            self.config.cropSize.defaultSeletedIndex = 0
            self.tableView.reloadData()
        }))
        alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: nil))
        presendAlert(alert)
    }
    func aspectRatiosAction(_ indexPath: IndexPath) {
        let alert = UIAlertController.init(title: "aspectRatiosAction", message: nil, preferredStyle: .alert)
        alert.addAction(.init(title: "默认数组", style: .default, handler: { [weak self] _ in
            self?.config.cropSize.aspectRatios = [
                .init(title: .localized("原始比例"), ratio: .init(width: -1, height: -1)),
                .init(title: .localized("自由格式"), ratio: .zero),
                .init(title: .localized("正方形"), ratio: .init(width: 1, height: 1)),
                .init(title: .localized("16:9"), ratio: .init(width: 16, height: 9)),
                .init(title: .localized("5:4"), ratio: .init(width: 5, height: 4)),
                .init(title: .localized("7:5"), ratio: .init(width: 7, height: 5)),
                .init(title: .localized("4:3"), ratio: .init(width: 4, height: 3)),
                .init(title: .localized("5:3"), ratio: .init(width: 5, height: 3)),
                .init(title: .localized("3:2"), ratio: .init(width: 3, height: 2))
            ]
            self?.config.cropSize.defaultSeletedIndex = 0
            self?.config.cropSize.aspectRatio = .zero
            self?.tableView.reloadData()
        }))
        alert.addAction(.init(title: "[0, 0], [1, 1], [1, 2], [1, 3], [1, 4], [2, 1], [3, 1], [4, 1]", style: .default, handler: { [weak self] _ in
            self?.config.cropSize.aspectRatios = [
                .init(title: .localized("自由格式"), ratio: .zero),
                .init(title: .localized("正方形"), ratio: .init(width: 1, height: 1)),
                .init(title: .localized("1:2"), ratio: .init(width: 1, height: 2)),
                .init(title: .localized("1:3"), ratio: .init(width: 1, height: 3)),
                .init(title: .localized("1:4"), ratio: .init(width: 1, height: 4)),
                .init(title: .localized("2:1"), ratio: .init(width: 2, height: 1)),
                .init(title: .localized("3:1"), ratio: .init(width: 3, height: 1)),
                .init(title: .localized("4:1"), ratio: .init(width: 4, height: 1))
            ]
            self?.config.cropSize.defaultSeletedIndex = 0
            self?.config.cropSize.aspectRatio = .zero
            self?.tableView.reloadData()
        }))
        alert.addAction(.init(title: "[0, 0], [1, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 6], [6, 7]", style: .default, handler: { [weak self] _ in
            self?.config.cropSize.aspectRatios = [
                .init(title: .localized("自由格式"), ratio: .zero),
                .init(title: .localized("正方形"), ratio: .init(width: 1, height: 1)),
                .init(title: .localized("1:2"), ratio: .init(width: 1, height: 2)),
                .init(title: .localized("2:3"), ratio: .init(width: 2, height: 3)),
                .init(title: .localized("3:4"), ratio: .init(width: 3, height: 4)),
                .init(title: .localized("4:3"), ratio: .init(width: 4, height: 5)),
                .init(title: .localized("5:6"), ratio: .init(width: 5, height: 6)),
                .init(title: .localized("6:7"), ratio: .init(width: 6, height: 7))
            ]
            self?.config.cropSize.defaultSeletedIndex = 0
            self?.config.cropSize.aspectRatio = .zero
            self?.tableView.reloadData()
        }))
        alert.addAction(.init(title: "清空数组", style: .default, handler: { [weak self] _ in
            self?.config.cropSize.aspectRatios = []
            self?.config.cropSize.defaultSeletedIndex = 0
            self?.config.cropSize.aspectRatio = .zero
            self?.tableView.reloadData()
        }))
        alert.addAction(.init(title: "取消", style: .cancel))
        presendAlert(alert)
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
            if self.config.cropSize.aspectRatios.isEmpty {
                self.config.cropSize.defaultSeletedIndex = 0
                self.config.cropSize.isFixedRatio = false
            }else {
                self.config.cropSize.defaultSeletedIndex = index
                self.config.cropSize.isFixedRatio = index != 0
                
                let aspectRatio1 = self.config.cropSize.aspectRatios[index]
                self.config.cropSize.aspectRatio = aspectRatio1.ratio
            }
            self.tableView.reloadData()
        }))
        alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: nil))
        presendAlert(alert)
    }
    func resetToOriginalAction(_ indexPath: IndexPath) {
        config.cropSize.isResetToOriginal = !config.cropSize.isResetToOriginal
        tableView.reloadRows(at: [indexPath], with: .fade)
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
                    self.config.cropSize.maskType = .customColor(color: .black)
                case 1:
                    self.config.cropSize.maskType = .blurEffect(style: .dark)
                case 2:
                    self.config.cropSize.maskType = .blurEffect(style: .light)
                default:
                    break
                }
                self.tableView.reloadRows(at: [indexPath], with: .fade)
            }))
        }
        alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: nil))
        presendAlert(alert)
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
                    self.config.video.preset = .lowQuality
                case 1:
                    self.config.video.preset = .mediumQuality
                case 2:
                    self.config.video.preset = .highQuality
                default:
                    break
                }
                self.tableView.reloadRows(at: [indexPath], with: .fade)
            }))
        }
        alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: nil))
        presendAlert(alert)
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
                    self.config.photo.defaultSelectedToolOption = nil
                    self.config.video.defaultSelectedToolOption = nil
                case 1:
                    self.config.photo.defaultSelectedToolOption = .cropSize
                    self.config.video.defaultSelectedToolOption = .cropSize
                default:
                    break
                }
                self.tableView.reloadRows(at: [indexPath], with: .fade)
            }))
        }
        alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: nil))
        presendAlert(alert)
    }
    func maximumVideoCroppingTimeAction(_ indexPath: IndexPath) {
        let alert = UIAlertController.init(title: "maximumVideoCroppingTime", message: nil, preferredStyle: .alert)
        let maximumVideoCroppingTime: Int = Int(config.video.cropTime.maximumTime)
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
            let time = Int(textFiled?.text ?? "0") ?? 0
            self.config.video.cropTime.maximumTime = TimeInterval(time)
            self.tableView.reloadRows(at: [indexPath], with: .fade)
        }))
        alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: nil))
        presendAlert(alert)
    }
    func minimumVideoCroppingTimeAction(_ indexPath: IndexPath) {
        let alert = UIAlertController.init(title: "maximumVideoCroppingTime", message: nil, preferredStyle: .alert)
        let minimumVideoCroppingTime: Int = Int(config.video.cropTime.minimumTime)
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
            self.config.video.cropTime.minimumTime = TimeInterval(time)
            self.tableView.reloadRows(at: [indexPath], with: .fade)
        }))
        alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: nil))
        presendAlert(alert)
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
        case defaultSelectedToolOption
        case isFixedCropSizeState
        case isRoundCrop
        case isFixedRatio
        case aspectRatioType
        case aspectRatios
        case defaultSeletedIndex
        case resetToOriginal
        case maskType
        var title: String {
            switch self {
            case .defaultSelectedToolOption:
                return "初始状态"
            case .isFixedCropSizeState:
                return "固定裁剪状态"
            case .isRoundCrop:
                return "圆形裁剪框"
            case .isFixedRatio:
                return "固定比例"
            case .aspectRatioType:
                return "默认宽高比"
            case .aspectRatios:
                return "宽高比数组"
            case .defaultSeletedIndex:
                return "宽高比数组默认选中下标"
            case .resetToOriginal:
                return "是否重置到原始宽高比"
            case .maskType:
                return "裁剪时遮罩类型"
            }
        }
        var detailTitle: String {
            switch self {
            case .defaultSelectedToolOption:
                return ".photo." + rawValue
            case .isFixedCropSizeState:
                return "." + rawValue
            default: break
            }
            return ".cropSize." + rawValue
        }
        func getFunction<T>(
            _ controller: T) -> (
                (IndexPath) -> Void
            ) where T: UIViewController {
            guard let controller = controller as? EditorConfigurationViewController else {
                return { _ in }
            }
            switch self {
            case .defaultSelectedToolOption:
                return controller.stateAction(_:)
            case .isFixedCropSizeState:
                return controller.fixedCropStateAction(_:)
            case .isRoundCrop:
                return controller.isRoundCropAction(_:)
            case .isFixedRatio:
                return controller.fixedRatioAction(_:)
            case .aspectRatioType:
                return controller.aspectRatioTypeAction(_:)
            case .aspectRatios:
                return controller.aspectRatiosAction(_:)
            case .defaultSeletedIndex:
                return controller.defaultSeletedIndexAction(_:)
            case .resetToOriginal:
                return controller.resetToOriginalAction(_:)
            case .maskType:
                return controller.maskTypeAction(_:)
            }
        }
    }
    enum VideoEditorRow: String, CaseIterable, ConfigRowTypeRule {
        case preset
        case defaultSelectedToolOption
        case maximumTime
        case minimumTime
        var title: String {
            switch self {
            case .preset:
                return "编辑后导出的质量"
            case .defaultSelectedToolOption:
                return "当前默认的状态"
            case .maximumTime:
                return "视频最大裁剪时长"
            case .minimumTime:
                return "视频最小裁剪时长"
            }
        }
        var detailTitle: String {
            switch self {
            case .maximumTime, .minimumTime:
                return ".cropTime." + self.rawValue
            default:
                break
            }
            return ".video." + self.rawValue
        }
        
        func getFunction<T>(
            _ controller: T) -> (
                (IndexPath) -> Void
            ) where T: UIViewController {
            guard let controller = controller as? EditorConfigurationViewController else {
                return { _ in }
            }
            switch self {
            case .preset:
                return controller.exportPresetNameAction(_:)
            case .defaultSelectedToolOption:
                return controller.defaultStateAction(_:)
            case .maximumTime:
                return controller.maximumVideoCroppingTimeAction(_:)
            case .minimumTime:
                return controller.minimumVideoCroppingTimeAction(_:)
            }
        }
    }
}
