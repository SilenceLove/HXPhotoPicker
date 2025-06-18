//
//  PreviewPhotoViewCell.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/3/12.
//

import UIKit
 
class PreviewPhotoViewCell: PhotoPreviewViewCell, PhotoPreviewContentViewDelete {
    
    var HDRMarkConfig: PreviewViewConfiguration.HDRMark? {
        didSet {
            configHDRMark()
        }
    }
    
    override var photoAsset: PhotoAsset! {
        didSet {
            configHDRMark()
        }
    }
    
    private var HDRMarkControl: UIControl!
    private var HDRMarkView: UIVisualEffectView!
    
    private var HDRMarkImageView: UIImageView!
     
    override init(frame: CGRect) {
        super.init(frame: frame)
        scrollContentView = PhotoPreviewContentPhotoView()
        scrollContentView.delegate = self
        initView()
        
        HDRMarkControl = UIControl()
        HDRMarkControl.layer.masksToBounds = true
        HDRMarkControl.addTarget(self, action: #selector(didHDRMarkButtonClick), for: .touchUpInside)
        contentView.addSubview(HDRMarkControl)
        
        let effect = UIBlurEffect(style: .light)
        HDRMarkView = UIVisualEffectView(effect: effect)
        HDRMarkView.isUserInteractionEnabled = false
        HDRMarkControl.addSubview(HDRMarkView)
        
        HDRMarkImageView = UIImageView()
        HDRMarkImageView.tintColor = "#666666".color
        HDRMarkView.contentView.addSubview(HDRMarkImageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupHDRMarkFrame()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                configHDRMark()
            }
        }
    }
    
    override func showScrollContainerSubview() {
        super.showScrollContainerSubview()
        guard !HDRMarkControl.isHidden else {
            return
        }
        HDRMarkControl.alpha = 0.0
        UIView.animate(withDuration: 0.25) {
            self.HDRMarkControl.alpha = 1.0
        }
    }
    
    override func hideScrollContainerSubview() {
        super.hideScrollContainerSubview()
        guard !HDRMarkControl.isHidden else {
            return
        }
        UIView.animate(withDuration: 0.25) {
            self.HDRMarkControl.alpha = 0.0
        }
    }
    
    func contentView(requestSucceed contentView: PhotoPreviewContentViewProtocol) {
        delegate?.cell(requestSucceed: self)
    }
    func contentView(requestFailed contentView: PhotoPreviewContentViewProtocol) {
        delegate?.cell(requestFailed: self)
    }
    func contentView(updateContentSize contentView: PhotoPreviewContentViewProtocol) {
        setupScrollViewContentSize()
    }
    
    func contentView(networkImagedownloadSuccess contentView: PhotoPreviewContentViewProtocol) {
        delegate?.photoCell(networkImagedownloadSuccess: self)
    }
    func contentView(networkImagedownloadFailed contentView: PhotoPreviewContentViewProtocol) {
        delegate?.photoCell(networkImagedownloadFailed: self)
    }
    
    private func configHDRMark() {
        guard photoAsset != nil else {
            return
        }
#if HXPICKER_ENABLE_EDITOR
        guard photoAsset.photoEditedResult == nil else {
            HDRMarkControl.isHidden = true
            return
        }
#endif
        guard photoAsset.mediaSubType.isHDRPhoto else {
            HDRMarkControl.isHidden = true
            return
        }
        guard let config = HDRMarkConfig else {
            HDRMarkControl.isHidden = true
            return
        }
        if config.allowShow {
            HDRMarkControl.isHidden = false
            
            HDRMarkView.effect = UIBlurEffect(
                style: PhotoManager.isDark ? config.blurDarkStyle : config.blurStyle
            )
            HDRMarkImageView.tintColor = PhotoManager.isDark ? config.imageDarkColor : config.imageColor
            
            let image = photoAsset.isDisableHDR ? UIImage.imageResource.picker.preview.HDRDisable.image : UIImage.imageResource.picker.preview.HDR.image
            HDRMarkImageView.image = image?.withRenderingMode(.alwaysTemplate)
        } else {
            HDRMarkControl.isHidden = true
        }
    }
    
    private func setupHDRMarkFrame() {
        guard let config = HDRMarkConfig else {
            return
        }
        if config.allowShow {
            let safeAreaInsets = {
                if #available(iOS 11.0, *) {
                    return self.safeAreaInsets
                } else {
                    return UIEdgeInsets(top: UIDevice.navigationBarHeight, left: 0, bottom: 0, right: 0)
                }
            }()
            let spacing = 10.0
            let contentInset = UIEdgeInsets(top: 5, left: 8, bottom: 5, right: 8)
            let imageSize = HDRMarkImageView.sizeThatFits(.zero)
            
            HDRMarkControl.frame = CGRect(
                x: safeAreaInsets.left + spacing,
                y: safeAreaInsets.top + spacing,
                width: imageSize.width + contentInset.left + contentInset.right,
                height: imageSize.height + contentInset.top + contentInset.bottom
            )
            HDRMarkControl.layer.cornerRadius = HDRMarkControl.frame.height / 2.0
            HDRMarkView.frame = HDRMarkControl.bounds
            
            HDRMarkImageView.frame = CGRect(
                x: contentInset.left,
                y: (HDRMarkView.frame.height - imageSize.height) / 2.0,
                width: imageSize.width,
                height: imageSize.height
            )
        }
    }
    
    @objc
    private func didHDRMarkButtonClick() {
        delegate?.photoCell(self, HDRDidDisabled: !photoAsset.isDisableHDR)
        
        configHDRMark()
    }

}
