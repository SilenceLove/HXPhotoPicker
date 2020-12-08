//
//  HXAlbumViewCell.swift
//  照片选择器-Swift
//
//  Created by 洪欣 on 2019/6/28.
//  Copyright © 2019年 洪欣. All rights reserved.
//

import UIKit
import Photos

class HXAlbumViewCell: UITableViewCell {
    lazy var albumCoverView: UIImageView = {
        let albumCoverView = UIImageView.init()
        albumCoverView.contentMode = .scaleAspectFill
        albumCoverView.clipsToBounds = true
        return albumCoverView
    }()
    lazy var albumNameLb: UILabel = {
        let albumNameLb = UILabel.init()
        return albumNameLb
    }()
    lazy var photoCountLb: UILabel = {
        let photoCountLb = UILabel.init()
        return photoCountLb
    }()
    lazy var bottomLineView: UIView = {
        let bottomLineView = UIView.init()
        bottomLineView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.15)
        return bottomLineView
    }()
    lazy var selectedBgView : UIView = {
        let selectedBgView = UIView.init()
        return selectedBgView
    }()
    var config : HXPHAlbumListConfiguration? {
        didSet {
            albumNameLb.font = config?.albumNameFont
            photoCountLb.font = config?.photoCountFont
            configColor()
        }
    }
    var assetCollection: HXPHAssetCollection? {
        didSet {
            albumNameLb.text = assetCollection?.albumName
            photoCountLb.text = String(assetCollection!.count)
            weak var weakSelf = self
            requestID = assetCollection?.requestCoverImage(completion: { (image, assetCollection, info) in
                if assetCollection == weakSelf?.assetCollection && image != nil {
                    weakSelf?.albumCoverView.image = image
                    if !HXPHAssetManager.assetDownloadIsDegraded(for: info) {
                        weakSelf?.requestID = nil
                    }
                }
            })
        }
    }
    var requestID: PHImageRequestID?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func initView() {
        contentView.addSubview(albumCoverView)
        contentView.addSubview(albumNameLb)
        contentView.addSubview(photoCountLb)
        contentView.addSubview(bottomLineView)
    }
    func configColor() {
        albumNameLb.textColor = HXPHManager.shared.isDark ? config?.albumNameDarkColor : config?.albumNameColor
        photoCountLb.textColor = HXPHManager.shared.isDark ? config?.photoCountDarkColor : config?.photoCountColor
        bottomLineView.backgroundColor = HXPHManager.shared.isDark ? config?.separatorLineDarkColor : config?.separatorLineColor
        backgroundColor = HXPHManager.shared.isDark ? config?.cellbackgroundDarkColor : config?.cellBackgroundColor
        if HXPHManager.shared.isDark {
            selectedBgView.backgroundColor = config?.cellDarkSelectedColor
            selectedBackgroundView = selectedBgView
        }else {
            if config?.cellSelectedColor != nil {
                selectedBgView.backgroundColor = config?.cellSelectedColor
                selectedBackgroundView = selectedBgView
            }else {
                selectedBackgroundView = nil
            }
        }
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        let coverMargin : CGFloat = 5
        let coverWidth = hx_height - (coverMargin * 2)
        albumCoverView.frame = CGRect(x: coverMargin, y: coverMargin, width: coverWidth, height: coverWidth)
        
        albumNameLb.hx_x = albumCoverView.frame.maxX + 10
        albumNameLb.hx_size = CGSize(width: hx_width - albumNameLb.hx_x - 20, height: 16)
        albumNameLb.hx_centerY = hx_height / CGFloat(2) - albumNameLb.hx_height / CGFloat(2)
        
        photoCountLb.hx_x = albumCoverView.frame.maxX + 10
        photoCountLb.hx_y = albumNameLb.frame.maxY + 5
        photoCountLb.hx_size = CGSize(width: hx_width - photoCountLb.hx_x - 20, height: 14)
        
        bottomLineView.frame = CGRect(x: coverMargin, y: hx_height - 0.5, width: hx_width - coverMargin * 2, height: 0.5)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                configColor()
            }
        }
    }
    
    func cancelRequest() {
        if requestID != nil {
            PHImageManager.default().cancelImageRequest(requestID!)
            requestID = nil
        }
    }
}
