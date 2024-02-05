//
//  EditorViewController+UINavigationController.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/7/22.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit

extension EditorViewController: UINavigationControllerDelegate {
    public func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        if operation == .push {
            isTransitionCompletion = false
            return EditorTransition(mode: .push)
        }else if operation == .pop {
            isPopTransition = true
            return EditorTransition(mode: .pop)
        }
        return nil
    }
}

extension EditorViewController: UIViewControllerTransitioningDelegate {
    
    public func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        isTransitionCompletion = false
        return EditorTransition(mode: .present)
    }
    
    public func animationController(
        forDismissed dismissed: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        isPopTransition = true
        return EditorTransition(mode: .dismiss)
    }
}


extension EditorViewController {
    
    func setTransitionImage(_ image: UIImage) {
        editorView.setImage(image)
    }
    
    func transitionHide() {
        cancelButton.alpha = 0
        toolsView.alpha = 0
        finishButton.alpha = 0
        bottomMaskView.alpha = 0
        topMaskView.alpha = 0
        if let tool = selectedTool {
            switch tool.type {
            case .time:
                videoControlView.alpha = 0
            case .graffiti:
                brushColorView.alpha = 0
                brushSizeView.alpha = 0
            case .mosaic:
                mosaicToolView.alpha = 0
            case .filterEdit:
                filterEditView.alpha = 0
                filterParameterView.alpha = 0
            case .filter:
                filtersView.alpha = 0
                filterParameterView.alpha = 0
            case .cropSize:
                if !config.cropSize.aspectRatios.isEmpty {
                    ratioToolView.alpha = 0
                }
                rotateScaleView.alpha = 0
                resetButton.alpha = 0
                leftRotateButton.alpha = 0
                rightRotateButton.alpha = 0
                mirrorVerticallyButton.alpha = 0
                mirrorHorizontallyButton.alpha = 0
                maskListButton.alpha = 0
            default:
                break
            }
        }
    }
    
    func transitionShow() {
        if config.isFixedCropSizeState {
            return
        }
        if selectedAsset.contentType == .image {
            if let type = config.photo.defaultSelectedToolOption, type == .cropSize {
                return
            }
        }else if selectedAsset.contentType == .video {
            if let type = config.video.defaultSelectedToolOption, type == .cropSize {
                return
            }
        }
        showTools()
    }
    
    func showTools(_ isCropSize: Bool = false) {
        if cancelButton.alpha == 1 {
            return
        }
        cancelButton.alpha = 1
        finishButton.alpha = 1
        if !isCropSize {
            toolsView.alpha = 1
            showMasks()
        }
    }
    
    func showMasks() {
        if UIDevice.isPortrait {
            if isToolsDisplay {
                if config.buttonType == .bottom {
                    topMaskView.alpha = 0
                }else {
                    topMaskView.alpha = 1
                }
                bottomMaskView.alpha = 1
            }
        }else {
            if isToolsDisplay {
                topMaskView.alpha = 1
                bottomMaskView.alpha = 1
            }
        }
    }
    
    func hideMasks() {
        if UIDevice.isPortrait {
            if isToolsDisplay {
                topMaskView.alpha = 0
                bottomMaskView.alpha = 0
            }
        }else {
            if isToolsDisplay {
                topMaskView.alpha = 0
                bottomMaskView.alpha = 0
            }
        }
    }
    
    func transitionCompletion() {
        switch loadAssetStatus {
        case .loadding(let isProgress):
            if isProgress {
                switch selectedAsset.type {
                case .networkVideo:
                    assetLoadingView = ProgressHUD.showLoading(addedTo: view, text: "视频下载中".localized, animated: true)
                default:
                    assetLoadingView = ProgressHUD.showLoading(addedTo: view, animated: true)
                }
            }else {
                ProgressHUD.showLoading(addedTo: view, animated: true)
            }
            bringViews()
        case .successful(let type):
            initAssetType(type)
        case .failure:
            if selectedAsset.contentType == .video {
                loadFailure(message: .textManager.editor.videoLoadFailedAlertMessage.text)
            }else {
                loadFailure(message: .textManager.editor.photoLoadFailedAlertMessage.text)
            }
        }
    }
}
