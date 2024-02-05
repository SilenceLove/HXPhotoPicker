//
//  PhotoPickerFilterViewController.swift
//  HXPhotoPickerExample
//
//  Created by Silence on 2023/6/18.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit

class PhotoPickerFilterViewController: UITableViewController {
     
    var options: PhotoPickerFilterSection.Options = .any
    var selectOptions: PickerAssetOptions = []
    var editorOptions: PickerAssetOptions = []
    var selectMode: PickerSelectMode = .single
    var photoCount: Int = 0
    var videoCount: Int = 0
    
    var didSelectedHandler: ((PhotoPickerFilterViewController) -> Void)?
    
    var themeColor: UIColor?
    var themeDarkColor: UIColor?
    
    private var bottomView: UIView!
    private var numberView: PhotoPickerBottomNumberView!
    private var filterLb: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            switch PhotoManager.shared.appearanceStyle {
            case .normal:
                overrideUserInterfaceStyle = .light
                navigationController?.overrideUserInterfaceStyle = .light
            case .dark:
                overrideUserInterfaceStyle = .dark
                navigationController?.overrideUserInterfaceStyle = .dark
            default:
                break
            }
        }
        navigationItem.title = .textPhotoList.filter.title.text
        navigationItem.rightBarButtonItem = .init(
            title: .textPhotoList.filter.finishTitle.text,
            style: .done,
            target: self,
            action: #selector(didDoneClick)
        )
        initViews()
        
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.register(PhotoPickerFilterViewCell.self)
        let bottomHeight = UIDevice.bottomMargin + 100
        bottomView.frame = .init(x: 0, y: 20, width: view.width, height: bottomHeight)
        tableView.tableFooterView = bottomView
        
        sections = []
        sections.append(.init(rows: [.init(title: .textPhotoList.filter.anyTitle.text, options: .any, isSelected: options == .any)]))
        var rows: [PhotoPickerFilterSection.Row] = []
        if selectOptions.isPhoto && selectOptions.isVideo {
            if !editorOptions.isEmpty, selectMode == .multiple {
                rows.append(.init(title: .textPhotoList.filter.editedTitle.text, options: .edited, isSelected: options.contains(.edited)))
            }
            rows.append(.init(title: .textPhotoList.filter.photoTitle.text, options: .photo, isSelected: options.contains(.photo)))
            if selectOptions.contains(.gifPhoto) {
                rows.append(.init(title: .textPhotoList.filter.gifTitle.text, options: .gif, isSelected: options.contains(.gif)))
            }
            if selectOptions.contains(.livePhoto) {
                rows.append(.init(title: .textPhotoList.filter.livePhotoTitle.text, options: .livePhoto, isSelected: options.contains(.livePhoto)))
            }
            rows.append(.init(title: .textPhotoList.filter.videoTitle.text, options: .video, isSelected: options.contains(.video)))
        }else if selectOptions.isPhoto {
            if editorOptions.isPhoto, selectMode == .multiple {
                rows.append(.init(title: .textPhotoList.filter.editedTitle.text, options: .edited, isSelected: options.contains(.edited)))
            }
            rows.append(.init(title: .textPhotoList.filter.photoTitle.text, options: .photo, isSelected: options.contains(.photo)))
            if selectOptions.contains(.gifPhoto) {
                rows.append(.init(title: .textPhotoList.filter.gifTitle.text, options: .gif, isSelected: options.contains(.gif)))
            }
            if selectOptions.contains(.livePhoto) {
                rows.append(.init(title: .textPhotoList.filter.livePhotoTitle.text, options: .livePhoto, isSelected: options.contains(.livePhoto)))
            }
        }else if selectOptions.isVideo {
            if editorOptions.isVideo, selectMode == .multiple {
                rows.append(.init(title: .textPhotoList.filter.editedTitle.text.localized, options: .edited, isSelected: options.contains(.edited)))
            }
            rows.append(.init(title: .textPhotoList.filter.videoTitle.text.localized, options: .video, isSelected: options.contains(.video)))
        }
        if !rows.isEmpty {
            sections.append(.init(title: .textPhotoList.filter.sectionTitle.text, rows: rows))
        }
    }
    
    private func initViews() {
        numberView = PhotoPickerBottomNumberView()
        numberView.photoCount = photoCount
        numberView.videoCount = videoCount
        numberView.config = .init()
        
        filterLb = UILabel()
        filterLb.text = options == .any ? .textPhotoList.filter.bottomEmptyTitle.text : .textPhotoList.filter.bottomTitle.text
        filterLb.font = .textPhotoList.filter.bottomTitleFont
        if #available(iOS 13.0, *) {
            filterLb.textColor = UIColor(dynamicProvider: {
                $0.userInterfaceStyle == .dark ? .white : .black
            })
        } else {
            filterLb.textColor = .black
        }
        filterLb.textAlignment = .center
        
        bottomView = UIView()
        bottomView.addSubview(numberView)
        bottomView.addSubview(filterLb)
        
        updateColors()
    }
    
    func updateColors() {
        if PhotoManager.isDark {
            if let themeDarkColor {
                navigationController?.navigationBar.tintColor = themeDarkColor
            }
        }else {
            if let themeColor {
                navigationController?.navigationBar.tintColor = themeColor
            }
        }
    }
    
    @objc
    private func didDoneClick() {
        dismiss(animated: true)
    }
    
    private var sections: [PhotoPickerFilterSection] = []
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: PhotoPickerFilterViewCell = tableView.dequeueReusableCell()
        let row = sections[indexPath.section].rows[indexPath.row]
        cell.textLabel?.text = row.title
        cell.accessoryType = row.isSelected ? .checkmark : .none
        if PhotoManager.isDark {
            if let themeDarkColor {
                cell.tintColor = themeDarkColor
            }
        }else {
            if let themeColor {
                cell.tintColor = themeColor
            }
        }
        cell.selectionStyle = .none
        switch row.options {
        case .any:
            cell.imageView?.image = .imageResource.picker.photoList.filter.any.image?.withRenderingMode(.alwaysTemplate)
        case .edited:
            cell.imageView?.image = .imageResource.picker.photoList.filter.edited.image?.withRenderingMode(.alwaysTemplate)
        case .photo:
            cell.imageView?.image = .imageResource.picker.photoList.filter.photo.image?.withRenderingMode(.alwaysTemplate)
        case .gif:
            cell.imageView?.image = .imageResource.picker.photoList.filter.gif.image?.withRenderingMode(.alwaysTemplate)
        case .livePhoto:
            cell.imageView?.image = .imageResource.picker.photoList.filter.livePhoto.image?.withRenderingMode(.alwaysTemplate)
        case .video:
            cell.imageView?.image = .imageResource.picker.photoList.filter.video.image?.withRenderingMode(.alwaysTemplate)
        default:
            break
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let row = sections[indexPath.section].rows[indexPath.row]
        switch row.options {
        case .any:
            if row.isSelected {
                return
            }else {
                for row in sections[1].rows where row.isSelected {
                    row.isSelected = false
                }
                row.isSelected = !row.isSelected
                options = .any
            }
        default:
            row.isSelected = !row.isSelected
            if row.isSelected {
                let anyRow = sections[0].rows[0]
                if anyRow.isSelected {
                    anyRow.isSelected = false
                    options = []
                }
                options.insert(row.options)
            }else {
                options.remove(row.options)
                var isAllUnselect = true
                for row in sections[1].rows where row.isSelected {
                    isAllUnselect = false
                }
                if isAllUnselect {
                    let anyRow = sections[0].rows[0]
                    anyRow.isSelected = true
                    options = .any
                }
            }
        }
        tableView.reloadData()
        didSelectedHandler?(self)
        updateBottom()
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].title
    }
    
    func updateBottom() {
        numberView.photoCount = photoCount
        numberView.videoCount = videoCount
        numberView.configData(true)
        filterLb.text = options == .any ? .textPhotoList.filter.bottomEmptyTitle.text : .textPhotoList.filter.bottomTitle.text
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let contentHeight = tableView.contentSize.height
        if #available(iOS 11.0, *) {
            if contentHeight < view.height - tableView.adjustedContentInset.top {
                bottomView.y = view.height - bottomView.height - UIDevice.bottomMargin
            }else {
                bottomView.y = contentHeight - bottomView.height + 20
            }
        }else {
            bottomView.y = view.height - bottomView.height - UIDevice.bottomMargin
        }
        numberView.frame = .init(x: 0, y: 0, width: view.width, height: 20)
        filterLb.frame = .init(x: 0, y: 20, width: view.width, height: 20)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                tableView.reloadData()
                updateColors()
            }
        }
    }
}

class PhotoPickerFilterViewCell: UITableViewCell {
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView?.centerX = 30
        textLabel?.x = 60
    }
}

public class PhotoPickerFilterSection {
    var title: String?
    var rows: [Row]
    
    init(title: String? = nil, rows: [Row]) {
        self.title = title
        self.rows = rows
    }
    
    class Row {
        var title: String
        var options: Options
        var isSelected: Bool
        init(title: String, options: Options, isSelected: Bool = false) {
            self.title = title
            self.options = options
            self.isSelected = isSelected
        }
    }
    
    public struct Options: OptionSet {
        public static let photo = Options(rawValue: 1 << 1)
        public static let gif = Options(rawValue: 1 << 2)
        public static let livePhoto = Options(rawValue: 1 << 3)
        public static let video = Options(rawValue: 1 << 4)
        public static let edited = Options(rawValue: 1 << 5)
        public static let any = Options(rawValue: 1 << 6)
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
}
