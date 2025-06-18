//
//  PreviewLivePhotoViewCell.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/3/12.
//

import UIKit

class PreviewLivePhotoViewCell: PhotoPreviewViewCell, PhotoPreviewContentViewDelete {
    
    private var liveMarkControl: UIControl!
    private var liveMarkView: UIVisualEffectView!
    
    private var liveMarkImageView: UIImageView!
    private var liveMarkLabel: UILabel!
    
    private var liveMuteContainerView: UIVisualEffectView!
    private var liveMuteButton: UIButton!
    
    var livePhotoPlayType: PhotoPreviewViewController.PlayType = .once {
        didSet {
            scrollContentView.livePhotoPlayType = livePhotoPlayType
        }
    }

    var liveMarkConfig: PreviewViewConfiguration.LivePhotoMark? {
        didSet {
            configLiveMark()
        }
    }
    
    override var photoAsset: PhotoAsset! {
        didSet {
            configLiveMark()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        scrollContentView = PhotoPreviewContentLivePhotoView()
        scrollContentView.delegate = self
        initView()
        
        liveMarkControl = UIControl()
        liveMarkControl.layer.masksToBounds = true
        liveMarkControl.addTarget(self, action: #selector(didLiveMarkButtonClick), for: .touchUpInside)
        contentView.addSubview(liveMarkControl)
        
        liveMarkView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        liveMarkView.isUserInteractionEnabled = false
        liveMarkControl.addSubview(liveMarkView)
        
        liveMarkImageView = UIImageView()
        liveMarkView.contentView.addSubview(liveMarkImageView)
        
        liveMarkLabel = UILabel()
        liveMarkLabel.text = .textManager.picker.preview.livePhotoTitle.text
        liveMarkLabel.textAlignment = .center
        liveMarkLabel.font = .mediumPingFang(ofSize: 14)
        liveMarkView.contentView.addSubview(liveMarkLabel)
        
        liveMuteContainerView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        liveMuteContainerView.layer.masksToBounds = true
        contentView.addSubview(liveMuteContainerView)
        
        liveMuteButton = UIButton(type: .custom)
        liveMuteButton.addTarget(self, action: #selector(didLiveMuteButtonClick), for: .touchUpInside)
        liveMuteContainerView.contentView.addSubview(liveMuteButton)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupLiveMarkFrame()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                configLiveMark()
            }
        }
    }
    
    func contentView(requestSucceed contentView: PhotoPreviewContentViewProtocol) {
        delegate?.cell(requestSucceed: self)
    }
    func contentView(requestFailed contentView: PhotoPreviewContentViewProtocol) {
        delegate?.cell(requestFailed: self)
    }
    
    func contentView(showLivePhotoMark contentView: PhotoPreviewContentViewProtocol) {
        showMark()
    }
    func contentView(hideLivePhotoMark contentView: PhotoPreviewContentViewProtocol) {
        hideMark()
    }
    
    private func configLiveMark() {
        guard photoAsset != nil else {
            return
        }
#if HXPICKER_ENABLE_EDITOR
        guard photoAsset.photoEditedResult == nil else {
            liveMarkControl.isHidden = true
            liveMuteContainerView.isHidden = true
            return
        }
#endif
        guard photoAsset.mediaSubType.isLivePhoto else {
            liveMarkControl.isHidden = true
            liveMuteContainerView.isHidden = true
            return
        }
        guard let liveMarkConfig = liveMarkConfig else {
            liveMarkControl.isHidden = true
            liveMuteContainerView.isHidden = true
            return
        }
        if liveMarkConfig.allowShow {
            liveMarkControl.isHidden = false
            liveMarkView.effect = UIBlurEffect(
                style: PhotoManager.isDark ? liveMarkConfig.blurDarkStyle : liveMarkConfig.blurStyle
            )
            liveMarkImageView.tintColor = PhotoManager.isDark ? liveMarkConfig.imageDarkColor : liveMarkConfig.imageColor
            liveMarkLabel.textColor = PhotoManager.isDark ? liveMarkConfig.textDarkColor : liveMarkConfig.textColor
            
            let image = photoAsset.isDisableLivePhoto ? UIImage.imageResource.picker.preview.livePhotoDisable.image : UIImage.imageResource.picker.preview.livePhoto.image
            liveMarkImageView.image = image?.withRenderingMode(.alwaysTemplate)
        } else {
            liveMarkControl.isHidden = true
        }
        
        if liveMarkConfig.allowMutedShow {
            liveMuteContainerView.isHidden = false
            liveMuteContainerView.effect = UIBlurEffect(
                style: PhotoManager.isDark ? liveMarkConfig.blurDarkStyle : liveMarkConfig.blurStyle
            )
            liveMuteButton.setImage(.imageResource.picker.preview.livePhotoMutedDisable.image?.withRenderingMode(.alwaysTemplate), for: .normal)
            liveMuteButton.setImage(.imageResource.picker.preview.livePhotoMuted.image?.withRenderingMode(.alwaysTemplate), for: .selected)
            liveMuteButton.tintColor = PhotoManager.isDark ? liveMarkConfig.mutedImageDarkColor : liveMarkConfig.mutedImageColor
            liveMuteButton.isSelected = photoAsset.isLivePhotoMuted
        } else {
            liveMuteContainerView.isHidden = true
        }
      
        self.setNeedsLayout()
    }
    
    private func setupLiveMarkFrame() {
        guard let liveMarkConfig = liveMarkConfig else {
            return
        }
        let safeAreaInsets = {
            if #available(iOS 11.0, *) {
                return self.safeAreaInsets
            } else {
                return UIEdgeInsets(top: UIDevice.navigationBarHeight, left: 0, bottom: 0, right: 0)
            }
        }()
        let spacing = 10.0
       
        if liveMarkConfig.allowShow {
            let contentInset = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
            let imageTextSpacing = 2.0
            let imageSize = liveMarkImageView.sizeThatFits(.zero)
            let textSize = liveMarkLabel.sizeThatFits(.zero)
            liveMarkControl.frame = CGRect(
                x: safeAreaInsets.left + spacing,
                y: safeAreaInsets.top + spacing,
                width: imageSize.width + textSize.width + spacing + contentInset.left + contentInset.right,
                height: max(imageSize.height, textSize.height) + contentInset.top + contentInset.bottom
            )
            liveMarkControl.layer.cornerRadius = liveMarkControl.frame.height / 2.0
            liveMarkView.frame = liveMarkControl.bounds
            
            liveMarkImageView.frame = CGRect(
                x: contentInset.left,
                y: (liveMarkView.frame.height - imageSize.height) / 2.0,
                width: imageSize.width,
                height: imageSize.height
            )
            liveMarkLabel.frame = CGRect(
                x: liveMarkImageView.frame.maxX + imageTextSpacing,
                y: (liveMarkView.frame.height - textSize.height) / 2.0,
                width: textSize.width,
                height: textSize.height
            )
        }
        
        if liveMarkConfig.allowMutedShow {
            let contentInset = UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
            let buttonSize = liveMuteButton.currentImage?.size ?? .zero
            liveMuteContainerView.frame = CGRect(
                x: self.contentView.bounds.width - safeAreaInsets.right - buttonSize.width - spacing - contentInset.left - contentInset.right,
                y: safeAreaInsets.top + spacing,
                width: buttonSize.width + contentInset.left + contentInset.right,
                height: buttonSize.height + contentInset.top + contentInset.bottom
            )
            liveMuteContainerView.layer.cornerRadius = liveMuteContainerView.frame.height / 2.0
            liveMuteButton.frame = CGRect(
                x: 0,
                y: 0,
                width: liveMuteContainerView.frame.width,
                height: liveMuteContainerView.frame.height
            )
        }
    }
    
    private func showMark() {
        if scrollContentView.isBacking ||
            statusBarShouldBeHidden {
            return
        }
        guard let superview = superview, superview is UICollectionView else {
            return
        }
        if !liveMarkControl.isHidden {
            liveMarkControl.alpha = 0
            UIView.animate(withDuration: 0.25) {
                self.liveMarkControl.alpha = 1
            }
        }
        if !liveMuteContainerView.isHidden {
            liveMuteContainerView.alpha = 0
            UIView.animate(withDuration: 0.25) {
                self.liveMuteContainerView.alpha = 1
            }
        }
    }
    
    private func hideMark() {
        if !liveMarkControl.isHidden {
            UIView.animate(withDuration: 0.25) {
                self.liveMarkControl.alpha = 0
            }
        }
        if !liveMuteContainerView.isHidden {
            UIView.animate(withDuration: 0.25) {
                self.liveMuteContainerView.alpha = 0
            }
        }
    }
    
    @objc
    private func didLiveMarkButtonClick() {
        delegate?.photoCell(self, livePhotoDidDisabled: !self.photoAsset.isDisableLivePhoto)
        
        configLiveMark()
    }
    
    @objc
    private func didLiveMuteButtonClick() {
        delegate?.photoCell(self, livePhotoDidMuted: !self.photoAsset.isLivePhotoMuted)
        
        configLiveMark()
    }
}
