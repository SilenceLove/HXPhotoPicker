//
//  AlbumViewCell.swift
//  照片选择器-Swift
//
//  Created by Silence on 2019/6/28.
//  Copyright © 2019年 Silence. All rights reserved.
//

import UIKit
import Photos

open class AlbumViewCell: AlbumViewBaseCell {
    
    public var albumCoverView: UIImageView!
    public var albumNameLb: UILabel!
    public var photoCountLb: UILabel!
    public var bottomLineView: UIView!
    public var selectedBgView: UIView!
    
    /// 配置
    public override var config: AlbumListConfiguration {
        didSet {
            albumNameLb.font = config.albumNameFont
            photoCountLb.font = config.photoCountFont
            photoCountLb.isHidden = !config.isShowPhotoCount
            configColor()
        }
    }
    
    /// 照片集合
    public override var assetCollection: PhotoAssetCollection! {
        didSet {
            albumNameLb.text = assetCollection.albumName
            photoCountLb.text = String(assetCollection.count)
            tickView.isHidden = !assetCollection.isSelected
            requestCoverImage()
        }
    }
    
    /// 请求id
    public var requestID: PHImageRequestID?
    
    var tickView: TickView!
    
    open func initView() {
        
        selectedBgView = UIView()
        
        albumCoverView = UIImageView()
        albumCoverView.contentMode = .scaleAspectFill
        albumCoverView.clipsToBounds = true
        contentView.addSubview(albumCoverView)
        
        albumNameLb = UILabel()
        contentView.addSubview(albumNameLb)
        
        photoCountLb = UILabel()
        contentView.addSubview(photoCountLb)
        
        bottomLineView = UIView()
        bottomLineView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.15)
        contentView.addSubview(bottomLineView)
        
        tickView = TickView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        contentView.addSubview(tickView)
    }
    
    /// 获取相册封面图片，重写此方法修改封面图片
    open func requestCoverImage() {
        cancelRequest()
        requestID = assetCollection?.requestCoverImage(completion: { [weak self] in
            guard let self = self else { return }
            if let info = $2, info.isCancel { return }
            if let image = $0,
               $1 == self.assetCollection {
                self.albumCoverView.image = image
                if !AssetManager.assetIsDegraded(for: $2) {
                    self.requestID = nil
                }
            }
        })
    }
    
    open override func updateSelectedStatus(_ isSelected: Bool) {
        tickView.isHidden = !isSelected
    }
    
    // 颜色配置，重写此方法修改颜色配置
    open func configColor() {
        let isDark = PhotoManager.isDark
        albumNameLb.textColor = isDark ? config.albumNameDarkColor : config.albumNameColor
        photoCountLb.textColor = isDark ? config.photoCountDarkColor : config.photoCountColor
        bottomLineView.backgroundColor = isDark ? config.separatorLineDarkColor : config.separatorLineColor
        tickView.tickLayer.strokeColor = isDark ? config.tickDarkColor.cgColor : config.tickColor.cgColor
        backgroundColor = isDark ? config.cellBackgroundDarkColor : config.cellBackgroundColor
        if isDark {
            selectedBgView.backgroundColor = config.cellSelectedDarkColor
            selectedBackgroundView = selectedBgView
        }else {
            if let color = config.cellSelectedColor {
                selectedBgView.backgroundColor = color
                selectedBackgroundView = selectedBgView
            }else {
                selectedBackgroundView = nil
            }
        }
    }
    
    /// 布局，重写此方法修改布局
    open func layoutView() {
        let width = contentView.width
        let coverMargin: CGFloat = 5
        let coverWidth = height - (coverMargin * 2)
        albumCoverView.frame = CGRect(x: coverMargin, y: coverMargin, width: coverWidth, height: coverWidth)
        
        if viewController?.splitViewController != nil {
            tickView.x = width - 12 - tickView.width
        }else {
            tickView.x = width - 12 - tickView.width - UIDevice.rightMargin
        }
        tickView.centerY = height * 0.5
        
        albumNameLb.x = albumCoverView.frame.maxX + 10
        albumNameLb.size = CGSize(width: tickView.x - albumNameLb.x - 20, height: 16)
        
        if config.isShowPhotoCount {
            albumNameLb.centerY = height / 2 - albumNameLb.height / 2
            
            photoCountLb.x = albumCoverView.frame.maxX + 10
            photoCountLb.y = albumNameLb.frame.maxY + 5
            photoCountLb.size = CGSize(width: width - photoCountLb.x - 20, height: 14)
        }else {
            albumNameLb.centerY = height / 2
        }
        
        bottomLineView.frame = CGRect(x: coverMargin, y: height - 0.5, width: width - coverMargin * 2, height: 0.5)
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
    
    public func cancelRequest() {
        guard let requestID = requestID else { return }
        PHImageManager.default().cancelImageRequest(requestID)
        self.requestID = nil
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override var canBecomeFocused: Bool {
        false
    }
    
    deinit {
        cancelRequest()
    }
}
