//
//  PhotoBrowserInteractiveAnimator.swift
//  HXPhotoPicker
//
//  Created by Silence on 2024/2/25.
//  Copyright © 2024 Silence. All rights reserved.
//

import UIKit

public class PhotoBrowserInteractiveAnimator: PhotoBrowserInteractiveTransition, UIGestureRecognizerDelegate {
    var panGestureRecognizer: UIPanGestureRecognizer!
    var backgroundView: UIView!
    weak var transitionContext: UIViewControllerContextTransitioning?
    weak var previewViewController: PhotoPreviewViewController?
    var beganPoint: CGPoint = .zero
    var slidingGap: CGPoint = .zero
    var canTransition: Bool = false
    var backgroundColor: UIColor?
    var previewBackgroundColor: UIColor?
    var toView: UIView?
    var beforePreviewFrame: CGRect = .zero
    var previewView: PhotoPreviewViewCell?
    var previewCenter: CGPoint = .zero
    var navigationBarAlpha: CGFloat = 1
    
    required init(pickerController: PhotoPickerController) {
        super.init(pickerController: pickerController)
        panGestureRecognizer = UIPanGestureRecognizer(
            target: self,
            action: #selector(panGestureRecognizerClick(gestureRecognizer:))
        )
        panGestureRecognizer.delegate = self
        pickerController.view.addGestureRecognizer(panGestureRecognizer)
        backgroundView = UIView()
    }
    
    public override func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        guard canTransition,
              let pickerController = transitionContext.viewController(forKey: .from) as? PhotoPickerController,
              let previewViewController = pickerController.previewViewController else {
            canInteration = false
            cancel()
            transitionContext.completeTransition(false)
            self.transitionContext = nil
            return
        }
        backgroundColor = pickerController.view.backgroundColor
        pickerController.view.backgroundColor = .clear
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
        
        if let previewCell = previewViewController.transitionCellView {
            previewCell.hideScrollContainerSubview()
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
        if let photoBrowser = pickerController as? PhotoBrowser {
            if photoBrowser.hideSourceView {
                toView?.isHidden = true
            }
        }else {
            toView?.isHidden = true
        }
        self.transitionContext = transitionContext
    }
    
    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        if otherGestureRecognizer is UITapGestureRecognizer && otherGestureRecognizer.view is UIScrollView {
            return false
        }
        guard let isDragging = pickerController?.previewViewController?.collectionView.isDragging else {
            return true
        }
        return !isDragging
    }
    
    @objc
    func panGestureRecognizerClick(gestureRecognizer: UIPanGestureRecognizer) {
        let factor = interationFactor(gestureRecognizer)
        if !factor.allowInteraction {
            return
        }
        switch gestureRecognizer.state {
        case .began:
            interationBegan(gestureRecognizer)
        case .changed:
            interationChanged(gestureRecognizer, isTracking: factor.isTracking)
        case .ended, .cancelled, .failed:
            interationEnded(gestureRecognizer)
        default:
            break
        }
    }
    
    func interationFactor(_ gestureRecognizer: UIPanGestureRecognizer) -> (allowInteraction:Bool, isTracking: Bool) {
        var isTracking = false
        let previewVC = pickerController?.previewViewController
        if pickerController?.topViewController != previewVC {
            return (false, isTracking)
        }
        if let cell = previewVC?.transitionCellView,
           let contentView = cell.scrollContainerView {
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
        return (true, isTracking)
    }
    
    func interationBegan(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard !canInteration, let pickerController = pickerController else {
            return
        }
        let velocity = gestureRecognizer.velocity(in: pickerController.view)
        let isVerticalGesture = (abs(velocity.y) > abs(velocity.x) && velocity.y > 0)
        if !isVerticalGesture {
            return
        }
        beganPoint = gestureRecognizer.location(in: gestureRecognizer.view)
        canInteration = true
        canTransition = true
        pickerController.dismiss(animated: true, completion: nil)
    }
    
    func interationChanged(_ gestureRecognizer: UIPanGestureRecognizer, isTracking: Bool) {
        if !canInteration || transitionContext == nil {
            if isTracking {
                interationBegan(gestureRecognizer) 
                if canInteration {
                    slidingGap = gestureRecognizer.translation(in: gestureRecognizer.view)
                }
            }
            return
        }
        guard let pickerController,
              let previewViewController,
              let previewView else {
            return
        }
        let translation = gestureRecognizer.translation(in: gestureRecognizer.view)
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
        if !previewViewController.statusBarShouldBeHidden {
            var bottomViewAlpha = 1 - scale * 1.5
            if bottomViewAlpha < 0 {
                bottomViewAlpha = 0
            }
            previewViewController.photoToolbar.alpha = bottomViewAlpha
            previewViewController.navBgView?.alpha = bottomViewAlpha
            previewViewController.navigationController?.navigationBar.alpha = alpha
            navigationBarAlpha = alpha
        }
        pickerController.pickerDelegate?
            .pickerController(pickerController, interPercentUpdate: alpha, type: .dismiss)
        update(1 - alpha)
    }
    
    func interationEnded(_ gestureRecognizer: UIPanGestureRecognizer) {
        canTransition = false
        if !canInteration {
            return
        }
        guard let previewViewController = previewViewController else {
            finish()
            backgroundView.removeFromSuperview()
            previewView?.removeFromSuperview()
            previewView = nil
            toView = nil
            transitionContext?.completeTransition(true)
            transitionContext = nil
            return
        }
        guard transitionContext != nil else {
            interationCancel()
            slidingGap = .zero
            return
        }
        let translation = gestureRecognizer.translation(in: gestureRecognizer.view)
        let scale = (translation.y - slidingGap.y) / (previewViewController.view.height)
        if scale < 0.15 {
            cancel()
            interationCancel()
        }else {
            finish()
            interationFinish()
        }
        slidingGap = .zero
    }
    
    func interationCancel() {
        guard let previewViewController,
              let previewView else {
            toView?.isHidden = false
            toView = nil
            return
        }
        panGestureRecognizer.isEnabled = false
        previewViewController.navigationController?.view.isUserInteractionEnabled = false
        let toVC = self.transitionContext?.viewController(forKey: .to) as? PhotoPickerViewController
        let picker = self.pickerController
        UIView.animate(withDuration: 0.25) {
            previewView.transform = .identity
            previewView.center = self.previewCenter
            self.backgroundView.alpha = 1
            if !previewViewController.statusBarShouldBeHidden {
                previewViewController.photoToolbar.alpha = 1
                previewViewController.navBgView?.alpha = 1
                previewViewController.navigationController?.navigationBar.alpha = 1
            }
            if let picker {
                picker.pickerDelegate?
                    .pickerController(picker, interPercentDidCancelAnimation: .dismiss)
            }
        } completion: { _ in
            previewViewController.photoToolbar.mask = nil
            toVC?.photoToolbar.mask = nil
            self.toView?.isHidden = false
            self.resetScrollView(for: true)
            previewView.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            previewView.frame = self.beforePreviewFrame
            previewViewController.collectionView.addSubview(previewView)
            previewView.showScrollContainerSubview()
            self.backgroundView.removeFromSuperview()
            self.previewView = nil
            self.toView = nil
            previewViewController.navigationController?.view.isUserInteractionEnabled = true
            self.transitionContext?.completeTransition(false)
            self.transitionContext = nil
            self.canInteration = false
            self.panGestureRecognizer.isEnabled = true
        }
    }
    
    func interationFinish() {
        guard let pickerController,
              let previewViewController,
              let previewView else {
            toView?.isHidden = false
            toView = nil
            return
        }
        panGestureRecognizer.isEnabled = false
        var toRect: CGRect = .zero
        if let toView = toView {
            if let toSuperView = toView.superview {
                toRect = toSuperView.convert(toView.frame, to: transitionContext?.containerView)
            }else {
                toRect = toView.convert(toView.bounds, to: transitionContext?.containerView)
            }
        }
        if toRect.isEmpty,
           let rect = pickerController.pickerDelegate?.pickerController(
            pickerController,
            dismissPreviewFrameForIndexAt:
                previewViewController.currentPreviewIndex
        ) {
            toRect = rect
        }
        if let toView = toView, toView.layer.cornerRadius > 0 {
            previewView.layer.masksToBounds = true
        }
        if pickerController.config.prefersStatusBarHidden && !previewViewController.statusBarShouldBeHidden {
            previewViewController.navigationController?.navigationBar.alpha = navigationBarAlpha
        }
        previewView.scrollContentView.isBacking = true
        let fromVC = transitionContext?.viewController(forKey: .from)
        backgroundView.isUserInteractionEnabled = false
        previewView.isUserInteractionEnabled = false
        fromVC?.view.isUserInteractionEnabled = false
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
                previewViewController.photoToolbar.alpha = 0
                previewViewController.navBgView?.alpha = 0
                previewViewController.navigationController?.navigationBar.alpha = 0
            }
            pickerController.pickerDelegate?
                .pickerController(pickerController, interPercentDidFinishAnimation: .dismiss)
        } completion: { _ in
            previewViewController.photoToolbar.mask = nil
            self.toView?.isHidden = false
            pickerController.pickerDelegate?.pickerController(
                pickerController,
                previewDismissComplete: pickerController.currentPreviewIndex
            )
            UIView.animate(withDuration: 0.2) {
                previewView.alpha = 0
            } completion: { _ in
                previewView.isUserInteractionEnabled = true
                previewView.removeFromSuperview()
                self.previewView = nil
                self.previewViewController = nil
                self.toView = nil
                self.backgroundView.removeFromSuperview()
                self.transitionContext?.completeTransition(true)
                self.transitionContext = nil
                self.panGestureRecognizer.isEnabled = true
            }
        }
    }

    func resetScrollView(for enabled: Bool) {
        previewViewController?.collectionView.isScrollEnabled = enabled
        previewView?.scrollView.isScrollEnabled = enabled
        previewView?.scrollView.pinchGestureRecognizer?.isEnabled = enabled
        previewView?.scrollView.clipsToBounds = enabled
        if enabled {
            previewViewController?.view.backgroundColor = previewBackgroundColor
            pickerController?.view.backgroundColor = backgroundColor
        }
    }
}
