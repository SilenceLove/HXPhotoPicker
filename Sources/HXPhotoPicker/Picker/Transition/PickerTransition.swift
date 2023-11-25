//
//  PickerTransition.swift
//  HXPhotoPicker
//
//  Created by Silence on 2020/12/9.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit
import Photos
#if canImport(Kingfisher)
import Kingfisher
#endif

public enum PickerTransitionType {
    case push
    case pop
    case present
    case dismiss
}

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
        using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        if type == .dismiss {
            return 0.65
        }
        return 0.5
    }
    
    func animateTransition(
        using transitionContext: UIViewControllerContextTransitioning) {
        if type == .push || type == .pop {
            pushTransition(using: transitionContext)
        }else {
            presentTransition(using: transitionContext)
        }
    }
    // swiftlint:disable function_body_length
    func pushTransition(
        using transitionContext: UIViewControllerContextTransitioning
    ) {
        // swiftlint:enable function_body_length
        guard let fromVC = transitionContext.viewController(forKey: .from),
              let toVC = transitionContext.viewController(forKey: .to) else {
            transitionContext.completeTransition(true)
            return
        }
        
        var previewVC: PhotoPreviewViewController?
        var pickerVC: PhotoPickerViewController?
        
        let containerView = transitionContext.containerView
        let contentView = UIView(frame: fromVC.view.bounds)
        if type == .push {
            pickerVC = fromVC as? PhotoPickerViewController
            previewVC = toVC as? PhotoPreviewViewController
        }else if type == .pop {
            pickerVC = toVC as? PhotoPickerViewController
            previewVC = fromVC as? PhotoPreviewViewController
        }
        guard let previewVC = previewVC else {
            transitionContext.completeTransition(true)
            return
        }
        previewVC.isTransitioning = true
        let backgroundColor = PhotoManager.isDark ?
            previewVC.config.backgroundDarkColor :
            previewVC.config.backgroundColor
        
        let photoAsset = previewVC.photoAsset(for: previewVC.currentPreviewIndex)
         
        var fromView: UIView?
        var toView: UIView?
        
        if type == .push {
            containerView.addSubview(fromVC.view)
            containerView.addSubview(toVC.view)
            let fromViewCount = fromVC.view.subviews.count
            if fromViewCount > 2, fromVC.view.subviews[2] is PreviewPhotoViewCell {
                fromVC.view.insertSubview(contentView, at: 3)
            }else if fromViewCount > 1, fromVC.view.subviews[1] is PreviewPhotoViewCell {
                fromVC.view.insertSubview(contentView, at: 2)
            }else {
                fromVC.view.insertSubview(contentView, at: 1)
            }
            contentView.backgroundColor = backgroundColor.withAlphaComponent(0)
            contentView.addSubview(pushImageView)
            
            if let pickerVC = pickerVC, let photoAsset = photoAsset {
                if let cell = pickerVC.listView.getCell(for: photoAsset) {
                    pushImageView.image = cell.photoView.image
                    pushImageView.frame = cell.photoView.convert(
                        cell.photoView.bounds,
                        to: containerView
                    )
                    fromView = cell
                }else {
                    pushImageView.center = CGPoint(x: toVC.view.width * 0.5, y: toVC.view.height * 0.5)
                }
                var reqeustAsset = photoAsset.phAsset != nil
                #if HXPICKER_ENABLE_EDITOR
                if photoAsset.editedResult != nil {
                    reqeustAsset = false
                }
                #endif
                if let phAsset = photoAsset.phAsset, reqeustAsset {
                    requestAssetImage(for: phAsset, isGIF: photoAsset.isGifAsset, isHEIC: photoAsset.photoFormat == "heic")
                }else if pushImageView.image == nil || photoAsset.isLocalAsset {
                    pushImageView.image = photoAsset.originalImage
                }
            }
            
            previewVC.collectionView.isHidden = true
            previewVC.photoToolbar.alpha = 0
            previewVC.navBgView?.alpha = 0
            previewVC.view.backgroundColor = backgroundColor.withAlphaComponent(0)
        }else if type == .pop {
            containerView.addSubview(toVC.view)
            containerView.addSubview(fromVC.view)
            toVC.view.insertSubview(contentView, at: 1)
            contentView.backgroundColor = backgroundColor
            if let pickerVC = pickerVC, pickerVC.isShowToolbar, previewVC.isShowToolbar {
                pickerVC.photoToolbar.selectViewOffset = previewVC.photoToolbar.selectViewOffset
            }
            
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
            if let pickerVC = pickerVC, let photoAsset = photoAsset {
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
                            self.pushTransitionAnimation(
                                photoAsset: photoAsset,
                                toVC: toVC,
                                previewVC: previewVC,
                                pickerVC: pickerVC,
                                containerView: containerView,
                                contentView: contentView,
                                fromView: fromView,
                                toView: toView,
                                backgroundColor: backgroundColor,
                                transitionContext: transitionContext
                            )
                        }else {
                            pickerVC.listView.scrollToCenter(for: photoAsset)
                            DispatchQueue.main.async {
                                pickerVC.listView.reloadCell(for: photoAsset)
                                pickerVC.listView.cellReloadImage()
                                toView = pickerVC.listView.getCell(for: photoAsset)
                                self.pushTransitionAnimation(
                                    photoAsset: photoAsset,
                                    toVC: toVC,
                                    previewVC: previewVC,
                                    pickerVC: pickerVC,
                                    containerView: containerView,
                                    contentView: contentView,
                                    fromView: fromView,
                                    toView: toView,
                                    backgroundColor: backgroundColor,
                                    transitionContext: transitionContext
                                )
                            }
                        }
                    }
                }
                return
            }
        }
        pushTransitionAnimation(
            photoAsset: photoAsset,
            toVC: toVC,
            previewVC: previewVC,
            pickerVC: pickerVC,
            containerView: containerView,
            contentView: contentView,
            fromView: fromView,
            toView: toView,
            backgroundColor: backgroundColor,
            transitionContext: transitionContext
        )
    }
    
    func pushTransitionAnimation(
        photoAsset: PhotoAsset?,
        toVC: UIViewController,
        previewVC: PhotoPreviewViewController,
        pickerVC: PhotoPickerViewController?,
        containerView: UIView,
        contentView: UIView,
        fromView: UIView?,
        toView: UIView?,
        backgroundColor: UIColor,
        transitionContext: UIViewControllerContextTransitioning
    ) {
        var rect: CGRect = .zero
        if type == .push {
            let imageSize: CGSize
            if let size = photoAsset?.imageSize {
                imageSize = size
            }else {
                imageSize = .zero
            }
            if UIDevice.isPad {
                rect = PhotoTools.transformImageSize(
                    imageSize,
                    toViewSize: toVC.view.size,
                    directions: [.horizontal]
                )
                if rect.width < toVC.view.width {
                    rect.origin.x = (toVC.view.width - rect.width) * 0.5
                }
                if rect.height < toVC.view.height {
                    rect.origin.y = (toVC.view.height - rect.height) * 0.5
                }
            }else {
                rect = PhotoTools.transformImageSize(
                    imageSize,
                    to: toVC.view
                )
            }
            fromView?.isHidden = true
        }else if type == .pop {
            if let toView = toView {
                rect = toView.convert(toView.bounds, to: containerView)
                toView.isHidden = true
            }
        }
        
        let previewMaskY: CGFloat
        let previewMaskHeight: CGFloat
        let previewToolbarHeight = previewVC.photoToolbar.toolbarHeight
        let previewViewHeight = previewVC.photoToolbar.viewHeight
        
        let pickerMaskY: CGFloat
        let pickerMaskHeight: CGFloat
        let pickerToolbarHeight: CGFloat
        if let height = pickerVC?.photoToolbar.toolbarHeight {
            pickerToolbarHeight = height
        }else {
            pickerToolbarHeight = 0
        }
        let pickerViewHeight: CGFloat
        if let height = pickerVC?.photoToolbar.viewHeight {
            pickerViewHeight = height
        }else {
            pickerViewHeight = 0
        }
        
        if previewViewHeight != pickerViewHeight {
            if type == .push {
                previewMaskY = previewViewHeight - previewToolbarHeight
                previewMaskHeight = previewToolbarHeight
            }else {
                previewMaskY = 0
                previewMaskHeight = previewViewHeight
            }
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
            pickerVC?.photoToolbar.mask = pickerMaskView
        }
        
        let duration = transitionDuration(using: transitionContext)
        UIView.animate(withDuration: duration - 0.15) {
            if self.type == .push {
                contentView.backgroundColor = backgroundColor.withAlphaComponent(1)
            }else if self.type == .pop {
                contentView.backgroundColor = backgroundColor.withAlphaComponent(0)
            }
        }
        if type == .push {
            let alphaDuration: TimeInterval
            if previewVC.photoToolbar.mask != nil {
                alphaDuration = 0.15
                UIView.animate(withDuration: duration - 0.2, delay: 0, options: [.curveEaseIn]) {
                    previewVC.photoToolbar.mask?.frame = CGRect(
                        x: 0, y: 0,
                        width: contentView.width, height: previewViewHeight
                    )
                    pickerVC?.photoToolbar.mask?.frame = CGRect(
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
        }else if type == .pop {
            if previewVC.photoToolbar.mask != nil {
                UIView.animate(withDuration: duration - 0.2, delay: 0, options: [.curveLinear]) {
                    previewVC.photoToolbar.mask?.frame = CGRect(
                        x: 0, y: previewViewHeight - previewToolbarHeight,
                        width: contentView.width, height: previewToolbarHeight
                    )
                    pickerVC?.photoToolbar.mask?.frame = CGRect(
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
        }
        
        UIView.animate(
            withDuration: duration,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0,
            options: [.layoutSubviews, .curveEaseOut]
        ) {
            if self.type == .push {
                self.pushImageView.frame = rect
            }else if self.type == .pop {
                if rect.isEmpty {
                    fromView?.transform = CGAffineTransform.init(scaleX: 0.1, y: 0.1)
                    fromView?.alpha = 0
                }else {
                    fromView?.frame = rect
                }
            }
            if let picker = pickerVC?.pickerController {
                picker.pickerDelegate?
                    .pickerController(picker, animateTransition: self.type)
            }
        } completion: { _ in
            pickerVC?.photoToolbar.mask = nil
            previewVC.photoToolbar.mask = nil
            previewVC.isTransitioning = false
            if self.type == .push {
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
                pickerVC?.photoToolbar.alpha = 1
            }else if self.type == .pop {
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
    }
    
    // swiftlint:disable function_body_length
    // swiftlint:disable cyclomatic_complexity
    func presentTransition(
        using transitionContext: UIViewControllerContextTransitioning
    ) {
        // swiftlint:enable function_body_length
        // swiftlint:enable cyclomatic_complexity
        guard let fromVC = transitionContext.viewController(forKey: .from),
              let toVC = transitionContext.viewController(forKey: .to) else {
            transitionContext.completeTransition(true)
            return
        }
        
        let containerView = transitionContext.containerView
        let contentView = UIView()
        
        var pickerController: PhotoPickerController
        if type == .present {
            pickerController = toVC as! PhotoPickerController
        }else {
            pickerController = fromVC as! PhotoPickerController
        }
        let backgroundColor = PhotoManager.isDark ?
            pickerController.config.previewView.backgroundDarkColor :
            pickerController.config.previewView.backgroundColor
        var fromView: UIView
        var previewView: UIView?
        var toRect: CGRect = .zero
        let previewViewController = pickerController.previewViewController
        previewViewController?.isTransitioning = true
        if type == .present {
            contentView.frame = toVC.view.bounds
            containerView.addSubview(contentView)
            containerView.addSubview(toVC.view)
            contentView.backgroundColor = backgroundColor.withAlphaComponent(0)
            previewViewController?.view.backgroundColor = backgroundColor.withAlphaComponent(0)
            pickerController.view.backgroundColor = nil
            pickerController.navigationBar.alpha = 0
            previewViewController?.photoToolbar.alpha = 0
            previewViewController?.navBgView?.alpha = 0
            previewViewController?.collectionView.isHidden = true
            fromView = pushImageView
            let currentPreviewIndex: Int
            if let index = previewViewController?.currentPreviewIndex {
                currentPreviewIndex = index
            }else {
                currentPreviewIndex = 0
            }
            if let view = pickerController.pickerDelegate?.pickerController(
                pickerController,
                presentPreviewViewForIndexAt: currentPreviewIndex) {
                let rect = view.convert(view.bounds, to: contentView)
                fromView.frame = rect
                if view.layer.cornerRadius > 0 {
                    pushImageView.layer.cornerRadius = view.layer.cornerRadius
                    pushImageView.layer.masksToBounds = true
                }
                previewView = view
            }else if let rect = pickerController.pickerDelegate?.pickerController(
                        pickerController,
                        presentPreviewFrameForIndexAt: currentPreviewIndex),
                     !rect.equalTo(.zero) {
                fromView.frame = rect
            }else {
                fromView.center = CGPoint(x: toVC.view.width * 0.5, y: toVC.view.height * 0.5)
            }
            
            if let image = pickerController.pickerDelegate?.pickerController(
                pickerController,
                presentPreviewImageForIndexAt: currentPreviewIndex) {
                pushImageView.image = image
            }
            var photoAsset: PhotoAsset?
            if pickerController.previewType == .picker {
                photoAsset = pickerController.previewViewController?.photoAsset(for: currentPreviewIndex)
            }else if !pickerController.selectedAssetArray.isEmpty {
                photoAsset = pickerController.selectedAssetArray[currentPreviewIndex]
            }else {
                photoAsset = pickerController.previewViewController?.photoAsset(for: currentPreviewIndex)
            }
            
            if let photoAsset = photoAsset {
                var reqeustAsset = photoAsset.phAsset != nil
                #if HXPICKER_ENABLE_EDITOR
                if photoAsset.editedResult != nil {
                    reqeustAsset = false
                }
                #endif
                if let phAsset = photoAsset.phAsset, reqeustAsset {
                    requestAssetImage(for: phAsset, isGIF: photoAsset.isGifAsset, isHEIC: photoAsset.photoFormat == "heic")
                }else if pushImageView.image == nil || photoAsset.isLocalAsset {
                    if let image = photoAsset.originalImage {
                        pushImageView.image = image
                    }
                }
                #if canImport(Kingfisher)
                if let networkImage = photoAsset.networkImageAsset {
                    let cacheKey = networkImage.originalURL.cacheKey
                    if ImageCache.default.isCached(forKey: cacheKey) {
                        ImageCache.default.retrieveImage(
                            forKey: cacheKey,
                            options: [],
                            callbackQueue: .mainAsync
                        ) { [weak self] in
                            guard let self = self else { return }
                            switch $0 {
                            case .success(let value):
                                if let image = value.image, self.pushImageView.superview != nil {
                                    self.pushImageView.setImage(image, duration: 0.4, animated: true)
                                }
                            default:
                                break
                            }
                        }
                    }else {
                        let cacheKey = networkImage.thumbnailURL.cacheKey
                        if ImageCache.default.isCached(forKey: cacheKey) {
                            ImageCache.default.retrieveImage(
                                forKey: cacheKey,
                                options: [],
                                callbackQueue: .mainAsync
                            ) { [weak self] in
                                guard let self = self else { return }
                                switch $0 {
                                case .success(let value):
                                    if let image = value.image,
                                       self.pushImageView.superview != nil {
                                        self.pushImageView.setImage(image, duration: 0.4, animated: true)
                                    }
                                default:
                                    break
                                }
                            }
                        }
                    }
                }
                #endif
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
        }else {
            contentView.frame = fromVC.view.bounds
            previewViewController?.view.insertSubview(contentView, at: 0)
            previewViewController?.view.backgroundColor = .clear
            previewViewController?.collectionView.isHidden = true
            pickerController.view.backgroundColor = .clear
            contentView.backgroundColor = backgroundColor
            if let pickerViewController = pickerController.pickerViewController,
               let previewViewController = previewViewController,
               pickerViewController.isShowToolbar,
               previewViewController.isShowToolbar {
                pickerViewController.photoToolbar.selectViewOffset = previewViewController.photoToolbar.selectViewOffset
            }
            let currentPreviewIndex: Int
            if let index = previewViewController?.currentPreviewIndex {
                currentPreviewIndex = index
            }else {
                currentPreviewIndex = 0
            }
            var hasCornerRadius = false
            if let view = pickerController.pickerDelegate?.pickerController(
                pickerController,
                dismissPreviewViewForIndexAt: currentPreviewIndex) {
                toRect = view.convert(view.bounds, to: containerView)
                previewView = view
                if view.layer.cornerRadius > 0 {
                    hasCornerRadius = true
                }
            }else if let rect = pickerController.pickerDelegate?.pickerController(
                        pickerController,
                        dismissPreviewFrameForIndexAt: currentPreviewIndex),
                     !rect.equalTo(.zero) {
                toRect = rect
            }
            if let previewVC = previewViewController,
               let cell = previewVC.getCell(for: previewVC.currentPreviewIndex),
               let cellContentView = cell.scrollContentView {
                cellContentView.hiddenOtherSubview()
                fromView = cellContentView
                fromView.frame = cellContentView.convert(cellContentView.bounds, to: containerView)
            }else {
                fromView = pushImageView
            }
            
            if hasCornerRadius {
                fromView.layer.masksToBounds = true
            }
        }
        if let photoBrowser = pickerController as? PhotoBrowser {
            if photoBrowser.hideSourceView {
                previewView?.isHidden = true
            }
        }else {
            previewView?.isHidden = true
        }
        contentView.addSubview(fromView)
        let duration: TimeInterval
        if type == .dismiss && !toRect.isEmpty {
            duration = transitionDuration(using: transitionContext) - 0.2
        }else {
            duration = transitionDuration(using: transitionContext)
        }
        let colorDuration = duration - 0.15
        let colorDelay: TimeInterval
        if type == .present {
            colorDelay = 0.05
        }else {
            colorDelay = 0
        }
        UIView.animate(withDuration: colorDuration, delay: colorDelay, options: [ .curveLinear]) {
            if self.type == .present {
                previewViewController?.photoToolbar.alpha = 1
                previewViewController?.navBgView?.alpha = 1
                contentView.backgroundColor = backgroundColor.withAlphaComponent(1)
            }else if self.type == .dismiss {
                previewViewController?.photoToolbar.alpha = 0
                previewViewController?.navBgView?.alpha = 0
                contentView.backgroundColor = backgroundColor.withAlphaComponent(0)
            }
        }
        let currentPreviewIndex: Int
        if let index = previewViewController?.currentPreviewIndex {
            currentPreviewIndex = index
        }else {
            currentPreviewIndex = 0
        }
        UIView.animate(
            withDuration: duration,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0,
            options: [.layoutSubviews, .curveEaseOut]
        ) {
            if self.type == .present {
                pickerController.navigationBar.alpha = 1
                if self.pushImageView.layer.cornerRadius > 0 {
                    self.pushImageView.layer.cornerRadius = 0
                }
                self.pushImageView.frame = toRect
            }else if self.type == .dismiss {
                pickerController.navigationBar.alpha = 0
                if let previewView = previewView, previewView.layer.cornerRadius > 0 {
                    fromView.layer.cornerRadius = previewView.layer.cornerRadius
                }
                if toRect.isEmpty {
                    fromView.transform = CGAffineTransform.init(scaleX: 0.1, y: 0.1)
                    fromView.alpha = 0
                }else {
                    fromView.frame = toRect
                }
            }
            pickerController.pickerDelegate?
                .pickerController(pickerController, animateTransition: self.type)
        } completion: { _ in
            previewView?.isHidden = false
            previewViewController?.isTransitioning = false
            if self.type == .present {
                if let requestID = self.requestID {
                    PHImageManager.default().cancelImageRequest(requestID)
                    self.requestID = nil
                }
                pickerController.pickerDelegate?.pickerController(
                    pickerController,
                    previewPresentComplete: currentPreviewIndex
                )
                previewViewController?.view.backgroundColor = backgroundColor.withAlphaComponent(1)
                previewViewController?.setCurrentCellImage(image: self.pushImageView.image)
                previewViewController?.collectionView.isHidden = false
                previewViewController?.updateColors()
                pickerController.configBackgroundColor()
                self.pushImageView.removeFromSuperview()
                contentView.removeFromSuperview()
                transitionContext.completeTransition(true)
            }else {
                pickerController.pickerDelegate?.pickerController(
                    pickerController,
                    previewDismissComplete: currentPreviewIndex
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
    
    func requestAssetImage(for asset: PHAsset, isGIF: Bool = false, isHEIC: Bool = false) {
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
