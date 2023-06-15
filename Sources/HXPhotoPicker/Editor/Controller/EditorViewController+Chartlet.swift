//
//  EditorViewController+Chartlet.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/17.
//

import UIKit

extension EditorViewController: EditorChartletViewControllerDelegate {
    
    func chartletViewController(
        _ chartletViewController: EditorChartletViewController,
        loadTitleChartlet response: @escaping ([EditorChartlet]) -> Void
    ) {
        if let editorDelegate = delegate {
            editorDelegate.editorViewController(
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
    func chartletViewController(
        _ chartletViewController: EditorChartletViewController,
        titleChartlet: EditorChartlet,
        titleIndex: Int,
        loadChartletList response: @escaping (Int, [EditorChartlet]) -> Void
    ) {
        if let editorDelegate = delegate {
            editorDelegate.editorViewController(
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
    func chartletViewController(
        _ chartletViewController: EditorChartletViewController,
        didSelectImage image: UIImage,
        imageData: Data?
    ) {
        deselectedDrawTool()
        if let tool = selectedTool,
           tool.type == .graffiti || tool.type == .graffiti {
            selectedTool = nil
        }
        if let imageData = imageData {
            editorView.addSticker(imageData)
        }else {
            editorView.addSticker(image)
        }
        checkSelectedTool()
        checkFinishButtonState()
    }
    
    func deselectedDrawTool() {
        if let tool = lastSelectedTool {
            switch tool.type {
            case .graffiti, .mosaic:
                toolsView.deselected()
                editorView.isMosaicEnabled = false
                editorView.isDrawEnabled = false
                hideBrushColorView()
                hideMosaicToolView()
                updateBottomMaskLayer()
                lastSelectedTool = nil
            default:
                break
            }
        }
    }
}
