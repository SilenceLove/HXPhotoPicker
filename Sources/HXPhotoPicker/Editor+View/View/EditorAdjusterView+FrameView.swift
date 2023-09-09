//
//  EditorAdjusterView+FrameView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2022/11/13.
//

import UIKit

extension EditorAdjusterView: EditorFrameViewDelegate {
    
    var finalView: UIView {
        frameView.controlView
    }
    
    func updateControlScaleSize() {
        let contentSize = contentView.bounds.size
        let controlSize = getControlInContentRect(true).size
        let width = imageSize.width * (controlSize.width / contentSize.width)
        let height = imageSize.height * (controlSize.height / contentSize.height)
        let size =  CGSize(width: width, height: height)
        if !frameView.imageSizeScale.equalTo(size) {
            frameView.imageSizeScale = size
        }
    }
    
    func frameView(beganChanged frameView: EditorFrameView, _ rect: CGRect) {
        updateControlScaleSize()
        delegate?.editorAdjusterView(willBeginEditing: self)
    }
    
    func frameView(didChanged frameView: EditorFrameView, _ rect: CGRect) {
        updateControlScaleSize()
        scrollView.minimumZoomScale = getScrollViewMinimumZoomScale(rect)
        let minSize = getMinimuzmControlSize(rect: rect)
        var changedZoomScale = false
        if minSize.height > contentView.height {
            let imageZoomScale = minSize.height / contentView.height
            let zoomScale = scrollView.zoomScale
            scrollView.setZoomScale(zoomScale * imageZoomScale, animated: false)
            changedZoomScale = true
        }
        if minSize.width > contentView.width {
            let imageZoomScale = minSize.width / contentView.width
            let zoomScale = scrollView.zoomScale
            scrollView.setZoomScale(zoomScale * imageZoomScale, animated: false)
            changedZoomScale = true
        }
        if !changedZoomScale {
            setScrollViewContentInset(rect)
        }
    }
    
    func frameView(endChanged frameView: EditorFrameView, _ rect: CGRect) {
        adjustmentViews(true)
    }
    
    func adjustmentViews(_ animated: Bool) {
        isMaskBgViewShowing = true
        /// 最大高度
        let maxHeight = containerView.height - contentInsets.top - contentInsets.bottom
        /// 裁剪框x
        var rectX = contentInsets.left
        /// 裁剪框的宽度
        var rectW = containerView.width - contentInsets.left - contentInsets.right
        let controlView = frameView.controlView!
        /// 裁剪框高度
        var rectH = rectW / controlView.width * controlView.height
        if rectH > maxHeight {
            /// 裁剪框超过最大高度就进行缩放
            rectW = maxHeight / rectH *  rectW
            rectH = maxHeight
            rectX = controlView.maxImageresizerFrame.midX - rectW * 0.5
        }
        /// 裁剪框y
        let rectY = controlView.maxImageresizerFrame.midY - rectH * 0.5
        /// 裁剪框将需要更新坐标
        let rect = CGRect(x: rectX, y: rectY, width: rectW, height: rectH)
        /// 裁剪框当前的坐标
        let beforeRect = controlView.frame
        /// 裁剪框当前在imageView上的坐标
        let controlBeforeRect = getControlInContentRect()
        /// 更新裁剪框坐标
        frameView.updateFrame(to: rect, animated: animated)
        updateControlScaleSize()
        /// 裁剪框更新之后再imageView上的坐标
        let controlAfterRect = getControlInContentRect()
        let scrollCotentInset = getScrollViewContentInset(rect)
        
        let beforeRoateRect = getControlInRotateRect(beforeRect)
        let afterRoateRect = getControlInRotateRect(rect)
        /// 计算scrollView偏移量
        var offset = scrollView.contentOffset
        let offsetX = offset.x - (afterRoateRect.midX - beforeRoateRect.midX)
        let offsetY = offset.y - (afterRoateRect.midY - beforeRoateRect.midY)
        offset = getZoomOffset(
            CGPoint(x: offsetX, y: offsetY),
            scrollCotentInset
        )
        let zoomScale = getZoomScale(
            fromRect: controlBeforeRect,
            toRect: controlAfterRect
        )
        let needZoomScale = zoomScale != scrollView.zoomScale
        if animated {
            isUserInteractionEnabled = false
            let currentOffset = scrollView.contentOffset
            scrollView.setContentOffset(currentOffset, animated: false)
            UIView.animate {
                self.setScrollViewContentInset(rect)
                if needZoomScale {
                    /// 需要进行缩放
                    self.scrollView.zoomScale = zoomScale
                    offset = self.getZoomOffset(
                        fromRect: controlBeforeRect,
                        zoomScale: zoomScale,
                        scrollCotentInset: scrollCotentInset
                    )
                }
                self.scrollView.contentOffset = offset
            } completion: { _ in
                self.scrollView.minimumZoomScale = self.getScrollViewMinimumZoomScale(rect)
                self.frameView.showMaskBgView()
                if self.isContinuousRotation {
                    self.frameView.showGridGraylinesLayer()
                }
                if self.state == .edit {
                    self.frameView.showVideoSlider(true)
                }
                self.isMaskBgViewShowing = false
                self.frameView.inControlTimer = false
                self.isUserInteractionEnabled = true
                self.delegate?.editorAdjusterView(didEndEditing: self)
            }
        }else {
            setScrollViewContentInset(rect)
            if needZoomScale {
                /// 需要进行缩放
                scrollView.zoomScale = zoomScale
                offset = getZoomOffset(
                    fromRect: controlBeforeRect,
                    zoomScale: zoomScale,
                    scrollCotentInset: scrollCotentInset
                )
            }
            scrollView.contentOffset = offset
            scrollView.minimumZoomScale = getScrollViewMinimumZoomScale(rect)
            frameView.showMaskBgView(animated: false)
            if isContinuousRotation {
                frameView.showGridGraylinesLayer(animated: false)
            }
            if state == .edit {
                frameView.showVideoSlider(false)
            }
            updateControlScaleSize()
            isMaskBgViewShowing = false
            frameView.inControlTimer = false
            delegate?.editorAdjusterView(didEndEditing: self)
        }
    }
    
    func frameView(_ frameView: EditorFrameView, didChangedPlayTime time: CGFloat, for state: VideoControlEvent) {
        var toTime: CGFloat
        if let startTime = videoStartTime, videoEndTime != nil {
            toTime = startTime.seconds + time
        }else if let startTime = videoStartTime {
            toTime = startTime.seconds + time
        }else {
            toTime = time
        }
        seekVideo(to: toTime, isPlay: false)
        delegate?.editorAdjusterView(self, videoControlDidChangedTimeAt: TimeInterval(toTime), for: state)
    }
    
    func frameView(_ frameView: EditorFrameView, didPlayButtonClick isSelected: Bool) {
        if isSelected {
            playVideo()
        }else {
            pauseVideo()
        }
    }
}

extension EditorAdjusterView {
    
    func showVideoControl(_ animated: Bool) {
        if state == .edit {
            return
        }
        frameView.showVideoSlider(animated)
    }
    
    func hideVideoControl(_ animated: Bool) {
        if state == .edit {
            return
        }
        frameView.hideVideoSilder(animated)
    }
    
}
