//
//  EmptyView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

public class PhotoPickerEmptyView: UIView {
    private var titleLb: UILabel!
    private var subTitleLb: UILabel!
    
    let config: EmptyViewConfiguration
    init(config: EmptyViewConfiguration) {
        self.config = config
        super.init(frame: .zero)
        
        titleLb = UILabel()
        titleLb.text = .textPhotoList.emptyTitle.text
        titleLb.numberOfLines = 0
        titleLb.textAlignment = .center
        titleLb.font = .textPhotoList.emptyTitleFont
        addSubview(titleLb)
        
        subTitleLb = UILabel()
        subTitleLb.text = .textPhotoList.emptySubTitle.text
        subTitleLb.numberOfLines = 0
        subTitleLb.textAlignment = .center
        subTitleLb.font = .textPhotoList.emptySubTitleFont
        addSubview(subTitleLb)
        
        configColor()
    }
    
    private func configColor() {
        titleLb.textColor = PhotoManager.isDark ? config.titleDarkColor : config.titleColor
        subTitleLb.textColor = PhotoManager.isDark ? config.subTitleDarkColor : config.subTitleColor
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        if let titleHeight = titleLb.text?.height(ofFont: titleLb.font, maxWidth: width - 20) {
            titleLb.frame = CGRect(x: 10, y: 0, width: width - 20, height: titleHeight)
        }
        if let subTitleHeight = subTitleLb.text?.height(ofFont: subTitleLb.font, maxWidth: width - 20) {
            subTitleLb.frame = CGRect(x: 10, y: titleLb.frame.maxY + 3, width: width - 20, height: subTitleHeight)
        }
        height = subTitleLb.frame.maxY
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
