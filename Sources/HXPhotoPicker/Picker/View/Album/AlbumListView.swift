//
//  AlbumListView.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/10/9.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit

open class AlbumListView: UIView, PhotoAlbumList, UITableViewDataSource, UITableViewDelegate {
    
    public weak var delegate: PhotoAlbumListDelegate?
    
    public var contentInset: UIEdgeInsets = .zero {
        didSet {
            tableView.contentInset = contentInset
        }
    }
    
    public var middleIndex: Int {
        let rows = tableView.indexPathsForVisibleRows?.sorted { $0.row < $1.row }
        guard let rows = rows, !rows.isEmpty else {
            return 0
        }
        if rows.last?.row == assetCollections.count - 1 {
            return rows[rows.count - 1].row
        }
        if rows.first?.row == 0 {
            return rows[0].row
        }
        let startRow = rows.first?.row ?? 0
        let endRow = rows.last?.row ?? 0
        if lastMiddleIndex >= startRow, lastMiddleIndex <= endRow {
            return lastMiddleIndex
        }
        let middleIndex = min(rows.count - 1, max(0, rows.count / 2))
        lastMiddleIndex = rows[middleIndex].row
        return lastMiddleIndex
    }
    
    public var assetCollections: [PhotoAssetCollection] = [] {
        didSet {
            reloadData()
        }
    }
    
    public var selectedAssetCollection: PhotoAssetCollection? {
        willSet {
            selectedAssetCollection?.isSelected = false
            updateCellSelected(for: selectedAssetCollection, isSelected: false)
        }
        didSet {
            selectedAssetCollection?.isSelected = true
            updateCellSelected(for: selectedAssetCollection, isSelected: true)
        }
    }
    
    public var config: PickerConfiguration
    public let isSplit: Bool
    public var tableView: UITableView!
    public var lastMiddleIndex: Int = 0
    
    required public init(config: PickerConfiguration, isSplit: Bool) {
        self.config = config
        self.isSplit = isSplit
        super.init(frame: .zero)
        initViews()
        configColor()
    }
    public func initViews() {
        tableView = UITableView(frame: .zero, style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.register(AlbumSectionHeaderView.self, forHeaderFooterViewReuseIdentifier: AlbumSectionHeaderView.className)
        if let customCellClass = config.albumList.customCellClass {
            tableView.register(customCellClass, forCellReuseIdentifier: AlbumViewBaseCell.className)
        }else {
            tableView.register(AlbumViewCell.self, forCellReuseIdentifier: AlbumViewBaseCell.className)
        }
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        }
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        addSubview(tableView)
    }
    
    func updateCellSelected(for collection: PhotoAssetCollection?, isSelected: Bool) {
        if let collection = collection,
           let index = assetCollections.firstIndex(of: collection) {
            let cell = tableView.cellForRow(at: .init(row: index, section: 0)) as? AlbumViewBaseCell
            cell?.updateSelectedStatus(isSelected)
        }
    }
    
    public func configColor() {
        let config = config.albumList
        if isSplit {
            tableView.backgroundColor = PhotoManager.isDark ? config.splitBackgroundDarkColor : config.splitBackgroundColor
            self.config.albumList.cellBackgroundColor = config.splitBackgroundColor
            self.config.albumList.cellBackgroundDarkColor = config.splitBackgroundDarkColor
        }else {
            tableView.backgroundColor = PhotoManager.isDark ? config.backgroundDarkColor : config.backgroundColor
        }
        backgroundColor = tableView.backgroundColor
    }
    
    public func scrollSelectToMiddle() {
        guard let collection = selectedAssetCollection,
              let index = assetCollections.firstIndex(of: collection) else {
            return
        }
        let indexPath = IndexPath(row: index, section: 0)
        tableView.scrollToRow(at: indexPath, at: .middle, animated: false)
    }
    
    public func reloadData() {
        tableView.reloadData()
    }
    
    public func scroll(to index: Int, animated: Bool) {
        if assetCollections.isEmpty { return }
        let indexPath = IndexPath(row: index, section: 0)
        tableView.scrollToRow(at: indexPath, at: .top, animated: animated)
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        assetCollections.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: AlbumViewBaseCell = tableView.dequeueReusableCell()
        cell.assetCollection = assetCollections[indexPath.row]
        cell.config = config.albumList
        return cell
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if isSplit {
            if UIDevice.isPad {
                return config.albumList.splitCellHeight
            }else {
                if !UIDevice.isPortrait {
                    return config.albumList.splitCellHeight
                }
            }
        }
        return config.albumList.cellHeight
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let assetCollection = assetCollections[indexPath.row]
        selectedAssetCollection = assetCollection
        delegate?.albumList(self, didSelectAt: indexPath.row, with: assetCollection)
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if config.allowLoadPhotoLibrary, AssetPermissionsUtil.isLimitedAuthorizationStatus {
            return 40
        }
        return 0
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if config.allowLoadPhotoLibrary, AssetPermissionsUtil.isLimitedAuthorizationStatus {
            let config = config.albumList
            let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: AlbumSectionHeaderView.className) as! AlbumSectionHeaderView
            view.titleColor = config.limitedStatusPromptColor
            view.titleDarkColor = config.limitedStatusPromptDarkColor
            view.bgColor = config.cellBackgroundColor
            view.bgDarkColor = config.cellBackgroundDarkColor
            view.updateColor()
            return view
        }
        return nil
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        tableView.frame = bounds
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                configColor()
            }
        }
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
