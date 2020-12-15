//
//  HXPHPickerTransition.swift
//  HXPHPickerExample
//
//  Created by 洪欣 on 2020/12/9.
//  Copyright © 2020 洪欣. All rights reserved.
//

import UIKit
import Photos

enum HXPHPickerControllerTransitionType: Int {
    case push
    case pop
    case persent
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
        if type == .pop {
            return 0.5
        }
        return 0.45
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        transition(using: transitionContext)
    }
    
    func transition(using transitionContext: UIViewControllerContextTransitioning) {
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
            
            if photoAsset != nil {
                let cell = pickerVC!.getCell(for: photoAsset!)
                if cell != nil {
                    pushImageView.image = cell?.imageView.image
                    pushImageView.frame = cell?.imageView.convert(cell?.imageView.bounds ?? CGRect.zero, to: containerView) ?? CGRect.zero
                    fromView = cell
                }else {
                    pushImageView.center = CGPoint(x: toVC.view.hx_width * 0.5, y: toVC.view.hx_height * 0.5)
                }
                
                if photoAsset!.asset != nil {
                    let options = PHImageRequestOptions.init()
                    options.resizeMode = .fast
                    options.isSynchronous = false
                    requestID = HXPHAssetManager.requestImageData(for: photoAsset!.asset!, options: options) { (imageData, dataUTI, imageOrientation, info) in
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
            
            if photoAsset != nil {
                toView = pickerVC?.getCell(for: photoAsset!)
                if toView == nil {
                    pickerVC?.scrollToCenter(for: photoAsset!)
                    pickerVC?.reloadCell(for: photoAsset!)
                    toView = pickerVC?.getCell(for: photoAsset!)
                }else {
                    pickerVC?.scrollToCell(toView as! HXPHPickerViewCell)
                }
            }
            
            previewVC?.collectionView.isHidden = true
            previewVC?.view.backgroundColor = UIColor.clear
        }
        
        var rect: CGRect = .zero
        if type == .push {
            var imageSize: CGSize = .zero
            var imageCenter: CGPoint = .zero
            if photoAsset != nil {
                if UIDevice.current.hx_isPortrait {
                    let aspectRatio = toVC.view.hx_width / photoAsset!.imageSize.width
                    let contentWidth = toVC.view.hx_width
                    let contentHeight = photoAsset!.imageSize.height * aspectRatio
                    imageSize = CGSize(width: contentWidth, height: contentHeight)
                    if contentHeight < toVC.view.hx_height {
                        imageCenter = CGPoint(x: toVC.view.hx_width * 0.5, y: toVC.view.hx_height * 0.5)
                    }
                }else {
                    let aspectRatio = toVC.view.hx_height / photoAsset!.imageSize.height
                    let contentWidth = photoAsset!.imageSize.width * aspectRatio
                    let contentHeight = toVC.view.hx_height
                    imageSize = CGSize(width: contentWidth, height: contentHeight)
                }
            }
            var rectY: CGFloat
            if imageCenter.equalTo(.zero) {
                rectY = 0
            }else {
                rectY = (toVC.view.hx_height - imageSize.height) * 0.5
            }
            rect = CGRect(x: (toVC.view.hx_width - imageSize.width) * 0.5, y: rectY, width: imageSize.width, height: imageSize.height)
            fromView?.isHidden = true
        }else if type == .pop {
            rect = toView?.convert(toView?.bounds ?? CGRect.zero, to: containerView) ?? .zero
            toView?.isHidden = true
            if HXPHAssetManager.authorizationStatusIsLimited() && pickerVC?.config.bottomView.showPrompt ?? false {
                pickerVC?.bottomView.alpha = 0
            }
        }
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext) - 0.1) {
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
    
    deinit {
//        print("\(self) deint")
    }
}
