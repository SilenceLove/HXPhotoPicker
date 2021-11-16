//
//  PhotoEditorViewController+MosaicToolView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/11/15.
//

import UIKit

extension PhotoEditorViewController: PhotoEditorMosaicToolViewDelegate {
    func mosaicToolView(
        _ mosaicToolView: PhotoEditorMosaicToolView,
        didChangedMosaicType type: PhotoEditorMosaicView.MosaicType
    ) {
        imageView.mosaicType = type
    }
    
    func mosaicToolView(didUndoClick mosaicToolView: PhotoEditorMosaicToolView) {
        imageView.undoMosaic()
        mosaicToolView.canUndo = imageView.canUndoMosaic
    }
}
