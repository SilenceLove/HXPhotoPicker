//
//  PhotoPickerView.swift
//  SwiftUIExample
//
//  Created by Silence on 2023/9/8.
//  Copyright © 2023 洪欣. All rights reserved.
//

import SwiftUI
import UIKit
import HXPhotoPicker

@available(iOS 13.0, *)
struct PhotoPickerView: UIViewControllerRepresentable {
    
    var config: PickerConfiguration
    @Binding var photoAssets: [PhotoAsset]
    @Binding var assets: [Asset]
    

    func makeUIViewController(context: Context) -> UIViewController {
        let controller: PhotoPickerController
        if UIDevice.isPad {
            controller = PhotoPickerController(splitPicker: config)
        }else {
            controller = PhotoPickerController(config: config)
        }
        controller.isOriginal = true
        controller.selectedAssetArray = photoAssets
        controller.autoDismiss = false
        Task {
            do {
                let assetResults: [AssetResult] = try await controller.pickerAsset()
                photoAssets = controller.selectedAssetArray
                var assets: [Asset] = []
                for (index, photoAsset) in photoAssets.enumerated() {
                    assets.append(.init(
                        result: assetResults[index],
                        videoDuration: photoAsset.videoTime ?? "",
                        photoAsset: photoAsset
                    ))
                }
                self.assets = assets
            } catch {
                let pickerError = error as! PickerError
                print(pickerError)
            }
        }
        if UIDevice.isPad {
            let splitVC = PhotoSplitViewController(picker: controller)
            return splitVC
        }
        return controller
    }

    func updateUIViewController(_ photoPickerController: UIViewController, context: Context) {
        
        
    }
 
}

@available(iOS 13.0, *)
struct Asset {
    let result: AssetResult
    let videoDuration: String
    let photoAsset: PhotoAsset
}
