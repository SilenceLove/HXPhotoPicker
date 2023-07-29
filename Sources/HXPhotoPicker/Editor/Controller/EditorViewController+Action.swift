//
//  EditorViewController+Action.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/7/22.
//  Copyright © 2023 洪欣. All rights reserved.
//

import UIKit

extension EditorViewController {
    
    @objc
    func didCancelButtonClick(button: UIButton) {
        if let selectedTool = selectedTool {
            switch selectedTool.type {
            case .cropSize:
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
                showChangeButton()
                checkFinishButtonState()
                return
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
                finishScaleAngle = rotateScaleView.angle
                if !config.cropSize.aspectRatios.isEmpty {
                    finishRatioIndex = ratioToolView.selectedIndex
                }
                if config.isFixedCropSizeState {
                    processing()
                    return
                }
                editorView.finishEdit(true)
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
                showChangeButton()
                checkFinishButtonState()
                return
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
            ratioToolView.scrollToFree(animated: true)
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
    func didChangeButtonClick(button: UIButton) {
        
    }
    
    @objc
    func didMaskListButtonClick(button: UIButton) {
        let vc = EditorMaskListViewController(config: config.cropSize)
        vc.delegate = self
        let nav = UINavigationController(rootViewController: vc)
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
}
