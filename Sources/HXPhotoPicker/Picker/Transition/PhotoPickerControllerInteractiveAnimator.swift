//
//  PhotoPickerControllerInteractiveAnimator.swift
//  HXPhotoPicker
//
//  Created by Slience on 2022/5/23.
//

import UIKit

public class PhotoPickerControllerInteractiveAnimator: PhotoPickerControllerInteractiveTransition, UIGestureRecognizerDelegate {
    public override var gestureRecognizer: UIGestureRecognizer? {
        panGestureRecognizer
    }
    private var panGestureRecognizer: UIPanGestureRecognizer!
    private weak var bgView: UIView?
    private weak var shadowView: UIView?
    private var pickerControllerBackgroundColor: UIColor?
    private var beganPoint: CGPoint = .zero
    private weak var transitionContext: UIViewControllerContextTransitioning?
    public required init(
        type: PhotoPickerControllerInteractiveTransition.InteractiveTransitionType,
        pickerController: PhotoPickerController,
        triggerRange: CGFloat
    ) {
        super.init(type: type, pickerController: pickerController, triggerRange: triggerRange)
        panGestureRecognizer = UIPanGestureRecognizer(
            target: self,
            action: #selector(panGestureRecognizerClick(gestureRecognizer:))
        )
        panGestureRecognizer.delegate = self
        pickerController.view.addGestureRecognizer(panGestureRecognizer)
    }
    public override func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext
        let pickerController = transitionContext.viewController(forKey: .from) as! PhotoPickerController
        let toVC = transitionContext.viewController(forKey: .to)!
        pickerControllerBackgroundColor = pickerController.view.backgroundColor
        let containerView = transitionContext.containerView
        let isChartlet: Bool
        #if HXPICKER_ENABLE_EDITOR
        isChartlet = toVC is EditorChartletListProtocol
        #else
        isChartlet = false
        #endif
        if (toVC.transitioningDelegate == nil || toVC is PhotoPickerController) && !isChartlet {
            containerView.addSubview(toVC.view)
        }else {
            let fromVC = transitionContext.viewController(forKey: .from)
            if let vc = fromVC as? PhotoPickerController {
                switch vc.config.pickerPresentStyle {
                case .push(let rightSwipe):
                    guard let rightSwipe = rightSwipe else {
                        break
                    }
                    for type in rightSwipe.viewControlls where toVC.isKind(of: type) {
                        containerView.addSubview(toVC.view)
                        break
                    }
                case .present(let rightSwipe):
                    guard let rightSwipe = rightSwipe else {
                        break
                    }
                    for type in rightSwipe.viewControlls where toVC.isKind(of: type) {
                        containerView.addSubview(toVC.view)
                        break
                    }
                default:
                    break
                }
            }
        }
        
        let bgView = UIView(frame: containerView.bounds)
        bgView.backgroundColor = .black.withAlphaComponent(0.1)
        containerView.addSubview(bgView)
        self.bgView = bgView
        let shadowView = UIView(frame: pickerController.view.frame)
        shadowView.backgroundColor = .white
        shadowView.layer.shadowColor = UIColor.black.cgColor
        shadowView.layer.shadowOffset = .init(width: 0, height: 0)
        shadowView.layer.shadowOpacity = 0.3
        shadowView.layer.shadowRadius = 40
        containerView.addSubview(shadowView)
        self.shadowView = shadowView
        containerView.addSubview(pickerController.view)
        if type == .pop {
            toVC.view.x = -(toVC.view.width * 0.3)
        }
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pickerController = pickerController,
              let topViewController = pickerController.topViewController,
              topViewController is PhotoPickerViewController else {
            return false
        }
        let point = gestureRecognizer.location(in: pickerController.view)
        if point.x > triggerRange {
            return false
        }
        return true
    }
    
    @objc
    func panGestureRecognizerClick(gestureRecognizer: UIPanGestureRecognizer) {
        guard let pickerController = pickerController else {
            return
        }
        let pickerWidth = pickerController.view.width
        let pickerHeight = pickerController.view.height
        switch gestureRecognizer.state {
        case .began:
            if canInteration {
                return
            }
            beganPoint = pickerController.view.frame.origin
            canInteration = true
            pickerController.dismiss(animated: true)
        case .changed:
            if !canInteration {
                return
            }
            let point = gestureRecognizer.translation(in: pickerController.view)
            var scale = (point.x / pickerWidth)
            if scale < 0 {
                scale = 0
            }
            if type == .pop {
                if let transitionContext = transitionContext,
                   let toVC = transitionContext.viewController(forKey: .to) {
                    let toScale = toVC.view.width * 0.3 * scale
                    toVC.view.x = -(toVC.view.width * 0.3) + toScale
                }
                pickerController.view.x = pickerWidth * scale
            }else {
                pickerController.view.y = beganPoint.y + scale * pickerHeight
                if pickerController.view.y < 0 {
                    pickerController.view.y = 0
                }
            }
            shadowView?.frame = pickerController.view.frame
            bgView?.alpha = 1 - scale
            update(scale)
        case .ended, .cancelled, .failed:
            if !canInteration {
                return
            }
            let velocity = gestureRecognizer.velocity(in: pickerController.view)
            let isFinish: Bool
            if type == .pop {
                if velocity.x > pickerWidth {
                    isFinish = true
                }else {
                    isFinish = pickerController.view.x > pickerWidth * 0.6
                }
            }else {
                isFinish = pickerController.view.y > pickerHeight * 0.4
            }
            if isFinish {
                finish()
                var duration: TimeInterval = 0.3
                if type == .pop {
                    if velocity.x > pickerWidth {
                        duration *= pickerWidth / min(velocity.x, pickerWidth * 2.5)
                    }
                }
                UIView.animate(
                    withDuration: duration,
                    delay: 0,
                    options: .curveEaseOut
                ) {
                    if self.type == .pop {
                        if let transitionContext = self.transitionContext,
                           let toVC = transitionContext.viewController(forKey: .to) {
                            toVC.view.x = 0
                        }
                        pickerController.view.x = pickerWidth
                    }else {
                        pickerController.view.y = pickerHeight
                    }
                    self.shadowView?.frame = pickerController.view.frame
                    self.bgView?.alpha = 0
                } completion: { _ in
                    self.pickerController?.view.removeFromSuperview()
                    self.pickerController = nil
                    self.bgView?.removeFromSuperview()
                    self.bgView = nil
                    self.shadowView?.removeFromSuperview()
                    self.shadowView = nil
                    self.canInteration = false
                    self.transitionContext?.completeTransition(true)
                    self.transitionContext = nil
                }
            }else {
                cancel()
                UIView.animate(
                    withDuration: 0.2,
                    delay: 0,
                    options: .curveEaseOut
                ) {
                    if self.type == .pop {
                        if let transitionContext = self.transitionContext,
                           let toVC = transitionContext.viewController(forKey: .to) {
                            toVC.view.x = -(toVC.view.width * 0.3)
                        }
                        pickerController.view.x = 0
                    }else {
                        pickerController.view.y = 0
                    }
                    self.shadowView?.frame = pickerController.view.frame
                    self.bgView?.alpha = 1
                } completion: { _ in
                    self.bgView?.removeFromSuperview()
                    self.bgView = nil
                    self.shadowView?.removeFromSuperview()
                    self.shadowView = nil
                    self.canInteration = false
                    self.transitionContext?.completeTransition(false)
                    self.transitionContext = nil
                }
            }
        default:
            break
        }
    }
}
