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

public class PhotoPickerViewController: BaseViewController {
    let config: PhotoListConfiguration
    init(config: PhotoListConfiguration) {
        self.config = config
        super.init(nibName: nil, bundle: nil)
    }
    var assetCollection: PhotoAssetCollection!
    var assets: [PhotoAsset] = []
    var swipeSelectBeganIndexPath: IndexPath?
    var swipeSelectedIndexArray: [Int]?
    var swipeSelectState: SwipeSelectState?
    lazy var collectionViewLayout: UICollectionViewFlowLayout = {
        let collectionViewLayout = UICollectionViewFlowLayout.init()
        let space = config.spacing
        collectionViewLayout.minimumLineSpacing = space
        collectionViewLayout.minimumInteritemSpacing = space
        return collectionViewLayout
    }()
    public lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView.init(frame: view.bounds, collectionViewLayout: collectionViewLayout)
        collectionView.dataSource = self
        collectionView.delegate = self
        if let customSingleCellClass = config.cell.customSingleCellClass {
            collectionView.register(
                customSingleCellClass,
                forCellWithReuseIdentifier:
                    NSStringFromClass(
                        PhotoPickerViewCell.classForCoder()
                    )
            )
        }else {
            collectionView.register(
                PhotoPickerViewCell.self,
                forCellWithReuseIdentifier:
                    NSStringFromClass(
                        PhotoPickerViewCell.classForCoder()
                    )
            )
        }
        if let customSelectableCellClass = config.cell.customSelectableCellClass {
            collectionView.register(
                customSelectableCellClass,
                forCellWithReuseIdentifier:
                    NSStringFromClass(
                        PhotoPickerSelectableViewCell.classForCoder()
                    )
            )
        }else {
            collectionView.register(
                PhotoPickerSelectableViewCell.self,
                forCellWithReuseIdentifier:
                    NSStringFromClass(
                        PhotoPickerSelectableViewCell.classForCoder()
                    )
            )
        }
        if config.allowAddCamera {
            collectionView.register(
                PickerCamerViewCell.self,
                forCellWithReuseIdentifier:
                    NSStringFromClass(PickerCamerViewCell.classForCoder())
            )
        }
        if #available(iOS 14.0, *), config.allowAddLimit {
            collectionView.register(
                PhotoPickerLimitCell.self,
                forCellWithReuseIdentifier:
                    NSStringFromClass(PhotoPickerLimitCell.classForCoder())
            )
        }
        if config.showAssetNumber {
            collectionView.register(
                PhotoPickerBottomNumberView.self,
                forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                withReuseIdentifier: NSStringFromClass(PhotoPickerBottomNumberView.classForCoder())
            )
        }
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        } else {
            // Fallback on earlier versions
            automaticallyAdjustsScrollViewInsets = false
        }
        return collectionView
    }()
    
    private lazy var emptyView: EmptyView = {
        let emptyView = EmptyView.init(frame: CGRect(x: 0, y: 0, width: view.width, height: 0))
        emptyView.config = config.emptyView
        emptyView.layoutSubviews()
        return emptyView
    }()
    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel.init()
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.textAlignment = .center
        return titleLabel
    }()
    lazy var titleView: AlbumTitleView = {
        let titleView = AlbumTitleView.init(config: config.titleView)
        titleView.addTarget(self, action: #selector(didTitleViewClick(control:)), for: .touchUpInside)
        return titleView
    }()
    
    lazy var albumBackgroudView: UIView = {
        let albumBackgroudView = UIView.init()
        albumBackgroudView.isHidden = true
        albumBackgroudView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        albumBackgroudView.addGestureRecognizer(
            UITapGestureRecognizer(
                target: self,
                action: #selector(didAlbumBackgroudViewClick)
            )
        )
        return albumBackgroudView
    }()
    
    lazy var albumView: AlbumView = {
        let albumView = AlbumView(config: pickerController!.config.albumList)
        albumView.delegate = self
        return albumView
    }()
    
    lazy var bottomView: PhotoPickerBottomView = {
        let bottomView = PhotoPickerBottomView(
            config: config.bottomView,
            allowLoadPhotoLibrary: allowLoadPhotoLibrary
        )
        bottomView.hx_delegate = self
        bottomView.boxControl.isSelected = pickerController!.isOriginal
        return bottomView
    }()
    
    var showLoading: Bool = false
    /// 允许加载系统相册库
    var allowLoadPhotoLibrary: Bool = true
    /// 是否为多选模式
    var isMultipleSelect: Bool = false
    /// 视频 Cell 为单选类型
    var videoLoadSingleCell = false
    /// 照片数量
    var photoCount: Int = 0
    /// 视频数量
    var videoCount: Int = 0
    
    // MARK: 屏幕旋转相关
    var orientationDidChange: Bool = false
    var beforeOrientationIndexPath: IndexPath?
    
    // MARK: 滑动选择相关
    var swipeSelectAutoScrollTimer: DispatchSourceTimer?
    var swipeSelectPanGR: UIPanGestureRecognizer?
    var swipeSelectLastLocalPoint: CGPoint?
    
    // MARK: 相机/更多 Cell 相关
    var limitAddCell: PhotoPickerLimitCell {
        let indexPath: IndexPath
        if config.sort == .asc {
            if canAddCamera {
                indexPath = IndexPath(item: assets.count - 1, section: 0)
            }else {
                indexPath = IndexPath(item: assets.count, section: 0)
            }
        }else {
            if canAddCamera {
                indexPath = IndexPath(item: 1, section: 0)
            }else {
                indexPath = IndexPath(item: 0, section: 0)
            }
        }
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: NSStringFromClass(
                PhotoPickerLimitCell.classForCoder()
            ),
            for: indexPath
        ) as! PhotoPickerLimitCell
        cell.config = config.limitCell
        return cell
    }
    var cameraCell: PickerCamerViewCell {
        let indexPath: IndexPath
        if config.sort == .asc {
            indexPath = IndexPath(item: assets.count, section: 0)
        }else {
            indexPath = IndexPath(item: 0, section: 0)
        }
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: NSStringFromClass(
                PickerCamerViewCell.classForCoder()
            ),
            for: indexPath
        ) as! PickerCamerViewCell
        cell.config = config.cameraCell
        return cell
    }
    var didFetchAsset: Bool = false
    var canAddCamera: Bool {
        if didFetchAsset && config.allowAddCamera {
            return true
        }
        return false
    }
    var canAddLimit: Bool {
        if didFetchAsset && config.allowAddLimit && AssetManager.authorizationStatusIsLimited() {
            return true
        }
        return false
    }
    var needOffset: Bool {
        if config.sort == .desc {
            if canAddCamera || canAddLimit {
                return true
            }
        }
        return false
    }
    var offsetIndex: Int {
        if !needOffset {
            return 0
        }
        if canAddCamera && canAddLimit {
            return 2
        }else if canAddCamera {
            return 1
        }else {
            return 1
        }
    }
    
    // MARK: UIScrollView滚动相关
    var scrollToTop = false
    var targetOffsetY: CGFloat = 0
    var didChangeCellLoadMode: Bool = false
    var scrollEndReload: Bool = false
    var scrollReachDistance = false
    
    // MARK: function
    public override func viewDidLoad() {
        super.viewDidLoad()
        guard let picker = pickerController else {
            return
        }
        allowLoadPhotoLibrary = picker.config.allowLoadPhotoLibrary
        if AssetManager.authorizationStatus() == .notDetermined {
            didFetchAsset = true
        }
        configData()
        initView()
        configColor()
        fetchData()
        if config.allowSwipeToSelect &&
            picker.config.selectMode == .multiple {
            swipeSelectPanGR = UIPanGestureRecognizer(
                target: self,
                action: #selector(panGestureRecognizer(panGR:))
            )
            view.addGestureRecognizer(swipeSelectPanGR!)
        }
    }
    public override func deviceOrientationWillChanged(notify: Notification) {
        guard #available(iOS 13.0, *) else {
            beforeOrientationIndexPath = collectionView.indexPathsForVisibleItems.first
            orientationDidChange = true
            return
        }
    }
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let margin: CGFloat = UIDevice.leftMargin
        collectionView.frame = CGRect(x: margin, y: 0, width: view.width - 2 * margin, height: view.height)
        var collectionTop: CGFloat = UIDevice.navigationBarHeight
        if let nav = navigationController {
            if nav.modalPresentationStyle == .fullScreen && UIDevice.isPortrait {
                if UIApplication.shared.isStatusBarHidden {
                    collectionTop = nav.navigationBar.height + UIDevice.generalStatusBarHeight
                }else {
                    collectionTop = UIDevice.navigationBarHeight
                }
            }else {
                collectionTop = nav.navigationBar.height
            }
        }
        if let pickerController = pickerController {
            if pickerController.config.albumShowMode == .popup {
                albumBackgroudView.frame = view.bounds
                updateAlbumViewFrame()
            }else {
                var titleWidth = titleLabel.text?.width(ofFont: titleLabel.font, maxHeight: 30) ?? 0
                if titleWidth > view.width * 0.6 {
                    titleWidth = view.width * 0.6
                }
                titleLabel.size = CGSize(width: titleWidth, height: 30)
            }
        }
        if isMultipleSelect {
            let promptHeight: CGFloat = (AssetManager.authorizationStatusIsLimited() &&
                                            config.bottomView.showPrompt &&
                                            allowLoadPhotoLibrary) ? 70 : 0
            let bottomHeight: CGFloat = 50 + UIDevice.bottomMargin + promptHeight
            bottomView.frame = CGRect(x: 0, y: view.height - bottomHeight, width: view.width, height: bottomHeight)
            collectionView.contentInset = UIEdgeInsets(
                top: collectionTop,
                left: 0,
                bottom: bottomView.height + 0.5,
                right: 0
            )
            collectionView.scrollIndicatorInsets = UIEdgeInsets(
                top: 0,
                left: 0,
                bottom: bottomHeight - UIDevice.bottomMargin,
                right: 0
            )
        }else {
            collectionView.contentInset = UIEdgeInsets(
                top: collectionTop,
                left: 0,
                bottom: UIDevice.bottomMargin,
                right: 0
            )
        }
        let space = config.spacing
        let count: CGFloat
        if  UIDevice.isPortrait == true {
            count = CGFloat(config.rowNumber)
        }else {
            count = CGFloat(config.landscapeRowNumber)
        }
        let itemWidth = (collectionView.width - space * (count - CGFloat(1))) / count
        collectionViewLayout.itemSize = CGSize.init(width: itemWidth, height: itemWidth)
        if orientationDidChange {
            if let picker = pickerController,
               picker.config.albumShowMode == .popup {
                titleView.updateViewFrame()
            }
            collectionView.reloadData()
            DispatchQueue.main.async {
                if let indexPath = self.beforeOrientationIndexPath {
                    self.collectionView.scrollToItem(at: indexPath, at: .top, animated: false)
                }
            }
            orientationDidChange = false
        }
        emptyView.width = collectionView.width
        emptyView.center = CGPoint(
            x: collectionView.width * 0.5,
            y: (collectionView.height - collectionView.contentInset.top - collectionView.contentInset.bottom) * 0.5
        )
    }
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        pickerController?.viewControllersWillAppear(self)
    }
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: Function
extension PhotoPickerViewController {
    
    private func initView() {
        guard let picker = pickerController else { return }
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = .all
        view.addSubview(collectionView)
        if isMultipleSelect {
            view.addSubview(bottomView)
            bottomView.updateFinishButtonTitle()
        }
        if picker.config.albumShowMode == .popup {
            var cancelItem: UIBarButtonItem
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
                navigationItem.leftBarButtonItem = cancelItem
            }else {
                navigationItem.rightBarButtonItem = cancelItem
            }
            view.addSubview(albumBackgroudView)
            view.addSubview(albumView)
        }else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: "取消".localized,
                style: .done,
                target: self,
                action: #selector(didCancelItemClick)
            )
        }
    }
    private func configData() {
        guard let picker = pickerController else { return }
        isMultipleSelect = picker.config.selectMode == .multiple
        videoLoadSingleCell = picker.singleVideo
        updateTitle()
    }
    private func configColor() {
        guard let picker = pickerController else { return }
        let isDark = PhotoManager.isDark
        view.backgroundColor = isDark ? config.backgroundDarkColor : config.backgroundColor
        collectionView.backgroundColor = isDark ? config.backgroundDarkColor : config.backgroundColor
        let titleColor = isDark ?
            picker.config.navigationTitleDarkColor :
            picker.config.navigationTitleColor
        if picker.config.albumShowMode == .popup {
            titleView.titleColor = titleColor
        }else {
            titleLabel.textColor = titleColor
        }
    }
    func updateTitle() {
        guard let picker = pickerController else { return }
        if picker.config.albumShowMode == .popup {
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
    func scrollToCenter(for photoAsset: PhotoAsset?) {
        if assets.isEmpty {
            return
        }
        if let photoAsset = photoAsset,
           var item = assets.firstIndex(of: photoAsset) {
            if needOffset {
                item += offsetIndex
            }
            collectionView.scrollToItem(
                at: IndexPath(item: item, section: 0),
                at: .centeredVertically,
                animated: false
            )
        }
    }
    func scrollCellToVisibleArea(_ cell: PhotoPickerBaseViewCell) {
        if assets.isEmpty {
            return
        }
        let rect = cell.photoView.convert(cell.photoView.bounds, to: view)
        if rect.minY - collectionView.contentInset.top < 0 {
            if let indexPath = collectionView.indexPath(for: cell) {
                collectionView.scrollToItem(
                    at: indexPath,
                    at: .top,
                    animated: false
                )
            }
        }else if rect.maxY > view.height - collectionView.contentInset.bottom {
            if let indexPath = collectionView.indexPath(for: cell) {
                collectionView.scrollToItem(
                    at: indexPath,
                    at: .bottom,
                    animated: false
                )
            }
        }
    }
    func scrollToAppropriatePlace(photoAsset: PhotoAsset?) {
        if assets.isEmpty {
            return
        }
        var item = config.sort == .asc ? assets.count - 1 : 0
        if let photoAsset = photoAsset {
            item = assets.firstIndex(of: photoAsset) ?? item
        }
        if config.sort == .asc {
            if canAddCamera && canAddLimit {
                item += 2
            }else if canAddCamera || canAddLimit {
                item += 1
            }
        }
        collectionView.scrollToItem(
            at: IndexPath(
                item: item,
                section: 0
            ),
            at: config.sort == .asc ? .bottom : .top,
            animated: false
        )
    }
    func getCell(
        for item: Int
    ) -> PhotoPickerBaseViewCell? {
        if assets.isEmpty {
            return nil
        }
        let cell = collectionView.cellForItem(
            at: IndexPath(item: item, section: 0)
        ) as? PhotoPickerBaseViewCell
        return cell
    }
    func getCell(
        for photoAsset: PhotoAsset
    ) -> PhotoPickerBaseViewCell? {
        if let item = getIndexPath(for: photoAsset)?.item {
            return getCell(for: item)
        }
        return nil
    }
    func getIndexPath(for photoAsset: PhotoAsset) -> IndexPath? {
        if assets.isEmpty {
            return nil
        }
        if var item = assets.firstIndex(of: photoAsset) {
            if needOffset {
                item += offsetIndex
            }
            return IndexPath(item: item, section: 0)
        }
        return nil
    }
    func reloadCell(for photoAsset: PhotoAsset) {
        if let indexPath = getIndexPath(for: photoAsset) {
            collectionView.reloadItems(at: [indexPath])
        }
    }
    func resetICloud(for photoAsset: PhotoAsset) {
        guard let cell = getCell(for: photoAsset),
              cell.inICloud else {
            return
        }
        cell.requestICloudState()
    }
    func getPhotoAsset(for index: Int) -> PhotoAsset {
        let photoAsset: PhotoAsset
        if needOffset {
            photoAsset = assets[index - offsetIndex]
        }else {
            photoAsset = assets[index]
        }
        return photoAsset
    }
    func addedPhotoAsset(for photoAsset: PhotoAsset) {
        let indexPath: IndexPath
        if config.sort == .desc {
            assets.insert(photoAsset, at: 0)
            indexPath = IndexPath(
                item: needOffset ? offsetIndex : 0,
                section: 0
            )
        }else {
            assets.append(photoAsset)
            indexPath = IndexPath(
                item: assets.count - 1,
                section: 0
            )
        }
        collectionView.insertItems(
            at: [indexPath]
        )
        collectionView.scrollToItem(
            at: indexPath,
            at: .bottom,
            animated: true
        )
    }
    func changedAssetCollection(collection: PhotoAssetCollection?) {
        guard let picker = pickerController else { return }
        ProgressHUD.showLoading(
            addedTo: navigationController?.view,
            animated: true
        )
        if let collection = collection {
            if picker.config.albumShowMode == .popup {
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
        guard let picker = pickerController else { return }
        if picker.config.albumShowMode == .popup {
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
        guard let picker = pickerController else { return }
        for case let cell as PhotoPickerBaseViewCell in collectionView.visibleCells {
            guard let photoAsset = cell.photoAsset else { continue }
            if !photoAsset.isSelected &&
                config.cell.showDisableMask &&
                picker.config.maximumSelectedVideoFileSize == 0  &&
                picker.config.maximumSelectedPhotoFileSize == 0 {
                cell.canSelect = picker.canSelectAsset(
                    for: photoAsset,
                    showHUD: false
                )
            }
            cell.updateSelectedState(
                isSelected: photoAsset.isSelected,
                animated: false
            )
        }
    }
    
    @objc func didCancelItemClick() {
        pickerController?.cancelCallback()
    }
}
