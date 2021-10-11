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
        PickerTransition(type: .present)
    }
    public func animationController(
        forDismissed dismissed: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
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
        return nil
    }
}
