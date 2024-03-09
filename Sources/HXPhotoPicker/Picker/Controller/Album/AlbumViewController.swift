//
//  AlbumViewController.swift
//  照片选择器-Swift
//
//  Created by Silence on 2019/6/28.
//  Copyright © 2019年 Silence. All rights reserved.
//

import UIKit
import Photos

public class AlbumViewController: PhotoBaseViewController, PhotoAlbumListDelegate {
    
    public var listView: PhotoAlbumList!
    private var titleLabel: UILabel!
    private let config: AlbumListConfiguration
    private var assetCollections: [PhotoAssetCollection] = [] {
        didSet {
            if let listView = listView {
                if assetCollections.count == 1 {
                    listView.selectedAssetCollection = assetCollections.first
                }
                listView.assetCollections = assetCollections
            }
        }
    }
    private var orientationDidChange: Bool = false
    private var beforeOrientationRow: Int = 0
    private var selectedCollection: PhotoAssetCollection?
    
    override init(config: PickerConfiguration) {
        self.config = config.albumList
        super.init(config: config)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = .all
        initViews()
        initTitleView()
        initItems()
        updateColors()
    }
    
    public override func updateColors() {
        let isDark = PhotoManager.isDark
        if pickerController.splitType.isSplit {
            view.backgroundColor = isDark ? config.splitBackgroundDarkColor : config.splitBackgroundColor
        }else {
            view.backgroundColor = isDark ? config.backgroundDarkColor : config.backgroundColor
        }
        titleLabel.textColor = isDark ?
            pickerConfig.navigationTitleDarkColor :
            pickerConfig.navigationTitleColor
    }
    
    private func initViews() {
        listView = config.albumList.init(config: pickerController.config, isSplit: pickerController.splitType.isSplit)
        listView.delegate = self
        listView.assetCollections = assetCollections
        for collection in assetCollections where collection.isSelected {
            listView.selectedAssetCollection = collection
            break
        }
        view.addSubview(listView)
        
        titleLabel = UILabel()
        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.textAlignment = .center
    }
    
    private func initTitleView() {
        if UIDevice.isPortrait {
            navigationItem.titleView = titleLabel
        }else {
            if splitViewController != nil {
                if #unavailable(iOS 14.5) {
                    navigationItem.titleView = titleLabel
                }else {
                    navigationItem.titleView = nil
                }
            }else {
                navigationItem.titleView = titleLabel
            }
        }
    }
    
    func reloadData() {
        listView.reloadData()
    }
    
    func initItems() {
        let items = config.leftNavigationItems + config.rightNavigationItems
        var leftItems: [UIBarButtonItem] = []
        var rightItems: [UIBarButtonItem] = []
        for (index, item) in items.enumerated() {
            let view = item.init(config: pickerConfig)
            view.itemDelegate = self
            if index < config.leftNavigationItems.count {
                leftItems.append(.init(customView: view))
            }else {
                rightItems.append(.init(customView: view))
            }
        }
        if let titleLabel = titleLabel {
            titleLabel.text = .textManager.picker.albumList.navigationTitle.text
        }
        if UIDevice.isPad {
            if !pickerController.splitType.isSplit {
                title = .textManager.picker.albumList.backTitle.text
            }else {
                title = .textManager.picker.albumList.navigationTitle.text
                rightItems = []
            }
        }else {
            if let splitVC = splitViewController as? PhotoSplitViewController, !UIDevice.isPortrait {
                title = nil
                if splitVC.modalPresentationStyle == .fullScreen {
                    if #available(iOS 14.5, *) {
                        leftItems.append(contentsOf: rightItems)
                        rightItems = []
                    }
                }else {
                    rightItems = []
                }
            }else {
                title = .textManager.picker.albumList.backTitle.text
            }
        }
        navigationItem.leftBarButtonItems = leftItems
        navigationItem.rightBarButtonItems = rightItems
    }
    
    func reloadTableView(assetCollections: [PhotoAssetCollection]) {
        self.assetCollections = assetCollections
        if splitViewController is PhotoSplitViewController {
            for collection in self.assetCollections where collection.isSelected {
                selectedCollection = collection
                break
            }
        }else {
            if self.assetCollections.isEmpty {
                let assetCollection = PhotoAssetCollection(
                    albumName: .textManager.picker.albumList.emptyAlbumName.text,
                    coverImage: pickerConfig.emptyCoverImageName.image
                )
                if splitViewController is PhotoSplitViewController {
                    assetCollection.isSelected = true
                }
                self.assetCollections.append(assetCollection)
                selectedCollection = assetCollection
            }
        }
        if let listView = listView {
            if isDidLayoutViews {
                DispatchQueue.main.async {
                    listView.scroll(to: 0, animated: false)
                }
            }
        }
    }
    
    private func pushPhotoPickerController(
        assetCollection: PhotoAssetCollection?,
        animated: Bool
    ) {
        if let splitViewController = splitViewController as? PhotoSplitViewController {
            let pickerController: PhotoPickerController?
            if #available(iOS 14.0, *) {
                pickerController = splitViewController.viewController(for: .secondary) as? PhotoPickerController
                if !UIDevice.isPad, !splitViewController.isSplitShowColumn {
                    splitViewController.show(.secondary)
                }
            } else {
                pickerController = splitViewController.viewControllers.last as? PhotoPickerController
                if let photoVC = pickerController?.pickerViewController, !UIDevice.isPad, !splitViewController.isSplitShowColumn {
                    splitViewController.showDetailViewController(photoVC, sender: pickerController)
                }
            }
            pickerController?.reloadData(assetCollection: assetCollection)
            return
        }
        let photoVC = PhotoPickerViewController(config: pickerController.config)
        photoVC.assetCollection = assetCollection
        photoVC.showLoading = animated
        navigationController?.pushViewController(photoVC, animated: animated)
    }
    
    var isDidLayoutViews: Bool = false
    
    private func changeSubviewFrame() {
        var titleWidth: CGFloat = 0
        if let labelWidth = titleLabel.text?.width(ofFont: titleLabel.font, maxHeight: 30) {
            titleWidth = labelWidth
        }
        if titleWidth > view.width * 0.6 {
            titleWidth = view.width * 0.6
        }
        titleLabel.size = CGSize(width: titleWidth, height: 30)
        let margin: CGFloat = UIDevice.leftMargin
        let tableWidth: CGFloat
        if splitViewController != nil, !UIDevice.isPortrait, !UIDevice.isPad {
            tableWidth = view.width - margin
        }else {
            tableWidth = view.width - 2 * margin
        }
        listView.frame = CGRect(x: margin, y: 0, width: tableWidth, height: view.height)
        if let nav = navigationController {
            listView.contentInset = UIEdgeInsets(
                top: nav.navigationBar.frame.maxY,
                left: 0,
                bottom: UIDevice.bottomMargin,
                right: 0
            )
        }
        if orientationDidChange {
            if !assetCollections.isEmpty {
                DispatchQueue.main.async {
                    self.listView.scroll(to: self.beforeOrientationRow, animated: false)
                }
            }
            orientationDidChange = false
        }
        if !isDidLayoutViews {
            if !assetCollections.isEmpty {
                DispatchQueue.main.async {
                    self.listView.scroll(to: 0, animated: false)
                }
            }
            isDidLayoutViews = true
        }
    }
    public func albumList(
        _ albumList: PhotoAlbumList,
        didSelectAt index: Int,
        with assetCollection: PhotoAssetCollection
    ) {
        if let splitViewController = splitViewController as? PhotoSplitViewController {
            if let selectedCollection = selectedCollection,
               let selectedIndex = assetCollections.firstIndex(of: selectedCollection) {
                if index == selectedIndex && (splitViewController.isSplitShowColumn || UIDevice.isPad) {
                    return
                }
            }
        }
        selectedCollection = assetCollection
        pushPhotoPickerController(assetCollection: assetCollection, animated: true)
    }
    
    public override func deviceOrientationWillChanged(notify: Notification) {
        orientationDidChange = true
        initItems()
        initTitleView()
        if let listView = listView {
            beforeOrientationRow = listView.middleIndex
        }
    }
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        changeSubviewFrame()
    }
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.popoverPresentationController?.delegate = self as?
            UIPopoverPresentationControllerDelegate
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AlbumViewController: PhotoNavigationItemDelegate {
    
    public func photoControllerDidCancel() {
        pickerController.cancelCallback()
    }
    
    public func photoControllerDidFinish() {
        pickerController.finishCallback()
    }
}
