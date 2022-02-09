//
//  EditorImageResizerView+Cropping.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/25.
//

import UIKit

extension EditorImageResizerView {
    
    func startCropTime(_ animated: Bool) {
        state = .cropping
        updateContentInsets(true)
        let margin: CGFloat = UIDevice.isPortrait ? 30 : 15
//        resetOther()
        if hasCropping {
            mirrorType = oldMirrorType
            currentAngle = oldAngle
            if !isFixedRatio {
                controlView.fixedRatio = false
            }
            // 之前有裁剪记录
            maskBgView.alpha = 1
            maskBgView.isHidden = false
            maskBgView.updateBlackMask(isShow: true, animated: false, completion: nil)
        }else {
            currentAngle = 0
            /// 之前没有裁剪记录时，需要清除上一次设置的宽高比
            if !isFixedRatio {
                // 没有固定比例，重新设置的默认比例
                controlViewAspectRatio()
                checkOriginalRatio()
                controlView.fixedRatio = false
                currentAspectRatio = controlView.aspectRatio
            }else {
                cropTime_IsOriginalRatio = isOriginalRatio
                cropTime_FixedRatio = controlView.fixedRatio
                cropTime_AspectRatio = controlView.aspectRatio
                controlView.fixedRatio = false
                controlView.aspectRatio = .zero
                currentAspectRatio = .zero
                isOriginalRatio = true
            }
        }
        clipsToBounds = false
//        controlView.isUserInteractionEnabled = true
        /// 获取初始缩放比例
        let zoomScale = hasCropping ? oldZoomScale : getInitialZoomScale()
        /// 最小缩放比例
        let minimumZoomScale = hasCropping ? oldMinimumZoomScale : zoomScale
        scrollView.minimumZoomScale = minimumZoomScale
        scrollView.maximumZoomScale = hasCropping ? oldMaximumZoomScale : 20
        /// 获取裁剪框位置发小
        let maskViewFrame = hasCropping ?
            CGRect(origin: .init(x: oldMaskRect.minX, y: oldMaskRect.minY - margin),
                   size: oldMaskRect.size) :
            getMaskViewFrame()
        /// 更新裁剪框
        updateMaskViewFrame(to: maskViewFrame, animated: animated)
        if animated {
            UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseOut) {
                if self.hasCropping {
                    self.scrollView.contentInset = UIEdgeInsets(
                        top: self.oldContentInset.top - margin,
                        left: self.oldContentInset.left,
                        bottom: self.oldContentInset.bottom + margin,
                        right: self.oldContentInset.right
                    )
                }
                self.scrollView.zoomScale = zoomScale
                if self.hasCropping {
                    self.scrollView.contentOffset = self.checkZoomOffset(
                        .init(x: self.oldContentOffset.x, y: self.oldContentOffset.y + margin),
                        self.scrollView.contentInset
                    )
                }else {
                    if !self.isOriginalRatio {
                        let offset = CGPoint(
                            x: -self.scrollView.contentInset.left +
                                (
                                self.imageView.width * 0.5 - maskViewFrame.width * 0.5
                                ),
                            y: -self.scrollView.contentInset.top +
                                (
                                self.imageView.height * 0.5 - maskViewFrame.height * 0.5
                                )
                        )
                        self.scrollView.contentOffset = offset
                    }
                }
            }
        }else {
            if hasCropping {
                scrollView.contentInset = UIEdgeInsets(
                    top: oldContentInset.top - margin,
                    left: oldContentInset.left,
                    bottom: oldContentInset.bottom + margin,
                    right: oldContentInset.right
                )
            }
            scrollView.zoomScale = zoomScale
            if hasCropping {
                scrollView.contentOffset = checkZoomOffset(
                    .init(x: oldContentOffset.x, y: oldContentOffset.y + margin),
                    scrollView.contentInset
                )
            }else {
                if !isOriginalRatio {
                    let offset = CGPoint(
                        x: -scrollView.contentInset.left +
                            (
                                imageView.width * 0.5 - maskViewFrame.width * 0.5
                            ),
                        y: -scrollView.contentInset.top + (
                            imageView.height * 0.5 - maskViewFrame.height * 0.5
                        )
                    )
                    scrollView.contentOffset = offset
                }
            }
        }
    }
    
    func cancelCropTime(_ animated: Bool) {
        state = .normal
        resetOther()
        if isFixedRatio && !hasCropping {
            isOriginalRatio = cropTime_IsOriginalRatio
            controlView.fixedRatio = cropTime_FixedRatio
            controlView.aspectRatio = cropTime_AspectRatio
            currentAspectRatio = cropTime_AspectRatio
        }
        if hasCropping {
            scrollView.minimumZoomScale = getScrollViewMinimumZoomScale(oldMaskRect)
            // 计算裁剪框的位置
            let maxWidth = containerView.width
            let rectW = maxWidth
            let scale = maxWidth / controlView.width
            let rectH = oldMaskRect.height * scale
            var rectY: CGFloat = 0
            if rectH < containerView.height {
                rectY = (containerView.height - rectH) * 0.5
            }
            let maskRect = CGRect(x: 0, y: rectY, width: rectW, height: rectH)
            let zoomScale = scrollView.zoomScale * scale
            if zoomScale > scrollView.maximumZoomScale {
                scrollView.maximumZoomScale = zoomScale
            }
            // 更新
            updateCropRect(maskRect: maskRect, zoomScale: zoomScale, animated: animated) { [weak self] () in
                self?.clipsToBounds = true
            }
        }else {
            /// 还原到初始状态
            clipsToBounds = false
            currentAngle = 0
            mirrorType = .none
            let maskRect = getMaskRect()
            updateMaskViewFrame(to: maskRect, animated: animated)
            hiddenMaskView(cropConfig.isRoundCrop ? false : animated)
            scrollView.minimumZoomScale = 1
            let scrollViewContentInset = getScrollViewContentInset(maskRect)
            let offset =  CGPoint(x: -scrollViewContentInset.left, y: -scrollViewContentInset.top)
            updateScrollViewContent(
                contentInset: nil,
                zoomScale: 1,
                contentOffset: offset,
                animated: animated,
                resetAngle: true
            ) {
            }
        }
        updateContentInsets(false)
    }
    
    /// 开始裁剪
    func startCorpping(_ animated: Bool, completion: (() -> Void)?) {
        state = .cropping
        resetOther()
        if hasCropping {
            mirrorType = oldMirrorType
            currentAngle = oldAngle
            if !isFixedRatio {
                controlView.fixedRatio = false
            }
            // 之前有裁剪记录
            maskBgView.alpha = 1
            maskBgView.isHidden = false
            maskBgView.updateBlackMask(isShow: true, animated: false, completion: nil)
        }else {
            currentAngle = 0
            /// 之前没有裁剪记录时，需要清除上一次设置的宽高比
            if !isFixedRatio {
                // 没有固定比例，重新设置的默认比例
                controlViewAspectRatio()
                checkOriginalRatio()
                controlView.fixedRatio = false
                currentAspectRatio = controlView.aspectRatio
            }
        }
        clipsToBounds = false
        controlView.isUserInteractionEnabled = true
        /// 获取初始缩放比例
        let zoomScale = hasCropping ? oldZoomScale : getInitialZoomScale()
        /// 最小缩放比例
        let minimumZoomScale = hasCropping ? oldMinimumZoomScale : zoomScale
        scrollView.minimumZoomScale = minimumZoomScale
        scrollView.maximumZoomScale = hasCropping ? oldMaximumZoomScale : 20
        /// 获取裁剪框位置发小
        let maskViewFrame = hasCropping ? oldMaskRect : getMaskViewFrame()
        /// 更新裁剪框
        updateMaskViewFrame(to: maskViewFrame, animated: animated)
        if animated {
            UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseOut) {
                if self.hasCropping {
                    self.scrollView.contentInset = self.oldContentInset
                }
                self.scrollView.zoomScale = zoomScale
                if self.hasCropping {
                    self.scrollView.contentOffset = self.checkZoomOffset(
                        self.oldContentOffset,
                        self.scrollView.contentInset
                    )
                }else {
                    if !self.isOriginalRatio {
                        let offset = CGPoint(
                            x: -self.scrollView.contentInset.left +
                                (
                                self.imageView.width * 0.5 - maskViewFrame.width * 0.5
                                ),
                            y: -self.scrollView.contentInset.top +
                                (
                                self.imageView.height * 0.5 - maskViewFrame.height * 0.5
                                )
                        )
                        self.scrollView.contentOffset = offset
                    }
                }
            } completion: { (isFinished) in
                self.maskBgView.updateBlackMask(isShow: false, animated: animated, completion: nil)
                self.showMaskView(animated)
                self.maskLinesView.showShadow(true)
                completion?()
            }
        }else {
            if hasCropping {
                scrollView.contentInset = oldContentInset
            }
            scrollView.zoomScale = zoomScale
            if hasCropping {
                scrollView.contentOffset = checkZoomOffset(oldContentOffset, oldContentInset)
            }else {
                if !isOriginalRatio {
                    let offset = CGPoint(
                        x: -scrollView.contentInset.left +
                            (
                                imageView.width * 0.5 - maskViewFrame.width * 0.5
                            ),
                        y: -scrollView.contentInset.top + (
                            imageView.height * 0.5 - maskViewFrame.height * 0.5
                        )
                    )
                    scrollView.contentOffset = offset
                }
            }
            maskBgView.updateBlackMask(isShow: false, animated: animated, completion: nil)
            showMaskView(animated)
            maskLinesView.showShadow(true)
            completion?()
        }
    }
    /// 完成裁剪
    func finishCropping(_ animated: Bool, completion: (() -> Void)?, updateCrop: Bool = true) {
        state = .normal
        resetOther()
        maskLinesView.showShadow(false)
        maskLinesView.showGridlinesLayer(false)
        controlView.isUserInteractionEnabled = false
        let fromSize = getExactnessSize(imageView.size)
        let toSize = getExactnessSize(controlView.size)
        let can_Reset = canReset()
        
        let isEqualSize = (!fromSize.equalTo(toSize) || (fromSize.equalTo(toSize) && cropConfig.isRoundCrop))
        if can_Reset || (!can_Reset && isEqualSize ) {
            // 调整裁剪框至中心
            adjustmentViews(false, showMaskShadow: false)
            hasCropping = true
            // 记录当前数据
            oldZoomScale = scrollView.zoomScale
            oldContentOffset = scrollView.contentOffset
            oldContentInset = scrollView.contentInset
            oldMinimumZoomScale = scrollView.minimumZoomScale
            oldMaximumZoomScale = scrollView.maximumZoomScale
            oldMaskRect = controlView.frame
            oldAngle = currentAngle
            oldMirrorType = mirrorType
            oldTransform = scrollView.transform
        }else {
            oldTransform = .identity
            hasCropping = false
        }
        if !updateCrop {
            return
        }
        // 计算裁剪框的位置
        let maxWidth = containerView.width
        let rectW = maxWidth
        let scale = maxWidth / controlView.width
        let rectH = controlView.height * scale
        var rectY: CGFloat = 0
        if rectH < containerView.height {
            rectY = (containerView.height - rectH) * 0.5
        }
        let maskRect = CGRect(x: 0, y: rectY, width: rectW, height: rectH)
        let zoomScale = scrollView.zoomScale * scale
        if zoomScale > scrollView.maximumZoomScale {
            scrollView.maximumZoomScale = zoomScale
        }
        // 更新
        updateCropRect(maskRect: maskRect, zoomScale: zoomScale, animated: animated) { [weak self] () in
            completion?()
            self?.clipsToBounds = true
        }
    }
    // 更新裁剪框大小，scrolView显示范围
    func updateCropRect(maskRect: CGRect, zoomScale: CGFloat, animated: Bool, completion: (() -> Void)?) {
        cropSize = maskRect.size
        let controlBeforeRect = maskBgView.convert(controlView.frame, to: imageView)
        updateMaskViewFrame(to: maskRect, animated: animated)
        hiddenMaskView(animated, onlyLines: true)
        maskBgView.updateBlackMask(isShow: true, animated: false, completion: nil)
        
        let scrollCotentInset = getScrollViewContentInset(maskRect)
        if animated {
            UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseOut) {
                self.updateScrollViewContentInset(maskRect)
                self.scrollView.zoomScale = zoomScale
                self.scrollView.contentOffset = self.getZoomOffset(
                    fromRect: controlBeforeRect,
                    zoomScale: zoomScale,
                    scrollCotentInset: scrollCotentInset
                )
            } completion: { (_) in
                completion?()
                self.maskBgView.updateBlackMask(
                    isShow: false,
                    animated: false,
                    completion: nil
                )
                self.maskBgView.isHidden = true
                self.maskBgView.alpha = 0
            }
        }else {
            updateScrollViewContentInset(maskRect)
            scrollView.zoomScale = zoomScale
            scrollView.contentOffset = getZoomOffset(
                fromRect: controlBeforeRect,
                zoomScale: zoomScale,
                scrollCotentInset: scrollCotentInset
            )
            completion?()
            maskBgView.updateBlackMask(
                isShow: false,
                animated: false,
                completion: nil
            )
            maskBgView.isHidden = true
            maskBgView.alpha = 0
        }
    }
    /// 取消裁剪
    func cancelCropping(canShowMask: Bool = true, _ animated: Bool, completion: (() -> Void)?) {
        state = .normal
        resetOther()
        maskLinesView.showShadow(false)
        maskLinesView.showGridlinesLayer(false)
        controlView.isUserInteractionEnabled = false
        if hasCropping {
            // 之前有裁剪记录，需要恢复到之前的状态
            if canShowMask {
                showMaskView(false)
            }
            currentAngle = oldAngle
            mirrorType = oldMirrorType
            resetScrollViewTransform(transform: oldTransform, angleInRadians: oldAngle, animated: false)
            updateMaskViewFrame(to: oldMaskRect, animated: false)
            scrollView.minimumZoomScale = getScrollViewMinimumZoomScale(oldMaskRect)
            scrollView.contentInset = oldContentInset
            scrollView.zoomScale = oldZoomScale
            scrollView.contentOffset = oldContentOffset
            // 计算裁剪框的位置
            let maxWidth = containerView.width
            let rectW = maxWidth
            let scale = maxWidth / controlView.width
            let rectH = oldMaskRect.height * scale
            var rectY: CGFloat = 0
            if rectH < containerView.height {
                rectY = (containerView.height - rectH) * 0.5
            }
            let maskRect = CGRect(x: 0, y: rectY, width: rectW, height: rectH)
            let zoomScale = scrollView.zoomScale * scale
            if zoomScale > scrollView.maximumZoomScale {
                scrollView.maximumZoomScale = zoomScale
            }
            // 更新
            updateCropRect(maskRect: maskRect, zoomScale: zoomScale, animated: animated) { [weak self] () in
                completion?()
                self?.clipsToBounds = true
            }
        }else {
            /// 还原到初始状态
            clipsToBounds = false
            currentAngle = 0
            mirrorType = .none
            let maskRect = getMaskRect()
            updateMaskViewFrame(to: maskRect, animated: animated)
            hiddenMaskView(cropConfig.isRoundCrop ? false : animated)
            scrollView.minimumZoomScale = 1
            let scrollViewContentInset = getScrollViewContentInset(maskRect)
            let offset =  CGPoint(x: -scrollViewContentInset.left, y: -scrollViewContentInset.top)
            updateScrollViewContent(
                contentInset: nil,
                zoomScale: 1,
                contentOffset: offset,
                animated: animated,
                resetAngle: true
            ) {
                completion?()
            }
        }
    }
    /// 还原重置
    func reset(_ animated: Bool) {
        delegate?.imageResizerView(willChangedMaskRect: self)
        // 停止定时器
        stopControlTimer()
        stopShowMaskBgTimer()
        inControlTimer = false
        // 停止滑动
        scrollView.setContentOffset(scrollView.contentOffset, animated: false)
        if !isFixedRatio {
            // 没有固定比例的时候重置需要还原原始比例
            controlView.fixedRatio = false
            controlView.aspectRatio = .zero
            currentAspectRatio = .zero
            isOriginalRatio = true
        }
        currentAngle = 0
        mirrorType = .none
        // 初始的缩放比例
        let zoomScale = getInitialZoomScale()
        let minimumZoomScale = zoomScale
        scrollView.minimumZoomScale = minimumZoomScale
        scrollView.maximumZoomScale = 20
        // 获取遮罩位置大小
        let maskViewFrame = getMaskViewFrame(true)
        updateMaskViewFrame(to: maskViewFrame, animated: animated)
        // 获取原始的contentInset
        let scrollViewContentInset = getScrollViewContentInset(maskViewFrame)
        var offset =  CGPoint(x: -scrollViewContentInset.left, y: -scrollViewContentInset.top)
        if !isOriginalRatio {
            // 如果不是原始比例，说明开启了固定比例，重置时需要将移动到中心点
            offset = CGPoint(
                x: -scrollViewContentInset.left +
                    (
                        baseImageSize.width * zoomScale * 0.5 - maskViewFrame.width * 0.5
                    ),
                y: -scrollViewContentInset.top +
                    (
                        baseImageSize.height * zoomScale * 0.5 - maskViewFrame.height * 0.5
                    )
            )
        }
        updateScrollViewContent(
            contentInset: scrollViewContentInset,
            zoomScale: zoomScale,
            contentOffset: offset,
            animated: animated,
            resetAngle: true
        ) { [weak self] in
            guard let self = self else { return }
            self.delegate?.imageResizerView(didEndChangedMaskRect: self)
            if self.maskBgShowTimer == nil &&
                self.maskBgView.alpha == 0 {
                self.showMaskBgView()
            }
        }
    }
    /// 是否可以还原重置
    func canReset() -> Bool {
        if currentAngle != 0 || mirrorType != .none {
            return true
        }
        if controlView.size.equalTo(.zero) {
            // 裁剪框大小还未初始化时
            return false
        }
        if isFixedRatio {
            // 开启了固定比例
            let zoomScale = getInitialZoomScale()
            let maskViewFrame = getMaskViewFrame(true)
            let scrollViewContentInset = getScrollViewContentInset(maskViewFrame)
            var offset =  CGPoint(x: -scrollViewContentInset.left, y: -scrollViewContentInset.top)
            if !isOriginalRatio {
                // 不是原始比例,需要判断中心点
                let leftMargin = baseImageSize.width * zoomScale * 0.5 - maskViewFrame.width * 0.5
                let rightMargin = baseImageSize.height * zoomScale * 0.5 - maskViewFrame.height * 0.5
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
            if zoomScaleDifference > 0.0000001 ||
                !controlView.frame.equalTo(maskViewFrame) ||
                difference > 0.18 {
                /// 缩放大小不一致、裁剪框位置大小不一致、不在中心点位置、角度不为0都可以还原
                return true
            }
            return false
        }
        let fromSize = getExactnessSize(imageView.size)
        let toSize = getExactnessSize(controlView.size)
        return !fromSize.equalTo(toSize)
    }
    
    /// 旋转
    func rotate(_ isClock_wise: Bool = false) {
        if mirroring {
            return
        }
        rotating = true
        var isClockwise = isClock_wise
        // 停止定时器
        stopControlTimer()
        stopShowMaskBgTimer()
        inControlTimer = false
        // 停止滑动
        scrollView.setContentOffset(scrollView.contentOffset, animated: false)
        if mirrorType == .horizontal {
            isClockwise = true
        }
        var newAngle = isClockwise ? currentAngle + 90 : currentAngle - 90
        if newAngle >= 360 || newAngle <= -360 {
            newAngle = 0
        }
        currentAngle = newAngle
        let angleInRadians = getAngleInRadians()
        delegate?.imageResizerView(willChangedMaskRect: self)
        let beforeZoomScale = scrollView.zoomScale / scrollView.minimumZoomScale
        // 获取当前裁剪框位置大小
        let controlBeforeRect = maskBgView.convert(controlView.frame, to: imageView)
        if !controlView.fixedRatio {
            let maxWidth = containerView.width - contentInsets.left - contentInsets.right
            let maxHeight = containerView.height - contentInsets.top - contentInsets.bottom
            var maskWidth = maxWidth
            var maskHeight = controlView.width * (maxWidth / controlView.height)
            if maskHeight > maxHeight {
                maskWidth = maskWidth * (maxHeight / maskHeight)
                maskHeight = maxHeight
            }
            let maskRect = CGRect(
                x: contentInsets.left + (maxWidth - maskWidth) * 0.5,
                y: contentInsets.top + (maxHeight - maskHeight) * 0.5,
                width: maskWidth,
                height: maskHeight
            )
            updateMaskViewFrame(to: maskRect, animated: true)
        }
        UIView.animate(withDuration: animationDuration, delay: 0, options: [.curveEaseOut]) {
            self.rotateHandler(
                angleInRadians: angleInRadians,
                beforeZoomScale: beforeZoomScale,
                controlBeforeRect: controlBeforeRect
            )
        } completion: { (isFinished) in
            self.changedMaskRectCompletion()
            self.rotating = false
        }
    }
    func rotateHandler(
        angleInRadians: CGFloat,
        beforeZoomScale: CGFloat,
        controlBeforeRect: CGRect
    ) {
        resetScrollViewTransform(angleInRadians: angleInRadians)
        updateScrollViewContentInset(controlView.frame)
        let zoomScale = getScrollViewMinimumZoomScale(controlView.frame)
        scrollView.minimumZoomScale = zoomScale
        scrollView.zoomScale = zoomScale * beforeZoomScale
        
        let controlAfterRect = maskBgView.convert(controlView.frame, to: imageView)
        
        var offsetX = controlBeforeRect.midX * scrollView.zoomScale - scrollView.contentInset.left
        var offsetY = controlBeforeRect.midY * scrollView.zoomScale - scrollView.contentInset.top
        offsetX -= controlAfterRect.width * 0.5 * scrollView.zoomScale
        offsetY -= controlAfterRect.height * 0.5 * scrollView.zoomScale
        scrollView.contentOffset = checkZoomOffset(
            CGPoint(x: offsetX, y: offsetY),
            scrollView.contentInset
        )
    }
    func resetScrollViewTransform(
        transform: CGAffineTransform? = nil,
        angleInRadians: CGFloat = 0,
        animated: Bool = false
    ) {
        let scrollViewFrame = scrollView.frame
        var rotateTransform: CGAffineTransform
        if let transform = transform {
            rotateTransform = transform
        }else {
            var identityTransForm = CGAffineTransform.identity
            if mirrorType == .horizontal {
                identityTransForm = identityTransForm.scaledBy(x: -1, y: 1)
            }
            rotateTransform = angleInRadians == 0 ? identityTransForm : identityTransForm.rotated(by: angleInRadians)
        }
        if animated {
            UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseOut) {
                self.scrollView.transform = rotateTransform
                self.scrollView.frame = scrollViewFrame
            }
        }else {
            scrollView.transform = rotateTransform
            scrollView.frame = scrollViewFrame
        }
    }
    func mirrorHorizontally(animated: Bool) {
        if rotating {
            return
        }
        mirroring = true
        delegate?.imageResizerView(willChangedMaskRect: self)
        if animated {
            UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseOut) {
                self.mirrorHorizontallyHandler()
            } completion: { (_) in
                self.changedMaskRectCompletion()
                self.mirroring = false
            }
        }else {
            mirrorHorizontallyHandler()
            changedMaskRectCompletion()
            mirroring = false
        }
    }
    func mirrorHorizontallyHandler() {
        let angleInRadians = getAngleInRadians()
        let rotateTransform = CGAffineTransform.identity.rotated(by: angleInRadians)
        if mirrorType == .none {
            mirrorType = .horizontal
            switch currentAngle {
            case -90, 270:
                scrollView.transform = rotateTransform.scaledBy(x: 1, y: -1)
            case -180, 180:
                scrollView.transform = rotateTransform.scaledBy(x: -1, y: 1)
            case -270, 90:
                scrollView.transform = CGAffineTransform.identity.rotated(by: -CGFloat.pi * 0.5).scaledBy(x: -1, y: 1)
            default:
                scrollView.transform = rotateTransform.scaledBy(x: -1, y: 1)
            }
        }else {
            mirrorType = .none
            switch currentAngle {
            case 90, -270:
                scrollView.transform = CGAffineTransform.identity.rotated(by: -(CGFloat.pi + CGFloat.pi * 0.5))
            case -180, 180:
                scrollView.transform = rotateTransform.scaledBy(x: 1, y: 1)
            case 270, -90:
                scrollView.transform = CGAffineTransform(rotationAngle: -CGFloat.pi * 0.5).scaledBy(x: 1, y: 1)
            default:
                scrollView.transform = rotateTransform.scaledBy(x: 1, y: 1)
            }
        }
    }
    /// 更新scrollView的显示内容
    func updateScrollViewContent(
        contentInset: UIEdgeInsets?,
        zoomScale: CGFloat,
        contentOffset: CGPoint,
        animated: Bool,
        resetAngle: Bool = false,
        completion: (() -> Void)? = nil
    ) {
        if animated {
            UIView.animate(
                withDuration: animationDuration,
                delay: 0,
                options: .curveEaseOut
            ) {
                if resetAngle {
                    self.resetScrollViewTransform()
                }
                if let contentInset = contentInset {
                    self.scrollView.contentInset = contentInset
                }
                self.scrollView.zoomScale = zoomScale
                self.scrollView.contentOffset = contentOffset
            } completion: { (isFinished) in
                completion?()
            }
        }else {
            if resetAngle {
                resetScrollViewTransform()
            }
            if let contentInset = contentInset {
                scrollView.contentInset = contentInset
            }
            scrollView.zoomScale = zoomScale
            scrollView.contentOffset = contentOffset
            completion?()
        }
    }
    
    /// 更新scrollView,停止定时器
    func resetOther() {
        updateScrollView()
        stopControlTimer()
        stopShowMaskBgTimer()
        inControlTimer = false
    }
}
