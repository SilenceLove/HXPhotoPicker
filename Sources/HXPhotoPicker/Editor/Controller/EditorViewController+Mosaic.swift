//
//  EditorViewController+Mosaic.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/20.
//

import UIKit

extension EditorViewController: EditorMosaicToolViewDelegate {
    func mosaicToolView(_ mosaicToolView: EditorMosaicToolView, didChangedMosaicType type: EditorMosaicType) {
        editorView.mosaicType = type
    }
    
    func mosaicToolView(didUndoClick mosaicToolView: EditorMosaicToolView) {
        editorView.undoMosaic()
        mosaicToolView.canUndo = editorView.isCanUndoMosaic
        checkFinishButtonState()
    }
}
