//
//  HXAlbumViewCell.swift
//  照片选择器-Swift
//
//  Created by Silence on 2019/6/28.
//  Copyright © 2019年 Silence. All rights reserved.
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
    lazy var tickView: HXAlbumTickView = {
        let tickView = HXAlbumTickView.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        return tickView
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
            tickView.isHidden = !(assetCollection?.isSelected ?? false)
            requestCoverImage()
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
        contentView.addSubview(tickView)
    }
    
    /// 获取相册封面图片，重写此方法修改封面图片
    func requestCoverImage() {
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
    // 颜色配置，重写此方法修改颜色配置
    func configColor() {
        let isDark = HXPHManager.shared.isDark
        albumNameLb.textColor = isDark ? config?.albumNameDarkColor : config?.albumNameColor
        photoCountLb.textColor = isDark ? config?.photoCountDarkColor : config?.photoCountColor
        bottomLineView.backgroundColor = isDark ? config?.separatorLineDarkColor : config?.separatorLineColor
        tickView.tickLayer.strokeColor = isDark ? config?.tickDarkColor.cgColor : config?.tickColor.cgColor
        backgroundColor = isDark ? config?.cellbackgroundDarkColor : config?.cellBackgroundColor
        if isDark {
            selectedBgView.backgroundColor = config?.cellSelectedDarkColor
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
    /// 布局，重写此方法修改布局
    func layoutView() {
        let coverMargin : CGFloat = 5
        let coverWidth = hx_height - (coverMargin * 2)
        albumCoverView.frame = CGRect(x: coverMargin, y: coverMargin, width: coverWidth, height: coverWidth)
        
        tickView.hx_x = hx_width - 12 - tickView.hx_width - UIDevice.current.hx_rightMargin
        tickView.hx_centerY = hx_height * 0.5
        
        albumNameLb.hx_x = albumCoverView.frame.maxX + 10
        albumNameLb.hx_size = CGSize(width: tickView.hx_x - albumNameLb.hx_x - 20, height: 16)
        albumNameLb.hx_centerY = hx_height / CGFloat(2) - albumNameLb.hx_height / CGFloat(2)
        
        photoCountLb.hx_x = albumCoverView.frame.maxX + 10
        photoCountLb.hx_y = albumNameLb.frame.maxY + 5
        photoCountLb.hx_size = CGSize(width: hx_width - photoCountLb.hx_x - 20, height: 14)
        
        bottomLineView.frame = CGRect(x: coverMargin, y: hx_height - 0.5, width: hx_width - coverMargin * 2, height: 0.5)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutView()
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

class HXAlbumTickView: UIView {
    lazy var tickLayer: CAShapeLayer = {
        let tickLayer = CAShapeLayer.init()
        tickLayer.contentsScale = UIScreen.main.scale
        let tickPath = UIBezierPath.init()
        tickPath.move(to: CGPoint(x: scale(8), y: hx_height * 0.5 + scale(1)))
        tickPath.addLine(to: CGPoint(x: hx_width * 0.5 - scale(2), y: hx_height - scale(8)))
        tickPath.addLine(to: CGPoint(x: hx_width - scale(7), y: scale(9)))
        tickLayer.path = tickPath.cgPath
        tickLayer.lineWidth = 1.5
        tickLayer.strokeColor = UIColor.black.cgColor
        tickLayer.fillColor = UIColor.clear.cgColor
        return tickLayer
    }()
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(tickLayer)
    }
    
    private func scale(_ numerator: CGFloat) -> CGFloat {
        return numerator / 30 * hx_height
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
