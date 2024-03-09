//
//  PhotoPickerController+Transitioning.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/8/25.
//

import UIKit

// MARK: UIViewControllerTransitioningDelegate
extension PhotoPickerController: UIViewControllerTransitioningDelegate {
    
    public func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        if !config.allowCustomTransitionAnimation {
            return nil
        }
        if modalPresentationStyle == .fullScreen &&
            config.albumShowMode.isPop {
            switch config.pickerPresentStyle {
            case .push:
                return config.pickerTransitionAnimator.init(type: .push)
            default:
                return nil
            }
        }
        return config.browserTransitionAnimator.init(type: .present)
    }
    
    public func animationController(
        forDismissed dismissed: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        if !config.allowCustomTransitionAnimation {
            return nil
        }
        if modalPresentationStyle == .fullScreen &&
            config.albumShowMode.isPop {
            switch config.pickerPresentStyle {
            case .push:
                return config.pickerTransitionAnimator.init(type: .pop)
            case .present:
                return config.pickerTransitionAnimator.init(type: .dismiss)
            default:
                return nil
            }
        }
        if disablesCustomDismiss {
            return nil
        }
        return config.browserTransitionAnimator.init(type: .dismiss)
    }
    
    public func interactionControllerForDismissal(
        using animator: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {
        if let canInteration = interactiveTransition?.canInteration, canInteration {
            return interactiveTransition
        }
        if let canInteration = dismissInteractiveTransition?.canInteration, canInteration {
            return dismissInteractiveTransition
        }
        return nil
    }
}
