//
//  EditorViewController+Action.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/7/22.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit

extension EditorViewController {
    
    @objc
    func didCancelButtonClick(button: UIButton) {
        if let selectedTool = selectedTool {
            switch selectedTool.type {
            case .cropSize:
                scaleSwitchSelectType = finishScaleSwitchSelectType
                rotateScaleView.stopScroll()
                if config.isFixedCropSizeState {
                    backClick(true)
                    return
                }
                editorView.cancelEdit(true, completion: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    self.rotateScaleView.updateAngle(self.finishScaleAngle)
                    self.lastScaleAngle = self.finishScaleAngle
                    if !self.config.cropSize.aspectRatios.isEmpty {
                        self.ratioToolView.scrollToIndex(at: self.finishRatioIndex, animated: false)
                    }
                })
                self.selectedTool = nil
                self.lastSelectedTool = nil
                toolsView.deselected()
                hideCropSizeToolsView()
                if let lastSelectedTool = lastSelectedTool {
                    switch lastSelectedTool.type {
                    case .graffiti:
                        editorView.isStickerEnabled = false
                        editorView.isDrawEnabled = true
                    case .mosaic:
                        editorView.isStickerEnabled = false
                        editorView.isMosaicEnabled = true
                    default:
                        editorView.isStickerEnabled = true
                    }
                }else {
                    editorView.isStickerEnabled = true
                }
                checkFinishButtonState()
                return
            case .graffiti:
                if #available(iOS 13.0, *), editorView.drawType == .canvas {
                    self.selectedTool = nil
                    self.lastSelectedTool = nil
                    hideCanvasViews()
                    editorView.cancelCanvasDrawing()
                    editorView.isStickerEnabled = true
                    checkFinishButtonState()
                    toolsView.deselected()
                    showToolsView()
                    return
                }
            default:
                break
            }
        }
        backClick(true)
    }
    
    @objc
    func didFinishButtonClick(button: UIButton) {
        if let selectedTool = selectedTool {
            switch selectedTool.type {
            case .cropSize:
                rotateScaleView.stopScroll()
                finishScaleAngle = rotateScaleView.angle
                finishScaleSwitchSelectType = scaleSwitchSelectType
                if !config.cropSize.aspectRatios.isEmpty {
                    finishRatioIndex = ratioToolView.selectedIndex
                }
                if config.isFixedCropSizeState {
                    processing()
                    return
                }
                editorView.finishEdit(true)
                self.selectedTool = nil
                self.lastSelectedTool = nil
                toolsView.deselected()
                hideCropSizeToolsView()
                if let lastSelectedTool = lastSelectedTool {
                    switch lastSelectedTool.type {
                    case .graffiti:
                        editorView.isStickerEnabled = false
                        editorView.isDrawEnabled = true
                    case .mosaic:
                        editorView.isStickerEnabled = false
                        editorView.isMosaicEnabled = true
                    default:
                        editorView.isStickerEnabled = true
                    }
                }else {
                    editorView.isStickerEnabled = true
                }
                checkFinishButtonState()
                return
            case .graffiti:
                if #available(iOS 13.0, *), editorView.drawType == .canvas {
                    self.selectedTool = nil
                    self.lastSelectedTool = nil
                    hideCanvasViews()
                    editorView.finishCanvasDrawing()
                    editorView.isStickerEnabled = true
                    checkFinishButtonState()
                    toolsView.deselected()
                    showToolsView()
                    return
                }
            default:
                break
            }
        }
        processing()
    }
    
    @objc
    func didResetButtonClick(button: UIButton) {
        rotateScaleView.stopScroll()
        if editorView.maskImage != nil {
            editorView.setMaskImage(nil, animated: true)
        }
        editorView.reset(true)
        lastScaleAngle = 0
        rotateScaleView.reset()
        if !config.cropSize.aspectRatios.isEmpty {
            scaleSwitchSelectType = nil
            if config.cropSize.isFixedRatio,
               !config.cropSize.isResetToOriginal,
               config.cropSize.isRoundCrop {
                ratioToolView.deselected()
            }else {
                ratioToolView.scrollToFree(animated: true)
            }
            hideScaleSwitchView(true)
        }
        button.isEnabled = false
    }
    
    @objc
    func didLeftRotateButtonClick(button: UIButton) {
        editorView.rotateLeft(true)
    }
    
    @objc
    func didRightRotateButtonClick(button: UIButton) {
        editorView.rotateRight(true)
    }
    
    @objc
    func didMirrorHorizontallyButtonClick(button: UIButton) {
        editorView.mirrorHorizontally(true)
    }
    
    @objc
    func didMirrorVerticallyButtonClick(button: UIButton) {
        editorView.mirrorVertically(true)
    }
    
    @objc
    func didMaskListButtonClick(button: UIButton) {
        let vc = config.cropSize.maskListProtcol.init(config: config)
        vc.delegate = self
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = vc.modalPresentationStyle
        present(nav, animated: true)
    }
    
    func checkFinishButtonState() {
        if editorView.state == .edit {
            finishButton.isEnabled = true
        }else {
            if config.isWhetherFinishButtonDisabledInUneditedState {
                finishButton.isEnabled = isEdited
            }else {
                finishButton.isEnabled = true
            }
        }
    }
    
    @objc
    func didScaleSwitchLeftBtn(button: UIButton) {
        if !button.isSelected {
            button.isSelected = true
            scaleSwitchRightBtn.isSelected = false
            let ratio = editorView.originalAspectRatio
            if ratio.width > ratio.height {
                editorView.setAspectRatio(.init(width: ratio.height, height: ratio.width), animated: true)
            }else {
                editorView.setAspectRatio(ratio, animated: true)
            }
            resetButton.isEnabled = isReset
            scaleSwitchSelectType = 0
        }
    }
    
    @objc
    func didScaleSwitchRightBtn(button: UIButton) {
        if !button.isSelected {
            button.isSelected = true
            scaleSwitchLeftBtn.isSelected = false
            let ratio = editorView.originalAspectRatio
            if ratio.width > ratio.height {
                editorView.setAspectRatio(ratio, animated: true)
            }else {
                editorView.setAspectRatio(.init(width: ratio.height, height: ratio.width), animated: true)
            }
            resetButton.isEnabled = isReset
            scaleSwitchSelectType = 1
        }
    }
    
    @objc
    func didDrawUndoBtn(button: UIButton) {
        if #available(iOS 13.0, *) {
            editorView.canvasUndo()
        }
    }
    
    @objc
    func didDrawUndoAllBtn(button: UIButton) {
        if #available(iOS 13.0, *) {
            editorView.canvasUndoAll()
        }
    }
    
    @objc
    func didDrawRedoBtn(button: UIButton) {
        if #available(iOS 13.0, *) {
            editorView.canvasRedo()
        }
    }
    
    func checkCanvasButtons() {
        if #available(iOS 13.0, *) {
            drawUndoBtn.isEnabled = editorView.isCanvasCanUndo
            drawRedoBtn.isEnabled = editorView.isCanvasCanRedo
            drawUndoAllBtn.isEnabled = !editorView.isCanvasEmpty
        }
    }
    
}
