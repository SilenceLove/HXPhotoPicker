//
//  HomeViewController.swift
//  Example
//
//  Created by Slience on 2021/3/11.
//

import UIKit
import HXPHPicker
import CoreLocation
#if canImport(GDPerformanceView_Swift)
import GDPerformanceView_Swift
#endif

class HomeViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Photo Picker"
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.reuseIdentifier)
        tableView.tableFooterView = UIView(frame: .zero)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        #if canImport(GDPerformanceView_Swift)
        PerformanceMonitor.shared().start()
        #endif
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Section.allCases[section].allRowCase.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.reuseIdentifier, for: indexPath)
        let rowType = Section.allCases[indexPath.section].allRowCase[indexPath.row]
        cell.textLabel?.text = rowType.title
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let rowType = Section.allCases[indexPath.section].allRowCase[indexPath.row]
        if let rowType = rowType as? HomeRowType {
            if rowType == .camera {
                let camerController = rowType.controller as! CameraController
                camerController.autoDismiss = false
                camerController.cameraDelegate = self
                present(camerController, animated: true, completion: nil)
                return
            }
        }
        if let rowType = rowType as? ApplicationRowType {
            if rowType == .customCell {
                let vc = rowType.controller as! PhotoPickerController
                vc.pickerDelegate = self
                present(vc, animated: true, completion: nil)
                return
            }
        }
        navigationController?.pushViewController(rowType.controller, animated: true)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Section.allCases[section].title
    }
}

extension HomeViewController {
    
    enum Section: Int, CaseIterable {
        case module
        case application
        
        var title: String {
            switch self {
            case .module:
                return "Module"
            case .application:
                return "Application"
            }
        }
        
        var allRowCase: [HomeRowTypeRule] {
            switch self {
            case .module:
                return HomeRowType.allCases
            case .application:
                return ApplicationRowType.allCases
            }
        }
    }
    enum HomeRowType: CaseIterable, HomeRowTypeRule {
        case picker
        case editor
        case camera
        
        var title: String {
            switch self {
            case .picker:
                return "Picker"
            case .editor:
                return "Editor"
            case .camera:
                return "Camera"
            }
        }
        
        var controller: UIViewController {
            switch self {
            case .picker:
                if #available(iOS 13.0, *) {
                    return PickerConfigurationViewController(style: .insetGrouped)
                } else {
                    return PickerConfigurationViewController(style: .grouped)
                }
            case .editor:
                if #available(iOS 13.0, *) {
                    return EditorConfigurationViewController(style: .insetGrouped)
                } else {
                    return EditorConfigurationViewController(style: .grouped)
                }
            case .camera:
                let config = CameraConfiguration()
                config.position = .front
                config.defaultFilterIndex = 0
                config.photoFilters = FilterTools.filters()
                config.videoFilters = FilterTools.filters()
                return CameraController(config: config, type: .all)
            }
        }
    }
    enum ApplicationRowType: CaseIterable, HomeRowTypeRule {
        case avatarPicker
        case preselectAsset
        case collectionView
        case customCell
        case weChat
        case weChatMoment
        case photoBrowser
        case pickerView
        
        var title: String {
            switch self {
            case .avatarPicker:
                return "Avatar Picker"
            case .preselectAsset:
                return "Preselect Asset"
            case .collectionView:
                return "Picker+UICollectionView"
            case .customCell:
                return "Picker+CustomCell"
            case .weChat:
                return "WeChat"
            case .weChatMoment:
                return "WeChat-Moment"
            case .photoBrowser:
                return "Photo Browser"
            case .pickerView:
                return "Picker View"
            }
        }
        
        var controller: UIViewController {
            switch self {
            case .avatarPicker:
                if #available(iOS 13.0, *) {
                    return AvatarPickerConfigurationViewController(style: .insetGrouped)
                } else {
                    return AvatarPickerConfigurationViewController(style: .grouped)
                }
            case .preselectAsset:
                let vc = PickerResultViewController()
                vc.config.allowSelectedTogether = true
                vc.preselect = true
                return vc
            case .collectionView:
                return PickerResultViewController()
            case .customCell:
                let config: PickerConfiguration = PhotoTools.getWXPickerConfig(
                    isMoment: false
                )
                config.photoSelectionTapAction = .quickSelect
                config.videoSelectionTapAction = .quickSelect
                config.photoList.cell.customSingleCellClass = CustomPickerViewCell.self
                config.photoList.cell.customSelectableCellClass = CustomPickerViewCell.self
                let pickerController = PhotoPickerController(
                    config: config
                )
                pickerController.autoDismiss = false
                return pickerController
            case .weChat:
                return WeChatViewController()
            case .weChatMoment:
                return WeChatMometViewController()
            case .photoBrowser:
                return PhotoBrowserViewController()
            case .pickerView:
                return WindowPickerViewController()
            }
        }
    }
}

extension HomeViewController: PhotoPickerControllerDelegate {
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
extension UITableViewCell {
    
    static var reuseIdentifier: String {
        return String(describing: Self.self)
    }
}
extension HomeViewController: CameraControllerDelegate {
    func cameraController(
        _ cameraController: CameraController,
        didFinishWithResult result: CameraController.Result,
        location: CLLocation?) {
        cameraController.dismiss(animated: true) {
            let photoAsset: PhotoAsset
            switch result {
            case .image(let image):
                photoAsset = PhotoAsset(localImageAsset: .init(image: image))
            case .video(let videoURL):
                let videoDuration = PhotoTools.getVideoDuration(videoURL: videoURL)
                photoAsset = .init(localVideoAsset: .init(videoURL: videoURL, duration: videoDuration))
            }
            let pickerResultVC = PickerResultViewController.init()
            pickerResultVC.selectedAssets = [photoAsset]
            self.navigationController?.pushViewController(pickerResultVC, animated: true)
        }
    }
}
