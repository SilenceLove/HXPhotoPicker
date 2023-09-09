//
//  EditorViewController+Ratio.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/17.
//

import UIKit

extension EditorViewController: EditorRatioToolViewDelegate {
    func ratioToolView(_ ratioToolView: EditorRatioToolView, didSelectedRatioAt ratio: CGSize) {
        if ratio.width < 0 || ratio.height < 0 {
            editorView.isFixedRatio = true
            let ratio = editorView.originalAspectRatio
            let buttonType: Int
            if let selectType = scaleSwitchSelectType {
                buttonType = selectType
                if selectType == 0 {
                    if ratio.width < ratio.height {
                        editorView.setAspectRatio(ratio, animated: true)
                    }else {
                        editorView.setAspectRatio(.init(width: ratio.height, height: ratio.width), animated: true)
                    }
                }else {
                    if ratio.width < ratio.height {
                        editorView.setAspectRatio(.init(width: ratio.height, height: ratio.width), animated: true)
                    }else {
                        editorView.setAspectRatio(ratio, animated: true)
                    }
                }
            }else {
                buttonType = ratio.width < ratio.height ? 0 : 1
                scaleSwitchSelectType = buttonType
                editorView.setAspectRatio(ratio, animated: true)
            }
            scaleSwitchLeftBtn.isSelected = buttonType == 0
            scaleSwitchRightBtn.isSelected = buttonType == 1
            showScaleSwitchView(UIDevice.isPortrait)
            hideMasks()
        }else {
            hideScaleSwitchView(UIDevice.isPortrait)
            editorView.isFixedRatio = ratio != .zero
            if editorView.isFixedRatio {
                editorView.setAspectRatio(ratio, animated: true)
            }
        }
        resetButton.isEnabled = isReset
    }
}
