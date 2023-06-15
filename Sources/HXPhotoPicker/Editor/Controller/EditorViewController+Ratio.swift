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
            editorView.setAspectRatio(editorView.originalAspectRatio, animated: true)
        }else {
            if ratio == .zero {
                editorView.isFixedRatio = false
            }else {
                editorView.isFixedRatio = true
                editorView.setAspectRatio(ratio, animated: true)
            }
        }
        resetButton.isEnabled = isReset
    }
}
