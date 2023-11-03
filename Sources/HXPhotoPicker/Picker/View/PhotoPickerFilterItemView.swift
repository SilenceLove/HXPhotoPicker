//
//  PhotoPickerFilterItemView.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/10/22.
//  Copyright © 2023 洪欣. All rights reserved.
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
        button.setImage("hx_picker_photolist_nav_filter_normal".image?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setImage("hx_picker_photolist_nav_filter_selected".image?.withRenderingMode(.alwaysTemplate), for: .selected)
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
        itemDelegate?.photoItem(presentFilterAssets: self)
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
