//
//  HomeViewController.swift
//  Example
//
//  Created by Slience on 2021/3/11.
//

import UIKit

class HomeViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "PhotoKit"
        
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
                    return VideoEditorConfigurationViewController(style: .insetGrouped)
                } else {
                    return VideoEditorConfigurationViewController(style: .grouped)
                }
            }
        }
    }
    enum ApplicationRowType: CaseIterable, HomeRowTypeRule {
        case UICollectionView
        case customCell
        
        var title: String {
            switch self {
            case .UICollectionView:
                return "Picker+UICollectionView"
            case .customCell:
                return "Picker+CustomCell"
            }
        }
        
        var controller: UIViewController {
            switch self {
            case .UICollectionView:
                return PickerResultViewController()
            case .customCell:
                return CustomPickerCellViewController()
            }
        }
    }
}

extension UITableViewCell {
    
    static var reuseIdentifier: String {
        return String(describing: Self.self)
    }
}
