//
//  PhotoPickerController+Transitioning.swift
//  HXPHPicker
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
        if allowPushPresent {
            return PickerControllerTransition(type: .push)
        }
        if isSwipeRightBack {
            return nil
        }
        return PickerTransition(type: .present)
    }
    public func animationController(
        forDismissed dismissed: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        if allowPushPresent {
            return PickerControllerTransition(type: .pop)
        }
        if isSwipeRightBack {
            return PickerControllerTransition(type: .dismiss)
        }
        if disablesCustomDismiss {
            return nil
        }
        return PickerTransition(type: .dismiss)
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
