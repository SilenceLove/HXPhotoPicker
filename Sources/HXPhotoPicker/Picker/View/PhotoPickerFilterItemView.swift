//
//  PhotoPickerFilterItemView.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/10/22.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit

public class PhotoPickerFilterItemView: UIView, PhotoNavigationItem {
    public weak var itemDelegate: PhotoNavigationItemDelegate?
    public var isSelected: Bool = false {
        didSet {
            button.isSelected = isSelected
        }
    }
    public var itemType: PhotoNavigationItemType { .filter }
    
    let config: PickerConfiguration
    public required init(config: PickerConfiguration) {
        self.config = config
        super.init(frame: .zero)
        initView()
    }
    
    var button: UIButton!
    func initView() {
        button = UIButton(type: .custom)
        button.setImage(.imageResource.picker.photoList.filterNormal.image?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setImage(.imageResource.picker.photoList.filterSelected.image?.withRenderingMode(.alwaysTemplate), for: .selected)
        if #available(iOS 26.0, *), !PhotoManager.isIos26Compatibility {
            button.configuration = config.photoList.filterButtonConfig
        }else {
            button.addTarget(self, action: #selector(didFilterClick), for: .touchUpInside)
        }
        addSubview(button)
        setColor()
    }
    
    func setColor() {
        guard let color = PhotoManager.isDark ? config.navigationDarkTintColor : config.navigationTintColor else {
            return
        }
        button.imageView?.tintColor = color
    }
    
    @objc
    func didFilterClick() {
        if #available(iOS 13.0, *) {
            itemDelegate?.photoItem(presentFilterAssets: self, modalPresentationStyle: .automatic)
        } else {
            itemDelegate?.photoItem(presentFilterAssets: self, modalPresentationStyle: .fullScreen)
        }
    }
    
    var filterDada: PhotoNavigationFilterData?
    var handler: ((PhotoPickerFilterSection.Options) -> Void)?
    public func makeFilterData(_ data: PhotoNavigationFilterData, handler: @escaping (PhotoPickerFilterSection.Options) -> Void) {
        if #available(iOS 26.0, *) {
            filterDada = data
            self.handler = handler
            button.menu = makeMenu()
            button.showsMenuAsPrimaryAction = true
        }
    }
    
    @available(iOS 26.0, *)
    func makeMenu() -> UIMenu? {
        guard let data = filterDada else {
            return nil
        }
        let options = data.options
        let selectOptions = data.selectOptions
        let selectMode = data.selectMode
        let editorOptions = data.editorOptions
        var sections: [PhotoPickerFilterSection] = []
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
        var menus: [UIMenu] = []
        for section in sections {
            var actions: [UIAction] = []
            for row in section.rows {
                let id = UIAction.Identifier("\(row.options.rawValue)")
                let action = UIAction(title: row.title, image: row.image, identifier: id, state: row.isSelected ? .on : .off, handler: { [weak self] action in
                    guard let self else { return }
                    if let optionsRow = Int(action.identifier.rawValue) {
                        let options = PhotoPickerFilterSection.Options.init(rawValue: optionsRow)
                        switch options {
                        case .any:
                            if action.state == .on {
                                return
                            }
                            self.filterDada?.options = .any
                        default:
                            if action.state == .off {
                                if let _options = self.filterDada?.options, _options == .any {
                                    self.filterDada?.options = []
                                }
                                self.filterDada?.options.insert(options)
                            }else {
                                self.filterDada?.options.remove(options)
                                if let _options = filterDada?.options {
                                    var isAllUnselect = true
                                    if _options.contains(.edited) {
                                        isAllUnselect = false
                                    }
                                    if _options.contains(.photo) {
                                        isAllUnselect = false
                                    }
                                    if _options.contains(.gif) {
                                        isAllUnselect = false
                                    }
                                    if _options.contains(.livePhoto) {
                                        isAllUnselect = false
                                    }
                                    if _options.contains(.video) {
                                        isAllUnselect = false
                                    }
                                    if isAllUnselect {
                                        self.filterDada?.options = .any
                                    }
                                }
                            }
                        }
                        if let options = self.filterDada?.options {
                            self.isSelected = options != .any
                            self.handler?(options)
                        }
                        self.button.menu = self.makeMenu()
                    }
                })
                action.attributes.insert(.keepsMenuPresented)
                actions.append(action)
            }
            menus.append(.init(options: .displayInline, children: actions))
        }
        return UIMenu(title: .textPhotoList.filter.title.text, children: menus)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        let buttonSize = CGSize(width: button.sizeThatFits(self.bounds.size).width - 4, height: button.sizeThatFits(self.bounds.size).height - 4)
        button.frame = CGRect(
            x: (self.bounds.width - buttonSize.width) / 2,
            y: (self.bounds.height - buttonSize.height) / 2,
            width: buttonSize.width,
            height: buttonSize.height
        )
    }
    
    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        return button.sizeThatFits(size)
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                setColor()
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
