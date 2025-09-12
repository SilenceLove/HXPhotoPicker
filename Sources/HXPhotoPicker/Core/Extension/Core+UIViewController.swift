//
//  Core+UIViewController.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/8/16.
//

import UIKit

extension UIViewController {
    
    class var topViewController: UIViewController? {
        let window = UIApplication.hx_keyWindow
        if var topViewController = window?.rootViewController {
            while true {
                if let controller = topViewController.presentedViewController {
                    topViewController = controller
                }else if let navController = topViewController as? UINavigationController,
                         let controller = navController.topViewController {
                    topViewController = controller
                }else if let tabbarController = topViewController as? UITabBarController,
                         let controller = tabbarController.selectedViewController {
                    topViewController = controller
                }else {
                    break
                }
            }
            return topViewController
        }
        return nil
    }
}
