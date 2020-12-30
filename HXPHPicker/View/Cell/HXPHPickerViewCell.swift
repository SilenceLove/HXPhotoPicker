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
    public var requestID: PHImageRequestID?
    
    open var photoAsset: HXPHAsset? {
        didSet {
            if let photoAsset = photoAsset {
                updateSelectedState(isSelected: photoAsset.isSelected, animated: false)
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
        requestID = photoAsset?.requestThumbnailImage(targetWidth: width * 2, completion: { (image, photoAsset, info) in
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
        if let photoAsset = photoAsset {
            selectedTitle = isSelected ? String(photoAsset.selectIndex + 1) : "0"
        }
    }
    /// 布局，重写此方法修改布局
    open func layoutView() {
        imageView.frame = bounds
    }
    
    /// 取消请求资源图片
    public func cancelRequest() {
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
    /// 资源类型标签背景
    public lazy var assetTypeMaskView: UIView = {
        let assetTypeMaskView = UIView.init()
        assetTypeMaskView.isHidden = true
        assetTypeMaskView.layer.addSublayer(assetTypeMaskLayer)
        return assetTypeMaskView
    }()
    
    /// 资源类型标签背景
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
    
    /// 资源类型标签
    public lazy var assetTypeLb: UILabel = {
        let assetTypeLb = UILabel.init()
        assetTypeLb.font = UIFont.mediumPingFang(ofSize: 14)
        assetTypeLb.textColor = .white
        assetTypeLb.textAlignment = .right
        return assetTypeLb
    }()
    
    /// 视频图标
    public lazy var videoIcon: UIImageView = {
        let videoIcon = UIImageView.init(image: UIImage.image(for: "hx_picker_cell_video_icon"))
        videoIcon.size = videoIcon.image?.size ?? CGSize.zero
        videoIcon.isHidden = true
        return videoIcon
    }()
    
    /// 禁用遮罩
    public lazy var disableMaskLayer: CALayer = {
        let disableMaskLayer = CALayer.init()
        disableMaskLayer.backgroundColor = UIColor.white.withAlphaComponent(0.6).cgColor
        disableMaskLayer.frame = bounds
        disableMaskLayer.isHidden = true
        return disableMaskLayer
    }()
    
    /// 资源对象
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
    
    /// 选中遮罩
    public lazy var selectMaskLayer: CALayer = {
        let selectMaskLayer = CALayer.init()
        selectMaskLayer.backgroundColor = UIColor.black.withAlphaComponent(0.6).cgColor
        selectMaskLayer.frame = bounds
        selectMaskLayer.isHidden = true
        return selectMaskLayer
    }()
    
    /// 是否可以选择
    open override var canSelect: Bool {
        didSet {
            // 禁用遮罩
            setupDisableMask()
        }
    }
    
    /// 添加视图
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
    /// 布局
    open override func layoutView() {
        super.layoutView()
        selectMaskLayer.frame = imageView.bounds
        disableMaskLayer.frame = imageView.bounds
        assetTypeMaskView.frame = CGRect(x: 0, y: imageView.height - 25, width: width, height: 25)
        assetTypeMaskLayer.frame = assetTypeMaskView.bounds
        assetTypeLb.frame = CGRect(x: 0, y: height - 19, width: width - 5, height: 18)
        videoIcon.x = 5
        videoIcon.y = height - videoIcon.height - 5
        assetTypeLb.centerY = videoIcon.centerY
    }
    
    /// 设置高亮时的遮罩
    open override var isHighlighted: Bool {
        didSet {
            setupHighlightedMask()
        }
    }
    
    /// 设置高亮遮罩
    open func setupHighlightedMask() {
        if let selected = photoAsset?.isSelected {
            if !selected {
                selectMaskLayer.isHidden = !isHighlighted
            }
        }
    }
}

open class HXPHPickerSelectableViewCell : HXPHPickerViewCell {
    
    /// 选择按钮
    public lazy var selectControl: HXPHPickerSelectBoxView = {
        let selectControl = HXPHPickerSelectBoxView.init()
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
    }
    
    /// 选择框点击事件
    /// - Parameter control: 选择框
    @objc open func didSelectControlClick(control: HXPHPickerSelectBoxView) {
        delegate?.cell?(didSelectControl: self, isSelected: control.isSelected)
    }
    
    /// 更新选择状态
    open override func updateSelectedState(isSelected: Bool, animated: Bool) {
        super.updateSelectedState(isSelected: isSelected, animated: animated)
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
                    let font = UIFont.mediumPingFang(ofSize: config.selectBox.titleFontSize)
                    let textHeight = text.height(ofFont: font, maxWidth: boxWidth)
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
        selectControl.frame = rect
    }
    
    open override func layoutView() {
        super.layoutView()
        updateSelectControlSize(width: selectControl.width, height: selectControl.height)
    }
}
