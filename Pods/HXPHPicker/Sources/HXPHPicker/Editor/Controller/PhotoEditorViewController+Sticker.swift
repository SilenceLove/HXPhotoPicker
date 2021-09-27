//
//  PhotoEditorViewController+Sticker.swift
//  HXPHPicker
//
//  Created by Slience on 2021/9/16.
//

import UIKit

extension PhotoEditorViewController: EditorStickerTextViewControllerDelegate {
    func stickerTextViewController(
        _ controller: EditorStickerTextViewController,
        didFinish stickerItem: EditorStickerItem
    ) {
        imageView.updateSticker(item: stickerItem)
    }
    
    func stickerTextViewController(
        _ controller: EditorStickerTextViewController,
        didFinish stickerText: EditorStickerText
    ) {
        let item = EditorStickerItem(
            image: stickerText.image,
            imageData: nil,
            text: stickerText
        )
        imageView.addSticker(item: item, isSelected: false)
    }
}

extension PhotoEditorViewController: EditorChartletViewDelegate {
    func chartletView(
        _ chartletView: EditorChartletView,
        loadTitleChartlet response: @escaping ([EditorChartlet]) -> Void
    ) {
        if let editorDelegate = delegate {
            editorDelegate.photoEditorViewController(
                self,
                loadTitleChartlet: response
            )
        }else {
            #if canImport(Kingfisher)
            let titles = PhotoTools.defaultTitleChartlet()
            response(titles)
            #else
            response([])
            #endif
        }
    }
    func chartletView(backClick chartletView: EditorChartletView) {
        singleTap()
    }
    func chartletView(
        _ chartletView: EditorChartletView,
        titleChartlet: EditorChartlet,
        titleIndex: Int,
        loadChartletList response: @escaping (Int, [EditorChartlet]) -> Void
    ) {
        if let editorDelegate = delegate {
            editorDelegate.photoEditorViewController(
                self,
                titleChartlet: titleChartlet,
                titleIndex: titleIndex,
                loadChartletList: response
            )
        }else {
            // 默认加载这些贴图
            #if canImport(Kingfisher)
            let chartletList = PhotoTools.defaultNetworkChartlet()
            response(titleIndex, chartletList)
            #else
            response(titleIndex, [])
            #endif
        }
    }
    func chartletView(
        _ chartletView: EditorChartletView,
        didSelectImage image: UIImage,
        imageData: Data?
    ) {
        let item = EditorStickerItem(
            image: image,
            imageData: imageData,
            text: nil
        )
        imageView.addSticker(
            item: item,
            isSelected: false
        )
        singleTap()
    }
}
