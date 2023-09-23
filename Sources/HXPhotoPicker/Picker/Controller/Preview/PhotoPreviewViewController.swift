//
//  PhotoPreviewViewController.swift
//  HXPhotoPicker
//
//  Created by Silence on 2020/11/13.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit
import Photos

public class PhotoPreviewViewController: BaseViewController {
    
    weak var delegate: PhotoPreviewViewControllerDelegate?
    public let config: PreviewViewConfiguration
    /// 当前预览的位置索引
    public var currentPreviewIndex: Int = 0
    /// 预览的资源数组
    public var previewAssets: [PhotoAsset] = []
    /// 是否是外部预览
    public var isExternalPreview: Bool = false
    public var collectionView: UICollectionView!
    
    private var collectionViewLayout: UICollectionViewFlowLayout!
    var numberOfPages: PhotoBrowser.NumberOfPagesHandler?
    var cellForIndex: PhotoBrowser.CellReloadContext?
    var assetForIndex: PhotoBrowser.RequiredAsset?
    
    var photoToolbar: PhotoToolBarProtocol!
    var selectBoxControl: SelectBoxView!
    var interactiveTransition: PickerInteractiveTransition?
    weak var beforeNavDelegate: UINavigationControllerDelegate?
    
    var isPreviewSelect: Bool = false
    var isExternalPickerPreview: Bool = false
    var orientationDidChange: Bool = false
    var statusBarShouldBeHidden: Bool = false
    var videoLoadSingleCell = false
    var viewDidAppear: Bool = false
    var firstLayoutSubviews: Bool = true
    var isMultipleSelect: Bool = false
    var allowLoadPhotoLibrary: Bool = true
    var requestPreviewTimer: Timer?
    
    var assetCount: Int {
        if previewAssets.isEmpty {
            if let pages = numberOfPages?() {
                return pages
            }
            return 0
        }
        return previewAssets.count
    }
    
    func photoAsset(for index: Int) -> PhotoAsset? {
        if !previewAssets.isEmpty && index > 0 || index < previewAssets.count {
            return previewAssets[index]
        }
        return assetForIndex?(index)
    }
    
    init(config: PreviewViewConfiguration) {
        self.config = config
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let margin: CGFloat = 20
        let itemWidth = view.width + margin
        collectionViewLayout.minimumLineSpacing = margin
        collectionViewLayout.itemSize = view.size
        let contentWidth = (view.width + itemWidth) * CGFloat(assetCount)
        collectionView.frame = CGRect(x: -(margin * 0.5), y: 0, width: itemWidth, height: view.height)
        collectionView.contentSize = CGSize(width: contentWidth, height: view.height)
        collectionView.setContentOffset(CGPoint(x: CGFloat(currentPreviewIndex) * itemWidth, y: 0), animated: false)
        DispatchQueue.main.async {
            if self.orientationDidChange {
                let cell = self.getCell(for: self.currentPreviewIndex)
                cell?.setupScrollViewContentSize()
                self.orientationDidChange = false
            }
        }
        configBottomViewFrame()
        if firstLayoutSubviews {
            guard let photoAsset = photoAsset(for: currentPreviewIndex) else {
                return
            }
            DispatchQueue.main.async {
                self.photoToolbar.selectedViewScrollTo(photoAsset, animated: false)
            }
            firstLayoutSubviews = false
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        title = ""
        isMultipleSelect = pickerController?.config.selectMode == .multiple
        if let isLoadPhotoLibrary = pickerController?.config.allowLoadPhotoLibrary {
            allowLoadPhotoLibrary = isLoadPhotoLibrary
        }else {
            allowLoadPhotoLibrary = true
        }
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = .all
        view.clipsToBounds = true
        initView()
    }
    public override func deviceOrientationWillChanged(notify: Notification) {
        orientationDidChange = true
        if let cell = getCell(for: currentPreviewIndex) {
            if cell.photoAsset.mediaSubType == .livePhoto ||
                cell.photoAsset.mediaSubType == .localLivePhoto {
                if #available(iOS 9.1, *) {
                    cell.scrollContentView.livePhotoView.stopPlayback()
                }
            }
        }
    }
    public override func deviceOrientationDidChanged(notify: Notification) {
        photoToolbar.deviceOrientationDidChanged()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        pickerController?.viewControllersWillAppear(self)
    }
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewDidAppear = true
        DispatchQueue.main.async {
            if let cell = self.getCell(for: self.currentPreviewIndex) {
                cell.requestPreviewAsset()
            }else {
                Timer.scheduledTimer(
                    withTimeInterval: 0.2,
                    repeats: false
                ) { [weak self] _ in
                    guard let self = self else { return }
                    let cell = self.getCell(for: self.currentPreviewIndex)
                    cell?.requestPreviewAsset()
                }
            }
        }
        pickerController?.viewControllersDidAppear(self)
        guard let picker = pickerController else {
            return
        }
        if (picker.modalPresentationStyle == .fullScreen && interactiveTransition == nil) ||
            (!UIDevice.isPortrait && !UIDevice.isPad) && !isExternalPreview {
            interactiveTransition = PickerInteractiveTransition(
                panGestureRecognizerFor: self,
                type: .pop
            )
        }
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
        return statusBarShouldBeHidden
    }
    
    public override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        if PhotoManager.isDark {
            return .lightContent
        }
        if let statusBarStyle = pickerController?.config.statusBarStyle {
            return statusBarStyle
        }
        return .default
    }
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) && viewDidAppear {
                configColor()
            }
        }
    }
}

// MARK: Function
extension PhotoPreviewViewController {
     
    private func initView() {
        guard let pickerController = pickerController else {
            return
        }
        collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.scrollDirection = .horizontal
        collectionViewLayout.minimumLineSpacing = 0
        collectionViewLayout.minimumInteritemSpacing = 0
        collectionViewLayout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: collectionViewLayout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isPagingEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        } else {
            // Fallback on earlier versions
            self.automaticallyAdjustsScrollViewInsets = false
        }
        collectionView.register(
            PreviewPhotoViewCell.self,
            forCellWithReuseIdentifier: NSStringFromClass(PreviewPhotoViewCell.self)
        )
        collectionView.register(
            PreviewLivePhotoViewCell.self,
            forCellWithReuseIdentifier: NSStringFromClass(PreviewLivePhotoViewCell.self)
        )
        if let customVideoCell = config.customVideoCellClass {
            collectionView.register(
                customVideoCell,
                forCellWithReuseIdentifier: NSStringFromClass(PreviewVideoViewCell.self)
            )
        }else {
            collectionView.register(
                PreviewVideoViewCell.self,
                forCellWithReuseIdentifier: NSStringFromClass(PreviewVideoViewCell.self)
            )
        }
        view.addSubview(collectionView)
        
        photoToolbar = config.photoToolbar.init()
        photoToolbar.initViews(pickerController.config, type: isExternalPreview ? .browser : .preview)
        photoToolbar.selectedAssetHandler = { [weak self] in
            guard let self = self else { return }
            if self.previewAssets.contains($0) {
                self.scrollToPhotoAsset($0)
            }else {
                self.photoToolbar.selectedViewScrollTo(nil, animated: true)
            }
        }
        photoToolbar.moveAssetHandler = { [weak self] in
            guard let self = self else { return }
            self.delegate?.previewViewController(self, moveItem: $0, toIndex: $1)
            guard let pickerController = self.pickerController else { return }
            pickerController.movePhotoAsset(fromIndex: $0, toIndex: $1)
            if self.isPreviewSelect {
                let fromAsset = previewAssets[$0]
                self.previewAssets.remove(at: $0)
                self.previewAssets.insert(fromAsset, at: $1)
                self.getCell(for: self.currentPreviewIndex)?.cancelRequest()
                self.collectionView.reloadData()
                self.setupRequestPreviewTimer()
            }
            self.photoToolbar.updateSelectedAssets(pickerController.selectedAssetArray)
            if let asset = self.photoAsset(for: self.currentPreviewIndex) {
                self.updateSelectBox(asset.isSelected, photoAsset: asset)
                DispatchQueue.main.async {
                    self.photoToolbar.selectedViewScrollTo(asset, animated: true)
                }
            }
            self.delegate?.previewViewController(movePhotoAsset: self)
        }
        #if HXPICKER_ENABLE_EDITOR
        photoToolbar.editHandler = { [weak self] in
            guard let self = self, let photoAsset = self.photoAsset(for: self.currentPreviewIndex) else {
                return
            }
            self.openEditor(photoAsset)
        }
        #endif
        photoToolbar.originalHandler = { [weak self] in
            guard let self = self else { return }
            self.pickerController?.isOriginal = $0
            self.pickerController?.originalButtonCallback()
            if $0 {
                self.requestSelectedAssetFileSize()
            }else {
                self.pickerController?.cancelRequestAssetFileSize(isPreview: true)
            }
            self.delegate?.previewViewController(
                self,
                didOriginalButton: $0
            )
            self.pickerController?.originalButtonCallback()
        }
        photoToolbar.finishHandler = { [weak self] in
            self?.didFinishClick()
        }
        
        if config.isShowBottomView {
            view.addSubview(photoToolbar)
            if !isExternalPreview {
                photoToolbar.updateOriginalState(pickerController.isOriginal)
                photoToolbar.requestOriginalAssetBtyes()
                let selectedAssetArray = pickerController.selectedAssetArray
                photoToolbar.updateSelectedAssets(selectedAssetArray)
                photoToolbar.selectedAssetDidChanged(selectedAssetArray)
            }else {
                photoToolbar.updateSelectedAssets(previewAssets)
            }
        }
        selectBoxControl = SelectBoxView(
            config.selectBox,
            frame: CGRect(
                origin: .zero,
                size: config.selectBox.size
            )
        )
        selectBoxControl.backgroundColor = .clear
        selectBoxControl.addTarget(self, action: #selector(didSelectBoxControlClick), for: UIControl.Event.touchUpInside)
        
        if (isExternalPreview || isExternalPickerPreview) && pickerController.modalPresentationStyle != .custom {
            configColor()
        }
        if isMultipleSelect || isExternalPreview {
            videoLoadSingleCell = pickerController.singleVideo
            if !isExternalPreview {
                if isExternalPickerPreview {
                    let cancelItem = UIBarButtonItem(
                        image: "hx_picker_photolist_cancel".image,
                        style: .done,
                        target: self,
                        action: #selector(didCancelItemClick)
                    )
                    navigationItem.leftBarButtonItem = cancelItem
                }
                navigationItem.rightBarButtonItem = UIBarButtonItem.init(customView: selectBoxControl)
            }else {
                var cancelItem: UIBarButtonItem
                if config.cancelType == .image {
                    let isDark = PhotoManager.isDark
                    cancelItem = UIBarButtonItem(
                        image: UIImage.image(
                            for: isDark ? config.cancelDarkImageName : config.cancelImageName
                        ),
                        style: .done,
                        target: self,
                        action: #selector(didCancelItemClick)
                    )
                }else {
                    cancelItem = UIBarButtonItem(
                        title: "取消".localized,
                        style: .done,
                        target: self,
                        action: #selector(didCancelItemClick)
                    )
                }
                if config.cancelPosition == .left {
                    navigationItem.leftBarButtonItem = cancelItem
                } else {
                    navigationItem.rightBarButtonItem = cancelItem
                }
            }
            if assetCount > 0 && currentPreviewIndex == 0 {
                if let photoAsset = photoAsset(for: 0) {
                    if config.isShowBottomView {
                        photoToolbar.selectedViewScrollTo(photoAsset, animated: true)
                        
                        #if HXPICKER_ENABLE_EDITOR
                        if photoAsset.mediaType == .photo {
                            photoToolbar.updateEditState(pickerController.config.editorOptions.isPhoto)
                        }else if photoAsset.mediaType == .video {
                            photoToolbar.updateEditState(pickerController.config.editorOptions.contains(.video))
                        }
                        #endif
                    }
                    if !isExternalPreview {
                        if photoAsset.mediaType == .video && videoLoadSingleCell {
                            selectBoxControl.isHidden = true
                        } else {
                            updateSelectBox(photoAsset.isSelected, photoAsset: photoAsset)
                            selectBoxControl.isSelected = photoAsset.isSelected
                        }
                    }
                    pickerController.previewUpdateCurrentlyDisplayedAsset(
                        photoAsset: photoAsset,
                        index: currentPreviewIndex
                    )
                }
            }
        }else if !isMultipleSelect {
            if isExternalPickerPreview {
                let cancelItem = UIBarButtonItem(
                    image: "hx_picker_photolist_cancel".image,
                    style: .done,
                    target: self,
                    action: #selector(didCancelItemClick)
                )
                navigationItem.leftBarButtonItem = cancelItem
            }
            if assetCount > 0 && currentPreviewIndex == 0 {
                if let photoAsset = photoAsset(for: 0) {
                    #if HXPICKER_ENABLE_EDITOR
                    if config.isShowBottomView {
                        if photoAsset.mediaType == .photo {
                            photoToolbar.updateEditState(pickerController.config.editorOptions.isPhoto)
                        }else if photoAsset.mediaType == .video {
                            photoToolbar.updateEditState(pickerController.config.editorOptions.contains(.video))
                        }
                    }
                    #endif
                    pickerController.previewUpdateCurrentlyDisplayedAsset(
                        photoAsset: photoAsset,
                        index: currentPreviewIndex
                    )
                }
            }
        }
    }
    func configBottomViewFrame() {
        if !config.isShowBottomView {
            return
        }
        let bottomHeight = photoToolbar.viewHeight()
        photoToolbar.frame = CGRect(
            x: 0,
            y: view.height - bottomHeight,
            width: view.width,
            height: bottomHeight
        )
    }
    func configColor() {
        view.backgroundColor = PhotoManager.isDark ?
            config.backgroundDarkColor :
            config.backgroundColor
    }
    func reloadCell(for item: Int) {
        guard let photoAsset = photoAsset(for: item) else {
            return
        }
        let indexPath = IndexPath(item: item, section: 0)
        collectionView.reloadItems(at: [indexPath])
        if config.isShowBottomView {
            photoToolbar.reloadSelectedAsset(photoAsset)
            photoToolbar.requestOriginalAssetBtyes()
        }
    }
    func getCell(for item: Int) -> PhotoPreviewViewCell? {
        if assetCount == 0 {
            return nil
        }
        let cell = collectionView.cellForItem(
            at: IndexPath(
                item: item,
                section: 0
            )
        ) as? PhotoPreviewViewCell
        return cell
    }
//    func getCell(for photoAsset: PhotoAsset) -> PhotoPreviewViewCell? {
//        guard let item = previewAssets.firstIndex(of: photoAsset) else {
//            return nil
//        }
//        return getCell(for: item)
//    }
    func scrollToPhotoAsset(_ photoAsset: PhotoAsset) {
        guard let index = previewAssets.firstIndex(of: photoAsset) else {
            return
        }
        scrollToItem(index)
    }
    func scrollToItem(_ item: Int) {
        if item == currentPreviewIndex {
            return
        }
        getCell(for: currentPreviewIndex)?.cancelRequest()
        collectionView.scrollToItem(
            at: IndexPath(item: item, section: 0),
            at: .centeredHorizontally,
            animated: false
        )
        setupRequestPreviewTimer()
    }
    func setCurrentCellImage(image: UIImage?) {
        guard let image = image,
              let cell = getCell(for: currentPreviewIndex),
              !cell.scrollContentView.requestCompletion else {
            return
        }
        cell.scrollContentView.imageView.image = image
    }
    func insert(at item: Int) {
        if item == currentPreviewIndex {
            getCell(for: item)?.cancelRequest()
            collectionView.insertItems(
                at: [
                    IndexPath(
                        item: item,
                        section: 0
                    )
                ]
            )
            collectionView.scrollToItem(
                at: IndexPath(
                    item: item,
                    section: 0
                ),
                at: .centeredHorizontally,
                animated: false
            )
            scrollViewDidScroll(collectionView)
            setupRequestPreviewTimer()
        }else {
            collectionView.insertItems(
                at: [
                    IndexPath(
                        item: item,
                        section: 0
                    )
                ]
            )
        }
    }
    func insert(_ photoAsset: PhotoAsset, at item: Int) {
        if previewAssets.isEmpty {
            return
        }
        previewAssets.insert(photoAsset, at: item)
        if item == currentPreviewIndex {
            getCell(for: item)?.cancelRequest()
            collectionView.insertItems(
                at: [
                    IndexPath(
                        item: item,
                        section: 0
                    )
                ]
            )
            collectionView.scrollToItem(
                at: IndexPath(
                    item: item,
                    section: 0
                ),
                at: .centeredHorizontally,
                animated: false
            )
            scrollViewDidScroll(collectionView)
            setupRequestPreviewTimer()
        }else {
            collectionView.insertItems(
                at: [
                    IndexPath(
                        item: item,
                        section: 0
                    )
                ]
            )
        }
        
    }
    func deleteItems(at items: [Int]) {
        if assetCount == 0 || !isExternalPreview || items.isEmpty {
            return
        }
        var indexPaths: [IndexPath] = []
        var photoAssets: [PhotoAsset] = []
        for item in items {
            guard let photoAsset = photoAsset(for: item) else {
                continue
            }
            if let shouldDelete = pickerController?.previewShouldDeleteAsset(
                photoAsset: photoAsset,
                index: item
            ), !shouldDelete {
                continue
            }
            #if HXPICKER_ENABLE_EDITOR
            photoAsset.editedResult = nil
            #endif
            if let index = previewAssets.firstIndex(of: photoAsset) {
                previewAssets.remove(at: index)
            }
            indexPaths.append(.init(
                item: item,
                section: 0
            ))
            photoAssets.append(photoAsset)
        }
        collectionView.deleteItems(at: indexPaths)
        if config.isShowBottomView {
            photoToolbar.removeSelectedAssets(photoAssets)
        }
        if let pickerController = pickerController {
            pickerController.pickerDelegate?.pickerController(
                pickerController,
                previewDidDeleteAssets: photoAssets,
                at: items
            )
        }
        if assetCount > 0 {
            scrollViewDidScroll(collectionView)
            setupRequestPreviewTimer()
        }else {
            didCancelItemClick()
        }
    }
    func deleteCurrentPhotoAsset() {
        deleteItems(at: [currentPreviewIndex])
    }
    func replacePhotoAsset(at index: Int, with photoAsset: PhotoAsset) {
        previewAssets[index] = photoAsset
        reloadCell(for: index)
//        collectionView.reloadItems(at: [IndexPath.init(item: index, section: 0)])
    }
    func addedCameraPhotoAsset(_ photoAsset: PhotoAsset) {
        guard let picker = pickerController else { return }
        if config.isShowBottomView {
            photoToolbar.updateSelectedAssets(picker.selectedAssetArray)
            configBottomViewFrame()
            photoToolbar.layoutSubviews()
            photoToolbar.selectedAssetDidChanged(picker.selectedAssetArray)
        }
        getCell(for: currentPreviewIndex)?.cancelRequest()
        previewAssets.insert(
            photoAsset,
            at: currentPreviewIndex
        )
        collectionView.insertItems(
            at: [
                IndexPath(
                    item: currentPreviewIndex,
                    section: 0
                )
            ]
        )
        collectionView.scrollToItem(
            at: IndexPath(
                item: currentPreviewIndex,
                section: 0
            ),
            at: .centeredHorizontally,
            animated: false
        )
        scrollViewDidScroll(collectionView)
        setupRequestPreviewTimer()
    }
    
    @objc func didCancelItemClick() {
        pickerController?.cancelCallback()
        dismiss(animated: true, completion: nil)
    }
}
