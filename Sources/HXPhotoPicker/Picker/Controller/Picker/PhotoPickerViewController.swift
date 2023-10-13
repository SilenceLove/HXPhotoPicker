//
//  PhotoPickerViewController.swift
//  照片选择器-Swift
//
//  Created by Silence on 2019/6/29.
//  Copyright © 2019年 Silence. All rights reserved.
//

import UIKit
import MobileCoreServices
import AVFoundation
import Photos

public class PhotoPickerViewController: BaseViewController, PhotoPickerControllerFectch {
    let pickerConfig: PickerConfiguration
    let config: PhotoListConfiguration
    init(config: PickerConfiguration) {
        self.config = config.photoList
        self.pickerConfig = config
        super.init(nibName: nil, bundle: nil)
    }
    var assetCollection: PhotoAssetCollection!
    var titleView: PhotoPickerNavigationTitle!
    var listView: PhotoPickerList!
    var albumBackgroudView: UIView!
    var albumView: PhotoAlbumList!
    var photoToolbar: PhotoToolBar!
    
    var showLoading: Bool = false
    
    var orientationDidChange: Bool = false
    var beforeOrientationIndexPath: IndexPath?
    
    var allowShowPrompt: Bool {
        config.bottomView.isShowPrompt &&
        AssetManager.authorizationStatusIsLimited() &&
        pickerConfig.allowLoadPhotoLibrary
    }
    
    weak var tmpPickerController: PhotoPickerController?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        initView()
        configColor()
        fetchData()
        tmpPickerController = pickerController
    }
    
    public override func deviceOrientationWillChanged(notify: Notification) {
        orientationDidChange = true
        let items = listView.collectionView.indexPathsForVisibleItems.sorted { $0.item < $1.item }
        if !items.isEmpty {
            if items.last?.item == listView.numberOfItems - 1 {
                beforeOrientationIndexPath = items.last
                return
            }
            if items.first?.item == 0 {
                beforeOrientationIndexPath = items.first
                return
            }
            let startItem = items.first?.item ?? 0
            let endItem = items.last?.item ?? 0
            if let beforeItem = beforeOrientationIndexPath?.item,
               beforeItem >= startItem, beforeItem <= endItem {
                return
            }
            let middleIndex = min(items.count - 1, max(0, items.count / 2))
            beforeOrientationIndexPath = items[middleIndex]
        }
    }
    
    public override func deviceOrientationDidChanged(notify: Notification) {
        if #available(iOS 14.5, *) {
            initNavItems()
        }
    }
    
    var isDisableLayout: Bool = false
    var isFirstLayout: Bool = true
    var appropriatePlaceAsset: PhotoAsset?
    var navigationBarHeight: CGFloat?
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if isDisableLayout {
            isDisableLayout = false
            return
        }
        let margin: CGFloat
        let collectionWidth: CGFloat
        if let splitViewController = splitViewController as? PhotoSplitViewController, !UIDevice.isPortrait, !UIDevice.isPad {
            if !splitViewController.isSplitShowColumn {
                margin = UIDevice.leftMargin
                collectionWidth = view.width - margin * 2
            }else {
                margin = 0
                collectionWidth = view.width - UIDevice.rightMargin
            }
        }else {
            margin = UIDevice.leftMargin
            collectionWidth = view.width - 2 * margin
        }
        listView.frame = CGRect(x: margin, y: 0, width: collectionWidth, height: view.height)
        var collectionTop: CGFloat = UIDevice.navigationBarHeight
        if let nav = navigationController {
            if nav.modalPresentationStyle == .fullScreen && UIDevice.isPortrait {
                if UIApplication.shared.isStatusBarHidden {
                    if let navigationBarHeight = navigationBarHeight {
                        collectionTop = navigationBarHeight
                    }else {
                        collectionTop = nav.navigationBar.height + UIDevice.generalStatusBarHeight
                    }
                }else {
                    collectionTop = nav.navigationBar.frame.maxY
                    if collectionTop.isLessThanOrEqualTo(0) {
                        if let albumVC = splitViewController?.viewControllers.first as? UINavigationController {
                            collectionTop = albumVC.navigationBar.frame.maxY
                        }else {
                            collectionTop = UIDevice.navBarHeight + UIDevice.generalStatusBarHeight
                        }
                    }
                    navigationBarHeight = collectionTop
                }
            }else {
                collectionTop = nav.navigationBar.frame.maxY
                if collectionTop.isLessThanOrEqualTo(0) {
                    if let albumVC = splitViewController?.viewControllers.first as? UINavigationController {
                        collectionTop = albumVC.navigationBar.frame.maxY
                    }else {
                        collectionTop = UIDevice.navBarHeight
                    }
                }
            }
        }
        if pickerConfig.albumShowMode == .popup {
            albumBackgroudView.frame = view.bounds
            updateAlbumViewFrame()
            if orientationDidChange {
                titleView.updateFrame()
            }
        }
        var promptHeight: CGFloat = UIDevice.bottomMargin
        if pickerConfig.isMultipleSelect {
            let bottomHeight: CGFloat = photoToolbar.viewHeight()
            photoToolbar.frame = .init(x: 0, y: view.height - bottomHeight, width: view.width, height: bottomHeight)
            listView.contentInset = UIEdgeInsets(
                top: collectionTop,
                left: 0,
                bottom: photoToolbar.height + 0.5,
                right: 0
            )
            listView.scrollIndicatorInsets = UIEdgeInsets(
                top: 0,
                left: 0,
                bottom: bottomHeight - UIDevice.bottomMargin,
                right: 0
            )
        }else {
            if allowShowPrompt {
                promptHeight = photoToolbar.viewHeight()
                photoToolbar.frame = .init(x: 0, y: view.height - promptHeight, width: view.width, height: promptHeight)
            }
            listView.contentInset = UIEdgeInsets(
                top: collectionTop,
                left: 0,
                bottom: promptHeight,
                right: 0
            )
        }
        if orientationDidChange {
            listView.reloadData()
            if navigationController?.topViewController == self {
                DispatchQueue.main.async {
                    if let indexPath = self.beforeOrientationIndexPath {
                        self.listView.scrollTo(at: indexPath, at: .centeredVertically, animated: false)
                    }
                }
            }
            orientationDidChange = false
        }
        if isFirstLayout {
            listView.scrollTo(appropriatePlaceAsset)
            appropriatePlaceAsset = nil
            isFirstLayout = false
        }
    }
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        pickerController.viewControllersWillAppear(self)
    }
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        pickerController.viewControllersDidAppear(self)
    }
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pickerController.viewControllersWillDisappear(self)
    }
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        tmpPickerController?.viewControllersDidDisappear(self)
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

extension PhotoPickerViewController {
    
    private func initView() {
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = .all
        if #unavailable(iOS 11.0) {
            automaticallyAdjustsScrollViewInsets = false
        }
        listView = config.listView.init(config: pickerConfig)
        listView.delegate = self
        view.addSubview(listView)
        
        initToolbar()
        initAlbumView()
        initTitleView()
        updateTitle()
    }
    
    func initTitleView() {
        navigationItem.titleView = titleView
    }
    
    func initNavItems(_ addFilter: Bool = true) {
        navigationItem.leftBarButtonItem = nil
        navigationItem.leftBarButtonItems = []
        navigationItem.rightBarButtonItem = nil
        navigationItem.rightBarButtonItems = []
        
        let filterImageName: String
        if listView.filterOptions == .any {
            filterImageName = "hx_picker_photolist_nav_filter_normal"
        }else {
            filterImageName = "hx_picker_photolist_nav_filter_selected"
        }
        let filterItem = UIBarButtonItem(
            image: filterImageName.image,
            style: .done,
            target: self,
            action: #selector(didFilterItemClick)
        )
        if pickerConfig.albumShowMode == .popup {
            let cancelItem: UIBarButtonItem
            if config.cancelType == .text {
                cancelItem = UIBarButtonItem(
                    title: "取消".localized,
                    style: .done,
                    target: self,
                    action: #selector(didCancelItemClick)
                )
            }else {
                cancelItem = UIBarButtonItem(
                    image: UIImage.image(
                        for: PhotoManager.isDark ?
                            config.cancelDarkImageName :
                            config.cancelImageName
                    ),
                    style: .done,
                    target: self,
                    action: #selector(didCancelItemClick)
                )
            }
            if config.cancelPosition == .left {
                if let splitViewController = splitViewController as? PhotoSplitViewController {
                    if UIDevice.isPad {
                        if #unavailable(iOS 14.0) {
                            navigationItem.leftBarButtonItems = [splitViewController.displayModeButtonItem, cancelItem]
                        }else {
                            navigationItem.leftBarButtonItem = cancelItem
                        }
                        if config.isShowFilterItem, addFilter {
                            navigationItem.rightBarButtonItem = filterItem
                        }
                    }else {
                        if UIDevice.isPortrait {
                            if config.isShowFilterItem, addFilter {
                                navigationItem.rightBarButtonItems = [cancelItem, filterItem]
                            }else {
                                navigationItem.rightBarButtonItem = cancelItem
                            }
                        }else {
                            if splitViewController.isSplitShowColumn {
                                if config.isShowFilterItem, addFilter {
                                    navigationItem.rightBarButtonItem = filterItem
                                }
                            }else {
                                navigationItem.leftBarButtonItem = cancelItem
                            }
                        }
                    }
                }else {
                    navigationItem.leftBarButtonItem = cancelItem
                    if config.isShowFilterItem, addFilter {
                        navigationItem.rightBarButtonItem = filterItem
                    }
                }
            }else {
                if let splitViewController = splitViewController as? PhotoSplitViewController, #unavailable(iOS 14.0) {
                    navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
                }
                if config.isShowFilterItem, addFilter {
                    if #available(iOS 14.5, *), let splitViewController = splitViewController as? PhotoSplitViewController, !UIDevice.isPad, splitViewController.isSplitShowColumn {
                        navigationItem.rightBarButtonItems = [filterItem]
                    }else {
                        navigationItem.rightBarButtonItems = [cancelItem, filterItem]
                    }
                }else {
                    if #available(iOS 14.5, *), let splitViewController = splitViewController as? PhotoSplitViewController, !UIDevice.isPad, splitViewController.isSplitShowColumn {
                        navigationItem.rightBarButtonItem = nil
                    }else {
                        navigationItem.rightBarButtonItem = cancelItem
                    }
                }
            }
        }else {
            let cancelItem = UIBarButtonItem(
                title: "取消".localized,
                style: .done,
                target: self,
                action: #selector(didCancelItemClick)
            )
            if config.isShowFilterItem, addFilter {
                navigationItem.rightBarButtonItems = [cancelItem, filterItem]
            }else {
                navigationItem.rightBarButtonItem = cancelItem
            }
        }
    }
    private func configColor() {
        let isDark = PhotoManager.isDark
        view.backgroundColor = isDark ? config.backgroundDarkColor : config.backgroundColor
        if let listView = listView {
            listView.backgroundColor = isDark ? config.backgroundDarkColor : config.backgroundColor
        }
        let titleColor = isDark ?
            pickerConfig.navigationTitleDarkColor :
            pickerConfig.navigationTitleColor
        if let titleView = titleView {
            titleView.titleColor = titleColor
        }
    }
    func updateTitle() {
        guard let titleView = titleView else { return }
        titleView.title = assetCollection?.albumName
    }
    func scrollToAppropriatePlace(photoAsset: PhotoAsset?) {
        if isFirstLayout {
            appropriatePlaceAsset = photoAsset
            return
        }
        listView.scrollTo(photoAsset)
    }
    
    func changedAssetCollection(collection: PhotoAssetCollection?) {
        ProgressHUD.showLoading(
            addedTo: navigationController?.view,
            animated: true
        )
        if let collection = collection {
            if pickerConfig.albumShowMode == .popup {
                assetCollection.isSelected = false
                collection.isSelected = true
            }
            assetCollection = collection
        }
        updateTitle()
        fetchPhotoAssets()
        reloadAlbumData()
    }
    func reloadAlbumData() {
        if pickerConfig.albumShowMode == .popup {
            albumView.reloadData()
        }
    }
    
    @objc func didCancelItemClick() {
        pickerController.cancelCallback()
    }
    
    @objc
    func didFilterItemClick() {
        let vc: PhotoPickerFilterViewController
        if #available(iOS 13.0, *) {
            vc = PhotoPickerFilterViewController(style: .insetGrouped)
        } else {
            vc = PhotoPickerFilterViewController(style: .grouped)
        }
        vc.selectOptions = pickerConfig.selectOptions
        #if HXPICKER_ENABLE_EDITOR
        vc.editorOptions = pickerConfig.editorOptions
        #endif
        vc.selectMode = pickerConfig.selectMode
        
        vc.photoCount = listView.photoCount
        vc.videoCount = listView.videoCount
        vc.options = listView.filterOptions
        vc.didSelectedHandler = { [weak self] in
            guard let self = self else {
                return
            }
            self.listView.filterOptions = $0.options
            self.initNavItems()
            $0.photoCount = self.listView.photoCount
            $0.videoCount = self.listView.videoCount
        }
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }
}
