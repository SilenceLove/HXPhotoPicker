//
//  PickerInteractiveTransition.swift
//  HXPHPickerExample
//
//  Created by Slience on 2020/12/26.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

public enum PickerInteractiveTransitionType {
    case pop
    case dismiss
}

class PickerInteractiveTransition: UIPercentDrivenInteractiveTransition, UIGestureRecognizerDelegate {
    var type: PickerInteractiveTransitionType
    weak var previewViewController: PhotoPreviewViewController?
    weak var pickerController: PhotoPickerController?
    lazy var panGestureRecognizer: UIPanGestureRecognizer = {
        let panGestureRecognizer = UIPanGestureRecognizer(
            target: self,
            action: #selector(panGestureRecognizerAction(panGR:))
        )
        return panGestureRecognizer
    }()
    lazy var backgroundView: UIView = {
        let backgroundView = UIView()
        return backgroundView
    }()
    var previewView: PhotoPreviewViewCell?
    var toView: UIView?
    var beforePreviewFrame: CGRect = .zero
    var previewCenter: CGPoint = .zero
    var beganPoint: CGPoint = .zero
    var canInteration: Bool = false
    var beganInterPercent: Bool = false
    var previewBackgroundColor: UIColor?
    var pickerControllerBackgroundColor: UIColor?
    weak var transitionContext: UIViewControllerContextTransitioning?
    var slidingGap: CGPoint = .zero
    var navigationBarAlpha: CGFloat = 1
    var canTransition: Bool = false
    
    init(
        panGestureRecognizerFor previewViewController: PhotoPreviewViewController,
        type: PickerInteractiveTransitionType
    ) {
        self.type = type
        super.init()
        self.previewViewController = previewViewController
        panGestureRecognizer.delegate = self
        previewViewController.view.addGestureRecognizer(panGestureRecognizer)
    }
    
    init(
        panGestureRecognizerFor pickerController: PhotoPickerController,
        type: PickerInteractiveTransitionType) {
        self.type = type
        super.init()
        self.pickerController = pickerController
        panGestureRecognizer.delegate = self
        pickerController.view.addGestureRecognizer(panGestureRecognizer)
    }
    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith
            otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if otherGestureRecognizer is UITapGestureRecognizer && otherGestureRecognizer.view is UIScrollView {
            return false
        }
        return !(previewViewController?.collectionView.isDragging ?? false)
    }
    
    @objc func panGestureRecognizerAction(panGR: UIPanGestureRecognizer) {
        let preposition = prepositionInteration(panGR: panGR)
        if !preposition.0 {
            return
        }
        let isTracking = preposition.1
        switch panGR.state {
        case .began:
            beginInteration(panGR: panGR)
        case .changed:
            changeInteration(
                panGR: panGR,
                isTracking: isTracking
            )
        case .ended, .cancelled, .failed:
            endInteration(panGR: panGR)
        default:
            break
        }
    }
    func prepositionInteration(
        panGR: UIPanGestureRecognizer) -> (Bool, Bool) {
        var isTracking = false
        if type == .pop {
            if let cell = previewViewController?.getCell(
                for: previewViewController?.currentPreviewIndex ?? 0),
               let contentView = cell.scrollContentView {
                let toRect = contentView.convert(contentView.bounds, to: cell.scrollView)
                if  (cell.scrollView.isZooming ||
                        cell.scrollView.isZoomBouncing ||
                        cell.scrollView.contentOffset.y > 0 ||
                        !cell.allowInteration ||
                        (toRect.minX != 0 && contentView.width > cell.scrollView.width))
                        && !canInteration {
                    return (false, isTracking)
                }else {
                    isTracking = cell.scrollView.isTracking
                }
            }
        }else {
            let previewVC = pickerController?.previewViewController
            if pickerController?.topViewController != previewVC {
                return (false, isTracking)
            }
            if let cell = previewVC?.getCell(
                for: previewVC?.currentPreviewIndex ?? 0),
               let contentView = cell.scrollContentView {
                let toRect = contentView.convert(contentView.bounds, to: cell.scrollView)
                if  (cell.scrollView.isZooming ||
                        cell.scrollView.isZoomBouncing ||
                        cell.scrollView.contentOffset.y > 0 ||
                        !cell.allowInteration ||
                        (toRect.minX != 0 && contentView.width > cell.scrollView.width)) && !canInteration {
                    return (false, isTracking)
                }else {
                    isTracking = cell.scrollView.isTracking
                }
            }
        }
        return (true, isTracking)
    }
    func beginInteration(panGR: UIPanGestureRecognizer) {
        if canInteration {
            return
        }
        if type == .pop, let previewViewController = previewViewController {
            let velocity = panGR.velocity(in: previewViewController.view)
            let isVerticalGesture = (abs(velocity.y) > abs(velocity.x) && velocity.y > 0)
            if !isVerticalGesture {
                return
            }
            beganPoint = panGR.location(in: panGR.view)
            canInteration = true
            canTransition = true
            previewViewController.navigationController?.popViewController(animated: true)
        }else if type == .dismiss, let pickerController = pickerController {
            let velocity = panGR.velocity(in: pickerController.view)
            let isVerticalGesture = (abs(velocity.y) > abs(velocity.x) && velocity.y > 0)
            if !isVerticalGesture {
                return
            }
            beganPoint = panGR.location(in: panGR.view)
            canInteration = true
            canTransition = true
            pickerController.dismiss(animated: true, completion: nil)
        }
    }
    func changeInteration(
        panGR: UIPanGestureRecognizer,
        isTracking: Bool) {
        if !canInteration || !beganInterPercent {
            if isTracking {
                beginInteration(panGR: panGR)
                if canInteration {
                    slidingGap = panGR.translation(in: panGR.view)
                }
            }
            return
        }
        if let previewViewController = previewViewController, let previewView = previewView {
            let translation = panGR.translation(in: panGR.view)
            var scale = (translation.y - slidingGap.y) / (previewViewController.view.height)
            if scale > 1 {
                scale = 1
            }else if scale < 0 {
                scale = 0
            }
            var previewViewScale = 1 - scale
            if previewViewScale < 0.4 {
                previewViewScale = 0.4
            }
            previewView.center = CGPoint(
                x: previewCenter.x + (translation.x - slidingGap.x),
                y: previewCenter.y + (translation.y - slidingGap.y)
            )
            previewView.transform = CGAffineTransform.init(scaleX: previewViewScale, y: previewViewScale)
            
            var alpha = 1 - scale * 2
            if alpha < 0 {
                alpha = 0
            }
            backgroundView.alpha = alpha
            let toVC = transitionContext?.viewController(forKey: .to) as? PhotoPickerViewController
            if !previewViewController.statusBarShouldBeHidden {
                let hasPreviewMask = previewViewController.bottomView.mask != nil
                if hasPreviewMask {
                    var bottomViewAlpha = 1 - scale * 1.5
                    if bottomViewAlpha < 0 {
                        bottomViewAlpha = 0
                    }
                    previewViewController.bottomView.alpha = bottomViewAlpha
                }else {
                    previewViewController.bottomView.alpha = alpha
                }
                if type == .pop {
                    var maskScale = 1 - scale * 2.85
                    if maskScale < 0 {
                        maskScale = 0
                    }
                    if hasPreviewMask {
                        let maskY = 70 * (1 - maskScale)
                        let maskWidth = previewViewController.bottomView.width
                        let maskHeight = previewViewController.bottomView.height - maskY
                        previewViewController.bottomView.mask?.frame = CGRect(
                            x: 0,
                            y: maskY,
                            width: maskWidth,
                            height: maskHeight
                        )
                    }
                    if toVC?.bottomView.mask != nil {
                        let maskY = 70 * maskScale
                        let maskWidth = previewViewController.bottomView.width
                        let maskHeight = 50 + UIDevice.bottomMargin + 70 * (1 - maskScale)
                        toVC?.bottomView.mask?.frame = CGRect(x: 0, y: maskY, width: maskWidth, height: maskHeight)
                        
                    }
                }else {
                    previewViewController.navigationController?.navigationBar.alpha = alpha
                    navigationBarAlpha = alpha
                }
            }else {
                if type == .pop {
                    toVC?.navigationController?.navigationBar.alpha = 1 - alpha
                    toVC?.bottomView.alpha = 1 - alpha
                }
            }
            if let picker = pickerController {
                picker.pickerDelegate?
                    .pickerController(picker, interPercentUpdate: alpha, type: type)
            }
            update(1 - alpha)
        }
    }
    func endInteration(
        panGR: UIPanGestureRecognizer) {
        canTransition = false
        if !canInteration {
            return
        }
        if let previewViewController = previewViewController {
            let translation = panGR.translation(in: panGR.view)
            let scale = (translation.y - slidingGap.y) / (previewViewController.view.height)
            if scale < 0.15 {
                cancel()
                interPercentDidCancel()
            }else {
                finish()
                interPercentDidFinish()
            }
        }else {
            finish()
            backgroundView.removeFromSuperview()
            previewView?.removeFromSuperview()
            previewView = nil
            previewViewController = nil
            toView = nil
            transitionContext?.completeTransition(true)
            transitionContext = nil
        }
        slidingGap = .zero
    }
    func interPercentDidCancel() {
        if let previewViewController = previewViewController, let previewView = previewView {
            panGestureRecognizer.isEnabled = false
            previewViewController.navigationController?.view.isUserInteractionEnabled = false
            let toVC = self.transitionContext?.viewController(forKey: .to) as? PhotoPickerViewController
            UIView.animate(withDuration: 0.25) {
                previewView.transform = .identity
                previewView.center = self.previewCenter
                self.backgroundView.alpha = 1
                if !previewViewController.statusBarShouldBeHidden {
                    previewViewController.bottomView.alpha = 1
                    if self.type == .pop {
                        let maskWidth = previewViewController.bottomView.width
                        if previewViewController.bottomView.mask != nil {
                            let maskHeight = previewViewController.bottomView.height
                            previewViewController.bottomView.mask?.frame = CGRect(
                                origin: .zero,
                                size: CGSize(
                                    width: maskWidth,
                                    height: maskHeight
                                )
                            )
                        }
                        if toVC?.bottomView.mask != nil {
                            let maskHeight = 50 + UIDevice.bottomMargin
                            toVC?.bottomView.mask?.frame = CGRect(x: 0, y: 70, width: maskWidth, height: maskHeight)
                        }
                    }else {
                        previewViewController.navigationController?.navigationBar.alpha = 1
                    }
                }else {
                    if self.type == .pop {
                        toVC?.navigationController?.navigationBar.alpha = 0
                        toVC?.bottomView.alpha = 0
                    }
                }
                if let picker = self.pickerController {
                    picker.pickerDelegate?
                        .pickerController(picker, interPercentDidCancelAnimation: self.type)
                }
            } completion: { (isFinished) in
                previewViewController.bottomView.mask = nil
                toVC?.bottomView.mask = nil
                self.toView?.isHidden = false
                let toVC = self.transitionContext?.viewController(forKey: .to) as? PhotoPickerViewController
                if previewViewController.statusBarShouldBeHidden {
                    if self.type == .pop {
                        previewViewController.navigationController?.setNavigationBarHidden(true, animated: false)
                        toVC?.navigationController?.setNavigationBarHidden(true, animated: false)
                        toVC?.bottomView.alpha = 1
                        toVC?.navigationController?.navigationBar.alpha = 1
                    }
                }
                self.resetScrollView(for: true)
                previewView.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                previewView.frame = self.beforePreviewFrame
                previewViewController.collectionView.addSubview(previewView)
                previewView.scrollContentView.showOtherSubview()
                self.backgroundView.removeFromSuperview()
                self.previewView = nil
                self.toView = nil
                self.panGestureRecognizer.isEnabled = true
                self.canInteration = false
                self.beganInterPercent = false
                previewViewController.navigationController?.view.isUserInteractionEnabled = true
                self.transitionContext?.completeTransition(false)
                self.transitionContext = nil
            }
        }else {
            toView?.isHidden = false
            toView = nil
        }
    }
    func interPercentDidFinish() {
        if let previewViewController = previewViewController,
            let previewView = previewView {
            panGestureRecognizer.isEnabled = false
            var toRect = toView?.convert(toView?.bounds ?? .zero, to: transitionContext?.containerView) ?? .zero
            if type == .dismiss, let pickerController = pickerController {
                if toRect.isEmpty {
                    toRect = pickerController.pickerDelegate?.pickerController(
                        pickerController,
                        dismissPreviewFrameForIndexAt:
                            previewViewController.currentPreviewIndex
                    ) ?? .zero
                }
                if let toView = toView, toView.layer.cornerRadius > 0 {
                    previewView.layer.masksToBounds = true
                }
                if pickerController.config.prefersStatusBarHidden && !previewViewController.statusBarShouldBeHidden {
                    previewViewController.navigationController?.navigationBar.alpha = navigationBarAlpha
                }
            }
            previewView.scrollContentView.isBacking = true
            let toVC = self.transitionContext?.viewController(forKey: .to) as? PhotoPickerViewController
            
            UIView.animate(
                withDuration: 0.45,
                delay: 0,
                usingSpringWithDamping: 0.8,
                initialSpringVelocity: 0,
                options: [.layoutSubviews, .curveEaseOut]
            ) {
                if let toView = self.toView, toView.layer.cornerRadius > 0 {
                    previewView.layer.cornerRadius = toView.layer.cornerRadius
                }
                if !toRect.isEmpty {
                    previewView.transform = .identity
                    previewView.frame = toRect
                    previewView.scrollView.contentOffset = .zero
                    previewView.scrollContentView.frame = CGRect(x: 0, y: 0, width: toRect.width, height: toRect.height)
                }else {
                    previewView.alpha = 0
                    previewView.transform = CGAffineTransform.init(scaleX: 0.1, y: 0.1)
                }
                self.backgroundView.alpha = 0
                if !previewViewController.statusBarShouldBeHidden {
                    previewViewController.bottomView.alpha = 0
                    if self.type == .pop {
                        let maskWidth = previewViewController.bottomView.width
                        if previewViewController.bottomView.mask != nil {
                            let maskHeight = previewViewController.bottomView.height - 70
                            previewViewController.bottomView.mask?.frame = CGRect(
                                x: 0,
                                y: 70,
                                width: maskWidth,
                                height: maskHeight
                            )
                        }
                        if toVC?.bottomView.mask != nil {
                            let maskHeight = UIDevice.bottomMargin + 120
                            toVC?.bottomView.mask?.frame = CGRect(x: 0, y: 0, width: maskWidth, height: maskHeight)
                        }
                    }else {
                        previewViewController.navigationController?.navigationBar.alpha = 0
                    }
                }else {
                    if self.type == .pop {
                        toVC?.bottomView.alpha = 1
                        toVC?.navigationController?.navigationBar.alpha = 1
                    }
                }
                if let picker = self.pickerController {
                    picker.pickerDelegate?
                        .pickerController(picker, interPercentDidFinishAnimation: self.type)
                }
            } completion: { (isFinished) in
                previewViewController.bottomView.mask = nil
                toVC?.bottomView.mask = nil
                self.toView?.isHidden = false
                UIView.animate(withDuration: 0.2) {
                    previewView.alpha = 0
                } completion: { (isFinished) in
                    self.backgroundView.removeFromSuperview()
                    previewView.removeFromSuperview()
                    if self.type == .dismiss, let pickerController = self.pickerController {
                        pickerController.pickerDelegate?.pickerController(
                            pickerController,
                            previewDismissComplete: previewViewController.currentPreviewIndex
                        )
                    }else if self.type == .pop {
                        toVC?.collectionView.layer.removeAllAnimations()
                    }
                    self.previewView = nil
                    self.previewViewController = nil
                    self.toView = nil
                    self.panGestureRecognizer.isEnabled = true
                    self.transitionContext?.completeTransition(true)
                    self.transitionContext = nil
                }
            }
        }else {
            toView?.isHidden = false
            toView = nil
        }
    }
    public override func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext
        if type == .pop {
            popTransition(transitionContext)
        }else {
            dismissTransition(transitionContext)
        }
    }
    func popTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        let previewViewController = transitionContext.viewController(forKey: .from) as! PhotoPreviewViewController
        previewBackgroundColor = previewViewController.view.backgroundColor
        previewViewController.view.backgroundColor = .clear
        let pickerViewController = transitionContext.viewController(forKey: .to) as! PhotoPickerViewController
        
        let containerView = transitionContext.containerView
        containerView.addSubview(pickerViewController.view)
        containerView.addSubview(previewViewController.view)
        if !canTransition {
            self.previewViewController?.view.removeGestureRecognizer(panGestureRecognizer)
            canInteration = false
            beganInterPercent = false
            self.cancel()
            UIView.animate(withDuration: 0.25) {
                if !previewViewController.statusBarShouldBeHidden {
                    previewViewController.bottomView.alpha = 1
                    if AssetManager.authorizationStatusIsLimited() &&
                        pickerViewController.config.bottomView.showPrompt {
                        pickerViewController.bottomView.alpha = 0
                    }
                }
            } completion: { (_) in
                transitionContext.completeTransition(false)
                self.previewViewController?.view.addGestureRecognizer(self.panGestureRecognizer)
            }
            return
        }
        backgroundView.frame = pickerViewController.view.bounds
        backgroundView.backgroundColor = previewBackgroundColor
        pickerViewController.view.insertSubview(backgroundView, at: 1)
        if !previewViewController.previewAssets.isEmpty {
            let photoAsset = previewViewController.previewAssets[previewViewController.currentPreviewIndex]
            pickerViewController.setCellLoadMode(.complete)
            if let pickerCell = pickerViewController.getCell(for: photoAsset) {
                pickerViewController.scrollCellToVisibleArea(pickerCell)
                DispatchQueue.main.async {
                    pickerViewController.cellReloadImage()
                }
                toView = pickerCell
            }else {
                pickerViewController.scrollToCenter(for: photoAsset)
                pickerViewController.reloadCell(for: photoAsset)
                DispatchQueue.main.async {
                    pickerViewController.cellReloadImage()
                }
                let pickerCell = pickerViewController.getCell(for: photoAsset)
                toView = pickerCell
            }
        }
        
        if let previewCell = previewViewController.getCell(for: previewViewController.currentPreviewIndex) {
            beforePreviewFrame = previewCell.frame
            previewView = previewCell
        }
        previewView?.scrollView.clipsToBounds = false
        
        if let previewView = previewView {
            let anchorPoint = CGPoint(x: beganPoint.x / previewView.width, y: beganPoint.y / previewView.height)
            previewView.layer.anchorPoint = anchorPoint
            previewView.frame = pickerViewController.view.bounds
            previewCenter = previewView.center
            pickerViewController.view.insertSubview(previewView, aboveSubview: backgroundView)
        }
        var pickerShowParompt = false
        var previewShowSelectedView = false
        if previewViewController.statusBarShouldBeHidden {
            pickerViewController.bottomView.alpha = 0
            pickerViewController.navigationController?.navigationBar.alpha = 0
            previewViewController.navigationController?.setNavigationBarHidden(false, animated: false)
        }else {
            if previewViewController.config.bottomView.showSelectedView == true &&
                previewViewController.pickerController?.config.selectMode == .multiple &&
                !previewViewController.statusBarShouldBeHidden {
                if previewViewController.pickerController?.selectedAssetArray.isEmpty == false {
                    previewShowSelectedView = true
                }
            }
            if AssetManager.authorizationStatusIsLimited() && previewViewController.config.bottomView.showPrompt {
                pickerShowParompt = true
            }
        }
        if previewShowSelectedView && !pickerShowParompt {
            let maskView = UIView(
                frame: CGRect(
                    x: 0,
                    y: 0,
                    width: previewViewController.view.width,
                    height: 120 + UIDevice.bottomMargin
                )
            )
            maskView.backgroundColor = .white
            previewViewController.bottomView.mask = maskView
        }else if !previewShowSelectedView && pickerShowParompt {
            let maskView = UIView(
                frame: CGRect(
                    x: 0,
                    y: 70,
                    width: previewViewController.view.width,
                    height: 50 + UIDevice.bottomMargin
                )
            )
            maskView.backgroundColor = .white
            pickerViewController.bottomView.mask = maskView
        }
        resetScrollView(for: false)
        toView?.isHidden = true
        beganInterPercent = true
    }
    func dismissTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        let pickerController = transitionContext.viewController(forKey: .from) as! PhotoPickerController
        pickerControllerBackgroundColor = pickerController.view.backgroundColor
        pickerController.view.backgroundColor = .clear
        if let previewViewController = pickerController.previewViewController {
            self.previewViewController = previewViewController
            previewBackgroundColor = previewViewController.view.backgroundColor
            previewViewController.view.backgroundColor = .clear
            
            let containerView = transitionContext.containerView
            
            backgroundView.frame = containerView.bounds
            backgroundView.backgroundColor = previewBackgroundColor
            containerView.addSubview(backgroundView)
            if let view = pickerController.pickerDelegate?.pickerController(
                pickerController,
                dismissPreviewViewForIndexAt: previewViewController.currentPreviewIndex) {
                toView = view
            }
            
            if let previewCell = previewViewController.getCell(for: previewViewController.currentPreviewIndex) {
                previewCell.scrollContentView.hiddenOtherSubview()
                beforePreviewFrame = previewCell.frame
                previewView = previewCell
            }
            previewView?.scrollView.clipsToBounds = false
            
            if let previewView = previewView {
                let anchorPoint = CGPoint(x: beganPoint.x / previewView.width, y: beganPoint.y / previewView.height)
                previewView.layer.anchorPoint = anchorPoint
                previewView.frame = pickerController.view.bounds
                previewCenter = previewView.center
                containerView.addSubview(previewView)
            }
            containerView.addSubview(pickerController.view)
            previewViewController.collectionView.isScrollEnabled = false
            previewView?.scrollView.isScrollEnabled = false
            previewView?.scrollView.pinchGestureRecognizer?.isEnabled = false
            toView?.isHidden = true
            beganInterPercent = true
        }
    }
    func resetScrollView(for enabled: Bool) {
        previewViewController?.collectionView.isScrollEnabled = enabled
        previewView?.scrollView.isScrollEnabled = enabled
        previewView?.scrollView.pinchGestureRecognizer?.isEnabled = enabled
        previewView?.scrollView.clipsToBounds = enabled
        if enabled {
            previewViewController?.view.backgroundColor = self.previewBackgroundColor
            pickerController?.view.backgroundColor = self.pickerControllerBackgroundColor
        }
    }
}
