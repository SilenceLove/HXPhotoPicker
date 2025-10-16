//
//  HXBaseViewController.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/1/9.
//

import UIKit

open class HXBaseViewController: UIViewController {
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
    
    var topContainerView: UIView!
    func initTopContainerView(_ scrollView: UIScrollView) {
        #if canImport(UIKit.UIGlassEffect)
        if #available(iOS 26.0, *), !PhotoManager.isIos26Compatibility  {
            scrollView.topEdgeEffect.isHidden = false
            topContainerView = UIView()
            topContainerView.clipsToBounds = false
            topContainerView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(topContainerView)
            let interaction = UIScrollEdgeElementContainerInteraction()
            interaction.scrollView = scrollView
            interaction.edge = .top
            topContainerView.addInteraction(interaction)
            
            let tmpBtn = UIButton(type: .system)
            tmpBtn.configuration = .glass()
            let tmpItem = UIBarButtonItem(customView: tmpBtn).hidesShared()
            let tmpToolView = UIToolbar()
            tmpToolView.setItems([tmpItem], animated: false)
            topContainerView.addSubview(tmpToolView)
            tmpToolView.x = -UIScreen._width
            tmpToolView.y = -100
        }
        #endif
    }
    
    var bottomContainerView: UIView!
    func initBottomContainerView(_ scrollView: UIScrollView) {
        #if canImport(UIKit.UIGlassEffect)
        if #available(iOS 26.0, *), !PhotoManager.isIos26Compatibility  {
            scrollView.bottomEdgeEffect.isHidden = false
            bottomContainerView = UIView()
            bottomContainerView.clipsToBounds = false
            bottomContainerView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(bottomContainerView)
            let interaction = UIScrollEdgeElementContainerInteraction()
            interaction.scrollView = scrollView
            interaction.edge = .bottom
            bottomContainerView.addInteraction(interaction)
        }
        #endif
    }
    
    @objc
    open func deviceOrientationDidChanged(notify: Notification) {
        
    }
    
    @objc
    open func deviceOrientationWillChanged(notify: Notification) {
        
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
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            self?.deviceOrientationDidChanged(
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
