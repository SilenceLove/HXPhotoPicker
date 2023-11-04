//
//  EditorAdjusterView+ScreenRotation.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/4.
//

import UIKit

extension EditorAdjusterView { 
    func prepareUpdate() {
        if state == .edit {
            stopTimer()
            adjustmentViews(false)
        }
        
        beforeContentOffset = scrollView.contentOffset
        beforeContentSize = scrollView.contentSize
        beforeContentInset = scrollView.contentInset
        beforeMirrorViewTransform = mirrorView.transform
        beforeRotateViewTransform = rotateView.transform
        beforeScrollViewTransform = scrollView.transform
        beforeScrollViewZoomScale = scrollView.zoomScale / scrollView.minimumZoomScale
        beforeDrawBrushInfos = contentView.drawView.getBrushData()
        beforeMosaicDatas = contentView.mosaicView.getMosaicData()
        beforeStickerItem = contentView.stickerView.getStickerItem()
        if #available(iOS 13.0, *), let canvasView = contentView.canvasView as? EditorCanvasView {
            beforeCanvasCurrentData = canvasView.currentData
            beforeCanvasHistoryData = canvasView.historyData
            canvasView.isClear = true
            canvasView.undoAll()
            canvasView.isClear = false
        }
        
        contentView.drawView.undoAll()
        contentView.mosaicView.undoAll()
        contentView.stickerView.removeAllSticker()
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        mirrorView.transform = .identity
        rotateView.transform = .identity
        scrollView.transform = .identity
        CATransaction.commit()
        scrollView.minimumZoomScale = 1
        scrollView.zoomScale = 1
    }
    
    func update() {
        setContent(state == .edit)
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        mirrorView.transform = beforeMirrorViewTransform
        rotateView.transform = beforeRotateViewTransform
        scrollView.transform = beforeScrollViewTransform
        CATransaction.commit()
        
        contentView.drawView.setBrushData(beforeDrawBrushInfos, viewSize: contentView.bounds.size)
        contentView.mosaicView.setMosaicData(mosaicDatas: beforeMosaicDatas, viewSize: contentView.bounds.size)
        contentView.stickerView.setStickerItem(beforeStickerItem, viewSize: contentView.bounds.size)
        if #available(iOS 13.0, *), let canvasView = contentView.canvasView as? EditorCanvasView {
            canvasView.setCurrentData(beforeCanvasCurrentData, viewSize: contentView.bounds.size)
            canvasView.setHistoryData(beforeCanvasHistoryData, viewSize: contentView.bounds.size)
        }
        
        let controlScale = frameView.controlView.size.height / frameView.controlView.size.width
        let beforeZoomScale = beforeScrollViewZoomScale
        var maxWidth = containerView.width
        var maxHeight = containerView.height
        if state == .edit {
            maxWidth -= contentInsets.left + contentInsets.right
            maxHeight -= contentInsets.top + contentInsets.bottom
            var maskWidth = maxWidth
            var maskHeight = maskWidth * controlScale
            if maskHeight > maxHeight {
                maskWidth *= maxHeight / maskHeight
                maskHeight = maxHeight
            }
            let maskRect = CGRect(
                x: contentInsets.left + (maxWidth - maskWidth) * 0.5,
                y: contentInsets.top + (maxHeight - maskHeight) * 0.5,
                width: maskWidth,
                height: maskHeight
            )
            updateMaskRect(to: maskRect, animated: false)
        }else {
            let rectW = maxWidth
            let rectH = maxWidth * controlScale
            var rectY: CGFloat = 0
            if rectH < maxHeight {
                rectY = (maxHeight - rectH) * 0.5
            }
            let maskRect = CGRect(x: 0, y: rectY, width: rectW, height: rectH)
            updateMaskRect(to: maskRect, animated: false)
        }
        if let oldData = oldAdjustedFactor {
            let controlScale = oldData.maskRect.height / oldData.maskRect.width
            let maxWidth = containerView.width - contentInsets.left - contentInsets.right
            let maxHeight = containerView.height - contentInsets.top - contentInsets.bottom
            var maskWidth = maxWidth
            var maskHeight = maskWidth * controlScale
            if maskHeight > maxHeight {
                maskWidth *= maxHeight / maskHeight
                maskHeight = maxHeight
            }
            let maskRect = CGRect(
                x: contentInsets.left + (maxWidth - maskWidth) * 0.5,
                y: contentInsets.top + (maxHeight - maskHeight) * 0.5,
                width: maskWidth,
                height: maskHeight
            )
            oldAdjustedFactor?.maskRect = maskRect
            let zoomScale = getScrollViewMinimumZoomScale(maskRect) * oldData.min_zoom_scale
            oldAdjustedFactor?.zoomScale = zoomScale
        }
        
        let controlView = frameView.controlView!
        setScrollViewContentInset(controlView.frame)
        if state == .edit {
            let minimumZoomScale = getScrollViewMinimumZoomScale(controlView.frame)
            scrollView.minimumZoomScale = minimumZoomScale
            let zoomScale = max(minimumZoomScale, minimumZoomScale * beforeZoomScale)
            scrollView.zoomScale = zoomScale
        }else {
            if let data = oldAdjustedFactor {
                let minimumZoomScale = getScrollViewMinimumZoomScale(data.maskRect)
                scrollView.minimumZoomScale = minimumZoomScale
                let maxWidth = containerView.width
                let scale = maxWidth / data.maskRect.width
                let zoomScale = data.zoomScale * scale
                scrollView.zoomScale = zoomScale
            }else {
                scrollView.minimumZoomScale = 1
                scrollView.zoomScale = 1
            }
        }
        
        if let data = oldAdjustedFactor {
            let contentWidth = baseContentSize.width * data.zoomScale
            let contentHeight = baseContentSize.height * data.zoomScale
            let contentInset = getOldContentInsert()
            oldAdjustedFactor?.contentInset = contentInset
            
            let offsetX = contentWidth * data.contentOffsetScale.x - contentInset.left
            let offsetY = contentHeight * data.contentOffsetScale.y - contentInset.top
            oldAdjustedFactor?.contentOffset = .init(x: offsetX, y: offsetY)
        }
        let contentSize = scrollView.contentSize
        let contentInset = scrollView.contentInset
        let offsetXScale = (beforeContentOffset.x + beforeContentInset.left) / beforeContentSize.width
        let offsetYScale = (beforeContentOffset.y + beforeContentInset.top) / beforeContentSize.height
        let offsetX = contentSize.width * offsetXScale - contentInset.left
        let offsetY = contentSize.height * offsetYScale - contentInset.top
        if !offsetX.isNaN && !offsetY.isNaN {
            scrollView.contentOffset = CGPoint(x: offsetX, y: offsetY)
        }
    }
}
