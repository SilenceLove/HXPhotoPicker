//
//  AlbumViewController.swift
//  照片选择器-Swift
//
//  Created by Silence on 2019/6/28.
//  Copyright © 2019年 Silence. All rights reserved.
//

import UIKit
import Photos

public class AlbumViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    var tableView: UITableView!
    private var promptLb: UILabel!
    private var titleLabel: UILabel!
    
    private let config: AlbumListConfiguration
    private var assetCollectionsArray: [PhotoAssetCollection] = []
    private var orientationDidChange: Bool = false
    private var beforeOrientationIndexPath: IndexPath?
    private var canFetchAssetCollections: Bool = false
    
    init(config: AlbumListConfiguration) {
        self.config = config
        super.init(nibName: nil, bundle: nil)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        guard let picker = pickerController else { return }
        initViews()
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = .all
        title = "返回".localized
        navigationItem.titleView = titleLabel
        let backItem = UIBarButtonItem(
            title: "取消".localized,
            style: .done,
            target: self,
            action: #selector(didCancelItemClick)
        )
        navigationItem.rightBarButtonItem = backItem
        view.addSubview(tableView)
        if AssetManager.authorizationStatusIsLimited() &&
            picker.config.allowLoadPhotoLibrary {
            tableView.tableHeaderView = promptLb
        }
        configColor()
        fetchCameraAssetCollection()
    }
    
    private func initViews() {
        tableView = UITableView(
            frame: .zero,
            style: .plain
        )
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.register(
            AlbumViewCell.self,
            forCellReuseIdentifier: "cellId"
        )
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        } else {
            self.automaticallyAdjustsScrollViewInsets = false
        }
        
        promptLb = UILabel(
            frame: CGRect(x: 0, y: 0, width: 0, height: 40)
        )
        promptLb.text = "只能查看允许访问的照片和相关相册".localized
        promptLb.textAlignment = .center
        promptLb.font = UIFont.systemFont(ofSize: 14)
        promptLb.adjustsFontSizeToFitWidth = true
        promptLb.numberOfLines = 0
        
        titleLabel = UILabel()
        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.textAlignment = .center
    }
    
    private func configColor() {
        let isDark = PhotoManager.isDark
        tableView.backgroundColor = isDark ? config.backgroundDarkColor : config.backgroundColor
        view.backgroundColor = isDark ? config.backgroundDarkColor : config.backgroundColor
        promptLb.textColor = isDark ? config.limitedStatusPromptDarkColor : config.limitedStatusPromptColor
        titleLabel.textColor = isDark ?
            pickerController?.config.navigationTitleDarkColor :
            pickerController?.config.navigationTitleColor
    }
    private func fetchCameraAssetCollection() {
        if let cameraAssetCollection = pickerController?.cameraAssetCollection {
            pushPhotoPickerController(
                assetCollection: cameraAssetCollection,
                animated: false
            )
            canFetchAssetCollections = true
            titleLabel.text = "相册".localized
        }else {
            pickerController?.fetchCameraAssetCollectionCompletion = { [weak self] (assetCollection) in
                var cameraAssetCollection = assetCollection
                if cameraAssetCollection == nil {
                    cameraAssetCollection = PhotoAssetCollection(
                        albumName: self?.config.emptyAlbumName.localized,
                        coverImage: self?.config.emptyCoverImageName.image
                    )
                }
                self?.canFetchAssetCollections = true
                self?.titleLabel.text = "相册".localized
                
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
        pickerController?.fetchAssetCollections()
        pickerController?
            .fetchAssetCollectionsCompletion = { [weak self] (assetCollectionsArray) in
            self?.reloadTableView(assetCollectionsArray: assetCollectionsArray)
            ProgressHUD.hide(forView: self?.view, animated: true)
        }
    }
    func reloadTableView(assetCollectionsArray: [PhotoAssetCollection]) {
        self.assetCollectionsArray = assetCollectionsArray
        if self.assetCollectionsArray.isEmpty {
            let assetCollection = PhotoAssetCollection(
                albumName: config.emptyAlbumName.localized,
                coverImage: config.emptyCoverImageName.image
            )
            self.assetCollectionsArray.append(assetCollection)
        }
        tableView.reloadData()
    }
    func updatePrompt() {
        guard let picker = pickerController else { return }
        if AssetManager.authorizationStatusIsLimited() &&
            picker.config.allowLoadPhotoLibrary {
            tableView.tableHeaderView = promptLb
        }
    }
    private func pushPhotoPickerController(
        assetCollection: PhotoAssetCollection?,
        animated: Bool
    ) {
        guard let picker = pickerController else { return }
        let photoVC = PhotoPickerViewController(config: picker.config.photoList)
        photoVC.assetCollection = assetCollection
        photoVC.showLoading = animated
        navigationController?.pushViewController(photoVC, animated: animated)
    }
    
    @objc
    private func didCancelItemClick() {
        pickerController?.cancelCallback()
    }
    
    private func changeSubviewFrame() {
        if AssetManager.authorizationStatusIsLimited() {
            promptLb.width = view.width
        }
        var titleWidth: CGFloat = 0
        if let labelWidth = titleLabel.text?.width(ofFont: titleLabel.font, maxHeight: 30) {
            titleWidth = labelWidth
        }
        if titleWidth > view.width * 0.6 {
            titleWidth = view.width * 0.6
        }
        titleLabel.size = CGSize(width: titleWidth, height: 30)
        let margin: CGFloat = UIDevice.leftMargin
        tableView.frame = CGRect(x: margin, y: 0, width: view.width - 2 * margin, height: view.height)
        if let nav = navigationController {
            if nav.modalPresentationStyle == .fullScreen && UIDevice.isPortrait {
                tableView.contentInset = UIEdgeInsets(
                    top: UIDevice.navigationBarHeight,
                    left: 0,
                    bottom: UIDevice.bottomMargin,
                    right: 0
                )
            }else {
                tableView.contentInset = UIEdgeInsets(
                    top: nav.navigationBar.height,
                    left: 0,
                    bottom: UIDevice.bottomMargin,
                    right: 0
                )
            }
        }
        if orientationDidChange {
            let indexPath: IndexPath
            if let index_Path = beforeOrientationIndexPath {
                indexPath = index_Path
            }else {
                indexPath = .init(row: 0, section: 0)
            }
            if !assetCollectionsArray.isEmpty {
                tableView.scrollToRow(
                    at: indexPath,
                    at: .top, animated: false
                )
            }
            orientationDidChange = false
        }
    }
    
    public func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        assetCollectionsArray.count
    }
    public func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "cellId"
        ) as! AlbumViewCell
        let assetCollection = assetCollectionsArray[indexPath.row]
        cell.assetCollection = assetCollection
        cell.config = config
        return cell
    }
    
    public func tableView(
        _ tableView: UITableView,
        heightForRowAt indexPath: IndexPath
    ) -> CGFloat {
        config.cellHeight
    }
    public func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: true)
        let assetCollection = assetCollectionsArray[indexPath.row]
        pushPhotoPickerController(assetCollection: assetCollection, animated: true)
    }
    
    public override func deviceOrientationWillChanged(notify: Notification) {
        beforeOrientationIndexPath = tableView.indexPathsForVisibleRows?.first
        orientationDidChange = true
    }
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        changeSubviewFrame()
    }
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.popoverPresentationController?.delegate = self as?
            UIPopoverPresentationControllerDelegate
        pickerController?.viewControllersWillAppear(self)
    }
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if assetCollectionsArray.isEmpty && canFetchAssetCollections {
            fetchAssetCollections()
        }
        pickerController?.viewControllersDidAppear(self)
    }
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pickerController?.viewControllersWillDisappear(self)
    }
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        pickerController?.viewControllersDidDisappear(self)
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
