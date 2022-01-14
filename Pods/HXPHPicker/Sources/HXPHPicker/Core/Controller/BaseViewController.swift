//
//  BaseViewController.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/9.
//

import UIKit

open class BaseViewController: UIViewController {
    open override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            return
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(deviceOrientationDidChanged(notify:)),
            name: UIApplication.didChangeStatusBarOrientationNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(deviceOrientationWillChanged(notify:)),
            name: UIApplication.willChangeStatusBarOrientationNotification,
            object: nil
        )
    }
    
    @objc open func deviceOrientationDidChanged(notify: Notification) {
        
    }
    
    @objc open func deviceOrientationWillChanged(notify: Notification) {
        
    }
    
    open override func viewWillTransition(
        to size: CGSize,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        super.viewWillTransition(to: size, with: coordinator)
        guard #available(iOS 13.0, *) else {
            return
        }
        deviceOrientationWillChanged(notify: .init(name: UIApplication.willChangeStatusBarOrientationNotification))
        coordinator.animate(alongsideTransition: nil) { _ in
            self.deviceOrientationDidChanged(
                notify: .init(
                    name: UIApplication.didChangeStatusBarOrientationNotification
                )
            )
        }
    }
    
    open override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PhotoTools.removeCache()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
