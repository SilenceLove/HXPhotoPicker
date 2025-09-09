//
//  PhotoPickerFinishItemView.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/10/22.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit

public class PhotoPickerFinishItemView: UIView, PhotoNavigationItem {
    public weak var itemDelegate: PhotoNavigationItemDelegate?
    public var itemType: PhotoNavigationItemType { .finish }
    
    let config: PickerConfiguration
    public required init(config: PickerConfiguration) {
        self.config = config
        super.init(frame: .zero)
        initView()
    }
    
    var button: UIButton!
    func initView() {
        button = UIButton(type: .custom)
        button.setTitle("完成".localized, for: .normal)
        button.titleLabel?.font = .mediumPingFang(ofSize: 16)
        button.layer.cornerRadius = 3
        button.layer.masksToBounds = true
        button.isEnabled = false
        button.addTarget(self, action: #selector(didFinishButtonClick), for: .touchUpInside)
        addSubview(button)
        
        setColor()
    }
    
    func setColor() {
        let isDark = PhotoManager.isDark
        let bottomView = config.photoList.bottomView
        let bgColor = isDark ?
        bottomView.finishButtonDarkBackgroundColor :
        bottomView.finishButtonBackgroundColor
        let bgDisableColor = isDark ?
        bottomView.finishButtonDisableDarkBackgroundColor :
        bottomView.finishButtonDisableBackgroundColor
        let titleColor = isDark ?
        bottomView.finishButtonTitleDarkColor :
        bottomView.finishButtonTitleColor
        let titleDisableColor = isDark ?
        bottomView.finishButtonDisableTitleDarkColor :
        bottomView.finishButtonDisableTitleColor
        button.setTitleColor(titleColor, for: .normal)
        button.setTitleColor(titleDisableColor, for: .disabled)
        button.setBackgroundImage(.image(for: bgColor, havingSize: .zero), for: .normal)
        button.setBackgroundImage(.image(for: bgDisableColor, havingSize: .zero), for: .disabled)
    }
    
    @objc
    func didFinishButtonClick() {
        itemDelegate?.photoControllerDidFinish()
    }
    
    public func selectedAssetDidChanged(_ photoAssets: [PhotoAsset]) {
        let count = photoAssets.count
        if count > 0 {
            button.isEnabled = true
            button.setTitle("完成".localized + " (\(count))", for: .normal)
        }else {
            button.isEnabled = !config.photoList.bottomView.disableFinishButtonWhenNotSelected
            button.setTitle("完成".localized, for: .normal)
        }
        self.setNeedsLayout()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        let buttonSize = button.sizeThatFits(self.bounds.size)
        button.frame = CGRect(
            x: (self.bounds.width - buttonSize.width) / 2,
            y: (self.bounds.height - buttonSize.height) / 2,
            width: buttonSize.width,
            height: buttonSize.height
        )
    }
    
    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        return button.sizeThatFits(size)
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                setColor()
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

