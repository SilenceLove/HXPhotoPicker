//
//  ConfigView.swift
//  SwiftUIExample
//
//  Created by Silence on 2023/9/9.
//  Copyright © 2023 洪欣. All rights reserved.
//

import SwiftUI
import UIKit
import HXPhotoPicker

@available(iOS 13.0, *)
struct ConfigView: UIViewControllerRepresentable {
    
    @Binding var config: PickerConfiguration

    func makeUIViewController(context: Context) -> UINavigationController {
        let vc = PickerConfigurationViewController(style: .insetGrouped)
        vc.showOpenPickerButton = false
        vc.config = config
        vc.didDoneHandler = {
            config = $0
        }
        return UINavigationController.init(rootViewController: vc)
    }

    func updateUIViewController(_ configVC: UINavigationController, context: Context) {
        
    }
 
}
