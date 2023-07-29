//
//  PhotoPickerBottomPromptView.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/7/29.
//  Copyright © 2023 洪欣. All rights reserved.
//

import UIKit

class PhotoPickerBottomPromptView: UIToolbar {
    let config: PickerBottomViewConfiguration
    init(config: PickerBottomViewConfiguration) {
        self.config = config
        super.init(frame: .zero)
        initView()
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
    
    func initView() {
        addSubview(promptIcon)
        addSubview(promptLb)
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
    func didPromptViewClick() {
        PhotoTools.openSettingsURL()
    }
    
    func configColor() {
        if PhotoManager.isDark {
            backgroundColor = config.backgroundDarkColor
            barTintColor = config.barTintDarkColor
            barStyle = config.barDarkStyle
            promptLb.textColor = config.promptTitleDarkColor
            promptIcon.tintColor = config.promptIconDarkColor
            promptArrow.tintColor = config.promptArrowDarkColor
        }else {
            backgroundColor = config.backgroundColor
            barTintColor = config.barTintColor
            barStyle = config.barStyle
            promptLb.textColor = config.promptTitleColor
            promptIcon.tintColor = config.promptIconColor
            promptArrow.tintColor = config.promptArrowColor
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let viewHeight = height - UIDevice.bottomMargin
        promptIcon.x = 12 + UIDevice.leftMargin
        promptIcon.centerY = viewHeight * 0.5
        promptArrow.x = width - 12 - promptArrow.width - UIDevice.rightMargin
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
