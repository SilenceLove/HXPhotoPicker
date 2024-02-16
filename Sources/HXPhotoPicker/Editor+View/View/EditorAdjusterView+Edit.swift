//
//  EditorAdjusterView+Edit.swift
//  HXPhotoPicker
//
//  Created by Slience on 2022/11/13.
//

import UIKit

extension EditorAdjusterView {
    
    func startEdit(_ animated: Bool, completion: (() -> Void)? = nil) {
        contentView.isDrawEnabled = false
        contentView.isMosaicEnabled = false
        contentView.isStickerEnabled = false
        if state == .edit {
            resetState()
            frameView.isControlEnable = true
            clipsToBounds = false
            return
        }
        delegate?.editorAdjusterView(editWillAppear: self)
        state = .edit
        resetState()
        frameView.isControlEnable = true
        clipsToBounds = false
        
        if let oldFactor = oldRatioFactor {
            frameView.aspectRatio = oldFactor.aspectRatio
            isFixedRatio = oldFactor.fixedRatio
        }else {
            if initialRoundMask {
                frameView.isRoundCrop = true
                isFixedRatio = true
            }else {
                isFixedRatio = initialFixedRatio
            }
        }
        let minimumZoomScale: CGFloat
        let maximumZoomScale = self.maximumZoomScale
        let maskRect: CGRect
        let isUpdateMask: Bool
        if let oldAdjustedData = oldAdjustedFactor {
            adjustedFactor = oldAdjustedData
            minimumZoomScale = getScrollViewMinimumZoomScale(oldAdjustedData.maskRect)
            frameView.showBlackMask(animated: false)
            maskRect = oldAdjustedData.maskRect
            scrollView.minimumZoomScale = minimumZoomScale
            scrollView.maximumZoomScale = maximumZoomScale
            isUpdateMask = true
        }else {
            if initialRoundMask {
                frameView.aspectRatio = .init(width: 1, height: 1)
                updateMaskAspectRatio(animated)
                maskRect = frameView.controlView.frame
                minimumZoomScale = getScrollViewMinimumZoomScale(maskRect)
                isUpdateMask = false
            }else {
                if initialFixedRatio && initialAspectRatio == .zero {
                    frameView.aspectRatio = originalAspectRatio
                    updateMaskAspectRatio(animated)
                    maskRect = frameView.controlView.frame
                    minimumZoomScale = getScrollViewMinimumZoomScale(maskRect)
                    isUpdateMask = false
                }else if initialAspectRatio != .zero {
                    frameView.aspectRatio = initialAspectRatio
                    updateMaskAspectRatio(animated)
                    maskRect = frameView.controlView.frame
                    minimumZoomScale = getScrollViewMinimumZoomScale(maskRect)
                    isUpdateMask = false
                }else {
                    minimumZoomScale = initialZoomScale
                    scrollView.minimumZoomScale = minimumZoomScale
                    scrollView.maximumZoomScale = maximumZoomScale
                    maskRect = getMaskRect()
                    isUpdateMask = true
                }
            }
        }
        if isUpdateMask {
            updateMaskRect(to: maskRect, animated: animated)
        }else {
            scrollView.minimumZoomScale = minimumZoomScale
            scrollView.maximumZoomScale = maximumZoomScale
        }
        
        if animated {
            UIView.animate {
                self.setupEdit(maskRect: maskRect)
            } completion: {
                if !$0 {
                    return
                }
                self.frameView.blackMask(
                    isShow: false,
                    animated: animated
                )
                self.frameView.show(animated)
                self.frameView.showImageMaskView(animated)
                self.frameView.showCustomMaskView(animated)
                self.frameView.showLinesShadow()
                self.frameView.showVideoSlider(animated)
                self.delegate?.editorAdjusterView(editDidAppear: self)
                completion?()
            }
        }else {
            setupEdit(maskRect: maskRect)
            frameView.blackMask(
                isShow: false,
                animated: animated
            )
            frameView.show(animated)
            frameView.showImageMaskView(animated)
            frameView.showCustomMaskView(animated)
            frameView.showLinesShadow()
            frameView.showVideoSlider(animated)
            delegate?.editorAdjusterView(editDidAppear: self)
            completion?()
        }
    }
    
    func finishEdit(
        _ animated: Bool,
        completion: (() -> Void)? = nil
    ) {
        if state != .edit {
            return
        }
        frameView.stopTimer()
        delegate?.editorAdjusterView(editWillDisappear: self)
        endEdit()
        
        let fromSize = getExactnessSize(contentView.size)
        let toSize = getExactnessSize(frameView.controlView.size)
        
        let isEqualSize = (
            !fromSize.equalTo(toSize)
            ||
            (fromSize.equalTo(toSize) &&
             frameView.isRoundCrop
            )
        )
        oldMaskImage = adjustedFactor.maskImage
        oldIsRound = frameView.isRoundCrop
        if canReset || (!canReset && isEqualSize ) {
            // 调整裁剪框至中心
            adjustmentViews(false)
            
            let contentInset = scrollView.contentInset
            let contentSize = scrollView.contentSize
            let contentOffset = scrollView.contentOffset
            var oldData = AdjustedFactor()
            // 记录当前数据
            oldData.zoomScale = scrollView.zoomScale
            oldData.contentOffset = contentOffset
            oldData.contentInset = contentInset
            oldData.maskRect = frameView.controlView.frame
            oldData.angle = adjustedFactor.angle
            oldData.mirrorTransform = adjustedFactor.mirrorTransform
            oldData.transform = scrollView.transform
            oldData.rotateTransform = rotateView.transform
            
            let offsetXScale = (contentOffset.x + contentInset.left) / contentSize.width
            let offsetYScale = (contentOffset.y + contentInset.top) / contentSize.height
            oldData.contentOffsetScale = .init(x: offsetXScale, y: offsetYScale)
            oldData.min_zoom_scale = scrollView.zoomScale / getScrollViewMinimumZoomScale(oldData.maskRect)
            oldData.isRoundMask = isRoundMask
            oldData.maskImage = oldMaskImage
            
            oldAdjustedFactor = oldData
            
            oldRatioFactor = .init(fixedRatio: frameView.isFixedRatio, aspectRatio: frameView.aspectRatio)
        }else {
            oldAdjustedFactor = nil
            oldRatioFactor = nil
        }
        // 计算裁剪框的位置
        let maxWidth = containerView.width
        let rectW = maxWidth
        let scale = maxWidth / frameView.controlView.width
        let rectH = frameView.controlView.height * scale
        var rectY: CGFloat = 0
        if rectH < containerView.height {
            rectY = (containerView.height - rectH) * 0.5
        }
        let maskRect = CGRect(x: 0, y: rectY, width: rectW, height: rectH)
        let zoomScale = scrollView.zoomScale * scale
        if zoomScale > scrollView.maximumZoomScale {
            scrollView.maximumZoomScale = zoomScale
        }
        if maskImage == nil {
            frameView.hideCustomMaskView(animated)
        }else {
            frameView.hideImageMaskView(animated)
        }
        contentView.stickerView.angle = oldAdjustedFactor?.angle ?? 0
        updateFrameView(
            maskRect: maskRect,
            zoomScale: zoomScale,
            animated: animated
        ) { [weak self] in
            if !$0 { return }
            completion?()
            guard let self = self else { return }
            self.delegate?.editorAdjusterView(editDidDisappear: self)
            self.clipsToBounds = true
            self.frameView.hideVideoSilder(true)
            if let oldAdjustedFactor = self.oldAdjustedFactor {
                self.contentView.stickerMirrorScale = .init(
                    x: oldAdjustedFactor.mirrorTransform.a,
                    y: oldAdjustedFactor.mirrorTransform.d
                )
            }else {
                self.contentView.stickerMirrorScale = .init(x: 1, y: 1)
            }
        }
    }
    
    func cancelEdit(
        _ animated: Bool,
        completion: (() -> Void)? = nil
    ) {
        frameView.stopTimer()
        delegate?.editorAdjusterView(editWillDisappear: self)
        endEdit()
        if let oldFactor = oldRatioFactor {
            isFixedRatio = oldFactor.fixedRatio
            frameView.aspectRatio = oldFactor.aspectRatio
        }else {
            isFixedRatio = false
        }
        if let oldMaskImage = oldMaskImage {
            setMaskImage(oldMaskImage, animated: animated)
        }else {
            setMaskImage(nil, animated: animated)
            frameView.hideCustomMaskView(animated)
        }
        if oldIsRound {
            setRoundCrop(isRound: true, animated: animated)
        }
        if let oldAdjustedData = oldAdjustedFactor {
            frameView.show(false)
            adjustedFactor = oldAdjustedData
            setScrollViewTransform(
                transform: oldAdjustedData.transform,
                rotateTransform: oldAdjustedData.rotateTransform,
                angle: oldAdjustedData.angle,
                animated: false
            )
            setMirrorTransform(transform: oldAdjustedData.mirrorTransform)
            updateMaskRect(to: oldAdjustedData.maskRect, animated: false)
            scrollView.minimumZoomScale = getScrollViewMinimumZoomScale(oldAdjustedData.maskRect)
            scrollView.contentInset = oldAdjustedData.contentInset
            scrollView.zoomScale = oldAdjustedData.zoomScale
            scrollView.contentOffset = oldAdjustedData.contentOffset
            // 计算裁剪框的位置
            let maxWidth = containerView.width
            let rectW = maxWidth
            let scale = maxWidth / frameView.controlView.width
            let rectH = oldAdjustedData.maskRect.height * scale
            var rectY: CGFloat = 0
            if rectH < containerView.height {
                rectY = (containerView.height - rectH) * 0.5
            }
            let maskRect = CGRect(x: 0, y: rectY, width: rectW, height: rectH)
            let zoomScale = scrollView.zoomScale * scale
            if zoomScale > scrollView.maximumZoomScale {
                scrollView.maximumZoomScale = zoomScale
            }
            frameView.hideImageMaskView(animated)
            updateFrameView(
                maskRect: maskRect,
                zoomScale: zoomScale,
                animated: animated
            ) { [weak self] in
                if !$0 { return }
                completion?()
                self?.clipsToBounds = true
                self?.frameView.hideVideoSilder(true)
                self?.contentView.stickerView.resetMirror()
            }
            return
        }
        clipsToBounds = false
        adjustedFactor = .init()
        let maskRect = getContentBaseFrame()
        updateMaskRect(to: maskRect, animated: animated)
        frameView.hide(animated: animated)
        frameView.hideVideoSilder(animated)
        scrollView.minimumZoomScale = 1
        let scrollViewContentInset = getScrollViewContentInset(maskRect, true)
        let offset =  CGPoint(x: -scrollViewContentInset.left, y: -scrollViewContentInset.top)
        updateScrollViewContent(
            contentInset: nil,
            zoomScale: 1,
            contentOffset: offset,
            animated: animated,
            resetAngle: true,
            isCancel: true
        ) { [weak self] in
            guard let self = self else { return }
            if !$0 { return }
            completion?()
            self.delegate?.editorAdjusterView(editDidDisappear: self)
            self.frameView.hideVideoSilder(true)
            self.contentView.stickerView.resetMirror()
        }
    }
    
    func getCurrentAdjusted() -> (AdjustedFactor?, CGSize) {
        if state != .edit {
            return (oldAdjustedFactor, editSize)
        }
        
        let fromSize = getExactnessSize(contentView.size)
        let toSize = getExactnessSize(frameView.controlView.size)
        
        let isEqualSize = (
            !fromSize.equalTo(toSize)
            ||
            (fromSize.equalTo(toSize) &&
             frameView.isRoundCrop
            )
        )
        var cAdjustmentData: AdjustedFactor?
        if canReset || (!canReset && isEqualSize ) {
            // 调整裁剪框至中心
            adjustmentViews(false)
            
            let contentInset = scrollView.contentInset
            let contentSize = scrollView.contentSize
            let contentOffset = scrollView.contentOffset
            
            var oldData = AdjustedFactor()
            // 记录当前数据
            oldData.zoomScale = scrollView.zoomScale
            oldData.contentOffset = contentOffset
            oldData.contentInset = contentInset
            oldData.maskRect = frameView.controlView.frame
            oldData.angle = adjustedFactor.angle
            oldData.mirrorTransform = adjustedFactor.mirrorTransform
            oldData.transform = scrollView.transform
            oldData.rotateTransform = rotateView.transform
            
            let offsetXScale = (contentOffset.x + contentInset.left) / contentSize.width
            let offsetYScale = (contentOffset.y + contentInset.top) / contentSize.height
            oldData.contentOffsetScale = .init(x: offsetXScale, y: offsetYScale)
            oldData.min_zoom_scale = scrollView.zoomScale / getScrollViewMinimumZoomScale(oldData.maskRect)
            oldData.isRoundMask = isRoundMask
            oldData.maskImage = adjustedFactor.maskImage
            
            cAdjustmentData = oldData
        }
        let maxWidth = containerView.width
        let rectW = maxWidth
        let scale = maxWidth / frameView.controlView.width
        let rectH = frameView.controlView.height * scale
        var rectY: CGFloat = 0
        if rectH < containerView.height {
            rectY = (containerView.height - rectH) * 0.5
        }
        let maskRect = CGRect(x: 0, y: rectY, width: rectW, height: rectH)
        return (cAdjustmentData, maskRect.size)
    }
}

extension EditorAdjusterView {
    var canReset: Bool {
        let isUpDirection = adjustedFactor.angle.truncatingRemainder(dividingBy: 360) == 0
        let isIdentityMirror = adjustedFactor.mirrorTransform == .identity
        if !isUpDirection || !isIdentityMirror {
            return true
        }
        if frameView.controlView.size.equalTo(.zero) {
            // 裁剪框大小还未初始化时
            return false
        }
        if isFixedRatio && !isResetIgnoreFixedRatio {
            if initialRoundMask, !isRoundMask {
                return true
            }
            // 开启了固定比例
            let zoomScale = initialZoomScale
            let maskViewFrame = getMaskRect(true)
            let scrollViewContentInset = getScrollViewContentInset(maskViewFrame)
            var offset =  CGPoint(x: -scrollViewContentInset.left, y: -scrollViewContentInset.top)
            if !isOriginalRatio {
                // 不是原始比例,需要判断中心点
                let leftMargin = baseContentSize.width * zoomScale * 0.5 - maskViewFrame.width * 0.5
                let rightMargin = baseContentSize.height * zoomScale * 0.5 - maskViewFrame.height * 0.5
                offset = CGPoint(
                    x: -scrollViewContentInset.left + leftMargin,
                    y: -scrollViewContentInset.top + rightMargin
                )
            }
            let currentOffset = scrollView.contentOffset
            // 允许0.18以内的误差
            let difference = max(
                fabsf(Float(currentOffset.x - offset.x)),
                fabsf(Float(currentOffset.y - offset.y))
            )
            let zoomScaleDifference = fabsf(Float(scrollView.zoomScale - zoomScale))
            let controlFrame = frameView.controlView.frame
            var frameIsEqual = true
            if abs(controlFrame.minX - maskViewFrame.minX) > 0.00001 {
                frameIsEqual = false
            }
            if abs(controlFrame.minY - maskViewFrame.minY) > 0.00001 {
                frameIsEqual = false
            }
            if abs(controlFrame.width - maskViewFrame.width) > 0.00001 {
                frameIsEqual = false
            }
            if abs(controlFrame.height - maskViewFrame.height) > 0.00001 {
                frameIsEqual = false
            }
            let allowDifference: Float
            if UIDevice.isPad {
                /// iPad上允许0.22以内的误差
                allowDifference = 0.22
            }else {
                /// iPhone上允许0.18以内的误差
                allowDifference = 0.18
            }
            if zoomScaleDifference > 0.0000001 ||
                !frameIsEqual ||
                difference > allowDifference {
                /// 缩放大小不一致、裁剪框位置大小不一致、不在中心点位置、角度不为0都可以还原
                return true
            }
            return false
        }
        let fromSize = getExactnessSize(contentView.size)
        let toSize = getExactnessSize(frameView.controlView.size)
        return !fromSize.equalTo(toSize)
    }
    
    func reset(_ animated: Bool, completion: (() -> Void)? = nil) {
        if !canReset {
            completion?()
            return
        }
        delegate?.editorAdjusterView(willBeginEditing: self)
        stopTimer()
        if isResetIgnoreFixedRatio {
            isFixedRatio = false
            if isRoundMask {
                setRoundCrop(isRound: false, animated: animated)
            }
        }else {
            if !isFixedRatio {
                frameView.aspectRatio = .zero
            }else {
                if initialRoundMask, !isRoundMask {
                    frameView.aspectRatio = .init(width: 1, height: 1)
                    setRoundCrop(isRound: true, animated: animated)
                }
            }
        }
        let mask_Image = adjustedFactor.maskImage
        adjustedFactor = .init()
        adjustedFactor.maskImage = mask_Image
        // 初始的缩放比例
        let zoomScale = initialZoomScale
        let minimumZoomScale = zoomScale
        scrollView.minimumZoomScale = minimumZoomScale
        scrollView.maximumZoomScale = maximumZoomScale
        // 获取遮罩位置大小
        let maskViewFrame = getMaskRect(true)
        updateMaskRect(to: maskViewFrame, animated: animated)
        // 获取原始的contentInset
        let scrollViewContentInset = getScrollViewContentInset(maskViewFrame, true)
        var offset =  CGPoint(x: -scrollViewContentInset.left, y: -scrollViewContentInset.top)
        if !isOriginalRatio {
            offset = CGPoint(
                x: -scrollViewContentInset.left +
                    (
                        baseContentSize.width * zoomScale * 0.5 - maskViewFrame.width * 0.5
                    ),
                y: -scrollViewContentInset.top +
                    (
                        baseContentSize.height * zoomScale * 0.5 - maskViewFrame.height * 0.5
                    )
            )
        }
        contentView.stickerView.initialMirror(.init(x: mirrorView.transform.a, y: mirrorView.transform.d))
        updateScrollViewContent(
            contentInset: scrollViewContentInset,
            zoomScale: zoomScale,
            contentOffset: offset,
            animated: animated,
            resetAngle: true
        ) { [weak self] in
            guard let self = self else { return }
            if !$0 { return }
            self.changedMaskRectCompletion(animated)
            completion?()
        }
    }
}

extension EditorAdjusterView {
    
    func endEdit() {
        state = .normal
        resetState()
        frameView.hideLinesShadow()
        frameView.hideGridlinesLayer()
        frameView.isControlEnable = false
    }
    
    func setupEdit(maskRect: CGRect) {
        let zoomScale = oldAdjustedFactor?.zoomScale ?? initialZoomScale
        scrollView.zoomScale = zoomScale
        if let oldAdjustedData = oldAdjustedFactor {
            scrollView.contentInset = oldAdjustedData.contentInset
            scrollView.contentOffset = getZoomOffset(
                oldAdjustedData.contentOffset,
                oldAdjustedData.contentInset
            )
        }else {
            if !isOriginalRatio {
                let rect = getControlInRotateRect(maskRect)
                let offset = CGPoint(
                    x: -scrollView.contentInset.left +
                        (
                        contentView.width * 0.5 - rect.width * 0.5
                        ),
                    y: -scrollView.contentInset.top +
                        (
                        contentView.height * 0.5 - rect.height * 0.5
                        )
                )
                self.scrollView.contentOffset = offset
            }
        }
    }
    
    func updateFrameView(
        maskRect: CGRect,
        zoomScale: CGFloat,
        animated: Bool,
        completion: ((Bool) -> Void)?
    ) {
        editSize = maskRect.size
        let controlBeforeRect = getControlInContentRect()
        updateMaskRect(to: maskRect, animated: animated)
        frameView.hide(isMaskBg: false, animated: animated)
        frameView.hideVideoSilder(animated)
        func animatedAction() {
            setScrollViewContentInset(maskRect)
            scrollView.zoomScale = zoomScale
            scrollView.contentOffset = getEndZoomOffset(
                fromRect: controlBeforeRect,
                zoomScale: zoomScale
            )
        }
        frameView.blackMask(isShow: true, animated: animated)
        if animated {
            UIView.animate {
                animatedAction()
            } completion: {
                completion?($0)
            }
        }else {
            animatedAction()
            completion?(true)
        }
    }
    
    func getEndZoomOffset(
        fromRect: CGRect,
        zoomScale: CGFloat
    ) -> CGPoint {
        let offsetX = fromRect.minX * zoomScale - scrollView.contentInset.left
        let offsetY = fromRect.minY * zoomScale - scrollView.contentInset.top
        return CGPoint(x: offsetX, y: offsetY)
    }
    
    func updateScrollViewContent(
        contentInset: UIEdgeInsets?,
        zoomScale: CGFloat,
        contentOffset: CGPoint,
        animated: Bool,
        resetAngle: Bool = false,
        isCancel: Bool = false,
        completion: ((Bool) -> Void)? = nil
    ) {
        func animatedAction() {
            if resetAngle {
                setScrollViewTransform()
                if let mirrorTransform = oldAdjustedFactor?.mirrorTransform, isCancel {
                    mirrorView.transform = mirrorTransform
                }else {
                    mirrorView.transform = .identity
                }
            }
            if let contentInset = contentInset {
                scrollView.contentInset = contentInset
            }
            scrollView.zoomScale = zoomScale
            scrollView.contentOffset = contentOffset
        }
        if animated {
            UIView.animate {
                animatedAction()
            } completion: { (isFinished) in
                completion?(isFinished)
            }
        }else {
            animatedAction()
            completion?(true)
        }
    }
    
    func stopTimer() {
        // 停止定时器
        frameView.stopTimer()
        // 停止滑动
        scrollView.setContentOffset(scrollView.contentOffset, animated: false)
    }
     
    func changedMaskRectCompletion(_ animated: Bool) {
        delegate?.editorAdjusterView(didEndEditing: self)
        if frameView.maskBgShowTimer == nil &&
            frameView.maskBgViewIsHidden {
            frameView.showMaskBgView(animated: animated)
        }
    }
}
