//
//  PickerColorConfigurationViewController.swift
//  Example
//
//  Created by Slience on 2021/3/17.
//

import UIKit
import HXPhotoPicker

class PickerColorConfigurationViewController: UITableViewController {
    
    var config: PickerConfiguration
    var didDoneHandler: ((PickerConfiguration) -> Void)?
    var currentSelectedIndexPath: IndexPath?
    init(config: PickerConfiguration) {
        self.config = config
        if #available(iOS 13.0, *) {
            super.init(style: .insetGrouped)
        } else {
            // Fallback on earlier versions
            super.init(style: .grouped)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Color"
        
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.register(ConfigurationViewCell.self, forCellReuseIdentifier: ConfigurationViewCell.reuseIdentifier)
        tableView.tableFooterView = UIView(frame: .zero)
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "确定",
            style: .done,
            target: self,
            action: #selector(backClick)
        )
    }
    
    @objc func backClick() {
        didDoneHandler?(config)
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return ColorConfigSection.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ColorConfigSection.allCases[section].allRowCase.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ConfigurationViewCell.reuseIdentifier,
            for: indexPath
        ) as! ConfigurationViewCell
        let rowType = ColorConfigSection.allCases[indexPath.section].allRowCase[indexPath.row]
        cell.setupColorData(rowType, getRowColor(rowType))
        return cell
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        54
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let rowType = ColorConfigSection.allCases[indexPath.section].allRowCase[indexPath.row]
        rowType.getFunction(self)(indexPath)
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ColorConfigSection.allCases[section].title
    }
}
extension PickerColorConfigurationViewController {
    // swiftlint:disable cyclomatic_complexity
    func getRowColor(_ rowType: ConfigRowTypeRule) -> UIColor? {
        // swiftlint:enable cyclomatic_complexity
        if let pickerRwoType = rowType as? PickerColorConfigRow {
            switch pickerRwoType {
            case .navigationViewBackgroundColor:
                return config.navigationViewBackgroundColor
            case .navigationViewBackgroudDarkColor:
                return config.navigationViewBackgroudDarkColor
            case .navigationTitleColor:
                return config.navigationTitleColor
            case .navigationTitleDarkColor:
                return config.navigationTitleDarkColor
            case .navigationTintColor:
                return config.navigationTintColor
            case .navigationDarkTintColor:
                return config.navigationDarkTintColor
            }
        }
        if let albumListRwoType = rowType as? AlbumListColorConfigRow {
            switch albumListRwoType {
            case .limitedStatusPromptColor:
                return config.albumList.limitedStatusPromptColor
            case .limitedStatusPromptDarkColor:
                return config.albumList.limitedStatusPromptDarkColor
            case .backgroundColor:
                return config.albumList.backgroundColor
            case .backgroundDarkColor:
                return config.albumList.backgroundDarkColor
            case .cellBackgroundColor:
                return config.albumList.cellBackgroundColor
            case .cellbackgroundDarkColor:
                return config.albumList.cellBackgroundDarkColor
            case .cellSelectedColor:
                return config.albumList.cellSelectedColor
            case .cellSelectedDarkColor:
                return config.albumList.cellSelectedDarkColor
            case .albumNameColor:
                return config.albumList.albumNameColor
            case .albumNameDarkColor:
                return config.albumList.albumNameDarkColor
            case .photoCountColor:
                return config.albumList.photoCountColor
            case .photoCountDarkColor:
                return config.albumList.photoCountDarkColor
            case .separatorLineColor:
                return config.albumList.separatorLineColor
            case .separatorLineDarkColor:
                return config.albumList.separatorLineDarkColor
            case .tickColor:
                return config.albumList.tickColor
            case .tickDarkColor:
                return config.albumList.tickDarkColor
            }
        }
        if let photoListRwoType = rowType as? PhotoListColorConfigRow {
            switch photoListRwoType {
            case .backgroundColor:
                return config.photoList.backgroundColor
            case .backgroundDarkColor:
                return config.photoList.backgroundDarkColor
            case .titleViewBackgroundColor:
                return config.photoList.titleView.backgroundColor
            case .titleViewBackgroundDarkColor:
                return config.photoList.titleView.backgroudDarkColor
            case .titleViewArrowBackgroundColor:
                return config.photoList.titleView.arrow.backgroundColor
            case .titleViewArrowBackgroudDarkColor:
                return config.photoList.titleView.arrow.backgroudDarkColor
            case .titleViewArrowColor:
                return config.photoList.titleView.arrow.arrowColor
            case .titleViewArrowDarkColor:
                return config.photoList.titleView.arrow.arrowDarkColor
            case .cellTitleColor:
                return config.photoList.cell.selectBox.titleColor
            case .cellTitleDarkColor:
                return config.photoList.cell.selectBox.titleDarkColor
            case .cellTickColor:
                return config.photoList.cell.selectBox.tickColor
            case .cellTickDarkColor:
                return config.photoList.cell.selectBox.tickDarkColor
            case .cellSelectedBackgroundColor:
                return config.photoList.cell.selectBox.selectedBackgroundColor
            case .cellSelectedBackgroudDarkColor:
                return config.photoList.cell.selectBox.selectedBackgroudDarkColor
            }
        }
        if let previewRwoType = rowType as? PreviewViewColorConfigRow {
            switch previewRwoType {
            case .backgroundColor:
                return config.previewView.backgroundColor
            case .backgroundDarkColor:
                return config.previewView.backgroundDarkColor
            case .selectTitleColor:
                return config.previewView.selectBox.titleColor
            case .selectTitleDarkColor:
                return config.previewView.selectBox.titleDarkColor
            case .selectTickColor:
                return config.previewView.selectBox.tickColor
            case .selectTickDarkColor:
                return config.previewView.selectBox.tickDarkColor
            case .selectedBackgroundColor:
                return config.previewView.selectBox.selectedBackgroundColor
            case .selectedBackgroudDarkColor:
                return config.previewView.selectBox.selectedBackgroudDarkColor
            }
        }
        
        return nil
    }
    
    func changedColorAction(_ indexPath: IndexPath) {
        currentSelectedIndexPath = indexPath
        if #available(iOS 14.0, *) {
            let vc = UIColorPickerViewController.init()
            vc.delegate = self
            if let color = getRowColor(ColorConfigSection.allCases[indexPath.section].allRowCase[indexPath.row]) {
                vc.selectedColor = color
            }
            present(vc, animated: true, completion: nil)
        } else {
            // Fallback on earlier versions
        }
    }
}
extension PickerColorConfigurationViewController: UIColorPickerViewControllerDelegate {
    @available(iOS 14.0, *)
    // swiftlint:disable cyclomatic_complexity
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        // swiftlint:enable cyclomatic_complexity
        if let indexPath = currentSelectedIndexPath {
            let rowType = ColorConfigSection.allCases[indexPath.section].allRowCase[indexPath.row]
            let color = viewController.selectedColor
            if let pickerRwoType = rowType as? PickerColorConfigRow {
                switch pickerRwoType {
                case .navigationViewBackgroundColor:
                    config.navigationViewBackgroundColor = color
                case .navigationViewBackgroudDarkColor:
                    config.navigationViewBackgroudDarkColor = color
                case .navigationTitleColor:
                    config.navigationTitleColor = color
                case .navigationTitleDarkColor:
                    config.navigationTitleDarkColor = color
                case .navigationTintColor:
                    config.navigationTintColor = color
                case .navigationDarkTintColor:
                    config.navigationDarkTintColor = color
                }
            }
            if let albumListRwoType = rowType as? AlbumListColorConfigRow {
                switch albumListRwoType {
                case .limitedStatusPromptColor:
                    config.albumList.limitedStatusPromptColor = color
                case .limitedStatusPromptDarkColor:
                    config.albumList.limitedStatusPromptDarkColor = color
                case .backgroundColor:
                    config.albumList.backgroundColor = color
                case .backgroundDarkColor:
                    config.albumList.backgroundDarkColor = color
                case .cellBackgroundColor:
                    config.albumList.cellBackgroundColor = color
                case .cellbackgroundDarkColor:
                    config.albumList.cellBackgroundDarkColor = color
                case .cellSelectedColor:
                    config.albumList.cellSelectedColor = color
                case .cellSelectedDarkColor:
                    config.albumList.cellSelectedDarkColor = color
                case .albumNameColor:
                    config.albumList.albumNameColor = color
                case .albumNameDarkColor:
                    config.albumList.albumNameDarkColor = color
                case .photoCountColor:
                    config.albumList.photoCountColor = color
                case .photoCountDarkColor:
                    config.albumList.photoCountDarkColor = color
                case .separatorLineColor:
                    config.albumList.separatorLineColor = color
                case .separatorLineDarkColor:
                    config.albumList.separatorLineDarkColor = color
                case .tickColor:
                    config.albumList.tickColor = color
                case .tickDarkColor:
                    config.albumList.tickDarkColor = color
                }
            }
            if let photoListRwoType = rowType as? PhotoListColorConfigRow {
                switch photoListRwoType {
                case .backgroundColor:
                    config.photoList.backgroundColor = color
                case .backgroundDarkColor:
                    config.photoList.backgroundDarkColor = color
                case .titleViewBackgroundColor:
                    config.photoList.titleView.backgroundColor = color
                case .titleViewBackgroundDarkColor:
                    config.photoList.titleView.backgroudDarkColor = color
                case .titleViewArrowBackgroundColor:
                    config.photoList.titleView.arrow.backgroundColor = color
                case .titleViewArrowBackgroudDarkColor:
                    config.photoList.titleView.arrow.backgroudDarkColor = color
                case .titleViewArrowColor:
                    config.photoList.titleView.arrow.arrowColor = color
                case .titleViewArrowDarkColor:
                    config.photoList.titleView.arrow.arrowDarkColor = color
                case .cellTitleColor:
                    config.photoList.cell.selectBox.titleColor = color
                case .cellTitleDarkColor:
                    config.photoList.cell.selectBox.titleDarkColor = color
                case .cellTickColor:
                    config.photoList.cell.selectBox.tickColor = color
                case .cellTickDarkColor:
                    config.photoList.cell.selectBox.tickDarkColor = color
                case .cellSelectedBackgroundColor:
                    config.photoList.cell.selectBox.selectedBackgroundColor = color
                case .cellSelectedBackgroudDarkColor:
                    config.photoList.cell.selectBox.selectedBackgroudDarkColor = color
                }
            }
            if let previewRwoType = rowType as? PreviewViewColorConfigRow {
                switch previewRwoType {
                case .backgroundColor:
                    config.previewView.backgroundColor = color
                case .backgroundDarkColor:
                    config.previewView.backgroundDarkColor = color
                case .selectTitleColor:
                    config.previewView.selectBox.titleColor = color
                case .selectTitleDarkColor:
                    config.previewView.selectBox.titleDarkColor = color
                case .selectTickColor:
                    config.previewView.selectBox.tickColor = color
                case .selectTickDarkColor:
                    config.previewView.selectBox.tickDarkColor = color
                case .selectedBackgroundColor:
                    config.previewView.selectBox.selectedBackgroundColor = color
                case .selectedBackgroudDarkColor:
                    config.previewView.selectBox.selectedBackgroudDarkColor = color
                }
            }
            tableView.reloadRows(at: [indexPath], with: .fade)
        }
    }
}

extension PickerColorConfigurationViewController {
    enum ColorConfigSection: Int, CaseIterable {
        case picker
        case albumList
        case photoList
        case previewView
        
        var title: String {
            switch self {
            case .picker:
                return "Picker"
            case .albumList:
                return "相册列表"
            case .photoList:
                return "照片列表"
            case .previewView:
                return "预览界面"
            }
        }
        
        var allRowCase: [ConfigRowTypeRule] {
            switch self {
            case .picker:
                return PickerColorConfigRow.allCases
            case .albumList:
                return AlbumListColorConfigRow.allCases
            case .photoList:
                return PhotoListColorConfigRow.allCases
            case .previewView:
                return PreviewViewColorConfigRow.allCases
            }
        }
    }
    
    enum PickerColorConfigRow: String, CaseIterable, ConfigRowTypeRule {
        
        case navigationViewBackgroundColor
        case navigationViewBackgroudDarkColor
        case navigationTitleColor
        case navigationTitleDarkColor
        case navigationTintColor
        case navigationDarkTintColor
        
        var title: String {
            switch self {
            case .navigationViewBackgroundColor:
                return "导航控制器背景颜色"
            case .navigationViewBackgroudDarkColor:
                return "暗黑风格下导航控制器背景颜色"
            case .navigationTitleColor:
                return "导航栏标题颜色"
            case .navigationTitleDarkColor:
                return "暗黑风格下导航栏标题颜色"
            case .navigationTintColor:
                return "TintColor"
            case .navigationDarkTintColor:
                return "暗黑风格下TintColor"
            }
        }
        
        var detailTitle: String {
            
            return "." + self.rawValue
        }
        
        func getFunction<T>(
            _ controller: T
        ) -> ((IndexPath) -> Void) where T: UIViewController {
            guard let controller = controller as? PickerColorConfigurationViewController else { return { _ in } }
            return controller.changedColorAction(_: )
        }
    }
    enum AlbumListColorConfigRow: String, CaseIterable, ConfigRowTypeRule {
        case limitedStatusPromptColor
        case limitedStatusPromptDarkColor
        case backgroundColor
        case backgroundDarkColor
        case cellBackgroundColor
        case cellbackgroundDarkColor
        case cellSelectedColor
        case cellSelectedDarkColor
        case albumNameColor
        case albumNameDarkColor
        case photoCountColor
        case photoCountDarkColor
        case separatorLineColor
        case separatorLineDarkColor
        case tickColor
        case tickDarkColor
        
        var title: String {
            switch self {
            case .limitedStatusPromptColor:
                return "可访问权限下的提示语颜色"
            case .limitedStatusPromptDarkColor:
                return "暗黑风格可访问权限下的提示语颜色"
            case .backgroundColor:
                return "列表背景颜色"
            case .backgroundDarkColor:
                return "暗黑风格下列表背景颜色"
            case .cellBackgroundColor:
                return "cell背景颜色"
            case .cellbackgroundDarkColor:
                return "暗黑风格下cell背景颜色"
            case .cellSelectedColor:
                return "cell选中时的颜色"
            case .cellSelectedDarkColor:
                return "暗黑风格下cell选中时的颜色"
            case .albumNameColor:
                return "相册名称颜色"
            case .albumNameDarkColor:
                return "暗黑风格下相册名称颜色"
            case .photoCountColor:
                return "照片数量颜色"
            case .photoCountDarkColor:
                return "暗黑风格下相册名称颜色"
            case .separatorLineColor:
                return "分隔线颜色"
            case .separatorLineDarkColor:
                return "暗黑风格下分隔线颜色"
            case .tickColor:
                return "选中勾勾的颜色"
            case .tickDarkColor:
                return "暗黑风格选中勾勾的颜色"
            }
        }
        
        var detailTitle: String {
            
            return ".albumList" + self.rawValue
        }
        
        func getFunction<T>(
            _ controller: T
        ) -> ((IndexPath) -> Void) where T: UIViewController {
            guard let controller = controller as? PickerColorConfigurationViewController else { return { _ in } }
            return controller.changedColorAction(_: )
        }
    }
    enum PhotoListColorConfigRow: String, CaseIterable, ConfigRowTypeRule {
        case backgroundColor
        case backgroundDarkColor
        case titleViewBackgroundColor
        case titleViewBackgroundDarkColor
        case titleViewArrowBackgroundColor
        case titleViewArrowBackgroudDarkColor
        case titleViewArrowColor
        case titleViewArrowDarkColor
        case cellTitleColor
        case cellTitleDarkColor
        case cellTickColor
        case cellTickDarkColor
        case cellSelectedBackgroundColor
        case cellSelectedBackgroudDarkColor
        
        var title: String {
            switch self {
            case .backgroundColor:
                return "背景颜色"
            case .backgroundDarkColor:
                return "暗黑风格下背景颜色"
            case .titleViewBackgroundColor:
                return "标题" + "背景颜色"
            case .titleViewBackgroundDarkColor:
                return "标题" + "暗黑风格下背景颜色"
            case .titleViewArrowBackgroundColor:
                return "标题" + "箭头背景颜色"
            case .titleViewArrowBackgroudDarkColor:
                return "标题" + "暗黑风格下箭头背景颜色"
            case .titleViewArrowColor:
                return "标题" + "箭头颜色"
            case .titleViewArrowDarkColor:
                return "标题" + "暗黑风格下箭头颜色"
            case .cellTitleColor:
                return "Cell" + "选中之后的数字颜色"
            case .cellTitleDarkColor:
                return "Cell" + "暗黑风格下选中之后的数字颜色"
            case .cellTickColor:
                return "Cell" + "选中之后勾勾颜色"
            case .cellTickDarkColor:
                return "Cell" + "暗黑风格下选中之后勾勾颜色"
            case .cellSelectedBackgroundColor:
                return "Cell" + "选择框选中后的背景颜色"
            case .cellSelectedBackgroudDarkColor:
                return "Cell" + "暗黑风格下选择框选中后的背景颜色"
            }
        }
        
        var detailTitle: String {
            switch self {
            case .titleViewBackgroundColor:
                return ".photoList.titleViewConfig.backgroundColor"
            case .titleViewBackgroundDarkColor:
                return ".photoList.titleViewConfig.backgroundDarkColor"
            case .titleViewArrowBackgroundColor:
                return ".photoList.titleViewConfig.arrowBackgroundColor"
            case .titleViewArrowBackgroudDarkColor:
                return ".photoList.titleViewConfig.arrowBackgroundDarkColor"
            case .titleViewArrowColor:
                return ".photoList.titleViewConfig.arrowColor"
            case .titleViewArrowDarkColor:
                return ".photoList.titleViewConfig.arrowDarkColor"
            case .cellTitleColor:
                return ".photoList.cell.selectBox.titleColor"
            case .cellTitleDarkColor:
                return ".photoList.cell.selectBox.titleDarkColor"
            case .cellTickColor:
                return ".photoList.cell.selectBox.tickColor"
            case .cellTickDarkColor:
                return ".photoList.cell.selectBox.tickDarkColor"
            case .cellSelectedBackgroundColor:
                return ".photoList.cell.selectBox.selectedBackgroundColor"
            case .cellSelectedBackgroudDarkColor:
                return ".photoList.cell.selectBox.selectedBackgroudDarkColor"
            default:
                break
            }
            return "." + self.rawValue
        }
        
        func getFunction<T>(
            _ controller: T
        ) -> ((IndexPath) -> Void) where T: UIViewController {
            guard let controller = controller as? PickerColorConfigurationViewController else { return { _ in } }
            return controller.changedColorAction(_: )
        }
    }
    enum PreviewViewColorConfigRow: String, CaseIterable, ConfigRowTypeRule {
        
        case backgroundColor
        case backgroundDarkColor
        case selectTitleColor
        case selectTitleDarkColor
        case selectTickColor
        case selectTickDarkColor
        case selectedBackgroundColor
        case selectedBackgroudDarkColor
        
        var title: String {
            switch self {
            case .backgroundColor:
                return "背景颜色"
            case .backgroundDarkColor:
                return "暗黑风格下背景颜色"
            case .selectTitleColor:
                return "选择框文字颜色"
            case .selectTitleDarkColor:
                return "暗黑风格下选择框文字颜色"
            case .selectTickColor:
                return "选择框勾勾颜色"
            case .selectTickDarkColor:
                return "暗黑风格下选择框勾勾颜色"
            case .selectedBackgroundColor:
                return "选择框选中后的背景颜色"
            case .selectedBackgroudDarkColor:
                return "暗黑风格下选择框选中后的背景颜色"
            }
        }
        
        var detailTitle: String {
            switch self {
            case .selectTitleColor:
                return ".previewView.selectBox.titleColor"
            case .selectTitleDarkColor:
                return ".previewView.selectBox.titleDarkColor"
            case .selectTickColor:
                return ".previewView.selectBox.tickColor"
            case .selectTickDarkColor:
                return ".previewView.selectBox.tickDarkColor"
            case .selectedBackgroundColor:
                return ".previewView.selectBox.selectedBackgroundColor"
            case .selectedBackgroudDarkColor:
                return ".previewView.selectBox.selectedBackgroudDarkColor"
            default:
                break
            }
            return "." + self.rawValue
        }
        
        func getFunction<T>(
            _ controller: T
        ) -> ((IndexPath) -> Void) where T: UIViewController {
            guard let controller = controller as? PickerColorConfigurationViewController else { return { _ in } }
            return controller.changedColorAction(_: )
        }
    }
}

extension UITableViewCell {
    
    static var reuseIdentifier: String {
        return String(describing: Self.self)
    }
}
