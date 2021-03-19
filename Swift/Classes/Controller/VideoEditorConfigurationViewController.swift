//
//  VideoEditorConfigurationViewController.swift
//  Example
//
//  Created by Slience on 2021/3/17.
//

import UIKit
import HXPHPicker
import AVFoundation

class VideoEditorConfigurationViewController: UITableViewController {
    
    var config: VideoEditorConfiguration = .init()
    var showOpenEditorButton: Bool = true
    let videoURL: URL = URL.init(fileURLWithPath: Bundle.main.path(forResource: "videoeditormatter", ofType: "MP4")!)
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
            let vc = EditorController.init(videoURL: videoURL, config: config)
            vc.videoEditorDelegate = self
            present(vc, animated: true, completion: nil)
        }else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return videoEditorSection.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videoEditorSection.allCases[section].allRowCase.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ConfigurationViewCell.reuseIdentifier, for: indexPath) as! ConfigurationViewCell
        let rowType = videoEditorSection.allCases[indexPath.section].allRowCase[indexPath.row]
        cell.setupData(rowType, getRowContent(rowType))
        return cell
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        54
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let rowType = videoEditorSection.allCases[indexPath.section].allRowCase[indexPath.row]
        rowType.getFunction(self)(indexPath)
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return videoEditorSection.allCases[section].title
    }
}
extension VideoEditorConfigurationViewController: VideoEditorViewControllerDelegate {
    func videoEditorViewController(_ videoEditorViewController: VideoEditorViewController, didFinish result: VideoEditResult) {
        let pickerResultVC = PickerResultViewController.init()
        let pickerConfig = PickerConfiguration.init()
        pickerConfig.videoEditor = config
        pickerResultVC.config = pickerConfig
        let photoAsset = PhotoAsset.init(videoURL: result.editedURL)
        pickerResultVC.selectedAssets = [photoAsset]
        self.navigationController?.pushViewController(pickerResultVC, animated: true)
    }
    func videoEditorViewController(didFinishWithUnedited videoEditorViewController: VideoEditorViewController) {
        let pickerResultVC = PickerResultViewController.init()
        let pickerConfig = PickerConfiguration.init()
        pickerConfig.videoEditor = config
        pickerResultVC.config = pickerConfig
        let photoAsset = PhotoAsset.init(videoURL: videoURL)
        pickerResultVC.selectedAssets = [photoAsset]
        self.navigationController?.pushViewController(pickerResultVC, animated: true)
    }
}
extension VideoEditorConfigurationViewController {
    func getRowContent(_ rowType: ConfigRowTypeRule) -> String {
        if let rowType = rowType as? videoEditorRow {
            switch rowType {
            case .exportPresetName:
                switch config.exportPresetName {
                case AVAssetExportPresetLowQuality:
                    return "LowQuality"
                case AVAssetExportPresetMediumQuality:
                    return "MediumQuality"
                default:
                    return "HighestQuality"
                }
            case .defaultState:
                return config.defaultState.title
            case .mustBeTailored:
                return config.mustBeTailored ? "true" : "false"
            case .maximumVideoCroppingTime:
                return String(Int(config.cropping.maximumVideoCroppingTime))
            case .minimumVideoCroppingTime:
                return String(Int(config.cropping.minimumVideoCroppingTime))
            }
        }
        return ""
    }
    func exportPresetNameAction(_ indexPath: IndexPath) {
        let alert = UIAlertController.init(title: "exportPresetNameAction", message: nil, preferredStyle: .alert)
        let titles = ["lowQuality", "mediumQuality", "highestQuality"]
        for title in titles {
            alert.addAction(UIAlertAction.init(title: title, style: .default, handler: { (action) in
                let index = titles.firstIndex(of: action.title!)!
                switch index {
                case 0:
                    self.config.exportPresetName = AVAssetExportPresetLowQuality
                case 1:
                    self.config.exportPresetName = AVAssetExportPresetMediumQuality
                case 2:
                    self.config.exportPresetName = AVAssetExportPresetHighestQuality
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
                    self.config.defaultState = .normal
                case 1:
                    self.config.defaultState = .cropping
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
        config.mustBeTailored = !config.mustBeTailored
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
    func maximumVideoCroppingTimeAction(_ indexPath: IndexPath) {
        let alert = UIAlertController.init(title: "maximumVideoCroppingTime", message: nil, preferredStyle: .alert)
        let maximumVideoCroppingTime: Int = Int(config.cropping.maximumVideoCroppingTime)
        alert.addTextField { (textfield) in
            textfield.keyboardType = .numberPad
            textfield.text = String(maximumVideoCroppingTime)
        }
        alert.addAction(UIAlertAction.init(title: "确定", style: .default, handler: { (action) in
            let textFiled = alert.textFields?.first
            let time = Int(textFiled?.text ?? "0")!
            self.config.cropping.maximumVideoCroppingTime = TimeInterval(time)
            self.tableView.reloadRows(at: [indexPath], with: .fade)
        }))
        alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    func minimumVideoCroppingTimeAction(_ indexPath: IndexPath) {
        let alert = UIAlertController.init(title: "maximumVideoCroppingTime", message: nil, preferredStyle: .alert)
        let minimumVideoCroppingTime: Int = Int(config.cropping.minimumVideoCroppingTime)
        alert.addTextField { (textfield) in
            textfield.keyboardType = .numberPad
            textfield.text = String(minimumVideoCroppingTime)
        }
        alert.addAction(UIAlertAction.init(title: "确定", style: .default, handler: { (action) in
            let textFiled = alert.textFields?.first
            let time = Int(textFiled?.text ?? "0")!
            self.config.cropping.minimumVideoCroppingTime = TimeInterval(time)
            self.tableView.reloadRows(at: [indexPath], with: .fade)
        }))
        alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
extension VideoEditorConfigurationViewController {
    enum videoEditorSection: Int, CaseIterable  {
        case options
        var title: String {
            return "Options"
        }
        var allRowCase: [ConfigRowTypeRule] {
            return videoEditorRow.allCases
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
        var detailTile: String {
            switch self {
            case .maximumVideoCroppingTime, .minimumVideoCroppingTime:
                return ".cropping." + self.rawValue
            default:
                break
            }
            return "." + self.rawValue
        }
        
        func getFunction<T>(_ controller: T) -> ((IndexPath) -> Void) where T : UIViewController {
            guard let controller = controller as? VideoEditorConfigurationViewController else {
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
