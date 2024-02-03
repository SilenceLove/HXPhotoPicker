//
//  PreviewLivePhotoViewCell.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/3/12.
//

import UIKit

class PreviewLivePhotoViewCell: PhotoPreviewViewCell, PhotoPreviewContentViewDelete {
    
    private var liveMarkView: UIVisualEffectView!
    
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
            #if HXPICKER_ENABLE_EDITOR
            if photoAsset.photoEditedResult != nil {
                liveMarkView.isHidden = true
            }
            else {
                if liveMarkConfig?.allowShow == true {
                    liveMarkView.isHidden = false
                }
            }
            #else
            if liveMarkConfig?.allowShow == true {
                liveMarkView.isHidden = false
            }
            #endif
        }
    }
    func configLiveMark() {
        guard let liveMarkConfig = liveMarkConfig else {
            liveMarkView.isHidden = true
            return
        }
        if !liveMarkConfig.allowShow {
            liveMarkView.isHidden = true
            return
        }
        liveMarkView.effect = UIBlurEffect(
            style: PhotoManager.isDark ? liveMarkConfig.blurDarkStyle : liveMarkConfig.blurStyle
        )
        let imageView = liveMarkView.contentView.subviews.first as? UIImageView
        imageView?.tintColor = PhotoManager.isDark ? liveMarkConfig.imageDarkColor : liveMarkConfig.imageColor
        let label = liveMarkView.contentView.subviews.last as? UILabel
        label?.textColor = PhotoManager.isDark ? liveMarkConfig.textDarkColor : liveMarkConfig.textColor
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        scrollContentView = PhotoPreviewContentLivePhotoView()
        scrollContentView.delegate = self
        initView()
        
        let effect = UIBlurEffect(style: .light)
        liveMarkView = UIVisualEffectView(effect: effect)
        if let nav = UIViewController.topViewController?.navigationController, !nav.navigationBar.isHidden {
            liveMarkView.y = nav.navigationBar.frame.maxY + 5
        }else {
            if UIApplication.shared.isStatusBarHidden {
                liveMarkView.y = UIDevice.navigationBarHeight + UIDevice.generalStatusBarHeight + 5
            }else {
                liveMarkView.y = UIDevice.navigationBarHeight + 5
            }
        }
        liveMarkView.x = 5 + UIDevice.leftMargin
        liveMarkView.height = 24
        liveMarkView.layer.cornerRadius = 3
        liveMarkView.layer.masksToBounds = true
        let imageView = UIImageView(image: .imageResource.picker.preview.livePhoto.image?.withRenderingMode(.alwaysTemplate))
        imageView.tintColor = "#666666".color
        if let imageSize = imageView.image?.size {
            imageView.size = imageSize
        }
        imageView.centerY = liveMarkView.height * 0.5
        imageView.x = 5
        liveMarkView.contentView.addSubview(imageView)
        let label = UILabel()
        label.text = "Live"
        label.textColor = "#666666".color
        label.textAlignment = .center
        label.font = .regularPingFang(ofSize: 15)
        label.x = imageView.frame.maxX + 5
        label.height = liveMarkView.height
        label.width = label.textWidth
        liveMarkView.width = label.frame.maxX + 5
        liveMarkView.contentView.addSubview(label)
        addSubview(liveMarkView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupLiveMarkFrame()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func contentView(requestSucceed contentView: PhotoPreviewContentViewProtocol) {
        delegate?.cell(requestSucceed: self)
    }
    func contentView(requestFailed contentView: PhotoPreviewContentViewProtocol) {
        delegate?.cell(requestFailed: self)
    }
    
    func contentView(livePhotoWillBeginPlayback contentView: PhotoPreviewContentViewProtocol) {
        hideMark()
    }
    func contentView(livePhotoDidEndPlayback contentView: PhotoPreviewContentViewProtocol) {
        showMark()
    }
    
    func showMark() {
        guard let liveMarkConfig = liveMarkConfig else {
            return
        }
        #if HXPICKER_ENABLE_EDITOR
        if photoAsset.photoEditedResult != nil {
            return
        }
        #endif
        if !liveMarkConfig.allowShow {
            return
        }
        if scrollContentView.isLivePhotoAnimating ||
            scrollContentView.isBacking ||
            statusBarShouldBeHidden { return }
        if let superView = superview, !(superView is UICollectionView) {
            return
        }
        if !liveMarkView.isHidden && liveMarkView.alpha == 1 { return }
        liveMarkView.isHidden = false
        UIView.animate(withDuration: 0.25) {
            self.liveMarkView.alpha = 1
        }
    }
    func setupLiveMarkFrame() {
        guard let liveMarkConfig = liveMarkConfig, liveMarkConfig.allowShow else {
            return
        }
        if let nav = UIViewController.topViewController?.navigationController, !nav.navigationBar.isHidden {
            liveMarkView.y = nav.navigationBar.frame.maxY + 5
        }else {
            if UIApplication.shared.isStatusBarHidden {
                liveMarkView.y = UIDevice.navigationBarHeight + UIDevice.generalStatusBarHeight + 5
            }else {
                liveMarkView.y = UIDevice.navigationBarHeight + 5
            }
        }
        liveMarkView.x = 5 + UIDevice.leftMargin
    }
    func hideMark() {
        guard let liveMarkConfig = liveMarkConfig else {
            return
        }
        #if HXPICKER_ENABLE_EDITOR
        if photoAsset.photoEditedResult != nil {
            return
        }
        #endif
        if !liveMarkConfig.allowShow {
            return
        }
        if liveMarkView.isHidden { return }
        UIView.animate(withDuration: 0.25) {
            self.liveMarkView.alpha = 0
        } completion: { _ in
            if self.liveMarkView.alpha == 0 {
                self.liveMarkView.isHidden = true
            }
        }
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                configLiveMark()
            }
        }
    }
}
