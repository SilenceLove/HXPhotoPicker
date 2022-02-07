//
//  EditorImageResizerView+Mask.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/25.
//

import UIKit

// MARK: MaskView Action
extension EditorImageResizerView {
    func getMaskRect() -> CGRect {
        return getImageViewFrame()
    }
    /// 显示遮罩界面
    func hiddenMaskView(_ animated: Bool, onlyLines: Bool = false) {
        if animated {
            UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseOut) {
                if !onlyLines {
                    self.maskBgView.alpha = 0
                }
                self.maskLinesView.alpha = 0
            } completion: { (isFinished) in
                if !onlyLines {
                    self.maskBgView.isHidden = true
                }
                self.maskLinesView.isHidden = true
            }
        }else {
            if !onlyLines {
                self.maskBgView.isHidden = true
                self.maskBgView.alpha = 0
            }
            self.maskLinesView.isHidden = true
            self.maskLinesView.alpha = 0
        }
    }
    
    /// 隐藏遮罩界面
    func showMaskView(_ animated: Bool) {
        if animated {
            self.maskBgView.isHidden = false
            self.maskLinesView.isHidden = false
            UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseOut) {
                self.maskBgView.alpha = 1
                self.maskLinesView.alpha = 1
            }
        }else {
            self.maskBgView.isHidden = false
            self.maskLinesView.isHidden = false
            self.maskBgView.alpha = 1
            self.maskLinesView.alpha = 1
        }
    }
    /// 裁剪框初始位置大小
    func getMaskViewFrame(_ isBase: Bool = false) -> CGRect {
        if !isOriginalRatio {
            return getInitializationRatioMaskRect()
        }
        let zoomScale = scrollView.minimumZoomScale
        let maskWidth = isBase ? baseImageSize.width * zoomScale : imageView.width * zoomScale
        let maskHeight = isBase ? baseImageSize.height * zoomScale : imageView.height * zoomScale
        let maskX = (
            containerView.width - contentInsets.left - contentInsets.right - maskWidth
        ) * 0.5 + contentInsets.left
        let maskY = (
            containerView.height - contentInsets.top - contentInsets.bottom - maskHeight
        ) * 0.5 + contentInsets.top
        return CGRect(x: maskX, y: maskY, width: maskWidth, height: maskHeight)
    }
    /// 更新遮罩界面位置大小
    /// - Parameters:
    ///   - rect: 指定位置
    ///   - animated: 是否需要动画效果
    func updateMaskViewFrame(to rect: CGRect, animated: Bool) {
        if rect.width.isNaN || rect.height.isNaN {
            return
        }
        /// 手势控制视图
        controlView.frame = rect
        /// 更新遮罩位置大小
        maskBgView.updateLayers(rect, animated)
        /// 更新线框位置大小
        maskLinesView.updateLayers(rect, animated)
        if state == .cropping {
            // 修改最小缩放比例
            scrollView.minimumZoomScale = getScrollViewMinimumZoomScale(rect)
        }
    }
    func startShowMaskBgTimer() {
        maskBgShowTimer?.invalidate()
        let timer = Timer.scheduledTimer(
            timeInterval: 1,
            target: self,
            selector: #selector(showMaskBgView),
            userInfo: nil,
            repeats: false
        )
        maskBgShowTimer = timer
    }
    func stopShowMaskBgTimer() {
        maskBgShowTimer?.invalidate()
        maskBgShowTimer = nil
    }
    /// 显示遮罩背景
    @objc func showMaskBgView() {
        if maskBgView.alpha == 1 {
            return
        }
        maskBgView.layer.removeAllAnimations()
        maskLinesView.showGridlinesLayer(false)
        UIView.animate(withDuration: 0.2) {
            self.maskBgView.alpha = 1
        }
    }
    /// 隐藏遮罩背景
    func hideMaskBgView() {
        stopShowMaskBgTimer()
        if maskBgView.alpha == 0 {
            return
        }
        maskBgView.layer.removeAllAnimations()
        maskLinesView.showGridlinesLayer(true)
        UIView.animate(withDuration: 0.2) {
            self.maskBgView.alpha = 0
        }
    }
}
