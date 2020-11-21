//
//  AppDelegate.swift
//  HXPhotoPickerSwift
//
//  Created by 洪欣 on 2020/11/12.
//  Copyright © 2020 洪欣. All rights reserved.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        window = UIWindow.init(frame: UIScreen.main.bounds)
        
        let vc = ViewController.init()
        let nav = UINavigationController.init(rootViewController: vc)
        
        window?.rootViewController = nav
        window?.makeKeyAndVisible()
        return true
    }

}

