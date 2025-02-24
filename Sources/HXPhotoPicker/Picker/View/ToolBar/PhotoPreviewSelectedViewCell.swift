//
//  PhotoPreviewSelectedViewCell.swift
//  HXPhotoPicker
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit
import Photos

public protocol PhotoPreviewSelectedViewCellDelegate: AnyObject {
    func selectedViewCell(didDelete cell: PhotoPreviewSelectedViewCell)
}

open class PhotoPreviewSelectedViewCell: UICollectionViewCell {
    public weak var delegate: PhotoPreviewSelectedViewCellDelegate?
    public var deleteBtn: UIButton!
    public var photoView: PhotoThumbnailView!
    public var selectedView: UIView!
    public var isPhotoList: Bool = false {
        didSet {
            if isPhotoList {
                selectedView.isHidden = true
                tickView.isHidden = true
                deleteBtn.isHidden = false
            }else {
                deleteBtn.isHidden = true
            }
        }
    }
    var tickView: TickView!
    
    open var tickColor: UIColor? {
        didSet {
            if !isPhotoList {
                tickView.isHidden = false
                tickView.tickLayer.strokeColor = tickColor?.cgColor
            }
            photoView.kf_indicatorColor = tickColor
        }
    }
    
    
    open var photoAsset: PhotoAsset! {
        didSet {
            photoView.photoAsset = photoAsset
            reqeustAssetImage()
        }
    }
    
    open override var isSelected: Bool {
        didSet {
            if isPhotoList {
                return
            }
            selectedView.isHidden = !isSelected
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        photoView = PhotoThumbnailView()
        photoView.imageView.size = size
        contentView.addSubview(photoView)
        
        deleteBtn = UIButton(type: .custom)
        deleteBtn.setImage(.imageResource.picker.photoList.bottomView.delete.image, for: .normal)
        deleteBtn.addTarget(self, action: #selector(didDeleteButtonClick), for: .touchUpInside)
        contentView.addSubview(deleteBtn)
        
        selectedView = UIView()
        selectedView.isHidden = true
        selectedView.backgroundColor = .black.withAlphaComponent(0.6)
        contentView.addSubview(selectedView)
        
        tickView = TickView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        selectedView.addSubview(tickView)
    }
    
    @objc
    func didDeleteButtonClick() {
        delegate?.selectedViewCell(didDelete: self)
    }
    
    /// 获取图片，重写此方法可以修改图片
    open func reqeustAssetImage() {
        photoView.requestThumbnailImage(targetWidth: width * 2)
    }
    
    public func cancelRequest() {
        photoView.cancelRequest()
    }
    open override func layoutSubviews() {
        super.layoutSubviews()
        photoView.frame = bounds
        selectedView.frame = bounds
        tickView.center = CGPoint(x: width * 0.5, y: height * 0.5)
         
        deleteBtn.size = .init(width: 18, height: 18)
        deleteBtn.y = 0
        deleteBtn.x = width - deleteBtn.width
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
