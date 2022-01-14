//
//  PhotoPreviewViewCell.swift
//  HXPHPickerExample
//
//  Created by Silence on 2020/11/13.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit
import Photos
import PhotosUI
import ImageIO

protocol PhotoPreviewViewCellDelegate: AnyObject {
    func cell(singleTap cell: PhotoPreviewViewCell)
    func cell(longPress cell: PhotoPreviewViewCell)
    func cell(requestSucceed cell: PhotoPreviewViewCell)
    func cell(requestFailed cell: PhotoPreviewViewCell)
    func photoCell(networkImagedownloadSuccess photoCell: PhotoPreviewViewCell)
    func photoCell(networkImagedownloadFailed photoCell: PhotoPreviewViewCell)
}

open class PhotoPreviewViewCell: UICollectionViewCell, UIScrollViewDelegate {
    
    weak var delegate: PhotoPreviewViewCellDelegate?
    
    var scrollContentView: PhotoPreviewContentView!
    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView.init()
        scrollView.delegate = self
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
        scrollView.addSubview(scrollContentView)
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressClick(longPress:)))
        scrollView.addGestureRecognizer(longPress)
        return scrollView
    }()
    
    var photoAsset: PhotoAsset! {
        didSet {
            setupScrollViewContentSize()
            scrollContentView.photoAsset = photoAsset
        }
    }
    
    var statusBarShouldBeHidden = false
    var allowInteration: Bool = true
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func initView() {
        contentView.addSubview(scrollView)
    }
    func setupScrollViewContentSize() {
        scrollView.zoomScale = 1
        if UIDevice.isPortrait {
            setupPortraitContentSize()
        }else {
            setupLandscapeContentSize()
        }
    }
    func setupPortraitContentSize() {
        let aspectRatio = width / photoAsset.imageSize.width
        let contentWidth = width
        let contentHeight = photoAsset.imageSize.height * aspectRatio
        if contentWidth < contentHeight {
            scrollView.maximumZoomScale = width * 2.5 / contentWidth
        }else {
            scrollView.maximumZoomScale = height * 2.5 / contentHeight
        }
        scrollContentView.frame = CGRect(x: 0, y: 0, width: contentWidth, height: contentHeight)
        if contentHeight < height {
            scrollView.contentSize = size
            scrollContentView.center = CGPoint(x: width * 0.5, y: height * 0.5)
        }else {
            scrollView.contentSize = CGSize(width: contentWidth, height: contentHeight)
        }
    }
    func setupLandscapeContentSize() {
        let aspectRatio = height / photoAsset.imageSize.height
        var contentWidth = photoAsset.imageSize.width * aspectRatio
        var contentHeight = height
        if contentWidth > width {
            contentHeight = width / contentWidth * contentHeight
            contentWidth = width
            scrollView.maximumZoomScale = height / contentHeight + 0.5
            scrollContentView.frame = CGRect(x: 0, y: 0, width: contentWidth, height: contentHeight)
            scrollView.contentSize = scrollContentView.size
        }else {
            scrollView.maximumZoomScale = width / contentWidth + 0.5
            scrollContentView.frame = CGRect(x: 0, y: 0, width: contentWidth, height: contentHeight)
            scrollView.contentSize = size
        }
        scrollContentView.center = CGPoint(x: width * 0.5, y: height * 0.5)
    }
    func requestPreviewAsset() {
        scrollContentView.requestPreviewAsset()
    }
    func cancelRequest() {
        scrollContentView.cancelRequest()
    }
    @objc func singleTap(tap: UITapGestureRecognizer) {
        delegate?.cell(singleTap: self)
    }
    @objc func doubleTap(tap: UITapGestureRecognizer) {
        if scrollView.zoomScale > 1 {
            scrollView.setZoomScale(1, animated: true)
        }else {
            let touchPoint = tap.location(in: scrollContentView)
            let maximumZoomScale = scrollView.maximumZoomScale
            let zoomWidth = width / maximumZoomScale
            let zoomHeight = height / maximumZoomScale
            scrollView.zoom(
                to: CGRect(
                    x: touchPoint.x - zoomWidth / 2,
                    y: touchPoint.y - zoomHeight / 2,
                    width: zoomWidth,
                    height: zoomHeight
                ),
                animated: true
            )
        }
    }
    @objc func longPressClick(longPress: UILongPressGestureRecognizer) {
        if longPress.state == .began {
            delegate?.cell(longPress: self)
        }
    }
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return scrollContentView
    }
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = (scrollView.width > scrollView.contentSize.width) ?
            (scrollView.width - scrollView.contentSize.width) * 0.5 : 0.0
        let offsetY = (scrollView.height > scrollView.contentSize.height) ?
            (scrollView.height - scrollView.contentSize.height) * 0.5 : 0.0
        scrollContentView.center = CGPoint(
            x: scrollView.contentSize.width * 0.5 + offsetX,
            y: scrollView.contentSize.height * 0.5 + offsetY
        )
    }
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if !scrollView.isTracking && scrollView.isDecelerating {
            allowInteration = false
        }
    }
//    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
//        if decelerate && scrollView.contentOffset.y >= -20 {
//            allowInteration = true
//        }
//    }
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= -40 {
            allowInteration = true
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        if scrollView.frame.equalTo(bounds) == false {
            scrollView.frame = bounds
        }
    }
}
