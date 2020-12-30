//
//  HXPHPickerViewController.swift
//  照片选择器-Swift
//
//  Created by Silence on 2019/6/29.
//  Copyright © 2019年 Silence. All rights reserved.
//

import UIKit
import MobileCoreServices
import AVFoundation

public class HXPHPickerViewController: UIViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
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
        if let customSingleCellClass = config.cell.customSingleCellClass {
            collectionView.register(customSingleCellClass, forCellWithReuseIdentifier: NSStringFromClass(HXPHPickerViewCell.classForCoder()))
        }else {
            collectionView.register(HXPHPickerViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(HXPHPickerViewCell.classForCoder()))
        }
        if let customSelectableCellClass = config.cell.customSelectableCellClass {
            collectionView.register(customSelectableCellClass, forCellWithReuseIdentifier: NSStringFromClass(HXPHPickerSelectableViewCell.classForCoder()))
        }else {
            collectionView.register(HXPHPickerSelectableViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(HXPHPickerSelectableViewCell.classForCoder()))
        }
        if config.allowAddCamera {
            collectionView.register(HXPHPickerCamerViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(HXPHPickerCamerViewCell.classForCoder()))
        }
        
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        } else {
            // Fallback on earlier versions
            self.automaticallyAdjustsScrollViewInsets = false
        }
        return collectionView
    }()
    
    var cameraCell: HXPHPickerCamerViewCell {
        get {
            var indexPath: IndexPath
            if !pickerController!.config.reverseOrder {
                indexPath = IndexPath(item: assets.count, section: 0)
            }else {
                indexPath = IndexPath(item: 0, section: 0)
            }
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(HXPHPickerCamerViewCell.classForCoder()), for: indexPath) as! HXPHPickerCamerViewCell
            cell.config = config.cameraCell
            return cell
        }
    }
    
    private lazy var emptyView: HXPHEmptyView = {
        let emptyView = HXPHEmptyView.init(frame: CGRect(x: 0, y: 0, width: view.width, height: 0))
        emptyView.config = config.emptyView
        emptyView.layoutSubviews()
        return emptyView
    }()
    
    var canAddCamera: Bool = false
    var orientationDidChange : Bool = false
    var beforeOrientationIndexPath: IndexPath?
    var showLoading : Bool = false
    var isMultipleSelect : Bool = false
    var videoLoadSingleCell = false
    var needOffset: Bool {
        get {
            return pickerController != nil && pickerController!.config.reverseOrder && config.allowAddCamera && canAddCamera
        }
    }
    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel.init()
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.textAlignment = .center
        return titleLabel
    }()
    lazy var titleView: HXAlbumTitleView = {
        let titleView = HXAlbumTitleView.init(config: config.titleViewConfig)
        titleView.addTarget(self, action: #selector(didTitleViewClick(control:)), for: .touchUpInside)
        return titleView
    }()
    
    lazy var albumBackgroudView: UIView = {
        let albumBackgroudView = UIView.init()
        albumBackgroudView.isHidden = true
        albumBackgroudView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        albumBackgroudView.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(didAlbumBackgroudViewClick)))
        return albumBackgroudView
    }()
    
    lazy var albumView: HXAlbumView = {
        let albumView = HXAlbumView.init(config: pickerController!.config.albumList)
        albumView.delegate = self
        return albumView
    }()
    
    lazy var bottomView : HXPHPickerBottomView = {
        let bottomView = HXPHPickerBottomView.init(config: config.bottomView, allowLoadPhotoLibrary: allowLoadPhotoLibrary)
        bottomView.hx_delegate = self
        bottomView.boxControl.isSelected = pickerController!.isOriginal
        return bottomView
    }()
    var allowLoadPhotoLibrary: Bool = true
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        allowLoadPhotoLibrary = pickerController?.config.allowLoadPhotoLibrary ?? true
        if HXPHAssetManager.authorizationStatus() == .notDetermined {
            canAddCamera = true
        }
        configData()
        initView()
        configColor()
        fetchData()
        guard #available(iOS 13.0, *) else {
            NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationChanged(notify:)), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
            return
        }
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let margin: CGFloat = UIDevice.current.leftMargin
        collectionView.frame = CGRect(x: margin, y: 0, width: view.width - 2 * margin, height: view.height)
        var collectionTop: CGFloat
        if navigationController?.modalPresentationStyle == .fullScreen && UIDevice.current.isPortrait {
            collectionTop = UIDevice.current.navigationBarHeight
        }else {
            collectionTop = navigationController!.navigationBar.height
        }
        if let pickerController = pickerController {
            if pickerController.config.albumShowMode == .popup {
                albumBackgroudView.frame = view.bounds
                configAlbumViewFrame()
            }else {
                var titleWidth = titleLabel.text?.width(ofFont: titleLabel.font, maxHeight: 30) ?? 0
                if titleWidth > view.width * 0.6 {
                    titleWidth = view.width * 0.6
                }
                titleLabel.size = CGSize(width: titleWidth, height: 30)
            }
        }
        if isMultipleSelect {
            let promptHeight: CGFloat = (HXPHAssetManager.authorizationStatusIsLimited() && config.bottomView.showPrompt && allowLoadPhotoLibrary) ? 70 : 0
            let bottomHeight: CGFloat = 50 + UIDevice.current.bottomMargin + promptHeight
            bottomView.frame = CGRect(x: 0, y: view.height - bottomHeight, width: view.width, height: bottomHeight)
            collectionView.contentInset = UIEdgeInsets(top: collectionTop, left: 0, bottom: bottomView.height + 0.5, right: 0)
            collectionView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: bottomHeight - UIDevice.current.bottomMargin, right: 0)
        }else {
            collectionView.contentInset = UIEdgeInsets(top: collectionTop, left: 0, bottom: UIDevice.current.bottomMargin, right: 0)
        }
        let space = config.spacing
        let count : CGFloat
        if  UIDevice.current.isPortrait == true {
            count = CGFloat(config.rowNumber)
        }else {
            count = CGFloat(config.landscapeRowNumber)
        }
        let itemWidth = (collectionView.width - space * (count - CGFloat(1))) / count
        collectionViewLayout.itemSize = CGSize.init(width: itemWidth, height: itemWidth)
        if orientationDidChange {
            if pickerController != nil && pickerController!.config.albumShowMode == .popup {
                titleView.updateViewFrame()
            }
            collectionView.reloadData()
            DispatchQueue.main.async {
                if self.beforeOrientationIndexPath != nil {
                    self.collectionView.scrollToItem(at: self.beforeOrientationIndexPath!, at: .top, animated: false)
                }
            }
            orientationDidChange = false
        }
        emptyView.width = collectionView.width
        emptyView.center = CGPoint(x: collectionView.width * 0.5, y: (collectionView.height - collectionView.contentInset.top - collectionView.contentInset.bottom) * 0.5)
    }
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if #available(iOS 13.0, *) {
            beforeOrientationIndexPath = collectionView.indexPathsForVisibleItems.first
            orientationDidChange = true
        }
        super.viewWillTransition(to: size, with: coordinator)
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

// MARK: fetch Asset
extension HXPHPickerViewController {
    
    func fetchData() {
        if pickerController!.config.albumShowMode == .popup {
            fetchAssetCollections()
            title = ""
            navigationItem.titleView = titleView
            if pickerController?.cameraAssetCollection != nil {
                assetCollection = pickerController?.cameraAssetCollection
                assetCollection.isSelected = true
                titleView.title = assetCollection.albumName
                fetchPhotoAssets()
            }else {
                weak var weakSelf = self
                pickerController?.fetchCameraAssetCollectionCompletion = { (assetCollection) in
                    var cameraAssetCollection = assetCollection
                    if cameraAssetCollection == nil {
                        cameraAssetCollection = HXPHAssetCollection.init(albumName: self.pickerController!.config.albumList.emptyAlbumName.localized, coverImage: self.pickerController!.config.albumList.emptyCoverImageName.image)
                    }
                    weakSelf?.assetCollection = cameraAssetCollection
                    weakSelf?.assetCollection.isSelected = true
                    weakSelf?.titleView.title = weakSelf?.assetCollection.albumName
                    weakSelf?.fetchPhotoAssets()
                }
            }
        }else {
            title = ""
            navigationItem.titleView = titleLabel
            if showLoading {
                _ = HXPHProgressHUD.showLoadingHUD(addedTo: view, afterDelay: 0.15, animated: true)
            }
            fetchPhotoAssets()
        }
    }
    
    func fetchAssetCollections() {
        if !pickerController!.assetCollectionsArray.isEmpty {
            albumView.assetCollectionsArray = pickerController!.assetCollectionsArray
            albumView.currentSelectedAssetCollection = assetCollection
            configAlbumViewFrame()
        }
        fetchAssetCollectionsClosure()
        if !pickerController!.config.allowLoadPhotoLibrary {
            pickerController?.fetchAssetCollections()
        }
    }
    private func fetchAssetCollectionsClosure() {
        weak var weakSelf = self
        pickerController?.fetchAssetCollectionsCompletion = { (assetCollectionsArray) in
            weakSelf?.albumView.assetCollectionsArray = assetCollectionsArray
            weakSelf?.albumView.currentSelectedAssetCollection = weakSelf?.assetCollection
            weakSelf?.configAlbumViewFrame()
        }
    }
    func fetchPhotoAssets() {
        weak var weakSelf = self
        pickerController!.fetchPhotoAssets(assetCollection: assetCollection) { (photoAssets, photoAsset) in
            weakSelf?.canAddCamera = true
            weakSelf?.assets = photoAssets
            weakSelf?.setupEmptyView()
            weakSelf?.collectionView.reloadData()
            weakSelf?.scrollToAppropriatePlace(photoAsset: photoAsset)
            if weakSelf != nil && weakSelf!.showLoading {
                HXPHProgressHUD.hideHUD(forView: weakSelf?.view, animated: true)
                weakSelf?.showLoading = false
            }else {
                HXPHProgressHUD.hideHUD(forView: weakSelf?.navigationController?.view, animated: false)
            }
        }
    }
}

// MARK: Function
extension HXPHPickerViewController {
    
    func initView() {
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = .all
        view.addSubview(collectionView)
        if isMultipleSelect {
            view.addSubview(bottomView)
            bottomView.updateFinishButtonTitle()
        }
        if pickerController!.config.albumShowMode == .popup {
            var cancelItem: UIBarButtonItem
            if config.cancelType == .text {
                cancelItem = UIBarButtonItem.init(title: "取消".localized, style: .done, target: self, action: #selector(didCancelItemClick))
            }else {
                cancelItem = UIBarButtonItem.init(image: UIImage.image(for: HXPHManager.shared.isDark ? config.cancelDarkImageName : config.cancelImageName), style: .done, target: self, action: #selector(didCancelItemClick))
            }
            if config.cancelPosition == .left {
                navigationItem.leftBarButtonItem = cancelItem
            }else {
                navigationItem.rightBarButtonItem = cancelItem
            }
            view.addSubview(albumBackgroudView)
            view.addSubview(albumView)
        }else {
            navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: "取消".localized, style: .done, target: self, action: #selector(didCancelItemClick))
        }
    }
    func configData() {
        isMultipleSelect = pickerController!.config.selectMode == .multiple
        if !pickerController!.config.allowSelectedTogether && pickerController!.config.maximumSelectedVideoCount == 1 &&
            pickerController!.config.selectType == .any &&
            isMultipleSelect {
            videoLoadSingleCell = true
        }
        config = pickerController!.config.photoList
        updateTitle()
    }
    func configColor() {
        let isDark = HXPHManager.shared.isDark
        view.backgroundColor = isDark ? config.backgroundDarkColor : config.backgroundColor
        collectionView.backgroundColor = isDark ? config.backgroundDarkColor : config.backgroundColor
        let titleColor = isDark ? pickerController?.config.navigationTitleDarkColor : pickerController?.config.navigationTitleColor
        if pickerController!.config.albumShowMode == .popup {
            titleView.titleColor = titleColor
        }else {
            titleLabel.textColor = titleColor
        }
    }
    func updateTitle() {
        if pickerController!.config.albumShowMode == .popup {
            titleView.title = assetCollection?.albumName
        }else {
            titleLabel.text = assetCollection?.albumName
        }
    }
    
    func setupEmptyView() {
        if assets.isEmpty {
            collectionView.addSubview(emptyView)
        }else {
            emptyView.removeFromSuperview()
        }
    }
    func scrollToCenter(for photoAsset: HXPHAsset?) {
        if assets.isEmpty || photoAsset == nil {
            return
        }
        var item = assets.firstIndex(of: photoAsset!)
        if item != nil {
            if needOffset {
                item! += 1
            }
            collectionView.scrollToItem(at: IndexPath(item: item!, section: 0), at: .centeredVertically, animated: false)
        }
    }
    func scrollCellToVisibleArea(_ cell: HXPHPickerBaseViewCell) {
        if assets.isEmpty {
            return
        }
        let rect = cell.imageView.convert(cell.imageView.bounds, to: view)
        if rect.minY - collectionView.contentInset.top < 0 {
            if let indexPath = collectionView.indexPath(for: cell) {
                collectionView.scrollToItem(at: indexPath, at: .top, animated: false)
            }
        }else if rect.maxY > view.height - collectionView.contentInset.bottom {
            if let indexPath = collectionView.indexPath(for: cell) {
                collectionView.scrollToItem(at: indexPath, at: .bottom, animated: false)
            }
        }
    }
    func scrollToAppropriatePlace(photoAsset: HXPHAsset?) {
        if assets.isEmpty {
            return
        }
        var item = !pickerController!.config.reverseOrder ? assets.count - 1 : 0
        if photoAsset != nil {
            item = assets.firstIndex(of: photoAsset!) ?? item
            if needOffset {
                item += 1
            }
        }
        collectionView.scrollToItem(at: IndexPath(item: item, section: 0), at: .centeredVertically, animated: false)
    }
    func getCell(for item: Int) -> HXPHPickerBaseViewCell? {
        if assets.isEmpty {
            return nil
        }
        let cell = collectionView.cellForItem(at: IndexPath.init(item: item, section: 0)) as? HXPHPickerBaseViewCell
        return cell
    }
    func getCell(for photoAsset: HXPHAsset) -> HXPHPickerBaseViewCell? {
        if assets.isEmpty {
            return nil
        }
        var item = assets.firstIndex(of: photoAsset)
        if item == nil {
            return nil
        }
        if needOffset {
            item! += 1
        }
        return getCell(for: item!)
    }
    func reloadCell(for photoAsset: HXPHAsset) {
        var item = assets.firstIndex(of: photoAsset)
        if item != nil {
            if needOffset {
                item! += 1
            }
            collectionView.reloadItems(at: [IndexPath.init(item: item!, section: 0)])
        }
    }
    func getPhotoAsset(for index: Int) -> HXPHAsset {
        var photoAsset: HXPHAsset
        if needOffset {
            photoAsset = assets[index - 1]
        }else {
            photoAsset = assets[index]
        }
        return photoAsset
    }
    func addedPhotoAsset(for photoAsset: HXPHAsset) {
        if pickerController!.config.reverseOrder {
            assets.insert(photoAsset, at: 0)
            collectionView.insertItems(at: [IndexPath(item: needOffset ? 1 : 0, section: 0)])
        }else {
            assets.append(photoAsset)
            collectionView.insertItems(at: [IndexPath(item: needOffset ? assets.count : assets.count - 1, section: 0)])
        }
    }
    func changedAssetCollection(collection: HXPHAssetCollection?) {
        _ = HXPHProgressHUD.showLoadingHUD(addedTo: navigationController?.view, animated: true)
        if collection == nil {
            updateTitle()
            fetchPhotoAssets()
            reloadAlbumData()
            return
        }
        if pickerController!.config.albumShowMode == .popup {
            assetCollection.isSelected = false
            collection?.isSelected = true
        }
        assetCollection = collection
        updateTitle()
        fetchPhotoAssets()
        reloadAlbumData()
    }
    func reloadAlbumData() {
        if pickerController!.config.albumShowMode == .popup {
            albumView.tableView.reloadData()
            albumView.updatePrompt()
        }
    }
    
    func updateBottomPromptView() {
        if isMultipleSelect {
            bottomView.updatePromptView()
        }
    }
    
    
    func updateCellSelectedTitle() {
        for visibleCell in collectionView.visibleCells {
            if visibleCell is HXPHPickerBaseViewCell, let photoAsset = (visibleCell as? HXPHPickerBaseViewCell)?.photoAsset, let pickerController = pickerController {
                let cell = visibleCell as! HXPHPickerBaseViewCell
                if !photoAsset.isSelected && config.cell.showDisableMask {
                    cell.canSelect = pickerController.canSelectAsset(for: photoAsset, showHUD: false)
                }
                cell.updateSelectedState(isSelected: photoAsset.isSelected, animated: false)
            }
        }
    }
}
// MARK: Action
extension HXPHPickerViewController {
     
    @objc func didTitleViewClick(control: HXAlbumTitleView) {
        control.isSelected = !control.isSelected
        if control.isSelected {
            // 展开
            if albumView.assetCollectionsArray.isEmpty {
//                HXPHProgressHUD.showLoadingHUD(addedTo: view, animated: true)
//                HXPHProgressHUD.hideHUD(forView: weakSelf?.navigationController?.view, animated: true)
                control.isSelected = false
                return
            }
            openAlbumView()
        }else {
            // 收起
            closeAlbumView()
        }
    }
    
    @objc func didAlbumBackgroudViewClick() {
        titleView.isSelected = false
        closeAlbumView()
    }
    
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
        } completion: { (isFinish) in
            if isFinish {
                self.albumBackgroudView.isHidden = true
            }
        }
    }
    
    func configAlbumViewFrame() {
        self.albumView.size = CGSize(width: view.width, height: getAlbumViewHeight())
        if titleView.isSelected {
            if self.navigationController?.modalPresentationStyle == UIModalPresentationStyle.fullScreen && UIDevice.current.isPortrait {
                self.albumView.y = UIDevice.current.navigationBarHeight
            }else {
                self.albumView.y = self.navigationController?.navigationBar.height ?? 0
            }
        }else {
            self.albumView.y = -self.albumView.height
        }
    }
    
    func getAlbumViewHeight() -> CGFloat {
        var albumViewHeight = CGFloat(albumView.assetCollectionsArray.count) * albumView.config.cellHeight
        if HXPHAssetManager.authorizationStatusIsLimited() &&
            pickerController!.config.allowLoadPhotoLibrary {
            albumViewHeight += 40
        }
        if albumViewHeight > view.height * 0.75 {
            albumViewHeight = view.height * 0.75
        }
        return albumViewHeight
    }
    
    @objc func didCancelItemClick() {
        pickerController?.cancelCallback()
    }
}

// MARK: UICollectionViewDataSource
extension HXPHPickerViewController: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return config.allowAddCamera && canAddCamera && pickerController != nil ? assets.count + 1 : assets.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if config.allowAddCamera && canAddCamera && pickerController != nil {
            if !pickerController!.config.reverseOrder {
                if indexPath.item == assets.count {
                    return self.cameraCell
                }
            }else {
                if indexPath.item == 0 {
                    return self.cameraCell
                }
            }
        }
        let cell: HXPHPickerBaseViewCell
        let photoAsset = getPhotoAsset(for: indexPath.item)
        if pickerController?.config.selectMode == .single || (photoAsset.mediaType == .video && videoLoadSingleCell) {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(HXPHPickerViewCell.classForCoder()), for: indexPath) as! HXPHPickerBaseViewCell
        }else {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(HXPHPickerSelectableViewCell.classForCoder()), for: indexPath) as! HXPHPickerBaseViewCell
        }
        cell.delegate = self
        cell.config = config.cell
        cell.photoAsset = photoAsset
        return cell
    }
}

// MARK: UICollectionViewDelegate
extension HXPHPickerViewController: UICollectionViewDelegate {
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let pickerController = pickerController, cell is HXPHPickerBaseViewCell {
            let myCell: HXPHPickerBaseViewCell = cell as! HXPHPickerBaseViewCell
            let photoAsset = getPhotoAsset(for: indexPath.item)
            if !photoAsset.isSelected && config.cell.showDisableMask {
                myCell.canSelect = pickerController.canSelectAsset(for: photoAsset, showHUD: false)
            }else {
                myCell.canSelect = true
            }
        }
    }
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let myCell: HXPHPickerBaseViewCell? = cell as? HXPHPickerBaseViewCell
        myCell?.cancelRequest()
    }
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if navigationController?.topViewController != self {
            return
        }
        collectionView.deselectItem(at: indexPath, animated: false)
        let cell = collectionView.cellForItem(at: indexPath)
        if cell == nil {
            return
        }
        if cell is HXPHPickerCamerViewCell {
            if !UIImagePickerController.isSourceTypeAvailable(.camera) {
                HXPHProgressHUD.showWarningHUD(addedTo: self.navigationController?.view, text: "相机不可用!".localized, animated: true, delay: 1.5)
                return
            }
            HXPHAssetManager.requestCameraAccess { (granted) in
                if granted {
                    self.presentCameraViewController()
                }else {
                    HXPHTools.showNotCameraAuthorizedAlert(viewController: self)
                }
            }
        }else if cell is HXPHPickerBaseViewCell {
            let myCell = cell as! HXPHPickerBaseViewCell
            if !myCell.canSelect {
                return
            }
            if let pickerController = pickerController {
                if !pickerController.shouldClickCell(photoAsset: myCell.photoAsset!, index: indexPath.item) {
                    return
                }
            }
            pushPreviewViewController(previewAssets: assets, currentPreviewIndex: needOffset ? indexPath.item - 1 : indexPath.item)
        }
    }
}

// MARK: UIImagePickerControllerDelegate
extension HXPHPickerViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func presentCameraViewController() {
        if let pickerController = pickerController {
            if !pickerController.shouldPresentCamera() {
                return
            }
        }
        let imagePickerController = HXPHCameraPickerController.init()
        imagePickerController.sourceType = .camera
        imagePickerController.delegate = self
        imagePickerController.videoMaximumDuration = config.camera.videoMaximumDuration
        imagePickerController.videoQuality = config.camera.videoQuality
        imagePickerController.allowsEditing = config.camera.allowsEditing
        imagePickerController.cameraDevice = config.camera.cameraDevice
        var mediaTypes: [String]
        if !config.camera.mediaTypes.isEmpty {
            mediaTypes = config.camera.mediaTypes
        }else {
            switch pickerController!.config.selectType {
            case .photo:
                mediaTypes = [kUTTypeImage as String]
                break
            case .video:
                mediaTypes = [kUTTypeMovie as String]
                break
            default:
                mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
            }
        }
        imagePickerController.mediaTypes = mediaTypes
        present(imagePickerController, animated: true, completion: nil)
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        _ = HXPHProgressHUD.showLoadingHUD(addedTo: self.navigationController?.view, animated: true)
        picker.dismiss(animated: true, completion: nil)
        DispatchQueue.global().async {
            let mediaType = info[.mediaType] as! String
            var photoAsset: HXPHAsset
            if mediaType == kUTTypeImage as String {
                var image: UIImage? = (info[.editedImage] ?? info[.originalImage]) as? UIImage
                image = image?.scaleSuitableSize()
                if let image = image, self.config.saveSystemAlbum {
                    self.saveSystemAlbum(for: image, mediaType: .photo)
                    return
                }
                photoAsset = HXPHAsset.init(image: image, localIdentifier: String(Date.init().timeIntervalSince1970))
            }else {
                let startTime = info[UIImagePickerController.InfoKey.init(rawValue: "_UIImagePickerControllerVideoEditingStart")] as? TimeInterval
                let endTime = info[UIImagePickerController.InfoKey.init(rawValue: "_UIImagePickerControllerVideoEditingEnd")] as? TimeInterval
                let videoURL: URL? = info[.mediaURL] as? URL
                if startTime != nil && endTime != nil && videoURL != nil {
                    let avAsset = AVAsset.init(url: videoURL!)
                    HXPHTools.exportEditVideo(for: avAsset, startTime: startTime!, endTime: endTime!, presentName: self.config.camera.videoEditExportQuality) { (url, error) in
                        if let url = url, error == nil {
                            if self.config.saveSystemAlbum {
                                self.saveSystemAlbum(for: url, mediaType: .video)
                                return
                            }
                            let phAsset: HXPHAsset = HXPHAsset.init(videoURL: url, localIdentifier: String(Date.init().timeIntervalSince1970))
                            self.addedCameraPhotoAsset(phAsset)
                        }else {
                            HXPHProgressHUD.hideHUD(forView: self.navigationController?.view, animated: false)
                            HXPHProgressHUD.showWarningHUD(addedTo: self.navigationController?.view, text: "视频导出失败".localized, animated: true, delay: 1.5)
                        }
                    }
                    return
                }else {
                    if let videoURL = videoURL, self.config.saveSystemAlbum {
                        self.saveSystemAlbum(for: videoURL, mediaType: .video)
                        return
                    }
                    photoAsset = HXPHAsset.init(videoURL: videoURL, localIdentifier: String(Date.init().timeIntervalSince1970))
                }
            }
            self.addedCameraPhotoAsset(photoAsset)
        }
    }
    func saveSystemAlbum(for asset: Any, mediaType: HXPHPicker.Asset.MediaType) {
        HXPHAssetManager.saveSystemAlbum(forAsset: asset, mediaType: mediaType, customAlbumName: config.customAlbumName, creationDate: nil, location: nil) { (phAsset) in
            if let phAsset = phAsset {
                self.addedCameraPhotoAsset(HXPHAsset.init(asset: phAsset))
            }else {
                DispatchQueue.main.async {
                    HXPHProgressHUD.hideHUD(forView: self.navigationController?.view, animated: true)
                    HXPHProgressHUD.showWarningHUD(addedTo: self.navigationController?.view, text: "保存失败".localized, animated: true, delay: 1.5)
                }
            }
        }
    }
    func addedCameraPhotoAsset(_ photoAsset: HXPHAsset) {
        DispatchQueue.main.async {
            HXPHProgressHUD.hideHUD(forView: self.navigationController?.view, animated: true)
            if self.config.takePictureCompletionToSelected {
                if self.pickerController!.addedPhotoAsset(photoAsset: photoAsset) {
                    self.updateCellSelectedTitle()
                }
            }
            self.pickerController?.updateAlbums(coverImage: photoAsset.originalImage, count: 1)
            if photoAsset.mediaSubType == .localImage || photoAsset.mediaSubType == .localVideo {
                self.pickerController?.addedLocalCameraAsset(photoAsset: photoAsset)
            }
            if self.pickerController!.config.albumShowMode == .popup {
                self.albumView.tableView.reloadData()
            }
            self.addedPhotoAsset(for: photoAsset)
            self.bottomView.updateFinishButtonTitle()
            self.setupEmptyView()
        }
    }
}

// MARK: HXPHPreviewViewControllerDelegate
extension HXPHPickerViewController: HXPHPreviewViewControllerDelegate  {
    
    func pushPreviewViewController(previewAssets: [HXPHAsset], currentPreviewIndex: Int) {
        let vc = HXPHPreviewViewController.init()
        vc.previewAssets = previewAssets
        vc.currentPreviewIndex = currentPreviewIndex
        vc.delegate = self
        navigationController?.delegate = vc
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func previewViewController(_ previewController: HXPHPreviewViewController, didOriginalButton isOriginal: Bool) {
        if isMultipleSelect {
            bottomView.boxControl.isSelected = isOriginal
            bottomView.requestAssetBytes()
        }
    }
    func previewViewController(_ previewController: HXPHPreviewViewController, didSelectBox photoAsset: HXPHAsset, isSelected: Bool) {
        updateCellSelectedTitle()
        bottomView.updateFinishButtonTitle()
    }
}

// MARK: HXAlbumViewDelegate
extension HXPHPickerViewController: HXAlbumViewDelegate {
    
    func albumView(_ albumView: HXAlbumView, didSelectRowAt assetCollection: HXPHAssetCollection) {
        didAlbumBackgroudViewClick()
        if self.assetCollection == assetCollection {
            return
        }
        titleView.title = assetCollection.albumName
        assetCollection.isSelected = true
        self.assetCollection.isSelected = false
        self.assetCollection = assetCollection
        _ = HXPHProgressHUD.showLoadingHUD(addedTo: navigationController?.view, animated: true)
        fetchPhotoAssets()
    }
}

// MARK: HXPHPickerBottomViewDelegate
extension HXPHPickerViewController: HXPHPickerBottomViewDelegate {
    
    func bottomView(didPreviewButtonClick view: HXPHPickerBottomView) {
        pushPreviewViewController(previewAssets: pickerController!.selectedAssetArray, currentPreviewIndex: 0)
    }
    func bottomView(didFinishButtonClick view: HXPHPickerBottomView) {
        pickerController?.finishCallback()
    }
    func bottomView(didOriginalButtonClick view: HXPHPickerBottomView, with isOriginal: Bool) {
        pickerController?.originalButtonCallback()
    }
}

// MARK: HXPHPickerViewCellDelegate
extension HXPHPickerViewController: HXPHPickerViewCellDelegate {
    
    public func cell(didSelectControl cell: HXPHPickerBaseViewCell, isSelected: Bool) {
        if isSelected {
            // 取消选中
            _ = pickerController?.removePhotoAsset(photoAsset: cell.photoAsset!)
            cell.updateSelectedState(isSelected: false, animated: true)
            updateCellSelectedTitle()
        }else {
            // 选中
            if pickerController!.addedPhotoAsset(photoAsset: cell.photoAsset!) {
                cell.updateSelectedState(isSelected: true, animated: true)
                updateCellSelectedTitle()
            }
        }
        bottomView.updateFinishButtonTitle()
    }
}

// MARK: Notification
extension HXPHPickerViewController {
    
    @objc func deviceOrientationChanged(notify: Notification) {
        beforeOrientationIndexPath = collectionView.indexPathsForVisibleItems.first
        orientationDidChange = true
    }
}
