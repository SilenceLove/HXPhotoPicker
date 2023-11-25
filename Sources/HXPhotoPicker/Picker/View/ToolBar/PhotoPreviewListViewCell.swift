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
            photoView.photoAsset = photoAsset
            reqeustAssetImage()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        photoView = PhotoThumbnailView()
        photoView.imageView.size = size
        contentView.addSubview(photoView)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        cancelRequest()
    }
    
    func reqeustAssetImage() {
        photoView.requestThumbnailImage(targetWidth: width * 2)
    }
    
    func cancelRequest() {
        photoView.cancelRequest()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        photoView.frame = bounds
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
