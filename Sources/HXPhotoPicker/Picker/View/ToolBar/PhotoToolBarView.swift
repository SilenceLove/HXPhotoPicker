//
//  PhotoToolBar.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/9/14.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit

public class PhotoToolBarView: UIToolbar, PhotoToolBar {
    
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
                    viewHeight += 70
                }
            }
        }else if type == .preview {
            if isShowPreviewList {
                viewHeight += 70
            }else {
                if isShowSelectedView, selectedView.assetCount > 0 {
                    viewHeight += 70
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
    private var editBtn: UIButton!
    #endif
    
    private let pickerConfig: PickerConfiguration
    private let type: PhotoToolBarType
    private var promptView: PhotoPermissionPromptView!
    private var selectedView: PhotoPreviewSelectedView!
    private var previewListView: PhotoPreviewListView!
    private var contentView: UIView!
    private var previewBtn: UIButton!
    private var originalView: UIControl!
    private var originalBox: SelectBoxView!
    private var originalTitleLb: UILabel!
    private var originalLoadingView: UIActivityIndicatorView!
    private var finishBtn: UIButton!
    private var isOriginalLoading: Bool = false
    private var originalobserve: NSKeyValueObservation?
    
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
        
        contentView = UIView(frame: CGRect(x: 0, y: 0, width: width, height: 50 + UIDevice.bottomMargin))
        
        let viewConfig: PickerBottomViewConfiguration
        if type == .picker {
            if pickerConfig.selectMode != .single {
                addSubview(contentView)
            }
            viewConfig = pickerConfig.photoList.bottomView
            if isShowPrompt {
                promptView = PhotoPermissionPromptView(config: viewConfig)
                addSubview(promptView)
            }
            if isShowSelectedView {
                initSelectedView()
            }
            previewBtn = UIButton(type: .custom)
            previewBtn.setTitle(.textPhotoList.bottomView.previewTitle.text, for: .normal)
            previewBtn.titleLabel?.font = .textPhotoList.bottomView.previewTitleFont
            previewBtn.isEnabled = false
            previewBtn.addTarget(self, action: #selector(didPreviewButtonClick), for: .touchUpInside)
            previewBtn.height = 50
            previewBtn.isHidden = viewConfig.isHiddenPreviewButton
            let previewWidth: CGFloat = previewBtn.currentTitle!.localized.width(
                ofFont: previewBtn.titleLabel!.font,
                maxHeight: 50
            )
            previewBtn.width = previewWidth
            contentView.addSubview(previewBtn)
        }else if type == .preview {
            addSubview(contentView)
            viewConfig = pickerConfig.previewView.bottomView
            if isShowPreviewList {
                previewListView = PhotoPreviewListView(frame: .init(x: 0, y: 0, width: width, height: 55))
                previewListView.dataSource = self
                addSubview(previewListView)
            }else {
                if isShowSelectedView {
                    initSelectedView()
                }
            }
            #if HXPICKER_ENABLE_EDITOR
            editBtn = UIButton(type: .custom)
            editBtn.setTitle(.textPreview.bottomView.editTitle.text, for: .normal)
            editBtn.titleLabel?.font = .textPreview.bottomView.editTitleFont
            editBtn.addTarget(self, action: #selector(didEditBtnButtonClick), for: .touchUpInside)
            editBtn.height = 50
            editBtn.isHidden = viewConfig.isHiddenEditButton
            let editWidth: CGFloat = editBtn.currentTitle!.localized.width(
                ofFont: editBtn.titleLabel!.font,
                maxHeight: 50
            )
            editBtn.width = editWidth
            contentView.addSubview(editBtn)
            #endif
        }else {
            viewConfig = pickerConfig.previewView.bottomView
            if isShowPreviewList {
                previewListView = PhotoPreviewListView(frame: .init(x: 0, y: 0, width: width, height: 55))
                previewListView.dataSource = self
                addSubview(previewListView)
            }else {
                if isShowSelectedView {
                    initSelectedView()
                    selectedView.allowDrop = false
                }
            }
        }
        
        if type != .browser {
            originalView = UIControl()
            originalView.isHidden = viewConfig.isHiddenOriginalButton
            contentView.addSubview(originalView)
            
            originalTitleLb = UILabel()
            if type == .picker {
                originalTitleLb.text = .textPhotoList.bottomView.originalTitle.text
                originalTitleLb.font = .textPhotoList.bottomView.originalTitleFont
            }else {
                originalTitleLb.text = .textPreview.bottomView.originalTitle.text
                originalTitleLb.font = .textPreview.bottomView.originalTitleFont
            }
            originalTitleLb.lineBreakMode = .byTruncatingHead
            originalView.addSubview(originalTitleLb)
            
            let boxConfig: SelectBoxConfiguration
            if type == .picker {
                boxConfig = config.photoList.bottomView.originalSelectBox
            }else {
                boxConfig = config.previewView.bottomView.originalSelectBox
            }
            originalBox = SelectBoxView(boxConfig, frame: CGRect(x: 0, y: 0, width: 17, height: 17))
            originalBox.backgroundColor = .clear
            originalBox.isUserInteractionEnabled = false
            originalView.addSubview(originalBox)
            
            originalLoadingView = UIActivityIndicatorView(style: .white)
            originalLoadingView.hidesWhenStopped = true
            originalView.addSubview(originalLoadingView)
            
            originalView.addTarget(self, action: #selector(didOriginalButtonClick), for: .touchUpInside)
            originalobserve = originalView.observe(\.isHighlighted, options: [.new, .old]) { [weak self] control, value in
                guard let self = self else { return }
                self.originalBox.isHighlighted = control.isHighlighted
                let config = self.type == .picker ? self.pickerConfig.photoList.bottomView : self.pickerConfig.previewView.bottomView
                let textColor = PhotoManager.isDark ? config.originalButtonTitleDarkColor : config.originalButtonTitleColor
                self.originalTitleLb.textColor = control.isHighlighted ? textColor.withAlphaComponent(0.4) : textColor
            }
            
            finishBtn = UIButton(type: .custom)
            if type == .picker {
                finishBtn.setTitle(.textPhotoList.bottomView.finishTitle.text, for: .normal)
                finishBtn.titleLabel?.font = .textPhotoList.bottomView.finishTitleFont
            }else {
                finishBtn.setTitle(.textPreview.bottomView.finishTitle.text, for: .normal)
                finishBtn.titleLabel?.font = .textPreview.bottomView.finishTitleFont
            }
            finishBtn.layer.cornerRadius = 3
            finishBtn.layer.masksToBounds = true
            if config.selectMode == .multiple {
                finishBtn.isEnabled = false
            }
            finishBtn.addTarget(self, action: #selector(didFinishButtonClick), for: .touchUpInside)
            contentView.addSubview(finishBtn)
        }
        layoutSubviews()
        bringSubviewToFront(contentView)
        if selectedView != nil {
            bringSubviewToFront(selectedView)
        }
        if previewListView != nil {
            bringSubviewToFront(previewListView)
        }
        if promptView != nil {
            bringSubviewToFront(promptView)
        }
        configColor()
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
        originalBox.isSelected = isSelected
    }
    
    public func requestOriginalAssetBtyes() {
        if type == .browser { return }
        if !originalBox.isSelected {
            return
        }
        if isCanLoadOriginal {
            startOriginalLoading()
        }
        toolbarDelegate?.photoToolbar(self, didOriginalClick: true)
    }
    
    public func originalAssetBytes(_ bytes: Int, bytesString: String) {
        if !originalBox.isSelected || !isCanLoadOriginal {
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
            self.promptView.alpha = 0
        }
    }
    
    public func removeSelectedAssets(_ photoAssets: [PhotoAsset]) {
        if !isShowSelectedView { return }
        selectedView.removePhotoAssets(photoAssets) { [weak self] in
            guard let self, self.isShowPrompt else {
                return
            }
            self.promptView.alpha = 1
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
                promptView.alpha = 0
            }else if photoAssets.isEmpty {
                promptView.alpha = 1
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
        originalBox.isSelected = !originalBox.isSelected
        originalBox.layer.removeAnimation(forKey: "SelectControlAnimation")
        let keyAnimation = CAKeyframeAnimation.init(keyPath: "transform.scale")
        keyAnimation.duration = 0.3
        keyAnimation.values = [1.2, 0.8, 1.1, 0.9, 1.0]
        originalBox.layer.add(keyAnimation, forKey: "SelectControlAnimation")
        
        let isSelected = originalBox.isSelected
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
        isOriginalLoading = true
        if type == .picker {
            originalTitleLb.text = .textPhotoList.bottomView.originalTitle.text
        }else {
            originalTitleLb.text = .textPreview.bottomView.originalTitle.text
        }
        originalLoadingView.startAnimating()
        updateOriginalViewFrame()
    }
    
    private func stopOriginalLoading(bytes: Int, bytesString: String) {
        isOriginalLoading = false
        originalLoadingView.stopAnimating()
        let originalTitle: String
        if type == .picker {
            originalTitle = .textPhotoList.bottomView.originalTitle.text
        }else {
            originalTitle = .textPreview.bottomView.originalTitle.text
        }
        if bytes > 0 {
            originalTitleLb.text = originalTitle + " (" + bytesString + ")"
        }else {
            originalTitleLb.text = originalTitle
        }
        updateOriginalViewFrame()
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
        contentView.width = width
        contentView.height = 50 + UIDevice.bottomMargin
        let leftMargin = self.leftMargin
        if type == .picker {
            if isShowPrompt {
                if pickerConfig.selectMode != .single {
                    promptView.frame = .init(x: 0, y: 0, width: width, height: 70)
                }else {
                    promptView.frame = .init(x: 0, y: 0, width: width, height: 55)
                }
                contentView.y = promptView.frame.maxY
            }
            if isShowSelectedView {
                selectedView.y = 0
                selectedView.width = width
                if !isShowPrompt {
                    if selectedView.assetCount > 0 {
                        contentView.y = selectedView.frame.maxY
                    }else {
                        contentView.y = height - contentView.height
                    }
                }
            }else if !isShowPrompt {
                contentView.y = height - contentView.height
            }
            if leftMargin > 0 {
                previewBtn.hxPicker_x = leftMargin
            }else {
                previewBtn.hxPicker_x = 12
            }
            updateFinishButtonFrame()
            updateOriginalViewFrame()
        }else if type == .preview {
            #if HXPICKER_ENABLE_EDITOR
            if UIDevice.leftMargin > 0 {
                editBtn.hxPicker_x = UIDevice.leftMargin
            }else {
                editBtn.hxPicker_x = 12
            }
            #endif
            if isShowPreviewList {
                previewListView.y = 10
                previewListView.width = width
                contentView.y = 70
            }else {
                if isShowSelectedView {
                    selectedView.y = 0
                    selectedView.width = width
                    if selectedView.assetCount > 0 {
                        contentView.y = selectedView.frame.maxY
                    }else {
                        contentView.y = height - contentView.height
                    }
                }else {
                    contentView.y = height - contentView.height
                }
            }
            updateFinishButtonFrame()
            updateOriginalViewFrame()
        }else {
            if isShowPreviewList {
                previewListView.y = 10
                previewListView.width = width
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
        guard #available(iOS 13.0, *),
              traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else {
            return
        }
        configColor()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        originalobserve = nil
    }
}

extension PhotoToolBarView: PhotoPreviewListViewDataSource {
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
extension PhotoToolBarView {
    
    func configColor() {
        let config = type == .picker ? pickerConfig.photoList.bottomView : pickerConfig.previewView.bottomView
        let isDark = PhotoManager.isDark
        backgroundColor = isDark ? config.backgroundDarkColor : config.backgroundColor
        barTintColor = isDark ? config.barTintDarkColor : config.barTintColor
        barStyle = isDark ? config.barDarkStyle : config.barStyle
        if type == .picker {
            let previewTitleColor = config.previewButtonTitleColor
            let previewTitleDarkColor = config.previewButtonTitleDarkColor
            previewBtn.setTitleColor(
                isDark ? previewTitleDarkColor : previewTitleColor,
                for: .normal
            )
            previewBtn.setTitleColor(
                isDark ? previewTitleDarkColor.withAlphaComponent(0.4) : previewTitleColor.withAlphaComponent(0.4),
                for: .highlighted
            )
            if isDark {
                if config.previewButtonDisableTitleDarkColor != nil {
                    previewBtn.setTitleColor(config.previewButtonDisableTitleDarkColor, for: .disabled)
                }else {
                    previewBtn.setTitleColor(previewTitleDarkColor.withAlphaComponent(0.6), for: .disabled)
                }
            }else {
                if config.previewButtonDisableTitleColor != nil {
                    previewBtn.setTitleColor(config.previewButtonDisableTitleColor, for: .disabled)
                }else {
                    previewBtn.setTitleColor(previewTitleColor.withAlphaComponent(0.6), for: .disabled)
                }
            }
            if isShowSelectedView {
                selectedView.tickColor = isDark ? config.selectedViewTickDarkColor : config.selectedViewTickColor
            }
        }else if type == .preview {
            #if HXPICKER_ENABLE_EDITOR
            let editTitleColor = config.editButtonTitleColor
            let editTitleDarkColor = config.editButtonTitleDarkColor
            editBtn.setTitleColor(isDark ? editTitleDarkColor : editTitleColor, for: .normal)
            editBtn.setTitleColor(isDark ? editTitleDarkColor.withAlphaComponent(0.4) : editTitleColor.withAlphaComponent(0.4), for: .highlighted)
            if isDark {
                if config.editButtonDisableTitleDarkColor != nil {
                    editBtn.setTitleColor(config.editButtonDisableTitleDarkColor, for: .disabled)
                }else {
                    editBtn.setTitleColor(editTitleDarkColor.withAlphaComponent(0.6), for: .disabled)
                }
            }else {
                if config.editButtonDisableTitleColor != nil {
                    editBtn.setTitleColor(config.editButtonDisableTitleColor, for: .disabled)
                }else {
                    editBtn.setTitleColor(editTitleColor.withAlphaComponent(0.6), for: .disabled)
                }
            }
            #endif
            if isShowPreviewList {
                previewListView.selectColor = isDark ? config.previewListTickDarkColor : config.previewListTickColor
                previewListView.selectBgColor = isDark ? config.previewListTickBgDarkColor : config.previewListTickBgColor
            }
            if isShowSelectedView {
                selectedView.tickColor = isDark ? config.selectedViewTickDarkColor : config.selectedViewTickColor
            }
        }
        
        if type != .browser {
            originalLoadingView.style = isDark ? config.originalLoadingDarkStyle : config.originalLoadingStyle
            originalTitleLb.textColor = isDark ? config.originalButtonTitleDarkColor : config.originalButtonTitleColor
            
            let finishBtnBackgroundColor = isDark ?
                config.finishButtonDarkBackgroundColor :
                config.finishButtonBackgroundColor
            finishBtn.setTitleColor(
                isDark ?
                    config.finishButtonTitleDarkColor :
                    config.finishButtonTitleColor,
                for: .normal
            )
            finishBtn.setTitleColor(
                isDark ?
                    config.finishButtonDisableTitleDarkColor :
                    config.finishButtonDisableTitleColor,
                for: .disabled
            )
            finishBtn.setBackgroundImage(
                UIImage.image(
                    for: finishBtnBackgroundColor,
                    havingSize: CGSize.zero
                ),
                for: .normal
            )
            finishBtn.setBackgroundImage(
                UIImage.image(
                    for: isDark ?
                        config.finishButtonDisableDarkBackgroundColor :
                        config.finishButtonDisableBackgroundColor,
                    havingSize: CGSize.zero
                ),
                for: .disabled
            )
        }else {
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

extension PhotoToolBarView {
    
    func updateOriginalViewFrame() {
        updateOriginalSubviewFrame()
        if isOriginalLoading {
            originalView.frame = CGRect(x: 0, y: 0, width: originalLoadingView.frame.maxX, height: 50)
        }else {
            originalView.frame = CGRect(x: 0, y: 0, width: originalTitleLb.frame.maxX, height: 50)
        }
        originalView.centerX = width / 2
        if PhotoManager.isRTL {
            return
        }
        let originalMinX: CGFloat
        if type == .picker {
            originalMinX = previewBtn.frame.maxX + 2
        }else {
            #if HXPICKER_ENABLE_EDITOR
            originalMinX = editBtn.frame.maxX + 2
            #else
            originalMinX = 10
            #endif
        }
        if originalView.frame.maxX > finishBtn.x || originalView.x < originalMinX {
            originalView.x = finishBtn.x - originalView.width
            if originalView.x < originalMinX {
                originalView.x = originalMinX
                originalTitleLb.width = finishBtn.x - originalMinX - 5 - originalBox.width
            }
        }
    }
    private func updateOriginalSubviewFrame() {
        originalTitleLb.frame = CGRect(
            x: originalBox.frame.maxX + 5,
            y: 0,
            width: originalTitleLb.text!.width(
                ofFont: originalTitleLb.font,
                maxHeight: 50
            ),
            height: 50
        )
        if !PhotoManager.isRTL {
            let leftMargin: CGFloat
            if type == .picker {
                leftMargin = previewBtn.frame.maxX
            }else {
                #if HXPICKER_ENABLE_EDITOR
                leftMargin = editBtn.frame.maxX
                #else
                leftMargin = 10
                #endif
            }
            if originalTitleLb.width > width - leftMargin - finishBtn.width - 12 {
                originalTitleLb.width = width - leftMargin - finishBtn.width - 12
            }
        }
        originalBox.centerY = originalTitleLb.height * 0.5
        originalLoadingView.centerY = originalView.height * 0.5
        originalLoadingView.x = originalTitleLb.frame.maxX + 3
    }
    
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
            finishBtn.setTitle(
                finishTitle + " (\(count))",
                for: .normal
            )
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
            finishBtn.setTitle(finishTitle, for: .normal)
        }
        updateFinishButtonFrame()
    }
    
    private func updateFinishButtonFrame() {
        var finishWidth: CGFloat = finishBtn.currentTitle!.localized.width(
            ofFont: finishBtn.titleLabel!.font,
            maxHeight: 50
        ) + 20
        if finishWidth < 60 {
            finishWidth = 60
        }
        finishBtn.size = .init(width: finishWidth, height: 33)
        if UIDevice.rightMargin > 0 {
            finishBtn.hxPicker_x = width - UIDevice.rightMargin - finishWidth
        }else {
            finishBtn.hxPicker_x = width - finishWidth - 12
        }
        finishBtn.centerY = 25
    }
}

extension PhotoToolBarView: PhotoPreviewSelectedViewDelegate {
    
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
