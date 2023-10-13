//
//  AlbumSectionHeaderView.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/10/6.
//  Copyright © 2023 洪欣. All rights reserved.
//

import UIKit

class AlbumSectionHeaderView: UITableViewHeaderFooterView {
    
    var titleLb: UILabel!
    
    var titleColor: UIColor?
    var titleDarkColor: UIColor?
    var bgColor: UIColor?
    var bgDarkColor: UIColor?
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        backgroundView = UIView()
        titleLb = UILabel()
        titleLb.text = "只能查看允许访问的照片和相关相册".localized
        titleLb.textAlignment = .center
        titleLb.font = UIFont.systemFont(ofSize: 14)
        titleLb.adjustsFontSizeToFitWidth = true
        titleLb.numberOfLines = 0
        
        contentView.addSubview(titleLb)
    }
    
    func updateColor() {
        titleLb.textColor = PhotoManager.isDark ? titleDarkColor : titleColor
        backgroundView?.backgroundColor = PhotoManager.isDark ? bgDarkColor : bgColor
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                updateColor()
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        titleLb.frame = contentView.bounds
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
