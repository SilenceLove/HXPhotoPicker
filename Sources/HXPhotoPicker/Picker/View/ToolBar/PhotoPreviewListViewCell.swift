//
//  PhotoPreviewListViewCell.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/11/23.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit

class PhotoPreviewListViewCell: UICollectionViewCell {
    var imageView: UIImageView {
        photoView.imageView ?? .init()
    }
    var photoView: PhotoThumbnailView!
    var photoAsset: PhotoAsset! {
        didSet {
            tickView.isHidden = !photoAsset.isSelected
            photoView.photoAsset = photoAsset
            reqeustAssetImage()
        }
    }
    var tickView: TickView!
    var tickColor: UIColor? {
        didSet {
            tickView.tickLayer.strokeColor = tickColor?.cgColor
        }
    }
    var tickBgColor: UIColor? {
        didSet {
            tickView.backgroundColor = tickBgColor
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        photoView = PhotoThumbnailView()
        photoView.imageView.size = size
        contentView.addSubview(photoView)
        
        tickView = TickView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        tickView.isHidden = true
        tickView.cornersRound(radius: 5, corner: .allCorners)
        contentView.addSubview(tickView)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        cancelRequest()
    }
    
    func reqeustAssetImage(_ scale: CGFloat = 2) {
        photoView.requestThumbnailImage(targetWidth: width * scale)
    }
    
    func cancelRequest() {
        photoView.cancelRequest()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        photoView.frame = bounds
        tickView.x = width - 2 - tickView.width
        tickView.y = 2
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
