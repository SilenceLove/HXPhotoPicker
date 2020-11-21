//
//  HXAlbumViewController.swift
//  照片选择器-Swift
//
//  Created by 洪欣 on 2019/6/28.
//  Copyright © 2019年 洪欣. All rights reserved.
//

import UIKit
import Photos

class HXAlbumViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    lazy var tableView : UITableView = {
        let tableView = UITableView.init(frame: CGRect.init(), style: UITableView.Style.plain)
        tableView.backgroundColor = config!.backgroundColor
        tableView.dataSource = self;
        tableView.delegate = self;
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        tableView.register(HXAlbumViewCell.self, forCellReuseIdentifier: "cellId")
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = UIScrollView.ContentInsetAdjustmentBehavior.never
        } else {
            // Fallback on earlier versions
            self.automaticallyAdjustsScrollViewInsets = false
        }
        return tableView
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
        extendedLayoutIncludesOpaqueBars = true;
        edgesForExtendedLayout = UIRectEdge.all;
        config = hx_pickerController()!.config.albumList
        view.backgroundColor = config!.backgroundColor
        let backItem = UIBarButtonItem.init(title: "取消".hx_localized(), style: UIBarButtonItem.Style.done, target: self, action: #selector(didCancelItemClick))
        navigationItem.rightBarButtonItem = backItem
        view.addSubview(tableView)
        fetchCameraAssetCollection()
        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationChanged(notify:)), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }
    @objc func deviceOrientationChanged(notify: Notification) {
        beforeOrientationIndexPath = tableView.indexPathsForVisibleRows?.first
        orientationDidChange = true
    }
    func fetchCameraAssetCollection() {
        if hx_pickerController()?.cameraAssetCollection != nil {
            self.pushPhotoPickerContoller(assetCollection: hx_pickerController()?.cameraAssetCollection, animated: false)
            self.canFetchAssetCollections = true
            title = "相册".hx_localized()
        }else {
            hx_pickerController()?.fetchCameraAssetCollectionCompletion = { (assetCollection) in
                var cameraAssetCollection = assetCollection
                if cameraAssetCollection == nil {
                    cameraAssetCollection = HXPHAssetCollection.init(albumName: self.config?.emptyAlbumName, coverImage: UIImage.hx_named(named: self.config!.emptyCoverImageName))
                }
                self.pushPhotoPickerContoller(assetCollection: cameraAssetCollection, animated: false)
                self.canFetchAssetCollections = true
                self.title = "相册".hx_localized()
            }
        }
    }
    
    func fetchAssetCollections() {
        HXPHProgressHUD.showLoadingHUD(addedTo: view, animated: true)
        hx_pickerController()?.fetchAssetCollections()
        hx_pickerController()?.fetchAssetCollectionsCompletion = { (assetCollectionsArray) in
            self.reloadTableView(assetCollectionsArray: assetCollectionsArray)
            HXPHProgressHUD.hideHUD(forView: self.view, animated: true)
        }
    }
    func reloadTableView(assetCollectionsArray: [HXPHAssetCollection]) {
        self.assetCollectionsArray = assetCollectionsArray
        if self.assetCollectionsArray.isEmpty {
            let assetCollection = HXPHAssetCollection.init(albumName: self.config?.emptyAlbumName, coverImage: UIImage.hx_named(named: self.config!.emptyCoverImageName))
            self.assetCollectionsArray.append(assetCollection)
        }
        self.tableView.reloadData()
    }
    private func pushPhotoPickerContoller(assetCollection: HXPHAssetCollection?, animated: Bool) {
        let photoVC = HXPHPickerViewController.init()
        photoVC.assetCollection = assetCollection
        photoVC.showLoading = animated
        navigationController?.pushViewController(photoVC, animated: animated)
    }
    
    @objc func didCancelItemClick() {
        hx_pickerController()?.cancelCallback()
        dismiss(animated: true, completion: nil)
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
        let margin: CGFloat = UIDevice.hx_leftMargin()
        tableView.frame = CGRect(x: margin, y: 0, width: view.hx_width - 2 * margin, height: view.hx_height)
        if navigationController?.modalPresentationStyle == UIModalPresentationStyle.fullScreen {
            tableView.contentInset = UIEdgeInsets.init(top: UIDevice.hx_navigationBarHeight(), left: 0, bottom: UIDevice.hx_bottomMargin(), right: 0)
        }else {
            tableView.contentInset = UIEdgeInsets.init(top: navigationController!.navigationBar.hx_height, left: 0, bottom: UIDevice.hx_bottomMargin(), right: 0)
        }
        if orientationDidChange {
            if !assetCollectionsArray.isEmpty {
                tableView.scrollToRow(at: beforeOrientationIndexPath ?? IndexPath.init(row: 0, section: 0), at: UITableView.ScrollPosition.top, animated: false)
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
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.default
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
        print("\(self) deinit")
    }
}
