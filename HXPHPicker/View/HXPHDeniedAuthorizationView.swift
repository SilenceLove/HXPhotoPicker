//
//  HXPHDeniedAuthorizationView.swift
//  HXPHPickerExample
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

class HXPHDeniedAuthorizationView: UIView {
    
    var config: HXPHNotAuthorizedConfiguration?
    
    lazy var navigationBar: UINavigationBar = {
        let navigationBar = UINavigationBar.init()
        navigationBar.setBackgroundImage(UIImage.image(for: UIColor.clear, havingSize: CGSize.zero), for: UIBarMetrics.default)
        navigationBar.shadowImage = UIImage.init()
        let navigationItem = UINavigationItem.init()
        navigationItem.leftBarButtonItem = UIBarButtonItem.init(customView: closeBtn)
        navigationBar.pushItem(navigationItem, animated: false)
        return navigationBar
    }()
    
    lazy var closeBtn: UIButton = {
        let closeBtn = UIButton.init(type: .custom)
        closeBtn.size = CGSize(width: 50, height: 40)
        closeBtn.addTarget(self, action: #selector(didCloseClick), for: .touchUpInside)
        closeBtn.contentHorizontalAlignment = .left
        return closeBtn
    }()
    
    lazy var titleLb: UILabel = {
        let titleLb = UILabel.init()
        titleLb.textAlignment = .center
        titleLb.numberOfLines = 0
        return titleLb
    }()
    
    lazy var subTitleLb: UILabel = {
        let subTitleLb = UILabel.init()
        subTitleLb.textAlignment = .center
        subTitleLb.numberOfLines = 0
        return subTitleLb
    }()
    
    lazy var jumpBtn: UIButton = {
        let jumpBtn = UIButton.init(type: .custom)
        jumpBtn.layer.cornerRadius = 5
        jumpBtn.addTarget(self, action: #selector(jumpSetting), for: .touchUpInside)
        return jumpBtn
    }()
    
    init(config: HXPHNotAuthorizedConfiguration?) {
        super.init(frame: CGRect.zero)
        self.config = config
        configView()
    }
    
    func configView() {
        addSubview(navigationBar)
        addSubview(titleLb)
        addSubview(subTitleLb)
        addSubview(jumpBtn)
        
        titleLb.text = "无法访问相册中照片".localized
        titleLb.font = UIFont.semiboldPingFang(ofSize: 20)
        
        subTitleLb.text = "当前无照片访问权限，建议前往系统设置，\n允许访问「照片」中的「所有照片」。".localized
        subTitleLb.font = UIFont.regularPingFang(ofSize: 17)
        
        jumpBtn.setTitle("前往系统设置".localized, for: .normal)
        jumpBtn.titleLabel?.font = UIFont.mediumPingFang(ofSize: 16)
        
        configColor()
    }
    func configColor() {
        let closeButtonImageName = config?.closeButtonImageName ?? "hx_picker_notAuthorized_close"
        let closeButtonDarkImageName = config?.closeButtonDarkImageName ?? "hx_picker_notAuthorized_close_dark"
        let isDark = HXPHManager.shared.isDark
        closeBtn.setImage(UIImage.image(for: isDark ? closeButtonDarkImageName : closeButtonImageName), for: .normal)
        backgroundColor = isDark ? config?.darkBackgroundColor : config?.backgroundColor
        titleLb.textColor = isDark ? config?.titleDarkColor : config?.titleColor
        subTitleLb.textColor = isDark ? config?.darkSubTitleColor : config?.subTitleColor
        jumpBtn.backgroundColor = isDark ? config?.jumpButtonDarkBackgroundColor : config?.jumpButtonBackgroundColor
        jumpBtn.setTitleColor(isDark ? config?.jumpButtonTitleDarkColor : config?.jumpButtonTitleColor, for: .normal)
    }
    @objc func didCloseClick() {
        self.viewController()?.dismiss(animated: true, completion: nil)
    }
    @objc func jumpSetting() {
        HXPHTools.openSettingsURL()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        var barHeight: CGFloat = 0
        if viewController()?.navigationController?.modalPresentationStyle == UIModalPresentationStyle.fullScreen {
            barHeight = (viewController()?.navigationController?.navigationBar.height ?? 44) + UIDevice.current.statusBarHeight
        }else {
            barHeight = viewController()?.navigationController?.navigationBar.height ?? 44
        }
        navigationBar.frame = CGRect(x: 0, y: 0, width: width, height: barHeight)
        
        let titleHeight = titleLb.text?.height(ofFont: titleLb.font, maxWidth: width) ?? 0
        titleLb.frame = CGRect(x: 0, y: 0, width: width, height: titleHeight)
        
        let subTitleHeight = subTitleLb.text?.height(ofFont: subTitleLb.font, maxWidth: width - 40) ?? 0
        subTitleLb.frame = CGRect(x: 20, y: height / 2 - subTitleHeight - 30 - UIDevice.current.topMargin, width: width - 40, height: subTitleHeight)
        titleLb.y = subTitleLb.y - 15 - titleHeight
        
        let jumpBtnBottomMargin : CGFloat = UIDevice.isProxy() ? 120 : 50
        var jumpBtnWidth = (jumpBtn.currentTitle?.width(ofFont: jumpBtn.titleLabel!.font, maxHeight: 40) ?? 0 ) + 10
        if jumpBtnWidth < 150 {
            jumpBtnWidth = 150
        }
        jumpBtn.frame = CGRect(x: 0, y: height - UIDevice.current.bottomMargin - 40 - jumpBtnBottomMargin, width: jumpBtnWidth, height: 40)
        jumpBtn.centerX = width * 0.5
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
