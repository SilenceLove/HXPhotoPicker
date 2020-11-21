//
//  HXPHPreviewViewCell.swift
//  HXPHPickerExample
//
//  Created by 洪欣 on 2020/11/13.
//  Copyright © 2020 洪欣. All rights reserved.
//

import UIKit
import Photos
import PhotosUI

protocol HXPHPreviewViewCellDelegate: NSObjectProtocol {
    func singleTap()
}

class HXPHPreviewViewCell: UICollectionViewCell, UIScrollViewDelegate {
    
    weak var delegate: HXPHPreviewViewCellDelegate?
    
    var scrollContentView: HXPHPreviewContentView?
    lazy var scrollView : UIScrollView = {
        let scrollView = UIScrollView.init()
        scrollView.delegate = self;
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.bouncesZoom = true
        scrollView.minimumZoomScale = 1
        scrollView.isMultipleTouchEnabled = true
        scrollView.scrollsToTop = false
        scrollView.delaysContentTouches = false
        scrollView.canCancelContentTouches = true
        scrollView.alwaysBounceVertical = false
        scrollView.autoresizingMask = UIView.AutoresizingMask.init(arrayLiteral: UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight)
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = UIScrollView.ContentInsetAdjustmentBehavior.never
        }
        let singleTap = UITapGestureRecognizer.init(target: self, action: #selector(singleTap(tap:)))
        scrollView.addGestureRecognizer(singleTap)
        let doubleTap = UITapGestureRecognizer.init(target: self, action: #selector(doubleTap(tap:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.numberOfTouchesRequired = 1
        singleTap.require(toFail: doubleTap)
        scrollView.addGestureRecognizer(doubleTap)
        scrollView.addSubview(scrollContentView!)
        return scrollView
    }()
    
    var photoAsset: HXPHAsset? {
        didSet {
            setupScrollViewContenSize()
            scrollContentView!.photoAsset = photoAsset
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func initView() {
        contentView.addSubview(scrollView)
    }
    func setupScrollViewContenSize() {
        if UIDevice.hx_isPortrait() {
            let aspectRatio = hx_width / photoAsset!.imageSize.width
            let contentWidth = hx_width
            let contentHeight = photoAsset!.imageSize.height * aspectRatio
            if contentWidth < contentHeight {
                scrollView.maximumZoomScale = hx_width * 2.5 / contentWidth
            }else {
                scrollView.maximumZoomScale = hx_height * 2.5 / contentHeight
            }
            scrollContentView!.frame = CGRect(x: 0, y: 0, width: contentWidth, height: contentHeight)
            if contentHeight < hx_height {
                scrollView.contentSize = hx_size
                scrollContentView!.center = CGPoint(x: hx_width * 0.5, y: hx_height * 0.5)
            }else {
                scrollView.contentSize = CGSize(width: contentWidth, height: contentHeight)
            }
        }else {
            let aspectRatio = hx_height / photoAsset!.imageSize.height
            let contentWidth = photoAsset!.imageSize.width * aspectRatio
            let contentHeight = hx_height
            scrollView.maximumZoomScale = hx_width / contentWidth + 0.5
            
            scrollContentView!.frame = CGRect(x: 0, y: 0, width: contentWidth, height: contentHeight)
            scrollContentView!.center = CGPoint(x: hx_width * 0.5, y: hx_height * 0.5)
            scrollView.contentSize = hx_size
        }
    }
    func requestPreviewAsset() {
        scrollContentView!.requestPreviewAsset()
    }
    func cancelRequest() {
        scrollContentView!.cancelRequest()
    }
    @objc func singleTap(tap: UITapGestureRecognizer) {
        delegate?.singleTap()
    }
    @objc func doubleTap(tap: UITapGestureRecognizer) {
        if scrollView.zoomScale > 1 {
            scrollView.setZoomScale(1, animated: true)
        }else {
            let touchPoint = tap.location(in: scrollContentView!)
            let maximumZoomScale = scrollView.maximumZoomScale
            let width = hx_width / maximumZoomScale
            let height = hx_height / maximumZoomScale
            scrollView.zoom(to: CGRect(x: touchPoint.x - width / 2, y: touchPoint.y - height / 2, width: width, height: height), animated: true)
        }
    }
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return scrollContentView!
    }
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = (scrollView.frame.size.width > scrollView.contentSize.width) ? (scrollView.frame.size.width - scrollView.contentSize.width) * 0.5 : 0.0;
        let offsetY = (scrollView.frame.size.height > scrollView.contentSize.height) ? (scrollView.frame.size.height - scrollView.contentSize.height) * 0.5 : 0.0;
        scrollContentView!.center = CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX, y: scrollView.contentSize.height * 0.5 + offsetY);
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if scrollView.frame.equalTo(bounds) == false {
            scrollView.frame = bounds
        }
    }
}
class HXPHPreviewPhotoViewCell: HXPHPreviewViewCell {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        scrollContentView = HXPHPreviewContentView.init(type: HXPHPreviewContentViewType.photo)
        initView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class HXPHPreviewLivePhotoViewCell: HXPHPreviewViewCell {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        scrollContentView = HXPHPreviewContentView.init(type: HXPHPreviewContentViewType.livePhoto)
        initView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

enum HXPHPreviewContentViewType: Int {
    case photo
    case livePhoto
    case video
}
class HXPHPreviewContentView: UIView, PHLivePhotoViewDelegate {
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView.init()
        return imageView
    }()
    @available(iOS 9.1, *)
    lazy var livePhotoView: PHLivePhotoView = {
        let livePhotoView = PHLivePhotoView.init()
        livePhotoView.delegate = self
        return livePhotoView
    }()
    var type: HXPHPreviewContentViewType = HXPHPreviewContentViewType.photo
    var requestID: PHImageRequestID?
    var requestCompletion: Bool = false
    
    var photoAsset: HXPHAsset? {
        didSet {
            if type == HXPHPreviewContentViewType.livePhoto {
                if #available(iOS 9.1, *) {
                    livePhotoView.livePhoto = nil
                }
            }
            requestID = photoAsset?.requestThumbnailImage(completion: { (image, asset, info) in
                if asset == self.photoAsset && image != nil {
                    self.imageView.image = image
                }
            })
        }
    }
    
    init(type: HXPHPreviewContentViewType) {
        super.init(frame: CGRect.zero)
        self.type = type
        addSubview(imageView)
        if type == HXPHPreviewContentViewType.livePhoto {
            if #available(iOS 9.1, *) {
                addSubview(livePhotoView)
            }
        }else if type == HXPHPreviewContentViewType.video {
            
        }
    }
    
    func requestPreviewAsset() {
        if requestCompletion {
            return
        }
        cancelRequest()
        if type == HXPHPreviewContentViewType.photo {
            requestOriginalImage()
        }else if type == HXPHPreviewContentViewType.livePhoto {
            if #available(iOS 9.1, *) {
                requestLivePhoto()
            }
        }else if type == HXPHPreviewContentViewType.video {
            
        }
    }
    
    func requestOriginalImage() {
        requestID = photoAsset?.requestImageData(iCloudHandler: { (asset, iCloudRequestID) in
            if asset == self.photoAsset {
                self.requestID = iCloudRequestID
            }
        }, progressHandler: { (asset, progress) in
            if asset == self.photoAsset {
                
            }
        }, success: { (asset, imageData, imageOrientation, info) in
            DispatchQueue.global().async {
                var image = UIImage.init(data: imageData)
                image = image?.hx_scaleSuitableSize()
                DispatchQueue.main.async {
                    if asset == self.photoAsset {
                        self.imageView.image = image
                        self.requestID = nil
                        self.requestCompletion = true
                    }
                }
            }
        }, failure: { (asset, info) in
            if asset == self.photoAsset {
                
            }
        })
    }
    @available(iOS 9.1, *)
    func requestLivePhoto() {
        let targetSize : CGSize = hx_size
        requestID = photoAsset?.requestLivePhoto(targetSize: targetSize, iCloudHandler: { (asset, requestID) in
            if asset == self.photoAsset {
                self.requestID = requestID
            }
        }, progressHandler: { (asset, progress) in
            if asset == self.photoAsset {
                
            }
        }, success: { (asset, livePhoto, info) in
            if asset == self.photoAsset {
                self.livePhotoView.livePhoto = livePhoto
                self.livePhotoView.startPlayback(with: PHLivePhotoViewPlaybackStyle.full)
                self.requestID = nil
                self.requestCompletion = true
            }
        }, failure: { (asset, info) in
            if asset == self.photoAsset {
                
            }
        })
    }
    func cancelRequest() {
        if requestID != nil {
            PHImageManager.default().cancelImageRequest(requestID!)
            requestID = nil
        }
        if type == HXPHPreviewContentViewType.livePhoto {
            if #available(iOS 9.1, *) {
                livePhotoView.stopPlayback()
            }
        }else if type == HXPHPreviewContentViewType.video {
            
        }
        requestCompletion = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
        if type == HXPHPreviewContentViewType.livePhoto {
            if #available(iOS 9.1, *) {
                livePhotoView.frame = bounds
            }
        }else if type == HXPHPreviewContentViewType.video {
            
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
