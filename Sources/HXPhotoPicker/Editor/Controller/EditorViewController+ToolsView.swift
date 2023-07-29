//
//  EditorViewController+ToolsView.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/17.
//

import UIKit

extension EditorViewController: EditorToolsViewDelegate {
    func toolsView(_ toolsView: EditorToolsView, didSelectItemAt model: EditorConfiguration.ToolsView.Options) {
        if editorView.type != .video, model.type == .time {
            return
        }
        editorView.deselectedSticker()
        switch model.type {
        case .text:
            presentText()
            return
        case .chartlet:
            let vc = EditorChartletViewController(config: config, editorType: selectedAsset.contentType)
            vc.delegate = self
            vc.firstRequest()
            present(vc, animated: true)
            return
        default:
            hideChangeButton()
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
            editorView.startEdit(true)
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
        showChangeButton()
    }
    
    func showToolsView() {
        if !toolsView.isHidden && toolsView.alpha == 1 {
            return
        }
        toolsView.isHidden = false
        cancelButton.isHidden = false
        finishButton.isHidden = false
        UIView.animate(withDuration: 0.2) {
            self.toolsView.alpha = 1
            self.cancelButton.alpha = 1
            self.finishButton.alpha = 1
            if !UIDevice.isPortrait || self.config.buttonPostion == .top {
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
    
    func hideToolsView() {
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
            self.topMaskView.alpha = 0
            self.bottomMaskView.alpha = 0
        } completion: {
            if $0 {
                self.toolsView.isHidden = false
                self.cancelButton.isHidden = false
                self.finishButton.isHidden = false
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
    
    func showBrushColorView() {
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
                            text: "暂无配乐".localized,
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
        maskListButton.isHidden = false
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
            self.maskListButton.alpha = 1
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
    
    func showChangeButton() {
        if assets.count <= 1 {
            return
        }
        if !changeButton.isHidden && changeButton.alpha == 1 {
            return
        }
        if selectedTool != nil {
            return
        }
        changeButton.isHidden = false
        UIView.animate(withDuration: 0.2) {
            self.changeButton.alpha = 1
        }
    }
    
    func hideChangeButton() {
        if changeButton.isHidden || changeButton.alpha == 0 {
            return
        }
        UIView.animate(withDuration: 0.2) {
            self.changeButton.alpha = 0
        } completion: {
            if $0 {
                self.changeButton.isHidden = true
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
