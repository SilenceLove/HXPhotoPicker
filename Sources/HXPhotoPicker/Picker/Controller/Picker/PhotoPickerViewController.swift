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

public class PhotoPickerViewController: PhotoBaseViewController {
    let config: PhotoListConfiguration
    override init(config: PickerConfiguration) {
        self.config = config.photoList
        super.init(config: config)
    }
    public var photoToolbar: PhotoToolBar!
    
    var assetCollection: PhotoAssetCollection!
    var titleView: PhotoPickerNavigationTitle!
    var listView: PhotoPickerList!
    var albumBackgroudView: UIView!
    var albumView: PhotoAlbumList!
    var isShowToolbar: Bool = false
    var didInitViews: Bool = false
    var showLoading: Bool = false
    var orientationDidChange: Bool = false
    var isDisableLayout: Bool = false
    var isFirstLayout: Bool = true
    var appropriatePlaceAsset: PhotoAsset?
    var navigationBarHeight: CGFloat?
    weak var finishItem: PhotoNavigationItem?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        if let photoToolbar = config.photoToolbar {
            isShowToolbar = photoToolbar.isShow(pickerConfig, type: .picker)
        }else {
            isShowToolbar = false
        }
        initView()
        updateColors()
        fetchData()
    }
    
    public override func updateColors() {
        let isDark = PhotoManager.isDark
        view.backgroundColor = isDark ? config.backgroundDarkColor : config.backgroundColor
        if let listView = listView {
            listView.view.backgroundColor = isDark ? config.backgroundDarkColor : config.backgroundColor
        }
        let titleColor = isDark ?
        pickerConfig.navigationTitleDarkColor :
        pickerConfig.navigationTitleColor
        if let titleView = titleView {
            titleView.titleColor = titleColor
        }
    }
    
    public override func deviceOrientationWillChanged(notify: Notification) {
        orientationDidChange = true
    }
    
    public override func deviceOrientationDidChanged(notify: Notification) {
        if #available(iOS 14.5, *) {
            initNavItems()
        }
        photoToolbar.deviceOrientationDidChanged()
    }
    
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
        listView.view.frame = CGRect(x: margin, y: 0, width: collectionWidth, height: view.height)
        if pickerConfig.albumShowMode.isPop {
            albumBackgroudView.frame = view.bounds
            updateAlbumViewFrame()
            if orientationDidChange {
                titleView.updateFrame()
            }
        }
        layoutToolbar()
        if orientationDidChange {
            orientationDidChange = false
        }
        if isFirstLayout {
            listView.scrollTo(appropriatePlaceAsset)
            appropriatePlaceAsset = nil
            isFirstLayout = false
        }
    }
    
    func layoutToolbar() {
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
        if pickerConfig.isMultipleSelect {
            let bottomInset: CGFloat
            let bottomIndicatorInset: CGFloat
            if isShowToolbar {
                let viewHeight = photoToolbar.viewHeight
                photoToolbar.frame = .init(x: 0, y: view.height - viewHeight, width: view.width, height: viewHeight)
                bottomInset = photoToolbar.height + 0.5
                bottomIndicatorInset = viewHeight - UIDevice.bottomMargin
            }else {
                bottomInset = UIDevice.bottomMargin
                bottomIndicatorInset = UIDevice.bottomMargin
            }
            listView.contentInset = UIEdgeInsets(
                top: collectionTop,
                left: 0,
                bottom: bottomInset,
                right: 0
            )
            listView.scrollIndicatorInsets = UIEdgeInsets(
                top: 0,
                left: 0,
                bottom: bottomIndicatorInset,
                right: 0
            )
        }else {
            var promptHeight: CGFloat = UIDevice.bottomMargin
            if isShowToolbar {
                promptHeight = photoToolbar.viewHeight
                photoToolbar.frame = .init(x: 0, y: view.height - promptHeight, width: view.width, height: promptHeight)
            }
            listView.contentInset = UIEdgeInsets(
                top: collectionTop,
                left: 0,
                bottom: promptHeight,
                right: 0
            )
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isShowToolbar {
            photoToolbar.viewWillAppear(self)
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isShowToolbar {
            photoToolbar.viewDidAppear(self)
        }
        weakController?.setupDelegate()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isShowToolbar {
            photoToolbar.viewWillDisappear(self)
        }
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isShowToolbar {
            photoToolbar.viewDidDisappear(self)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        HXLog("PickerViewController deinited 👍")
    }
}

extension PhotoPickerViewController {
    
    func initView() {
        if didInitViews {
            return
        }
        didInitViews = true
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = .all
        if #unavailable(iOS 11.0) {
            automaticallyAdjustsScrollViewInsets = false
        }
        initListView()
        initToolbar()
        initAlbumView()
        initTitleView()
        updateTitle()
    }
    
    func initTitleView() {
        navigationItem.titleView = titleView
    }
    
    func initNavItems(_ addFilter: Bool = true) {
        let items = config.leftNavigationItems + config.rightNavigationItems
        var leftItems: [UIBarButtonItem] = []
        var rightItems: [UIBarButtonItem] = []
        for (index, item) in items.enumerated() {
            let isLeft = index < config.leftNavigationItems.count
            let view = item.init(config: pickerConfig)
            view.itemDelegate = self
            if view.itemType == .cancel {
                if let splitViewController = splitViewController as? PhotoSplitViewController,
                   splitViewController.isSplitShowColumn,
                   !UIDevice.isPad,
                   !UIDevice.isPortrait {
                    continue
                }
            }
            if view.itemType == .filter {
                if !addFilter || !config.isShowFilterItem {
                    continue
                }
                if !isLeft, config.rightNavigationItems.count > 1, view.size.width < 25 {
                    view.width += 10
                }
                view.isSelected = listView.filterOptions != .any
            }
            if view.itemType == .finish {
                finishItem = view
                if pickerConfig.isMultipleSelect {
                    view.selectedAssetDidChanged(pickerController.selectedAssetArray)
                }
            }
            if isLeft {
                leftItems.append(.init(customView: view))
            }else {
                rightItems.append(.init(customView: view))
            }
        }
        navigationItem.leftItemsSupplementBackButton = true
        if pickerConfig.albumShowMode.isPopView {
            if let splitViewController = splitViewController as? PhotoSplitViewController,
               UIDevice.isPad {
                if #unavailable(iOS 14.0) {
                    leftItems.insert(splitViewController.displayModeButtonItem, at: 0)
                }
            }
        }
        navigationItem.leftBarButtonItems = leftItems
        navigationItem.rightBarButtonItems = rightItems
    }
    
    @objc 
    func didCancelItemClick() {
        pickerController.cancelCallback()
    }
    
    func didFilterItemClick(modalPresentationStyle: UIModalPresentationStyle) {
        let vc: PhotoPickerFilterViewController
        if #available(iOS 13.0, *) {
            vc = PhotoPickerFilterViewController(style: .insetGrouped)
        } else {
            vc = PhotoPickerFilterViewController(style: .grouped)
        }
        vc.themeColor = config.filterThemeColor
        vc.themeDarkColor = config.filterThemeDarkColor
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
        nav.modalPresentationStyle = modalPresentationStyle
        present(nav, animated: true)
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
}

extension PhotoPickerViewController: PhotoNavigationItemDelegate {
    public func photoItem(presentFilterAssets photoItem: PhotoNavigationItem, modalPresentationStyle: UIModalPresentationStyle) {
        didFilterItemClick(modalPresentationStyle: modalPresentationStyle)
    }
}

extension PhotoPickerViewController: PhotoControllerEvent {
    public func photoControllerDidFinish() {
        pickerController.finishCallback()
    }
    public func photoControllerDidCancel() {
        pickerController.cancelCallback()
    }
}
