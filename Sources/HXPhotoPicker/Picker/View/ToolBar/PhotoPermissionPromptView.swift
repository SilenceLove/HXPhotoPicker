//
//  PhotoPermissionPromptView.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/9/14.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit

class PhotoPermissionPromptView: UIView {
    let config: PickerBottomViewConfiguration
    init(config: PickerBottomViewConfiguration) {
        self.config = config
        super.init(frame: .zero)
        initView()
    }
    
    private var promptLb: UILabel!
    private var promptIcon: UIImageView!
    private var promptArrow: UIImageView!
    
    private func initView() {
        let promptIconImage: UIImage? = .imageResource.picker.photoList.bottomView.permissionsPrompt.image?.withRenderingMode(.alwaysTemplate)
        promptIcon = UIImageView(image: promptIconImage)
        if let imageSize = promptIcon.image?.size {
            promptIcon.size = imageSize
        }
        addSubview(promptIcon)
        
        promptLb = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 60))
        promptLb.text = .textPhotoList.bottomView.permissionsTitle.text
        promptLb.font = .textPhotoList.bottomView.permissionsTitleFont
        promptLb.numberOfLines = 0
        promptLb.adjustsFontSizeToFitWidth = true
        addSubview(promptLb)
        
        let promptArrowImage = HX.imageResource.picker.photoList.bottomView.permissionsArrow.image?.withRenderingMode(.alwaysTemplate)
        promptArrow = UIImageView(image: promptArrowImage)
        if let imageSize = promptArrow.image?.size {
            promptArrow.size = imageSize
        }
        addSubview(promptArrow)
        
        addGestureRecognizer(
            UITapGestureRecognizer(
                target: self,
                action: #selector(didPromptViewClick)
            )
        )
        configColor()
    }
    
    @objc
    private func didPromptViewClick() {
        PhotoTools.openSettingsURL()
    }
    
    private func configColor() {
        if PhotoManager.isDark {
            promptLb.textColor = config.promptTitleDarkColor
            promptIcon.tintColor = config.promptIconDarkColor
            promptArrow.tintColor = config.promptArrowDarkColor
        }else {
            promptLb.textColor = config.promptTitleColor
            promptIcon.tintColor = config.promptIconColor
            promptArrow.tintColor = config.promptArrowColor
        }
    }
    
    var leftMargin: CGFloat {
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let viewHeight = height
        let leftMargin = self.leftMargin
        if leftMargin > 0 {
            promptIcon.x = leftMargin
        }else {
            promptIcon.x = 12
        }
        promptIcon.centerY = viewHeight * 0.5
        if UIDevice.rightMargin > 0 {
            promptArrow.x = width - promptArrow.width - UIDevice.rightMargin
        }else {
            promptArrow.x = width - 12 - promptArrow.width
        }
        promptLb.x = promptIcon.frame.maxX + 12
        promptLb.width = promptArrow.x - promptLb.x - 12
        promptLb.centerY = viewHeight * 0.5
        promptArrow.centerY = viewHeight * 0.5
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
