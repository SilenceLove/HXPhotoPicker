//
//  PhotoPickerControllerAnimator.swift
//  HXPhotoPicker
//
//  Created by Slience on 2022/5/23.
//

import UIKit

public final class PhotoPickerControllerAnimator: NSObject, PhotoPickerControllerAnimationTransitioning {
    private let type: PhotoPickerControllerTransitionType
    public init(type: PhotoPickerControllerTransitionType) {
        self.type = type
        super.init()
    }
    
    public func transitionDuration(
        using transitionContext: UIViewControllerContextTransitioning?
    ) -> TimeInterval {
        if type == .push {
            return 0.3
        }else if type == .dismiss {
            return 0.2
        }
        return 0.25
    }
    
    public func animateTransition(
        using transitionContext: UIViewControllerContextTransitioning
    ) {
        guard let fromVC = transitionContext.viewController(forKey: .from),
              let toVC = transitionContext.viewController(forKey: .to) else {
            transitionContext.completeTransition(transitionContext.transitionWasCancelled)
            return
        }
        
        let containerView = transitionContext.containerView
        let bgView = UIView(frame: containerView.bounds)
        bgView.backgroundColor = .black.withAlphaComponent(0.1)
        if type == .push {
            bgView.alpha = 0
            containerView.addSubview(fromVC.view)
            containerView.addSubview(bgView)
            containerView.addSubview(toVC.view)
        }else {
            let isChartlet: Bool
            #if HXPICKER_ENABLE_EDITOR
            isChartlet = toVC is EditorChartletListProtocol
            #else
            isChartlet = false
            #endif
            if (toVC.transitioningDelegate == nil || toVC is PhotoPickerController) && !isChartlet {
                containerView.addSubview(toVC.view)
            }else {
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
            containerView.addSubview(bgView)
            containerView.addSubview(fromVC.view)
        }
        let duration = transitionDuration(using: transitionContext)
        let options: UIView.AnimationOptions
        switch self.type {
        case .push:
            toVC.view.x = toVC.view.width
            options = .curveEaseOut
        case .pop:
            toVC.view.x = -(toVC.view.width * 0.3)
            options = .curveLinear
        default:
            options = .curveLinear
        }
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: options
        ) {
            switch self.type {
            case .push:
                fromVC.view.x = -(fromVC.view.width * 0.3)
                toVC.view.x = 0
                bgView.alpha = 1
            case .pop:
                fromVC.view.x = fromVC.view.width
                toVC.view.x = 0
                bgView.alpha = 0
            case .dismiss:
                fromVC.view.y = fromVC.view.height
                bgView.alpha = 0
            }
        } completion: { _ in
            bgView.removeFromSuperview()
            switch self.type {
            case .pop, .dismiss:
                fromVC.view.removeFromSuperview()
            default:
                break
            }
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}
