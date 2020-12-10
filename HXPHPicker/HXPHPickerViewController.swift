//
//  HXPHPickerViewController.swift
//  照片选择器-Swift
//
//  Created by 洪欣 on 2019/6/29.
//  Copyright © 2019年 洪欣. All rights reserved.
//

import UIKit

class HXPHPickerViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, HXPHPickerViewCellDelegate, HXPHPickerBottomViewDelegate, HXPHPreviewViewControllerDelegate, HXAlbumViewDelegate {
    
    var config: HXPHPhotoListConfiguration!
    var assetCollection: HXPHAssetCollection!
    var assets: [HXPHAsset] = []
    lazy var collectionViewLayout: UICollectionViewFlowLayout = {
        let collectionViewLayout = UICollectionViewFlowLayout.init()
        let space = config.spacing
        collectionViewLayout.minimumLineSpacing = space
        collectionViewLayout.minimumInteritemSpacing = space
        return collectionViewLayout
    }()
    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView.init(frame: view.bounds, collectionViewLayout: collectionViewLayout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(HXPHPickerViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(HXPHPickerViewCell.classForCoder()))
        collectionView.register(HXPHPickerMultiSelectViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(HXPHPickerMultiSelectViewCell.classForCoder()))
        
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        } else {
            // Fallback on earlier versions
            self.automaticallyAdjustsScrollViewInsets = false
        }
        return collectionView
    }()
    
    var orientationDidChange : Bool = false
    var beforeOrientationIndexPath: IndexPath?
    var showLoading : Bool = false
    var isMultipleSelect : Bool = false
    var videoLoadSingleCell = false
    
    lazy var titleView: HXAlbumTitleView = {
        let titleView = HXAlbumTitleView.init(config: config.titleViewConfig)
        titleView.addTarget(self, action: #selector(didTitleViewClick(control:)), for: .touchUpInside)
        return titleView
    }()
    
    @objc func didTitleViewClick(control: HXAlbumTitleView) {
        control.isSelected = !control.isSelected
        if control.isSelected {
            // 展开
            if albumView.assetCollectionsArray.isEmpty {
//                HXPHProgressHUD.showLoadingHUD(addedTo: view, animated: true)
//                HXPHProgressHUD.hideHUD(forView: weakSelf?.navigationController?.view, animated: true)
                return
            }
            openAlbumView()
        }else {
            // 收起
            closeAlbumView()
        }
    }
    
    lazy var albumBackgroudView: UIView = {
        let albumBackgroudView = UIView.init()
        albumBackgroudView.isHidden = true
        albumBackgroudView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        albumBackgroudView.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(didAlbumBackgroudViewClick)))
        return albumBackgroudView
    }()
    
    @objc func didAlbumBackgroudViewClick() {
        titleView.isSelected = false
        closeAlbumView()
    }
    
    lazy var albumView: HXAlbumView = {
        let albumView = HXAlbumView.init(config: hx_pickerController!.config.albumList)
        albumView.delegate = self
        return albumView
    }()
    
    func openAlbumView() {
        albumBackgroudView.alpha = 0
        albumBackgroudView.isHidden = false
        albumView.scrollToMiddle()
        UIView.animate(withDuration: 0.25) {
            self.albumBackgroudView.alpha = 1
            self.configAlbumViewFrame()
            self.titleView.arrowView.transform = CGAffineTransform.init(rotationAngle: .pi)
        }
    }
    
    func closeAlbumView() {
        UIView.animate(withDuration: 0.25) {
            self.albumBackgroudView.alpha = 0
            self.configAlbumViewFrame()
            self.titleView.arrowView.transform = CGAffineTransform.init(rotationAngle: 2 * .pi)
        } completion: { (finish) in
            self.albumBackgroudView.isHidden = true
        }
    }
    
    func configAlbumViewFrame() {
        self.albumView.hx_size = CGSize(width: view.hx_width, height: getAlbumViewHeight())
        if titleView.isSelected {
            if self.navigationController!.modalPresentationStyle == UIModalPresentationStyle.fullScreen {
                self.albumView.hx_y = UIDevice.current.hx_navigationBarHeight
            }else {
                self.albumView.hx_y = self.navigationController!.navigationBar.hx_height
            }
        }else {
            self.albumView.hx_y = -self.albumView.hx_height
        }
    }
    
    func getAlbumViewHeight() -> CGFloat {
        var albumViewHeight = CGFloat(albumView.assetCollectionsArray.count) * (albumView.config?.cellHeight ?? 50)
        if albumViewHeight > view.hx_height * 0.75 {
            albumViewHeight = view.hx_height * 0.75
        }
        return albumViewHeight
    }
    
    lazy var bottomView : HXPHPickerBottomView = {
        let bottomView = HXPHPickerBottomView.init(config: config.bottomView)
        bottomView.hx_delegate = self
        bottomView.boxControl.isSelected = hx_pickerController!.isOriginal
        return bottomView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configData()
        initView()
        configColor()
        fetchData()
        guard #available(iOS 13.0, *) else {
            NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationChanged(notify:)), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
            return
        }
    }
    @objc func deviceOrientationChanged(notify: Notification) {
        beforeOrientationIndexPath = collectionView.indexPathsForVisibleItems.first
        orientationDidChange = true
    }
    func configData() {
        isMultipleSelect = hx_pickerController!.config.selectMode == .multiple
        if !hx_pickerController!.config.allowSelectedTogether && hx_pickerController!.config.maximumSelectVideoCount == 1 &&
            hx_pickerController!.config.selectType == .any &&
            isMultipleSelect {
            videoLoadSingleCell = true
        }
        config = hx_pickerController!.config.photoList
        updateTitle()
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: "取消".hx_localized, style: .done, target: self, action: #selector(didCancelItemClick))
    }
    func configColor() {
        view.backgroundColor = HXPHManager.shared.isDark ? config.backgroundDarkColor : config.backgroundColor
        collectionView.backgroundColor = HXPHManager.shared.isDark ? config.backgroundDarkColor : config.backgroundColor
        if hx_pickerController!.config.albumShowMode == .popup {
            titleView.titleColor = HXPHManager.shared.isDark ? hx_pickerController?.config.navigationTitleDarkColor : hx_pickerController?.config.navigationTitleColor
        }
    }
    @objc func didCancelItemClick() {
        hx_pickerController?.cancelCallback()
    }
    
    func initView() {
        extendedLayoutIncludesOpaqueBars = true;
        edgesForExtendedLayout = .all;
        view.addSubview(collectionView)
        if isMultipleSelect {
            view.addSubview(bottomView)
            bottomView.updateFinishButtonTitle()
            view.addSubview(albumBackgroudView)
            view.addSubview(albumView)
        }
    }
    func updateTitle() {
        if hx_pickerController!.config.albumShowMode == .popup {
            titleView.title = assetCollection?.albumName
        }else {
            title = assetCollection?.albumName
        }
    }
    func fetchData() {
        if hx_pickerController!.config.albumShowMode == .popup {
            fetchAssetCollections()
            navigationItem.titleView = titleView
            if hx_pickerController?.cameraAssetCollection != nil {
                assetCollection = hx_pickerController?.cameraAssetCollection
                assetCollection.isSelected = true
                titleView.title = assetCollection.albumName
                fetchPhotoAssets()
            }else {
                weak var weakSelf = self
                hx_pickerController?.fetchCameraAssetCollectionCompletion = { (assetCollection) in
                    var cameraAssetCollection = assetCollection
                    if cameraAssetCollection == nil {
                        cameraAssetCollection = HXPHAssetCollection.init(albumName: self.hx_pickerController!.config.albumList.emptyAlbumName, coverImage: self.hx_pickerController!.config.albumList.emptyCoverImageName.hx_image)
                    }
                    weakSelf?.assetCollection = cameraAssetCollection
                    weakSelf?.assetCollection.isSelected = true
                    weakSelf?.titleView.title = weakSelf?.assetCollection.albumName
                    weakSelf?.fetchPhotoAssets()
                }
            }
        }else {
            if showLoading {
                HXPHProgressHUD.showLoadingHUD(addedTo: view, afterDelay: 0.15, animated: true)
            }
            fetchPhotoAssets()
        }
    }
    
    func fetchAssetCollections() {
        if !hx_pickerController!.assetCollectionsArray.isEmpty {
            albumView.assetCollectionsArray = hx_pickerController!.assetCollectionsArray
            albumView.currentSelectedAssetCollection = assetCollection
            configAlbumViewFrame()
            if HXPHAssetManager.authorizationStatusIsLimited() {
                fetchAssetCollectionsClosure()
            }
        }else {
            fetchAssetCollectionsClosure()
        }
    }
    private func fetchAssetCollectionsClosure() {
        weak var weakSelf = self
        hx_pickerController?.fetchAssetCollectionsCompletion = { (assetCollectionsArray) in
            weakSelf?.albumView.assetCollectionsArray = assetCollectionsArray
            weakSelf?.albumView.currentSelectedAssetCollection = weakSelf?.assetCollection
            weakSelf?.configAlbumViewFrame()
        }
    }
    func fetchPhotoAssets() {
        weak var weakSelf = self
        hx_pickerController!.fetchPhotoAssets(assetCollection: assetCollection) { (photoAssets, photoAsset) in
            weakSelf?.assets = photoAssets
            if weakSelf != nil {
                UIView.transition(with: weakSelf!.collectionView, duration: 0.05, options: .transitionCrossDissolve) {
                    weakSelf?.collectionView.reloadData()
                } completion: { (isFinished) in }
            }
            weakSelf?.scrollToAppropriatePlace(photoAsset: photoAsset)
            if weakSelf != nil && weakSelf!.showLoading {
                HXPHProgressHUD.hideHUD(forView: weakSelf?.view, animated: true)
                weakSelf?.showLoading = false
            }else {
                HXPHProgressHUD.hideHUD(forView: weakSelf?.navigationController?.view, animated: false)
            }
        }
    }
    func scrollToAppropriatePlace(photoAsset: HXPHAsset?) {
        if assets.isEmpty {
            return
        }
        if !hx_pickerController!.config.reverseOrder {
            var item = assets.count - 1
            if photoAsset != nil {
                item = assets.firstIndex(of: photoAsset!) ?? item
            }
            collectionView.scrollToItem(at: IndexPath(item: item, section: 0), at: .centeredVertically, animated: false)
        }
    }
    func getCell(for item: Int) -> HXPHPickerViewCell? {
        if assets.isEmpty {
            return nil
        }
        let cell = collectionView.cellForItem(at: IndexPath.init(item: item, section: 0)) as? HXPHPickerViewCell
        return cell
    }
    func getCell(for photoAsset: HXPHAsset) -> HXPHPickerViewCell? {
        if assets.isEmpty {
            return nil
        }
        let item = assets.firstIndex(of: photoAsset)
        if item == nil {
            return nil
        }
        return getCell(for: item!)
    }
    func reloadCell(for photoAsset: HXPHAsset) {
        let item = assets.firstIndex(of: photoAsset)
        if item != nil {
            collectionView.reloadItems(at: [IndexPath.init(item: item!, section: 0)])
        }
    }
    func changedAssetCollection(collection: HXPHAssetCollection?) {
        HXPHProgressHUD.showLoadingHUD(addedTo: navigationController?.view, animated: true)
        if collection == nil {
            updateTitle()
            fetchPhotoAssets()
            reloadAlbumData()
            return
        }
        if hx_pickerController!.config.albumShowMode == .popup {
            assetCollection.isSelected = false
            collection?.isSelected = true
        }
        assetCollection = collection
        updateTitle()
        fetchPhotoAssets()
        reloadAlbumData()
    }
    func reloadAlbumData() {
        if hx_pickerController!.config.albumShowMode == .popup {
            albumView.tableView.reloadData()
        }
    }
    
    // MARK: UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: HXPHPickerViewCell
        let photoAsset = assets[indexPath.item]
        if hx_pickerController?.config.selectMode == .single || (photoAsset.mediaType == .video && videoLoadSingleCell) {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(HXPHPickerViewCell.classForCoder()), for: indexPath) as! HXPHPickerViewCell
        }else {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(HXPHPickerMultiSelectViewCell.classForCoder()), for: indexPath) as! HXPHPickerMultiSelectViewCell
        }
        if !photoAsset.isSelected {
            cell.canSelect = hx_pickerController!.canSelectAsset(for: photoAsset, showHUD: false)
        }else {
            cell.canSelect = true
        }
        cell.delegate = self
        cell.config = config.cell
        cell.photoAsset = photoAsset
        return cell
    }
    // MARK: UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let myCell: HXPHPickerViewCell = cell as! HXPHPickerViewCell
        
        myCell.cancelRequest()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        if !getCell(for: indexPath.item)!.canSelect {
            return
        }
        pushPreviewViewController(previewAssets: assets, currentPreviewIndex: indexPath.item)
    }
    
    func pushPreviewViewController(previewAssets: [HXPHAsset], currentPreviewIndex: Int) {
        let vc = HXPHPreviewViewController.init()
        vc.previewAssets = previewAssets
        vc.currentPreviewIndex = currentPreviewIndex
        vc.delegate = self
        navigationController?.delegate = vc
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: HXAlbumViewDelegate
    func albumView(_ albumView: HXAlbumView, didSelectRowAt assetCollection: HXPHAssetCollection) {
        didAlbumBackgroudViewClick()
        if self.assetCollection == assetCollection {
            return
        }
        titleView.title = assetCollection.albumName
        assetCollection.isSelected = true
        self.assetCollection.isSelected = false
        self.assetCollection = assetCollection
        HXPHProgressHUD.showLoadingHUD(addedTo: navigationController?.view, animated: true)
        fetchPhotoAssets()
    }
    
    // MARK: HXPHPickerViewCellDelegate
    
    func cellDidSelectControlClick(_ cell: HXPHPickerMultiSelectViewCell, isSelected: Bool) {
        if isSelected {
            // 取消选中
            _ = hx_pickerController?.removePhotoAsset(photoAsset: cell.photoAsset!)
            cell.updateSelectedState(isSelected: false, animated: true)
//            if config.cell.selectBox.type == .number {
//                updateCellSelectedTitle()
//            }
        }else {
            // 选中
            if hx_pickerController!.addedPhotoAsset(photoAsset: cell.photoAsset!) {
//                if HXPHAssetManager.isICloudAsset(for: cell.photoAsset!.asset) {
//                    navigationController?.interactivePopGestureRecognizer?.isEnabled = false
//                    HXPHProgressHUD.showLoadingHUD(addedTo: navigationController?.view, text: "正在下载...", animated: true)
//                    weak var weakSelf = self
//                    if cell.photoAsset?.mediaType == .photo {
//                        _ = cell.photoAsset?.requestImageData(iCloudHandler: nil, progressHandler: { (photoAsset, progress) in
//                            print(progress)
//                        }, success: { (photoAsset, data, orientation, info) in
//                            cell.photoAsset?.asset = HXPHAssetManager.fetchAsset(withLocalIdentifier: photoAsset.asset!.localIdentifier)
//                            cell.updateSelectedState(isSelected: true, animated: true)
//                            weakSelf?.bottomView.updateFinishButtonTitle()
//                            HXPHProgressHUD.hideHUD(forView: weakSelf?.navigationController?.view, animated: true)
//                            weakSelf?.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
//                        }, failure: { (photoAsset, info) in
//                            HXPHProgressHUD.hideHUD(forView: weakSelf?.navigationController?.view, animated: true)
//                            weakSelf?.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
//                        })
//                    }else if cell.photoAsset?.mediaType == .video {
//                        _ = cell.photoAsset?.requestAVAsset(iCloudHandler: nil, progressHandler: nil, success: { (photoAsset, avAsset, info) in
//                            cell.photoAsset?.asset = HXPHAssetManager.fetchAsset(withLocalIdentifier: photoAsset.asset!.localIdentifier)
//                            cell.updateSelectedState(isSelected: true, animated: true)
//                            weakSelf?.bottomView.updateFinishButtonTitle()
//                            HXPHProgressHUD.hideHUD(forView: weakSelf?.navigationController?.view, animated: true)
//                            weakSelf?.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
//                        }, failure: { (photoAsset, info) in
//                            HXPHProgressHUD.hideHUD(forView: weakSelf?.navigationController?.view, animated: true)
//                            weakSelf?.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
//                        })
//                    }
//                    return
//                }
                cell.updateSelectedState(isSelected: true, animated: true)
            }
        }
        updateCellSelectedTitle()
        bottomView.updateFinishButtonTitle()
    }
    
    func updateCellSelectedTitle() {
        for visibleCell in collectionView.visibleCells {
            if visibleCell is HXPHPickerViewCell {
                let cell = visibleCell as! HXPHPickerViewCell
                if !cell.photoAsset!.isSelected {
                    cell.canSelect = hx_pickerController!.canSelectAsset(for: cell.photoAsset!, showHUD: false)
                }
                if visibleCell is HXPHPickerMultiSelectViewCell {
                    let cell = visibleCell as! HXPHPickerMultiSelectViewCell
                    if cell.photoAsset!.isSelected {
                        if Int(cell.selectControl.text) != (cell.photoAsset!.selectIndex + 1) {
                            cell.updateSelectedState(isSelected: true, animated: false)
                            cell.selectControl.setNeedsDisplay()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: HXPHPickerBottomViewDelegate
    func bottomViewDidPreviewButtonClick(view: HXPHPickerBottomView) {
        pushPreviewViewController(previewAssets: hx_pickerController!.selectedAssetArray, currentPreviewIndex: 0)
    }
    func bottomViewDidFinishButtonClick(view: HXPHPickerBottomView) {
        hx_pickerController?.finishCallback()
    }
    func bottomViewDidOriginalButtonClick(view: HXPHPickerBottomView, with isOriginal: Bool) {
        hx_pickerController?.originalButtonCallback()
    }
    
    // MARK: HXPHPreviewViewControllerDelegate
    func previewViewControllerDidClickOriginal(_ previewViewController: HXPHPreviewViewController, with isOriginal: Bool) {
        if isMultipleSelect {
            bottomView.boxControl.isSelected = isOriginal
        }
    }
    func previewViewControllerDidClickSelectBox(_ previewViewController: HXPHPreviewViewController, with isSelected: Bool) {
        collectionView.reloadData()
        bottomView.updateFinishButtonTitle()
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let margin: CGFloat = UIDevice.current.hx_leftMargin
        collectionView.frame = CGRect(x: margin, y: 0, width: view.hx_width - 2 * margin, height: view.hx_height)
        var collectionTop: CGFloat
        if navigationController?.modalPresentationStyle == .fullScreen {
            collectionTop = UIDevice.current.hx_navigationBarHeight
        }else {
            collectionTop = navigationController!.navigationBar.hx_height
        }
        if isMultipleSelect {
            albumBackgroudView.frame = view.bounds
            configAlbumViewFrame()
            bottomView.frame = CGRect(x: 0, y: view.hx_height - 50 - UIDevice.current.hx_bottomMargin, width: view.hx_width, height: 50 + UIDevice.current.hx_bottomMargin)
            collectionView.contentInset = UIEdgeInsets(top: collectionTop, left: 0, bottom: bottomView.hx_height + 0.5, right: 0)
        }else {
            collectionView.contentInset = UIEdgeInsets(top: collectionTop, left: 0, bottom: UIDevice.current.hx_bottomMargin, right: 0)
        }
        let space = config.spacing
        let count : CGFloat
        if  UIDevice.current.hx_isPortrait == true {
            count = CGFloat(config.rowNumber)
        }else {
            count = CGFloat(config.landscapeRowNumber)
        }
        let itemWidth = (collectionView.hx_width - space * (count - CGFloat(1))) / count
        collectionViewLayout.itemSize = CGSize.init(width: itemWidth, height: itemWidth)
        if orientationDidChange {
            collectionView.reloadData()
            DispatchQueue.main.async {
                if self.beforeOrientationIndexPath != nil {
                    self.collectionView.scrollToItem(at: self.beforeOrientationIndexPath!, at: .top, animated: false)
                }
            }
            orientationDidChange = false
        }
    }
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if #available(iOS 13.0, *) {
            beforeOrientationIndexPath = collectionView.indexPathsForVisibleItems.first
            orientationDidChange = true
        }
        super.viewWillTransition(to: size, with: coordinator)
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

protocol HXPHPickerBottomViewDelegate: NSObjectProtocol {
    func bottomViewDidPreviewButtonClick(view: HXPHPickerBottomView)
    func bottomViewDidFinishButtonClick(view: HXPHPickerBottomView)
    func bottomViewDidOriginalButtonClick(view: HXPHPickerBottomView, with isOriginal: Bool)
}

class HXPHPickerBottomView: UIToolbar {
    weak var hx_delegate: HXPHPickerBottomViewDelegate?
    
    var config: HXPHPickerBottomViewConfiguration?
    
    lazy var previewBtn: UIButton = {
        let previewBtn = UIButton.init(type: .custom)
        previewBtn.setTitle("预览".hx_localized, for: .normal)
        previewBtn.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        previewBtn.isEnabled = false
        previewBtn.addTarget(self, action: #selector(didPreviewButtonClick(button:)), for: .touchUpInside)
        previewBtn.isHidden = config!.previewButtonHidden
        return previewBtn
    }()
    
    @objc func didPreviewButtonClick(button: UIButton) {
        hx_delegate?.bottomViewDidPreviewButtonClick(view: self)
    }
    
    lazy var editBtn: UIButton = {
        let editBtn = UIButton.init(type: .custom)
        editBtn.setTitle("编辑".hx_localized, for: .normal)
        editBtn.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        editBtn.addTarget(self, action: #selector(didEditBtnButtonClick(button:)), for: .touchUpInside)
        editBtn.isHidden = config!.editButtonHidden
        return editBtn
    }()
    
    @objc func didEditBtnButtonClick(button: UIButton) {
        hx_delegate?.bottomViewDidPreviewButtonClick(view: self)
    }
    
    lazy var originalBtn: UIView = {
        let originalBtn = UIView.init()
        originalBtn.addSubview(originalTitleLb)
        originalBtn.addSubview(boxControl)
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(didOriginalButtonClick))
        originalBtn.addGestureRecognizer(tap)
        originalBtn.isHidden = config!.originalButtonHidden
        return originalBtn
    }()
    
    @objc func didOriginalButtonClick() {
        if boxControl.isSelected {
            // 取消
            
        }else {
            // 选中
            
        }
        boxControl.isSelected = !boxControl.isSelected
        hx_viewController()?.hx_pickerController?.isOriginal = boxControl.isSelected
        hx_delegate?.bottomViewDidOriginalButtonClick(view: self, with: boxControl.isSelected)
        boxControl.layer.removeAnimation(forKey: "SelectControlAnimation")
        let keyAnimation = CAKeyframeAnimation.init(keyPath: "transform.scale")
        keyAnimation.duration = 0.3
        keyAnimation.values = [1.2, 0.8, 1.1, 0.9, 1.0]
        boxControl.layer.add(keyAnimation, forKey: "SelectControlAnimation")
    }
    
    lazy var originalTitleLb: UILabel = {
        let originalTitleLb = UILabel.init()
        originalTitleLb.text = "原图".hx_localized
        originalTitleLb.font = UIFont.systemFont(ofSize: 17)
        originalTitleLb.frame = CGRect(x: 0, y: 0, width: originalTitleLb.text!.hx_stringWidth(ofFont: originalTitleLb.font, maxHeight: 50), height: 50)
        return originalTitleLb
    }()
    
    lazy var boxControl: HXPHPickerCellSelectBoxControl = {
        let boxControl = HXPHPickerCellSelectBoxControl.init(frame: CGRect(x: originalTitleLb.hx_width + 2, y: 0, width: 16, height: 16))
        boxControl.config = config!.originalSelectBox
        boxControl.hx_centerY = originalTitleLb.hx_height * 0.5
        boxControl.backgroundColor = UIColor.clear
        return boxControl
    }()
    
    lazy var finishBtn: UIButton = {
        let finishBtn = UIButton.init(type: .custom)
        finishBtn.setTitle("完成".hx_localized, for: .normal)
        finishBtn.titleLabel?.font = UIFont.hx_mediumPingFang(size: 16)
        finishBtn.layer.cornerRadius = 3
        finishBtn.layer.masksToBounds = true
        finishBtn.isEnabled = false
        finishBtn.addTarget(self, action: #selector(didFinishButtonClick(button:)), for: .touchUpInside)
        return finishBtn
    }()
    @objc func didFinishButtonClick(button: UIButton) {
        hx_delegate?.bottomViewDidFinishButtonClick(view: self)
    }
    
    init(config: HXPHPickerBottomViewConfiguration) {
        super.init(frame: CGRect.zero)
        self.config = config
        addSubview(previewBtn)
        addSubview(editBtn)
        addSubview(originalBtn)
        addSubview(finishBtn)
        configColor()
        isTranslucent = config.isTranslucent
    }
    func configColor() {
        backgroundColor = HXPHManager.shared.isDark ? config!.backgroundDarkColor : config!.backgroundColor
        barTintColor = HXPHManager.shared.isDark ? config!.barTintDarkColor : config!.barTintColor
        barStyle = HXPHManager.shared.isDark ? config!.barDarkStyle : config!.barStyle
        
        previewBtn.setTitleColor(HXPHManager.shared.isDark ? config?.previewButtonTitleDarkColor : config?.previewButtonTitleColor, for: .normal)
        
        editBtn.setTitleColor(HXPHManager.shared.isDark ? config?.editButtonTitleDarkColor : config?.editButtonTitleColor, for: .normal)
        
        if HXPHManager.shared.isDark {
            if config?.previewButtonDisableTitleDarkColor != nil {
                previewBtn.setTitleColor(config?.previewButtonDisableTitleDarkColor, for: .disabled)
            }else {
                previewBtn.setTitleColor(config?.previewButtonTitleDarkColor.withAlphaComponent(0.6), for: .disabled)
            }
            
            if config?.editButtonDisableTitleDarkColor != nil {
                editBtn.setTitleColor(config?.editButtonDisableTitleDarkColor, for: .disabled)
            }else {
                editBtn.setTitleColor(config?.editButtonTitleDarkColor.withAlphaComponent(0.6), for: .disabled)
            }
        }else {
            if config?.previewButtonDisableTitleColor != nil {
                previewBtn.setTitleColor(config?.previewButtonDisableTitleColor, for: .disabled)
            }else {
                previewBtn.setTitleColor(config?.previewButtonTitleColor.withAlphaComponent(0.6), for: .disabled)
            }
            
            if config?.editButtonDisableTitleColor != nil {
                editBtn.setTitleColor(config?.editButtonDisableTitleColor, for: .disabled)
            }else {
                editBtn.setTitleColor(config?.editButtonTitleColor.withAlphaComponent(0.6), for: .disabled)
            }
        }
        
        originalTitleLb.textColor = HXPHManager.shared.isDark ? config?.originalButtonTitleDarkColor : config?.originalButtonTitleColor
        
        let finishBtnBackgroundColor = HXPHManager.shared.isDark ? config!.finishButtonDarkBackgroundColor : config!.finishButtonBackgroundColor
        finishBtn.setTitleColor(HXPHManager.shared.isDark ? config?.finishButtonTitleDarkColor : config?.finishButtonTitleColor, for: .normal)
        finishBtn.setTitleColor(HXPHManager.shared.isDark ? config?.finishButtonDisableTitleDarkColor : config?.finishButtonDisableTitleColor, for: .disabled)
        finishBtn.setBackgroundImage(UIImage.hx_image(for: finishBtnBackgroundColor, havingSize: CGSize.zero), for: .normal)
        finishBtn.setBackgroundImage(UIImage.hx_image(for: HXPHManager.shared.isDark ? config!.finishButtonDisableDarkBackgroundColor : config!.finishButtonDisableBackgroundColor, havingSize: CGSize.zero), for: .disabled)
    }
    func updateFinishButtonTitle() {
        let selectCount = hx_viewController()?.hx_pickerController?.selectedAssetArray.count ?? 0
        if selectCount > 0 {
            finishBtn.isEnabled = true
            previewBtn.isEnabled = true
            finishBtn.setTitle("完成".hx_localized + " (" + String(format: "%d", arguments: [selectCount]) + ")", for: .normal)
        }else {
            finishBtn.isEnabled = !config!.disableFinishButtonWhenNotSelected
            previewBtn.isEnabled = false
            finishBtn.setTitle("完成".hx_localized, for: .normal)
        }
        updateFinishButtonFrame()
    }
    
    func updateFinishButtonFrame() {
        originalBtn.hx_centerX = hx_width / 2
        var finishWidth : CGFloat = finishBtn.currentTitle!.hx_localized.hx_stringWidth(ofFont: finishBtn.titleLabel!.font, maxHeight: 50) + 20
        if finishWidth < 60 {
            finishWidth = 60
        }
        finishBtn.frame = CGRect(x: hx_width - UIDevice.current.hx_rightMargin - finishWidth - 12, y: 0, width: finishWidth, height: 33)
        finishBtn.hx_centerY = 25
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let previewWidth : CGFloat = previewBtn.currentTitle!.hx_localized.hx_stringWidth(ofFont: previewBtn.titleLabel!.font, maxHeight: 50)
        previewBtn.frame = CGRect(x: 12 + UIDevice.current.hx_leftMargin, y: 0, width: previewWidth, height: 50)
        editBtn.frame = previewBtn.frame
        originalBtn.frame = CGRect(x: 0, y: 0, width: boxControl.frame.maxX, height: 50)
        updateFinishButtonFrame()
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
