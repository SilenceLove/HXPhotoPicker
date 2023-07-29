//
//  EditorViewController+Brush.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/17.
//

import UIKit

extension EditorViewController: EditorBrushColorViewDelegate {
    func brushColorView(
        _ colorView: EditorBrushColorView,
        changedColor colorHex: String
    ) {
        editorView.drawLineColor = colorHex.color
        brushBlockView.color = colorHex.color
        showBrushBlockView()
        perform(#selector(hideBrushBlockView), with: nil, afterDelay: 1.5, inModes: [.common])
    }
    func brushColorView(
        _ colorView: EditorBrushColorView,
        changedColor color: UIColor
    ) {
        editorView.drawLineColor = color
        brushBlockView.color = color
        showBrushBlockView()
        perform(#selector(hideBrushBlockView), with: nil, afterDelay: 1.5, inModes: [.common])
        
    }
    func brushColorView(
        didUndoButton colorView: EditorBrushColorView
    ) {
        editorView.undoDraw()
        brushColorView.canUndo = editorView.isCanUndoDraw
        checkFinishButtonState()
    }
    
    func showBrushBlockView() {
        UIViewController.cancelPreviousPerformRequests(
            withTarget: self,
            selector: #selector(hideBrushBlockView),
            object: nil
        )
        if brushBlockView.superview == view {
            return
        }
        brushBlockView.layer.removeAllAnimations()
        brushBlockView.center = CGPoint(x: self.view.width * 0.5, y: self.view.height * 0.5)
        brushBlockView.alpha = 0
        view.addSubview(brushBlockView)
        UIView.animate(withDuration: 0.2) {
            self.brushBlockView.alpha = 1
        }
    }
    
    @objc
    func hideBrushBlockView() {
        if brushBlockView.superview != view {
            return
        }
        UIView.animate(withDuration: 0.2) {
            self.brushBlockView.alpha = 0
        } completion: {
            if !$0 {
                return
            }
            self.brushBlockView.removeFromSuperview()
        }
    }
}
