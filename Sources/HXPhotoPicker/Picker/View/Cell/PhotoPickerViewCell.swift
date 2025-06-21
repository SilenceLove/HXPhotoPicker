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
    public var iCloudMarkView: UIImageView!
    /// 资源类型标签背景
    public var assetTypeMaskView: UIView!
    /// 资源类型标签背景
    public var assetTypeMaskLayer: CAGradientLayer!
    /// 资源类型标签
    public var assetTypeLb: UILabel!
    /// 资源类型图标
    public var assetTypeIcon: UIImageView!
    /// 资源编辑标示
    public var assetEditMarkIcon: UIImageView!
    /// 禁用遮罩
    public var disableMaskLayer: CALayer!
    /// 选中遮罩
    public var selectMaskLayer: CALayer!
    
    public var syncICloudRequestID: PHImageRequestID?
    
    /// iCloud下载进度视图
    var loaddingView: PhotoLoadingView!
    /// 获取视频时长时的 AVAsset 对象
    var videoDurationAsset: AVAsset?
    
    /// 资源对象
    open override var photoAsset: PhotoAsset! {
        didSet {
            cancelGetVideoDuration()
            setupState()
        }
    }
    
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
        assetTypeMaskLayer = PhotoTools.getGradientShadowLayer(false)
        assetTypeMaskView = UIView()
        assetTypeMaskView.isHidden = true
        assetTypeMaskView.layer.addSublayer(assetTypeMaskLayer)
        photoView.addSubview(assetTypeMaskView)
        
        selectMaskLayer = CALayer()
        selectMaskLayer.backgroundColor = UIColor.black.withAlphaComponent(0.6).cgColor
        selectMaskLayer.hxPicker_frame = bounds
        selectMaskLayer.isHidden = true
        photoView.layer.addSublayer(selectMaskLayer)
        
        assetTypeLb = UILabel()
        assetTypeLb.font = .mediumPingFang(ofSize: 14)
        assetTypeLb.textColor = .white
        assetTypeLb.hxpicker_alignment = .right
        contentView.addSubview(assetTypeLb)
        
        assetTypeIcon = UIImageView(image: .imageResource.picker.photoList.cell.video.image)
        assetTypeIcon.isHidden = true
        contentView.addSubview(assetTypeIcon)
        
        assetEditMarkIcon = UIImageView(image: .imageResource.picker.photoList.cell.photoEdited.image)
        assetEditMarkIcon.isHidden = true
        contentView.addSubview(assetEditMarkIcon)
        
        disableMaskLayer = CALayer()
        disableMaskLayer.backgroundColor = UIColor.white.withAlphaComponent(0.6).cgColor
        disableMaskLayer.isHidden = true
        contentView.layer.addSublayer(disableMaskLayer)
        
        iCloudMarkView = UIImageView(image: .imageResource.picker.photoList.cell.iCloud.image)
        if let imageSize = iCloudMarkView.image?.size {
            iCloudMarkView.size = imageSize
        }
        iCloudMarkView.isHidden = true
        contentView.addSubview(iCloudMarkView)
        
        loaddingView = PhotoLoadingView(frame: .init(origin: .zero, size: size))
        loaddingView.isHidden = true
        contentView.addSubview(loaddingView)
    }
    
    open override func requestICloudStateCompletion(_ inICloud: Bool) {
        super.requestICloudStateCompletion(inICloud)
        self.inICloud = inICloud
        iCloudMarkView.isHidden = !inICloud
        setupDisableMask()
        if inICloud &&
            (photoAsset.downloadStatus == .downloading ||
             photoAsset.downloadStatus == .canceled) {
            syncICloud()
        }else {
            loaddingView.isHidden = true
            loaddingView.stopAnimating()
        }
    }
    
    /// 触发选中回调
    open func selectedAction(_ isSelected: Bool) {
        delegate?.pickerCell(self, didSelectControl: isSelected)
    }
    
    /// 设置禁用遮罩
    open func setupDisableMask() {
        if photoAsset.downloadStatus == .downloading {
            return
        }
        if inICloud {
            disableMaskLayer.isHidden = false
            return
        }
        disableMaskLayer.isHidden = canSelect
    }
    
    open func cancelSyncICloud() {
        guard let id = syncICloudRequestID else {
            return
        }
        loaddingView.isHidden = true
        loaddingView.stopAnimating()
        PHImageManager.default().cancelImageRequest(id)
        syncICloudRequestID = nil
    }
    
    open func checkICloundStatus(
        allowSyncPhoto: Bool
    ) -> Bool {
        guard let phAsset = photoAsset.phAsset,
              photoAsset.downloadStatus != .succeed else {
            return false
        }
        if photoAsset.mediaType == .photo && !allowSyncPhoto {
            return false
        }
        if phAsset.inICloud {
            if photoAsset.downloadStatus != .downloading {
                syncICloud()
            }
            return true
        }else {
            photoAsset.downloadStatus = .succeed
        }
        return false
    }
    
    open func syncICloud() {
        cancelSyncICloud()
        disableMaskLayer.isHidden = true
        loaddingView.isHidden = false
        loaddingView.startAnimating()
        syncICloudRequestID = photoAsset.syncICloud { [weak self] in
            guard let self = self, $0 == self.photoAsset else {
                return
            }
            self.syncICloudRequestID = $1
        } progressHandler: { [weak self] in
            guard let self = self, $0 == self.photoAsset else {
                return
            }
            if $1 > 0 {
                self.loaddingView.progress = $1
            }
        } completionHandler: { [weak self] in
            guard let self = self, $0 == self.photoAsset else {
                return
            }
            if $1 {
                self.requestICloudState()
                if self.photoAsset.mediaType == .video, self.photoAsset.videoTime == nil {
                    self.videoDurationAsset = self.photoAsset.getVideoDuration { [weak self] (asset, _) in
                        guard let self = self, self.photoAsset == asset else { return }
                        self.assetTypeLb.text = asset.videoTime
                        self.videoDurationAsset = nil
                        self.delegate?.pickerCell(videoRequestDurationCompletion: self)
                    }
                }
            }else {
                if $0.downloadStatus != .canceled {
                    self.disableMaskLayer.isHidden = false
                    self.loaddingView.isHidden = true
                    self.loaddingView.stopAnimating()
                }
            }
        }
    }
    
    /// 布局
    open override func layoutView() {
        super.layoutView()
        iCloudMarkView.hxPicker_x = width - iCloudMarkView.width - 5
        iCloudMarkView.y = 5
        
        assetTypeMaskView.hxPicker_frame = CGRect(x: 0, y: photoView.height - 25, width: width, height: 25)
        let assetTypeMakeFrame = CGRect(
            x: 0,
            y: -5,
            width: assetTypeMaskView.width,
            height: assetTypeMaskView.height + 5
        )
        var updateFrame = false
        if !assetTypeMaskLayer.frame.equalTo(assetTypeMakeFrame) {
            updateFrame = true
        }
        if !selectMaskLayer.frame.equalTo(photoView.bounds) {
            updateFrame = true
        }
        if !disableMaskLayer.frame.equalTo(photoView.bounds) {
            updateFrame = true
        }
        if updateFrame {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            assetTypeMaskLayer.hxPicker_frame = assetTypeMakeFrame
            selectMaskLayer.hxPicker_frame = photoView.bounds
            disableMaskLayer.hxPicker_frame = photoView.bounds
            CATransaction.commit()
        }
        loaddingView.hxPicker_frame = bounds
        setupAssetTypeFrame()
        if let imageSize = assetEditMarkIcon.image?.size {
            assetEditMarkIcon.size = imageSize
        }
        assetEditMarkIcon.hxPicker_x = 5
        assetEditMarkIcon.y = height - assetEditMarkIcon.height - 5
    }
    
    open func setupAssetTypeFrame() {
        assetTypeLb.hxPicker_frame = CGRect(x: 0, y: height - 19, width: width - 5, height: 18)
        if let imageSize = assetTypeIcon.image?.size {
            assetTypeIcon.size = imageSize
        }
        //备注：很多适配RTL的工程都会Hook调整alignment，因此该处根据当前的alignment来调整图标的位置（避免遮挡）
        let isAssetTypeLbInRight = assetTypeLb.hxpicker_alignment == .right
        assetTypeIcon.hxPicker_x = isAssetTypeLbInRight ? 5 : (width - assetTypeIcon.width - 5)
        assetTypeIcon.y = height - assetTypeIcon.height - 5
        assetTypeLb.centerY = assetTypeIcon.centerY
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
    
    open func setupState() {
        if !didLoadCompletion {
            return
        }
        assetTypeIcon.isHidden = true
        if photoAsset.isGifAsset {
            assetTypeLb.text = .textPhotoList.cell.gifTitle.text
            assetTypeMaskView.isHidden = false
        }else if photoAsset.mediaSubType.isVideo {
            assetTypeIcon.isHidden = false
            assetTypeIcon.image = .imageResource.picker.photoList.cell.video.image
            if let videoTime = photoAsset.videoTime {
                assetTypeLb.text = videoTime
            }else {
                assetTypeLb.text = nil
                videoDurationAsset = photoAsset.getVideoDuration { [weak self] (asset, _) in
                    guard let self = self, self.photoAsset == asset else { return }
                    self.assetTypeLb.text = asset.videoTime
                    self.videoDurationAsset = nil
                    self.delegate?.pickerCell(videoRequestDurationCompletion: self)
                }
            }
            assetTypeMaskView.isHidden = false
//            #if HXPICKER_ENABLE_EDITOR
//            if photoAsset.videoEditedResult == nil {
//                assetTypeIcon.image = .imageResource.picker.photoList.cell.video.image
//            }else {
//                assetTypeIcon.image = .imageResource.picker.photoList.cell.videoEdited.image
//            }
//            #endif
        }else if photoAsset.mediaSubType.isLivePhoto {
            assetTypeLb.text = .textPhotoList.cell.LivePhotoTitle.text
            assetTypeMaskView.isHidden = false
        }else if photoAsset.mediaSubType.isHDRPhoto {
            assetTypeLb.text = .textPhotoList.cell.HDRPhotoTitle.text
            assetTypeMaskView.isHidden = false
        }else {
            assetTypeLb.text = nil
            assetTypeMaskView.isHidden = true
        }
        assetEditMarkIcon.isHidden = true
        if photoAsset.mediaType == .photo {
            #if HXPICKER_ENABLE_EDITOR
            if let editedResult = photoAsset.editedResult {
                switch editedResult {
                case .image(let result, _):
                    assetTypeLb.text = result.imageType == .gif ? .textPhotoList.cell.gifTitle.text : nil
                    assetTypeMaskView.isHidden = false
                    assetEditMarkIcon.isHidden = false
                default:
                    break
                }
            }
            #endif
        }
    }
    
    open override func cancelICloudRequest() {
        super.cancelICloudRequest()
        iCloudMarkView.isHidden = true
    }
    
    private var didLoadCompletion: Bool = false
    
    deinit {
        disableMaskLayer.backgroundColor = nil
        cancelSyncICloud()
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
