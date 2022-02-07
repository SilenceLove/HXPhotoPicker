//
//  PhotoPreviewViewController.swift
//  HXPHPickerExample
//
//  Created by Silence on 2020/11/13.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit
import Photos

protocol PhotoPreviewViewControllerDelegate: AnyObject {
    func previewViewController(
        _ previewController: PhotoPreviewViewController,
        didOriginalButton isOriginal: Bool
    )
    func previewViewController(
        _ previewController: PhotoPreviewViewController,
        didSelectBox photoAsset: PhotoAsset,
        isSelected: Bool,
        updateCell: Bool
    )
    func previewViewController(
        _ previewController: PhotoPreviewViewController,
        editAssetFinished photoAsset: PhotoAsset
    )
    func previewViewController(
        _ previewController: PhotoPreviewViewController,
        networkImagedownloadSuccess photoAsset: PhotoAsset
    )
    func previewViewController(
        didFinishButton previewController: PhotoPreviewViewController
    )
    func previewViewController(
        _ previewController: PhotoPreviewViewController,
        requestSucceed photoAsset: PhotoAsset
    )
    func previewViewController(
        _ previewController: PhotoPreviewViewController,
        requestFailed photoAsset: PhotoAsset
    )
}
extension PhotoPreviewViewControllerDelegate {
    func previewViewController(
        _ previewController: PhotoPreviewViewController,
        didOriginalButton isOriginal: Bool
    ) { }
    func previewViewController(
        _ previewController: PhotoPreviewViewController,
        didSelectBox photoAsset: PhotoAsset,
        isSelected: Bool,
        updateCell: Bool
    ) { }
    func previewViewController(
        _ previewController: PhotoPreviewViewController,
        editAssetFinished photoAsset: PhotoAsset
    ) { }
    func previewViewController(
        _ previewController: PhotoPreviewViewController,
        networkImagedownloadSuccess photoAsset: PhotoAsset
    ) { }
    func previewViewController(
        didFinishButton previewController: PhotoPreviewViewController
    ) { }
    func previewViewController(
        _ previewController: PhotoPreviewViewController,
        requestSucceed photoAsset: PhotoAsset
    ) { }
    func previewViewController(
        _ previewController: PhotoPreviewViewController,
        requestFailed photoAsset: PhotoAsset
    ) { }
}

public class PhotoPreviewViewController: BaseViewController {
    
    weak var delegate: PhotoPreviewViewControllerDelegate?
    public let config: PreviewViewConfiguration
    /// 当前预览的位置索引
    public var currentPreviewIndex: Int = 0
    /// 预览的资源数组
    public var previewAssets: [PhotoAsset] = []
    /// 是否是外部预览
    public var isExternalPreview: Bool = false
    
    var isExternalPickerPreview: Bool = false
    var orientationDidChange: Bool = false
    var statusBarShouldBeHidden: Bool = false
    var videoLoadSingleCell = false
    var viewDidAppear: Bool = false
    var firstLayoutSubviews: Bool = true
    var interactiveTransition: PickerInteractiveTransition?
    weak var beforeNavDelegate: UINavigationControllerDelegate?
    lazy var selectBoxControl: SelectBoxView = {
        let boxControl = SelectBoxView(
            frame: CGRect(
                origin: .zero,
                size: config.selectBox.size
            )
        )
        boxControl.backgroundColor = .clear
        boxControl.config = config.selectBox
        boxControl.addTarget(self, action: #selector(didSelectBoxControlClick), for: UIControl.Event.touchUpInside)
        return boxControl
    }()
    
    lazy var collectionViewLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout.init()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        return layout
    }()
    
    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView.init(frame: view.bounds, collectionViewLayout: collectionViewLayout)
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
        return collectionView
    }()
    var isMultipleSelect: Bool = false
    var allowLoadPhotoLibrary: Bool = true
    lazy var bottomView: PhotoPickerBottomView = {
        let bottomView = PhotoPickerBottomView(
            config: config.bottomView,
            allowLoadPhotoLibrary: allowLoadPhotoLibrary,
            isMultipleSelect: isMultipleSelect,
            sourceType: isExternalPreview ? .browser : .preview
        )
        bottomView.hx_delegate = self
        if config.bottomView.showSelectedView && (isMultipleSelect || isExternalPreview) {
            bottomView.selectedView.reloadData(
                photoAssets: pickerController!.selectedAssetArray
            )
        }
        if !isExternalPreview {
            bottomView.boxControl.isSelected = pickerController!.isOriginal
            bottomView.requestAssetBytes()
        }
        return bottomView
    }()
    var requestPreviewTimer: Timer?
    
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
        let contentWidth = (view.width + itemWidth) * CGFloat(previewAssets.count)
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
            if !previewAssets.isEmpty &&
                config.bottomView.showSelectedView &&
                (isMultipleSelect || isExternalPreview) &&
                config.showBottomView {
                DispatchQueue.main.async {
                    self.bottomView.selectedView.scrollTo(
                        photoAsset: self.previewAssets[self.currentPreviewIndex],
                        isAnimated: false
                    )
                }
            }
            firstLayoutSubviews = false
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        title = ""
        isMultipleSelect = pickerController?.config.selectMode == .multiple
        allowLoadPhotoLibrary = pickerController?.config.allowLoadPhotoLibrary ?? true
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
        if config.bottomView.showSelectedView &&
            (isMultipleSelect || isExternalPreview) &&
            config.showBottomView {
            bottomView.selectedView.reloadSectionInset()
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        pickerController?.viewControllersWillAppear(self)
    }
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewDidAppear = true
        DispatchQueue.main.async {
            let cell = self.getCell(for: self.currentPreviewIndex)
            cell?.requestPreviewAsset()
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
        return pickerController?.config.statusBarStyle ?? .default
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
        view.addSubview(collectionView)
        if config.showBottomView {
            view.addSubview(bottomView)
            bottomView.updateFinishButtonTitle()
        }
        if let pickerController = pickerController, (isExternalPreview || isExternalPickerPreview) {
//            statusBarShouldBeHidden = pickerController.config.prefersStatusBarHidden
            if pickerController.modalPresentationStyle != .custom {
                configColor()
            }
        }
        if isMultipleSelect || isExternalPreview {
            videoLoadSingleCell = pickerController!.singleVideo
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
            if !previewAssets.isEmpty {
                if currentPreviewIndex == 0 {
                    let photoAsset = previewAssets.first!
                    if config.bottomView.showSelectedView && config.showBottomView {
                        bottomView.selectedView.scrollTo(photoAsset: photoAsset)
                    }
                    if !isExternalPreview {
                        if photoAsset.mediaType == .video && videoLoadSingleCell {
                            selectBoxControl.isHidden = true
                        } else {
                            updateSelectBox(photoAsset.isSelected, photoAsset: photoAsset)
                            selectBoxControl.isSelected = photoAsset.isSelected
                        }
                    }
                    #if HXPICKER_ENABLE_EDITOR
                    if let pickerController = pickerController, !config.bottomView.editButtonHidden,
                       config.showBottomView {
                        if photoAsset.mediaType == .photo {
                            bottomView.editBtn.isEnabled = pickerController.config.editorOptions.isPhoto
                        }else if photoAsset.mediaType == .video {
                            bottomView.editBtn.isEnabled = pickerController.config.editorOptions.contains(.video)
                        }
                    }
                    #endif
                    pickerController?.previewUpdateCurrentlyDisplayedAsset(
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
            if !previewAssets.isEmpty {
                if currentPreviewIndex == 0 {
                    let photoAsset = previewAssets.first!
                    #if HXPICKER_ENABLE_EDITOR
                    if let pickerController = pickerController, !config.bottomView.editButtonHidden,
                       config.showBottomView {
                        if photoAsset.mediaType == .photo {
                            bottomView.editBtn.isEnabled = pickerController.config.editorOptions.isPhoto
                        }else if photoAsset.mediaType == .video {
                            bottomView.editBtn.isEnabled = pickerController.config.editorOptions.contains(.video)
                        }
                    }
                    #endif
                    pickerController?.previewUpdateCurrentlyDisplayedAsset(
                        photoAsset: photoAsset,
                        index: currentPreviewIndex
                    )
                }
            }
        }
    }
    func configBottomViewFrame() {
        if !config.showBottomView {
            return
        }
        var bottomHeight: CGFloat = 0
        if isExternalPreview {
            bottomHeight = (pickerController?.selectedAssetArray.isEmpty ?? true) ? 0 : UIDevice.bottomMargin + 70
            #if HXPICKER_ENABLE_EDITOR
            if !config.bottomView.showSelectedView && config.bottomView.editButtonHidden {
                if config.bottomView.editButtonHidden {
                    bottomHeight = 0
                }else {
                    bottomHeight = UIDevice.bottomMargin + 50
                }
            }
            #endif
        }else {
            if let picker = pickerController {
                bottomHeight = picker.selectedAssetArray.isEmpty ?
                    50 + UIDevice.bottomMargin : 50 + UIDevice.bottomMargin + 70
            }
            if !config.bottomView.showSelectedView || !isMultipleSelect {
                bottomHeight = 50 + UIDevice.bottomMargin
            }
        }
        bottomView.frame = CGRect(
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
    func reloadCell(for photoAsset: PhotoAsset) {
        guard let item = previewAssets.firstIndex(of: photoAsset),
              !previewAssets.isEmpty else {
            return
        }
        let indexPath = IndexPath(item: item, section: 0)
        collectionView.reloadItems(at: [indexPath])
        if config.showBottomView {
            bottomView.selectedView.reloadData(photoAsset: photoAsset)
            bottomView.requestAssetBytes()
        }
    }
    func getCell(for item: Int) -> PhotoPreviewViewCell? {
        if previewAssets.isEmpty {
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
    func getCell(for photoAsset: PhotoAsset) -> PhotoPreviewViewCell? {
        guard let item = previewAssets.firstIndex(of: photoAsset) else {
            return nil
        }
        return getCell(for: item)
    }
    func setCurrentCellImage(image: UIImage?) {
        guard let image = image,
              let cell = getCell(for: currentPreviewIndex),
              !cell.scrollContentView.requestCompletion else {
            return
        }
        cell.scrollContentView.imageView.image = image
    }
    func deleteCurrentPhotoAsset() {
        if previewAssets.isEmpty || !isExternalPreview {
            return
        }
        let photoAsset = previewAssets[currentPreviewIndex]
        if let shouldDelete = pickerController?.previewShouldDeleteAsset(
            photoAsset: photoAsset,
            index: currentPreviewIndex
        ), !shouldDelete {
            return
        }
        #if HXPICKER_ENABLE_EDITOR
        photoAsset.photoEdit = nil
        photoAsset.videoEdit = nil
        #endif
        previewAssets.remove(
            at: currentPreviewIndex
        )
        collectionView.deleteItems(
            at: [
                IndexPath(
                    item: currentPreviewIndex,
                    section: 0
                )
            ]
        )
        if config.showBottomView {
            bottomView.selectedView.removePhotoAsset(photoAsset: photoAsset)
        }
        pickerController?.previewDidDeleteAsset(
            photoAsset: photoAsset,
            index: currentPreviewIndex
        )
        if previewAssets.isEmpty {
            didCancelItemClick()
            return
        }
        scrollViewDidScroll(collectionView)
        setupRequestPreviewTimer()
    }
    func replacePhotoAsset(at index: Int, with photoAsset: PhotoAsset) {
        previewAssets[index] = photoAsset
        reloadCell(for: photoAsset)
//        collectionView.reloadItems(at: [IndexPath.init(item: index, section: 0)])
    }
    func addedCameraPhotoAsset(_ photoAsset: PhotoAsset) {
        guard let picker = pickerController else { return }
        if config.bottomView.showSelectedView &&
            (isMultipleSelect || isExternalPreview) &&
            config.showBottomView {
            bottomView.selectedView.reloadData(
                photoAssets: picker.selectedAssetArray
            )
            configBottomViewFrame()
            bottomView.layoutSubviews()
            bottomView.updateFinishButtonTitle()
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
