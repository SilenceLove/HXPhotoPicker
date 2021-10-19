//
//  AlbumView.swift
//  HXPHPickerExample
//
//  Created by Silence on 2020/11/17.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

protocol AlbumViewDelegate: AnyObject {
    func albumView(_ albumView: AlbumView, didSelectRowAt assetCollection: PhotoAssetCollection)
}

class AlbumView: UIView, UITableViewDataSource, UITableViewDelegate {
    
    weak var delegate: AlbumViewDelegate?
    
    lazy var tableView: UITableView = {
        let tableView = UITableView.init(frame: CGRect.init(), style: .plain)
        if AssetManager.authorizationStatusIsLimited() {
            tableView.tableHeaderView = promptLb
        }
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        if let customCellClass = config.customCellClass {
            tableView.register(customCellClass, forCellReuseIdentifier: "AlbumViewCellID")
        }else {
            tableView.register(AlbumViewCell.self, forCellReuseIdentifier: "AlbumViewCellID")
        }
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        }
        return tableView
    }()
    lazy var promptLb: UILabel = {
        let promptLb = UILabel.init(frame: CGRect(x: 0, y: 0, width: 0, height: 40))
        promptLb.text = "只能查看允许访问的照片和相关相册".localized
        promptLb.textAlignment = .center
        promptLb.font = UIFont.systemFont(ofSize: 14)
        promptLb.adjustsFontSizeToFitWidth = true
        promptLb.numberOfLines = 0
        return promptLb
    }()
    var config: AlbumListConfiguration
    var assetCollectionsArray: [PhotoAssetCollection] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    private var currentSelectedRow: Int = 0
    var currentSelectedAssetCollection: PhotoAssetCollection? {
        didSet {
            if currentSelectedAssetCollection != nil {
                currentSelectedRow = assetCollectionsArray.firstIndex(of: currentSelectedAssetCollection!) ?? 0
            }
        }
    }
    
    init(config: AlbumListConfiguration) {
        self.config = config
        super.init(frame: CGRect.zero)
        addSubview(tableView)
        configColor()
    }
    func scrollToMiddle() {
        if assetCollectionsArray.isEmpty {
            return
        }
        let indexPath = IndexPath(row: currentSelectedRow, section: 0)
        tableView.scrollToRow(at: indexPath, at: .middle, animated: false)
    }
    func configColor() {
        tableView.backgroundColor = PhotoManager.isDark ? config.backgroundDarkColor : config.backgroundColor
        backgroundColor = PhotoManager.isDark ? config.backgroundDarkColor : config.backgroundColor
        promptLb.textColor = PhotoManager.isDark ? config.limitedStatusPromptDarkColor : config.limitedStatusPromptColor
    }
    func updatePrompt() {
        if AssetManager.authorizationStatusIsLimited() {
            tableView.tableHeaderView = promptLb
        }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return assetCollectionsArray.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AlbumViewCellID") as! AlbumViewCell
        let assetCollection = assetCollectionsArray[indexPath.row]
        cell.assetCollection = assetCollection
        cell.config = config
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return config.cellHeight
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let assetCollection = assetCollectionsArray[indexPath.row]
        currentSelectedAssetCollection = assetCollection
        delegate?.albumView(self, didSelectRowAt: assetCollection)
        tableView.reloadData()
    }
    
//    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        let myCell: AlbumViewCell = cell as! AlbumViewCell
//        myCell.cancelRequest()
//    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if AssetManager.authorizationStatusIsLimited() {
            promptLb.width = width
        }
        tableView.frame = bounds
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                configColor()
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
