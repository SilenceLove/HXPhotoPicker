//
//  PickerTransition.swift
//  HXPhotoPicker
//
//  Created by Silence on 2020/12/9.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit
import Photos

class PickerTransition: NSObject, UIViewControllerAnimatedTransitioning {
    private let type: PickerTransitionType
    private var requestID: PHImageRequestID?
    private var pushImageView: UIImageView!
    
    init(type: PickerTransitionType) {
        self.type = type
        super.init()
        pushImageView = UIImageView()
        pushImageView.contentMode = .scaleAspectFill
        pushImageView.clipsToBounds = true
    }
    
    func transitionDuration(
        using transitionContext: UIViewControllerContextTransitioning?
    ) -> TimeInterval {
        0.5
    }
    
    func animateTransition(
        using transitionContext: UIViewControllerContextTransitioning
    ) {
        if type == .push {
            pushTransition(transitionContext)
        }else {
            popTransition(transitionContext)
        }
    }
    
    func pushTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        guard let pickerVC = transitionContext.viewController(forKey: .from) as? PhotoPickerViewController,
              let previewVC = transitionContext.viewController(forKey: .to) as? PhotoPreviewViewController else {
            transitionContext.completeTransition(true)
            return
        }
        previewVC.isTransitioning = true
        let backgroundColor = PhotoManager.isDark ?
        previewVC.config.backgroundDarkColor :
        previewVC.config.backgroundColor
        let containerView = transitionContext.containerView
        let contentView = UIView(frame: pickerVC.view.bounds)
        containerView.addSubview(pickerVC.view)
        containerView.addSubview(previewVC.view)
        let fromViewCount = pickerVC.view.subviews.count
        if fromViewCount > 2, pickerVC.view.subviews[2] is PreviewPhotoViewCell {
            pickerVC.view.insertSubview(contentView, at: 3)
        }else if fromViewCount > 1, pickerVC.view.subviews[1] is PreviewPhotoViewCell {
            pickerVC.view.insertSubview(contentView, at: 2)
        }else {
            pickerVC.view.insertSubview(contentView, at: 1)
        }
        contentView.backgroundColor = backgroundColor.withAlphaComponent(0)
        contentView.addSubview(pushImageView)
        
        var fromView: UIView?
        let photoAsset = previewVC.photoAsset(for: previewVC.currentPreviewIndex)
        if let photoAsset {
            if let cell = pickerVC.listView.getCell(for: photoAsset) {
                pushImageView.image = cell.photoView.image
                pushImageView.frame = cell.photoView.convert(
                    cell.photoView.bounds,
                    to: containerView
                )
                fromView = cell
            }else {
                pushImageView.center = CGPoint(x: previewVC.view.width * 0.5, y: previewVC.view.height * 0.5)
            }
            var reqeustAsset = photoAsset.phAsset != nil
            #if HXPICKER_ENABLE_EDITOR
            if photoAsset.editedResult != nil {
                reqeustAsset = false
            }
            #endif
            if let phAsset = photoAsset.phAsset, reqeustAsset {
                requestAssetImage(for: phAsset)
            }else if pushImageView.image == nil || photoAsset.isLocalAsset {
                pushImageView.image = photoAsset.originalImage
            }
        }
        previewVC.collectionView.isHidden = true
        previewVC.photoToolbar.alpha = 0
        previewVC.navBgView?.alpha = 0
        previewVC.view.backgroundColor = backgroundColor.withAlphaComponent(0)
        let imageSize: CGSize
        if let size = photoAsset?.imageSize {
            imageSize = size
        }else {
            imageSize = .zero
        }
        var rect: CGRect = .zero
        if UIDevice.isPad {
            rect = PhotoTools.transformImageSize(
                imageSize,
                toViewSize: previewVC.view.size,
                directions: [.horizontal]
            )
            if rect.width < previewVC.view.width {
                rect.origin.x = (previewVC.view.width - rect.width) * 0.5
            }
            if rect.height < previewVC.view.height {
                rect.origin.y = (previewVC.view.height - rect.height) * 0.5
            }
        }else {
            rect = PhotoTools.transformImageSize(
                imageSize,
                to: previewVC.view
            )
        }
        fromView?.isHidden = true
        
        let previewMaskY: CGFloat
        let previewMaskHeight: CGFloat
        let previewToolbarHeight = previewVC.photoToolbar.toolbarHeight
        let previewViewHeight = previewVC.photoToolbar.viewHeight
        
        let pickerMaskY: CGFloat
        let pickerMaskHeight: CGFloat
        let pickerToolbarHeight = pickerVC.photoToolbar.toolbarHeight
        let pickerViewHeight = pickerVC.photoToolbar.viewHeight
        if previewViewHeight != pickerViewHeight {
            previewMaskY = previewViewHeight - previewToolbarHeight
            previewMaskHeight = previewToolbarHeight
            let previewMaskView = UIView(
                frame: CGRect(
                    x: 0, y: previewMaskY,
                    width: contentView.width, height: previewMaskHeight
                )
            )
            previewMaskView.backgroundColor = .white
            previewVC.photoToolbar.mask = previewMaskView
            
            if type == .push {
                pickerMaskY = 0
                pickerMaskHeight = pickerViewHeight
            }else {
                pickerMaskY = pickerViewHeight - pickerToolbarHeight
                pickerMaskHeight = pickerToolbarHeight
            }
            let pickerMaskView = UIView(frame: CGRect(x: 0, y: pickerMaskY, width: contentView.width, height: pickerMaskHeight))
            pickerMaskView.backgroundColor = .white
            pickerVC.photoToolbar.mask = pickerMaskView
        }
        
        func animateHandler() {
            let duration = transitionDuration(using: transitionContext)
            UIView.animate(withDuration: duration - 0.15) {
                contentView.backgroundColor = backgroundColor.withAlphaComponent(1)
            }
            let alphaDuration: TimeInterval
            if previewVC.photoToolbar.mask != nil {
                alphaDuration = 0.15
                UIView.animate(withDuration: duration - 0.2, delay: 0, options: [.curveEaseIn]) {
                    previewVC.photoToolbar.mask?.frame = CGRect(
                        x: 0, y: 0,
                        width: contentView.width, height: previewViewHeight
                    )
                    pickerVC.photoToolbar.mask?.frame = CGRect(
                        x: 0, y: pickerViewHeight - pickerToolbarHeight,
                        width: contentView.width, height: pickerToolbarHeight
                    )
                }
            }else {
                alphaDuration = duration
            }
            UIView.animate(withDuration: alphaDuration) {
                previewVC.photoToolbar.alpha = 1
                previewVC.navBgView?.alpha = 1
            }
            
            UIView.animate(
                withDuration: duration,
                delay: 0,
                usingSpringWithDamping: 0.8,
                initialSpringVelocity: 0,
                options: [.layoutSubviews, .curveEaseOut]
            ) {
                self.pushImageView.frame = rect
                pickerVC.pickerController.pickerDelegate?
                    .pickerController(pickerVC.pickerController, animateTransition: .push)
            } completion: { _ in
                pickerVC.photoToolbar.mask = nil
                previewVC.photoToolbar.mask = nil
                previewVC.isTransitioning = false
                if let requestID = self.requestID {
                    PHImageManager.default().cancelImageRequest(requestID)
                    self.requestID = nil
                }
                fromView?.isHidden = false
                previewVC.setCurrentCellImage(image: self.pushImageView.image)
                previewVC.collectionView.isHidden = false
                previewVC.updateColors()
                self.pushImageView.removeFromSuperview()
                contentView.removeFromSuperview()
                transitionContext.completeTransition(true)
                pickerVC.photoToolbar.alpha = 1
            }
        }
        if let networkImage = photoAsset?.networkImageAsset {
            var isRequest: Bool = false
            var isChangeImage: Bool = false
            if networkImage.imageSize.equalTo(.zero) {
                isRequest = true
            }else {
                if let image = pushImageView.image {
                    let networkScale = networkImage.imageSize.width / networkImage.imageSize.height
                    let imageScale = image.width / image.height
                    if networkScale != imageScale {
                        isRequest = true
                        isChangeImage = true
                    }
                }else {
                    isRequest = true
                }
            }
            if !isRequest {
                animateHandler()
                return
            }
            requestNetworkImage(networkImage) { [weak self] image in
                guard let self, let image else {
                    animateHandler()
                    return
                }
                if self.pushImageView.image == nil || isChangeImage {
                    self.pushImageView.image = image
                }
                if isChangeImage {
                    photoAsset?.networkImageAsset?.imageSize = image.size
                }
                animateHandler()
            }
            return
        }
        animateHandler()
    }
    
    func requestNetworkImage(_ networkImage: NetworkImageAsset, completion: @escaping(UIImage?) -> Void) {
        if let cacheKey = networkImage.originalCacheKey,
           PhotoManager.ImageView.isCached(forKey: cacheKey) {
            PhotoManager.ImageView.getCacheImage(forKey: cacheKey) { image in
                guard let image else {
                    completion(nil)
                    return
                }
                completion(image)
            }
            return
        }
        if let cacheKey = networkImage.thumbailCacheKey,
           PhotoManager.ImageView.isCached(forKey: cacheKey) {
            PhotoManager.ImageView.getCacheImage(forKey: cacheKey) { image in
                guard let image else {
                    completion(nil)
                    return
                }
                completion(image)
            }
            return
        }
        completion(nil)
    }
    
    func popTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        guard let previewVC = transitionContext.viewController(forKey: .from) as? PhotoPreviewViewController,
              let pickerVC = transitionContext.viewController(forKey: .to) as? PhotoPickerViewController else {
            transitionContext.completeTransition(true)
            return
        }
        previewVC.isTransitioning = true
        let backgroundColor = PhotoManager.isDark ?
            previewVC.config.backgroundDarkColor :
            previewVC.config.backgroundColor
         
        let containerView = transitionContext.containerView
        let contentView = UIView(frame: previewVC.view.bounds)
        containerView.addSubview(pickerVC.view)
        containerView.addSubview(previewVC.view)
        pickerVC.view.insertSubview(contentView, at: 1)
        contentView.backgroundColor = backgroundColor
        if pickerVC.isShowToolbar, previewVC.isShowToolbar {
            pickerVC.photoToolbar.selectViewOffset = previewVC.photoToolbar.selectViewOffset
        }
        var fromView: UIView?
        var toView: UIView?
        let cell = previewVC.getCell(for: previewVC.currentPreviewIndex)
        fromView = cell?.scrollContentView
        if let contentBounds = cell?.scrollContentView.bounds,
           let rect = cell?.scrollContentView.convert(contentBounds, to: containerView) {
            fromView?.frame = rect
        }
        if let fromView {
            contentView.addSubview(fromView)
        }
        previewVC.collectionView.isHidden = true
        previewVC.view.backgroundColor = UIColor.clear
        
        func popTransitionAnimation() {
            var rect: CGRect = .zero
            if let toView = toView {
                rect = toView.convert(toView.bounds, to: containerView)
                toView.isHidden = true
            }
            
            let previewMaskY: CGFloat
            let previewMaskHeight: CGFloat
            let previewToolbarHeight = previewVC.photoToolbar.toolbarHeight
            let previewViewHeight = previewVC.photoToolbar.viewHeight
            
            let pickerMaskY: CGFloat
            let pickerMaskHeight: CGFloat
            let pickerToolbarHeight = pickerVC.photoToolbar.toolbarHeight
            let pickerViewHeight = pickerVC.photoToolbar.viewHeight
            
            if previewViewHeight != pickerViewHeight {
                previewMaskY = 0
                previewMaskHeight = previewViewHeight
                let previewMaskView = UIView(
                    frame: CGRect(
                        x: 0, y: previewMaskY,
                        width: contentView.width, height: previewMaskHeight
                    )
                )
                previewMaskView.backgroundColor = .white
                previewVC.photoToolbar.mask = previewMaskView
                pickerMaskY = pickerViewHeight - pickerToolbarHeight
                pickerMaskHeight = pickerToolbarHeight
                let pickerMaskView = UIView(frame: CGRect(x: 0, y: pickerMaskY, width: contentView.width, height: pickerMaskHeight))
                pickerMaskView.backgroundColor = .white
                pickerVC.photoToolbar.mask = pickerMaskView
            }
            
            let duration = transitionDuration(using: transitionContext)
            UIView.animate(withDuration: duration - 0.15) {
                contentView.backgroundColor = backgroundColor.withAlphaComponent(0)
            }
            if previewVC.photoToolbar.mask != nil {
                UIView.animate(withDuration: duration - 0.2, delay: 0, options: [.curveLinear]) {
                    previewVC.photoToolbar.mask?.frame = CGRect(
                        x: 0, y: previewViewHeight - previewToolbarHeight,
                        width: contentView.width, height: previewToolbarHeight
                    )
                    pickerVC.photoToolbar.mask?.frame = CGRect(
                        x: 0, y: 0,
                        width: contentView.width, height: pickerViewHeight
                    )
                }
                UIView.animate(withDuration: duration - 0.15, delay: 0.125, options: []) {
                    previewVC.photoToolbar.alpha = 0
                    previewVC.navBgView?.alpha = 0
                }
            }else {
                UIView.animate(withDuration: duration) {
                    previewVC.photoToolbar.alpha = 0
                    previewVC.navBgView?.alpha = 0
                }
            }
            UIView.animate(
                withDuration: duration,
                delay: 0,
                usingSpringWithDamping: 0.8,
                initialSpringVelocity: 0,
                options: [.layoutSubviews, .curveEaseOut]
            ) {
                if rect.isEmpty {
                    fromView?.transform = CGAffineTransform.init(scaleX: 0.1, y: 0.1)
                    fromView?.alpha = 0
                }else {
                    fromView?.frame = rect
                }
                pickerVC.pickerController.pickerDelegate?
                    .pickerController(pickerVC.pickerController, animateTransition: .pop)
            } completion: { _ in
                pickerVC.photoToolbar.mask = nil
                previewVC.photoToolbar.mask = nil
                previewVC.isTransitioning = false
                toView?.isHidden = false
                UIView.animate(
                    withDuration: 0.25,
                    delay: 0,
                    options: [.allowUserInteraction]) {
                    fromView?.alpha = 0
                } completion: { _ in
                    contentView.removeFromSuperview()
                    transitionContext.completeTransition(true)
                }
            }
        }
        if let photoAsset = previewVC.photoAsset(for: previewVC.currentPreviewIndex) {
            pickerVC.viewDidLayoutSubviews()
            pickerVC.listView.updateCellLoadMode(.complete)
            pickerVC.isDisableLayout = true
            DispatchQueue.main.async {
                toView = pickerVC.listView.getCell(for: photoAsset)
                DispatchQueue.main.async {
                    if let toView = toView as? PhotoPickerBaseViewCell {
                        pickerVC.listView.scrollCellToVisibleArea(toView)
                        DispatchQueue.main.async {
                            pickerVC.listView.cellReloadImage()
                        }
                        popTransitionAnimation()
                    }else {
                        pickerVC.listView.scrollToCenter(for: photoAsset)
                        DispatchQueue.main.async {
                            pickerVC.listView.reloadCell(for: photoAsset)
                            pickerVC.listView.cellReloadImage()
                            toView = pickerVC.listView.getCell(for: photoAsset)
                            popTransitionAnimation()
                        }
                    }
                }
            }
            return
        }
    }
    
    func requestAssetImage(for asset: PHAsset) {
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
                if self.pushImageView.superview != nil {
                    self.pushImageView.image = image
                }
            }
            if AssetManager.assetDownloadFinined(for: info) || AssetManager.assetCancelDownload(for: info) {
                self.requestID = nil
            }
        }
    }
}
