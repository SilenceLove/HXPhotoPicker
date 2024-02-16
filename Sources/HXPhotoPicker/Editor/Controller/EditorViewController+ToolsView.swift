//
//  EditorViewController+ToolsView.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/17.
//

import UIKit
import PencilKit

extension EditorViewController: EditorToolsViewDelegate {
    func toolsView(_ toolsView: EditorToolsView, didSelectItemAt model: EditorConfiguration.ToolsView.Options) {
        if editorView.type != .video, model.type == .time {
            return
        }
        editorView.deselectedSticker()
        switch model.type {
        case .graffiti:
            if #available(iOS 13.0, *), editorView.drawType == .canvas {
                hideLastToolView()
                hideToolsView(isCanvasGraffiti: true)
                selectedTool = model
                showCanvasViews()
                editorView.isStickerEnabled = false
                startCanvasDrawing()
                updateBottomMaskLayer()
                lastSelectedTool = model
                return
            }else {
                selectedTool = model
            }
        case .text:
            presentText()
            return
        case .chartlet:
            let vc = config.chartlet.listProtcol.init(config: config, editorType: selectedAsset.contentType)
            if let vc = vc as? EditorChartletViewController {
                vc.chartletDelegate = self
            }
            vc.modalPresentationStyle = config.chartlet.modalPresentationStyle
            vc.delegate = self
            present(vc, animated: true)
            return
        default:
            selectedTool = model
        }
        hideLastToolView()
        switch model.type {
        case .graffiti:
            editorView.isStickerEnabled = false
            editorView.isDrawEnabled = true
            showBrushColorView()
        case .mosaic:
            editorView.isStickerEnabled = false
            editorView.isMosaicEnabled = true
            showMosaicToolView()
        case .filter:
            showFiltersView()
        case .music:
            showMusicView()
            return
        case .cropSize:
            if let selectType = scaleSwitchSelectType {
                scaleSwitchLeftBtn.isSelected = selectType == 0
                scaleSwitchRightBtn.isSelected = selectType == 1
            }
            editorView.startEdit(true) { [weak self] in
                guard let self = self else {
                    return
                }
                if let ratio = self.ratioToolView.selectedRatio?.ratio, !ratio.equalTo(.zero), !self.editorView.isRoundMask {
                    self.ratioToolView(self.ratioToolView, didSelectedRatioAt: ratio)
                }
            }
            showCropSizeToolsView()
            checkFinishButtonState()
            return
        case .time:
            showVideoControlView()
        case .filterEdit:
            showFilterEditView()
        default:
            break
        }
        lastSelectedTool = model
        updateBottomMaskLayer()
    }
    
    func toolsView(_ toolsView: EditorToolsView, deselectItemAt model: EditorConfiguration.ToolsView.Options) {
        lastSelectedTool = nil
        selectedTool = nil
        switch model.type {
        case .time:
            hideVideoControlView()
        case .graffiti:
            editorView.isDrawEnabled = false
            hideBrushColorView()
        case .mosaic:
            editorView.isMosaicEnabled = false
            hideMosaicToolView()
        case .filter:
            hideFiltersView()
        case .filterEdit:
            hideFilterEditView()
        default:
            break
        }
        editorView.isStickerEnabled = true
        updateBottomMaskLayer()
    }
    
    func showToolsView() {
        if !toolsView.isHidden && toolsView.alpha == 1 {
            return
        }
        if let tool = selectedTool, tool.type == .graffiti, editorView.drawType == .canvas {
            return
        }
        toolsView.isHidden = false
        cancelButton.isHidden = false
        finishButton.isHidden = false
        topMaskView.isHidden = false
        bottomMaskView.isHidden = false
        UIView.animate(withDuration: 0.2) {
            self.toolsView.alpha = 1
            self.cancelButton.alpha = 1
            self.finishButton.alpha = 1
            if !UIDevice.isPortrait || self.config.buttonType == .top {
                self.topMaskView.alpha = 1
            }
            self.bottomMaskView.alpha = 1
        }
        if let selectedTool = selectedTool {
            switch selectedTool.type {
            case .time:
                showVideoControlView()
            case .graffiti:
                showBrushColorView()
            case .mosaic:
                showMosaicToolView()
            case .filter:
                showFiltersView()
            case .filterEdit:
                showFilterEditView()
            default:
                break
            }
        }
    }
    
    func hideToolsView(isCanvasGraffiti: Bool = false) {
        if toolsView.isHidden || toolsView.alpha == 0 {
            return
        }
        if let selectedTool = selectedTool {
            switch selectedTool.type {
            case .time:
                hideVideoControlView()
            case .graffiti:
                hideBrushColorView()
            case .mosaic:
                hideMosaicToolView()
            case .filter:
                hideFiltersView()
            case .filterEdit:
                hideFilterEditView()
            default:
                break
            }
        }
        UIView.animate(withDuration: 0.2) {
            self.toolsView.alpha = 0
            self.cancelButton.alpha = 0
            self.finishButton.alpha = 0
            if !isCanvasGraffiti {
                self.topMaskView.alpha = 0
            }
            self.bottomMaskView.alpha = 0
        } completion: {
            if $0 {
                self.toolsView.isHidden = true
                self.cancelButton.isHidden = true
                self.finishButton.isHidden = true
                if !isCanvasGraffiti {
                    self.topMaskView.isHidden = true
                }
                self.bottomMaskView.isHidden = true
            }
        }
    }
    
    func hideLastToolView() {
        if let selectedTool = selectedTool {
            switch selectedTool.type {
            case .text, .chartlet:
                return
            default:
                break
            }
        }
        if let lastSelectedTool = lastSelectedTool {
            switch lastSelectedTool.type {
            case .time:
                hideVideoControlView()
            case .graffiti:
                editorView.isStickerEnabled = true
                editorView.isDrawEnabled = false
                hideBrushColorView()
            case .mosaic:
                editorView.isStickerEnabled = true
                editorView.isMosaicEnabled = false
                hideMosaicToolView()
            case .filter:
                hideFiltersView()
            case .filterEdit:
                hideFilterEditView()
            default:
                break
            }
        }
    }
    
    func showLastToolView() {
        if let lastSelectedTool = lastSelectedTool {
            switch lastSelectedTool.type {
            case .time:
                showVideoControlView()
            case .graffiti:
                showBrushColorView()
            case .mosaic:
                showMosaicToolView()
            case .filter:
                showFiltersView()
            case .filterEdit:
                showFilterEditView()
            default:
                break
            }
        }
    }
    
    func showVideoControlView() {
        if !videoControlView.isHidden && videoControlView.alpha == 1 {
            return
        }
        videoControlView.isHidden = false
        UIView.animate(withDuration: 0.2) {
            self.videoControlView.alpha = 1
        }
    }
    
    func hideVideoControlView() {
        if videoControlView.isHidden || videoControlView.alpha == 0 {
            return
        }
        videoControlView.stopScroll()
        UIView.animate(withDuration: 0.2) {
            self.videoControlView.alpha = 0
        } completion: {
            if $0 {
                self.videoControlView.isHidden = true
            }
        }
    }
    
    @available(iOS 13.0, *)
    func startCanvasDrawing(_ isRotate: Bool = false) {
        let toolPicker: PKToolPicker
        if isRotate {
            guard let _toolPicker = editorView.enterCanvasDrawing() else {
                return
            }
            toolPicker = _toolPicker
        }else {
            guard let _toolPicker = editorView.startCanvasDrawing() else {
                return
            }
            toolPicker = _toolPicker
        }
        editorView.setZoomScale(1, animated: true)
        editorView.setContentOffset(.zero, animated: true)
        
        let topHeight = topMaskView.height
        let rect = toolPicker.frameObscured(in: view)
        let maxHeight: CGFloat
        if rect.isNull {
            let bottomMargin: CGFloat
            if isFullScreen {
                bottomMargin = UIDevice.bottomMargin + 10
            }else {
                bottomMargin = 20
            }
            maxHeight = view.height - topHeight - bottomMargin
        }else {
            maxHeight = rect.minY - topMaskView.height
        }
        let contentHeight = editorView.contentSize.height
        backgroundView.bouncesZoom = true
        editorView.isCanZoomScale = false
        backgroundView.maximumZoomScale = 20
        if contentHeight > maxHeight {
            let zoomScale = maxHeight / contentHeight
            let minWidth = view.width * zoomScale
            
            backgroundInsetRect = .init(x: (view.width - minWidth) / 2, y: topHeight, width: minWidth, height: maxHeight)
            let editorHeight = editorView.height * zoomScale
            if editorHeight < backgroundInsetRect.height, contentHeight > editorHeight {
                backgroundView.contentSize = editorView.contentSize
                editorView.height = contentHeight
            }
            backgroundView.minimumZoomScale = zoomScale
            UIView.animate {
                self.backgroundView.zoomScale = zoomScale
            }
        }else {
            backgroundView.minimumZoomScale = 1
            let padding = (maxHeight - contentHeight) / 2
            let top = topHeight + padding
            backgroundInsetRect = .init(x: 0, y: top, width: view.width, height: contentHeight)
            let offsetY = (view.height - contentHeight) / 2 - top
            UIView.animate {
                self.backgroundView.contentOffset = .init(x: 0, y: offsetY)
            }
        }
    }
    
    func showCanvasViews() {
        if editorView.drawType != .canvas {
            return
        }
        if !drawCancelButton.isHidden && drawCancelButton.alpha == 1 {
            return
        }
        editorView.hideStickersView()
        drawCancelButton.isHidden = false
        drawFinishButton.isHidden = false
        drawUndoBtn.isHidden = false
        drawRedoBtn.isHidden = false
        drawUndoAllBtn.isHidden = false
        topMaskView.isHidden = false
        UIView.animate {
            self.drawCancelButton.alpha = 1
            self.drawFinishButton.alpha = 1
            self.drawUndoBtn.alpha = 1
            self.drawRedoBtn.alpha = 1
            self.drawUndoAllBtn.alpha = 1
            self.topMaskView.alpha = 1
        }
    }
    
    func hideCanvasViews(_ isRotate: Bool = false, animated: Bool = true) {
        if editorView.drawType != .canvas {
            return
        }
        if drawCancelButton.isHidden || drawCancelButton.alpha == 0 {
            return
        }
        if !isRotate {
            editorView.showStickersView()
            editorView.isCanZoomScale = true
        }else {
            backgroundInsetRect = view.bounds
        }
        backgroundView.contentSize = view.size
        if animated {
            UIView.animate  {
                self.backgroundView.zoomScale = 1
                self.scrollViewDidZoom(self.backgroundView)
                self.backgroundView.contentOffset = .zero
                self.editorView.zoomScale = 1
                self.drawCancelButton.alpha = 0
                self.drawFinishButton.alpha = 0
                self.drawUndoBtn.alpha = 0
                self.drawRedoBtn.alpha = 0
                self.drawUndoAllBtn.alpha = 0
                if self.config.buttonType == .bottom && UIDevice.isPortrait {
                    self.topMaskView.alpha = 0
                }
            } completion: {
                if $0 {
                    self.backgroundView.maximumZoomScale = 1
                    self.backgroundView.minimumZoomScale = 1
                    self.backgroundView.bouncesZoom = false
                    self.drawCancelButton.isHidden = true
                    self.drawFinishButton.isHidden = true
                    self.drawUndoBtn.isHidden = true
                    self.drawRedoBtn.isHidden = true
                    self.drawUndoAllBtn.isHidden = true
                    if self.config.buttonType == .bottom && UIDevice.isPortrait {
                        self.topMaskView.isHidden = true
                    }
                }
            }
        }else {
            self.backgroundView.zoomScale = 1
            self.scrollViewDidZoom(self.backgroundView)
            self.backgroundView.contentOffset = .zero
            self.backgroundView.maximumZoomScale = 1
            self.backgroundView.minimumZoomScale = 1
            self.backgroundView.bouncesZoom = false
            self.editorView.zoomScale = 1
            self.drawCancelButton.alpha = 0
            self.drawFinishButton.alpha = 0
            self.drawUndoBtn.alpha = 0
            self.drawRedoBtn.alpha = 0
            self.drawUndoAllBtn.alpha = 0
            if self.config.buttonType == .bottom && UIDevice.isPortrait {
                self.topMaskView.alpha = 0
            }
            self.drawCancelButton.isHidden = true
            self.drawFinishButton.isHidden = true
            self.drawUndoBtn.isHidden = true
            self.drawRedoBtn.isHidden = true
            self.drawUndoAllBtn.isHidden = true
            if self.config.buttonType == .bottom && UIDevice.isPortrait {
                self.topMaskView.isHidden = true
            }
        }
    }
    
    func showBrushColorView() {
        if editorView.drawType == .canvas {
            return
        }
        if !brushColorView.isHidden && brushColorView.alpha == 1 {
            return
        }
        brushColorView.isHidden = false
        brushSizeView.isHidden = false
        UIView.animate(withDuration: 0.2) {
            self.brushColorView.alpha = 1
            self.brushSizeView.alpha = 1
        }
    }
    
    func hideBrushColorView() {
        if brushColorView.isHidden || brushColorView.alpha == 0 {
            return
        }
        UIView.animate(withDuration: 0.2) {
            self.brushColorView.alpha = 0
            self.brushSizeView.alpha = 0
        } completion: {
            if $0 {
                self.brushColorView.isHidden = true
                self.brushSizeView.isHidden = true
            }
        }
    }
    
    func showMosaicToolView() {
        if !mosaicToolView.isHidden && mosaicToolView.alpha == 1 {
            return
        }
        mosaicToolView.isHidden = false
        UIView.animate(withDuration: 0.2) {
            self.mosaicToolView.alpha = 1
        }
    }
    
    func hideMosaicToolView() {
        if mosaicToolView.isHidden || mosaicToolView.alpha == 0 {
            return
        }
        UIView.animate(withDuration: 0.2) {
            self.mosaicToolView.alpha = 0
        } completion: {
            if $0 {
                self.mosaicToolView.isHidden = true
            }
        }
    }
    
    func showMusicView() {
        if musicView.y == view.height - musicView.height - UIDevice.bottomMargin {
            return
        }
        if let shouldClick = delegate?.editorViewController(shouldClickMusicTool: self),
           !shouldClick {
            return
        }
        editorView.isStickerEnabled = false
        hideToolsView()
        if musicView.musics.isEmpty {
            if let loadHandler = config.video.music.handler {
                let showLoading = loadHandler { [weak self] infos in
                    self?.musicView.reloadData(infos: infos)
                }
                if showLoading {
                    musicView.showLoading()
                }
            }else {
                if let editorDelegate = delegate {
                    if editorDelegate.editorViewController(
                        self,
                        loadMusic: { [weak self] infos in
                            self?.musicView.reloadData(infos: infos)
                    }) {
                        musicView.showLoading()
                    }
                }else {
                    let infos = PhotoTools.defaultMusicInfos()
                    if infos.isEmpty {
                        ProgressHUD.showWarning(
                            addedTo: view,
                            text: .textManager.editor.music.emptyHudTitle.text,
                            animated: true,
                            delayHide: 1.5
                        )
                        return
                    }else {
                        musicView.reloadData(infos: infos)
                    }
                }
            }
        }
        UIView.animate(withDuration: 0.2) {
            self.updateMusicViewFrame()
        }
    }
    
    func hideMusicView() {
        if musicView.y == view.height {
            return
        }
        UIView.animate(withDuration: 0.2) {
            self.updateMusicViewFrame()
        }
    }
    
    func showFilterEditView() {
        if !filterEditView.isHidden && filterEditView.alpha == 1 {
            return
        }
        filterEditView.isHidden = false
        UIView.animate(withDuration: 0.2) {
            self.filterEditView.alpha = 1
        }
    }
    
    func hideFilterEditView() {
        if filterEditView.isHidden || filterEditView.alpha == 0 {
            return
        }
        UIView.animate(withDuration: 0.2) {
            self.filterEditView.alpha = 0
        } completion: {
            if $0 {
                self.filterEditView.isHidden = true
            }
        }
    }
    
    func showFiltersView() {
        if !filtersView.isHidden && filtersView.alpha == 1 {
            return
        }
        filtersView.isHidden = false
        UIView.animate(withDuration: 0.2) {
            self.filtersView.alpha = 1
        }
    }
    
    func hideFiltersView() {
        if filtersView.isHidden || filtersView.alpha == 0 {
            return
        }
        UIView.animate(withDuration: 0.2) {
            self.filtersView.alpha = 0
        } completion: {
            if $0 {
                self.filtersView.isHidden = true
            }
        }
    }
    
    func showCropSizeToolsView() {
        if !rotateScaleView.isHidden && rotateScaleView.alpha == 1 {
            return
        }
        if !config.cropSize.aspectRatios.isEmpty {
            ratioToolView.isHidden = false
        }
        rotateScaleView.isHidden = false
        resetButton.isHidden = false
        leftRotateButton.isHidden = false
        rightRotateButton.isHidden = false
        mirrorVerticallyButton.isHidden = false
        mirrorHorizontallyButton.isHidden = false
        
        var isShowMaskList: Bool = true
        if let ratio = ratioToolView.selectedRatio?.ratio, (ratio.width < 0 || ratio.height < 0) {
            isShowMaskList = false
        }
        if isShowMaskList {
            maskListButton.isHidden = false
        }
        showScaleSwitchView()
        UIView.animate(withDuration: 0.2) {
            if !self.config.cropSize.aspectRatios.isEmpty {
                self.ratioToolView.alpha = 1
            }
            self.rotateScaleView.alpha = 1
            self.resetButton.alpha = 1
            self.leftRotateButton.alpha = 1
            self.rightRotateButton.alpha = 1
            self.mirrorVerticallyButton.alpha = 1
            self.mirrorHorizontallyButton.alpha = 1
            if isShowMaskList {
                self.maskListButton.alpha = 1
            }
            self.toolsView.alpha = 0
            self.hideMasks()
        } completion: {
            if $0 {
                self.toolsView.isHidden = true
            }
        }
    }
    
    func hideCropSizeToolsView() {
        showLastToolView()
        selectedTool = lastSelectedTool
        if rotateScaleView.isHidden || rotateScaleView.alpha == 0 {
            return
        }
        toolsView.isHidden = false
        hideScaleSwitchView()
        UIView.animate(withDuration: 0.2) {
            if !self.config.cropSize.aspectRatios.isEmpty {
                self.ratioToolView.alpha = 0
            }
            self.rotateScaleView.alpha = 0
            self.resetButton.alpha = 0
            self.leftRotateButton.alpha = 0
            self.rightRotateButton.alpha = 0
            self.mirrorVerticallyButton.alpha = 0
            self.mirrorHorizontallyButton.alpha = 0
            self.maskListButton.alpha = 0
            self.toolsView.alpha = 1
            self.showMasks()
        } completion: {
            if $0 {
                if !self.config.cropSize.aspectRatios.isEmpty {
                    self.ratioToolView.isHidden = true
                }
                self.rotateScaleView.isHidden = true
                self.resetButton.isHidden = true
                self.leftRotateButton.isHidden = true
                self.rightRotateButton.isHidden = true
                self.mirrorVerticallyButton.isHidden = true
                self.mirrorHorizontallyButton.isHidden = true
                self.maskListButton.isHidden = true
            }
        }
    }
    
    func showScaleSwitchView(_ isRatioClick: Bool = false) {
        if config.cropSize.aspectRatios.isEmpty {
            return
        }
        if let ratio = ratioToolView.selectedRatio?.ratio, (ratio.width < 0 || ratio.height < 0) {
            scaleSwitchView.isHidden = false
        }else {
            return
        }
        UIView.animate(withDuration: 0.2) {
            if !self.config.cropSize.aspectRatios.isEmpty {
                self.scaleSwitchView.alpha = 1
            }
            if isRatioClick {
                self.maskListButton.alpha = 0
            }
        } completion: {
            if $0, isRatioClick {
                self.maskListButton.isHidden = true
            }
        }
    }
    
    func hideScaleSwitchView(_ isRatioClick: Bool = false) {
        if config.cropSize.aspectRatios.isEmpty {
            return
        }
        if isRatioClick {
            maskListButton.isHidden = false
        }
        UIView.animate(withDuration: 0.2) {
            self.scaleSwitchView.alpha = 0
            if isRatioClick {
                self.maskListButton.alpha = 1
            }
        } completion: {
            if $0 {
                self.scaleSwitchView.isHidden = true
            }
        }
    }
    
    func presentText(_ text: EditorStickerText? = nil) {
        let textVC = EditorStickerTextViewController(config: config.text, stickerText: text)
        textVC.delegate = self
        let nav = EditorStickerTextController(rootViewController: textVC)
        nav.modalPresentationStyle = config.text.modalPresentationStyle
        present(nav, animated: true, completion: nil)
    }
}

extension EditorViewController: EditorMaskListViewControllerDelegate {
    
    func editorMaskListViewController(
        _ editorMaskListViewController: EditorMaskListViewController,
        didSelected image: UIImage
    ) {
        let imageAspectRatio = image.size
        editorView.isFixedRatio = true
        editorView.setMaskImage(image, animated: true)
        editorView.setAspectRatio(imageAspectRatio, animated: true)
        ratioToolView.deselected()
        for (index, aspectRatio) in ratioToolView.ratios.enumerated() {
            if aspectRatio.ratio.equalTo(.init(width: -1, height: -1)) || aspectRatio.ratio.equalTo(.zero) {
                continue
            }
            let scale1 = CGFloat(Int(aspectRatio.ratio.width / aspectRatio.ratio.height * 1000)) / 1000
            let scale2 = CGFloat(Int(imageAspectRatio.width / imageAspectRatio.height * 1000)) / 1000
            if scale1 == scale2 {
                ratioToolView.scrollToIndex(at: index, animated: true)
                break
            }
        }
        resetButton.isEnabled = isReset
    }
}
