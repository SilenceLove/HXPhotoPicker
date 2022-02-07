//
//  PhotoPickerBottomView.swift
//  HXPHPickerExample
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

protocol PhotoPickerBottomViewDelegate: AnyObject {
    func bottomView(didPreviewButtonClick bottomView: PhotoPickerBottomView)
    func bottomView(didEditButtonClick bottomView: PhotoPickerBottomView)
    func bottomView(didFinishButtonClick bottomView: PhotoPickerBottomView)
    func bottomView(_ bottomView: PhotoPickerBottomView, didOriginalButtonClick isOriginal: Bool)
    func bottomView(_ bottomView: PhotoPickerBottomView, didSelectedItemAt photoAsset: PhotoAsset)
}

extension PhotoPickerBottomViewDelegate {
    func bottomView(didPreviewButtonClick bottomView: PhotoPickerBottomView) {}
    func bottomView(didEditButtonClick bottomView: PhotoPickerBottomView) {}
    func bottomView(didFinishButtonClick bottomView: PhotoPickerBottomView) {}
    func bottomView(_ bottomView: PhotoPickerBottomView, didOriginalButtonClick isOriginal: Bool) {}
    func bottomView(_ bottomView: PhotoPickerBottomView, didSelectedItemAt photoAsset: PhotoAsset) {}
}

class PhotoPickerBottomView: UIToolbar, PhotoPreviewSelectedViewDelegate {
    enum SourceType {
        case picker
        case preview
        case browser
    }
    weak var hx_delegate: PhotoPickerBottomViewDelegate?
    
    let config: PickerBottomViewConfiguration
    let sourceType: SourceType
    let allowLoadPhotoLibrary: Bool
    let isMultipleSelect: Bool
    
    init(
        config: PickerBottomViewConfiguration,
        allowLoadPhotoLibrary: Bool,
        isMultipleSelect: Bool,
        sourceType: SourceType) {
        self.sourceType = sourceType
        self.allowLoadPhotoLibrary = allowLoadPhotoLibrary
        self.config = config
        self.isMultipleSelect = isMultipleSelect
        super.init(frame: CGRect.zero)
        layoutSubviews()
        if config.showPrompt &&
            AssetManager.authorizationStatusIsLimited() &&
            allowLoadPhotoLibrary &&
            sourceType == .picker {
            addSubview(promptView)
        }
        if sourceType == .browser {
            if config.showSelectedView {
                addSubview(selectedView)
            }
            #if HXPICKER_ENABLE_EDITOR
            if !config.editButtonHidden {
                addSubview(editBtn)
            }
            #endif
        }else {
            addSubview(contentView)
            if config.showSelectedView && isMultipleSelect {
                addSubview(selectedView)
            }
        }
        configColor()
        isTranslucent = config.isTranslucent
    }
    
    convenience init(
        config: PickerBottomViewConfiguration,
        allowLoadPhotoLibrary: Bool) {
        self.init(
            config: config,
            allowLoadPhotoLibrary: allowLoadPhotoLibrary,
            isMultipleSelect: true,
            sourceType: .picker
        )
    }
    
    lazy var selectedView: PhotoPreviewSelectedView = {
        let selectedView = PhotoPreviewSelectedView.init(frame: CGRect(x: 0, y: 0, width: width, height: 70))
        if let customSelectedViewCellClass = config.customSelectedViewCellClass {
            selectedView.collectionView.register(
                customSelectedViewCellClass,
                forCellWithReuseIdentifier:
                    NSStringFromClass(PhotoPreviewSelectedViewCell.self)
            )
        }else {
            selectedView.collectionView.register(
                PhotoPreviewSelectedViewCell.self,
                forCellWithReuseIdentifier:
                    NSStringFromClass(PhotoPreviewSelectedViewCell.self)
            )
        }
        selectedView.delegate = self
        selectedView.tickColor = config.selectedViewTickColor
        return selectedView
    }()
    
    lazy var promptView: UIView = {
        let promptView = UIView.init(frame: CGRect(x: 0, y: 0, width: width, height: 70))
        promptView.addSubview(promptIcon)
        promptView.addSubview(promptLb)
        promptView.addSubview(promptArrow)
        promptView.addGestureRecognizer(
            UITapGestureRecognizer(
                target: self,
                action: #selector(didPromptViewClick))
        )
        return promptView
    }()
    @objc func didPromptViewClick() {
        PhotoTools.openSettingsURL()
    }
    lazy var promptLb: UILabel = {
        let promptLb = UILabel.init(frame: CGRect(x: 0, y: 0, width: 0, height: 60))
        promptLb.text = "无法访问相册中所有照片，\n请允许访问「照片」中的「所有照片」".localized
        promptLb.font = UIFont.systemFont(ofSize: 15)
        promptLb.numberOfLines = 0
        promptLb.adjustsFontSizeToFitWidth = true
        return promptLb
    }()
    lazy var promptIcon: UIImageView = {
        let image = UIImage.image(for: "hx_picker_photolist_bottom_prompt")?.withRenderingMode(.alwaysTemplate)
        let promptIcon = UIImageView.init(image: image)
        promptIcon.size = promptIcon.image?.size ?? CGSize.zero
        return promptIcon
    }()
    lazy var promptArrow: UIImageView = {
        let image = UIImage.image(for: "hx_picker_photolist_bottom_prompt_arrow")?.withRenderingMode(.alwaysTemplate)
        let promptArrow = UIImageView.init(image: image)
        promptArrow.size = promptArrow.image?.size ?? CGSize.zero
        return promptArrow
    }()
    
    lazy var contentView: UIView = {
        let contentView = UIView.init(frame: CGRect(x: 0, y: 0, width: width, height: 50 + UIDevice.bottomMargin))
        contentView.addSubview(previewBtn)
        #if HXPICKER_ENABLE_EDITOR
        contentView.addSubview(editBtn)
        #endif
        contentView.addSubview(originalBtn)
        contentView.addSubview(finishBtn)
        return contentView
    }()
    
    lazy var previewBtn: UIButton = {
        let previewBtn = UIButton.init(type: .custom)
        previewBtn.setTitle("预览".localized, for: .normal)
        previewBtn.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        previewBtn.isEnabled = false
        previewBtn.addTarget(self, action: #selector(didPreviewButtonClick(button:)), for: .touchUpInside)
        previewBtn.isHidden = config.previewButtonHidden
        previewBtn.height = 50
        let previewWidth: CGFloat = previewBtn.currentTitle!.localized.width(
            ofFont: previewBtn.titleLabel!.font,
            maxHeight: 50
        )
        previewBtn.width = previewWidth
        return previewBtn
    }()
    
    @objc func didPreviewButtonClick(button: UIButton) {
        hx_delegate?.bottomView(didPreviewButtonClick: self)
    }
    
    #if HXPICKER_ENABLE_EDITOR
    lazy var editBtn: UIButton = {
        let editBtn = UIButton.init(type: .custom)
        editBtn.setTitle("编辑".localized, for: .normal)
        editBtn.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        editBtn.addTarget(self, action: #selector(didEditBtnButtonClick(button:)), for: .touchUpInside)
        editBtn.isHidden = config.editButtonHidden
        editBtn.height = 50
        let editWidth: CGFloat = editBtn.currentTitle!.localized.width(
            ofFont: editBtn.titleLabel!.font,
            maxHeight: 50
        )
        editBtn.width = editWidth
        return editBtn
    }()
    
    @objc func didEditBtnButtonClick(button: UIButton) {
        hx_delegate?.bottomView(didEditButtonClick: self)
    }
    #endif
    
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
        viewController?.pickerController?.isOriginal = boxControl.isSelected
        hx_delegate?.bottomView(self, didOriginalButtonClick: boxControl.isSelected)
        boxControl.layer.removeAnimation(forKey: "SelectControlAnimation")
        let keyAnimation = CAKeyframeAnimation.init(keyPath: "transform.scale")
        keyAnimation.duration = 0.3
        keyAnimation.values = [1.2, 0.8, 1.1, 0.9, 1.0]
        boxControl.layer.add(keyAnimation, forKey: "SelectControlAnimation")
    }
    func requestAssetBytes() {
        if sourceType == .browser {
           return
        }
        if !config.showOriginalFileSize || !isMultipleSelect {
            return
        }
        if !boxControl.isSelected {
            cancelRequestAssetFileSize()
            return
        }
        if let pickerController = viewController?.pickerController {
            if pickerController.selectedAssetArray.isEmpty {
                cancelRequestAssetFileSize()
                return
            }
            originalLoadingDelayTimer?.invalidate()
            let timer = Timer(
                timeInterval: 0.1,
                target: self,
                selector: #selector(showOriginalLoading(timer:)),
                userInfo: nil,
                repeats: false
            )
            RunLoop.main.add(timer, forMode: .common)
            originalLoadingDelayTimer = timer
            pickerController.requestSelectedAssetFileSize(
                isPreview: sourceType == .preview
            ) { [weak self] (bytes, bytesString) in
                self?.originalLoadingDelayTimer?.invalidate()
                self?.originalLoadingDelayTimer = nil
                self?.originalLoadingView.stopAnimating()
                self?.showOriginalLoadingView = false
                if bytes > 0 {
                    self?.originalTitleLb.text = "原图".localized + " (" + bytesString + ")"
                }else {
                    self?.originalTitleLb.text = "原图".localized
                }
                self?.updateOriginalButtonFrame()
            }
        }
    }
    @objc func showOriginalLoading(timer: Timer) {
        originalTitleLb.text = "原图".localized
        showOriginalLoadingView = true
        originalLoadingView.startAnimating()
        updateOriginalButtonFrame()
        originalLoadingDelayTimer = nil
    }
    func cancelRequestAssetFileSize() {
        if sourceType == .browser {
           return
        }
        if !config.showOriginalFileSize || !isMultipleSelect {
            return
        }
        originalLoadingDelayTimer?.invalidate()
        originalLoadingDelayTimer = nil
        if let pickerController = viewController?.pickerController {
            pickerController.cancelRequestAssetFileSize(isPreview: sourceType == .preview)
        }
        showOriginalLoadingView = false
        originalLoadingView.stopAnimating()
        originalTitleLb.text = "原图".localized
        updateOriginalButtonFrame()
    }
    lazy var originalTitleLb: UILabel = {
        let originalTitleLb = UILabel.init()
        originalTitleLb.text = "原图".localized
        originalTitleLb.font = UIFont.systemFont(ofSize: 17)
        originalTitleLb.lineBreakMode = .byTruncatingHead
        return originalTitleLb
    }()
    
    lazy var boxControl: SelectBoxView = {
        let boxControl = SelectBoxView.init(frame: CGRect(x: 0, y: 0, width: 17, height: 17))
        boxControl.config = config.originalSelectBox
        boxControl.backgroundColor = .clear
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
        finishBtn.setTitle("完成".localized, for: .normal)
        finishBtn.titleLabel?.font = UIFont.mediumPingFang(ofSize: 16)
        finishBtn.layer.cornerRadius = 3
        finishBtn.layer.masksToBounds = true
        finishBtn.isEnabled = false
        finishBtn.addTarget(self, action: #selector(didFinishButtonClick(button:)), for: .touchUpInside)
        return finishBtn
    }()
    @objc func didFinishButtonClick(button: UIButton) {
        hx_delegate?.bottomView(didFinishButtonClick: self)
    }
    func updatePromptView() {
        if config.showPrompt &&
            AssetManager.authorizationStatusIsLimited() &&
            allowLoadPhotoLibrary &&
            sourceType == .picker {
            if promptView.superview == nil {
                addSubview(promptView)
                configPromptColor()
            }
        }
    }
    func configColor() {
        let isDark = PhotoManager.isDark
        backgroundColor = isDark ? config.backgroundDarkColor : config.backgroundColor
        barTintColor = isDark ? config.barTintDarkColor : config.barTintColor
        barStyle = isDark ? config.barDarkStyle : config.barStyle
        if sourceType != .browser {
            configCoreColor()
        }else {
            #if HXPICKER_ENABLE_EDITOR
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
        }
        configPromptColor()
    }
    func configCoreColor() {
        let isDark = PhotoManager.isDark
        previewBtn.setTitleColor(
            isDark ?
                config.previewButtonTitleDarkColor :
                config.previewButtonTitleColor,
            for: .normal
        )
        #if HXPICKER_ENABLE_EDITOR
        editBtn.setTitleColor(isDark ? config.editButtonTitleDarkColor : config.editButtonTitleColor, for: .normal)
        #endif
        if isDark {
            if config.previewButtonDisableTitleDarkColor != nil {
                previewBtn.setTitleColor(config.previewButtonDisableTitleDarkColor, for: .disabled)
            }else {
                previewBtn.setTitleColor(config.previewButtonTitleDarkColor.withAlphaComponent(0.6), for: .disabled)
            }
            #if HXPICKER_ENABLE_EDITOR
            if config.editButtonDisableTitleDarkColor != nil {
                editBtn.setTitleColor(config.editButtonDisableTitleDarkColor, for: .disabled)
            }else {
                editBtn.setTitleColor(config.editButtonTitleDarkColor.withAlphaComponent(0.6), for: .disabled)
            }
            #endif
        }else {
            if config.previewButtonDisableTitleColor != nil {
                previewBtn.setTitleColor(config.previewButtonDisableTitleColor, for: .disabled)
            }else {
                previewBtn.setTitleColor(config.previewButtonTitleColor.withAlphaComponent(0.6), for: .disabled)
            }
            #if HXPICKER_ENABLE_EDITOR
            if config.editButtonDisableTitleColor != nil {
                editBtn.setTitleColor(config.editButtonDisableTitleColor, for: .disabled)
            }else {
                editBtn.setTitleColor(config.editButtonTitleColor.withAlphaComponent(0.6), for: .disabled)
            }
            #endif
        }
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
    }
    func configPromptColor() {
        if config.showPrompt &&
            AssetManager.authorizationStatusIsLimited()
            && allowLoadPhotoLibrary &&
            sourceType == .picker {
            let isDark = PhotoManager.isDark
            promptLb.textColor = isDark ? config.promptTitleDarkColor : config.promptTitleColor
            promptIcon.tintColor = isDark ? config.promptIconDarkColor : config.promptIconColor
            promptArrow.tintColor = isDark ? config.promptArrowDarkColor : config.promptArrowColor
        }
    }
    func updateFinishButtonTitle() {
        guard let picker = viewController?.pickerController,
              sourceType != .browser else {
            return
        }
        requestAssetBytes()
        var selectCount = 0
        if picker.config.selectMode == .multiple {
            selectCount = picker.selectedAssetArray.count
        }
        if selectCount > 0 {
            finishBtn.isEnabled = true
            previewBtn.isEnabled = true
            finishBtn.setTitle(
                "完成".localized + " (" +
                    String(
                    format: "%d",
                    arguments: [selectCount]
                    )
                    + ")",
                for: .normal
            )
        }else {
            if picker.config.selectMode == .single {
                finishBtn.isEnabled = true
            }else {
                finishBtn.isEnabled = !config.disableFinishButtonWhenNotSelected
            }
            previewBtn.isEnabled = false
            finishBtn.setTitle("完成".localized, for: .normal)
        }
        updateFinishButtonFrame()
    }
    func updateFinishButtonFrame() {
        if sourceType == .browser {
           return
        }
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
    func updateOriginalButtonFrame() {
        if sourceType == .browser {
           return
        }
        updateOriginalSubviewFrame()
        if showOriginalLoadingView {
            originalBtn.frame = CGRect(x: 0, y: 0, width: originalLoadingView.frame.maxX, height: 50)
        }else {
            originalBtn.frame = CGRect(x: 0, y: 0, width: originalTitleLb.frame.maxX, height: 50)
        }
        originalBtn.centerX = width / 2
        let originalMinX: CGFloat
        #if HXPICKER_ENABLE_EDITOR
        originalMinX = sourceType == .preview ? editBtn.frame.maxX + 2 : previewBtn.frame.maxX + 2
        #else
        originalMinX = sourceType == .preview ? 10 : previewBtn.frame.maxX + 2
        #endif
        if originalBtn.frame.maxX > finishBtn.x || originalBtn.x < originalMinX {
            originalBtn.x = finishBtn.x - originalBtn.width
            if originalBtn.x < originalMinX {
                originalBtn.x = originalMinX
                originalTitleLb.width = finishBtn.x - originalMinX - 5 - boxControl.width
            }
        }
    }
    private func updateOriginalSubviewFrame() {
        if sourceType == .browser {
           return
        }
        originalTitleLb.frame = CGRect(
            x: boxControl.frame.maxX + 5,
            y: 0,
            width: originalTitleLb.text!.width(
                ofFont: originalTitleLb.font,
                maxHeight: 50
            ),
            height: 50
        )
        if originalTitleLb.width > width - previewBtn.frame.maxX - finishBtn.width - 12 {
            originalTitleLb.width = width - previewBtn.frame.maxX - finishBtn.width - 12
        }
        boxControl.centerY = originalTitleLb.height * 0.5
        originalLoadingView.centerY = originalBtn.height * 0.5
        originalLoadingView.x = originalTitleLb.frame.maxX + 3
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if sourceType != .browser {
            contentView.width = width
            contentView.height = 50 + UIDevice.bottomMargin
            contentView.y = height - contentView.height
            previewBtn.x = 12 + UIDevice.leftMargin
            #if HXPICKER_ENABLE_EDITOR
            editBtn.x = previewBtn.x
            #endif
            updateFinishButtonFrame()
            updateOriginalButtonFrame()
        }
        if config.showPrompt &&
            AssetManager.authorizationStatusIsLimited() &&
            allowLoadPhotoLibrary &&
            sourceType == .picker {
            promptView.width = width
            promptIcon.x = 12 + UIDevice.leftMargin
            promptIcon.centerY = promptView.height * 0.5
            promptArrow.x = width - 12 - promptArrow.width - UIDevice.rightMargin
            promptLb.x = promptIcon.frame.maxX + 12
            promptLb.width = promptArrow.x - promptLb.x - 12
            promptLb.centerY = promptView.height * 0.5
            promptArrow.centerY = promptView.height * 0.5
        }
        if sourceType == .browser {
            #if HXPICKER_ENABLE_EDITOR
            editBtn.x = 12 + UIDevice.leftMargin
            #endif
            if config.showSelectedView {
                #if HXPICKER_ENABLE_EDITOR
                if !config.editButtonHidden {
                    selectedView.x = editBtn.frame.maxX + 12
                    selectedView.width = width - selectedView.x
                    selectedView.collectionViewLayout.sectionInset = UIEdgeInsets(
                        top: 10,
                        left: 0,
                        bottom: 5,
                        right: 12 + UIDevice.rightMargin
                    )
                }else {
                    selectedView.width = width
                }
                editBtn.centerY = selectedView.centerY
                #else
                selectedView.width = width
                #endif
            }
        }else {
            if config.showSelectedView && isMultipleSelect {
                selectedView.width = width
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

// MARK: PhotoPreviewSelectedViewDelegate
extension PhotoPickerBottomView {
    
    func selectedView(
        _ selectedView: PhotoPreviewSelectedView,
        didSelectItemAt photoAsset: PhotoAsset
    ) {
        hx_delegate?.bottomView(self, didSelectedItemAt: photoAsset)
    }
}
