//
//  CustomPickerCellView.swift
//  Example
//
//  Created by Slience on 2021/3/16.
//

import UIKit
import HXPhotoPicker

class CustomPickerViewCell: PhotoPickerViewCell {
    lazy var selectedMaskView: UIView = {
        let view = UIView.init()
        view.layer.borderWidth = 5
        view.layer.borderColor = UIColor(hexString: "#07c160").cgColor
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        view.addSubview(numberLb)
        view.isHidden = true
        return view
    }()
    
    lazy var numberLb: UILabel = {
        let label = UILabel.init()
        label.textColor = UIColor(hexString: "#ffffff")
        label.textAlignment = .center
        label.font = .boldSystemFont(ofSize: 35)
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    override func initView() {
        super.initView()
        contentView.addSubview(selectedMaskView)
    }
    
    override func updateSelectedState(isSelected: Bool, animated: Bool) {
        super.updateSelectedState(isSelected: isSelected, animated: animated)
        numberLb.text = String(photoAsset.selectIndex + 1)
        selectedMaskView.isHidden = !isSelected
    }
    
    override func layoutView() {
        super.layoutView()
        selectedMaskView.frame = bounds
        numberLb.frame = selectedMaskView.bounds
    }
    
}
