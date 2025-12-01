//
//  PhotoToolBarGlassView.swift
//  HXPhotoPickerExample
//
//  Created by Silence on 2025/10/13.
//  Copyright © 2025 Silence. All rights reserved.
//

import UIKit

@available(iOS 26.0, *)
public class PhotoToolBarGlassView: UIView, PhotoToolBar {
    
    public weak var toolbarDelegate: PhotoToolBarDelegate?
    
    public var toolbarHeight: CGFloat {
        if type == .browser {
            return 70 + UIDevice.bottomMargin
        }
        if pickerConfig.selectMode == .single, isShowPrompt {
            return 0
        }
        return 50 + UIDevice.bottomMargin
    }
    
    public var viewHeight: CGFloat {
        if pickerConfig.selectMode == .single, isShowPrompt, type != .browser {
            return 55 + UIDevice.bottomMargin
        }
        var viewHeight: CGFloat = toolbarHeight
        if type == .picker {
            if isShowPrompt {
                viewHeight += 70
            }else {
                if isShowSelectedView, selectedView.assetCount > 0 {
                    viewHeight += 75
                }
            }
        }else if type == .preview {
            if isShowPreviewList {
                viewHeight += 75
            }else {
                if isShowSelectedView, selectedView.assetCount > 0 {
                    viewHeight += 75
                }
            }
        }
        return viewHeight
    }
    
    public var selectViewOffset: CGPoint? {
        get {
            if !isShowSelectedView {
                return nil
            }
            return selectedView.contentOffset
        }
        set {
            guard let contentOffset = newValue else {
                return
            }
            selectedView.contentOffset = contentOffset
        }
    }
    
    var previewAssets: [PhotoAsset] = []
    private var previewPage: Int?
     
    #if HXPICKER_ENABLE_EDITOR
    private var editBtn: UIBarButtonItem!
    #endif
    
    private let pickerConfig: PickerConfiguration
    private let type: PhotoToolBarType
    private var promptBgView: UIToolbar!
    private var selectedView: PhotoPreviewSelectedView!
    private var previewListView: PhotoPreviewListView!
    private var previewShadeView: UIView!
    private var previewShadeMaskLayer: CAGradientLayer!
    private var contentView: UIToolbar!
    private var previewBtn: UIBarButtonItem!
    private var originalItem: UIBarButtonItem!
    private var originalBtn: UIButton!
    private var finishBtn: UIBarButtonItem!
    
    private var isShowPrompt: Bool {
        type == .picker &&
        AssetPermissionsUtil.isLimitedAuthorizationStatus &&
        pickerConfig.photoList.bottomView.isShowPrompt &&
        pickerConfig.allowLoadPhotoLibrary
    }
    private var isShowSelectedView: Bool {
        switch type {
        case .picker:
            return pickerConfig.photoList.bottomView.isShowSelectedView && pickerConfig.selectMode == .multiple
        case .preview:
            return pickerConfig.previewView.bottomView.isShowSelectedView && pickerConfig.selectMode == .multiple && !isShowPreviewList
        case .browser:
            return !isShowPreviewList
        }
    }
    private var isShowPreviewList: Bool {
        switch type {
        case .picker:
            return false
        case .preview, .browser:
            return pickerConfig.previewView.bottomView.isShowPreviewList
        }
    }
    
    private var allowPreviewDidScroll: Bool = true
    private var assetCount: Int = 0
    
    private var isCanLoadOriginal: Bool {
        ((type == .picker && pickerConfig.photoList.bottomView.isShowOriginalFileSize) ||
         (type == .preview && pickerConfig.previewView.bottomView.isShowOriginalFileSize)) &&
        assetCount > 0
    }
    
    public required init(_ config: PickerConfiguration, type: PhotoToolBarType) {
        pickerConfig = config
        self.type = type
        super.init(frame: .zero)
        
        contentView = UIToolbar(frame: CGRect(x: 0, y: 0, width: width, height: 50 + UIDevice.bottomMargin))
        let viewConfig: PickerBottomViewConfiguration
        if type == .picker {
            if pickerConfig.selectMode != .single {
                addSubview(contentView)
            }
            viewConfig = pickerConfig.photoList.bottomView
            if isShowPrompt {
                promptBgView = UIToolbar()
                let item = makePermissionPromptItem()
                promptBgView.setItems([item], animated: false)
                addSubview(promptBgView)
            }
            if isShowSelectedView {
                initSelectedView()
            }
            previewBtn = .init(title: .textPhotoList.bottomView.previewTitle.text, style: .plain, target: self, action: #selector(didPreviewButtonClick))
            previewBtn.isEnabled = false
            previewBtn.isHidden = viewConfig.isHiddenPreviewButton
        }else if type == .preview {
            addSubview(contentView)
            viewConfig = pickerConfig.previewView.bottomView
            if isShowPreviewList {
                previewListView = PhotoPreviewListView()
                previewListView.dataSource = self
                
                previewShadeMaskLayer = CAGradientLayer()
                previewShadeMaskLayer.colors = [UIColor.clear.cgColor, UIColor.white.cgColor, UIColor.white.cgColor, UIColor.clear.cgColor]
                previewShadeMaskLayer.locations = [0.0, 0.075, 0.925, 1.0]
                previewShadeMaskLayer.startPoint = .init(x: 0, y: 0.5)
                previewShadeMaskLayer.endPoint = .init(x: 1, y: 0.5)
                
                previewShadeView = UIView(frame: .init(x: 0, y: 0, width: width, height: 55))
                previewShadeView.addSubview(previewListView)
                previewShadeView.layer.mask = previewShadeMaskLayer
                addSubview(previewShadeView)
            }else {
                if isShowSelectedView {
                    initSelectedView()
                }
            }
            #if HXPICKER_ENABLE_EDITOR
            editBtn = .init(title: .textPreview.bottomView.editTitle.text, style: .plain, target: self, action: #selector(didEditBtnButtonClick))
            editBtn.isHidden = viewConfig.isHiddenEditButton
            #endif
        }else {
            viewConfig = pickerConfig.previewView.bottomView
            if isShowPreviewList {
                previewListView = PhotoPreviewListView()
                previewListView.dataSource = self
                
                previewShadeMaskLayer = CAGradientLayer()
                previewShadeMaskLayer.colors = [UIColor.clear.cgColor, UIColor.white.cgColor, UIColor.white.cgColor, UIColor.clear.cgColor]
                previewShadeMaskLayer.locations = [0.0, 0.075, 0.925, 1.0]
                previewShadeMaskLayer.startPoint = .init(x: 0, y: 0.5)
                previewShadeMaskLayer.endPoint = .init(x: 1, y: 0.5)
                
                previewShadeView = UIView(frame: .init(x: 0, y: 0, width: width, height: 55))
                previewShadeView.addSubview(previewListView)
                previewShadeView.layer.mask = previewShadeMaskLayer
                addSubview(previewShadeView)
            }else {
                if isShowSelectedView {
                    initSelectedView()
                    selectedView.allowDrop = false
                }
            }
        }
        
        if type != .browser {
            originalItem = makeCenterItem()
            originalItem.isHidden = viewConfig.isHiddenOriginalButton
             
            if type == .picker {
                finishBtn = .init(title: .textPhotoList.bottomView.finishTitle.text, style: .plain, target: self, action: #selector(didFinishButtonClick))
            }else {
                finishBtn = .init(title: .textPreview.bottomView.finishTitle.text, style: .plain, target: self, action: #selector(didFinishButtonClick))
            }
            if config.selectMode == .multiple {
                finishBtn.isEnabled = false
            }
        }
        let leftItem: UIBarButtonItem
        if let previewBtn {
            leftItem = previewBtn
        }else {
            #if HXPICKER_ENABLE_EDITOR
            if let editBtn {
                leftItem = editBtn
            }else {
                leftItem = .flexibleSpace()
            }
            #else
            leftItem = .flexibleSpace()
            #endif
        }
        let centerItem: UIBarButtonItem
        if let originalItem {
            centerItem = originalItem
        }else {
            centerItem = .flexibleSpace()
        }
        
        let rightItem: UIBarButtonItem
        if let finishBtn {
            rightItem = finishBtn
        }else {
            rightItem = .flexibleSpace()
        }
        let flex = UIBarButtonItem.flexibleSpace()
        contentView.setItems([leftItem, flex, centerItem, flex, rightItem], animated: false)
        contentView.insetsLayoutMarginsFromSafeArea = false
        
        let tmpBtn = UIButton(type: .system)
        tmpBtn.configuration = .glass()
        let tmpItem = UIBarButtonItem(customView: tmpBtn).hidesShared()
        let tmpToolView = UIToolbar()
        tmpToolView.setItems([tmpItem], animated: false)
        addSubview(tmpToolView)
        tmpToolView.x = -UIScreen._width
        tmpToolView.y = 100
        
        layoutSubviews()
        bringSubviewToFront(contentView)
        if selectedView != nil {
            bringSubviewToFront(selectedView)
        }
        if previewListView != nil {
            bringSubviewToFront(previewListView)
        }
        if promptBgView != nil {
            bringSubviewToFront(promptBgView)
        }
        configColor()
    }
    
    func makeCenterItem() -> UIBarButtonItem {
        originalBtn = ExpandButton(type: .system)
        var cfg = UIButton.Configuration.plain()
        cfg.background.backgroundColorTransformer = UIConfigurationColorTransformer { _ in .clear }
        cfg.background.visualEffect = nil
        cfg.baseForegroundColor = .label
//        cfg.imageColorTransformer = UIConfigurationColorTransformer { [weak self] color in
//            guard let self else { return color }
//            if self.originalBtn.isSelected {
//                return self.pickerConfig.photoList.bottomView.originalSelectBox.selectedBackgroundColor
//            }else {
//                return color
//            }
//        }
        cfg.imagePadding = 4
        cfg.contentInsets = .init(top: 0, leading: 5, bottom: 0, trailing: 5)
        originalBtn.configuration = cfg
        
        if type == .picker {
            originalBtn.setTitle(.textPhotoList.bottomView.originalTitle.text, for: .normal)
        }else {
            originalBtn.setTitle(.textPreview.bottomView.originalTitle.text, for: .normal)
        }
        originalBtn.setImage(.init(systemName: "circle")?.withRenderingMode(.alwaysTemplate), for: .normal)
        originalBtn.setImage(.init(systemName: "checkmark.circle.fill")?.withRenderingMode(.alwaysTemplate), for: .selected)
        originalBtn.addTarget(self, action: #selector(didOriginalButtonClick), for: .touchUpInside)
        
        originalBtn.titleLabel?.numberOfLines = 0
        originalBtn.titleLabel?.adjustsFontSizeToFitWidth = true
        originalBtn.titleLabel?.lineBreakMode = .byTruncatingMiddle
        return UIBarButtonItem(customView: originalBtn)
    }
    
    func makePermissionPromptItem() -> UIBarButtonItem {
        let button = ExpandButton(type: .system)
        var cfg = UIButton.Configuration.plain()
        cfg.background.backgroundColorTransformer = UIConfigurationColorTransformer { _ in .clear }
        cfg.background.visualEffect = nil
        cfg.baseForegroundColor = .label
        cfg.imagePadding = 10
        cfg.buttonSize = .mini
        cfg.contentInsets = .init(top: 5, leading: 10, bottom: 5, trailing: 10)
        button.configuration = cfg
        
        button.setTitle(.textPhotoList.bottomView.permissionsTitle.text, for: .normal)
        button.titleLabel?.font = .textPhotoList.bottomView.permissionsTitleFont
        button.setImage(.imageResource.picker.photoList.bottomView.permissionsPrompt.image?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.addTarget(self, action: #selector(didPromptViewClick), for: .touchUpInside)
        return UIBarButtonItem(customView: button)
    }
    
    @objc
    private func didPromptViewClick() {
        PhotoTools.openSettingsURL()
    }
    
    private func initSelectedView() {
        let viewConfig = pickerConfig.previewView.bottomView
        selectedView = PhotoPreviewSelectedView(frame: CGRect(x: 0, y: 0, width: width, height: 70))
        selectedView.isPhotoList = type == .picker
        if let cellClass = viewConfig.customSelectedViewCellClass {
            selectedView.collectionView.register(
                cellClass,
                forCellWithReuseIdentifier: PhotoPreviewSelectedViewCell.className
            )
        }else {
            selectedView.collectionView.register(
                PhotoPreviewSelectedViewCell.self,
                forCellWithReuseIdentifier: PhotoPreviewSelectedViewCell.className
            )
        }
        selectedView.delegate = self
        addSubview(selectedView)
    }
    public func updateOriginalState(_ isSelected: Bool) {
        guard let originalBtn else { return}
        originalBtn.isSelected = isSelected
    }
    
    public func requestOriginalAssetBtyes() {
        if type == .browser { return }
        guard let originalBtn else { return}
        if !originalBtn.isSelected {
            return
        }
        if isCanLoadOriginal {
            startOriginalLoading()
        }
        toolbarDelegate?.photoToolbar(self, didOriginalClick: true)
    }
    
    public func originalAssetBytes(_ bytes: Int, bytesString: String) {
        guard let originalBtn else { return}
        if !originalBtn.isSelected || !isCanLoadOriginal {
            stopOriginalLoading(bytes: 0, bytesString: "")
            return
        }
        stopOriginalLoading(bytes: bytes, bytesString: bytesString)
    }
    
    #if HXPICKER_ENABLE_EDITOR
    public func updateEditState(_ isEnabled: Bool) {
        if type == .browser { return }
        editBtn.isEnabled = isEnabled
    }
    #endif
    
    public func selectedAssetDidChanged(_ photoAssets: [PhotoAsset]) {
        if type == .browser { return }
        updateFinishButtonTitle(photoAssets)
    }
    
    public func insertSelectedAsset(_ photoAsset: PhotoAsset) {
        if !isShowSelectedView { return }
        selectedView.insertPhotoAsset(photoAsset: photoAsset) { [weak self] in
            guard let self, self.isShowPrompt else {
                return
            }
            self.promptBgView.alpha = 0
        }
    }
    
    public func removeSelectedAssets(_ photoAssets: [PhotoAsset]) {
        if !isShowSelectedView { return }
        selectedView.removePhotoAssets(photoAssets) { [weak self] in
            guard let self, self.isShowPrompt else {
                return
            }
            self.promptBgView.alpha = 1
        }
    }
    
    public func reloadSelectedAsset(_ photoAsset: PhotoAsset) {
        if !isShowSelectedView { return }
        selectedView.reloadData(photoAsset: photoAsset)
    }
    
    public func updateSelectedAssets(_ photoAssets: [PhotoAsset]) {
        if !isShowSelectedView { return }
        if isShowPrompt {
            if selectedView.photoAssetArray.isEmpty, !photoAssets.isEmpty {
                promptBgView.alpha = 0
            }else if photoAssets.isEmpty {
                promptBgView.alpha = 1
            }
        }
        selectedView.reloadData(photoAssets: photoAssets)
    }
    
    public func selectedViewScrollTo(_ photoAsset: PhotoAsset?, animated: Bool) {
        if !isShowSelectedView { return }
        selectedView.scrollTo(photoAsset: photoAsset, isAnimated: animated)
    }
    
    public func deviceOrientationDidChanged() {
        if !isShowSelectedView { return }
        UIView.animate(withDuration: 0.2) {
            self.selectedView.reloadSectionInset()
        }
    }
    
    @objc
    private func didPreviewButtonClick() {
        toolbarDelegate?.photoToolbar(didPreviewClick: self)
    }
    
    #if HXPICKER_ENABLE_EDITOR
    @objc
    private func didEditBtnButtonClick() {
        toolbarDelegate?.photoToolbar(didEditClick: self)
    }
    #endif
    
    @objc
    private func didOriginalButtonClick() {
        guard let originalBtn else { return}
        originalBtn.isSelected = !originalBtn.isSelected
        let isSelected = originalBtn.isSelected
        if isSelected {
            if isCanLoadOriginal {
                startOriginalLoading()
            }
        }else {
            stopOriginalLoading(bytes: 0, bytesString: "")
        }
        toolbarDelegate?.photoToolbar(self, didOriginalClick: isSelected)
    }
    
    private func startOriginalLoading() {
        guard let originalBtn else { return}
        if type == .picker {
            originalBtn.setTitle(.textPhotoList.bottomView.originalTitle.text, for: .normal)
        }else {
            originalBtn.setTitle(.textPreview.bottomView.originalTitle.text, for: .normal)
        }
        originalBtn.invalidateIntrinsicContentSize()
        originalBtn.setNeedsLayout()
        originalBtn.layoutIfNeeded()
        contentView.setNeedsLayout()
        contentView.layoutIfNeeded()
    }
    
    private func stopOriginalLoading(bytes: Int, bytesString: String) {
        guard let originalBtn else { return}
        let originalTitle: String
        if type == .picker {
            originalTitle = .textPhotoList.bottomView.originalTitle.text
        }else {
            originalTitle = .textPreview.bottomView.originalTitle.text
        }
        if bytes > 0 {
            originalBtn.setTitle(originalTitle + " (" + bytesString + ")", for: .normal)
        }else {
            originalBtn.setTitle(originalTitle, for: .normal)
        }
        originalBtn.invalidateIntrinsicContentSize()
        originalBtn.setNeedsLayout()
        originalBtn.layoutIfNeeded()
        contentView.setNeedsLayout()
        contentView.layoutIfNeeded()
    }
    
    @objc
    private func didFinishButtonClick() {
        toolbarDelegate?.photoToolbar(didFinishClick: self)
    }
    
    public var leftMargin: CGFloat {
        if let splitViewController = viewController?.splitViewController as? PhotoSplitViewController,
           !UIDevice.isPortrait,
           !UIDevice.isPad {
            if !splitViewController.isSplitShowColumn {
                return UIDevice.leftMargin
            }else {
                return 0
            }
        }else {
            return UIDevice.leftMargin
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        contentView.x = 0
        contentView.width = width
        contentView.height = 50 + UIDevice.bottomMargin
        if type == .picker {
            if isShowPrompt {
                if pickerConfig.selectMode != .single {
                    promptBgView.frame = .init(x: 0, y: 0, width: width, height: 70)
                }else {
                    promptBgView.frame = .init(x: 0, y: 0, width: width, height: 55)
                }
                contentView.y = promptBgView.frame.maxY
            }
            if isShowSelectedView {
                selectedView.y = 0
                selectedView.width = width
                if !isShowPrompt {
                    if selectedView.assetCount > 0 {
                        contentView.y = selectedView.frame.maxY + 5
                    }else {
                        contentView.y = height - contentView.height
                    }
                }
            }else if !isShowPrompt {
                contentView.y = height - contentView.height
            }
        }else if type == .preview {
            if isShowPreviewList {
                previewShadeView.y = 10
                previewShadeView.width = width
                previewShadeMaskLayer.frame = previewShadeView.bounds
                previewListView.frame = previewShadeView.bounds
                contentView.y = 75
            }else {
                if isShowSelectedView {
                    selectedView.y = 0
                    selectedView.width = width
                    if selectedView.assetCount > 0 {
                        contentView.y = selectedView.frame.maxY + 5
                    }else {
                        contentView.y = height - contentView.height
                    }
                }else {
                    contentView.y = height - contentView.height
                }
            }
        }else {
            if isShowPreviewList {
                previewShadeView.y = 10
                previewShadeView.width = width
                previewShadeMaskLayer.frame = previewShadeView.bounds
                previewListView.frame = previewShadeView.bounds
            }else {
                if isShowSelectedView {
                    selectedView.y = 0
                    selectedView.width = width
                }
            }
        }
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else {
            return
        }
        configColor()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@available(iOS 26.0, *)
extension PhotoToolBarGlassView: PhotoPreviewListViewDataSource {
    func previewListView(_ previewListView: PhotoPreviewListView, thumbnailOnPage page: Int) -> PhotoAsset? {
        if !isShowPreviewList || previewAssets.isEmpty { return nil }
        return previewAssets[page]
    }
    
    func previewListView(_ previewListView: PhotoPreviewListView, thumbnailWidthToHeightOnPage page: Int) -> CGFloat? {
        if !isShowPreviewList || previewAssets.isEmpty { return nil }
        let asset = previewAssets[page]
        guard asset.imageSize.height > 0 else { return nil }
        return asset.imageSize.width / asset.imageSize.height
    }
    
    func previewListView(_ previewListView: PhotoPreviewListView, pageDidChange page: Int, reason: PhotoPreviewListView.PageChangeReason) {
        if previewAssets.isEmpty {
            return
        }
        switch reason {
        case .tapOnPageThumbnail, .scrollingBar:
            allowPreviewDidScroll = false
            previewPage = page
            toolbarDelegate?.photoToolbar(self, previewMoveTo: previewAssets[page])
        case .configuration, .interactivePaging:
            break
        }
    }
    
    public func configPreviewList(_ assets: [PhotoAsset], page: Int) {
        if !isShowPreviewList { return }
        previewAssets = assets
        previewListView.configure(numberOfPages: assets.count, currentPage: page)
    }
    
    public func previewListInsert(_ asset: PhotoAsset, at index: Int) {
        if !isShowPreviewList { return }
        previewAssets.insert(asset, at: index)
        previewListView.insertData(with: [index])
    }
    
    public func previewListRemove(_ assets: [PhotoAsset]) {
        if !isShowPreviewList { return }
        var indexs: [Int] = []
        let tempAssets = previewAssets
        for asset in assets {
            guard let index = tempAssets.firstIndex(of: asset) else {
                continue
            }
            indexs.append(index)
            previewAssets.remove(at: index)
        }
        previewListView.removeData(with: indexs)
    }
    
    public func previewListReload(_ assets: [PhotoAsset]) {
        if !isShowPreviewList { return }
        var indexs: [Int] = []
        for asset in assets {
            guard let index = previewAssets.firstIndex(of: asset) else {
                continue
            }
            indexs.append(index)
        }
        previewListView.reloadData(with: indexs)
    }
    
    public func previewListDidScroll(_ scrollView: UIScrollView) {
        if !isShowPreviewList || previewAssets.isEmpty {
            return
        }
        if !allowPreviewDidScroll {
            allowPreviewDidScroll = true
            return
        }
        let viewWidth = scrollView.width
        let offsetX = scrollView.contentOffset.x
        let page = Int((offsetX + viewWidth / 2) / viewWidth)
        let currentPage = min(previewAssets.count - 1, max(0, page))
        if previewListView.collectionView.isTracking || previewListView.collectionView.isDragging {
            if !scrollView.isTracking && !scrollView.isDragging {
                return
            }else {
                if previewListView.collectionView.isDragging {
                    previewListView.stopScroll(to: currentPage, animated: false)
                    previewListView.finishInteractivePaging()
                    previewPage = currentPage
                    return
                }
            }
        }
        var didChangePage: Bool = false
        if let previewPage {
            let currentOffsetX = viewWidth * CGFloat(previewPage)
            if offsetX <= currentOffsetX - viewWidth || offsetX >= currentOffsetX + viewWidth {
                didChangePage = true
            }
        }else {
            previewPage = currentPage
        }
        guard let previewPage else { return }
        previewListScrollHandler(scrollView, page: previewPage)
        if didChangePage {
            previewListScrollHandler(scrollView, page: previewPage, didChange: true)
            previewListScrollHandler(scrollView, page: currentPage)
            self.previewPage = currentPage
        }
    }
    
    func previewListScrollHandler(_ scrollView: UIScrollView, page: Int, didChange: Bool = false) {
        let offsetX = scrollView.contentOffset.x
        let viewWidth = scrollView.width
        let currentOffsetX = viewWidth * CGFloat(page)
        let scale = abs(currentOffsetX - viewWidth - offsetX) / viewWidth
        let progress0To2 = scale
        let isMovingToNextPage = progress0To2 > 1
        let rawProgress = isMovingToNextPage ? (progress0To2 - 1) : (1 - progress0To2)
        let progress = didChange ? 1 : min(max(rawProgress, 0), 1)
        
        switch previewListView.state {
        case .transitioningInteractively(_, let forwards):
            if progress == 1 {
                previewListView.finishInteractivePaging()
            } else if forwards == isMovingToNextPage {
                previewListView.updatePagingProgress(progress)
            } else {
                previewListView.cancelInteractivePaging()
            }
        case .collapsing, .collapsed, .expanding, .expanded:
            if progress != 0, !didChange {
                previewListView.startInteractivePaging(forwards: isMovingToNextPage)
            }
        }
    }
    
    public func viewWillDisappear(_ viewController: UIViewController) {
        if !isShowPreviewList { return }
        guard let index = previewListView.indexPathForCurrentCenterItem?.item, previewListView.collectionView.isDragging else {
            return
        }
        previewListView.stopScroll(to: index, animated: false)
        previewListView.finishInteractivePaging()
        previewPage = index
    }
}
@available(iOS 26.0, *)
extension PhotoToolBarGlassView {
    
    func configColor() {
        let config = type == .picker ? pickerConfig.photoList.bottomView : pickerConfig.previewView.bottomView
        let isDark = PhotoManager.isDark
        
        if type == .picker {
            if isShowSelectedView {
                selectedView.tickColor = isDark ? config.selectedViewTickDarkColor : config.selectedViewTickColor
            }
        }else if type == .preview {
            #if HXPICKER_ENABLE_EDITOR
            #endif
            if isShowPreviewList {
                previewListView.selectColor = isDark ? config.previewListTickDarkColor : config.previewListTickColor
                previewListView.selectBgColor = isDark ? config.previewListTickBgDarkColor : config.previewListTickBgColor
            }
            if isShowSelectedView {
                selectedView.tickColor = isDark ? config.selectedViewTickDarkColor : config.selectedViewTickColor
            }
        }
        
        if type == .browser {
            if isShowPreviewList {
                previewListView.selectColor = isDark ? config.previewListTickDarkColor : config.previewListTickColor
                previewListView.selectBgColor = isDark ? config.previewListTickBgDarkColor : config.previewListTickBgColor
            }
            if isShowSelectedView {
                selectedView.tickColor = isDark ? config.selectedViewTickDarkColor : config.selectedViewTickColor
            }
        }
    }
}

@available(iOS 26.0, *)
extension PhotoToolBarGlassView {
    
    private func updateFinishButtonTitle(_ photoAssets: [PhotoAsset]) {
        let count = photoAssets.count
        assetCount = count
        let finishTitle: String
        if type == .picker {
            finishTitle = .textPhotoList.bottomView.finishTitle.text
        }else {
            finishTitle = .textPreview.bottomView.finishTitle.text
        }
        if count > 0 {
            finishBtn.isEnabled = true
            if type == .picker {
                previewBtn.isEnabled = true
            }
            finishBtn.title = finishTitle + " (\(count))"
        }else {
            if type == .preview {
                if pickerConfig.maximumSelectedVideoCount == 1 || pickerConfig.selectMode == .single {
                    finishBtn.isEnabled = true
                }else {
                    finishBtn.isEnabled = !pickerConfig.previewView.bottomView.disableFinishButtonWhenNotSelected
                }
            }else {
                finishBtn.isEnabled = !pickerConfig.photoList.bottomView.disableFinishButtonWhenNotSelected
            }
            if type == .picker {
                previewBtn.isEnabled = false
            }
            finishBtn.title = finishTitle
        }
    }
}

@available(iOS 26.0, *)
extension PhotoToolBarGlassView: PhotoPreviewSelectedViewDelegate {
    
    func selectedView(
        _ selectedView: PhotoPreviewSelectedView,
        didSelectItemAt photoAsset: PhotoAsset
    ) {
        toolbarDelegate?.photoToolbar(self, didSelectedAsset: photoAsset)
    }
    
    func selectedView(
        _ selectedView: PhotoPreviewSelectedView,
        moveItemAt fromIndex: Int, toIndex: Int
    ) {
        toolbarDelegate?.photoToolbar(self, didMoveAsset: fromIndex, with: toIndex)
    }
    
    func selectedView(
        _ selectedView: PhotoPreviewSelectedView,
        didDeleteItemAt photoAsset: PhotoAsset
    ) {
        toolbarDelegate?.photoToolbar(self, didDeleteAsset: photoAsset)
    }
}
