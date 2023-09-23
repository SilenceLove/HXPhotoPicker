//
//  EditorView+ScrollView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2022/11/13.
//

import UIKit

extension EditorView: UIScrollViewDelegate {
    
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        (allowZoom && isCanZoomScale) ? adjusterView : nil
    }
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        if !allowZoom || !isCanZoomScale {
            return
        }
        let viewWidth = scrollView.width - scrollView.contentInset.left - scrollView.contentInset.right
        let viewHeight = scrollView.height - scrollView.contentInset.top - scrollView.contentInset.bottom
        let offsetX = (viewWidth > scrollView.contentSize.width) ?
            (viewWidth - scrollView.contentSize.width) * 0.5 : 0
        let offsetY = (viewHeight > scrollView.contentSize.height) ?
            (viewHeight - scrollView.contentSize.height) * 0.5 : 0
        let centerX = scrollView.contentSize.width * 0.5 + offsetX
        let centerY = scrollView.contentSize.height * 0.5 + offsetY
        adjusterView.center = CGPoint(x: centerX, y: centerY)
    }
    public func scrollViewDidEndZooming(
        _ scrollView: UIScrollView,
        with view: UIView?,
        atScale scale: CGFloat
    ) {
        adjusterView.zoomScale = scale
    }
}
