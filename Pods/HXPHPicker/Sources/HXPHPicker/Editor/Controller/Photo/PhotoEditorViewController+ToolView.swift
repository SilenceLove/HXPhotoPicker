//
//  PhotoEditorViewController+ToolView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/9/16.
//

import UIKit

extension PhotoEditorViewController: EditorToolViewDelegate {
    func toolView(didFinishButtonClick toolView: EditorToolView) {
        exportResources()
    }
    func toolView(_ toolView: EditorToolView, didSelectItemAt model: EditorToolOptions) {
        switch model.type {
        case .graffiti:
            currentToolOption = nil
            imageView.mosaicEnabled = false
            hiddenMosaicToolView()
            imageView.drawEnabled = !imageView.drawEnabled
            toolView.stretchMask = imageView.drawEnabled
            toolView.layoutSubviews()
            if imageView.drawEnabled {
                imageView.stickerEnabled = false
                showBrushColorView()
                currentToolOption = model
            }else {
                imageView.stickerEnabled = true
                hiddenBrushColorView()
            }
        case .chartlet:
            deselectedDraw()
            chartletView.firstRequest()
            imageView.deselectedSticker()
            disableImageSubView()
            imageView.isEnabled = false
            showChartlet = true
            hidenTopView()
            showChartletView()
        case .text:
            deselectedDraw()
            imageView.deselectedSticker()
            presentText()
        case .cropSize:
            disableImageSubView()
            pState = .cropping
            imageView.startCropping(true)
            croppingAction()
        case .mosaic:
            currentToolOption = nil
            imageView.drawEnabled = false
            hiddenBrushColorView()
            imageView.mosaicEnabled = !imageView.mosaicEnabled
            toolView.stretchMask = imageView.mosaicEnabled
            toolView.layoutSubviews()
            if imageView.mosaicEnabled {
                imageView.stickerEnabled = false
                showMosaicToolView()
                currentToolOption = model
            }else {
                imageView.stickerEnabled = true
                hiddenMosaicToolView()
            }
        case .filter:
            deselectedDraw()
            disableImageSubView()
            isFilter = true
            hidenTopView()
            showFilterView()
            imageView.canLookOriginal = true
        default:
            break
        }
    }
    
    func deselectedDraw() {
        currentToolOption = nil
        imageView.drawEnabled = false
        hiddenBrushColorView()
        imageView.mosaicEnabled = false
        hiddenMosaicToolView()
        toolView.deselected()
    }
    
    func disableImageSubView() {
        imageView.drawEnabled = false
        imageView.mosaicEnabled = false
        imageView.stickerEnabled = false
    }
    
    func presentText() {
        let textVC = EditorStickerTextViewController(config: config.text)
        textVC.delegate = self
        let nav = EditorStickerTextController(rootViewController: textVC)
        nav.modalPresentationStyle = config.text.modalPresentationStyle
        present(nav, animated: true, completion: nil)
    }
}
