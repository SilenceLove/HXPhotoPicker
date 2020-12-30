//
//  HXPHPreviewViewCell.swift
//  HXPHPickerExample
//
//  Created by Silence on 2020/11/13.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit
import Photos
import PhotosUI
import ImageIO

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
        scrollView.autoresizingMask = UIView.AutoresizingMask.init(arrayLiteral: .flexibleWidth, .flexibleHeight)
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
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
    var allowInteration: Bool = true
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
        scrollView.zoomScale = 1
        if UIDevice.current.isPortrait {
            let aspectRatio = width / photoAsset!.imageSize.width
            let contentWidth = width
            let contentHeight = photoAsset!.imageSize.height * aspectRatio
            if contentWidth < contentHeight {
                scrollView.maximumZoomScale = width * 2.5 / contentWidth
            }else {
                scrollView.maximumZoomScale = height * 2.5 / contentHeight
            }
            scrollContentView!.frame = CGRect(x: 0, y: 0, width: contentWidth, height: contentHeight)
            if contentHeight < height {
                scrollView.contentSize = size
                scrollContentView!.center = CGPoint(x: width * 0.5, y: height * 0.5)
            }else {
                scrollView.contentSize = CGSize(width: contentWidth, height: contentHeight)
            }
        }else {
            let aspectRatio = height / photoAsset!.imageSize.height
            let contentWidth = photoAsset!.imageSize.width * aspectRatio
            let contentHeight = height
            scrollView.maximumZoomScale = width / contentWidth + 0.5
            
            scrollContentView!.frame = CGRect(x: 0, y: 0, width: contentWidth, height: contentHeight)
            scrollContentView!.center = CGPoint(x: width * 0.5, y: height * 0.5)
            scrollView.contentSize = size
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
            let zoomWidth = width / maximumZoomScale
            let zoomHeight = height / maximumZoomScale
            scrollView.zoom(to: CGRect(x: touchPoint.x - zoomWidth / 2, y: touchPoint.y - zoomHeight / 2, width: zoomWidth, height: zoomHeight), animated: true)
        }
    }
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return scrollContentView!
    }
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = (scrollView.width > scrollView.contentSize.width) ? (scrollView.width - scrollView.contentSize.width) * 0.5 : 0.0;
        let offsetY = (scrollView.height > scrollView.contentSize.height) ? (scrollView.height - scrollView.contentSize.height) * 0.5 : 0.0;
        scrollContentView!.center = CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX, y: scrollView.contentSize.height * 0.5 + offsetY);
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if !scrollView.isTracking && scrollView.isDecelerating {
            allowInteration = false
        }
    }
//    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
//        if decelerate && scrollView.contentOffset.y >= -20 {
//            allowInteration = true
//        }
//    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= -40 {
            allowInteration = true
        }
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

class HXPHPreviewVideoViewCell: HXPHPreviewViewCell {
    
    var videoPlayType: HXPHPicker.PreviewView.VideoPlayType = .normal  {
        didSet {
            scrollContentView?.videoView.videoPlayType = videoPlayType
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        scrollContentView = HXPHPreviewContentView.init(type: HXPHPreviewContentViewType.video)
        initView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


