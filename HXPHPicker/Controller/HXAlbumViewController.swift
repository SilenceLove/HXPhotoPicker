//
//  HXAlbumViewController.swift
//  照片选择器-Swift
//
//  Created by Silence on 2019/6/28.
//  Copyright © 2019年 Silence. All rights reserved.
//

import UIKit
import Photos

public class HXAlbumViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    lazy var tableView : UITableView = {
        let tableView = UITableView.init(frame: CGRect.init(), style: .plain)
        if HXPHAssetManager.authorizationStatusIsLimited() &&
            pickerController!.config.allowLoadPhotoLibrary{
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
        promptLb.text = "只能查看允许访问的照片和相关相册".localized
        promptLb.textAlignment = .center
        promptLb.font = UIFont.systemFont(ofSize: 14)
        promptLb.adjustsFontSizeToFitWidth = true
        promptLb.numberOfLines = 0
        return promptLb
    }()
    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel.init()
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.textAlignment = .center
        return titleLabel
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
    public override func viewDidLoad() {
        super.viewDidLoad()
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = .all
        config = pickerController!.config.albumList
        title = "返回".localized
        navigationItem.titleView = titleLabel
        let backItem = UIBarButtonItem.init(title: "取消".localized, style: .done, target: self, action: #selector(didCancelItemClick))
        navigationItem.rightBarButtonItem = backItem
        view.addSubview(tableView)
        configColor()
        fetchCameraAssetCollection()
        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationChanged(notify:)), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }
    func configColor() {
        let isDark = HXPHManager.shared.isDark
        tableView.backgroundColor = isDark ? config!.backgroundDarkColor : config!.backgroundColor
        view.backgroundColor = isDark ? config!.backgroundDarkColor : config!.backgroundColor
        promptLb.textColor = isDark ? config!.limitedStatusPromptDarkColor : config!.limitedStatusPromptColor
        titleLabel.textColor = isDark ? pickerController?.config.navigationTitleDarkColor : pickerController?.config.navigationTitleColor
    }
    @objc func deviceOrientationChanged(notify: Notification) {
        beforeOrientationIndexPath = tableView.indexPathsForVisibleRows?.first
        orientationDidChange = true
    }
    func fetchCameraAssetCollection() {
        if pickerController?.cameraAssetCollection != nil {
            self.pushPhotoPickerController(assetCollection: pickerController?.cameraAssetCollection, animated: false)
            self.canFetchAssetCollections = true
            titleLabel.text = "相册".localized
        }else {
            weak var weakSelf = self
            pickerController?.fetchCameraAssetCollectionCompletion = { (assetCollection) in
                var cameraAssetCollection = assetCollection
                if cameraAssetCollection == nil {
                    cameraAssetCollection = HXPHAssetCollection.init(albumName: weakSelf?.config?.emptyAlbumName.localized, coverImage: weakSelf?.config!.emptyCoverImageName.image)
                }
                weakSelf?.canFetchAssetCollections = true
                weakSelf?.titleLabel.text = "相册".localized
                if weakSelf?.navigationController?.topViewController is HXPHPickerViewController {
                    let vc = weakSelf?.navigationController?.topViewController as! HXPHPickerViewController
                    vc.changedAssetCollection(collection: cameraAssetCollection)
                    return
                }
                weakSelf?.pushPhotoPickerController(assetCollection: cameraAssetCollection, animated: false)
            }
        }
    }
    
    func fetchAssetCollections() {
        _ = HXPHProgressHUD.showLoadingHUD(addedTo: view, animated: true)
        pickerController?.fetchAssetCollections()
        weak var weakSelf = self
        pickerController?.fetchAssetCollectionsCompletion = { (assetCollectionsArray) in
            weakSelf?.reloadTableView(assetCollectionsArray: assetCollectionsArray)
            HXPHProgressHUD.hideHUD(forView: weakSelf?.view, animated: true)
        }
    }
    func reloadTableView(assetCollectionsArray: [HXPHAssetCollection]) {
        self.assetCollectionsArray = assetCollectionsArray
        if self.assetCollectionsArray.isEmpty {
            let assetCollection = HXPHAssetCollection.init(albumName: self.config?.emptyAlbumName.localized, coverImage: self.config!.emptyCoverImageName.image)
            self.assetCollectionsArray.append(assetCollection)
        }
        self.tableView.reloadData()
    }
    func updatePrompt() {
        if HXPHAssetManager.authorizationStatusIsLimited() &&
            pickerController!.config.allowLoadPhotoLibrary {
            tableView.tableHeaderView = promptLb
        }
    }
    private func pushPhotoPickerController(assetCollection: HXPHAssetCollection?, animated: Bool) {
        let photoVC = HXPHPickerViewController.init()
        photoVC.assetCollection = assetCollection
        photoVC.showLoading = animated
        navigationController?.pushViewController(photoVC, animated: animated)
    }
    
    @objc func didCancelItemClick() {
        pickerController?.cancelCallback()
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return assetCollectionsArray.count
    }
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellId") as! HXAlbumViewCell
        let assetCollection = assetCollectionsArray[indexPath.row]
        cell.assetCollection = assetCollection
        cell.config = config
        return cell
    }
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return config!.cellHeight
    }
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let assetCollection = assetCollectionsArray[indexPath.row]
        pushPhotoPickerController(assetCollection: assetCollection, animated: true)
    }
    
    public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let myCell: HXAlbumViewCell = cell as! HXAlbumViewCell
        myCell.cancelRequest()
    }
    
    func changeSubviewFrame() {
        if HXPHAssetManager.authorizationStatusIsLimited() {
            promptLb.width = view.width
        }
        var titleWidth = titleLabel.text?.width(ofFont: titleLabel.font, maxHeight: 30) ?? 0
        if titleWidth > view.width * 0.6 {
            titleWidth = view.width * 0.6
        }
        titleLabel.size = CGSize(width: titleWidth, height: 30)
        let margin: CGFloat = UIDevice.current.leftMargin
        tableView.frame = CGRect(x: margin, y: 0, width: view.width - 2 * margin, height: view.height)
        if navigationController?.modalPresentationStyle == .fullScreen && UIDevice.current.isPortrait {
            tableView.contentInset = UIEdgeInsets.init(top: UIDevice.current.navigationBarHeight, left: 0, bottom: UIDevice.current.bottomMargin, right: 0)
        }else {
            tableView.contentInset = UIEdgeInsets.init(top: navigationController!.navigationBar.height, left: 0, bottom: UIDevice.current.bottomMargin, right: 0)
        }
        if orientationDidChange {
            if !assetCollectionsArray.isEmpty {
                tableView.scrollToRow(at: beforeOrientationIndexPath ?? IndexPath.init(row: 0, section: 0), at: .top, animated: false)
            }
            orientationDidChange = false
        }
    }
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        changeSubviewFrame()
    }
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.popoverPresentationController?.delegate = self as? UIPopoverPresentationControllerDelegate;
    }
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if assetCollectionsArray.isEmpty && canFetchAssetCollections {
            fetchAssetCollections()
        }
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
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
