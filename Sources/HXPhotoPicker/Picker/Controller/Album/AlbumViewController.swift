//
//  AlbumViewController.swift
//  照片选择器-Swift
//
//  Created by Silence on 2019/6/28.
//  Copyright © 2019年 Silence. All rights reserved.
//

import UIKit
import Photos

public class AlbumViewController: BaseViewController, PhotoPickerControllerFectch, PhotoAlbumListDelegate {
    
    var listView: PhotoAlbumList!
    private var titleLabel: UILabel!
    
    private let config: AlbumListConfiguration
    private var assetCollectionsArray: [PhotoAssetCollection] = [] {
        didSet {
            if let listView = listView {
                if assetCollectionsArray.count == 1 {
                    listView.selectedAssetCollection = assetCollectionsArray.first
                }
                listView.assetCollections = assetCollectionsArray
            }
        }
    }
    private var orientationDidChange: Bool = false
    private var beforeOrientationRow: Int = 0
    private var canFetchAssetCollections: Bool = false
    private var selectedCollection: PhotoAssetCollection?
    
    init(config: AlbumListConfiguration) {
        self.config = config
        super.init(nibName: nil, bundle: nil)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = .all
        initViews()
        initTitleView()
        initItems()
        configColor()
        if !pickerController.splitType.isSplit {
            fetchCameraAssetCollection()
        }else {
            if let splitViewController = splitViewController as? PhotoSplitViewController {
                if !splitViewController.assetCollections.isEmpty {
                    listView.selectedAssetCollection = splitViewController.cameraAssetCollection
                    reloadTableView(assetCollectionsArray: splitViewController.assetCollections)
                }else if let collection = splitViewController.cameraAssetCollection {
                    reloadTableView(assetCollectionsArray: [collection])
                }
            }
        }
    }
    
    private func initViews() {
        listView = config.albumList.init(config: pickerController.config, isSplit: pickerController.splitType.isSplit)
        listView.delegate = self
        listView.assetCollections = assetCollectionsArray
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
    
    private func initItems() {
        let backItem = UIBarButtonItem(
            title: "取消".localized,
            style: .done,
            target: self,
            action: #selector(didCancelItemClick)
        )
        if let titleLabel = titleLabel {
            titleLabel.text = "相册".localized
        }
        navigationItem.rightBarButtonItems = []
        navigationItem.leftBarButtonItem = nil
        if UIDevice.isPad {
            if !pickerController.splitType.isSplit {
                title = "返回".localized
                navigationItem.rightBarButtonItem = backItem
            }else {
                title = "相册".localized
                navigationItem.rightBarButtonItem = nil
            }
        }else {
            if !UIDevice.isPortrait && pickerController.splitType.isSplit {
                title = nil
                navigationItem.rightBarButtonItem = nil
                if #available(iOS 14.5, *) {
                    navigationItem.leftBarButtonItem = backItem
                }
            }else {
                title = "返回".localized
                navigationItem.rightBarButtonItem = backItem
            }
        }
    }
    
    func updatePrompt() {
        listView.reloadData()
    }
    
    private func configColor() {
        let isDark = PhotoManager.isDark
        if pickerController.splitType.isSplit {
            view.backgroundColor = isDark ? config.splitBackgroundDarkColor : config.splitBackgroundColor
        }else {
            view.backgroundColor = isDark ? config.backgroundDarkColor : config.backgroundColor
        }
        titleLabel.textColor = isDark ?
            pickerController.config.navigationTitleDarkColor :
            pickerController.config.navigationTitleColor
    }
    private func fetchCameraAssetCollection() {
        let fetchData = pickerController.fetchData
        if let cameraAssetCollection = fetchData.cameraAssetCollection {
            selectedCollection = cameraAssetCollection
            pushPhotoPickerController(
                assetCollection: cameraAssetCollection,
                animated: false
            )
            canFetchAssetCollections = true
            titleLabel.text = "相册".localized
        }else {
            fetchData.fetchCameraAssetCollectionCompletion = { [weak self] assetCollection in
                var cameraAssetCollection = assetCollection
                if cameraAssetCollection == nil {
                    cameraAssetCollection = PhotoAssetCollection(
                        albumName: self?.config.emptyAlbumName.localized,
                        coverImage: self?.config.emptyCoverImageName.image
                    )
                }
                self?.canFetchAssetCollections = true
                self?.titleLabel.text = "相册".localized
                
                self?.selectedCollection = cameraAssetCollection
                if let topViewController = self?.navigationController?.topViewController as? PhotoPickerViewController {
                    topViewController.changedAssetCollection(
                        collection: cameraAssetCollection
                    )
                    return
                }
                self?.pushPhotoPickerController(
                    assetCollection: cameraAssetCollection,
                    animated: false
                )
            }
        }
    }
    
    private func fetchAssetCollections() {
        ProgressHUD.showLoading(addedTo: view, animated: true)
        pickerController.fetchData.fetchAssetCollections()
        pickerController
            .fetchData.fetchAssetCollectionsCompletion = { [weak self] assetCollectionsArray in
                self?.reloadTableView(assetCollectionsArray: assetCollectionsArray)
                ProgressHUD.hide(forView: self?.view, animated: true)
            }
    }
    func reloadTableView(assetCollectionsArray: [PhotoAssetCollection]) {
        self.assetCollectionsArray = assetCollectionsArray
        if splitViewController is PhotoSplitViewController {
            for collection in self.assetCollectionsArray where collection.isSelected {
                selectedCollection = collection
                break
            }
        }else {
            if self.assetCollectionsArray.isEmpty {
                let assetCollection = PhotoAssetCollection(
                    albumName: config.emptyAlbumName.localized,
                    coverImage: config.emptyCoverImageName.image
                )
                if splitViewController is PhotoSplitViewController {
                    assetCollection.isSelected = true
                }
                self.assetCollectionsArray.append(assetCollection)
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
    
    @objc
    private func didCancelItemClick() {
        pickerController.cancelCallback()
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
            if !assetCollectionsArray.isEmpty {
                DispatchQueue.main.async {
                    self.listView.scroll(to: self.beforeOrientationRow, animated: false)
                }
            }
            orientationDidChange = false
        }
        if !isDidLayoutViews {
            if !assetCollectionsArray.isEmpty {
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
               let selectedIndex = assetCollectionsArray.firstIndex(of: selectedCollection) {
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
        pickerController.viewControllersWillAppear(self)
    }
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if assetCollectionsArray.isEmpty && canFetchAssetCollections {
            fetchAssetCollections()
        }
        pickerController.viewControllersDidAppear(self)
    }
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pickerController.viewControllersWillDisappear(self)
    }
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        pickerController.viewControllersDidDisappear(self)
    }
    public override var prefersStatusBarHidden: Bool {
        return false
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
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
