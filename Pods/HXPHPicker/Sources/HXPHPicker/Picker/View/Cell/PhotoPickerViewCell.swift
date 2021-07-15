//
//  PhotoPickerViewCell.swift
//  照片选择器-Swift
//
//  Created by Silence on 2019/6/29.
//  Copyright © 2019年 Silence. All rights reserved.
//

import UIKit
import Photos

open class PhotoPickerViewCell: PhotoPickerBaseViewCell {
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
    
    /// 资源类型图标
    public lazy var assetTypeIcon: UIImageView = {
        let assetTypeIcon = UIImageView.init(image: UIImage.image(for: "hx_picker_cell_video_icon"))
        assetTypeIcon.isHidden = true
        return assetTypeIcon
    }()
    
    /// 资源编辑标示
    public lazy var assetEditMarkIcon: UIImageView = {
        let assetEditMarkIcon = UIImageView.init(image: UIImage.image(for: "hx_picker_cell_photo_edit_icon"))
        assetEditMarkIcon.isHidden = true
        return assetEditMarkIcon
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
    open override var photoAsset: PhotoAsset! {
        didSet {
            switch photoAsset.mediaSubType {
            case .imageAnimated, .localGifImage:
                assetTypeLb.text = "GIF"
                assetTypeMaskView.isHidden = false
            case .networkImage(let isGif):
                assetTypeLb.text = isGif ? "GIF" : nil
                assetTypeMaskView.isHidden = !isGif
            case .livePhoto:
                assetTypeLb.text = "Live"
                assetTypeMaskView.isHidden = false
            case .video, .localVideo, .networkVideo:
                if let videoTime = photoAsset.videoTime {
                    assetTypeLb.text = videoTime
                }else {
                    assetTypeLb.text = nil
                    PhotoTools.getVideoDuration(for: photoAsset) { [weak self] (asset, duration) in
                        guard let self = self else { return }
                        if self.photoAsset == asset {
                            self.assetTypeLb.text = asset.videoTime
                        }
                    }
                }
                assetTypeMaskView.isHidden = false
//                #if HXPICKER_ENABLE_EDITOR
//                if photoAsset.videoEdit == nil {
//                    assetTypeIcon.image = UIImage.image(for: "hx_picker_cell_video_icon")
//                }else {
//                    assetTypeIcon.image = UIImage.image(for: "hx_picker_cell_video_edit_icon")
//                }
//                #endif
            default:
                assetTypeLb.text = nil
                assetTypeMaskView.isHidden = true
            }
            assetEditMarkIcon.isHidden = true
            if photoAsset.mediaType == .photo {
                #if HXPICKER_ENABLE_EDITOR
                if let photoEdit = photoAsset.photoEdit {
                    if photoEdit.imageType == .normal {
                        assetTypeLb.text = nil
                    }
                    assetEditMarkIcon.isHidden = false
                    assetTypeMaskView.isHidden = false
                }
                #endif
            }
            assetTypeIcon.isHidden = photoAsset.mediaType != .video
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
        contentView.addSubview(assetTypeIcon)
        contentView.addSubview(assetEditMarkIcon)
        contentView.layer.addSublayer(disableMaskLayer)
    }
    
    /// 触发选中回调
    open func selectedAction(_ isSelected: Bool) {
        delegate?.cell(self, didSelectControl: isSelected)
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
        assetTypeMaskLayer.frame = CGRect(x: 0, y: -5, width: assetTypeMaskView.width, height: assetTypeMaskView.height + 5)
        assetTypeLb.frame = CGRect(x: 0, y: height - 19, width: width - 5, height: 18)
        assetTypeIcon.size = assetTypeIcon.image?.size ?? CGSize.zero
        assetTypeIcon.x = 5
        assetTypeIcon.y = height - assetTypeIcon.height - 5
        assetTypeLb.centerY = assetTypeIcon.centerY
        assetEditMarkIcon.size = assetEditMarkIcon.image?.size ?? CGSize.zero
        assetEditMarkIcon.x = 5
        assetEditMarkIcon.y = height - assetEditMarkIcon.height - 5
    }
    
    /// 设置高亮时的遮罩
    open override var isHighlighted: Bool {
        didSet {
            setupHighlightedMask()
        }
    }
    
    /// 设置高亮遮罩
    open func setupHighlightedMask() {
        if !photoAsset.isSelected {
            selectMaskLayer.isHidden = !isHighlighted
        }
    }
}
