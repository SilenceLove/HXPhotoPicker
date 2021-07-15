//
//  HomeViewController.swift
//  Example
//
//  Created by Slience on 2021/3/11.
//

import UIKit
import HXPHPicker

class HomeViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Photo Kit"
        
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.reuseIdentifier)
        tableView.tableFooterView = UIView(frame: .zero)
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
        if let rowType = rowType as? ApplicationRowType  {
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
        
        var title: String {
            switch self {
            case .picker:
                return "Picker"
            case .editor:
                return "Editor"
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
            }
        }
    }
    enum ApplicationRowType: CaseIterable, HomeRowTypeRule {
        case avatarPicker
        case preselectAsset
        case collectionView
        case customCell
        
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
                let config: PickerConfiguration = PhotoTools.getWXPickerConfig(isMoment: false)
                config.photoSelectionTapAction = .quickSelect
                config.videoSelectionTapAction = .quickSelect
                config.photoList.cell.customSingleCellClass = CustomPickerViewCell.self
                config.photoList.cell.customSelectableCellClass = CustomPickerViewCell.self
                let pickerController = PhotoPickerController.init(config: config)
                pickerController.autoDismiss = false
                return pickerController
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
