//
//  DeniedAuthorizationView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit
 
public class DeniedAuthorizationView: UIView, PhotoDeniedAuthorization {
    public weak var pickerDelegate: PhotoControllerEvent?
    
    let config: NotAuthorizedConfiguration
    
    private var navigationBar: UINavigationBar!
    private var closeBtn: UIButton!
    private var titleLb: UILabel!
    private var subTitleLb: UILabel!
    private var jumpBtn: UIButton!
    
    required public init(config: PickerConfiguration) {
        self.config = config.notAuthorized
        super.init(frame: .zero)
        initViews()
        configViews()
    }
    
    private func initViews() {
        if !config.isHiddenCloseButton {
            closeBtn = UIButton(type: .custom)
            closeBtn.size = CGSize(width: 50, height: 40)
            closeBtn.addTarget(self, action: #selector(didCloseClick), for: .touchUpInside)
            closeBtn.contentHorizontalAlignment = .left
            
            navigationBar = UINavigationBar()
            navigationBar.setBackgroundImage(
                UIImage.image(
                    for: UIColor.clear,
                    havingSize: CGSize.zero
                ),
                for: UIBarMetrics.default
            )
            navigationBar.shadowImage = UIImage()
            let navigationItem = UINavigationItem()
            navigationItem.leftBarButtonItem = UIBarButtonItem(customView: closeBtn)
            navigationBar.pushItem(navigationItem, animated: false)
            addSubview(navigationBar)
        }
        
        titleLb = UILabel()
        titleLb.textAlignment = .center
        titleLb.numberOfLines = 0
        addSubview(titleLb)
        
        subTitleLb = UILabel()
        subTitleLb.textAlignment = .center
        subTitleLb.numberOfLines = 0
        addSubview(subTitleLb)
        
        jumpBtn = UIButton(type: .custom)
        jumpBtn.layer.cornerRadius = 5
        jumpBtn.addTarget(self, action: #selector(jumpSetting), for: .touchUpInside)
        addSubview(jumpBtn)
    }
    
    private func configViews() {
        
        titleLb.text = .textNotAuthorized.title.text
        titleLb.font = .textNotAuthorized.titleFont
        
        subTitleLb.text = .textNotAuthorized.subTitle.text
        subTitleLb.font = .textNotAuthorized.subTitleFont
        
        jumpBtn.setTitle(.textNotAuthorized.buttonTitle.text, for: .normal)
        jumpBtn.titleLabel?.font = .textNotAuthorized.buttonTitleFont
        
        configColor()
    }
    
    private func configColor() {
        let isDark = PhotoManager.isDark
        if !config.isHiddenCloseButton {
            let closeButtonImageName = config.closeButtonImageName
            let closeButtonDarkImageName = config.closeButtonDarkImageName
            let closeBtnColor = isDark ? config.closeButtonDarkColor : config.closeButtonColor
            if let closeBtnColor = closeBtnColor {
                closeBtn.setImage(UIImage.image(for: isDark ? closeButtonDarkImageName : closeButtonImageName)?.withRenderingMode(.alwaysTemplate), for: .normal)
                closeBtn.tintColor = closeBtnColor
            }else {
                closeBtn.setImage(UIImage.image(for: isDark ? closeButtonDarkImageName : closeButtonImageName), for: .normal)
            }
        }
        backgroundColor = isDark ? config.darkBackgroundColor : config.backgroundColor
        titleLb.textColor = isDark ? config.titleDarkColor : config.titleColor
        subTitleLb.textColor = isDark ? config.darkSubTitleColor : config.subTitleColor
        let jumpBackgroundColor = isDark ? config.jumpButtonDarkBackgroundColor : config.jumpButtonBackgroundColor
        let labelWidth = jumpBtn.currentTitle?.width(ofFont: jumpBtn.titleLabel!.font, maxHeight: 40) ?? 10
        let jumpBtnWidth: CGFloat = max(labelWidth + 10, 150)
        jumpBtn.setBackgroundImage(.image(for: jumpBackgroundColor, havingSize: .init(width: jumpBtnWidth, height: 40), radius: 5), for: .normal)
        jumpBtn.setTitleColor(isDark ? config.jumpButtonTitleDarkColor : config.jumpButtonTitleColor, for: .normal)
    }
    @objc
    private func didCloseClick() {
        pickerDelegate?.photoControllerDidCancel()
    }
    @objc
    private func jumpSetting() {
        PhotoTools.openSettingsURL()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        var barHeight: CGFloat = 0
        var barY: CGFloat = 0
        if let pickerController = viewController as? PhotoPickerController {
            barHeight = pickerController.navigationBar.height
            if pickerController.modalPresentationStyle == .fullScreen {
                barY = UIDevice.statusBarHeight
            }
        }else if let splitVC = viewController as? PhotoSplitViewController {
            barHeight = splitVC.photoController.navigationBar.height
            if splitVC.photoController.modalPresentationStyle == .fullScreen {
                barY = UIDevice.statusBarHeight
            }
        }
        if !config.isHiddenCloseButton {
            navigationBar.frame = CGRect(x: 0, y: barY, width: width, height: barHeight)
        }
        
        var titleHeight: CGFloat = 0
        if let labelWidth = titleLb.text?.height(ofFont: titleLb.font, maxWidth: width - 20) {
            titleHeight = labelWidth
        }
        titleLb.frame = CGRect(x: 10, y: 0, width: width - 20, height: titleHeight)
        
        var subTitleHeight: CGFloat = 0
        if let labelWidth = subTitleLb.text?.height(ofFont: subTitleLb.font, maxWidth: width - 40) {
            subTitleHeight = labelWidth
        }
        let subTitleY: CGFloat
        if barHeight == 0 {
            subTitleY = height / 2 - subTitleHeight
        }else {
            subTitleY = height / 2 - subTitleHeight - 30 - UIDevice.topMargin
        }
        subTitleLb.frame = CGRect(
            x: 20,
            y: subTitleY,
            width: width - 40,
            height: subTitleHeight
        )
        titleLb.y = subTitleLb.y - 15 - titleHeight
        
        let jumpBtnBottomMargin: CGFloat = UIDevice.isPortrait ? 120 : 50
        let labelWidth = jumpBtn.currentTitle?.width(ofFont: jumpBtn.titleLabel!.font, maxHeight: 40) ?? 10
        let jumpBtnWidth: CGFloat = max(labelWidth + 10, 150)
        let jumpY: CGFloat
        if barHeight == 0 {
            jumpY = height - UIDevice.bottomMargin - 50
        }else {
            jumpY = height - UIDevice.bottomMargin - 40 - jumpBtnBottomMargin
        }
        jumpBtn.frame = CGRect(
            x: 0,
            y: jumpY,
            width: jumpBtnWidth,
            height: 40
        )
        jumpBtn.centerX = width * 0.5
    }
    
    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        true
    }
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if !config.isHiddenCloseButton, closeBtn.frame.contains(point) {
            return closeBtn
        }
        return super.hitTest(point, with: event)
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
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
