//
//  PhotoBrowser.swift
//  SwiftUIExample
//
//  Created by Silence on 2023/9/8.
//  Copyright © 2023 洪欣. All rights reserved.
//

import SwiftUI
import UIKit
import HXPhotoPicker
import Foundation

@available(iOS 13.0, *)
struct PhotoBrowser {
    
    let pageIndex: Int
    let rowCount: CGFloat
    @Binding var photoAssets: [PhotoAsset]
    @Binding var assets: [Asset]
    
    func show(_ image: UIImage, topMargin: CGFloat, itemSize: CGSize) {
        var config = HXPhotoPicker.PhotoBrowser.Configuration()
        config.showDelete = true
        HXPhotoPicker.PhotoBrowser.show(
            photoAssets,
            pageIndex: pageIndex,
            config: config,
            transitionalImage: image
        ) { index in
            let count = index + 1
            var row = CGFloat(count / Int(rowCount))
            let remainder = CGFloat(count).truncatingRemainder(dividingBy: rowCount)
            var xPadding: CGFloat = remainder
            if remainder != 0 {
                row += 1
            }else {
                xPadding = 3
            }
            let x: CGFloat = 12 * xPadding + (xPadding - 1) * itemSize.width
            let y: CGFloat = topMargin + (row - 1) * (itemSize.height + 12)
            let view = UIView(frame: .init(x: x, y: y, width: itemSize.width, height: itemSize.height))
            view.layer.cornerRadius = 5
            return view
        } deleteAssetHandler: { index, _, browser in
            PhotoTools.showAlert(
                viewController: browser,
                title: "是否删除?",
                leftActionTitle: "取消",
                rightActionTitle: "确定",
                rightHandler:  { _ in
                    browser.deleteCurrentPreviewPhotoAsset()
                    photoAssets.remove(at: index)
                    assets.remove(at: index)
                }
            )
        }
    }
    
}


@available(iOS 13.0, *)
struct Editor {
    
    let asset: EditorAsset
    let config: EditorConfiguration
    
    @Binding var resultAsset: EditorAsset
    func start() {
        Task {
            do {
                let result = try await Photo.edit(asset, config: config)
                resultAsset = result
            } catch {
                
            }
        }
    }
}
