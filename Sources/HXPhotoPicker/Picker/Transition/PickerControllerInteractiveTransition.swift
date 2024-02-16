//
//  PickerControllerInteractiveTransition.swift
//  HXPhotoPicker
//
//  Created by Slience on 2022/5/23.
//

import UIKit

class PickerControllerInteractiveTransition: UIPercentDrivenInteractiveTransition, UIGestureRecognizerDelegate {
    enum TransitionType {
        case pop
        case dismiss
    }
    var panGestureRecognizer: UIPanGestureRecognizer!
    private weak var bgView: UIView?
    private var pickerControllerBackgroundColor: UIColor?
    private var beganPoint: CGPoint = .zero
    private let triggerRange: CGFloat
    private weak var transitionContext: UIViewControllerContextTransitioning?
    private weak var pickerController: PhotoPickerController?
    private let type: TransitionType
    
    var canInteration: Bool = false
    init(
        panGestureRecognizerFor pickerController: PhotoPickerController,
        type: TransitionType,
        triggerRange: CGFloat
    ) {
        self.pickerController = pickerController
        self.type = type
        self.triggerRange = triggerRange
        super.init()
        panGestureRecognizer = UIPanGestureRecognizer(
            target: self,
            action: #selector(panGestureRecognizerAction(panGR:))
        )
        panGestureRecognizer.delegate = self
        pickerController.view.addGestureRecognizer(panGestureRecognizer)
    }
    
    override func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
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
        containerView.addSubview(pickerController.view)
        if type == .pop {
            toVC.view.x = -(toVC.view.width * 0.3)
        }
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
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
    func panGestureRecognizerAction(panGR: UIPanGestureRecognizer) {
        guard let pickerController = pickerController else {
            return
        }
        let velocity = panGR.velocity(in: pickerController.view)
        let pickerWidth = pickerController.view.width
        let pickerHeight = pickerController.view.height
        switch panGR.state {
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
            let point = panGR.translation(in: pickerController.view)
            var scale = (point.x / pickerWidth)
            if scale < 0 {
                scale = 0
            }
            if type == .pop {
                if velocity.x < pickerWidth {
                    if let transitionContext = transitionContext,
                       let toVC = transitionContext.viewController(forKey: .to) {
                        let toScale = toVC.view.width * 0.3 * scale
                        toVC.view.x = -(toVC.view.width * 0.3) + toScale
                    }
                    pickerController.view.x = pickerWidth * scale
                }
            }else {
                pickerController.view.y = beganPoint.y + scale * pickerHeight
                if pickerController.view.y < 0 {
                    pickerController.view.y = 0
                }
            }
            bgView?.alpha = 1 - scale
            update(scale)
        case .ended, .cancelled, .failed:
            if !canInteration {
                return
            }
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
                        duration *= pickerWidth / min(velocity.x, pickerWidth * 2)
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
                    self.bgView?.alpha = 0
                } completion: { _ in
                    self.pickerController?.view.removeFromSuperview()
                    self.pickerController = nil
                    self.bgView?.removeFromSuperview()
                    self.bgView = nil
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
                    self.bgView?.alpha = 1
                } completion: { _ in
                    self.bgView?.removeFromSuperview()
                    self.bgView = nil
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
