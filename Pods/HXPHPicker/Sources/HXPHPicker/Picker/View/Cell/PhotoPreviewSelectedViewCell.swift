//
//  PhotoPreviewSelectedViewCell.swift
//  HXPHPickerExample
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit
import Photos

open class PhotoPreviewSelectedViewCell: UICollectionViewCell {
    
    public lazy var photoView: PhotoThumbnailView = {
        let photoView = PhotoThumbnailView()
        return photoView
    }()
    
    public lazy var selectedView: UIView = {
        let selectedView = UIView.init()
        selectedView.isHidden = true
        selectedView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        selectedView.addSubview(tickView)
        return selectedView
    }()
    
    public lazy var tickView: AlbumTickView = {
        let tickView = AlbumTickView.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        return tickView
    }()
    
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
        contentView.addSubview(photoView)
        contentView.addSubview(selectedView)
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
