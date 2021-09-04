//
//  PhotoPreviewViewController+NavigationController.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/27.
//

import UIKit

// MARK: UINavigationControllerDelegate
extension PhotoPreviewViewController: UINavigationControllerDelegate {
    
    public func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        if operation == .push {
            if toVC is PhotoPreviewViewController && fromVC is PhotoPickerViewController {
                return PickerTransition.init(type: .push)
            }
        }else if operation == .pop {
            if fromVC is PhotoPreviewViewController && toVC is PhotoPickerViewController {
                let cell = getCell(for: currentPreviewIndex)
                cell?.scrollContentView.hiddenOtherSubview()
                return PickerTransition.init(type: .pop)
            }
        }
        return nil
    }
    public func navigationController(
        _ navigationController: UINavigationController,
        interactionControllerFor
            animationController: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {
        if let canInteration = interactiveTransition?.canInteration, canInteration {
            return interactiveTransition
        }
        return nil
    }
}
