//
//  PhotoPickerSelectableViewCell.swift
//  HXPHPicker
//
//  Created by Slience on 2021/3/12.
//

import UIKit

open class PhotoPickerSelectableViewCell: PhotoPickerViewCell {
    
    /// 选择按钮
    public lazy var selectControl: SelectBoxView = {
        let selectControl = SelectBoxView()
        selectControl.isHidden = true
        selectControl.backgroundColor = .clear
        selectControl.addTarget(self, action: #selector(didSelectControlClick(control:)), for: .touchUpInside)
        return selectControl
    }()
    
    /// 配置颜色
    open override func configColor() {
        super.configColor()
        if let config = config {
            selectControl.config = config.selectBox
        }
    }
    
    /// 添加视图
    open override func initView() {
        super.initView()
        contentView.addSubview(selectControl)
        contentView.layer.addSublayer(disableMaskLayer)
        contentView.addSubview(iCloudMarkView)
    }
    
    private var didLoadCompletion: Bool = false
    
    open override func requestThumbnailImage(targetWidth: CGFloat) {
        if didLoadCompletion {
            selectControl.isHidden = false
        }
        super.requestThumbnailImage(targetWidth: targetWidth)
    }
    open override func requestThumbnailCompletion(_ image: UIImage?) {
        super.requestThumbnailCompletion(image)
        if !didLoadCompletion {
            selectControl.isHidden = false
            didLoadCompletion = true
        }
    }
    
    open override func requestICloudStateCompletion(_ inICloud: Bool) {
        super.requestICloudStateCompletion(inICloud)
        selectControl.isHidden = inICloud
        selectControl.isEnabled = !inICloud
    }
    
    /// 选择框点击事件
    /// - Parameter control: 选择框
    @objc open func didSelectControlClick(control: SelectBoxView) {
        if inICloud {
            return
        }
        selectedAction(self.selectControl.isSelected)
    }
    
    /// 更新选择状态
    open override func updateSelectedState(isSelected: Bool, animated: Bool) {
        super.updateSelectedState(isSelected: isSelected, animated: animated)
        if let config = config {
            let boxWidth = config.selectBox.size.width
            let boxHeight = config.selectBox.size.height
            if isSelected {
                if selectControl.text == selectedTitle && selectControl.isSelected == true {
                    return
                }
                selectMaskLayer.isHidden = false
                if config.selectBox.style == .number {
                    let text = selectedTitle
                    let font = UIFont.mediumPingFang(ofSize: config.selectBox.titleFontSize)
                    let textHeight = text.height(ofFont: font, maxWidth: CGFloat(MAXFLOAT))
                    var textWidth = text.width(ofFont: font, maxHeight: textHeight)
                    selectControl.textSize = CGSize(width: textWidth, height: textHeight)
                    textWidth += boxHeight * 0.5
                    if textWidth < boxWidth {
                        textWidth = boxWidth
                    }
                    selectControl.text = text
                    updateSelectControlSize(width: textWidth, height: boxHeight)
                }else {
                    updateSelectControlSize(width: boxWidth, height: boxHeight)
                }
            }else {
                if selectControl.isSelected == false &&
                    selectControl.size.equalTo(CGSize(width: boxWidth, height: boxHeight)) {
                    return
                }
                selectMaskLayer.isHidden = true
                updateSelectControlSize(width: boxWidth, height: boxHeight)
            }
            selectControl.isSelected = isSelected
            if animated {
                selectControl.layer.removeAnimation(forKey: "SelectControlAnimation")
                let keyAnimation = CAKeyframeAnimation.init(keyPath: "transform.scale")
                keyAnimation.duration = 0.3
                keyAnimation.values = [1.2, 0.8, 1.1, 0.9, 1.0]
                selectControl.layer.add(keyAnimation, forKey: "SelectControlAnimation")
            }
        }
    }
    
    /// 更新选择框大小
    open func updateSelectControlSize(width: CGFloat, height: CGFloat) {
        let topMargin = config?.selectBoxTopMargin ?? 5
        let rightMargin = config?.selectBoxRightMargin ?? 5
        let rect = CGRect(x: self.width - rightMargin - width, y: topMargin, width: width, height: height)
        if selectControl.frame.equalTo(rect) {
            return
        }
        if let photoAsset = photoAsset, photoAsset.isScrolling {
            let x = selectControl.x
            selectControl.frame = rect
            selectControl.x = x
        }else {
            selectControl.frame = rect
        }
    }
    
    open override func layoutView() {
        super.layoutView()
        updateSelectControlSize()
    }
    
    func updateSelectControlSize() {
        updateSelectControlSize(
            width: selectControl.width,
            height: selectControl.height
        )
    }
}
