//
//  HXPHPickerBottomView.swift
//  HXPHPickerExample
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 洪欣. All rights reserved.
//

import UIKit

@objc protocol HXPHPickerBottomViewDelegate: NSObjectProtocol {
    @objc optional func bottomView(didPreviewButtonClick view: HXPHPickerBottomView)
    @objc optional func bottomView(didEditButtonClick view: HXPHPickerBottomView)
    @objc optional func bottomView(didFinishButtonClick view: HXPHPickerBottomView)
    @objc optional func bottomView(didOriginalButtonClick view: HXPHPickerBottomView, with isOriginal: Bool)
    @objc optional func bottomView(_ bottomView: HXPHPickerBottomView, didSelectedItemAt photoAsset: HXPHAsset)
}

class HXPHPickerBottomView: UIToolbar, HXPHPreviewSelectedViewDelegate {
    
    weak var hx_delegate: HXPHPickerBottomViewDelegate?
    
    var config: HXPHPickerBottomViewConfiguration
    
    lazy var selectedView: HXPHPreviewSelectedView = {
        let selectedView = HXPHPreviewSelectedView.init(frame: CGRect(x: 0, y: 0, width: hx_width, height: 70))
        if let customSelectedViewCellClass = config.customSelectedViewCellClass {
            selectedView.collectionView.register(customSelectedViewCellClass, forCellWithReuseIdentifier: NSStringFromClass(HXPHPreviewSelectedViewCell.self))
        }else {
            selectedView.collectionView.register(HXPHPreviewSelectedViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(HXPHPreviewSelectedViewCell.self))
        }
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
        previewBtn.hx_height = 50
        let previewWidth : CGFloat = previewBtn.currentTitle!.hx_localized.hx_stringWidth(ofFont: previewBtn.titleLabel!.font, maxHeight: 50)
        previewBtn.hx_width = previewWidth
        return previewBtn
    }()
    
    @objc func didPreviewButtonClick(button: UIButton) {
        hx_delegate?.bottomView?(didPreviewButtonClick: self)
    }
    
    lazy var editBtn: UIButton = {
        let editBtn = UIButton.init(type: .custom)
        editBtn.setTitle("编辑".hx_localized, for: .normal)
        editBtn.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        editBtn.addTarget(self, action: #selector(didEditBtnButtonClick(button:)), for: .touchUpInside)
        editBtn.isHidden = config.editButtonHidden
        editBtn.hx_height = 50
        let editWidth : CGFloat = editBtn.currentTitle!.hx_localized.hx_stringWidth(ofFont: editBtn.titleLabel!.font, maxHeight: 50)
        editBtn.hx_width = editWidth
        return editBtn
    }()
    
    @objc func didEditBtnButtonClick(button: UIButton) {
        hx_delegate?.bottomView?(didEditButtonClick: self)
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
        hx_delegate?.bottomView?(didOriginalButtonClick: self, with: boxControl.isSelected)
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
        hx_delegate?.bottomView?(didFinishButtonClick: self)
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
            if !config.editButtonHidden {
                addSubview(editBtn)
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
        hx_delegate?.bottomView?(self, didSelectedItemAt: photoAsset)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if !isExternalPreview {
            contentView.hx_width = hx_width
            contentView.hx_height = 50 + UIDevice.current.hx_bottomMargin
            contentView.hx_y = hx_height - contentView.hx_height
            previewBtn.hx_x = 12 + UIDevice.current.hx_leftMargin
            editBtn.hx_x = previewBtn.hx_x
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
            editBtn.hx_x = 12 + UIDevice.current.hx_leftMargin
            if config.showSelectedView {
                if !config.editButtonHidden {
                    selectedView.hx_x = editBtn.frame.maxX + 12
                    selectedView.hx_width = hx_width - selectedView.hx_x
                    selectedView.collectionViewLayout.sectionInset = UIEdgeInsets(top: 10, left: 0, bottom: 5, right: 12 + UIDevice.current.hx_rightMargin)
                }else {
                    selectedView.hx_width = hx_width
                }
                editBtn.hx_centerY = selectedView.hx_centerY
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
