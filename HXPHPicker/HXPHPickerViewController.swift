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

class HXPHPickerViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, HXPHPickerViewCellDelegate, HXPHPickerBottomViewDelegate, HXPHPreviewViewControllerDelegate, HXAlbumViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
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
        if let customMultipleCellClass = config.cell.customMultipleCellClass {
            collectionView.register(customMultipleCellClass, forCellWithReuseIdentifier: NSStringFromClass(HXPHPickerMultiSelectViewCell.classForCoder()))
        }else {
            collectionView.register(HXPHPickerMultiSelectViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(HXPHPickerMultiSelectViewCell.classForCoder()))
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
            if !hx_pickerController!.config.reverseOrder {
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
        let emptyView = HXPHEmptyView.init(frame: CGRect(x: 0, y: 0, width: view.hx_width, height: 0))
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
            return hx_pickerController != nil && hx_pickerController!.config.reverseOrder && config.allowAddCamera && canAddCamera
        }
    }
    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel.init()
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.textAlignment = .center
        return titleLabel
    }()
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
                control.isSelected = false
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
        albumBackgroudView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
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
        } completion: { (isFinish) in
            if isFinish {
                self.albumBackgroudView.isHidden = true
            }
        }
    }
    
    func configAlbumViewFrame() {
        self.albumView.hx_size = CGSize(width: view.hx_width, height: getAlbumViewHeight())
        if titleView.isSelected {
            if self.navigationController?.modalPresentationStyle == UIModalPresentationStyle.fullScreen && UIDevice.current.hx_isPortrait {
                self.albumView.hx_y = UIDevice.current.hx_navigationBarHeight
            }else {
                self.albumView.hx_y = self.navigationController?.navigationBar.hx_height ?? 0
            }
        }else {
            self.albumView.hx_y = -self.albumView.hx_height
        }
    }
    
    func getAlbumViewHeight() -> CGFloat {
        var albumViewHeight = CGFloat(albumView.assetCollectionsArray.count) * albumView.config.cellHeight
        if HXPHAssetManager.authorizationStatusIsLimited() &&
            hx_pickerController!.config.allowLoadPhotoLibrary {
            albumViewHeight += 40
        }
        if albumViewHeight > view.hx_height * 0.75 {
            albumViewHeight = view.hx_height * 0.75
        }
        return albumViewHeight
    }
    
    lazy var bottomView : HXPHPickerBottomView = {
        let bottomView = HXPHPickerBottomView.init(config: config.bottomView, allowLoadPhotoLibrary: allowLoadPhotoLibrary)
        bottomView.hx_delegate = self
        bottomView.boxControl.isSelected = hx_pickerController!.isOriginal
        return bottomView
    }()
    var allowLoadPhotoLibrary: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        allowLoadPhotoLibrary = hx_pickerController?.config.allowLoadPhotoLibrary ?? true
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
    @objc func deviceOrientationChanged(notify: Notification) {
        beforeOrientationIndexPath = collectionView.indexPathsForVisibleItems.first
        orientationDidChange = true
    }
    func configData() {
        isMultipleSelect = hx_pickerController!.config.selectMode == .multiple
        if !hx_pickerController!.config.allowSelectedTogether && hx_pickerController!.config.maximumSelectedVideoCount == 1 &&
            hx_pickerController!.config.selectType == .any &&
            isMultipleSelect {
            videoLoadSingleCell = true
        }
        config = hx_pickerController!.config.photoList
        updateTitle()
    }
    func configColor() {
        let isDark = HXPHManager.shared.isDark
        view.backgroundColor = isDark ? config.backgroundDarkColor : config.backgroundColor
        collectionView.backgroundColor = isDark ? config.backgroundDarkColor : config.backgroundColor
        let titleColor = isDark ? hx_pickerController?.config.navigationTitleDarkColor : hx_pickerController?.config.navigationTitleColor
        if hx_pickerController!.config.albumShowMode == .popup {
            titleView.titleColor = titleColor
        }else {
            titleLabel.textColor = titleColor
        }
    }
    @objc func didCancelItemClick() {
        hx_pickerController?.cancelCallback()
    }
    
    func initView() {
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = .all
        view.addSubview(collectionView)
        if isMultipleSelect {
            view.addSubview(bottomView)
            bottomView.updateFinishButtonTitle()
        }
        if hx_pickerController!.config.albumShowMode == .popup {
            var cancelItem: UIBarButtonItem
            if config.cancelType == .text {
                cancelItem = UIBarButtonItem.init(title: "取消".hx_localized, style: .done, target: self, action: #selector(didCancelItemClick))
            }else {
                cancelItem = UIBarButtonItem.init(image: UIImage.hx_named(named: HXPHManager.shared.isDark ? config.cancelDarkImageName : config.cancelImageName), style: .done, target: self, action: #selector(didCancelItemClick))
            }
            if config.cancelPosition == .left {
                navigationItem.leftBarButtonItem = cancelItem
            }else {
                navigationItem.rightBarButtonItem = cancelItem
            }
            view.addSubview(albumBackgroudView)
            view.addSubview(albumView)
        }
    }
    func updateTitle() {
        if hx_pickerController!.config.albumShowMode == .popup {
            titleView.title = assetCollection?.albumName
        }else {
            titleLabel.text = assetCollection?.albumName
//            title = assetCollection.albumName
        }
    }
    func fetchData() {
        if hx_pickerController!.config.albumShowMode == .popup {
            fetchAssetCollections()
            title = ""
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
                        cameraAssetCollection = HXPHAssetCollection.init(albumName: self.hx_pickerController!.config.albumList.emptyAlbumName.hx_localized, coverImage: self.hx_pickerController!.config.albumList.emptyCoverImageName.hx_image)
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
        if !hx_pickerController!.assetCollectionsArray.isEmpty {
            albumView.assetCollectionsArray = hx_pickerController!.assetCollectionsArray
            albumView.currentSelectedAssetCollection = assetCollection
            configAlbumViewFrame()
        }
        fetchAssetCollectionsClosure()
        if !hx_pickerController!.config.allowLoadPhotoLibrary {
            hx_pickerController?.fetchAssetCollections()
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
            weakSelf?.canAddCamera = true
            weakSelf?.assets = photoAssets
            weakSelf?.setupEmptyView()
//            if weakSelf != nil {
//                UIView.transition(with: weakSelf!.collectionView, duration: 0.05, options: .transitionCrossDissolve) {
                    weakSelf?.collectionView.reloadData()
//                } completion: { (isFinished) in }
//            }
            weakSelf?.scrollToAppropriatePlace(photoAsset: photoAsset)
            if weakSelf != nil && weakSelf!.showLoading {
                HXPHProgressHUD.hideHUD(forView: weakSelf?.view, animated: true)
                weakSelf?.showLoading = false
            }else {
                HXPHProgressHUD.hideHUD(forView: weakSelf?.navigationController?.view, animated: false)
            }
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
    func scrollCellToVisibleArea(_ cell: HXPHPickerViewCell) {
        if assets.isEmpty {
            return
        }
        let rect = cell.imageView.convert(cell.imageView.bounds, to: view)
        if rect.minY - collectionView.contentInset.top < 0 {
            if let indexPath = collectionView.indexPath(for: cell) {
                collectionView.scrollToItem(at: indexPath, at: .top, animated: false)
            }
        }else if rect.maxY > view.hx_height - collectionView.contentInset.bottom {
            if let indexPath = collectionView.indexPath(for: cell) {
                collectionView.scrollToItem(at: indexPath, at: .bottom, animated: false)
            }
        }
    }
    func scrollToAppropriatePlace(photoAsset: HXPHAsset?) {
        if assets.isEmpty {
            return
        }
        var item = !hx_pickerController!.config.reverseOrder ? assets.count - 1 : 0
        if photoAsset != nil {
            item = assets.firstIndex(of: photoAsset!) ?? item
            if needOffset {
                item += 1
            }
        }
        collectionView.scrollToItem(at: IndexPath(item: item, section: 0), at: .centeredVertically, animated: false)
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
        if hx_pickerController!.config.reverseOrder {
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
            albumView.updatePrompt()
        }
    }
    
    func updateBottomPromptView() {
        if isMultipleSelect {
            bottomView.updatePromptView()
        }
    }
    
    // MARK: UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return config.allowAddCamera && canAddCamera && hx_pickerController != nil ? assets.count + 1 : assets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if config.allowAddCamera && canAddCamera && hx_pickerController != nil {
            if !hx_pickerController!.config.reverseOrder {
                if indexPath.item == assets.count {
                    return self.cameraCell
                }
            }else {
                if indexPath.item == 0 {
                    return self.cameraCell
                }
            }
        }
        let cell: HXPHPickerViewCell
        let photoAsset = getPhotoAsset(for: indexPath.item)
        if hx_pickerController?.config.selectMode == .single || (photoAsset.mediaType == .video && videoLoadSingleCell) {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(HXPHPickerViewCell.classForCoder()), for: indexPath) as! HXPHPickerViewCell
        }else {
            let multiSelectCell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(HXPHPickerMultiSelectViewCell.classForCoder()), for: indexPath) as! HXPHPickerMultiSelectViewCell
            multiSelectCell.delegate = self
            cell = multiSelectCell
        }
        cell.config = config.cell
        cell.photoAsset = photoAsset
        return cell
    }
    // MARK: UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let pickerController = hx_pickerController, cell is HXPHPickerViewCell {
            let myCell: HXPHPickerViewCell = cell as! HXPHPickerViewCell
            let photoAsset = getPhotoAsset(for: indexPath.item)
            if !photoAsset.isSelected && config.cell.showDisableMask {
                myCell.canSelect = pickerController.canSelectAsset(for: photoAsset, showHUD: false)
            }else {
                myCell.canSelect = true
            }
        }
    }
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let myCell: HXPHPickerViewCell? = cell as? HXPHPickerViewCell
        myCell?.cancelRequest()
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
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
                HXPHProgressHUD.showWarningHUD(addedTo: self.navigationController?.view, text: "相机不可用!".hx_localized, animated: true, delay: 1.5)
                return
            }
            HXPHAssetManager.requestCameraAccess { (granted) in
                if granted {
                    self.presentCameraViewController()
                }else {
                    HXPHTools.showNotCameraAuthorizedAlert(viewController: self)
                }
            }
        }else if cell is HXPHPickerViewCell {
            let myCell = cell as! HXPHPickerViewCell
            if !myCell.canSelect {
                return
            }
            pushPreviewViewController(previewAssets: assets, currentPreviewIndex: needOffset ? indexPath.item - 1 : indexPath.item)
        }
    }
    func pushPreviewViewController(previewAssets: [HXPHAsset], currentPreviewIndex: Int) {
        let vc = HXPHPreviewViewController.init()
        vc.previewAssets = previewAssets
        vc.currentPreviewIndex = currentPreviewIndex
        vc.delegate = self
        navigationController?.delegate = vc
        navigationController?.pushViewController(vc, animated: true)
    }
    func presentCameraViewController() {
        if let pickerController = hx_pickerController {
            if !pickerController.shouldPresentCamera() {
                return
            }
        }
        let imagePickerController = HXPHImagePickerController.init()
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
            switch hx_pickerController!.config.selectType {
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
    // MARK: UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        _ = HXPHProgressHUD.showLoadingHUD(addedTo: self.navigationController?.view, animated: true)
        DispatchQueue.global().async {
            let mediaType = info[.mediaType] as! String
            var photoAsset: HXPHAsset
            if mediaType == kUTTypeImage as String {
                var image: UIImage? = (info[.editedImage] ?? info[.originalImage]) as? UIImage
                image = image?.hx_scaleSuitableSize()
                photoAsset = HXPHAsset.init(image: image, localIdentifier: String(Date.init().timeIntervalSince1970))
            }else {
                let startTime = info[UIImagePickerController.InfoKey.init(rawValue: "_UIImagePickerControllerVideoEditingStart")] as? TimeInterval
                let endTime = info[UIImagePickerController.InfoKey.init(rawValue: "_UIImagePickerControllerVideoEditingEnd")] as? TimeInterval
                let videoURL: URL? = info[.mediaURL] as? URL
                if startTime != nil && endTime != nil && videoURL != nil {
                    let avAsset = AVAsset.init(url: videoURL!)
                    HXPHTools.exportEditVideo(for: avAsset, startTime: startTime!, endTime: endTime!, presentName: self.config.camera.videoEditExportQuality) { (url, error) in
                        if error == nil {
                            let phAsset: HXPHAsset = HXPHAsset.init(videoURL: url, localIdentifier: String(Date.init().timeIntervalSince1970))
                            self.addedCameraPhotoAsset(phAsset)
                        }else {
                            HXPHProgressHUD.hideHUD(forView: self.navigationController?.view, animated: false)
                            HXPHProgressHUD.showWarningHUD(addedTo: self.navigationController?.view, text: "视频导出失败".hx_localized, animated: true, delay: 1.5)
                        }
                    }
                    return
                }else {
                    photoAsset = HXPHAsset.init(videoURL: videoURL, localIdentifier: String(Date.init().timeIntervalSince1970))
                }
            }
            self.addedCameraPhotoAsset(photoAsset)
        }
        picker.dismiss(animated: true, completion: nil)
    }
    func addedCameraPhotoAsset(_ photoAsset: HXPHAsset) {
        DispatchQueue.main.async {
            HXPHProgressHUD.hideHUD(forView: self.navigationController?.view, animated: true)
            if self.config.camera.takePictureCompletionToSelected {
                if self.hx_pickerController!.addedPhotoAsset(photoAsset: photoAsset) {
                    self.updateCellSelectedTitle()
                }
            }
            self.hx_pickerController?.updateAlbums(coverImage: photoAsset.originalImage, count: 1)
            self.hx_pickerController?.addedLocalCameraAsset(photoAsset: photoAsset)
            if self.hx_pickerController!.config.albumShowMode == .popup {
                self.albumView.tableView.reloadData()
            }
            self.addedPhotoAsset(for: photoAsset)
            self.bottomView.updateFinishButtonTitle()
            self.setupEmptyView()
        }
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
        _ = HXPHProgressHUD.showLoadingHUD(addedTo: navigationController?.view, animated: true)
        fetchPhotoAssets()
    }
    
    // MARK: HXPHPickerViewCellDelegate
    func cell(didSelectControl cell: HXPHPickerMultiSelectViewCell, isSelected: Bool) {
        if isSelected {
            // 取消选中
            _ = hx_pickerController?.removePhotoAsset(photoAsset: cell.photoAsset!)
            cell.updateSelectedState(isSelected: false, animated: true)
            updateCellSelectedTitle()
        }else {
            // 选中
            if hx_pickerController!.addedPhotoAsset(photoAsset: cell.photoAsset!) {
                cell.updateSelectedState(isSelected: true, animated: true)
                updateCellSelectedTitle()
            }
        }
        bottomView.updateFinishButtonTitle()
    }
    
    func updateCellSelectedTitle() {
        for visibleCell in collectionView.visibleCells {
            if visibleCell is HXPHPickerViewCell {
                let cell = visibleCell as! HXPHPickerViewCell
                if !cell.photoAsset!.isSelected && config.cell.showDisableMask {
                    cell.canSelect = hx_pickerController!.canSelectAsset(for: cell.photoAsset!, showHUD: false)
                }
                if visibleCell is HXPHPickerMultiSelectViewCell {
                    let cell = visibleCell as! HXPHPickerMultiSelectViewCell
                    if cell.photoAsset!.isSelected {
                        if Int(cell.selectControl.text) != (cell.photoAsset!.selectIndex + 1) {
                            cell.updateSelectedState(isSelected: true, animated: false)
                        }
                    }else if cell.selectControl.isSelected {
                        cell.updateSelectedState(isSelected: false, animated: false)
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
    func bottomViewDidSelectedViewClick(_ bottomView: HXPHPickerBottomView, didSelectedItemAt photoAsset: HXPHAsset) { } 
    
    // MARK: HXPHPreviewViewControllerDelegate
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
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let margin: CGFloat = UIDevice.current.hx_leftMargin
        collectionView.frame = CGRect(x: margin, y: 0, width: view.hx_width - 2 * margin, height: view.hx_height)
        var collectionTop: CGFloat
        if navigationController?.modalPresentationStyle == .fullScreen && UIDevice.current.hx_isPortrait {
            collectionTop = UIDevice.current.hx_navigationBarHeight
        }else {
            collectionTop = navigationController!.navigationBar.hx_height
        }
        if let pickerController = hx_pickerController {
            if pickerController.config.albumShowMode == .popup {
                albumBackgroudView.frame = view.bounds
                configAlbumViewFrame()
            }else {
                titleLabel.hx_size = CGSize(width: view.hx_width * 0.6, height: 30)
            }
        }
        if isMultipleSelect {
            let promptHeight: CGFloat = (HXPHAssetManager.authorizationStatusIsLimited() && config.bottomView.showPrompt && allowLoadPhotoLibrary) ? 70 : 0
            let bottomHeight: CGFloat = 50 + UIDevice.current.hx_bottomMargin + promptHeight
            bottomView.frame = CGRect(x: 0, y: view.hx_height - bottomHeight, width: view.hx_width, height: bottomHeight)
            collectionView.contentInset = UIEdgeInsets(top: collectionTop, left: 0, bottom: bottomView.hx_height + 0.5, right: 0)
            collectionView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: bottomHeight - UIDevice.current.hx_bottomMargin, right: 0)
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
            if hx_pickerController != nil && hx_pickerController!.config.albumShowMode == .popup {
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
        emptyView.hx_width = collectionView.hx_width
        emptyView.center = CGPoint(x: collectionView.hx_width * 0.5, y: (collectionView.hx_height - collectionView.contentInset.top - collectionView.contentInset.bottom) * 0.5)
    }
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if #available(iOS 13.0, *) {
            beforeOrientationIndexPath = collectionView.indexPathsForVisibleItems.first
            orientationDidChange = true
        }
        super.viewWillTransition(to: size, with: coordinator)
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

protocol HXPHPickerBottomViewDelegate: NSObjectProtocol {
    func bottomViewDidPreviewButtonClick(view: HXPHPickerBottomView)
    func bottomViewDidFinishButtonClick(view: HXPHPickerBottomView)
    func bottomViewDidOriginalButtonClick(view: HXPHPickerBottomView, with isOriginal: Bool)
    func bottomViewDidSelectedViewClick(_ bottomView: HXPHPickerBottomView, didSelectedItemAt photoAsset: HXPHAsset)
}

class HXPHPickerBottomView: UIToolbar, HXPHPreviewSelectedViewDelegate {
    
    weak var hx_delegate: HXPHPickerBottomViewDelegate?
    
    var config: HXPHPickerBottomViewConfiguration
    
    lazy var selectedView: HXPHPreviewSelectedView = {
        let selectedView = HXPHPreviewSelectedView.init(frame: CGRect(x: 0, y: 0, width: hx_width, height: 70))
        selectedView.delegate = self
        selectedView.tickColor = config.selectedViewTickColor
        return selectedView
    }()
    
    lazy var promptView: UIView = {
        let promptView = UIView.init(frame: CGRect(x: 0, y: 0, width: hx_width, height: 70))
        promptView.addSubview(promptIcon)
        promptView.addSubview(promptLb)
        promptView.addSubview(promptArrow)
        promptView.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(didPromptViewClick)))
        return promptView
    }()
    @objc func didPromptViewClick() {
        HXPHTools.openSettingsURL()
    }
    lazy var promptLb: UILabel = {
        let promptLb = UILabel.init(frame: CGRect(x: 0, y: 0, width: 0, height: 60))
        promptLb.text = "无法访问相册中所有照片，\n请允许访问「照片」中的「所有照片」".hx_localized
        promptLb.font = UIFont.systemFont(ofSize: 15)
        promptLb.numberOfLines = 0
        promptLb.adjustsFontSizeToFitWidth = true
        return promptLb
    }()
    lazy var promptIcon: UIImageView = {
        let image = UIImage.hx_named(named: "hx_picker_photolist_bottom_prompt")?.withRenderingMode(.alwaysTemplate)
        let promptIcon = UIImageView.init(image: image)
        promptIcon.hx_size = promptIcon.image?.size ?? CGSize.zero
        return promptIcon
    }()
    lazy var promptArrow: UIImageView = {
        let image = UIImage.hx_named(named: "hx_picker_photolist_bottom_prompt_arrow")?.withRenderingMode(.alwaysTemplate)
        let promptArrow = UIImageView.init(image: image)
        promptArrow.hx_size = promptArrow.image?.size ?? CGSize.zero
        return promptArrow
    }()
    
    lazy var contentView: UIView = {
        let contentView = UIView.init(frame: CGRect(x: 0, y: 0, width: hx_width, height: 50 + UIDevice.current.hx_bottomMargin))
        contentView.addSubview(previewBtn)
        contentView.addSubview(editBtn)
        contentView.addSubview(originalBtn)
        contentView.addSubview(finishBtn)
        return contentView
    }()
    
    lazy var previewBtn: UIButton = {
        let previewBtn = UIButton.init(type: .custom)
        previewBtn.setTitle("预览".hx_localized, for: .normal)
        previewBtn.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        previewBtn.isEnabled = false
        previewBtn.addTarget(self, action: #selector(didPreviewButtonClick(button:)), for: .touchUpInside)
        previewBtn.isHidden = config.previewButtonHidden
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
        editBtn.isHidden = config.editButtonHidden
        return editBtn
    }()
    
    @objc func didEditBtnButtonClick(button: UIButton) {
        hx_delegate?.bottomViewDidPreviewButtonClick(view: self)
    }
    
    lazy var originalBtn: UIView = {
        let originalBtn = UIView.init()
        originalBtn.addSubview(originalTitleLb)
        originalBtn.addSubview(boxControl)
        originalBtn.addSubview(originalLoadingView)
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(didOriginalButtonClick))
        originalBtn.addGestureRecognizer(tap)
        originalBtn.isHidden = config.originalButtonHidden
        return originalBtn
    }()
    
    @objc func didOriginalButtonClick() {
        boxControl.isSelected = !boxControl.isSelected
        if !boxControl.isSelected {
            // 取消
            cancelRequestAssetFileSize()
        }else {
            // 选中
            requestAssetBytes()
        }
        hx_viewController()?.hx_pickerController?.isOriginal = boxControl.isSelected
        hx_delegate?.bottomViewDidOriginalButtonClick(view: self, with: boxControl.isSelected)
        boxControl.layer.removeAnimation(forKey: "SelectControlAnimation")
        let keyAnimation = CAKeyframeAnimation.init(keyPath: "transform.scale")
        keyAnimation.duration = 0.3
        keyAnimation.values = [1.2, 0.8, 1.1, 0.9, 1.0]
        boxControl.layer.add(keyAnimation, forKey: "SelectControlAnimation")
    } 
    func requestAssetBytes() {
        if isExternalPreview {
           return
        }
        if !config.showOriginalFileSize || !isMultipleSelect {
            return
        }
        if !boxControl.isSelected {
            cancelRequestAssetFileSize()
            return
        }
        if let pickerController = hx_viewController()?.hx_pickerController {
            if pickerController.selectedAssetArray.isEmpty {
                cancelRequestAssetFileSize()
                return
            }
            originalLoadingDelayTimer?.invalidate()
            let timer = Timer.init(timeInterval: 0.1, target: self, selector: #selector(showOriginalLoading(timer:)), userInfo: nil, repeats: false)
            RunLoop.main.add(timer, forMode: .common)
            originalLoadingDelayTimer = timer
            pickerController.requestSelectedAssetFileSize(isPreview: isPreview) { (bytes, bytesString) in
                self.originalLoadingDelayTimer?.invalidate()
                self.originalLoadingDelayTimer = nil
                self.originalLoadingView.stopAnimating()
                self.showOriginalLoadingView = false
                self.originalTitleLb.text = "原图".hx_localized + " (" + bytesString + ")"
                self.updateOriginalButtonFrame()
            }
        }
    }
    @objc func showOriginalLoading(timer: Timer) {
        originalTitleLb.text = "原图".hx_localized
        showOriginalLoadingView = true
        originalLoadingView.startAnimating()
        updateOriginalButtonFrame()
        originalLoadingDelayTimer = nil
    }
    func cancelRequestAssetFileSize() {
        if isExternalPreview {
           return
        }
        if !config.showOriginalFileSize || !isMultipleSelect {
            return
        }
        originalLoadingDelayTimer?.invalidate()
        originalLoadingDelayTimer = nil
        if let pickerController = hx_viewController()?.hx_pickerController {
            pickerController.cancelRequestAssetFileSize(isPreview: isPreview)
        }
        showOriginalLoadingView = false
        originalLoadingView.stopAnimating()
        originalTitleLb.text = "原图".hx_localized
        updateOriginalButtonFrame()
    }
    lazy var originalTitleLb: UILabel = {
        let originalTitleLb = UILabel.init()
        originalTitleLb.text = "原图".hx_localized
        originalTitleLb.font = UIFont.systemFont(ofSize: 17)
        originalTitleLb.lineBreakMode = .byTruncatingHead
        return originalTitleLb
    }()
    
    lazy var boxControl: HXPHPickerSelectBoxView = {
        let boxControl = HXPHPickerSelectBoxView.init(frame: CGRect(x: 0, y: 0, width: 17, height: 17))
        boxControl.config = config.originalSelectBox
        boxControl.backgroundColor = UIColor.clear
        return boxControl
    }()
    var showOriginalLoadingView: Bool = false
    var originalLoadingDelayTimer: Timer?
    lazy var originalLoadingView: UIActivityIndicatorView = {
        let originalLoadingView = UIActivityIndicatorView.init(style: .white)
        originalLoadingView.hidesWhenStopped = true
        return originalLoadingView
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
    var allowLoadPhotoLibrary: Bool
    var isMultipleSelect : Bool
    var isExternalPreview: Bool
    var isPreview: Bool
    
    init(config: HXPHPickerBottomViewConfiguration, allowLoadPhotoLibrary: Bool, isMultipleSelect: Bool, isPreview: Bool, isExternalPreview: Bool) {
        self.isPreview = isPreview
        self.isExternalPreview = isExternalPreview
        self.allowLoadPhotoLibrary = allowLoadPhotoLibrary
        self.config = config
        self.isMultipleSelect = isMultipleSelect
        super.init(frame: CGRect.zero)
        if config.showPrompt && HXPHAssetManager.authorizationStatusIsLimited() && allowLoadPhotoLibrary && !isPreview && !isExternalPreview {
            addSubview(promptView)
        }
        if isExternalPreview {
            if config.showSelectedView {
                addSubview(selectedView)
            }
        }else {
            addSubview(contentView)
            if config.showSelectedView && isMultipleSelect {
                addSubview(selectedView)
            }
        }
        configColor()
        isTranslucent = config.isTranslucent
    }
    
    convenience init(config: HXPHPickerBottomViewConfiguration, allowLoadPhotoLibrary: Bool) {
        self.init(config: config, allowLoadPhotoLibrary: allowLoadPhotoLibrary, isMultipleSelect: true, isPreview: false, isExternalPreview: false)
    }
    func updatePromptView() {
        if config.showPrompt && HXPHAssetManager.authorizationStatusIsLimited() && allowLoadPhotoLibrary && !isPreview && !isExternalPreview {
            if promptView.superview == nil {
                addSubview(promptView)
                configPromptColor()
            }
        }
    }
    func configColor() {
        let isDark = HXPHManager.shared.isDark
        backgroundColor = isDark ? config.backgroundDarkColor : config.backgroundColor
        barTintColor = isDark ? config.barTintDarkColor : config.barTintColor
        barStyle = isDark ? config.barDarkStyle : config.barStyle
        if !isExternalPreview {
            previewBtn.setTitleColor(isDark ? config.previewButtonTitleDarkColor : config.previewButtonTitleColor, for: .normal)
            editBtn.setTitleColor(isDark ? config.editButtonTitleDarkColor : config.editButtonTitleColor, for: .normal)
            if isDark {
                if config.previewButtonDisableTitleDarkColor != nil {
                    previewBtn.setTitleColor(config.previewButtonDisableTitleDarkColor, for: .disabled)
                }else {
                    previewBtn.setTitleColor(config.previewButtonTitleDarkColor.withAlphaComponent(0.6), for: .disabled)
                }
                if config.editButtonDisableTitleDarkColor != nil {
                    editBtn.setTitleColor(config.editButtonDisableTitleDarkColor, for: .disabled)
                }else {
                    editBtn.setTitleColor(config.editButtonTitleDarkColor.withAlphaComponent(0.6), for: .disabled)
                }
            }else {
                if config.previewButtonDisableTitleColor != nil {
                    previewBtn.setTitleColor(config.previewButtonDisableTitleColor, for: .disabled)
                }else {
                    previewBtn.setTitleColor(config.previewButtonTitleColor.withAlphaComponent(0.6), for: .disabled)
                }
                if config.editButtonDisableTitleColor != nil {
                    editBtn.setTitleColor(config.editButtonDisableTitleColor, for: .disabled)
                }else {
                    editBtn.setTitleColor(config.editButtonTitleColor.withAlphaComponent(0.6), for: .disabled)
                }
            }
            originalLoadingView.style = isDark ? config.originalLoadingDarkStyle : config.originalLoadingStyle
            originalTitleLb.textColor = isDark ? config.originalButtonTitleDarkColor : config.originalButtonTitleColor
            
            let finishBtnBackgroundColor = isDark ? config.finishButtonDarkBackgroundColor : config.finishButtonBackgroundColor
            finishBtn.setTitleColor(isDark ? config.finishButtonTitleDarkColor : config.finishButtonTitleColor, for: .normal)
            finishBtn.setTitleColor(isDark ? config.finishButtonDisableTitleDarkColor : config.finishButtonDisableTitleColor, for: .disabled)
            finishBtn.setBackgroundImage(UIImage.hx_image(for: finishBtnBackgroundColor, havingSize: CGSize.zero), for: .normal)
            finishBtn.setBackgroundImage(UIImage.hx_image(for: isDark ? config.finishButtonDisableDarkBackgroundColor : config.finishButtonDisableBackgroundColor, havingSize: CGSize.zero), for: .disabled)
        }
        configPromptColor()
    }
    func configPromptColor() {
        if config.showPrompt && HXPHAssetManager.authorizationStatusIsLimited() && allowLoadPhotoLibrary && !isPreview && !isExternalPreview {
            let isDark = HXPHManager.shared.isDark
            promptLb.textColor = isDark ? config.promptTitleDarkColor : config.promptTitleColor
            promptIcon.tintColor = isDark ? config.promptIconDarkColor : config.promptIconColor
            promptArrow.tintColor = isDark ? config.promptArrowDarkColor : config.promptArrowColor
        }
    }
    func updateFinishButtonTitle() {
        if isExternalPreview {
           return
        }
        requestAssetBytes()
        var selectCount = 0
        if let pickerController = hx_viewController()?.hx_pickerController {
            if pickerController.config.selectMode == .multiple {
                selectCount = pickerController.selectedAssetArray.count
            }
        }
        if selectCount > 0 {
            finishBtn.isEnabled = true
            previewBtn.isEnabled = true
            finishBtn.setTitle("完成".hx_localized + " (" + String(format: "%d", arguments: [selectCount]) + ")", for: .normal)
        }else {
            finishBtn.isEnabled = !config.disableFinishButtonWhenNotSelected
            previewBtn.isEnabled = false
            finishBtn.setTitle("完成".hx_localized, for: .normal)
        }
        updateFinishButtonFrame()
    }
    func updateFinishButtonFrame() {
        if isExternalPreview {
           return
        }
        var finishWidth : CGFloat = finishBtn.currentTitle!.hx_localized.hx_stringWidth(ofFont: finishBtn.titleLabel!.font, maxHeight: 50) + 20
        if finishWidth < 60 {
            finishWidth = 60
        }
        finishBtn.frame = CGRect(x: hx_width - UIDevice.current.hx_rightMargin - finishWidth - 12, y: 0, width: finishWidth, height: 33)
        finishBtn.hx_centerY = 25
    }
    func updateOriginalButtonFrame() {
        if isExternalPreview {
           return
        }
        updateOriginalSubviewFrame()
        if showOriginalLoadingView {
            originalBtn.frame = CGRect(x: 0, y: 0, width: originalLoadingView.frame.maxX, height: 50)
        }else {
            originalBtn.frame = CGRect(x: 0, y: 0, width: originalTitleLb.frame.maxX, height: 50)
        }
        originalBtn.hx_centerX = hx_width / 2
        if originalBtn.frame.maxX > finishBtn.hx_x {
            originalBtn.hx_x = finishBtn.hx_x - originalBtn.hx_width
            if originalBtn.hx_x < previewBtn.frame.maxX + 2 {
                originalBtn.hx_x = previewBtn.frame.maxX + 2
                originalTitleLb.hx_width = finishBtn.hx_x - previewBtn.frame.maxX - 2 - 5 - boxControl.hx_width
            }
        }
    }
    private func updateOriginalSubviewFrame() {
        if isExternalPreview {
           return
        }
        originalTitleLb.frame = CGRect(x: boxControl.frame.maxX + 5, y: 0, width: originalTitleLb.text!.hx_stringWidth(ofFont: originalTitleLb.font, maxHeight: 50), height: 50)
        boxControl.hx_centerY = originalTitleLb.hx_height * 0.5
        originalLoadingView.hx_centerY = originalBtn.hx_height * 0.5
        originalLoadingView.hx_x = originalTitleLb.frame.maxX + 3
    }
    // MARK: HXPHPreviewSelectedViewDelegate
    func selectedView(_ selectedView: HXPHPreviewSelectedView, didSelectItemAt photoAsset: HXPHAsset) {
        hx_delegate?.bottomViewDidSelectedViewClick(self, didSelectedItemAt: photoAsset)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if !isExternalPreview {
            contentView.hx_width = hx_width
            contentView.hx_height = 50 + UIDevice.current.hx_bottomMargin
            contentView.hx_y = hx_height - contentView.hx_height
            let previewWidth : CGFloat = previewBtn.currentTitle!.hx_localized.hx_stringWidth(ofFont: previewBtn.titleLabel!.font, maxHeight: 50)
            previewBtn.frame = CGRect(x: 12 + UIDevice.current.hx_leftMargin, y: 0, width: previewWidth, height: 50)
            editBtn.frame = previewBtn.frame
            updateFinishButtonFrame()
            updateOriginalButtonFrame()
        }
        if config.showPrompt && HXPHAssetManager.authorizationStatusIsLimited() && allowLoadPhotoLibrary && !isPreview && !isExternalPreview {
            promptView.hx_width = hx_width
            promptIcon.hx_x = 12 + UIDevice.current.hx_leftMargin
            promptIcon.hx_centerY = promptView.hx_height * 0.5
            promptArrow.hx_x = hx_width - 12 - promptArrow.hx_width - UIDevice.current.hx_rightMargin
            promptLb.hx_x = promptIcon.frame.maxX + 12
            promptLb.hx_width = promptArrow.hx_x - promptLb.hx_x - 12
            promptLb.hx_centerY = promptView.hx_height * 0.5
            promptArrow.hx_centerY = promptView.hx_height * 0.5
        }
        if isExternalPreview {
            if config.showSelectedView {
                selectedView.hx_width = hx_width
            }
        }else {
            if config.showSelectedView && isMultipleSelect {
                selectedView.hx_width = hx_width
            }
        }
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
