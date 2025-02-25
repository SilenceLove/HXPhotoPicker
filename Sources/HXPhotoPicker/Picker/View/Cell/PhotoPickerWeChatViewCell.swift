//
//  PhotoPickerWeChatViewCell.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/10/25.
//

import UIKit

open class PhotoPickerWeChatViewCell: PhotoPickerSelectableViewCell {
    
    public var titleLb: UILabel!
    
    open override func initView() {
        super.initView()
        titleLb = UILabel()
        titleLb.hxpicker_alignment = .center
        titleLb.textColor = .white
        titleLb.font = .semiboldPingFang(ofSize: 15)
        titleLb.isHidden = true
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
        titleLb.hxPicker_x = 10
    }
}
