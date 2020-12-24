//
//  HXAlbumViewController.swift
//  照片选择器-Swift
//
//  Created by Silence on 2019/6/28.
//  Copyright © 2019年 Silence. All rights reserved.
//

import UIKit
import Photos

class HXAlbumViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    lazy var tableView : UITableView = {
        let tableView = UITableView.init(frame: CGRect.init(), style: .plain)
        if HXPHAssetManager.authorizationStatusIsLimited() &&
            hx_pickerController!.config.allowLoadPhotoLibrary{
            tableView.tableHeaderView = promptLb
        }
        tableView.dataSource = self;
        tableView.delegate = self;
        tableView.separatorStyle = .none
        tableView.register(HXAlbumViewCell.self, forCellReuseIdentifier: "cellId")
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        } else {
            // Fallback on earlier versions
            self.automaticallyAdjustsScrollViewInsets = false
        }
        return tableView
    }()
    lazy var promptLb: UILabel = {
        let promptLb = UILabel.init(frame: CGRect(x: 0, y: 0, width: 0, height: 40))
        promptLb.text = "只能查看允许访问的照片和相关相册".hx_localized
        promptLb.textAlignment = .center
        promptLb.font = UIFont.systemFont(ofSize: 14)
        promptLb.adjustsFontSizeToFitWidth = true
        promptLb.numberOfLines = 0
        return promptLb
    }()
    var config: HXPHAlbumListConfiguration?
    var assetCollectionsArray: [HXPHAssetCollection] = []
    var orientationDidChange : Bool = false
    var beforeOrientationIndexPath: IndexPath?
    var canFetchAssetCollections: Bool = false
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = .all
        config = hx_pickerController!.config.albumList
        let backItem = UIBarButtonItem.init(title: "取消".hx_localized, style: .done, target: self, action: #selector(didCancelItemClick))
        navigationItem.rightBarButtonItem = backItem
        view.addSubview(tableView)
        configColor()
        fetchCameraAssetCollection()
        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationChanged(notify:)), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }
    func configColor() {
        tableView.backgroundColor = HXPHManager.shared.isDark ? config!.backgroundDarkColor : config!.backgroundColor
        view.backgroundColor = HXPHManager.shared.isDark ? config!.backgroundDarkColor : config!.backgroundColor
        promptLb.textColor = HXPHManager.shared.isDark ? config!.limitedStatusPromptDarkColor : config!.limitedStatusPromptColor
    }
    @objc func deviceOrientationChanged(notify: Notification) {
        beforeOrientationIndexPath = tableView.indexPathsForVisibleRows?.first
        orientationDidChange = true
    }
    func fetchCameraAssetCollection() {
        if hx_pickerController?.cameraAssetCollection != nil {
            self.pushPhotoPickerContoller(assetCollection: hx_pickerController?.cameraAssetCollection, animated: false)
            self.canFetchAssetCollections = true
            title = "相册".hx_localized
        }else {
            weak var weakSelf = self
            hx_pickerController?.fetchCameraAssetCollectionCompletion = { (assetCollection) in
                var cameraAssetCollection = assetCollection
                if cameraAssetCollection == nil {
                    cameraAssetCollection = HXPHAssetCollection.init(albumName: weakSelf?.config?.emptyAlbumName.hx_localized, coverImage: weakSelf?.config!.emptyCoverImageName.hx_image)
                }
                weakSelf?.canFetchAssetCollections = true
                weakSelf?.title = "相册".hx_localized
                if weakSelf?.navigationController?.topViewController is HXPHPickerViewController {
                    let vc = weakSelf?.navigationController?.topViewController as! HXPHPickerViewController
                    vc.changedAssetCollection(collection: cameraAssetCollection)
                    return
                }
                weakSelf?.pushPhotoPickerContoller(assetCollection: cameraAssetCollection, animated: false)
            }
        }
    }
    
    func fetchAssetCollections() {
        HXPHProgressHUD.showLoadingHUD(addedTo: view, animated: true)
        hx_pickerController?.fetchAssetCollections()
        weak var weakSelf = self
        hx_pickerController?.fetchAssetCollectionsCompletion = { (assetCollectionsArray) in
            weakSelf?.reloadTableView(assetCollectionsArray: assetCollectionsArray)
            HXPHProgressHUD.hideHUD(forView: weakSelf?.view, animated: true)
        }
    }
    func reloadTableView(assetCollectionsArray: [HXPHAssetCollection]) {
        self.assetCollectionsArray = assetCollectionsArray
        if self.assetCollectionsArray.isEmpty {
            let assetCollection = HXPHAssetCollection.init(albumName: self.config?.emptyAlbumName.hx_localized, coverImage: self.config!.emptyCoverImageName.hx_image)
            self.assetCollectionsArray.append(assetCollection)
        }
        self.tableView.reloadData()
    }
    func updatePrompt() {
        if HXPHAssetManager.authorizationStatusIsLimited() &&
            hx_pickerController!.config.allowLoadPhotoLibrary {
            tableView.tableHeaderView = promptLb
        }
    }
    private func pushPhotoPickerContoller(assetCollection: HXPHAssetCollection?, animated: Bool) {
        let photoVC = HXPHPickerViewController.init()
        photoVC.assetCollection = assetCollection
        photoVC.showLoading = animated
        navigationController?.pushViewController(photoVC, animated: animated)
    }
    
    @objc func didCancelItemClick() {
        hx_pickerController?.cancelCallback()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return assetCollectionsArray.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellId") as! HXAlbumViewCell
        let assetCollection = assetCollectionsArray[indexPath.row]
        cell.assetCollection = assetCollection
        cell.config = config
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return config!.cellHeight
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let assetCollection = assetCollectionsArray[indexPath.row]
        pushPhotoPickerContoller(assetCollection: assetCollection, animated: true)
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let myCell: HXAlbumViewCell = cell as! HXAlbumViewCell
        myCell.cancelRequest()
    }
    
    func changeSubviewFrame() {
        if HXPHAssetManager.authorizationStatusIsLimited() {
            promptLb.hx_width = view.hx_width
        }
        let margin: CGFloat = UIDevice.current.hx_leftMargin
        tableView.frame = CGRect(x: margin, y: 0, width: view.hx_width - 2 * margin, height: view.hx_height)
        if navigationController?.modalPresentationStyle == .fullScreen {
            tableView.contentInset = UIEdgeInsets.init(top: UIDevice.current.hx_navigationBarHeight, left: 0, bottom: UIDevice.current.hx_bottomMargin, right: 0)
        }else {
            tableView.contentInset = UIEdgeInsets.init(top: navigationController!.navigationBar.hx_height, left: 0, bottom: UIDevice.current.hx_bottomMargin, right: 0)
        }
        if orientationDidChange {
            if !assetCollectionsArray.isEmpty {
                tableView.scrollToRow(at: beforeOrientationIndexPath ?? IndexPath.init(row: 0, section: 0), at: .top, animated: false)
            }
            orientationDidChange = false
        }
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        changeSubviewFrame()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.popoverPresentationController?.delegate = self as? UIPopoverPresentationControllerDelegate;
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if assetCollectionsArray.isEmpty && canFetchAssetCollections {
            fetchAssetCollections()
        }
    }
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                configColor()
            }
        }
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
