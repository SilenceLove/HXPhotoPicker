//
//  PhotoBrowserAnimator.swift
//  HXPhotoPicker
//
//  Created by Silence on 2024/2/24.
//  Copyright © 2024 Silence. All rights reserved.
//

import UIKit
import Photos
#if canImport(Kingfisher)
import Kingfisher
#endif

open class PhotoBrowserAnimator: NSObject, PhotoBrowserAnimationTransitioning {
    public let type: PhotoBrowserAnimationTransitionType
    public var requestID: PHImageRequestID?
    public var animatedImageView: UIImageView!
    public required init(type: PhotoBrowserAnimationTransitionType) {
        self.type = type
        super.init()
        animatedImageView = UIImageView()
        animatedImageView.contentMode = .scaleAspectFill
        animatedImageView.clipsToBounds = true
    }
    
    open func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        if type == .dismiss {
            return 0.65
        }
        return 0.5
    }
    
    open func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if type == .present {
            presentTransition(transitionContext)
        }else {
            dismissTransition(transitionContext)
        }
    }
    
    open func presentTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        guard let toVC = transitionContext.viewController(forKey: .to) as? PhotoPickerController else {
            transitionContext.completeTransition(true)
            return
        }
        toVC.isBrowserTransitioning = true
        let backgroundColor = PhotoManager.isDark ?
        toVC.config.previewView.backgroundDarkColor :
        toVC.config.previewView.backgroundColor
        toVC.previewViewController?.view.backgroundColor = backgroundColor.withAlphaComponent(0)
        toVC.previewViewController?.photoToolbar.alpha = 0
        toVC.previewViewController?.navBgView?.alpha = 0
        toVC.previewViewController?.collectionView.isHidden = true
        toVC.view.backgroundColor = nil
        toVC.navigationBar.alpha = 0
        let previewIndex = toVC.currentPreviewIndex
        let containerView = transitionContext.containerView
        let contentView = UIView(frame: toVC.view.bounds)
        contentView.backgroundColor = backgroundColor.withAlphaComponent(0)
        contentView.addSubview(animatedImageView)
        containerView.addSubview(contentView)
        containerView.addSubview(toVC.view)
        
        var previewView: UIView?
        if let view = toVC.pickerDelegate?.pickerController(toVC, presentPreviewViewForIndexAt: previewIndex) {
            let rect = view.convert(view.bounds, to: contentView)
            animatedImageView.frame = rect
            if view.layer.cornerRadius > 0 {
                animatedImageView.layer.cornerRadius = view.layer.cornerRadius
                animatedImageView.layer.masksToBounds = true
            }
            previewView = view
        }else if let rect = toVC.pickerDelegate?.pickerController(toVC, presentPreviewFrameForIndexAt: previewIndex), !rect.equalTo(.zero) {
            animatedImageView.frame = rect
        }else {
            animatedImageView.center = CGPoint(x: toVC.view.width * 0.5, y: toVC.view.height * 0.5)
        }
        
        if let image = toVC.pickerDelegate?.pickerController(toVC, presentPreviewImageForIndexAt: previewIndex) {
            animatedImageView.image = image
        }
        var photoAsset: PhotoAsset?
        if toVC.previewType == .picker {
            photoAsset = toVC.previewViewController?.photoAsset(for: previewIndex)
        }else if !toVC.selectedAssetArray.isEmpty {
            photoAsset = toVC.selectedAssetArray[previewIndex]
        }else {
            photoAsset = toVC.previewViewController?.photoAsset(for: previewIndex)
        }
        var toRect: CGRect = .zero
        if let photoAsset = photoAsset {
            var isReqeustAsset = photoAsset.phAsset != nil
            #if HXPICKER_ENABLE_EDITOR
            if photoAsset.editedResult != nil {
                isReqeustAsset = false
            }
            #endif
            if let phAsset = photoAsset.phAsset, isReqeustAsset {
                requestAssetImage(for: phAsset)
            }else if animatedImageView.image == nil || photoAsset.isLocalAsset {
                if let image = photoAsset.originalImage {
                    animatedImageView.image = image
                }
            }
            if UIDevice.isPad {
                toRect = PhotoTools.transformImageSize(
                    photoAsset.imageSize,
                    toViewSize: toVC.view.size,
                    directions: [.horizontal]
                )
            }else {
                toRect = PhotoTools.transformImageSize(photoAsset.imageSize, to: toVC.view)
            }
        }
        if let photoBrowser = toVC as? PhotoBrowser {
            if photoBrowser.hideSourceView {
                previewView?.isHidden = true
            }
        }else {
            previewView?.isHidden = true
        }
        func animateHandler() {
            let duration = transitionDuration(using: transitionContext)
            let colorDuration = duration - 0.15
            let colorDelay: TimeInterval = 0.05
            UIView.animate(withDuration: colorDuration, delay: colorDelay, options: [ .curveLinear]) {
                toVC.previewViewController?.photoToolbar.alpha = 1
                toVC.previewViewController?.navBgView?.alpha = 1
                contentView.backgroundColor = backgroundColor.withAlphaComponent(1)
            }
            UIView.animate(
                withDuration: duration,
                delay: 0,
                usingSpringWithDamping: 0.8,
                initialSpringVelocity: 0,
                options: [.layoutSubviews, .curveEaseOut]
            ) {
                toVC.navigationBar.alpha = 1
                if self.animatedImageView.layer.cornerRadius > 0 {
                    self.animatedImageView.layer.cornerRadius = 0
                }
                self.animatedImageView.frame = toRect
                toVC.pickerDelegate?
                    .pickerController(toVC, animateTransition: .present)
            } completion: { _ in
                previewView?.isHidden = false
                toVC.isBrowserTransitioning = false
                if let requestID = self.requestID {
                    PHImageManager.default().cancelImageRequest(requestID)
                    self.requestID = nil
                }
                toVC.pickerDelegate?.pickerController(
                    toVC,
                    previewPresentComplete: previewIndex
                )
                toVC.previewViewController?.view.backgroundColor = backgroundColor.withAlphaComponent(1)
                toVC.previewViewController?.setCurrentCellImage(image: self.animatedImageView.image)
                toVC.previewViewController?.collectionView.isHidden = false
                toVC.previewViewController?.updateColors()
                toVC.setupBackgroundColor()
                self.animatedImageView.removeFromSuperview()
                contentView.removeFromSuperview()
                transitionContext.completeTransition(true)
            }
        }
        #if canImport(Kingfisher)
        if let networkImage = photoAsset?.networkImageAsset, networkImage.imageSize.equalTo(.zero) {
            requestNetworkImage(networkImage) { [weak self] image in
                guard let self, let image else {
                    animateHandler()
                    return
                }
                if self.animatedImageView.image == nil {
                    self.animatedImageView.image = image
                }
                photoAsset?.networkImageAsset?.imageSize = image.size
                if UIDevice.isPad {
                    toRect = PhotoTools.transformImageSize(
                        image.size,
                        toViewSize: toVC.view.size,
                        directions: [.horizontal]
                    )
                }else {
                    toRect = PhotoTools.transformImageSize(image.size, to: toVC.view)
                }
                animateHandler()
            }
            return
        }
        #endif
        animateHandler()
    }
    
    open func requestAssetImage(for asset: PHAsset) {
        let options = PHImageRequestOptions()
        options.resizeMode = .fast
        options.deliveryMode = .highQualityFormat
        requestID = AssetManager.requestImage(
            for: asset,
            targetSize: asset.thumTargetSize,
            options: options
        ) { image, info in
            guard let image else { return }
            DispatchQueue.main.async {
                if self.animatedImageView.superview != nil {
                    self.animatedImageView.image = image
                }
            }
            if AssetManager.assetDownloadFinined(for: info) || AssetManager.assetCancelDownload(for: info) {
                self.requestID = nil
            }
        }
    }
    
    #if canImport(Kingfisher)
    open func requestNetworkImage(_ networkImage: NetworkImageAsset, completion: @escaping(UIImage?) -> Void) {
        if let cacheKey = networkImage.originalURL?.cacheKey,
           ImageCache.default.isCached(forKey: cacheKey) {
            ImageCache.default.retrieveImage(
                forKey: cacheKey,
                options: [],
                callbackQueue: .mainAsync
            ) {
                switch $0 {
                case .success(let value):
                    completion(value.image)
                default:
                    completion(nil)
                }
            }
            return
        }
        if let cacheKey = networkImage.thumbnailURL?.cacheKey,
           ImageCache.default.isCached(forKey: cacheKey) {
            ImageCache.default.retrieveImage(
                forKey: cacheKey,
                options: [],
                callbackQueue: .mainAsync
            ) {
                switch $0 {
                case .success(let value):
                    completion(value.image)
                default:
                    completion(nil)
                }
            }
            return
        }
        completion(nil)
    }
    #endif
    
    open func dismissTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from) as? PhotoPickerController else {
            transitionContext.completeTransition(true)
            return
        }
        fromVC.isBrowserTransitioning = true
        fromVC.view.backgroundColor = .clear
        fromVC.previewViewController?.view.backgroundColor = .clear
        fromVC.previewViewController?.collectionView.isHidden = true
        
        let backgroundColor = PhotoManager.isDark ?
        fromVC.config.previewView.backgroundDarkColor :
        fromVC.config.previewView.backgroundColor
        
        let containerView = transitionContext.containerView
        let contentView = UIView(frame: fromVC.view.bounds)
        contentView.backgroundColor = backgroundColor
        fromVC.previewViewController?.view.insertSubview(contentView, at: 0)
        
        var previewView: UIView?
        var toRect: CGRect = .zero
        let previewIndex = fromVC.currentPreviewIndex
        var isCornerRadius = false
        if let view = fromVC.pickerDelegate?.pickerController(fromVC, dismissPreviewViewForIndexAt: previewIndex) {
            toRect = view.convert(view.bounds, to: containerView)
            previewView = view
            if view.layer.cornerRadius > 0 {
                isCornerRadius = true
            }
        }else if let rect = fromVC.pickerDelegate?.pickerController(fromVC, dismissPreviewFrameForIndexAt: previewIndex), !rect.equalTo(.zero) {
            toRect = rect
        }
        let fromView: UIView
        if let cell = fromVC.previewViewController?.transitionCellView {
            cell.hideScrollContainerSubview()
            fromView = cell.scrollContainerView
            fromView.frame = cell.scrollContainerView.convert(cell.scrollContainerView.bounds, to: containerView)
        }else {
            fromView = animatedImageView
        }
        if isCornerRadius {
            fromView.layer.masksToBounds = true
        }
        if let photoBrowser = fromVC as? PhotoBrowser {
            if photoBrowser.hideSourceView {
                previewView?.isHidden = true
            }
        }else {
            previewView?.isHidden = true
        }
        contentView.addSubview(fromView)
        let duration: TimeInterval
        if !toRect.isEmpty {
            duration = transitionDuration(using: transitionContext) - 0.2
        }else {
            duration = transitionDuration(using: transitionContext)
        }
        let colorDuration = duration - 0.15
        UIView.animate(withDuration: colorDuration, delay: 0, options: [ .curveLinear]) {
            fromVC.previewViewController?.photoToolbar.alpha = 0
            fromVC.previewViewController?.navBgView?.alpha = 0
            contentView.backgroundColor = backgroundColor.withAlphaComponent(0)
        }
        UIView.animate(
            withDuration: duration,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0,
            options: [.layoutSubviews, .curveEaseOut]
        ) {
            fromVC.navigationBar.alpha = 0
            if let previewView = previewView, previewView.layer.cornerRadius > 0 {
                fromView.layer.cornerRadius = previewView.layer.cornerRadius
            }
            if toRect.isEmpty {
                fromView.transform = CGAffineTransform.init(scaleX: 0.1, y: 0.1)
                fromView.alpha = 0
            }else {
                fromView.frame = toRect
            }
            fromVC.pickerDelegate?
                .pickerController(fromVC, animateTransition: .dismiss)
        } completion: { _ in
            previewView?.isHidden = false
            fromVC.isBrowserTransitioning = false
            fromVC.pickerDelegate?.pickerController(
                fromVC,
                previewDismissComplete: previewIndex
            )
            if toRect.isEmpty {
                contentView.removeFromSuperview()
                transitionContext.completeTransition(true)
            }else {
                UIView.animate(withDuration: 0.2, delay: 0, options: [.allowUserInteraction]) {
                    fromView.alpha = 0
                } completion: { _ in
                    contentView.removeFromSuperview()
                    transitionContext.completeTransition(true)
                }
            }
        }
    }
}
