//
//  EditorImageResizerView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/3/19.
//

import UIKit
import AVFoundation
#if canImport(Kingfisher)
import Kingfisher
#endif

protocol EditorImageResizerViewDelegate: AnyObject {
    func imageResizerView(willChangedMaskRect imageResizerView: EditorImageResizerView)
    func imageResizerView(didEndChangedMaskRect imageResizerView: EditorImageResizerView)
    func imageResizerView(willBeginDragging imageResizerView: EditorImageResizerView)
    func imageResizerView(didEndDecelerating imageResizerView: EditorImageResizerView)
    func imageResizerView(WillBeginZooming imageResizerView: EditorImageResizerView)
    func imageResizerView(didEndZooming imageResizerView: EditorImageResizerView)
}

class EditorImageResizerView: UIView {
    
    enum ImageOrientation {
        case up
        case left
        case right
        case down
    }
    
    deinit {
//        print("deinit", self)
    }
    /// 裁剪配置
    var cropConfig: PhotoCroppingConfiguration
    weak var delegate: EditorImageResizerViewDelegate?
    lazy var containerView: UIView = {
        let containerView = UIView.init()
        containerView.addSubview(scrollView)
        updateScrollView()
        containerView.addSubview(maskBgView)
        containerView.addSubview(maskLinesView)
        containerView.addSubview(controlView)
        return containerView
    }()
    
    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView.init(frame: .zero)
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 20.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.clipsToBounds = false
        scrollView.scrollsToTop = false
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        scrollView.addSubview(imageView)
        return scrollView
    }()
    
    lazy var imageView: PhotoEditorContentView = {
        let imageView = PhotoEditorContentView.init()
        return imageView
    }()
    
    lazy var maskBgView: EditorImageResizerMaskView = {
        let maskBgView = EditorImageResizerMaskView.init(isMask: true, maskType: cropConfig.maskType)
        maskBgView.isRoundCrop = cropConfig.isRoundCrop
        maskBgView.alpha = 0
        maskBgView.isHidden = true
        maskBgView.isUserInteractionEnabled = false
        return maskBgView
    }()
    
    lazy var maskLinesView: EditorImageResizerMaskView = {
        let maskLinesView = EditorImageResizerMaskView.init(isMask: false)
        maskLinesView.isRoundCrop = cropConfig.isRoundCrop
        maskLinesView.isUserInteractionEnabled = false
        maskLinesView.alpha = 0
        maskLinesView.isHidden = true
        return maskLinesView
    }()
    lazy var controlView: EditorImageResizerControlView = {
        let controlView = EditorImageResizerControlView.init()
        controlView.isUserInteractionEnabled = false
        controlView.delegate = self
        return controlView
    }()
    /// 当前状态
    var state: PhotoEditorView.State = .normal
    /// 当前镜像类型
    var mirrorType: MirrorType = .none
    /// imageview原始宽高
    var baseImageSize: CGSize = .zero
    /// 图片宽高比例
    var imageScale: CGFloat = 1
    /// 裁剪框边距
    var contentInsets: UIEdgeInsets = .zero
    /// 裁剪框定时器
    var controlTimer: Timer?
    var maskBgViewisShowing: Bool = false
    var inControlTimer: Bool = false
    /// 遮罩定时器
    var maskBgShowTimer: Timer?
    /// 裁剪的大小
    var cropSize: CGSize = .zero
    /// 有裁剪记录
    var hasCropping: Bool = false
    
    /// 上一次裁剪数据
    var oldZoomScale: CGFloat = 0
    var oldContentOffset: CGPoint = .zero
    var oldContentInset: UIEdgeInsets = .zero
    var oldMinimumZoomScale: CGFloat = 0
    var oldMaximumZoomScale: CGFloat = 0
    var oldMaskRect: CGRect = .zero
    var oldAngle: CGFloat = 0
    var oldTransform: CGAffineTransform = .identity
    var oldMirrorType: MirrorType = .none
    
    /// 是否原始宽高比
    var isOriginalRatio: Bool = false
    /// 当前宽高比
    var currentAspectRatio: CGSize = .zero
    /// 是否固定比例
    var isFixedRatio: Bool = false
    var currentAngle: CGFloat = 0
    
    var rotating: Bool = false
    var mirroring: Bool = false
    
    init(cropConfig: PhotoCroppingConfiguration) {
        self.cropConfig = cropConfig
        super.init(frame: .zero)
        addSubview(containerView)
    }
    func getEditedData() -> PhotoEditData {
        var editedData = PhotoEditData.init()
        editedData.cropSize = cropSize
        editedData.zoomScale = oldZoomScale
        editedData.contentInset = oldContentInset
        editedData.minimumZoomScale = oldMinimumZoomScale
        editedData.maximumZoomScale = oldMaximumZoomScale
        editedData.maskRect = oldMaskRect
        editedData.angle = oldAngle
        editedData.mirrorType = oldMirrorType
        editedData.transform = oldTransform
        editedData.isPortrait = UIDevice.isPortrait
        let rect = maskBgView.convert(controlView.frame, to: imageView)
        
        editedData.offsetScale = CGPoint(x: rect.minX / baseImageSize.width, y: rect.minY / baseImageSize.height)
        return editedData
    }
    func setEditedData(editedData: PhotoEditData) {
        hasCropping = true
        // 记录当前数据
        oldAngle = editedData.angle
        oldMirrorType = editedData.mirrorType
        oldTransform = editedData.transform
//        let cropRect = AVMakeRect(aspectRatio: editedData.cropSize, insideRect: getEditableArea())
        cropSize = editedData.cropSize
        oldContentInset = editedData.contentInset
        let rect = AVMakeRect(aspectRatio: editedData.maskRect.size, insideRect: getEditableArea())
        let widthScale = rect.width / editedData.maskRect.width
        oldZoomScale = editedData.zoomScale * widthScale
        oldMinimumZoomScale = editedData.minimumZoomScale * widthScale
        oldMaximumZoomScale = editedData.maximumZoomScale * widthScale
        let scrollViewContentInset = getScrollViewContentInset(rect, true)
        let offsetX = baseImageSize.width * editedData.offsetScale.x * oldZoomScale - scrollViewContentInset.left
        let offsetY = baseImageSize.height * editedData.offsetScale.y * oldZoomScale - scrollViewContentInset.top
        oldContentOffset = CGPoint(x: offsetX, y: offsetY)
        oldMaskRect = rect
    }
    func getEditableArea() -> CGRect {
        let editWidth = containerView.width - contentInsets.left - contentInsets.right
        let editHeight = containerView.height - contentInsets.top - contentInsets.bottom
        let editX = contentInsets.left
        let editY = contentInsets.top
        return CGRect(x: editX, y: editY, width: editWidth, height: editHeight)
    }
    func setImage(_ image: UIImage) {
        updateContentInsets()
        imageScale = image.width / image.height
        imageView.setImage(image)
        configAspectRatio()
        updateScrollView()
        updateImageViewFrame(getImageViewFrame())
        /// 手势最大范围
        let maxControlRect = CGRect(x: contentInsets.left, y: contentInsets.top, width: containerView.width - contentInsets.left - contentInsets.right, height: containerView.height - contentInsets.top - contentInsets.bottom)
        controlView.maxImageresizerFrame = maxControlRect
    }
    /// 配置宽高比数据
    func configAspectRatio() {
        controlView.fixedRatio = cropConfig.fixedRatio
        controlViewAspectRatio()
        if cropConfig.isRoundCrop {
            controlView.fixedRatio = true
            controlView.aspectRatio = CGSize(width: 1, height: 1)
        }
        isFixedRatio = controlView.fixedRatio
        currentAspectRatio = controlView.aspectRatio
        checkOriginalRatio()
    }
    /// 裁剪框的宽高比
    func controlViewAspectRatio() {
        switch cropConfig.aspectRatioType {
        case .original:
            if cropConfig.fixedRatio {
                controlView.aspectRatio = imageView.image!.size
            }else {
                controlView.aspectRatio = .zero
            }
        case .ratio_1x1:
            controlView.aspectRatio = CGSize(width: 1, height: 1)
        case .ratio_2x3:
            controlView.aspectRatio = CGSize(width: 2, height: 3)
        case .ratio_3x2:
            controlView.aspectRatio = CGSize(width: 3, height: 2)
        case .ratio_3x4:
            controlView.aspectRatio = CGSize(width: 3, height: 4)
        case .ratio_4x3:
            controlView.aspectRatio = CGSize(width: 4, height: 3)
        case .ratio_9x16:
            controlView.aspectRatio = CGSize(width: 9, height: 16)
        case .ratio_16x9:
            controlView.aspectRatio = CGSize(width: 16, height: 9)
        case .custom(let aspectRatio):
            controlView.aspectRatio = aspectRatio
        }
    }
    /// 检测是否原始宽高比
    func checkOriginalRatio() {
        isOriginalRatio = false
        let aspectRatio = controlView.aspectRatio
        if aspectRatio.equalTo(.zero) {
            isOriginalRatio = true
        }else {
            if aspectRatio.width / aspectRatio.height == imageScale {
                isOriginalRatio = true
            }
        }
    }
    /// 获取当前宽高比下裁剪框的位置大小
    func getInitializationRatioMaskRect() -> CGRect{
        let maxWidth = containerView.width - contentInsets.left - contentInsets.right
        let maxHeight = containerView.height - contentInsets.top - contentInsets.bottom
        var maskWidth = maxWidth
        var maskHeight = maskWidth * (currentAspectRatio.height / currentAspectRatio.width)
        if maskHeight > maxHeight {
            maskWidth = maskWidth * (maxHeight / maskHeight)
            maskHeight = maxHeight
        }
        let maskX = (maxWidth - maskWidth) * 0.5 + contentInsets.left
        let maskY = (maxHeight -  maskHeight) * 0.5 + contentInsets.top
        return CGRect(x: maskX, y: maskY, width: maskWidth, height: maskHeight)
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
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveLinear) {
                if self.hasCropping {
                    self.scrollView.contentInset = self.oldContentInset
                }
                self.scrollView.zoomScale = zoomScale
                if self.hasCropping {
                    self.scrollView.contentOffset = self.checkZoomOffset(self.oldContentOffset, self.scrollView.contentInset)
                }else {
                    if !self.isOriginalRatio {
                        let offset = CGPoint(x: -self.scrollView.contentInset.left + (self.imageView.width * 0.5 - maskViewFrame.width * 0.5), y: -self.scrollView.contentInset.top + (self.imageView.height * 0.5 - maskViewFrame.height * 0.5))
                        self.scrollView.contentOffset = offset
                    }
                }
            } completion: { (isFinished) in
                self.maskBgView.updateBlackMask(isShow: false, animated: animated, completion: nil)
                self.showMaskView(animated)
                self.maskLinesView.setupShadow(false)
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
                    let offset = CGPoint(x: -scrollView.contentInset.left + (imageView.width * 0.5 - maskViewFrame.width * 0.5), y: -scrollView.contentInset.top + (imageView.height * 0.5 - maskViewFrame.height * 0.5))
                    scrollView.contentOffset = offset
                }
            }
            maskBgView.updateBlackMask(isShow: false, animated: animated, completion: nil)
            showMaskView(animated)
            maskLinesView.setupShadow(false)
            completion?()
        }
    }
    /// 完成裁剪
    func finishCropping(_ animated: Bool, completion: (() -> Void)?, updateCrop: Bool = true) {
        state = .normal
        resetOther()
        maskLinesView.setupShadow(true)
        controlView.isUserInteractionEnabled = false
        let fromSize = getExactnessSize(imageView.size)
        let toSize = getExactnessSize(controlView.size)
        let can_Reset = canReset()
        if can_Reset || (!can_Reset && (!fromSize.equalTo(toSize) || (fromSize.equalTo(toSize) && cropConfig.isRoundCrop))) {
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
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveLinear) {
                self.updateScrollViewContentInset(maskRect)
                self.scrollView.zoomScale = zoomScale
                self.scrollView.contentOffset = self.getZoomOffset(fromRect: controlBeforeRect, zoomScale: zoomScale, scrollCotentInset: scrollCotentInset)
            } completion: { (_) in
                completion?()
                self.maskBgView.updateBlackMask(isShow: false, animated: false, completion: nil)
                self.maskBgView.isHidden = true
                self.maskBgView.alpha = 0
            }
        }else {
            updateScrollViewContentInset(maskRect)
            scrollView.zoomScale = zoomScale
            scrollView.contentOffset = getZoomOffset(fromRect: controlBeforeRect, zoomScale: zoomScale, scrollCotentInset: scrollCotentInset)
            completion?()
            maskBgView.updateBlackMask(isShow: false, animated: false, completion: nil)
            maskBgView.isHidden = true
            maskBgView.alpha = 0
        }
    }
    /// 取消裁剪
    func cancelCropping(canShowMask: Bool = true, _ animated: Bool, completion: (() -> Void)?) {
        state = .normal
        resetOther()
        maskLinesView.setupShadow(true)
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
            updateScrollViewContent(contentInset: nil, zoomScale: 1, contentOffset: offset, animated: animated, resetAngle: true) {
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
        maskLinesView.setupShadow(true)
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
            offset = CGPoint(x: -scrollViewContentInset.left + (baseImageSize.width * zoomScale * 0.5 - maskViewFrame.width * 0.5), y: -scrollViewContentInset.top + (baseImageSize.height * zoomScale * 0.5 - maskViewFrame.height * 0.5))
        }
        updateScrollViewContent(contentInset: scrollViewContentInset, zoomScale: zoomScale, contentOffset: offset, animated: animated, resetAngle: true) {
            self.maskLinesView.setupShadow(false)
            self.delegate?.imageResizerView(didEndChangedMaskRect: self)
            if self.maskBgShowTimer == nil && self.maskBgView.alpha == 0 {
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
                offset = CGPoint(x: -scrollViewContentInset.left + (baseImageSize.width * zoomScale * 0.5 - maskViewFrame.width * 0.5), y: -scrollViewContentInset.top + (baseImageSize.height * zoomScale * 0.5 - maskViewFrame.height * 0.5))
            }
            let currentOffset = scrollView.contentOffset
            // 允许0.18以内的误差
            let difference = max(fabsf(Float(currentOffset.x - offset.x)), fabsf(Float(currentOffset.y - offset.y)))
            let zoomScaleDifference = fabsf(Float(scrollView.zoomScale - zoomScale))
            if zoomScaleDifference > 0.0000001 || !controlView.frame.equalTo(maskViewFrame) || difference > 0.18 {
                /// 缩放大小不一致、裁剪框位置大小不一致、不在中心点位置、角度不为0都可以还原
                return true
            }
            return false
        }
        let fromSize = getExactnessSize(imageView.size)
        let toSize = getExactnessSize(controlView.size)
        return !fromSize.equalTo(toSize)
    }
    /// 改变比例
    func changedAspectRatio(of aspectRatio: CGSize) {
        if aspectRatio.width == 0 {
            // 自由
            // 取消固定比例
            controlView.fixedRatio = false
            // 情况宽高比
            controlView.aspectRatio = .zero
            currentAspectRatio = controlView.aspectRatio
            // 检测是否是原始宽高比
            checkOriginalRatio()
        }else {
            // 停止定时器
            stopControlTimer()
            stopShowMaskBgTimer()
            maskLinesView.setupShadow(true)
            inControlTimer = false
            // 停止滑动
            scrollView.setContentOffset(scrollView.contentOffset, animated: false)
            // 指定比例
            delegate?.imageResizerView(willChangedMaskRect: self)
            // 固定比例
            controlView.fixedRatio = true
            // 修改宽高比
            controlView.aspectRatio = aspectRatio
            // 记录当前宽高比
            currentAspectRatio = controlView.aspectRatio
            // 检测是否是原始宽高比
            checkOriginalRatio()
            // 获取比例对应的裁剪框大小
            let maskRect = getInitializationRatioMaskRect()
            // 获取当前裁剪框位置大小
            let controlBeforeRect = maskBgView.convert(controlView.frame, to: imageView)
            // 更新裁剪框
            updateMaskViewFrame(to: maskRect, animated: true)
            // 需要缩放的比例
            let zoomScale = getInitialZoomScale()
            let scrollViewContentInset = getScrollViewContentInset(maskRect)
            // 当前缩放比例小于指定缩放比例,需要进行缩放
            if scrollView.zoomScale < zoomScale {
                // 缩放之后裁剪框对应的图片中心点要和之前的一致
                var offsetX = controlBeforeRect.midX * zoomScale - scrollViewContentInset.left
                var offsetY = controlBeforeRect.midY * zoomScale - scrollViewContentInset.top
                UIView.animate(withDuration: 0.25, delay: 0, options: .curveLinear) {
                    self.scrollView.contentInset = scrollViewContentInset
                    self.scrollView.zoomScale = zoomScale
                    let controlAfterRect = self.maskBgView.convert(self.controlView.frame, to: self.imageView)
                    offsetX = offsetX - controlAfterRect.width * 0.5 * zoomScale
                    offsetY = offsetY - controlAfterRect.height * 0.5 * zoomScale
                    self.scrollView.contentOffset = self.checkZoomOffset(CGPoint(x: offsetX, y: offsetY), scrollViewContentInset)
                } completion: { (isFinished) in
                    self.changedMaskRectCompletion()
                }
            }else {
                scrollView.contentInset = scrollViewContentInset
                let offset = checkZoomOffset(scrollView.contentOffset, scrollViewContentInset)
                if !offset.equalTo(scrollView.contentOffset) {
                    UIView.animate(withDuration: 0.25, delay: 0, options: .curveLinear) {
                        self.scrollView.contentOffset = offset
                    } completion: { (isFinished) in
                        self.changedMaskRectCompletion()
                    }
                }else {
                    changedMaskRectCompletion()
                }
            }
        }
    }
    private func changedMaskRectCompletion() {
        maskLinesView.setupShadow(false)
        delegate?.imageResizerView(didEndChangedMaskRect: self)
        if maskBgShowTimer == nil && maskBgView.alpha == 0 {
            showMaskBgView()
        }
    }
    func getAngleInRadians() -> CGFloat {
        switch currentAngle {
        case 90:
            return CGFloat.pi / 2
        case -90:
            return -CGFloat.pi / 2
        case 180:
            return CGFloat.pi
        case -180:
            return -CGFloat.pi
        case 270:
            return CGFloat.pi + CGFloat.pi / 2
        case -270:
            return -(CGFloat.pi + CGFloat.pi / 2)
        default:
            return 0
        }
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
        maskLinesView.setupShadow(true)
        if !controlView.fixedRatio {
            let maxWidth = containerView.width - contentInsets.left - contentInsets.right
            let maxHeight = containerView.height - contentInsets.top - contentInsets.bottom
            var maskWidth = maxWidth
            var maskHeight = controlView.width * (maxWidth / controlView.height)
            if maskHeight > maxHeight {
                maskWidth = maskWidth * (maxHeight / maskHeight)
                maskHeight = maxHeight
            }
            let maskRect = CGRect(x: contentInsets.left + (maxWidth - maskWidth) * 0.5, y: contentInsets.top + (maxHeight - maskHeight) * 0.5, width: maskWidth, height: maskHeight)
            
            updateMaskViewFrame(to: maskRect, animated: true)
        }
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveLinear]) {
            self.rotateHandler(angleInRadians: angleInRadians, beforeZoomScale: beforeZoomScale, controlBeforeRect: controlBeforeRect)
        } completion: { (isFinished) in
            self.maskLinesView.setupShadow(false)
            self.changedMaskRectCompletion()
            self.rotating = false
        }
    }
    func rotateHandler(angleInRadians: CGFloat, beforeZoomScale: CGFloat, controlBeforeRect: CGRect) {
        resetScrollViewTransform(angleInRadians: angleInRadians)
        updateScrollViewContentInset(controlView.frame)
        let zoomScale = getScrollViewMinimumZoomScale(controlView.frame)
        scrollView.minimumZoomScale = zoomScale
        scrollView.zoomScale = zoomScale * beforeZoomScale
        
        let controlAfterRect = maskBgView.convert(controlView.frame, to: imageView)
        
        var offsetX = controlBeforeRect.midX * scrollView.zoomScale - scrollView.contentInset.left 
        var offsetY = controlBeforeRect.midY * scrollView.zoomScale - scrollView.contentInset.top
        offsetX = offsetX - controlAfterRect.width * 0.5 * scrollView.zoomScale
        offsetY = offsetY - controlAfterRect.height * 0.5 * scrollView.zoomScale
        scrollView.contentOffset = checkZoomOffset(CGPoint(x: offsetX, y: offsetY), scrollView.contentInset)
    }
    func resetScrollViewTransform(transform: CGAffineTransform? = nil, angleInRadians: CGFloat = 0, animated: Bool = false) {
        
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
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveLinear) {
                self.scrollView.transform = rotateTransform
                self.scrollView.frame = scrollViewFrame
            } completion: { (_) in
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
        maskLinesView.setupShadow(true)
        if animated {
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveLinear) {
                self.mirrorHorizontallyHandler()
            } completion: { (_) in
                self.maskLinesView.setupShadow(false)
                self.changedMaskRectCompletion()
                self.mirroring = false
            }
        }else {
            mirrorHorizontallyHandler()
            maskLinesView.setupShadow(false)
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
            case -90, 90:
                scrollView.transform = rotateTransform.scaledBy(x: 1, y: -1)
                currentAngle = 270
            case -180, 180:
                scrollView.transform = rotateTransform.scaledBy(x: -1, y: 1)
            case -270, 270:
                scrollView.transform = CGAffineTransform.identity.rotated(by: -CGFloat.pi * 0.5).scaledBy(x: -1, y: 1)
                currentAngle = 90
            default:
                scrollView.transform = rotateTransform.scaledBy(x: -1, y: 1)
            }
        }else {
            mirrorType = .none
            switch currentAngle {
            case -90, 90:
                scrollView.transform = CGAffineTransform.identity.rotated(by: -(CGFloat.pi + CGFloat.pi * 0.5))
                currentAngle = -270
            case -180, 180:
                scrollView.transform = rotateTransform.scaledBy(x: 1, y: 1)
            case -270, 270:
                scrollView.transform = CGAffineTransform(rotationAngle: -CGFloat.pi * 0.5).scaledBy(x: 1, y: 1)
                currentAngle = -90
            default:
                scrollView.transform = rotateTransform.scaledBy(x: 1, y: 1)
            }
        }
    }
    func getImageOrientation(_ isOld: Bool = false) -> ImageOrientation {
        switch isOld ? oldAngle : currentAngle {
        case 90, -270:
            return .right
        case 180, -180:
            return .down
        case 270, -90:
            return .left
        default:
            return .up
        }
    }
    func getCroppingRect() -> CGRect {
        var rect = maskBgView.convert(controlView.frame, to: imageView)
        rect = CGRect(x: rect.minX * scrollView.zoomScale, y: rect.minY * scrollView.zoomScale, width: rect.width * scrollView.zoomScale, height: rect.height * scrollView.zoomScale)
        return rect
    }
    func cropping(_ inputImage: UIImage?, toRect cropRect: CGRect, viewWidth: CGFloat, viewHeight: CGFloat) -> (UIImage, URL, PhotoEditResult.ImageType)? {
        if let option = inputImage?.animateImageFrame() {
            var images = [UIImage]()
            var delays = [Double]()
            for (index, image) in option.0.enumerated() {
                if let newImage = cropImage(image, toRect: cropRect, viewWidth: viewWidth, viewHeight: viewHeight) {
                    images.append(newImage)
                    delays.append(option.1[index])
                }
            }
            if let image = images.first, let imageURL = PhotoTools.createAnimatedImageURL(images: images, delays: delays) {
                return (image, imageURL, .gif)
            }
            return nil
        }
        if let image = cropImage(inputImage, toRect: cropRect, viewWidth: viewWidth, viewHeight: viewHeight), let imageURL = PhotoTools.write(image: image) {
            return (image, imageURL, .normal)
        }
        return nil
    }
    func cropImage(_ inputImage: UIImage?, toRect cropRect: CGRect, viewWidth: CGFloat, viewHeight: CGFloat) -> UIImage?  {
        var image = inputImage?.cropImage(toRect: cropRect, viewWidth: viewWidth, viewHeight: viewHeight)
        if cropConfig.isRoundCrop {
            image = image?.roundCropping()
        }
        var rotate = CGFloat.pi * currentAngle / 180
        if rotate != 0 {
            rotate = CGFloat.pi * 2 + rotate
        }
        let isHorizontal = mirrorType == .horizontal
        if rotate > 0 || isHorizontal {
            let angle = labs(Int(currentAngle))
            image = image?.rotation(angle: angle, isHorizontal: isHorizontal)
        }
        return image
    }
    /// 更新scrollView的显示内容
    func updateScrollViewContent(contentInset: UIEdgeInsets?, zoomScale: CGFloat, contentOffset: CGPoint, animated: Bool, resetAngle: Bool = false, completion: (()->())? = nil) {
        if animated {
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveLinear) {
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
    /// 更新边距
    func updateContentInsets() {
        if UIDevice.isPortrait {
            contentInsets = UIEdgeInsets(top: 20 + UIDevice.generalStatusBarHeight, left: 30 + UIDevice.leftMargin, bottom: 125 + UIDevice.bottomMargin, right: 30 + UIDevice.rightMargin)
        }else {
            contentInsets = UIEdgeInsets(top: 20 , left: 30 + UIDevice.leftMargin, bottom: 125 + UIDevice.bottomMargin, right: 30 + UIDevice.rightMargin)
        }
    }
    /// 屏幕旋转时需要还原到初始配置
    func updateBaseConfig() {
        updateContentInsets()
        scrollView.contentInset = .zero
        updateImageViewFrame(getImageViewFrame())
        /// 手势最大范围
        let maxControlRect = CGRect(x: contentInsets.left, y: contentInsets.top, width: containerView.width - contentInsets.left - contentInsets.right, height: containerView.height - contentInsets.top - contentInsets.bottom)
        controlView.maxImageresizerFrame = maxControlRect
    }
    
    func setViewFrame(_ frame: CGRect) {
        containerView.frame = frame
        maskBgView.frame = containerView.bounds
        maskLinesView.frame = containerView.bounds
        scrollView.frame = containerView.bounds
    }
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if state == .cropping {
            return true
        }
        return super.point(inside: point, with: event)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
// MARK: ScrollView Action
extension EditorImageResizerView {
    
    /// 获取初始缩放比例
    func getInitialZoomScale() -> CGFloat {
        let maxWidth = containerView.width - contentInsets.left - contentInsets.right
        let maxHeight = containerView.height - contentInsets.top - contentInsets.bottom
        var imageWidth: CGFloat
        var imageHeight: CGFloat
        
        switch getImageOrientation() {
        case .up, .down:
            imageWidth = maxWidth
            imageHeight = imageWidth / imageScale
            if imageHeight > maxHeight {
                imageHeight = maxHeight
                imageWidth = imageHeight * imageScale
            }
            
            if !isOriginalRatio {
                let maskRect = getInitializationRatioMaskRect()
                if imageHeight < maskRect.height {
                    imageWidth = imageWidth * (maskRect.height / imageHeight)
                }
                if imageWidth < maskRect.width {
                    imageWidth = maskRect.width
                }
            }
        case .left, .right:
            imageHeight = maxWidth
            imageWidth = imageHeight * imageScale
            if imageWidth > maxHeight {
                imageWidth = maxHeight
                imageHeight = imageWidth / imageScale
            }
            
            if !isOriginalRatio {
                let maskRect = getInitializationRatioMaskRect()
                if imageWidth < maskRect.height {
                    imageHeight = imageHeight * (maskRect.height / imageWidth)
                }
                if imageHeight < maskRect.width {
                    imageHeight = maskRect.width
                }
                imageWidth = imageHeight * imageScale
            }
        }
        let minimumZoomScale = imageWidth / baseImageSize.width
        return minimumZoomScale
    }
    
    /// 更新scrollView属性
    func updateScrollView() {
        scrollView.alwaysBounceVertical = state == .cropping
        scrollView.alwaysBounceHorizontal = state == .cropping
        scrollView.isUserInteractionEnabled = state == .cropping
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
// MARK: ImageView Action
extension EditorImageResizerView {
    /// 获取imageView初始位置大小
    func getImageViewFrame() -> CGRect {
        let maxWidth = containerView.width
        let maxHeight = containerView.height
        let imageWidth = maxWidth
        let imageHeight = imageWidth / imageScale
        var imageX: CGFloat = 0
        var imageY: CGFloat = 0
        if imageHeight < maxHeight {
            imageY = (maxHeight - imageHeight) * 0.5
        }
        if imageWidth < maxWidth {
            imageX = (maxWidth - imageWidth) * 0.5
        }
        return CGRect(x: imageX, y: imageY, width: imageWidth, height: imageHeight)
    }
    /// 更新imageView位置大小
    func updateImageViewFrame(_ imageFrame: CGRect) {
        imageView.size = imageFrame.size
        baseImageSize = imageView.size
        scrollView.contentSize = imageView.size
        if imageView.height < containerView.height {
            let top = (containerView.height - imageView.height) * 0.5
            let left = (containerView.width - imageView.width) * 0.5
            scrollView.contentInset = UIEdgeInsets(top: top, left: left, bottom: top, right: left)
        }
    }
}
// MARK: MaskView Action
extension EditorImageResizerView {
    func getMaskRect() -> CGRect {
        return getImageViewFrame()
    }
    /// 显示遮罩界面
    func hiddenMaskView(_ animated: Bool, onlyLines: Bool = false) {
        if animated {
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveLinear) {
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
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveLinear) {
                self.maskBgView.alpha = 1
                self.maskLinesView.alpha = 1
            } completion: { (isFinished) in
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
        let maskX = (containerView.width - contentInsets.left - contentInsets.right - maskWidth) * 0.5 + contentInsets.left
        let maskY = (containerView.height - contentInsets.top - contentInsets.bottom - maskHeight) * 0.5 + contentInsets.top
        return CGRect(x: maskX, y: maskY, width: maskWidth, height: maskHeight)
    }
    /// 更新遮罩界面位置大小
    /// - Parameters:
    ///   - rect: 指定位置
    ///   - animated: 是否需要动画效果
    func updateMaskViewFrame(to rect: CGRect, animated: Bool) {
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
        let timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(showMaskBgView), userInfo: nil, repeats: false)
        RunLoop.main.add(timer, forMode: .common)
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
        UIView.animate(withDuration: 0.2) {
            self.maskBgView.alpha = 0
        }
    }
}
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
        if inControlTimer {
            startControlTimer()
        }else {
            startShowMaskBgTimer()
        }
        delegate?.imageResizerView(didEndZooming: self)
    }
}
// MARK: EditorImageResizerControlViewDelegate
extension EditorImageResizerView: EditorImageResizerControlViewDelegate {
    
    func controlView(beganChanged controlView: EditorImageResizerControlView, _ rect: CGRect) {
        delegate?.imageResizerView(willChangedMaskRect: self)
        hideMaskBgView()
        stopControlTimer()
    }
    func controlView(didChanged controlView: EditorImageResizerControlView, _ rect: CGRect) {
        stopControlTimer()
        if state == .normal {
            return
        }
        maskBgView.updateLayers(rect, false)
        maskLinesView.updateLayers(rect, false)
        
        scrollView.minimumZoomScale = getScrollViewMinimumZoomScale(rect)
        var imageViewHeight: CGFloat
        var imageViewWidth: CGFloat
        switch getImageOrientation() {
        case .up, .down:
            imageViewWidth = imageView.width
            imageViewHeight = imageView.height
        case .left, .right:
            imageViewWidth = imageView.height
            imageViewHeight = imageView.width
        }
        var changedZoomScale = false
        if rect.height > imageViewHeight {
            let imageZoomScale = rect.height / imageViewHeight
            let zoomScale = scrollView.zoomScale
            scrollView.setZoomScale(zoomScale * imageZoomScale, animated: false)
            changedZoomScale = true
        }
        if rect.width > imageViewWidth {
            let imageZoomScale = rect.width / imageViewWidth
            let zoomScale = scrollView.zoomScale
            scrollView.setZoomScale(zoomScale * imageZoomScale, animated: false)
            changedZoomScale = true
        }
        if !changedZoomScale {
            updateScrollViewContentInset(controlView.frame)
        }
    }
    func controlView(endChanged controlView: EditorImageResizerControlView, _ rect: CGRect) {
        startControlTimer()
    }
    func startControlTimer() {
        controlTimer?.invalidate()
        let timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(controlTimerAction), userInfo: nil, repeats: false)
        RunLoop.main.add(timer, forMode: .common)
        controlTimer = timer
        inControlTimer = true
    }
    
    func stopControlTimer() {
        controlTimer?.invalidate()
        controlTimer = nil
    }
    
    @objc func controlTimerAction() {
        adjustmentViews(true)
    }
    func adjustmentViews(_ animated: Bool, showMaskShadow: Bool = true) {
        maskBgViewisShowing = true
        /// 显示遮罩背景
        showMaskBgView()
        /// 停止定时器
        stopControlTimer()
        /// 最大高度
        let maxHeight = containerView.height - contentInsets.top - contentInsets.bottom
        /// 裁剪框x
        var rectX = contentInsets.left
        /// 裁剪框的宽度
        var rectW = containerView.width - contentInsets.left - contentInsets.right
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
        let controlBeforeRect = maskBgView.convert(controlView.frame, to: imageView)
        /// 隐藏阴影
        maskLinesView.setupShadow(true)
        /// 更新裁剪框坐标
        updateMaskViewFrame(to: rect, animated: animated)
        /// 裁剪框更新之后再imageView上的坐标
        let controlAfterRect = maskBgView.convert(controlView.frame, to: imageView)
        let scrollCotentInset = getScrollViewContentInset(rect)
        /// 计算scrollView偏移量
        var offset = scrollView.contentOffset
        var offsetX: CGFloat
        var offsetY: CGFloat
        switch getImageOrientation() {
        case .up:
            if mirrorType == .horizontal {
                offsetX = offset.x + (rect.midX - beforeRect.midX)
            }else {
                offsetX = offset.x - (rect.midX - beforeRect.midX)
            }
            offsetY = offset.y - (rect.midY - beforeRect.midY)
        case .left:
            offsetX = offset.x + (rect.midY - beforeRect.midY)
            if mirrorType == .horizontal {
                offsetY = offset.y + (rect.midX - beforeRect.midX)
            }else {
                offsetY = offset.y - (rect.midX - beforeRect.midX)
            }
        case .down:
            if mirrorType == .horizontal {
                offsetX = offset.x - (rect.midX - beforeRect.midX)
            }else {
                offsetX = offset.x + (rect.midX - beforeRect.midX)
            }
            offsetY = offset.y + (rect.midY - beforeRect.midY)
        case .right:
            offsetX = offset.x - (rect.midY - beforeRect.midY)
            if mirrorType == .horizontal {
                offsetY = offset.y - (rect.midX - beforeRect.midX)
            }else {
                offsetY = offset.y + (rect.midX - beforeRect.midX)
            }
        }
        offset = checkZoomOffset(CGPoint(x: offsetX, y: offsetY), scrollCotentInset)
        let zoomScale = getZoomScale(fromRect: controlBeforeRect, toRect: controlAfterRect)
        let needZoomScale = zoomScale != scrollView.zoomScale
        if animated {
            UIView.animate(withDuration: 0.25, delay: 0, options: [.curveLinear]) {
                self.updateScrollViewContentInset(rect)
                if needZoomScale {
                    /// 需要进行缩放
                    self.scrollView.zoomScale = zoomScale
                    offset = self.getZoomOffset(fromRect: controlBeforeRect, zoomScale: zoomScale, scrollCotentInset: scrollCotentInset)
                }
                self.scrollView.contentOffset = offset
            } completion: { (isFinished) in
                if showMaskShadow {
                    self.maskLinesView.setupShadow(false)
                }
                self.maskBgViewisShowing = false
                self.inControlTimer = false
                self.delegate?.imageResizerView(didEndChangedMaskRect: self)
            }
        }else {
            updateScrollViewContentInset(rect)
            if needZoomScale {
                /// 需要进行缩放
                scrollView.zoomScale = zoomScale
                offset = getZoomOffset(fromRect: controlBeforeRect, zoomScale: zoomScale, scrollCotentInset: scrollCotentInset)
            }
            scrollView.contentOffset = offset
            if showMaskShadow {
                maskLinesView.setupShadow(false)
            }
            maskBgViewisShowing = false
            inControlTimer = false
            delegate?.imageResizerView(didEndChangedMaskRect: self)
        }
    }
    func checkZoomOffset(_ offset: CGPoint, _ scrollCotentInset: UIEdgeInsets) -> CGPoint {
        var offsetX = offset.x
        var offsetY = offset.y
        var maxOffsetX: CGFloat
        var maxOffsetY: CGFloat
        switch getImageOrientation() {
        case .up:
            maxOffsetX = scrollView.contentSize.width - scrollView.width + scrollCotentInset.left
            maxOffsetY = scrollView.contentSize.height - scrollView.height + scrollCotentInset.bottom
        case .right:
            maxOffsetX = scrollView.contentSize.width - scrollView.height + scrollCotentInset.right
            maxOffsetY = scrollView.contentSize.height - scrollView.width + scrollCotentInset.bottom
        case .down:
            maxOffsetX = scrollView.contentSize.width - scrollView.width + scrollCotentInset.left
            maxOffsetY = scrollView.contentSize.height - scrollView.height + scrollCotentInset.bottom
        case .left:
            maxOffsetX = scrollView.contentSize.width - scrollView.height + scrollCotentInset.right
            maxOffsetY = scrollView.contentSize.height - scrollView.width + scrollCotentInset.top
        }
        if offsetX > maxOffsetX {
            offsetX = maxOffsetX
        }
        if offsetX < -scrollCotentInset.left {
            offsetX = -scrollCotentInset.left
        }
        if offsetY > maxOffsetY {
            offsetY = maxOffsetY
        }
        if offsetY < -scrollCotentInset.top {
            offsetY = -scrollCotentInset.top
        }
        return CGPoint(x: offsetX, y: offsetY)
    }
    func getZoomOffset(fromRect: CGRect, zoomScale: CGFloat, scrollCotentInset: UIEdgeInsets) -> CGPoint {
        let offsetX = fromRect.minX * zoomScale - scrollView.contentInset.left
        let offsetY = fromRect.minY * zoomScale - scrollView.contentInset.top
        return checkZoomOffset(CGPoint(x: offsetX, y: offsetY), scrollCotentInset)
    }
    func getExactnessSize(_ size: CGSize) -> CGSize {
        CGSize(width: CGFloat(Float(String(format: "%.2f", size.width))!), height: CGFloat(Float(String(format: "%.2f", size.height))!))
    }
    func getZoomScale(fromRect: CGRect, toRect: CGRect) -> CGFloat {
        var widthScale = toRect.width / fromRect.width
        let fromSize = getExactnessSize(fromRect.size)
        let toSize = getExactnessSize(toRect.size)
        /// 大小一样不需要缩放
        var isMaxZoom = fromSize.equalTo(toSize)
        if scrollView.zoomScale * widthScale > scrollView.maximumZoomScale {
            let scale = scrollView.maximumZoomScale - scrollView.zoomScale
            if scale > 0 {
                widthScale = scrollView.maximumZoomScale
            }else {
                isMaxZoom = true
            }
        }else {
            widthScale *= scrollView.zoomScale
        }
        return isMaxZoom ? scrollView.zoomScale : widthScale
    }
}
