//
//  PhotoPickerSelectableViewCell.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/3/12.
//

import UIKit
import PhotosUI

open class PhotoPickerSelectableViewCell: PhotoPickerViewCell {
    
    /// 选择按钮
    public var selectControl: SelectBoxView!
    
    public private(set) var livePhotoView: PHLivePhotoView?
    public private(set) var livePhotoButton: UIButton?
    public private(set) var livePhotoRequestID: PHLivePhotoRequestID?
    public private(set) var livePhotoIsPlaying: Bool = false
    
    /// 配置颜色
    open override func configColor() {
        super.configColor()
        selectControl.config = config.selectBox
    }
    
    /// 添加视图
    open override func initView() {
        super.initView()
        selectControl = SelectBoxView(.init())
        selectControl.isHidden = true
        selectControl.backgroundColor = .clear
        selectControl.addTarget(self, action: #selector(didSelectControlClick(control:)), for: .touchUpInside)
        contentView.addSubview(selectControl)
        
        contentView.layer.addSublayer(disableMaskLayer)
        contentView.addSubview(iCloudMarkView)
    }
    
    private var didLoadCompletion: Bool = false
    
    open override func requestThumbnailImage(targetWidth: CGFloat) {
        if didLoadCompletion {
            if !inICloud {
                selectControl.isHidden = false
            }
        }
        super.requestThumbnailImage(targetWidth: targetWidth)
    }
    
    open override func requestThumbnailCompletion(_ image: UIImage?) {
        super.requestThumbnailCompletion(image)
        if !didLoadCompletion {
            if !inICloud {
                selectControl.isHidden = false
            }
            didLoadCompletion = true
        }
    }
    
    open override func requestICloudStateCompletion(_ inICloud: Bool) {
        super.requestICloudStateCompletion(inICloud)
        selectControl.isHidden = inICloud
        selectControl.isEnabled = !inICloud
    }
    
    open func requestLivePhoto(isPlay: Bool) {
        guard photoAsset.mediaSubType.isLivePhoto,
              PhotoManager.shared.thumbnailLoadMode == .complete else {
            return
        }
        cancelLivePhotoRequest()
        livePhotoRequestID = photoAsset.requestLivePhoto(targetSize: size, iCloudHandler: nil, progressHandler: nil) { [weak self] photoAsset, livePhoto, _ in
            guard let self, self.photoAsset == photoAsset else {
                return
            }
            self.livePhotoView?.livePhoto = livePhoto
            if isPlay {
                self.livePhotoView?.startPlayback(with: .full)
            }
        } failure: { _, _, _ in
            
        }
    }
    
    /// 选择框点击事件
    /// - Parameter control: 选择框
    @objc open func didSelectControlClick(control: SelectBoxView) {
        if inICloud {
            return
        }
        selectedAction(selectControl.isSelected)
        
        createLivePhotoViewIfNeeded()
        if let livePhotoView = self.livePhotoView {
            if selectControl.isSelected {
                if livePhotoView.livePhoto == nil {
                    requestLivePhoto(isPlay: true)
                }else {
                    livePhotoView.startPlayback(with: .full)
                }
            }else {
                if livePhotoView.livePhoto == nil {
                    cancelLivePhotoRequest()
                }
                if livePhotoIsPlaying {
                    removeLivePhotoView()
                }
            }
        }
    }
    
    /// 更新选择状态
    open override func updateSelectedState(isSelected: Bool, animated: Bool) {
        super.updateSelectedState(isSelected: isSelected, animated: animated)
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
        if photoAsset.mediaSubType.isLivePhoto {
            if !isSelected, livePhotoIsPlaying {
                removeLivePhotoView()
            }
            setupLivePhotoState()
        }else {
            livePhotoButton?.isHidden = true
            livePhotoView?.isHidden = true
            removeLivePhotoView()
        }
    }
    
    /// 更新选择框大小
    open func updateSelectControlSize(width: CGFloat, height: CGFloat) {
        let topMargin = config.selectBoxTopMargin
        let rightMargin = config.selectBoxRightMargin
        let rect = CGRect(x: self.width - rightMargin - width, y: topMargin, width: width, height: height)
        if selectControl.hxPicker_frame.equalTo(rect) {
            return
        }
        if let photoAsset = photoAsset, photoAsset.isScrolling {
            let x = selectControl.x
            selectControl.hxPicker_frame = rect
            selectControl.hxPicker_x = x
        }else {
            selectControl.hxPicker_frame = rect
        }
    }
    
    open override func cancelRequest() {
        super.cancelRequest()
        cancelLivePhotoRequest()
    }
    
    open func cancelLivePhotoRequest() {
        livePhotoView?.stopPlayback()
        
        guard let livePhotoRequestID else {
            return
        }
        PHImageManager.default().cancelImageRequest(livePhotoRequestID)
        self.livePhotoRequestID = nil
    }
    
    open override func layoutView() {
        super.layoutView()
        livePhotoView?.frame = bounds
        updateSelectControlSize()
    }
    
    open override func setupState() {
        super.setupState()
        livePhotoButton?.isHidden = true
        livePhotoView?.isHidden = true
        if photoAsset.mediaSubType.isLivePhoto {
            livePhotoIsPlaying = false
            livePhotoView?.livePhoto = nil
            setupLivePhotoState()
        }else if photoAsset.mediaSubType.isVideo {
            setupAssetTypeFrame()
        }
    }
    
    open override func setupAssetTypeFrame() {
        super.setupAssetTypeFrame()
        livePhotoButton?.size = .init(width: 50, height: 20)
        livePhotoButton?.hxPicker_x = assetTypeIcon.hxPicker_x
        livePhotoButton?.hxPicker_center.y = assetTypeIcon.hxPicker_center.y
    }
    
    open func setupLivePhotoState() {
        if photoAsset.isEdited {
            return
        }
        assetTypeIcon.image = .imageResource.picker.photoList.cell.livePhoto.image
        assetTypeMaskView.isHidden = false
        if photoAsset.isSelected {
            createLivePhotoButtonIfNeeded()
            if let livePhotoButton = livePhotoButton {
                livePhotoButton.isHidden = false
                livePhotoButton.isSelected = photoAsset.isDisableLivePhoto
                livePhotoButton.imageView?.tintColor = livePhotoButton.isSelected ? .white : .init(hexString: "#171717")
                assetTypeLb.text = ""
            }
        }else {
            livePhotoButton?.isHidden = true
            assetTypeIcon.isHidden = false
            assetTypeLb.text = .textPhotoList.cell.LivePhotoTitle.text
            setupAssetTypeFrame()
        }
    }
    
    open func createLivePhotoViewIfNeeded() {
        guard livePhotoView == nil && config.isPlayLivePhoto && photoAsset.mediaSubType.isLivePhoto && !photoAsset.isEdited && !photoAsset.isDisableLivePhoto else {
            return
        }
        let livePhotoView = PHLivePhotoView()
        livePhotoView.isMuted = true
        livePhotoView.playbackGestureRecognizer.isEnabled = false
        livePhotoView.delegate = self
        livePhotoView.isHidden = true
        contentView.insertSubview(livePhotoView, aboveSubview: photoView)
        self.livePhotoView = livePhotoView
        livePhotoView.frame = bounds
    }
    
    open func createLivePhotoButtonIfNeeded() {
        guard livePhotoButton == nil && config.isShowLivePhotoControl && photoAsset.mediaSubType.isLivePhoto && !photoAsset.isEdited else {
            return
        }
        let livePhotoButton = UIButton(type: .custom)
        livePhotoButton.setTitle(.textManager.picker.photoList.cell.LivePhotoTitle.text, for: .normal)
        livePhotoButton.setTitleColor(.init(hexString: "#171717"), for: .normal)
        livePhotoButton.setTitleColor(.white, for: .selected)
        livePhotoButton.titleLabel?.font = .mediumPingFang(ofSize: 12)
        livePhotoButton.setImage(.imageResource.picker.preview.livePhoto.image?.withRenderingMode(.alwaysTemplate), for: .normal)
        livePhotoButton.setImage(.imageResource.picker.preview.livePhotoDisable.image?.withRenderingMode(.alwaysTemplate), for: .selected)
        livePhotoButton.setBackgroundImage(.image(for: .white.withAlphaComponent(0.9), havingSize: .init(width: 50, height: 20), radius: 10), for: .normal)
        livePhotoButton.setBackgroundImage(.image(for: .init(hexString: "404040"), havingSize: .init(width: 50, height: 20), radius: 10), for: .selected)
        livePhotoButton.imageView?.tintColor = .init(hexString: "#171717")
        livePhotoButton.titleEdgeInsets = .init(top: 0, left: 0, bottom: 0, right: 1)
        livePhotoButton.imageEdgeInsets = .init(top: 0, left: 0, bottom: 0, right: 1)
        livePhotoButton.addTarget(self, action: #selector(didLivePhotoButtonClick), for: .touchUpInside)
        livePhotoButton.isHidden = true
        contentView.addSubview(livePhotoButton)
        self.livePhotoButton = livePhotoButton
        setupAssetTypeFrame()
    }
    
    func updateSelectControlSize() {
        updateSelectControlSize(
            width: selectControl.width,
            height: selectControl.height
        )
    }
    
    @objc
    private func didLivePhotoButtonClick() {
        guard let livePhotoButton = self.livePhotoButton else {
            return
        }
        livePhotoButton.isSelected = !livePhotoButton.isSelected
        livePhotoButton.imageView?.tintColor = livePhotoButton.isSelected ? .white : .init(hexString: "#171717")
        photoAsset.isDisableLivePhoto = livePhotoButton.isSelected
        photoAsset.pFileSize = nil
        delegate?.pickerCell(livePhotoContorlDidChange: self)
        
        createLivePhotoViewIfNeeded()
        if let livePhotoView = livePhotoView {
            if livePhotoView.livePhoto == nil {
                requestLivePhoto(isPlay: !livePhotoButton.isSelected)
            }else {
                if livePhotoButton.isSelected {
                    livePhotoView.stopPlayback()
                }else {
                    livePhotoView.startPlayback(with: .full)
                }
            }
        }
    }
    
    private func removeLivePhotoView() {
        guard let livePhotoView = self.livePhotoView else {
            return
        }
        // 结束播放时移除，避免占用内存或影响滑动帧率
        livePhotoView.stopPlayback()
        livePhotoView.removeFromSuperview()
        self.livePhotoView = nil
    }
    
}

extension PhotoPickerSelectableViewCell: PHLivePhotoViewDelegate {
    
    open func livePhotoView(_ livePhotoView: PHLivePhotoView, willBeginPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle) {
        assert(livePhotoView == self.livePhotoView)
        livePhotoIsPlaying = true
        livePhotoView.layer.removeAllAnimations()
        livePhotoView.isHidden = false
        livePhotoView.alpha = 0
        UIView.animate(withDuration: 0.2) {
            livePhotoView.alpha = 1
        }
    }
    
    open func livePhotoView(_ livePhotoView: PHLivePhotoView, didEndPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle) {
        assert(livePhotoView == self.livePhotoView)
        livePhotoIsPlaying = false
        if livePhotoView.isHidden {
            removeLivePhotoView()
            return
        }
        livePhotoView.alpha = 1
        UIView.animate(withDuration: 0.25) {
            livePhotoView.alpha = 0
        } completion: { _ in
            self.removeLivePhotoView()
        }
    }
    
}
