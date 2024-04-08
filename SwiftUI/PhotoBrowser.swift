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
    
    enum TransitionType {
        case start
        case end
        
        var opacity: CGFloat {
            switch self {
            case .start:
                return 0
            case .end:
                return 1
            }
        }
    }
    
    let pageIndex: Int
    let rowCount: CGFloat
    @Binding var photoAssets: [PhotoAsset]
    @Binding var assets: [Asset]
    @Binding var transitionTypes: [TransitionType]
    
    func show(_ image: UIImage, itemSize: CGSize, pointHandler: @escaping (Int) -> CGPoint) {
        var config = HXPhotoPicker.PhotoBrowser.Configuration()
        config.showDelete = true
        HXPhotoPicker.PhotoBrowser.show(
            photoAssets,
            pageIndex: pageIndex,
            config: config,
            transitionalImage: image
        ) { index, _ in
            transitionTypes[index] = .start
            let point = pointHandler(index)
            let view = UIView(frame: .init(x: point.x, y: point.y, width: itemSize.width, height: itemSize.height))
            view.layer.cornerRadius = 5
            return view
        } transitionCompletion: { index, _ in
            transitionTypes[index] = .end
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
