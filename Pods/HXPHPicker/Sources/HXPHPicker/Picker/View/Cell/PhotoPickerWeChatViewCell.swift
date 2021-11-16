//
//  PhotoPickerWeChatViewCell.swift
//  HXPHPicker
//
//  Created by Slience on 2021/10/25.
//

import UIKit

open class PhotoPickerWeChatViewCell: PhotoPickerSelectableViewCell {
    
    lazy var titleLb: UILabel = {
        let titleLb = UILabel()
        titleLb.textAlignment = .center
        titleLb.textColor = .white
        titleLb.font = .semiboldPingFang(ofSize: 15)
        titleLb.isHidden = true
        return titleLb
    }()
    
    open override func initView() {
        super.initView()
        contentView.insertSubview(titleLb, belowSubview: selectControl)
    }
    
    open override func updateSelectedState(isSelected: Bool, animated: Bool) {
        super.updateSelectedState(isSelected: isSelected, animated: animated)
        titleLb.isHidden = !isSelected
        titleLb.text = "\(photoAsset.selectIndex + 1)"
        titleLb.height = 18
        titleLb.width = titleLb.textWidth
        titleLb.centerY = selectControl.centerY
    }
    
    open override func layoutView() {
        super.layoutView()
        titleLb.x = 10
    }
}
