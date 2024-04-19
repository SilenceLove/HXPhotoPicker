//
//  PhotoPickerListViewController.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/10/11.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit
import Photos

open class PhotoPickerListViewController:
    HXBaseViewController,
    PhotoPickerList,
    PhotopickerListRegisterClass,
    PhotoPickerListFectchCell,
    PhotoPickerListSwipeSelect
{
    public weak var delegate: PhotoPickerListDelegate?
    
    public var config: PhotoListConfiguration
    public var pickerConfig: PickerConfiguration
    
    public var emptyView: PhotoPickerEmptyView!
    public var collectionView: UICollectionView!
    public var contentInset: UIEdgeInsets = .zero {
        didSet {
            collectionView.contentInset = contentInset
        }
    }
    public var scrollIndicatorInsets: UIEdgeInsets = .zero {
        didSet {
            collectionView.scrollIndicatorInsets = scrollIndicatorInsets
        }
    }
    
    public var assetResult: PhotoFetchAssetResult = .init() {
        didSet {
            didFetchAsset = true
            photoCount = assetResult.photoCount
            videoCount = assetResult.videoCount
            allAssets = assetResult.assets
            assets = assetResult.assets
            if let collectionView {
                collectionView.reloadData()
            }
            updateEmptyView()
        }
    }
    
    public var assets: [PhotoAsset] = []
    public var didFetchAsset: Bool = false
    
    public var swipeSelectBeganIndexPath: IndexPath?
    public var swipeSelectedIndexArray: [Int]?
    public var swipeSelectState: PhotoPickerListSwipeSelectState?
    public var swipeSelectAutoScrollTimer: DispatchSourceTimer?
    public var swipeSelectPanGR: UIPanGestureRecognizer?
    public var swipeSelectLastLocalPoint: CGPoint?
    
    public var filterOptions: PhotoPickerFilterSection.Options = .any {
        didSet {
            filterPhotoAssets()
        }
    }
    
    public var photoCount: Int = 0
    public var videoCount: Int = 0
    
    var collectionViewLayout: UICollectionViewFlowLayout!
    
    var allAssets: [PhotoAsset] = []
    
    var scrollToTop = false
    var targetOffsetY: CGFloat = 0
    var didChangeCellLoadMode: Bool = false
    var scrollEndReload: Bool = false
    var scrollReachDistance = false
    
    var orientationDidChange: Bool = false
    var beforeOrientationIndexPath: IndexPath?
    var canScrollToBeforeIndexPath: Bool = false
    
    public required init(config: PickerConfiguration) {
        self.config = config.photoList
        self.pickerConfig = config
        super.init(nibName: nil, bundle: nil)
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        initViews()
    }
    
    func initViews() {
        collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.minimumLineSpacing = config.spacing
        collectionViewLayout.minimumInteritemSpacing = config.spacing
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: collectionViewLayout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        if !config.allowSwipeToSelect {
            collectionView.delaysContentTouches = false
        }
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }else {
            automaticallyAdjustsScrollViewInsets = false
        }
        registerClass()
        view.addSubview(collectionView)
        if pickerConfig.isMultipleSelect, config.allowSwipeToSelect {
            let panGR = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizer(panGR:)))
            view.addGestureRecognizer(panGR)
            switch pickerConfig.pickerPresentStyle {
            case .none:
                break
            default:
                panGR.delegate = self
            }
            swipeSelectPanGR = panGR
        }
        emptyView = PhotoPickerEmptyView(config: config.emptyView)
    }
    
    @objc
    func panGestureRecognizer(panGR: UIPanGestureRecognizer) {
        let localPoint = panGR.location(in: collectionView)
        swipeSelectLastLocalPoint = panGR.location(in: view)
        switch panGR.state {
        case .began:
            beganPanGestureRecognizer(panGR: panGR, localPoint: localPoint)
        case .changed:
            changedPanGestureRecognizer(panGR: panGR, localPoint: localPoint)
        case .ended, .cancelled, .failed:
            endedPanGestureRecognizer()
        default:
            break
        }
    }
    
    public func recallSwipeSelectAction() {
        guard let panGR = swipeSelectPanGR else { return }
        panGestureRecognizer(panGR: panGR)
    }
    
    public func selectCell(for asset: PhotoAsset, isSelected: Bool) {
        guard let cell = getCell(for: asset) else {
            if isSelected {
                pickerController.pickerData.append(asset)
            }else {
                pickerController.pickerData.remove(asset)
            }
            return
        }
        pickerCell(cell, didSelectControl: !isSelected)
    }
    
    public func addedAsset(for asset: PhotoAsset) {
        let indexPath: IndexPath
        if config.sort == .desc {
            allAssets.insert(asset, at: 0)
            if filterOptions != .any {
                filterPhotoAssets()
                return
            }else {
                assets = allAssets
            }
            indexPath = IndexPath(
                item: needOffset ? offsetIndex : 0,
                section: 0
            )
        }else {
            allAssets.append(asset)
            if filterOptions != .any {
                filterPhotoAssets()
                return
            }else {
                assets = allAssets
            }
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
        updateEmptyView()
    }
    
    public func reloadData() {
        filterPhotoAssets()
    }
    
    func filterPhotoAssets() {
        if filterOptions == .any {
            assets = allAssets
            photoCount = assetResult.photoCount
            videoCount = assetResult.videoCount
            collectionView.reloadData()
            scrollTo(nil)
            updateEmptyView()
            return
        }
        var photoCount: Int = 0
        var videoCount: Int = 0
        let assets = allAssets.filter {
            if filterOptions.contains(.edited) {
                #if HXPICKER_ENABLE_EDITOR
                if $0.editedResult != nil {
                    if $0.mediaType == .photo {
                        photoCount += 1
                    }else {
                        videoCount += 1
                    }
                    return true
                }
                #endif
            }
            if filterOptions.contains(.photo) {
                if $0.mediaSubType.isNormalPhoto {
                    photoCount += 1
                    return true
                }
            }
            if filterOptions.contains(.gif) {
                if $0.mediaSubType.isGif {
                    photoCount += 1
                    return true
                }
            }
            if filterOptions.contains(.livePhoto) {
                if $0.mediaSubType.isLivePhoto {
                    photoCount += 1
                    return true
                }
            }
            if filterOptions.contains(.video) {
                if $0.mediaType == .video {
                    videoCount += 1
                    return true
                }
            }
            return false
        }
        self.assets = assets
        self.photoCount = photoCount
        self.videoCount = videoCount
        collectionView.reloadData()
        scrollTo(nil)
        updateEmptyView()
    }
    
    func updateEmptyView() {
        guard let emptyView = emptyView else {
            return
        }
        if assets.isEmpty {
            view.addSubview(emptyView)
        }else {
            emptyView.removeFromSuperview()
        }
    }
    
    public func scrollToCenter(for photoAsset: PhotoAsset?) {
        if assets.isEmpty {
            return
        }
        if let photoAsset = photoAsset,
           var item = assets.firstIndex(of: photoAsset) {
            if needOffset {
                item += offsetIndex
            }
            canScrollToBeforeIndexPath = false
            collectionView.scrollToItem(
                at: IndexPath(item: item, section: 0),
                at: .centeredVertically,
                animated: false
            )
        }
    }
    
    public func scrollCellToVisibleArea(_ cell: PhotoPickerBaseViewCell) {
        if assets.isEmpty {
            return
        }
        let rect = cell.photoView.convert(cell.photoView.bounds, to: view)
        var scrollPosition: UICollectionView.ScrollPosition?
        if rect.minY - collectionView.contentInset.top < 0 {
            scrollPosition = .top
        }else if rect.maxY > view.height - collectionView.contentInset.bottom {
            scrollPosition = .bottom
        }
        if let indexPath = collectionView.indexPath(for: cell), let scrollPosition {
            canScrollToBeforeIndexPath = false
            collectionView.scrollToItem(
                at: indexPath,
                at: scrollPosition,
                animated: false
            )
        }
    }
    
    public override func deviceOrientationWillChanged(notify: Notification) {
        orientationDidChange = true
        let items = collectionView.indexPathsForVisibleItems.sorted { $0.item < $1.item }
        if !items.isEmpty {
            if items.last?.item == numberOfItems - 1 {
                beforeOrientationIndexPath = items.last
                return
            }
            if items.first?.item == 0 {
                beforeOrientationIndexPath = items.first
                return
            }
            let startItem: Int
            if let item = items.first?.item {
                startItem = item
            }else {
                startItem = 0
            }
            let endItem: Int
            if let item = items.last?.item {
                endItem = item
            }else {
                endItem = 0
            }
            if let beforeItem = beforeOrientationIndexPath?.item,
               beforeItem >= startItem, beforeItem <= endItem {
                return
            }
            let middleIndex = min(items.count - 1, max(0, items.count / 2))
            beforeOrientationIndexPath = items[middleIndex]
        }
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let space = config.spacing
        let count: CGFloat
        if  UIDevice.isPortrait {
            count = CGFloat(config.rowNumber)
        }else {
            if let splitViewController = splitViewController as? PhotoSplitViewController, !UIDevice.isPad {
                if splitViewController.isSplitShowColumn {
                    count = CGFloat(config.spltRowNumber)
                }else {
                    if splitViewController.supportedInterfaceOrientations == .portrait ||
                        splitViewController.supportedInterfaceOrientations == .portraitUpsideDown {
                        count = CGFloat(config.rowNumber)
                    }else {
                        count = CGFloat(config.landscapeRowNumber)
                    }
                }
            }else {
                count = CGFloat(config.landscapeRowNumber)
            }
        }
        let itemWidth = (view.width - space * (count - CGFloat(1))) / count
        collectionViewLayout.itemSize = .init(width: itemWidth, height: itemWidth)
        collectionView.frame = view.bounds
        
        emptyView.width = view.width
        emptyView.center = CGPoint(
            x: view.width * 0.5,
            y: (view.height - contentInset.top - contentInset.bottom) * 0.5
        )
        
        if orientationDidChange {
            reloadData()
            if navigationController?.topViewController is PhotoPickerViewController {
                canScrollToBeforeIndexPath = true
                DispatchQueue.main.async {
                    if self.canScrollToBeforeIndexPath {
                        if let indexPath = self.beforeOrientationIndexPath {
                            self.scrollTo(at: indexPath, at: .centeredVertically, animated: false)
                        }
                        self.canScrollToBeforeIndexPath = false
                    }
                }
            }
            orientationDidChange = false
        }
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        HXLog("PickerListController deinited 👍")
    }
}

extension PhotoPickerListViewController: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        numberOfItems
    }
    public func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        if let cell = dequeueReusableAdditiveCell(indexPath) {
            return cell
        }
        let asset = getAsset(for: indexPath.item)
        let cell = dequeueReusableCell(for: indexPath, with: asset)
        cell.delegate = self
        cell.config = config.cell
        cell.isRequestDirectly = false
        cell.photoAsset = asset
        return cell
    }
}

extension PhotoPickerListViewController: UICollectionViewDelegate {
    public func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        guard let myCell = cell as? PhotoPickerBaseViewCell else {
            return
        }
        myCell.request()
        let photoAsset = getAsset(for: indexPath.item)
        if !photoAsset.isSelected &&
            config.cell.isShowDisableMask &&
            pickerConfig.maximumSelectedVideoFileSize == 0 &&
            pickerConfig.maximumSelectedPhotoFileSize == 0 {
            myCell.canSelect = pickerController.pickerData.canSelect(
                photoAsset,
                isShowHUD: false
            )
        }else {
            myCell.canSelect = true
        }
        myCell.updateSelectedState(
            isSelected: photoAsset.isSelected,
            animated: false
        )
    }
    public func collectionView(
        _ collectionView: UICollectionView,
        didEndDisplaying cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        guard let myCell = cell as? PhotoPickerBaseViewCell else {
            return
        }
        myCell.cancelReload()
        if let pickerCell = myCell as? PhotoPickerViewCell {
            pickerCell.cancelSyncICloud()
        }
    }
    public func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        didSelectItem(indexPath: indexPath, animated: true)
    }
    
    func didSelectItem(indexPath: IndexPath, animated: Bool) {
        collectionView.deselectItem(at: indexPath, animated: false)
        guard navigationController?.topViewController is PhotoPickerViewController,
              let cell = collectionView.cellForItem(at: indexPath) else {
            return
        }
        #if !targetEnvironment(macCatalyst)
        if cell is PickerCameraViewCell {
            delegate?.photoList(presentCamera: self)
            return
        }
        #endif
        if cell is PhotoPickerLimitCell {
            if #available(iOS 14, *) {
                PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: pickerController)
            }
            return
        }
        if let myCell = cell as? PhotoPickerBaseViewCell,
           let photoAsset = myCell.photoAsset {
            if !myCell.canSelect {
                return
            }
            if let pickerCell = myCell as? PhotoPickerViewCell,
               pickerCell.inICloud {
                if pickerCell.photoAsset.downloadStatus != .downloading {
                    pickerCell.syncICloud()
                }
                return
            }
            let item = needOffset ? indexPath.item - offsetIndex : indexPath.item
            delegate?.photoList(self, didSelectCell: photoAsset, at: item, animated: animated)
        }
    }
    
    @available(iOS 13.0, *)
    public func collectionView(
        _ collectionView: UICollectionView,
        contextMenuConfiguration configuration: UIContextMenuConfiguration,
        highlightPreviewForItemAt indexPath: IndexPath
    ) -> UITargetedPreview? {
        guard let cell = collectionView.cellForItem(at: indexPath) as? PhotoPickerBaseViewCell,
              config.allowHapticTouchPreview else {
            return nil
        }
        return .init(view: cell)
    }
    
    @available(iOS 13.0, *)
    public func collectionView(
        _ collectionView: UICollectionView,
        contextMenuConfigurationForItemsAt indexPaths: [IndexPath],
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard let indexPath = indexPaths.first,
              let sCell = collectionView.cellForItem(at: indexPath),
              config.allowHapticTouchPreview else {
            return nil
        }
        let isCameraCell: Bool
        #if !targetEnvironment(macCatalyst)
        isCameraCell = sCell is PickerCameraViewCell
        if isCameraCell {
            if !UIImagePickerController.isSourceTypeAvailable(.camera) ||
                AssetPermissionsUtil.cameraAuthorizationStatus != .authorized {
                return nil
            }
        }
        #else
        isCameraCell = false
        #endif
        let viewSize = view.size
        return .init(
            identifier: indexPath as NSCopying
        ) {
            if let cell = sCell as? PhotoPickerBaseViewCell {
                let photoAsset = cell.photoAsset!
                let imageSize = photoAsset.imageSize
                let aspectRatio = imageSize.width / imageSize.height
                let maxWidth = viewSize.width - UIDevice.leftMargin - UIDevice.rightMargin - 60
                let maxHeight: CGFloat
                if UIDevice.isPortrait {
                    maxHeight = UIDevice.screenSize.height * 0.659
                }else {
                    maxHeight = UIDevice.screenSize.height - UIDevice.topMargin - UIDevice.bottomMargin
                }
                var width = imageSize.width
                var height = imageSize.height
                if width > maxWidth {
                    width = maxWidth
                    height = min(width / aspectRatio, maxHeight)
                }
                if height > maxHeight {
                    height = maxHeight
                    width = min(height * aspectRatio, maxWidth)
                }
                width = max(120, width)
                height = max(120, height)
                let vc = PhotoPeekViewController(photoAsset)
                vc.delegate = self
                vc.preferredContentSize = CGSize(width: width, height: height)
                return vc
            }else if isCameraCell {
                let vc = PhotoPeekViewController(isCamera: true)
                if UIDevice.isPortrait {
                    let width = UIScreen._width
                    vc.preferredContentSize = .init(width: width, height: width / 9 * 16)
                }else {
                    let height = UIScreen._height
                    vc.preferredContentSize = .init(width: height / 9 * 16, height: height)
                }
                return vc
            }
            return nil
        } actionProvider: { [weak self] _ in
            guard let self = self,
                  let cell = sCell as? PhotoPickerBaseViewCell,
                  self.config.allowAddMenuElements else {
                return nil
            }
            var menus: [UIMenuElement] = []
            let photoAsset = cell.photoAsset!
            if self.pickerConfig.selectMode == .multiple {
                let title: String
                let image: UIImage?
                let attributes: UIMenuElement.Attributes
                if photoAsset.isSelected {
                    title = .textPhotoList.hapticTouchDeselectedTitle.text
                    image = UIImage(systemName: "minus.circle")
                    attributes = [.destructive]
                }else {
                    title = .textPhotoList.hapticTouchSelectedTitle.text
                    image = UIImage(systemName: "checkmark.circle")
                    attributes = []
                }
                let select = UIAction(
                    title: title,
                    image: image,
                    attributes: attributes
                ) { [weak self] _ in
                    guard let self = self,
                          let cell = self.getCell(for: indexPath.item) else {
                        return
                    }
                    self.pickerCell(cell, didSelectControl: photoAsset.isSelected)
                }
                menus.append(select)
            }
            
            #if HXPICKER_ENABLE_EDITOR
            let options: PickerAssetOptions
            if photoAsset.mediaType == .photo {
                options = .photo
            }else {
                options = .video
            }
            if self.pickerConfig.editorOptions.contains(options) {
                let edit = UIAction(
                    title: .textPhotoList.hapticTouchEditTitle.text,
                    image: UIImage(systemName: "slider.horizontal.3")
                ) { [weak self] _ in
                    guard let self = self else { return }
                    self.delegate?.photoList(self, openEditor: photoAsset, with: cell.photoView.image)
                }
                menus.append(edit)
            }
            if photoAsset.editedResult != nil {
                let removeEdit = UIAction(
                    title: .textPhotoList.hapticTouchRemoveEditTitle.text,
                    image: .init(systemName: "xmark.circle"),
                    attributes: [.destructive]
                ) { [weak self] _ in
                    guard let self = self,
                          let cell = self.getCell(for: indexPath.item),
                          let photoAsset = cell.photoAsset else {
                        return
                    }
                    if photoAsset.videoEditedResult != nil {
                        photoAsset.editedResult = nil
                        cell.isRequestDirectly = true
                        cell.updatePhotoAsset(photoAsset)
                    }else if photoAsset.photoEditedResult != nil {
                        photoAsset.editedResult = nil
                        cell.updatePhotoAsset(photoAsset)
                    }
                    self.delegate?.photoList(self, updateAsset: photoAsset)
                }
                menus.append(removeEdit)
            }
            #endif
            
            return .init(children: menus)
        }
    }
    
    @available(iOS 13.0, *)
    public func collectionView(
        _ collectionView: UICollectionView,
        willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration,
        animator: UIContextMenuInteractionCommitAnimating
    ) {
        guard let indexPath = configuration.identifier as? IndexPath else {
            return
        }
        animator.addCompletion { [weak self] in
            self?.didSelectItem(
                indexPath: indexPath,
                animated: false
            )
        }
    }
    
    public func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        if config.isShowAssetNumber &&
            kind == UICollectionView.elementKindSectionFooter &&
            (photoCount > 0 || videoCount > 0) {
            let view = collectionView
                .dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: PhotoPickerBottomNumberView.className,
                    for: indexPath
                ) as! PhotoPickerBottomNumberView
            view.photoCount = photoCount
            view.videoCount = videoCount
            view.config = config.assetNumber
            view.filterOptions = filterOptions
            view.didFilterHandler = { [weak self] in
                guard let self = self else { return }
                if #available(iOS 13.0, *) {
                    self.delegate?.photoList(presentFilter: self, modalPresentationStyle: .automatic)
                } else {
                    self.delegate?.photoList(presentFilter: self, modalPresentationStyle: .fullScreen)
                }
            }
            return view
        }
        return .init()
    }
    public func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        PhotoManager.shared.thumbnailLoadModeDidChange(.complete)
        cellReloadImage()
        scrollToTop = false
    }
    public func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        scrollToTop = true
        scrollEndReload = true
        PhotoManager.shared.thumbnailLoadModeDidChange(.simplify)
        return true
    }
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if scrollToTop { return }
        updateCellLoadMode(.complete)
        cellReloadImage()
    }
    public func scrollViewDidEndDragging(
        _ scrollView: UIScrollView,
        willDecelerate decelerate: Bool
    ) {
        if !decelerate && !scrollToTop {
            didChangeCellLoadMode = false
            cellReloadImage()
        }
    }
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if !scrollView.isTracking && !scrollToTop {
            didChangeCellLoadMode = false
            cellReloadImage()
        }
    }
    public func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        let offset = targetContentOffset.pointee
        let abs = abs(offset.y - scrollView.contentOffset.y)
        if abs < 3000 {
            if scrollReachDistance {
                updateCellLoadMode(.complete, judgmentIsEqual: false)
                scrollReachDistance = false
            }
            return
        }
        targetOffsetY = offset.y
        updateCellLoadMode(.simplify)
        scrollReachDistance = true
    }
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        if scrollToTop {
            let scrollY = offsetY + scrollView.contentInset.top
            if scrollY < scrollView.height {
                updateCellLoadMode(.complete)
            }
        }
        if didChangeCellLoadMode {
            if abs(targetOffsetY - offsetY) < 1250 {
                updateCellLoadMode(.complete)
            }
        }
    }
    public func updateCellLoadMode(_ mode: PhotoManager.ThumbnailLoadMode, judgmentIsEqual: Bool = true) {
        if PhotoManager.shared.thumbnailLoadMode == mode && judgmentIsEqual {
            return
        }
        PhotoManager.shared.thumbnailLoadModeDidChange(mode)
        scrollEndReload = mode == .complete
        didChangeCellLoadMode = mode != .complete
    }
    public func cellReloadImage() {
        if !scrollEndReload &&
            !didChangeCellLoadMode &&
            PhotoManager.shared.thumbnailLoadMode == .complete {
            return
        }
        for baseCell in collectionView.visibleCells where baseCell is PhotoPickerBaseViewCell {
            let cell = baseCell as! PhotoPickerBaseViewCell
            cell.reload()
        }
        scrollEndReload = false
    }
}

extension PhotoPickerListViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForFooterInSection section: Int
    ) -> CGSize {
        if config.isShowAssetNumber && (photoCount > 0 || videoCount > 0) {
            return CGSize(width: view.width, height: filterOptions == .any ? 50 : 70)
        }
        return .zero
    }
}

extension PhotoPickerListViewController: PhotoPickerViewCellDelegate {
    
    public func pickerCell(
        _ cell: PhotoPickerBaseViewCell,
        didSelectControl isSelected: Bool
    ) {
        if isSelected {
            // 取消选中
            let photoAsset = cell.photoAsset!
            let isSuccess = pickerController.pickerData.remove(photoAsset)
            #if HXPICKER_ENABLE_EDITOR
            if photoAsset.videoEditedResult != nil, pickerConfig.isDeselectVideoRemoveEdited {
                photoAsset.editedResult = nil
                cell.updatePhotoAsset(photoAsset)
            }else if photoAsset.photoEditedResult != nil, pickerConfig.isDeselectPhotoRemoveEdited {
                photoAsset.editedResult = nil
                cell.updatePhotoAsset(photoAsset)
            }else {
                cell.updateSelectedState(
                    isSelected: false,
                    animated: true
                )
            }
            #else
            cell.updateSelectedState(
                isSelected: false,
                animated: true
            )
            #endif
            updateCellSelectedTitle()
            if isSuccess {
                delegate?.photoList(self, didDeselectedAsset: photoAsset)
            }
        }else {
            // 选中
            #if HXPICKER_ENABLE_EDITOR
            if cell.photoAsset.mediaType == .video &&
                pickerController.pickerData.videoDurationExceedsTheLimit(cell.photoAsset) &&
                pickerConfig.editorOptions.isVideo {
                if pickerController.pickerData.canSelect(
                    cell.photoAsset,
                    isShowHUD: true
                ) {
                    delegate?.photoList(self, openEditor: cell.photoAsset, with: cell.photoView.image)
                }
                return
            }
            #endif
            func addAsset() {
                if pickerController.pickerData.append(cell.photoAsset) {
                    delegate?.photoList(self, didSelectedAsset: cell.photoAsset)
                }
                cell.updateSelectedState(
                    isSelected: true,
                    animated: true
                )
                updateCellSelectedTitle()
            }
            let inICloud: Bool
            if let pickerCell = cell as? PhotoPickerViewCell {
                inICloud = pickerCell.checkICloundStatus(allowSyncPhoto: pickerConfig.allowSyncICloudWhenSelectPhoto)
            }else {
                inICloud = cell.photoAsset.checkICloundStatus(
                    allowSyncPhoto: pickerConfig.allowSyncICloudWhenSelectPhoto,
                    completion: { _, isSuccess in
                    if isSuccess {
                        addAsset()
                    }
                })
            }
            if !inICloud {
                addAsset()
            }
        }
        delegate?.photoList(selectedAssetDidChanged: self)
    }
    
    public func pickerCell(videoRequestDurationCompletion cell: PhotoPickerBaseViewCell) {
        if !cell.photoAsset.isSelected &&
            config.cell.isShowDisableMask &&
            pickerConfig.maximumSelectedVideoFileSize == 0 &&
            pickerConfig.maximumSelectedPhotoFileSize == 0 {
            cell.canSelect = pickerController.pickerData.canSelect(
                cell.photoAsset,
                isShowHUD: false
            )
        }else {
            cell.canSelect = true
        }
    }
}

extension PhotoPickerListViewController: PhotoPeekViewControllerDelegate {
    public func photoPeekViewController(
        requestSucceed photoPeekViewController: PhotoPeekViewController
    ) {
        guard let photoAsset = photoPeekViewController.photoAsset else {
            return
        }
        resetICloud(for: photoAsset)
    }
}

extension PhotoPickerListViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer != swipeSelectPanGR {
            return true
        }
        let point = gestureRecognizer.location(in: view)
        return point.x > pickerConfig.photoList.swipeSelectIgnoreLeftArea
    }
}
