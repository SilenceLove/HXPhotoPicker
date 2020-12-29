//
//  HXPHPickerViewCell.swift
//  照片选择器-Swift
//
//  Created by Silence on 2019/6/29.
//  Copyright © 2019年 Silence. All rights reserved.
//

import UIKit
import Photos


@objc public protocol HXPHPickerViewCellDelegate: NSObjectProtocol {
    @objc optional func cell(didSelectControl cell: HXPHPickerBaseViewCell, isSelected: Bool)
}

open class HXPHPickerBaseViewCell: UICollectionViewCell {
    public weak var delegate: HXPHPickerViewCellDelegate?
    
    /// 配置
    public var config: HXPHPhotoListCellConfiguration? {
        didSet {
            configColor()
        }
    }
    open func configColor() {
        backgroundColor = HXPHManager.shared.isDark ? config?.backgroundDarkColor : config?.backgroundColor
    }
    // 展示图片
    public lazy var imageView: UIImageView = {
        let imageView = UIImageView.init()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    /// 是否可以选择
    open var canSelect = true
    
    /// 请求ID
    var requestID: PHImageRequestID?
    
    open var photoAsset: HXPHAsset? {
        didSet {
            if let photoAsset = photoAsset {
                selectedTitle = photoAsset.isSelected ? String(photoAsset.selectIndex + 1) : "0"
            }
            requestThumbnailImage()
        }
    }
    private var firstLoadCompletion: Bool = false
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func initView() {
        isHidden = true
        contentView.addSubview(imageView)
    }
    
    /// 当前选中时显示的标题数字
    open var selectedTitle: String = "0"
    /// 获取图片，重写此方法可以修改图片
    open func requestThumbnailImage() {
        weak var weakSelf = self
        requestID = photoAsset?.requestThumbnailImage(targetWidth: hx_width * 2, completion: { (image, photoAsset, info) in
            if photoAsset == weakSelf?.photoAsset && image != nil {
                if !(weakSelf?.firstLoadCompletion ?? true) {
                    weakSelf?.isHidden = false
                    weakSelf?.firstLoadCompletion = true
                }
                weakSelf?.imageView.image = image
                if !HXPHAssetManager.assetDownloadIsDegraded(for: info) {
                    weakSelf?.requestID = nil
                }
            }
        })
    }
    
    /// 更新已选状态
    /// 重写此方法时如果是自定义的选择按钮显示当前选择的下标文字，必须在此方法内更新文字内容，否则将会出现顺序显示错乱
    /// 当前选择的下标：photoAsset.selectIndex
    /// - Parameters:
    ///   - isSelected: 是否已选择
    ///   - animated: 是否需要动画效果
    open func updateSelectedState(isSelected: Bool, animated: Bool) {
        
    }
    /// 布局，重写此方法修改布局
    open func layoutView() {
        imageView.frame = bounds
    }
    
    func cancelRequest() {
        if requestID != nil {
            PHImageManager.default().cancelImageRequest(requestID!)
            requestID = nil
        }
    }
    open override func layoutSubviews() {
        super.layoutSubviews()
        layoutView()
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                configColor()
            }
        }
    }
}

open class HXPHPickerViewCell: HXPHPickerBaseViewCell {
    public lazy var assetTypeMaskView: UIView = {
        let assetTypeMaskView = UIView.init()
        assetTypeMaskView.isHidden = true
        assetTypeMaskView.layer.addSublayer(assetTypeMaskLayer)
        return assetTypeMaskView
    }()
    public lazy var assetTypeMaskLayer: CAGradientLayer = {
        let layer = CAGradientLayer.init()
        layer.contentsScale = UIScreen.main.scale
        let blackColor = UIColor.black
        layer.colors = [blackColor.withAlphaComponent(0).cgColor,
                        blackColor.withAlphaComponent(0.15).cgColor,
                        blackColor.withAlphaComponent(0.35).cgColor,
                        blackColor.withAlphaComponent(0.6).cgColor]
        layer.startPoint = CGPoint(x: 0, y: 0)
        layer.endPoint = CGPoint(x: 0, y: 1)
        layer.locations = [0.15, 0.35, 0.6, 0.9]
        layer.borderWidth = 0.0
        return layer
    }()
    public lazy var assetTypeLb: UILabel = {
        let assetTypeLb = UILabel.init()
        assetTypeLb.font = UIFont.hx_mediumPingFang(size: 14)
        assetTypeLb.textColor = .white
        assetTypeLb.textAlignment = .right
        return assetTypeLb
    }()
    public lazy var videoIcon: UIImageView = {
        let videoIcon = UIImageView.init(image: UIImage.hx_named(named: "hx_picker_cell_video_icon"))
        videoIcon.hx_size = videoIcon.image?.size ?? CGSize.zero
        videoIcon.isHidden = true
        return videoIcon
    }()
    
    public lazy var disableMaskLayer: CALayer = {
        let disableMaskLayer = CALayer.init()
        disableMaskLayer.backgroundColor = UIColor.white.withAlphaComponent(0.6).cgColor
        disableMaskLayer.frame = bounds
        disableMaskLayer.isHidden = true
        return disableMaskLayer
    }()
    open override var photoAsset: HXPHAsset? {
        didSet {
            switch photoAsset?.mediaSubType {
            case .imageAnimated:
                assetTypeLb.text = "GIF"
                assetTypeMaskView.isHidden = false
                break
            case .livePhoto:
                assetTypeLb.text = "Live"
                assetTypeMaskView.isHidden = false
                break
            case .video, .localVideo:
                assetTypeLb.text = photoAsset?.videoTime
                assetTypeMaskView.isHidden = false
                break
            default:
                assetTypeLb.text = nil
                assetTypeMaskView.isHidden = true
            }
            videoIcon.isHidden = photoAsset?.mediaType != .video
        }
    }
    
    public lazy var selectMaskLayer: CALayer = {
        let selectMaskLayer = CALayer.init()
        selectMaskLayer.backgroundColor = UIColor.black.withAlphaComponent(0.6).cgColor
        selectMaskLayer.frame = bounds
        selectMaskLayer.isHidden = true
        return selectMaskLayer
    }()
    open override var canSelect: Bool {
        didSet {
            // 禁用遮罩
            setupDisableMask()
        }
    }
    open override func initView() {
        super.initView()
        imageView.addSubview(assetTypeMaskView)
        imageView.layer.addSublayer(selectMaskLayer)
        contentView.addSubview(assetTypeLb)
        contentView.addSubview(videoIcon)
        contentView.layer.addSublayer(disableMaskLayer)
    }
    
    /// 设置禁用遮罩
    open func setupDisableMask() {
        disableMaskLayer.isHidden = canSelect
    }
    /// 设置高亮遮罩
    open func setupHighlightedMask() {
        if let selected = photoAsset?.isSelected {
            if !selected {
                selectMaskLayer.isHidden = !isHighlighted
            }
        }
    }
    open override func layoutView() {
        super.layoutView()
        selectMaskLayer.frame = imageView.bounds
        disableMaskLayer.frame = imageView.bounds
        assetTypeMaskView.frame = CGRect(x: 0, y: imageView.hx_height - 25, width: hx_width, height: 25)
        assetTypeMaskLayer.frame = assetTypeMaskView.bounds
        assetTypeLb.frame = CGRect(x: 0, y: hx_height - 19, width: hx_width - 5, height: 18)
        videoIcon.hx_x = 5
        videoIcon.hx_y = hx_height - videoIcon.hx_height - 5
        assetTypeLb.hx_centerY = videoIcon.hx_centerY
    }
    
    open override var isHighlighted: Bool {
        didSet {
            setupHighlightedMask()
        }
    }
}

open class HXPHPickerSelectableViewCell : HXPHPickerViewCell {
    public lazy var selectControl: HXPHPickerSelectBoxView = {
        let selectControl = HXPHPickerSelectBoxView.init()
        selectControl.backgroundColor = .clear
        selectControl.addTarget(self, action: #selector(didSelectControlClick(control:)), for: .touchUpInside)
        return selectControl
    }()
    
    open override var photoAsset: HXPHAsset? {
        didSet {
            if let photoAsset = photoAsset {
                updateSelectedState(isSelected: photoAsset.isSelected, animated: false)
            }
        }
    }
    open override func configColor() {
        super.configColor()
        if let config = config {
            selectControl.config = config.selectBox
        }
    }
    open override func initView() {
        super.initView()
        contentView.addSubview(selectControl)
        contentView.layer.addSublayer(disableMaskLayer)
    }
    
    /// 选择框点击事件
    /// - Parameter control: 选择框
    @objc open func didSelectControlClick(control: HXPHPickerSelectBoxView) {
        delegate?.cell?(didSelectControl: self, isSelected: control.isSelected)
    }
    open override func updateSelectedState(isSelected: Bool, animated: Bool) {
        if let photoAsset = photoAsset, let config = config {
            if Int(selectedTitle) == photoAsset.selectIndex + 1 && selectControl.isSelected == isSelected {
                return
            }
            selectedTitle = String(photoAsset.selectIndex + 1)
            let boxWidth = config.selectBox.size.width
            let boxHeight = config.selectBox.size.height
            if isSelected {
                selectMaskLayer.isHidden = false
                if config.selectBox.type == .number {
                    let text = selectedTitle
                    let font = UIFont.hx_mediumPingFang(size: config.selectBox.titleFontSize)
                    let textHeight = text.hx_stringHeight(ofFont: font, maxWidth: boxWidth)
                    var textWidth = text.hx_stringWidth(ofFont: font, maxHeight: textHeight)
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
        selectControl.frame = CGRect(x: hx_width - rightMargin - width, y: topMargin, width: width, height: height)
    }
    
    open override func layoutView() {
        super.layoutView()
        if selectControl.hx_width != hx_width - 5 - selectControl.hx_width {
            updateSelectControlSize(width: selectControl.hx_width, height: selectControl.hx_height)
        }
    }
}
