//
//  PhotoAlbumHeaderView.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/10/19.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit

public protocol PhotoAlbumHeaderViewDelegate: AnyObject {
    func albumHeaderView(didAllClick albumHeaderView: PhotoAlbumHeaderView)
}

public class PhotoAlbumHeaderView: UITableViewHeaderFooterView {
    public weak var delegate: PhotoAlbumHeaderViewDelegate?
    var titleLb: UILabel!
    var allBtn: UIButton!
    
    public var config: PhotoAlbumControllerConfiguration = .init() {
        didSet {
            titleLb.font = config.headerTitleFont
            allBtn.titleLabel?.font = config.headerButtonTitleFont
            updateColors()
        }
    }
    
    public override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        titleLb = UILabel()
        contentView.addSubview(titleLb)
        
        allBtn = UIButton(type: .system)
        allBtn.setTitle(.textManager.picker.albumList.lookAllSectionTitle.text, for: .normal)
        allBtn.addTarget(self, action: #selector(didAllButtonClick), for: .touchUpInside)
        contentView.addSubview(allBtn)
    }
    
    @objc
    func didAllButtonClick() {
        delegate?.albumHeaderView(didAllClick: self)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        titleLb.x = 15
        titleLb.centerY = contentView.height / 2
        titleLb.size = contentView.size
        
        if let btnWidth = allBtn.titleLabel?.textWidth {
            allBtn.size = .init(width: btnWidth, height: contentView.height)
            allBtn.x = contentView.width - 15 - btnWidth
        }
    }
    
    func updateColors() {
        if #available(iOS 14.0, *) {
            backgroundConfiguration?.backgroundColor = PhotoManager.isDark ? config.cellBackgroundDarkColor : config.cellBackgroundColor
        } else {
            backgroundColor = PhotoManager.isDark ? config.cellBackgroundDarkColor : config.cellBackgroundColor
        }
        allBtn.setTitleColor(PhotoManager.isDark ? config.headerButtonTitleDarkColor : config.headerButtonTitleColor, for: .normal)
        titleLb.textColor = PhotoManager.isDark ? config.headerTitleDarkColor : config.headerTitleColor
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                updateColors()
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
