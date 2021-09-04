//
//  EditorImageResizerView+ScrollView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/25.
//

import UIKit

// MARK: UIScrollViewDelegate
extension EditorImageResizerView: UIScrollViewDelegate {
    func didScrollAction() {
        if state != .cropping || controlView.panning {
            return
        }
        stopControlTimer()
        if !maskBgViewisShowing {
            hideMaskBgView()
        }
    }
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        didScrollAction()
        delegate?.imageResizerView(willBeginDragging: self)
    }
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        didScrollAction()
        delegate?.imageResizerView(willBeginDragging: self)
    }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if state != .cropping || controlView.panning {
            return
        }
        if !decelerate {
            if inControlTimer {
                startControlTimer()
            }else {
                startShowMaskBgTimer()
            }
            delegate?.imageResizerView(didEndDecelerating: self)
        }
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if state != .cropping || controlView.panning {
            return
        }
        if inControlTimer {
            startControlTimer()
        }else {
            startShowMaskBgTimer()
        }
        delegate?.imageResizerView(didEndDecelerating: self)
    }
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateScrollViewContentInset(controlView.frame)
        
    }
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        if state != .cropping {
            return
        }
        stopControlTimer()
        if !maskBgViewisShowing {
            hideMaskBgView()
        }
        delegate?.imageResizerView(WillBeginZooming: self)
    }
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        if state != .cropping {
            return
        }
        zoomScale = scale
        if inControlTimer {
            startControlTimer()
        }else {
            startShowMaskBgTimer()
        }
        delegate?.imageResizerView(didEndZooming: self)
    }
    
    /// 更新scrollView属性
    func updateScrollView() {
        scrollView.alwaysBounceVertical = state == .cropping
        scrollView.alwaysBounceHorizontal = state == .cropping
        scrollView.isScrollEnabled = state == .cropping
        scrollView.pinchGestureRecognizer?.isEnabled = state == .cropping
    }
    /// 根据裁剪框位置大小获取ScrollView的ContentInset
    func getScrollViewContentInset(_ rect: CGRect, _ isOld: Bool = false) -> UIEdgeInsets {
        switch getImageOrientation(isOld) {
        case .up:
            let top: CGFloat = rect.minY
            let bottom: CGFloat = containerView.height - rect.maxY
            var left: CGFloat
            var right: CGFloat
            if isOld ? oldMirrorType == .horizontal : mirrorType == .horizontal {
                left = containerView.width - rect.maxX
                right = rect.minX
            }else {
                left = rect.minX
                right = containerView.width - rect.maxX
            }
            return UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
        case .left:
            var top = rect.minX
            var bottom = containerView.width - rect.maxX
            let left = containerView.height - rect.maxY
            let right = rect.minY
            if isOld ? oldMirrorType == .horizontal : mirrorType == .horizontal {
                top = containerView.width - rect.maxX
                bottom = rect.minX
            }else {
                top = rect.minX
                bottom = containerView.width - rect.maxX
            }
            return UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
        case .down:
            let top = containerView.height - rect.maxY
            let bottom = rect.minY
            var left = containerView.width - rect.maxX
            var right = rect.minX
            if isOld ? oldMirrorType == .horizontal : mirrorType == .horizontal {
                left = rect.minX
                right = containerView.width - rect.maxX
            }else {
                left = containerView.width - rect.maxX
                right = rect.minX
            }
            return UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
        case .right:
            var top = containerView.width - rect.maxX
            var bottom = rect.minX
            let left = rect.minY
            let right = containerView.height - rect.maxY
            if isOld ? oldMirrorType == .horizontal : mirrorType == .horizontal {
                top = rect.minX
                bottom = containerView.width - rect.maxX
            }else {
                top = containerView.width - rect.maxX
                bottom = rect.minX
            }
            return UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
        }
    }
    /// 根据裁剪框大小更新ScrollView的ContentInset
    func updateScrollViewContentInset(_ rect: CGRect) {
        scrollView.contentInset = getScrollViewContentInset(rect)
    }
    
    /// 根据裁剪框大小获取最小缩放比例
    /// - Parameter rect: 线框大小
    /// - Returns: 最小缩放比例
    func getScrollViewMinimumZoomScale(_ rect: CGRect) -> CGFloat {
        var minZoomScale: CGFloat
        let rectW = rect.width
        let rectH = rect.height
        if rectW >= rectH {
            switch getImageOrientation() {
            case .up, .down:
                minZoomScale = rectW / baseImageSize.width
                let scaleHeight = baseImageSize.height * minZoomScale
                if scaleHeight < rectH {
                    minZoomScale *= rectH / scaleHeight
                }
            case .right, .left:
                minZoomScale = rectW / baseImageSize.height
                let scaleHeight = baseImageSize.width * minZoomScale
                if scaleHeight < rectH {
                    minZoomScale *= rectH / scaleHeight
                }
            }
        }else {
            switch getImageOrientation() {
            case .up, .down:
                minZoomScale = rectH / baseImageSize.height
                let scaleWidth = baseImageSize.width * minZoomScale
                if scaleWidth < rectW {
                    minZoomScale *= rectW / scaleWidth
                }
            case .right, .left:
                minZoomScale = rectH / baseImageSize.width
                let scaleWidth = baseImageSize.height * minZoomScale
                if scaleWidth < rectW {
                    minZoomScale *= rectW / scaleWidth
                }
            }
        }
        return minZoomScale
    }
}
