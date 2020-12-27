//
//  HXPHPickerTransition.swift
//  HXPHPickerExample
//
//  Created by Silence on 2020/12/9.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit
import Photos

enum HXPHPickerControllerTransitionType: Int {
    case push
    case pop
    case present
    case dismiss
}

class HXPHPickerControllerTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    var type: HXPHPickerControllerTransitionType = .push
    
    var requestID: PHImageRequestID?
    lazy var pushImageView: UIImageView = {
        let imageView = UIImageView.init()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    init(type: HXPHPickerControllerTransitionType) {
        super.init()
        self.type = type
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        if type == .pop || type == .present {
            return 0.5
        }else if type == .dismiss {
            return 0.65
        }
        return 0.45
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if type == .push || type == .pop {
            pushTransition(using: transitionContext)
        }else {
            presentTransition(using: transitionContext)
        }
    }
    
    func pushTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let fromVC = transitionContext.viewController(forKey: .from)!
        let toVC = transitionContext.viewController(forKey: .to)!
        
        var previewVC: HXPHPreviewViewController?
        var pickerVC: HXPHPickerViewController?
        
        let containerView = transitionContext.containerView
        let contentView = UIView.init(frame: fromVC.view.bounds)
        if type == .push {
            pickerVC = fromVC as? HXPHPickerViewController
            previewVC = toVC as? HXPHPreviewViewController
        }else if type == .pop {
            pickerVC = toVC as? HXPHPickerViewController
            previewVC = fromVC as? HXPHPreviewViewController
        }
        
        let backgroundColor = HXPHManager.shared.isDark ? previewVC?.config.backgroundDarkColor : previewVC?.config.backgroundColor
        
        let photoAsset = previewVC?.previewAssets[previewVC!.currentPreviewIndex]
         
        var fromView: UIView?
        var toView: UIView?
        
        if type == .push {
            containerView.addSubview(fromVC.view)
            containerView.addSubview(toVC.view)
            fromVC.view.insertSubview(contentView, at: 1)
            contentView.backgroundColor = backgroundColor?.withAlphaComponent(0)
            contentView.addSubview(pushImageView)
            
            if photoAsset != nil && pickerVC != nil {
                let cell = pickerVC!.getCell(for: photoAsset!)
                if cell != nil {
                    pushImageView.image = cell?.imageView.image
                    pushImageView.frame = cell?.imageView.convert(cell?.imageView.bounds ?? CGRect.zero, to: containerView) ?? CGRect.zero
                    fromView = cell
                }else {
                    pushImageView.center = CGPoint(x: toVC.view.hx_width * 0.5, y: toVC.view.hx_height * 0.5)
                }
                
                if photoAsset!.asset != nil {
                    requestAssetImage(for: photoAsset!.asset!)
                }else if pushImageView.image == nil {
                    pushImageView.image = photoAsset?.originalImage
                }
            }
            
            previewVC?.collectionView.isHidden = true
            previewVC?.bottomView.alpha = 0
            previewVC?.view.backgroundColor = backgroundColor?.withAlphaComponent(0)
        }else if type == .pop {
            containerView.addSubview(toVC.view)
            containerView.addSubview(fromVC.view)
            toVC.view.insertSubview(contentView, at: 1)
            contentView.backgroundColor = backgroundColor
            
            let cell = previewVC!.getCell(for: previewVC!.currentPreviewIndex)
            fromView = cell?.scrollContentView
            fromView?.frame = cell?.scrollContentView?.convert(cell?.scrollContentView?.bounds ?? CGRect.zero, to: containerView) ?? CGRect.zero
            contentView.addSubview(fromView!)
            
            if photoAsset != nil && pickerVC != nil {
                toView = pickerVC?.getCell(for: photoAsset!)
                if toView == nil {
                    pickerVC?.scrollToCenter(for: photoAsset!)
                    pickerVC?.reloadCell(for: photoAsset!)
                    toView = pickerVC?.getCell(for: photoAsset!)
                }else {
                    pickerVC?.scrollCellToVisibleArea(toView as! HXPHPickerViewCell)
                }
            }
            
            previewVC?.collectionView.isHidden = true
            previewVC?.view.backgroundColor = UIColor.clear
        }
        
        var rect: CGRect = .zero
        if type == .push {
            if photoAsset != nil {
                rect = getPreviewViewFrame(photoAsset: photoAsset!, size: toVC.view.hx_size)
            }
            fromView?.isHidden = true
        }else if type == .pop {
            rect = toView?.convert(toView?.bounds ?? CGRect.zero, to: containerView) ?? .zero
            toView?.isHidden = true
            if HXPHAssetManager.authorizationStatusIsLimited() && pickerVC?.config.bottomView.showPrompt ?? false {
                pickerVC?.bottomView.alpha = 0
            }
        }
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext) - 0.125) {
            if self.type == .push {
                previewVC?.bottomView.alpha = 1
                if HXPHAssetManager.authorizationStatusIsLimited() && pickerVC?.config.bottomView.showPrompt ?? false {
                    pickerVC?.bottomView.alpha = 0
                }
                contentView.backgroundColor = backgroundColor?.withAlphaComponent(1)
            }else if self.type == .pop {
                previewVC?.bottomView.alpha = 0
                if HXPHAssetManager.authorizationStatusIsLimited() && pickerVC?.config.bottomView.showPrompt ?? false {
                    pickerVC?.bottomView.alpha = 1
                }
                contentView.backgroundColor = backgroundColor?.withAlphaComponent(0)
            }
        }
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [.layoutSubviews, .curveEaseOut]) {
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
        } completion: { (isFinished) in
            if self.type == .push {
                if self.requestID != nil {
                    PHImageManager.default().cancelImageRequest(self.requestID!)
                    self.requestID = nil
                }
                pickerVC?.bottomView.alpha = 1
                fromView?.isHidden = false
                previewVC?.setCurrentCellImage(image: self.pushImageView.image)
                previewVC?.collectionView.isHidden = false
                previewVC?.configColor()
                contentView.removeFromSuperview()
                transitionContext.completeTransition(true)
            }else if self.type == .pop {
                toView?.isHidden = false
                UIView.animate(withDuration: 0.25, delay: 0, options: [.allowUserInteraction]) {
                    fromView?.alpha = 0
                } completion: { (isFinished) in
                    contentView.removeFromSuperview()
                    transitionContext.completeTransition(true)
                }
            }
        }
    }
    func presentTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let fromVC = transitionContext.viewController(forKey: .from)!
        let toVC = transitionContext.viewController(forKey: .to)!
        
        let containerView = transitionContext.containerView
        let contentView = UIView.init(frame: fromVC.view.bounds)
        
        var pickerController: HXPHPickerController
        if type == .present {
            pickerController = toVC as! HXPHPickerController
        }else {
            pickerController = fromVC as! HXPHPickerController
        }
        let backgroundColor = HXPHManager.shared.isDark ? pickerController.config.previewView.backgroundDarkColor : pickerController.config.previewView.backgroundColor
        var fromView: UIView
        var previewView: UIView?
        var toRect: CGRect = .zero
        if type == .present {
            containerView.addSubview(contentView)
            containerView.addSubview(toVC.view)
            contentView.backgroundColor = backgroundColor.withAlphaComponent(0)
            pickerController.previewViewController()?.view.backgroundColor = backgroundColor.withAlphaComponent(0)
            pickerController.view.backgroundColor = nil
            pickerController.previewViewController()?.bottomView.alpha = 0
            pickerController.navigationBar.alpha = 0
            pickerController.previewViewController()?.collectionView.isHidden = true
            fromView = pushImageView
            let currentPreviewIndex = pickerController.previewIndex
            if let view = pickerController.pickerControllerDelegate?.pickerController?(pickerController, presentPreviewViewForIndexAt: currentPreviewIndex) {
                let rect = view.convert(view.bounds, to: contentView)
                fromView.frame = rect
                previewView = view
            }else if let rect = pickerController.pickerControllerDelegate?.pickerController?(pickerController, presentPreviewFrameForIndexAt: currentPreviewIndex) {
                fromView.frame = rect
            }else {
                fromView.center = CGPoint(x: toVC.view.hx_width * 0.5, y: toVC.view.hx_height * 0.5)
            }
            
            if let image = pickerController.pickerControllerDelegate?.pickerController?(pickerController, presentPreviewImageForIndexAt: pickerController.previewIndex) {
                pushImageView.image = image
            }
            if !pickerController.selectedAssetArray.isEmpty {
                let photoAsset = pickerController.selectedAssetArray[pickerController.previewIndex]
                if photoAsset.asset != nil {
                    requestAssetImage(for: photoAsset.asset!)
                }else if pushImageView.image == nil {
                    pushImageView.image = photoAsset.originalImage
                }
                toRect = getPreviewViewFrame(photoAsset: photoAsset, size: toVC.view.hx_size)
            }
        }else {
            pickerController.previewViewController()?.view.insertSubview(contentView, at: 0)
            pickerController.previewViewController()?.view.backgroundColor = .clear
            pickerController.previewViewController()?.collectionView.isHidden = true
            pickerController.view.backgroundColor = .clear
            contentView.backgroundColor = backgroundColor
            let currentPreviewIndex = pickerController.previewViewController()?.currentPreviewIndex ?? 0
            if let view = pickerController.pickerControllerDelegate?.pickerController?(pickerController, dismissPreviewViewForIndexAt: currentPreviewIndex) {
                toRect = view.convert(view.bounds, to: containerView)
                previewView = view
            }else if let rect = pickerController.pickerControllerDelegate?.pickerController?(pickerController, dismissPreviewFrameForIndexAt: currentPreviewIndex) {
                toRect = rect
            }
            if let previewVC = pickerController.previewViewController(), let cell = previewVC.getCell(for: previewVC.currentPreviewIndex), let cellContentView = cell.scrollContentView {
                cellContentView.hiddenOtherSubview()
                fromView = cellContentView
                fromView.frame = cellContentView.convert(cellContentView.bounds, to: containerView)
            }else {
                fromView = pushImageView
            }

        }
        previewView?.isHidden = true
        contentView.addSubview(fromView)
        let duration = (self.type == .dismiss && !toRect.isEmpty) ? transitionDuration(using: transitionContext) - 0.2 : transitionDuration(using: transitionContext)
        let colorDuration = duration - 0.15
        let colorDelay = type == .present ? 0.05 : 0
        UIView.animate(withDuration: colorDuration, delay: colorDelay, options: [.curveLinear]) {
            if self.type == .present {
                pickerController.navigationBar.alpha = 1
                pickerController.previewViewController()?.bottomView.alpha = 1
                contentView.backgroundColor = backgroundColor.withAlphaComponent(1)
            }else if self.type == .dismiss {
                pickerController.navigationBar.alpha = 0
                pickerController.previewViewController()?.bottomView.alpha = 0
                contentView.backgroundColor = backgroundColor.withAlphaComponent(0)
            }
        } completion: { (isFinished) in
        }
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [.layoutSubviews, .curveEaseOut]) {
            if self.type == .present {
                self.pushImageView.frame = toRect
            }else if self.type == .dismiss {
                if toRect.isEmpty {
                    fromView.transform = CGAffineTransform.init(scaleX: 0.1, y: 0.1)
                    fromView.alpha = 0
                }else {
                    fromView.frame = toRect
                }
            }
        } completion: { (isFinished) in
            previewView?.isHidden = false
            if self.type == .present {
                if self.requestID != nil {
                    PHImageManager.default().cancelImageRequest(self.requestID!)
                    self.requestID = nil
                }
                pickerController.pickerControllerDelegate?.pickerController?(pickerController, previewPresentComplete: pickerController.previewIndex)
                pickerController.previewViewController()?.view.backgroundColor = backgroundColor.withAlphaComponent(1)
                pickerController.previewViewController()?.setCurrentCellImage(image: self.pushImageView.image)
                pickerController.previewViewController()?.collectionView.isHidden = false
                pickerController.previewViewController()?.configColor()
                pickerController.configBackgroundColor()
                contentView.removeFromSuperview()
                transitionContext.completeTransition(true)
            }else {
                let currentPreviewIndex = pickerController.previewViewController()?.currentPreviewIndex ?? 0
                pickerController.pickerControllerDelegate?.pickerController?(pickerController, previewDismissComplete: currentPreviewIndex)
                if toRect.isEmpty {
                    contentView.removeFromSuperview()
                    transitionContext.completeTransition(true)
                }else {
                    UIView.animate(withDuration: 0.2, delay: 0, options: [.allowUserInteraction]) {
                        fromView.alpha = 0
                    } completion: { (isFinished) in
                        contentView.removeFromSuperview()
                        transitionContext.completeTransition(true)
                    }
                }
            }
        }
    }
    
    func requestAssetImage(for asset: PHAsset) {
        let options = PHImageRequestOptions.init()
        options.resizeMode = .fast
        options.isSynchronous = false
        requestID = HXPHAssetManager.requestImageData(for: asset, options: options) { (imageData, dataUTI, imageOrientation, info) in
            if imageData != nil {
                var image: UIImage?
                if imageOrientation != .up {
                    image = UIImage.init(data: imageData!)?.hx_normalizedImage()
                }else {
                    image = UIImage.init(data: imageData!)
                }
                DispatchQueue.main.async {
                    self.pushImageView.image = image
                }
            }
            if HXPHAssetManager.assetDownloadFinined(for: info) ||
                HXPHAssetManager.assetDownloadCancel(for: info){
                self.requestID = nil
            }
        }
    }
    func getPreviewViewFrame(photoAsset: HXPHAsset, size: CGSize) -> CGRect {
        var imageSize: CGSize = .zero
        var imageCenter: CGPoint = .zero
        if UIDevice.current.hx_isPortrait {
            let aspectRatio = size.width / photoAsset.imageSize.width
            let contentWidth = size.width
            let contentHeight = photoAsset.imageSize.height * aspectRatio
            imageSize = CGSize(width: contentWidth, height: contentHeight)
            if contentHeight < size.height {
                imageCenter = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
            }
        }else {
            let aspectRatio = size.height / photoAsset.imageSize.height
            let contentWidth = photoAsset.imageSize.width * aspectRatio
            let contentHeight = size.height
            imageSize = CGSize(width: contentWidth, height: contentHeight)
        }
        var rectY: CGFloat
        if imageCenter.equalTo(.zero) {
            rectY = 0
        }else {
            rectY = (size.height - imageSize.height) * 0.5
        }
        return CGRect(x: (size.width - imageSize.width) * 0.5, y: rectY, width: imageSize.width, height: imageSize.height)
    }
}
