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
    
    /// iCloud标示
    public lazy var iCloudMarkView: UIImageView = {
        let view = UIImageView(image: "hx_picker_photo_icloud_mark".image)
        view.size = view.image?.size ?? .zero
        view.isHidden = true
        return view
    }()
    
    /// 资源类型标签背景
    public lazy var assetTypeMaskView: UIView = {
        let assetTypeMaskView = UIView()
        assetTypeMaskView.isHidden = true
        assetTypeMaskView.layer.addSublayer(assetTypeMaskLayer)
        return assetTypeMaskView
    }()
    
    /// 资源类型标签背景
    public lazy var assetTypeMaskLayer: CAGradientLayer = {
        let layer = PhotoTools.getGradientShadowLayer(false)
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
        let disableMaskLayer = CALayer()
        disableMaskLayer.backgroundColor = UIColor.white.withAlphaComponent(0.6).cgColor
        disableMaskLayer.isHidden = true
        return disableMaskLayer
    }()
    
    /// 获取视频时长时的 AVAsset 对象
    var videoDurationAsset: AVAsset?
    
    /// 资源对象
    open override var photoAsset: PhotoAsset! {
        didSet {
            cancelGetVideoDuration()
            setupState()
        }
    }
    
    open override func requestICloudStateCompletion(_ inICloud: Bool) {
        super.requestICloudStateCompletion(inICloud)
        self.inICloud = inICloud
        iCloudMarkView.isHidden = !inICloud
        setupDisableMask()
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
        photoView.addSubview(assetTypeMaskView)
        photoView.layer.addSublayer(selectMaskLayer)
        contentView.addSubview(assetTypeLb)
        contentView.addSubview(assetTypeIcon)
        contentView.addSubview(assetEditMarkIcon)
        contentView.layer.addSublayer(disableMaskLayer)
        contentView.addSubview(iCloudMarkView)
    }
    
    /// 触发选中回调
    open func selectedAction(_ isSelected: Bool) {
        delegate?.cell(self, didSelectControl: isSelected)
    }
    
    /// 设置禁用遮罩
    open func setupDisableMask() {
        if inICloud {
            disableMaskLayer.isHidden = false
            return
        }
        disableMaskLayer.isHidden = canSelect
    }
    /// 布局
    open override func layoutView() {
        super.layoutView()
        iCloudMarkView.x = width - iCloudMarkView.width - 5
        iCloudMarkView.y = 5
        
        selectMaskLayer.frame = photoView.bounds
        disableMaskLayer.frame = photoView.bounds
        assetTypeMaskView.frame = CGRect(x: 0, y: photoView.height - 25, width: width, height: 25)
        assetTypeMaskLayer.frame = CGRect(
            x: 0,
            y: -5,
            width: assetTypeMaskView.width,
            height: assetTypeMaskView.height + 5
        )
        assetTypeLb.frame = CGRect(x: 0, y: height - 19, width: width - 5, height: 18)
        assetTypeIcon.size = assetTypeIcon.image?.size ?? .zero
        assetTypeIcon.x = 5
        assetTypeIcon.y = height - assetTypeIcon.height - 5
        assetTypeLb.centerY = assetTypeIcon.centerY
        assetEditMarkIcon.size = assetEditMarkIcon.image?.size ?? .zero
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
        guard let photoAsset = photoAsset else { return }
        if !photoAsset.isSelected {
            selectMaskLayer.isHidden = !isHighlighted
        }
    }
    
    open override func requestThumbnailCompletion(_ image: UIImage?) {
        super.requestThumbnailCompletion(image)
        if !didLoadCompletion {
            didLoadCompletion = true
            setupState()
        }
    }
    
    open override func cancelICloudRequest() {
        super.cancelICloudRequest()
        iCloudMarkView.isHidden = true
    }
    private var didLoadCompletion: Bool = false
    
    deinit {
        disableMaskLayer.backgroundColor = nil
    }
}

// MARK: request
extension PhotoPickerViewCell {
    
    func cancelGetVideoDuration() {
        if let avAsset = videoDurationAsset {
            avAsset.cancelLoading()
            videoDurationAsset = nil
        }
    }
}

// MARK: private
extension PhotoPickerViewCell {
    
    private func setupState() {
        if !didLoadCompletion {
            return
        }
        if photoAsset.isGifAsset {
            assetTypeLb.text = "GIF"
            assetTypeMaskView.isHidden = false
        }else if photoAsset.mediaSubType.isVideo {
            if let videoTime = photoAsset.videoTime {
                assetTypeLb.text = videoTime
            }else {
                assetTypeLb.text = nil
                videoDurationAsset = PhotoTools.getVideoDuration(for: photoAsset) { [weak self] (asset, duration) in
                    guard let self = self else { return }
                    if self.photoAsset == asset {
                        self.assetTypeLb.text = asset.videoTime
                        self.videoDurationAsset = nil
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
        }else if photoAsset.mediaSubType == .livePhoto ||
                    photoAsset.mediaSubType == .localLivePhoto {
            assetTypeLb.text = "Live"
            assetTypeMaskView.isHidden = false
        }else {
            assetTypeLb.text = nil
            assetTypeMaskView.isHidden = true
        }
        assetEditMarkIcon.isHidden = true
        if photoAsset.mediaType == .photo {
            #if HXPICKER_ENABLE_EDITOR
            if let photoEdit = photoAsset.photoEdit {
                assetTypeLb.text = photoEdit.imageType == .gif ? "GIF" : nil
                assetTypeMaskView.isHidden = false
                assetEditMarkIcon.isHidden = false
            }
            #endif
        }
        assetTypeIcon.isHidden = photoAsset.mediaType != .video
    }
}
