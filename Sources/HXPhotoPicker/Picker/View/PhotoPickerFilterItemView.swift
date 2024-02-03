//
//  PhotoPickerFilterItemView.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/10/22.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit

public class PhotoPickerFilterItemView: UIView, PhotoNavigationItem {
    public weak var itemDelegate: PhotoNavigationItemDelegate?
    public var isSelected: Bool = false {
        didSet {
            button.isSelected = isSelected
        }
    }
    public var itemType: PhotoNavigationItemType { .filter }
    
    let config: PickerConfiguration
    public required init(config: PickerConfiguration) {
        self.config = config
        super.init(frame: .zero)
        initView()
    }
    
    var button: UIButton!
    func initView() {
        button = UIButton(type: .custom)
        button.setImage(.imageResource.picker.photoList.filterNormal.image?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setImage(.imageResource.picker.photoList.filterSelected.image?.withRenderingMode(.alwaysTemplate), for: .selected)
        button.addTarget(self, action: #selector(didFilterClick), for: .touchUpInside)
        addSubview(button)
        if let btnSize = button.currentImage?.size {
            button.size = btnSize
            size = button.size
        }
        setColor()
    }
    
    func setColor() {
        guard let color = PhotoManager.isDark ? config.navigationDarkTintColor : config.navigationTintColor else {
            return
        }
        button.imageView?.tintColor = color
    }
    
    @objc
    func didFilterClick() {
        if #available(iOS 13.0, *) {
            itemDelegate?.photoItem(presentFilterAssets: self, modalPresentationStyle: .automatic)
        } else {
            itemDelegate?.photoItem(presentFilterAssets: self, modalPresentationStyle: .fullScreen)
        }
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
