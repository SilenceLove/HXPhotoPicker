//
//  PickerInteractiveTransition.swift
//  HXPhotoPicker
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
    private let type: PickerInteractiveTransitionType
    private weak var previewViewController: PhotoPreviewViewController?
    private weak var pickerController: PhotoPickerController?
    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var backgroundView: UIView!
    private var previewView: PhotoPreviewViewCell?
    private var toView: UIView?
    private var beforePreviewFrame: CGRect = .zero
    private var previewCenter: CGPoint = .zero
    private var beganPoint: CGPoint = .zero
    private var beganInterPercent: Bool = false
    private var previewBackgroundColor: UIColor?
    private var pickerControllerBackgroundColor: UIColor?
    private weak var transitionContext: UIViewControllerContextTransitioning?
    private var slidingGap: CGPoint = .zero
    private var navigationBarAlpha: CGFloat = 1
    private var canTransition: Bool = false
    
    var canInteration: Bool = false
    
    init(
        panGestureRecognizerFor previewViewController: PhotoPreviewViewController,
        type: PickerInteractiveTransitionType
    ) {
        self.type = type
        super.init()
        self.previewViewController = previewViewController
        panGestureRecognizer = UIPanGestureRecognizer(
            target: self,
            action: #selector(panGestureRecognizerClick(gestureRecognizer:))
        )
        panGestureRecognizer.delegate = self
        previewViewController.view.addGestureRecognizer(panGestureRecognizer)
        backgroundView = UIView()
    }
    
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith
            otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        if otherGestureRecognizer is UITapGestureRecognizer && otherGestureRecognizer.view is UIScrollView {
            return false
        }
        guard let isDragging = previewViewController?.collectionView.isDragging else {
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
        let previewIndex: Int
        if let index = previewViewController?.currentPreviewIndex {
            previewIndex = index
        }else {
            previewIndex = 0
        }
        if let cell = previewViewController?.getCell(for: previewIndex),
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
        return (true, isTracking)
    }
    
    func interationBegan(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard !canInteration, let previewViewController else {
            return
        }
        let velocity = gestureRecognizer.velocity(in: previewViewController.view)
        let isVerticalGesture = (abs(velocity.y) > abs(velocity.x) && velocity.y > 0)
        if !isVerticalGesture {
            return
        }
        beganPoint = gestureRecognizer.location(in: gestureRecognizer.view)
        canInteration = true
        canTransition = true
        previewViewController.navigationController?.popViewController(animated: true)
    }
    
    func interationChanged(_ gestureRecognizer: UIPanGestureRecognizer, isTracking: Bool) {
        if !canInteration || !beganInterPercent {
            if isTracking {
                interationBegan(gestureRecognizer)
                if canInteration {
                    slidingGap = gestureRecognizer.translation(in: gestureRecognizer.view)
                }
            }
            return
        }
        guard let previewViewController, let previewView else {
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
        let toVC = transitionContext?.viewController(forKey: .to) as? PhotoPickerViewController
        var maskScale = 1 - scale * 2.85
        if maskScale < 0 {
            maskScale = 0
        }
        if let previewToolbar = previewViewController.photoToolbar,
           let photoToolbar = toVC?.photoToolbar,
           previewToolbar.viewHeight != photoToolbar.viewHeight {
            let previewViewHeight = previewToolbar.viewHeight
            let previewToolbarHeight = previewToolbar.toolbarHeight
            let previewTopHeight = (previewViewHeight - previewToolbarHeight)
            let previewMaskY = previewTopHeight * (1 - maskScale)
            let previewMaskWidth = previewToolbar.width
            let previewMaskHeight = previewToolbar.height - previewMaskY
            previewToolbar.mask?.frame = CGRect(
                x: 0,
                y: previewMaskY,
                width: previewMaskWidth,
                height: previewMaskHeight
            )
            let pickerToolbarHeight = photoToolbar.toolbarHeight
            let pickerViewHeight = photoToolbar.viewHeight
            let pickerTopHeight = pickerViewHeight - pickerToolbarHeight
            let pickerMaskY = pickerTopHeight * maskScale
            let pickerMaskWidth = photoToolbar.width
            let pickerMaskHeight = pickerToolbarHeight + pickerTopHeight * (1 - maskScale)
            photoToolbar.mask?.frame = CGRect(x: 0, y: pickerMaskY, width: pickerMaskWidth, height: pickerMaskHeight)
        }
        if !previewViewController.statusBarShouldBeHidden {
            var bottomViewAlpha = 1 - scale * 1.5
            if bottomViewAlpha < 0 {
                bottomViewAlpha = 0
            }
            previewViewController.photoToolbar.alpha = bottomViewAlpha
            previewViewController.navBgView?.alpha = bottomViewAlpha
        }else {
            toVC?.navigationController?.navigationBar.alpha = 1 - alpha
            toVC?.photoToolbar.alpha = 1 - alpha
        }
        if let picker = pickerController {
            picker.pickerDelegate?
                .pickerController(picker, interPercentUpdate: alpha, type: type)
        }
        update(1 - alpha)
    }
    
    func interationEnded(_ gestureRecognizer: UIPanGestureRecognizer) {
        canTransition = false
        if !canInteration {
            return
        }
        guard let previewViewController else {
            finish()
            backgroundView.removeFromSuperview()
            previewView?.removeFromSuperview()
            previewView = nil
            previewViewController = nil
            toView = nil
            transitionContext?.completeTransition(true)
            transitionContext = nil
            slidingGap = .zero
            return
        }
        if transitionContext == nil {
            interationCancel()
        }else {
            let translation = gestureRecognizer.translation(in: gestureRecognizer.view)
            let scale = (translation.y - slidingGap.y) / (previewViewController.view.height)
            if scale < 0.15 {
                cancel()
                interationCancel()
            }else {
                finish()
                interationFinish()
            }
        }
        slidingGap = .zero
    }
    
    func interationCancel() {
        guard let previewViewController, let previewView else {
            toView?.isHidden = false
            toView = nil
            return
        }
        panGestureRecognizer.isEnabled = false
        previewViewController.navigationController?.view.isUserInteractionEnabled = false
        let toVC = transitionContext?.viewController(forKey: .to) as? PhotoPickerViewController
        UIView.animate(withDuration: 0.25) {
            previewView.transform = .identity
            previewView.center = self.previewCenter
            self.backgroundView.alpha = 1
            if !previewViewController.statusBarShouldBeHidden {
                previewViewController.photoToolbar.alpha = 1
                previewViewController.navBgView?.alpha = 1
                if self.type == .pop {
                    let maskWidth = previewViewController.photoToolbar.width
                    if previewViewController.photoToolbar.mask != nil {
                        let maskHeight = previewViewController.photoToolbar.height
                        previewViewController.photoToolbar.mask?.frame = CGRect(
                            origin: .zero,
                            size: CGSize(
                                width: maskWidth,
                                height: maskHeight
                            )
                        )
                    }
                    if let toolbar = toVC?.photoToolbar, toolbar.mask != nil {
                        let viewheight = toolbar.viewHeight
                        let maskHeight = toolbar.toolbarHeight
                        toolbar.mask?.frame = CGRect(x: 0, y: viewheight - maskHeight, width: maskWidth, height: maskHeight)
                    }
                }else {
                    previewViewController.navigationController?.navigationBar.alpha = 1
                }
            }else {
                if self.type == .pop {
                    toVC?.navigationController?.navigationBar.alpha = 0
                    toVC?.photoToolbar.alpha = 0
                }
            }
            if let picker = self.pickerController {
                picker.pickerDelegate?
                    .pickerController(picker, interPercentDidCancelAnimation: .pop)
            }
        } completion: { _ in
            previewViewController.photoToolbar.mask = nil
            toVC?.photoToolbar.mask = nil
            self.toView?.isHidden = false
            let toVC = self.transitionContext?.viewController(forKey: .to) as? PhotoPickerViewController
            if previewViewController.statusBarShouldBeHidden {
                previewViewController.navigationController?.setNavigationBarHidden(true, animated: false)
                toVC?.navigationController?.setNavigationBarHidden(true, animated: false)
                toVC?.photoToolbar.alpha = 1
                toVC?.navigationController?.navigationBar.alpha = 1
            }
            self.resetScrollView(for: true)
            previewView.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            previewView.frame = self.beforePreviewFrame
            previewViewController.collectionView.addSubview(previewView)
            previewView.scrollContentView.showOtherSubview()
            self.backgroundView.removeFromSuperview()
            self.previewView = nil
            self.toView = nil
            previewViewController.navigationController?.view.isUserInteractionEnabled = true
            self.transitionContext?.completeTransition(false)
            self.transitionContext = nil
            self.canInteration = false
            self.beganInterPercent = false
            self.panGestureRecognizer.isEnabled = true
        }
    }
    
    func interationFinish() {
        guard let previewViewController, let previewView else {
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
        previewView.scrollContentView.isBacking = true
        let fromVC = transitionContext?.viewController(forKey: .from) as? PhotoPreviewViewController
        let toVC = transitionContext?.viewController(forKey: .to) as? PhotoPickerViewController
        backgroundView.isUserInteractionEnabled = false
        previewView.isUserInteractionEnabled = false
        fromVC?.view.isUserInteractionEnabled = false
        UIView.animate(
            withDuration: 0.175,
            delay: 0,
            options: [.layoutSubviews, .curveEaseOut]
        ) {
            self.backgroundView.alpha = 0
            if !previewViewController.statusBarShouldBeHidden {
                previewViewController.photoToolbar.alpha = 0
                previewViewController.navBgView?.alpha = 0
                let maskWidth = previewViewController.photoToolbar.width
                if let toolbar = previewViewController.photoToolbar,
                   toolbar.mask != nil {
                    let viewHeight = toolbar.viewHeight
                    let toolbarHeight = toolbar.toolbarHeight
                    let maskY = viewHeight - toolbarHeight
                    let maskHeight = toolbarHeight
                    toolbar.mask?.frame = CGRect(
                        x: 0,
                        y: maskY,
                        width: maskWidth,
                        height: maskHeight
                    )
                }
                if let toolbar = toVC?.photoToolbar, toolbar.mask != nil {
                    let maskHeight = toolbar.viewHeight
                    toolbar.mask?.frame = CGRect(x: 0, y: 0, width: maskWidth, height: maskHeight)
                }
            }else {
                toVC?.photoToolbar.alpha = 1
                toVC?.navigationController?.navigationBar.alpha = 1
            }
        } completion: { _ in
            self.backgroundView.removeFromSuperview()
            toVC?.listView.view.layer.removeAllAnimations()
            self.transitionContext?.completeTransition(true)
            self.transitionContext = nil
        }
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
            if !previewViewController.statusBarShouldBeHidden {
                previewViewController.photoToolbar.alpha = 0
                previewViewController.navBgView?.alpha = 0
                previewViewController.navigationController?.navigationBar.alpha = 0
            }
            if let picker = self.pickerController {
                picker.pickerDelegate?
                    .pickerController(picker, interPercentDidFinishAnimation: self.type)
            }
        } completion: { _ in
            previewViewController.photoToolbar.mask = nil
            toVC?.photoToolbar.mask = nil
            self.toView?.isHidden = false
            UIView.animate(withDuration: 0.2) {
                previewView.alpha = 0
            } completion: { _ in
                previewView.isUserInteractionEnabled = true
                previewView.removeFromSuperview()
                self.previewView = nil
                self.previewViewController = nil
                self.toView = nil
                self.panGestureRecognizer.isEnabled = true
            }
        }
    }
    
    override func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        guard let previewViewController = transitionContext.viewController(forKey: .from)
                as? PhotoPreviewViewController,
              let pickerViewController = transitionContext.viewController(forKey: .to)
                as? PhotoPickerViewController else {
            canInteration = false
            beganInterPercent = false
            cancel()
            transitionContext.completeTransition(false)
            return
        }
        if !canTransition {
            self.previewViewController?.view.removeGestureRecognizer(panGestureRecognizer)
            canInteration = false
            beganInterPercent = false
            self.cancel()
            UIView.animate(withDuration: 0.25) {
                if !previewViewController.statusBarShouldBeHidden {
                    previewViewController.photoToolbar.alpha = 1
                    previewViewController.navBgView?.alpha = 1
                    pickerViewController.photoToolbar.alpha = 0
                }
            } completion: { (_) in
                transitionContext.completeTransition(false)
                self.previewViewController?.view.addGestureRecognizer(self.panGestureRecognizer)
            }
            return
        }
        self.transitionContext = transitionContext
        previewBackgroundColor = previewViewController.view.backgroundColor
        previewViewController.view.backgroundColor = .clear
        if pickerViewController.isShowToolbar, previewViewController.isShowToolbar {
            pickerViewController.photoToolbar.selectViewOffset = previewViewController.photoToolbar.selectViewOffset
        }
         
        let containerView = transitionContext.containerView
        containerView.addSubview(pickerViewController.view)
        containerView.addSubview(previewViewController.view)
        backgroundView.frame = pickerViewController.view.bounds
        backgroundView.backgroundColor = previewBackgroundColor
        pickerViewController.view.insertSubview(backgroundView, at: 1)
        if let photoAsset = previewViewController.photoAsset(for: previewViewController.currentPreviewIndex) {
            pickerViewController.viewDidLayoutSubviews()
            pickerViewController.listView.updateCellLoadMode(.complete)
            pickerViewController.isDisableLayout = true
            DispatchQueue.main.async {
                if let pickerCell = pickerViewController.listView.getCell(for: photoAsset) {
                    DispatchQueue.main.async {
                        pickerViewController.listView.scrollCellToVisibleArea(pickerCell)
                        self.toView = pickerCell
                        self.toView?.isHidden = true
                        DispatchQueue.main.async {
                            pickerViewController.listView.cellReloadImage()
                        }
                    }
                }else {
                    DispatchQueue.main.async {
                        pickerViewController.listView.scrollToCenter(for: photoAsset)
                        pickerViewController.listView.reloadCell(for: photoAsset)
                        DispatchQueue.main.async {
                            pickerViewController.listView.cellReloadImage()
                            let pickerCell = pickerViewController.listView.getCell(for: photoAsset)
                            self.toView = pickerCell
                            self.toView?.isHidden = true
                        }
                    }
                }
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
        if previewViewController.statusBarShouldBeHidden {
            pickerViewController.photoToolbar.alpha = 0
            pickerViewController.navigationController?.navigationBar.alpha = 0
            previewViewController.navigationController?.setNavigationBarHidden(false, animated: false)
        }else {
            pickerViewController.photoToolbar.alpha = 1
        }
        
        let pickerToolbarHeight = pickerViewController.photoToolbar.toolbarHeight
        let pickerViewHeight = pickerViewController.photoToolbar.viewHeight
        if previewViewController.photoToolbar.viewHeight != pickerViewHeight {
            let previewMaskView = UIView(
                frame: CGRect(
                    x: 0,
                    y: 0,
                    width: previewViewController.view.width,
                    height: previewViewController.photoToolbar.viewHeight
                )
            )
            previewMaskView.backgroundColor = .white
            previewViewController.photoToolbar.mask = previewMaskView
            
            let pickerMaskView = UIView(
                frame: CGRect(
                    x: 0,
                    y: pickerViewHeight - pickerToolbarHeight,
                    width: previewViewController.view.width,
                    height: pickerToolbarHeight
                )
            )
            pickerMaskView.backgroundColor = .white
            pickerViewController.photoToolbar.mask = pickerMaskView
        }else {
            previewViewController.photoToolbar.mask = nil
            pickerViewController.photoToolbar.mask = nil
        }
        resetScrollView(for: false)
        toView?.isHidden = true
        beganInterPercent = true
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
