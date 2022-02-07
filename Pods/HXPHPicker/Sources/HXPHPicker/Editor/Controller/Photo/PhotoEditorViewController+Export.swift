//
//  PhotoEditorViewController+Export.swift
//  HXPHPicker
//
//  Created by Slience on 2021/7/14.
//

import UIKit

extension PhotoEditorViewController {
    func exportResources() {
        if imageView.canReset() ||
            imageView.imageResizerView.hasCropping ||
            imageView.canUndoDraw ||
            imageView.canUndoMosaic ||
            imageView.hasFilter ||
            imageView.hasSticker {
            imageView.deselectedSticker()
            ProgressHUD.showLoading(addedTo: view, text: "正在处理...", animated: true)
            imageView.cropping { [weak self] in
                guard let self = self else { return }
                if let result = $0 {
                    ProgressHUD.hide(forView: self.view, animated: false)
                    self.isFinishedBack = true
                    self.transitionalImage = result.editedImage
                    self.delegate?.photoEditorViewController(self, didFinish: result)
                    self.finishHandler?(self, result)
                    self.didBackClick()
                }else {
                    ProgressHUD.hide(forView: self.view, animated: true)
                    ProgressHUD.showWarning(
                        addedTo: self.view,
                        text: "处理失败".localized,
                        animated: true,
                        delayHide: 1.5
                    )
                }
            }
        }else {
            transitionalImage = image
            delegate?.photoEditorViewController(didFinishWithUnedited: self)
            finishHandler?(self, nil)
            didBackClick()
        }
    }
}
