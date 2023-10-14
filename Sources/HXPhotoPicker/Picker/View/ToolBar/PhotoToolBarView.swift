//
//  PhotoToolBar.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/9/14.
//  Copyright © 2023 洪欣. All rights reserved.
//

import UIKit

public class PhotoToolBarView: UIToolbar, PhotoToolBar {
    
    public var previewHandler: (() -> Void)?
    public var originalHandler: ((Bool) -> Void)?
    public var selectedAssetHandler: ((PhotoAsset) -> Void)?
    public var moveAssetHandler: ((Int, Int) -> Void)?
    public var finishHandler: (() -> Void)?
    #if HXPICKER_ENABLE_EDITOR
    public var editHandler: (() -> Void)?
    private var editBtn: UIButton!
    #endif
    
    private let pickerConfig: PickerConfiguration
    private let type: PhotoToolBarType
    private var promptView: PhotoPermissionPromptView!
    private var selectedView: PhotoPreviewSelectedView!
    private var contentView: UIView!
    private var previewBtn: UIButton!
    private var originalView: UIView!
    private var originalBox: SelectBoxView!
    private var originalTitleLb: UILabel!
    private var originalLoadingView: UIActivityIndicatorView!
    private var finishBtn: UIButton!
    private var isOriginalLoading: Bool = false
    
    private var isShowPrompt: Bool {
        type == .picker &&
        AssetManager.authorizationStatusIsLimited() &&
        pickerConfig.photoList.bottomView.isShowPrompt &&
        pickerConfig.allowLoadPhotoLibrary
    }
    private var isShowSelectedView: Bool {
        (type == .preview &&
         pickerConfig.previewView.bottomView.isShowSelectedView &&
         pickerConfig.selectMode == .multiple) ||
        type == .browser
    }
    
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
            previewBtn = UIButton(type: .custom)
            previewBtn.setTitle("预览".localized, for: .normal)
            previewBtn.titleLabel?.font = .systemFont(ofSize: 17)
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
            if isShowSelectedView {
                initSelectedView()
            }
            
            #if HXPICKER_ENABLE_EDITOR
            editBtn = UIButton(type: .custom)
            editBtn.setTitle("编辑".localized, for: .normal)
            editBtn.titleLabel?.font = .systemFont(ofSize: 17)
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
            initSelectedView()
            selectedView.allowDrop = false
        }
        
        if type != .browser {
            originalView = UIView()
            originalView.isHidden = viewConfig.isHiddenOriginalButton
            contentView.addSubview(originalView)
            
            originalTitleLb = UILabel()
            originalTitleLb.text = "原图".localized
            originalTitleLb.font = .systemFont(ofSize: 17)
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
            originalView.addSubview(originalBox)
            
            originalLoadingView = UIActivityIndicatorView(style: .white)
            originalLoadingView.hidesWhenStopped = true
            originalView.addSubview(originalLoadingView)
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(didOriginalButtonClick))
            originalView.addGestureRecognizer(tap)
            
            finishBtn = UIButton(type: .custom)
            finishBtn.setTitle("完成".localized, for: .normal)
            finishBtn.titleLabel?.font = .mediumPingFang(ofSize: 16)
            finishBtn.layer.cornerRadius = 3
            finishBtn.layer.masksToBounds = true
            finishBtn.isEnabled = false
            finishBtn.addTarget(self, action: #selector(didFinishButtonClick), for: .touchUpInside)
            contentView.addSubview(finishBtn)
        }
        
        configColor()
    }
    
    private func initSelectedView() {
        let viewConfig = pickerConfig.previewView.bottomView
        selectedView = PhotoPreviewSelectedView(frame: CGRect(x: 0, y: 0, width: width, height: 70))
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
    
    public func toolbarHeight() -> CGFloat {
        if type == .browser {
            return 70 + UIDevice.bottomMargin
        }
        if pickerConfig.selectMode == .single, isShowPrompt {
            return 0
        }
        return 50 + UIDevice.bottomMargin
    }
    
    public func viewHeight() -> CGFloat {
        if pickerConfig.selectMode == .single, isShowPrompt, type != .browser {
            return 55 + UIDevice.bottomMargin
        }
        var viewHeight: CGFloat = toolbarHeight()
        if type == .picker {
            if isShowPrompt {
                viewHeight += 70
            }
        }else if type == .preview {
            if isShowSelectedView, selectedView.assetCount > 0 {
                viewHeight += 70
            }
        }
        return viewHeight
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
        originalHandler?(true)
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
        selectedView.insertPhotoAsset(photoAsset: photoAsset)
    }
    
    public func removeSelectedAssets(_ photoAssets: [PhotoAsset]) {
        if !isShowSelectedView { return }
        selectedView.removePhotoAssets(photoAssets)
    }
    
    public func reloadSelectedAsset(_ photoAsset: PhotoAsset) {
        if !isShowSelectedView { return }
        selectedView.reloadData(photoAsset: photoAsset)
    }
    
    public func updateSelectedAssets(_ photoAssets: [PhotoAsset]) {
        if !isShowSelectedView { return }
        selectedView.reloadData(photoAssets: photoAssets)
    }
    
    public func selectedViewScrollTo(_ photoAsset: PhotoAsset?, animated: Bool) {
        if !isShowSelectedView { return }
        selectedView.scrollTo(photoAsset: photoAsset, isAnimated: animated)
    }
    
    public func deviceOrientationDidChanged() {
        if !isShowSelectedView { return }
        selectedView.reloadSectionInset()
    }
    
    @objc
    private func didPreviewButtonClick() {
        previewHandler?()
    }
    
    #if HXPICKER_ENABLE_EDITOR
    @objc
    private func didEditBtnButtonClick() {
        editHandler?()
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
        originalHandler?(isSelected)
    }
    
    private func startOriginalLoading() {
        isOriginalLoading = true
        originalTitleLb.text = "原图".localized
        originalLoadingView.startAnimating()
        updateOriginalViewFrame()
    }
    
    private func stopOriginalLoading(bytes: Int, bytesString: String) {
        isOriginalLoading = false
        originalLoadingView.stopAnimating()
        if bytes > 0 {
            originalTitleLb.text = "原图".localized + " (" + bytesString + ")"
        }else {
            originalTitleLb.text = "原图".localized
        }
        updateOriginalViewFrame()
    }
    
    @objc
    private func didFinishButtonClick() {
        finishHandler?()
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
        if type == .picker {
            if isShowPrompt {
                if pickerConfig.selectMode != .single {
                    promptView.frame = .init(x: 0, y: 0, width: width, height: 70)
                }else {
                    promptView.frame = .init(x: 0, y: 0, width: width, height: 55)
                }
                contentView.y = promptView.frame.maxY
            }else {
                contentView.y = height - contentView.height
            }
            previewBtn.x = 12 + leftMargin
            updateFinishButtonFrame()
            updateOriginalViewFrame()
        }else if type == .preview {
            #if HXPICKER_ENABLE_EDITOR
            editBtn.x = 12 + UIDevice.leftMargin
            #endif
            if isShowSelectedView {
                selectedView.width = width
                if selectedView.assetCount > 0 {
                    contentView.y = selectedView.frame.maxY
                }else {
                    contentView.y = height - contentView.height
                }
            }else {
                contentView.y = height - contentView.height
            }
            updateFinishButtonFrame()
            updateOriginalViewFrame()
        }else {
            selectedView.width = width
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
}

extension PhotoToolBarView {
    
    func configColor() {
        let config = type == .picker ? pickerConfig.photoList.bottomView : pickerConfig.previewView.bottomView
        let isDark = PhotoManager.isDark
        backgroundColor = isDark ? config.backgroundDarkColor : config.backgroundColor
        barTintColor = isDark ? config.barTintDarkColor : config.barTintColor
        barStyle = isDark ? config.barDarkStyle : config.barStyle
        if type == .picker {
            previewBtn.setTitleColor(
                isDark ?
                    config.previewButtonTitleDarkColor :
                    config.previewButtonTitleColor,
                for: .normal
            )
            if isDark {
                if config.previewButtonDisableTitleDarkColor != nil {
                    previewBtn.setTitleColor(config.previewButtonDisableTitleDarkColor, for: .disabled)
                }else {
                    previewBtn.setTitleColor(config.previewButtonTitleDarkColor.withAlphaComponent(0.6), for: .disabled)
                }
            }else {
                if config.previewButtonDisableTitleColor != nil {
                    previewBtn.setTitleColor(config.previewButtonDisableTitleColor, for: .disabled)
                }else {
                    previewBtn.setTitleColor(config.previewButtonTitleColor.withAlphaComponent(0.6), for: .disabled)
                }
            }
        }else if type == .preview {
            #if HXPICKER_ENABLE_EDITOR
            editBtn.setTitleColor(isDark ? config.editButtonTitleDarkColor : config.editButtonTitleColor, for: .normal)
            if isDark {
                if config.editButtonDisableTitleDarkColor != nil {
                    editBtn.setTitleColor(config.editButtonDisableTitleDarkColor, for: .disabled)
                }else {
                    editBtn.setTitleColor(config.editButtonTitleDarkColor.withAlphaComponent(0.6), for: .disabled)
                }
            }else {
                if config.editButtonDisableTitleColor != nil {
                    editBtn.setTitleColor(config.editButtonDisableTitleColor, for: .disabled)
                }else {
                    editBtn.setTitleColor(config.editButtonTitleColor.withAlphaComponent(0.6), for: .disabled)
                }
            }
            #endif
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
            selectedView.tickColor = isDark ? config.selectedViewTickDarkColor : config.selectedViewTickColor
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
        originalBox.centerY = originalTitleLb.height * 0.5
        originalLoadingView.centerY = originalView.height * 0.5
        originalLoadingView.x = originalTitleLb.frame.maxX + 3
    }
    
    private func updateFinishButtonTitle(_ photoAssets: [PhotoAsset]) {
        let count = photoAssets.count
        assetCount = count
        if count > 0 {
            finishBtn.isEnabled = true
            if type == .picker {
                previewBtn.isEnabled = true
            }
            finishBtn.setTitle(
                "完成".localized + " (\(count))",
                for: .normal
            )
        }else {
            if type == .preview {
                if pickerConfig.maximumSelectedVideoCount == 1 {
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
            finishBtn.setTitle("完成".localized, for: .normal)
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
        finishBtn.frame = CGRect(
            x: width - UIDevice.rightMargin - finishWidth - 12,
            y: 0,
            width: finishWidth,
            height: 33
        )
        finishBtn.centerY = 25
    }
}

extension PhotoToolBarView: PhotoPreviewSelectedViewDelegate {
    
    func selectedView(
        _ selectedView: PhotoPreviewSelectedView,
        didSelectItemAt photoAsset: PhotoAsset
    ) {
        selectedAssetHandler?(photoAsset)
    }
    
    func selectedView(
        _ selectedView: PhotoPreviewSelectedView,
        moveItemAt fromIndex: Int, toIndex: Int
    ) {
        moveAssetHandler?(fromIndex, toIndex)
    }
}
