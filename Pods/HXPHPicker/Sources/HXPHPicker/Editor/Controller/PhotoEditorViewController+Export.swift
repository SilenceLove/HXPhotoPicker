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
            ProgressHUD.showLoading(addedTo: view, animated: true)
            imageView.cropping { [weak self] (result) in
                guard let self = self else { return }
                if let result = result {
                    self.delegate?.photoEditorViewController(self, didFinish: result)
                    self.didBackClick()
                }else {
                    ProgressHUD.hide(forView: self.view, animated: true)
                    ProgressHUD.showWarning(
                        addedTo: self.view,
                        text: "图片获取失败!".localized,
                        animated: true,
                        delayHide: 1.5
                    )
                }
            }
        }else {
            delegate?.photoEditorViewController(didFinishWithUnedited: self)
            didBackClick()
        }
    }
}
