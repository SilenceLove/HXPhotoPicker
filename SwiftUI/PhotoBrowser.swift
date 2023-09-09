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

struct PhotoBrowser: UIViewControllerRepresentable {
    
    var pageIndex: Int
    @Binding var photoAssets: [PhotoAsset]
    @Binding var assets: [Asset]

    func makeUIViewController(context: Context) -> HXPhotoPicker.PhotoBrowser {
        var config = HXPhotoPicker.PhotoBrowser.Configuration()
        config.modalPresentationStyle = .automatic
        config.showDelete = true
        let browser = HXPhotoPicker.PhotoBrowser(config, pageIndex: pageIndex, assets: photoAssets)
        browser.deleteAssetHandler = { index, _, browser in
            PhotoTools.showAlert(viewController: browser, title: "是否删除?", leftActionTitle: "取消", rightActionTitle: "确定", rightHandler:  { _ in
                browser.deleteCurrentPreviewPhotoAsset()
                photoAssets.remove(at: index)
                assets.remove(at: index)
            })
        }
        return browser
    }

    func updateUIViewController(_ photoBrowser: HXPhotoPicker.PhotoBrowser, context: Context) {
        
    }
 
}
