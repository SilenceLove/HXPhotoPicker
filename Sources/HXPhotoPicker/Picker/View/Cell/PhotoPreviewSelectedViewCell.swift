//
//  PhotoPreviewSelectedViewCell.swift
//  HXPhotoPicker
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit
import Photos

open class PhotoPreviewSelectedViewCell: UICollectionViewCell {
    
    public var photoView: PhotoThumbnailView!
    public var selectedView: UIView!
    var tickView: TickView!
    
    open var tickColor: UIColor? {
        didSet {
            tickView.tickLayer.strokeColor = tickColor?.cgColor
            #if canImport(Kingfisher)
            photoView.kf_indicatorColor = tickColor
            #endif
        }
    }
    
    public var requestID: PHImageRequestID?
    
    open var photoAsset: PhotoAsset! {
        didSet {
            photoView.photoAsset = photoAsset
            reqeustAssetImage()
        }
    }
    
    /// 获取图片，重写此方法可以修改图片
    open func reqeustAssetImage() {
        photoView.requestThumbnailImage(targetWidth: width * 2)
    }
    
    open override var isSelected: Bool {
        didSet {
            selectedView.isHidden = !isSelected
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        photoView = PhotoThumbnailView()
        photoView.imageView.size = size
        contentView.addSubview(photoView)
        
        selectedView = UIView()
        selectedView.isHidden = true
        selectedView.backgroundColor = .black.withAlphaComponent(0.6)
        contentView.addSubview(selectedView)
        
        tickView = TickView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        selectedView.addSubview(tickView)
    }
    
    public func cancelRequest() {
        photoView.cancelRequest()
    }
    open override func layoutSubviews() {
        super.layoutSubviews()
        photoView.frame = bounds
        selectedView.frame = bounds
        tickView.center = CGPoint(x: width * 0.5, y: height * 0.5)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
