//
//  PhotoEditorViewController+Navigation.swift
//  HXPHPicker
//
//  Created by Slience on 2021/11/15.
//

import UIKit

extension PhotoEditorViewController: UINavigationControllerDelegate {
    public func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        if operation == .push {
            return EditorTransition(mode: .push)
        }else if operation == .pop {
            return EditorTransition(mode: .pop)
        }
        return nil
    }
}
