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

class PhotoEditorContainerView: UIView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        true
    }
}

class PhotoEditorScrollView: UIScrollView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        true
    }
}

class EditorImageResizerView: UIView {
    
    enum ImageOrientation {
        case up
        case left
        case right
        case down
    }
    var exportScale: CGFloat = UIScreen.main.scale
    var animationDuration: TimeInterval = 0.3
    /// 裁剪配置
    var cropConfig: EditorCropSizeConfiguration
    weak var delegate: EditorImageResizerViewDelegate?
    lazy var containerView: PhotoEditorContainerView = {
        let containerView = PhotoEditorContainerView.init()
        containerView.addSubview(scrollView)
        updateScrollView()
        containerView.addSubview(maskBgView)
        containerView.addSubview(maskLinesView)
        containerView.addSubview(controlView)
        return containerView
    }()
    
    lazy var scrollView: PhotoEditorScrollView = {
        let scrollView = PhotoEditorScrollView.init(frame: .zero)
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
    
    let mosaicConfig: PhotoEditorConfiguration.Mosaic
    lazy var imageView: PhotoEditorContentView = {
        let imageView = PhotoEditorContentView(
            editType: editType,
            mosaicConfig: mosaicConfig
        )
        imageView.itemViewMoveToCenter = { [weak self] rect -> Bool in
            guard let self = self,
                  let view = self.viewController?.view else { return false }
            var newRect = self.convert(self.bounds, to: view)
            if newRect.width > view.width {
                newRect.origin.x = 0
                newRect.size.width = view.width
            }
            if newRect.height > view.height {
                newRect.origin.y = 0
                newRect.size.height = view.height
            }
            let marginWidth = rect.width - 20
            let marginHeight = rect.height - 20
            if CGRect(
                x: newRect.minX - marginWidth,
                y: newRect.minY - marginHeight,
                width: newRect.width + marginWidth * 2,
                height: newRect.height + marginHeight * 2
            ).contains(rect) {
                return false
            }
            return true
        }
        imageView.stickerMinScale = { itemSize -> CGFloat in
            min(35 / itemSize.width, 35 / itemSize.height)
        }
        imageView.stickerMaxScale = { [weak self] itemSize -> CGFloat in
            guard let self = self, let view = self.viewController?.view else { return 0 }
            var newRect = self.convert(self.bounds, to: view)
            if newRect.width > view.width {
                newRect.origin.x = 0
                newRect.size.width = view.width
            }
            if newRect.height > view.height {
                newRect.origin.y = 0
                newRect.size.height = view.height
            }
            let maxScale = min(itemSize.width, itemSize.height)
            return max((newRect.width + 35) / maxScale, (newRect.height + 35) / maxScale)
        }
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
    var mirrorType: MirrorType = .none {
        didSet {
            imageView.stickerView.mirrorType = mirrorType
        }
    }
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
    var currentAngle: CGFloat = 0 {
        didSet {
            imageView.stickerView.angle = currentAngle
        }
    }
    
    var rotating: Bool = false
    var mirroring: Bool = false
    
    var drawEnabled: Bool {
        get { imageView.drawView.enabled }
        set { imageView.drawView.enabled = newValue }
    }
    var stickerEnabled: Bool {
        get { imageView.stickerView.enabled }
        set { imageView.stickerView.enabled = newValue }
    }
    var mosaicEnabled: Bool {
        get { imageView.mosaicView.enabled }
        set { imageView.mosaicView.enabled = newValue }
    }
    
    var isDrawing: Bool { imageView.drawView.isDrawing }
    var cropTime_AspectRatio: CGSize = .zero
    var cropTime_FixedRatio: Bool = false
    var cropTime_IsOriginalRatio: Bool = false
    var zoomScale: CGFloat = 1 {
        didSet { imageView.zoomScale = zoomScale * scrollView.zoomScale }
    }
    var hasFilter: Bool = false
    var videoFilter: VideoEditorFilter?
    let editType: PhotoEditorContentView.EditType
    init(
        editType: PhotoEditorContentView.EditType,
        cropConfig: EditorCropSizeConfiguration,
        mosaicConfig: PhotoEditorConfiguration.Mosaic
    ) {
        self.editType = editType
        self.cropConfig = cropConfig
        self.mosaicConfig = mosaicConfig
        super.init(frame: .zero)
        addSubview(containerView)
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
        rect = CGRect(
            x: rect.minX * scrollView.zoomScale,
            y: rect.minY * scrollView.zoomScale,
            width: rect.width * scrollView.zoomScale,
            height: rect.height * scrollView.zoomScale
        )
        return rect
    }
    
    /// 改变裁剪框比例
    func changedAspectRatio(of aspectRatio: CGSize) {
        if aspectRatio.width == 0 {
            // 自由
            // 取消固定比例
            controlView.fixedRatio = false
            // 清空宽高比
            controlView.aspectRatio = .zero
            currentAspectRatio = controlView.aspectRatio
            // 检测是否是原始宽高比
            checkOriginalRatio()
        }else {
            // 停止定时器
            stopControlTimer()
            stopShowMaskBgTimer()
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
                UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseOut) {
                    self.scrollView.contentInset = scrollViewContentInset
                    self.scrollView.zoomScale = zoomScale
                    let controlAfterRect = self.maskBgView.convert(self.controlView.frame, to: self.imageView)
                    offsetX -= controlAfterRect.width * 0.5 * zoomScale
                    offsetY -= controlAfterRect.height * 0.5 * zoomScale
                    self.scrollView.contentOffset = self.checkZoomOffset(
                        CGPoint(x: offsetX, y: offsetY),
                        scrollViewContentInset
                    )
                } completion: { (isFinished) in
                    self.changedMaskRectCompletion()
                }
            }else {
                scrollView.contentInset = scrollViewContentInset
                let offset = checkZoomOffset(scrollView.contentOffset, scrollViewContentInset)
                if !offset.equalTo(scrollView.contentOffset) {
                    UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseOut) {
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
    func changedMaskRectCompletion() {
        delegate?.imageResizerView(didEndChangedMaskRect: self)
        if maskBgShowTimer == nil && maskBgView.alpha == 0 {
            showMaskBgView()
        }
    }
}
