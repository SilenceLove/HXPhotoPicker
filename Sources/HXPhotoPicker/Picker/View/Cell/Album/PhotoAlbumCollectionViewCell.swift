//
//  PhotoAlbumCollectionViewCell.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/10/19.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit
import Photos

public class PhotoAlbumCollectionViewCell: UICollectionViewCell {
    
    var imageView: UIImageView!
    var titleLb: UILabel!
    var countLb: UILabel!
    var selectedBgView: UIView!
    
    public var config: PhotoAlbumControllerConfiguration = .init() {
        didSet {
            titleLb.font = config.albumNameFont
            countLb.font = config.photoCountFont
            countLb.isHidden = !config.isShowPhotoCount
            updateColors()
        }
    }
    
    public var assetCollection: PhotoAssetCollection! {
        didSet {
            titleLb.text = assetCollection.albumName
            countLb.text = "\(assetCollection.count)"
            requestImage()
        }
    }
    
    public override var isSelected: Bool {
        didSet {
            if isSelected {
                selectedBgView.alpha = 1
                selectedBgView.isHidden = false
            }else {
                UIView.animate(withDuration: 0.2) {
                    self.selectedBgView.alpha = 0
                } completion: {
                    if $0 {
                        self.selectedBgView.isHidden = true
                    }
                }
            }
        }
    }
    
    public override var isHighlighted: Bool {
        didSet {
            selectedBgView.alpha = isHighlighted ? 1 : 0
            selectedBgView.isHidden = !isHighlighted
        }
    }
    
    var requestID: PHImageRequestID?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 5
        imageView.layer.masksToBounds = true
        contentView.addSubview(imageView)
        titleLb = UILabel()
        contentView.addSubview(titleLb)
        countLb = UILabel()
        contentView.addSubview(countLb)
        
        selectedBgView = UIView()
        selectedBgView.isHidden = true
        selectedBgView.backgroundColor = .black.withAlphaComponent(0.5)
        selectedBgView.layer.cornerRadius = 5
        selectedBgView.layer.masksToBounds = true
        contentView.addSubview(selectedBgView)
    }
    
    func requestImage() {
        cancelRequest()
        requestID = assetCollection.requestCoverImage(completion: { [weak self] in
            guard let self = self else { return }
            if let info = $2, info.isCancel { return }
            if let image = $0,
               $1 == self.assetCollection {
                self.imageView.image = image
                if !AssetManager.assetIsDegraded(for: $2) {
                    self.requestID = nil
                }
            }
        })
    }
    
    func cancelRequest() {
        guard let requestID = requestID else { return }
        PHImageManager.default().cancelImageRequest(requestID)
        self.requestID = nil
    }
    
    func updateColors() {
        let isDark = PhotoManager.isDark
        titleLb.textColor = isDark ? config.albumNameDarkColor : config.albumNameColor
        countLb.textColor = isDark ? config.photoCountDarkColor : config.photoCountColor
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = .init(x: 0, y: 0, width: contentView.width, height: contentView.width)
        titleLb.y = imageView.frame.maxY + 4
        titleLb.height = titleLb.font.lineHeight
        titleLb.width = min(titleLb.textWidth, contentView.width)
        titleLb.hxPicker_x = 0
        countLb.y = titleLb.frame.maxY + 2
        countLb.height = countLb.textHeight
        countLb.width = countLb.textWidth
        countLb.hxPicker_x = 0
        selectedBgView.hxPicker_frame = imageView.bounds
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                updateColors()
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        cancelRequest()
    }
}
