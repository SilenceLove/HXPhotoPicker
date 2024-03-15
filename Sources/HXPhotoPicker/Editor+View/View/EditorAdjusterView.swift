//
//  EditorAdjusterView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2022/11/12.
//

import UIKit
import AVFoundation

class EditorAdjusterView: UIView {
    
    weak var delegate: EditorAdjusterViewDelegate?
    
    var state: EditorView.State = .normal {
        didSet {
            frameView.state = state
        }
    }
    var contentInsets: UIEdgeInsets = .zero
    var setContentInsets: (() -> UIEdgeInsets)?
    var maximumZoomScale: CGFloat = 20
    var exportScale: CGFloat = UIScreen._scale {
        didSet {
            if #available(iOS 13.0, *), let canvasView = contentView.canvasView as? EditorCanvasView {
                canvasView.exportScale = exportScale
            }
        }
    }
    
    var baseContentSize: CGSize = .zero
    var zoomScale: CGFloat = 1 {
        didSet { contentView.zoomScale = zoomScale * scrollView.zoomScale }
    }
    var editSize: CGSize = .zero
    var superContentInset: UIEdgeInsets = .zero
    
    var isContinuousRotation: Bool = false {
        didSet {
            if isContinuousRotation {
                lastRatationMinimumZoomScale = scrollView.zoomScale
                frameView.hideVideoSilder(true)
                frameView.showGridGraylinesLayer()
            }else {
                frameView.showVideoSlider(true)
                frameView.hideGridGraylinesLayer()
            }
        }
    }
    var isHEICImage: Bool = false
    var lastRatationMinimumZoomScale: CGFloat = 1
    
    var adjustedFactor: AdjustedFactor = .init()
    var oldAdjustedFactor: AdjustedFactor?
    var oldRatioFactor: EditorControlView.Factor?
    
    var isResetIgnoreFixedRatio: Bool = true
    var isMaskBgViewShowing: Bool = false
    var oldMaskImage: UIImage?
    var oldIsRound: Bool = false
    
    /// 初始编辑时的裁剪框比例
    var initialAspectRatio: CGSize = .zero
    /// 初始编辑时固定裁剪框
    var initialFixedRatio: Bool = false
    /// 初始编辑时圆形裁剪框
    var initialRoundMask: Bool = false
    
    var maskColor: UIColor? {
        didSet {
            frameView.maskColor = maskColor
        }
    }
    
    var urlConfig: EditorURLConfig?
    weak var videoTool: EditorVideoTool?
    var lastVideoFator: LastVideoFator?
    var lastVideoAngle: CGFloat = 0
    
    // MARK: initialize
    init(maskColor: UIColor?) {
        self.maskColor = maskColor
        super.init(frame: .zero)
        initViews()
        addSubview(containerView)
        resetState()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if state == .edit {
            return true
        }
        if isDrawEnabled, drawType == .canvas {
            return containerView.point(inside: point, with: event)
        }
        return super.point(inside: point, with: event)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if view == containerView {
            if state == .normal {
                if contentView.convert(contentView.frame, to: view).contains(point) {
                    return contentView.hitTest(contentView.convert(point, from: view), with: event)
                }
            }else {
                let framePoint = convert(point, to: frameView)
                if let view = frameView.hitTest(framePoint, with: event) {
                    return view
                }
                let rectX = -superContentInset.left
                let rectY = -superContentInset.top
                let rectW = containerView.width + superContentInset.left + superContentInset.right
                let rectH = containerView.height + superContentInset.top + superContentInset.bottom
                let rect = CGRect(x: rectX, y: rectY, width: rectW, height: rectH)
                if rect.contains(convert(point, to: superview)) {
                    return scrollView
                }
            }
        }
        return view
    }
    
    // MARK: views
    var containerView: ContainerView!
    var mirrorView: UIView!
    var rotateView: UIView!
    var scrollView: ScrollView!
    var contentView: EditorContentView!
    var frameView: EditorFrameView!
    
    private func initViews() {
        rotateView = UIView()
        rotateView.isUserInteractionEnabled = false
        
        contentView = EditorContentView()
        contentView.delegate = self
        
        frameView = EditorFrameView(maskColor: maskColor)
        frameView.delegate = self
        
        scrollView = ScrollView()
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = maximumZoomScale
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.clipsToBounds = false
        scrollView.scrollsToTop = false
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        scrollView.addSubview(contentView)
        
        mirrorView = UIView()
        mirrorView.addSubview(rotateView)
        mirrorView.addSubview(scrollView)
        
        containerView = ContainerView()
        containerView.addSubview(mirrorView)
        containerView.addSubview(frameView)
    }
    
    // MARK: Screen Rotation
    var beforeContentOffset: CGPoint = .zero
    var beforeContentSize: CGSize = .zero
    var beforeContentInset: UIEdgeInsets = .zero
    var beforeMirrorViewTransform: CGAffineTransform = .identity
    var beforeRotateViewTransform: CGAffineTransform = .identity
    var beforeScrollViewTransform: CGAffineTransform = .identity
    var beforeScrollViewZoomScale: CGFloat = 1
    var beforeDrawBrushInfos: [EditorDrawView.BrushInfo] = []
    var beforeMosaicDatas: [EditorMosaicView.MosaicData] = []
    var beforeStickerItem: EditorStickersView.Item?
    var beforeCanvasCurrentData: EditorCanvasData?
    var beforeCanvasHistoryData: EditorCanvasData?
    
    deinit {
        videoTool?.cancelExport()
    }
}

extension EditorAdjusterView {
    var contentType: EditorContentViewType {
        contentView.type
    }
    var isVideoPlaying: Bool {
        contentView.isPlaying
    }
    var videoPlayTime: CMTime {
        contentView.playTime
    }
    var videoDuration: CMTime {
        contentView.duration
    }
    var videoStartTime: CMTime? {
        get { contentView.startTime }
        set { contentView.startTime = newValue }
    }
    var videoEndTime: CMTime? {
        get { contentView.endTime }
        set { contentView.endTime = newValue }
    }
    var isOriginalRatio: Bool {
        let aspectRatio = frameView.aspectRatio
        if aspectRatio.equalTo(.zero) {
            return true
        }else {
            if aspectRatio.width / aspectRatio.height == contentScale {
                return true
            }
        }
        return false
    }
    var currentAngle: CGFloat {
        if state == .normal {
            guard let angle = oldAdjustedFactor?.angle else {
                return 0
            }
            return angle
        }
        return adjustedFactor.angle
    }
    var currentAspectRatio: CGSize {
        frameView.aspectRatio
    }
    var maskType: EditorView.MaskType {
        get {
            frameView.maskType
        }
        set {
            setMaskType(newValue, animated: false)
        }
    }
    func setMaskType(_ maskType: EditorView.MaskType, animated: Bool) {
        frameView.setMaskType(maskType, animated: animated)
    }
    var maskImage: UIImage? {
        get {
            frameView.maskImage
        }
        set {
            setMaskImage(newValue, animated: false)
        }
    }
    func setMaskImage(_ image: UIImage?, animated: Bool, completion: (() -> Void)? = nil) {
        adjustedFactor.maskImage = image
        frameView.setMaskImage(image, animated: animated, completion: completion)
    }
    
    var image: UIImage? {
        get {
            contentView.image
        }
        set {
            contentView.image = newValue
        }
    }
    
    var imageSize: CGSize {
        contentView.contentSize
    }
    
    var mosaicOriginalImage: UIImage? {
        get {
            contentView.mosaicOriginalImage
        }
        set {
            contentView.mosaicOriginalImage = newValue
        }
    }
    
    var mosaicOriginalCGImage: CGImage? {
        get { contentView.mosaicOriginalCGImage }
        set { contentView.mosaicOriginalCGImage = newValue }
    }
    
    func setImage(
        _ image: UIImage?
    ) {
        contentView.image = image
        frameView.contentType = contentType
    }
    
    func setImageData(
        _ imageData: Data?
    ) {
        contentView.imageData = imageData
        frameView.contentType = contentType
    }
    
    func setVideoAsset(
        _ avAsset: AVAsset,
        coverImage: UIImage? = nil
    ) {
        contentView.image = nil
        contentView.videoCover = coverImage
        contentView.avAsset = avAsset
        frameView.contentType = contentType
    }
    
    var avAsset: AVAsset? {
        contentView.avAsset
    }
    
    var avPlayer: AVPlayer? {
        contentView.avPlayer
    }
    
    var playerLayer: AVPlayerLayer? {
        contentView.playerLayer
    }
    
    var videoView: UIView? {
        if contentType != .video {
            return nil
        }
        return contentView.videoView
    }
    
    func getVideoDisplayedImage(at time: TimeInterval) -> UIImage? {
        contentView.getVideoDisplayerImage(at: time)
    }
    
    func updateVideoController() {
        if contentType == .video && state == .edit {
            frameView.showVideoSlider(true)
        }else {
            frameView.hideVideoSilder(true)
        }
    }
    
    var videoVolume: CGFloat {
        get {
            contentView.volume
        }
        set {
            contentView.volume = newValue
        }
    }
    func loadVideoAsset(isPlay: Bool, _ completion: ((Bool) -> Void)? = nil) {
        contentView.loadAsset(isPlay: isPlay, completion)
    }
    func seekVideo(to time: CMTime, isPlay: Bool, comletion: ((Bool) -> Void)? = nil) {
        contentView.seek(to: time, isPlay: isPlay, comletion: comletion)
    }
    func seekVideo(to time: TimeInterval, isPlay: Bool, comletion: ((Bool) -> Void)? = nil) {
        contentView.seek(to: time, isPlay: isPlay, comletion: comletion)
    }
    func playVideo() {
        contentView.play()
    }
    func pauseVideo() {
        contentView.pause()
    }
    func resetPlayVideo(completion: ((CMTime) -> Void)? = nil) {
        contentView.resetPlay(completion: completion)
    }
    
    func setContent(_ isEnabled: Bool = false) {
        setScrollViewEnabled(isEnabled)
        setControllContentInsets()
        setContentFrame(contentViewFrame)
        frameView.maxControlRect = .init(
            x: contentInsets.left,
            y: contentInsets.top,
            width: containerView.width - contentInsets.left - contentInsets.right,
            height: containerView.height - contentInsets.top - contentInsets.bottom
        )
    }
    
    func setMaskRect() {
        let maskRect = getContentBaseFrame()
        updateMaskRect(to: maskRect, animated: false)
    }
    
    func setControllContentInsets() {
        if let insets = setContentInsets?() {
            contentInsets = insets
        }else {
            contentInsets = .zero
        }
    }
    
    func setScrollViewEnabled(_ isEnabled: Bool) {
        scrollView.alwaysBounceVertical = isEnabled
        scrollView.alwaysBounceHorizontal = isEnabled
        scrollView.isScrollEnabled = isEnabled
        scrollView.pinchGestureRecognizer?.isEnabled = isEnabled
    }
    
    func setContentFrame(_ frame: CGRect) {
        contentView.size = frame.size
        baseContentSize = contentView.size
        scrollView.contentSize = contentView.size
        if contentView.height < containerView.height {
            let top = (containerView.height - contentView.height) * 0.5
            let left = (containerView.width - contentView.width) * 0.5
            scrollView.contentInset = UIEdgeInsets(top: top, left: left, bottom: top, right: left)
        }else {
            scrollView.contentInset = .zero
        }
    }
    
    func setFrame(_ rect: CGRect, maxRect: CGRect, contentInset: UIEdgeInsets) {
        containerView.frame = rect
        if mirrorView.size.equalTo(containerView.size) {
            return
        }
        superContentInset = contentInset
        frameView.setMaskBgFrame(
            .init(
                x: -contentInset.left,
                y: -contentInset.top,
                width: maxRect.width,
                height: maxRect.height
            ),
            insets: contentInset
        )
        frameView.frame = containerView.bounds
        let insets: UIEdgeInsets
        if let contentInsets = setContentInsets?() {
            insets = contentInsets
        }else {
            insets = .zero
        }
        let anchorX: CGFloat
        if insets.left == insets.right {
            anchorX = 0.5
        }else {
            anchorX = (insets.left + (containerView.width - insets.left - insets.right) * 0.5) / containerView.width
        }
        let anchorY: CGFloat
        if insets.top == insets.bottom {
            anchorY = 0.5
        }else {
            anchorY = (insets.top + (containerView.height - insets.top - insets.bottom) * 0.5) / containerView.height
        }
        mirrorView.layer.anchorPoint = .init(x: anchorX, y: anchorY)
        mirrorView.frame = containerView.bounds
        scrollView.layer.anchorPoint = .init(x: anchorX, y: anchorY)
        scrollView.frame = mirrorView.bounds
        rotateView.layer.anchorPoint = .init(x: anchorX, y: anchorY)
        rotateView.frame = mirrorView.bounds
    }
    
    func setCustomMaskFrame(_ rect: CGRect, maxRect: CGRect, contentInset: UIEdgeInsets) {
        frameView.setCustomMaskFrame(
            .init(
                x: -contentInset.left,
                y: -contentInset.top,
                width: maxRect.width,
                height: maxRect.height
            ),
            insets: contentInset
        )
    }
    
    func setScrollViewContentInset(_ rect: CGRect, isRound: Bool = false) {
        scrollView.contentInset = getScrollViewContentInset(rect, isRound: isRound)
    }
    
    func setScrollViewTransform(
        transform: CGAffineTransform? = nil,
        rotateTransform: CGAffineTransform? = nil,
        angle: CGFloat = 0,
        animated: Bool = false
    ) {
        var _transform: CGAffineTransform
        var rotate_Transform: CGAffineTransform
        if let transform = transform {
            _transform = transform
        }else {
            let identityTransForm = CGAffineTransform.identity
            _transform = angle == 0 ? identityTransForm : identityTransForm.rotated(by: angle.radians)
        }
        if let rotateTransform = rotateTransform {
            rotate_Transform = rotateTransform
        }else {
            let identityTransForm = CGAffineTransform.identity
            rotate_Transform = angle == 0 ? identityTransForm : identityTransForm.rotated(by: angle.radians)
        }
        if animated {
            UIView.animate {
                self.rotateView.transform = rotate_Transform
                self.scrollView.transform = _transform
            }
        }else {
            rotateView.transform = rotate_Transform
            scrollView.transform = _transform
        }
    }
    
    func setMirrorTransform(
        transform: CGAffineTransform? = nil,
        animated: Bool = false
    ) {
        if animated {
            UIView.animate {
                if let transform {
                    self.mirrorView.transform = transform
                }else {
                    self.mirrorView.transform = .identity
                }
            }
        }else {
            if let transform {
                mirrorView.transform = transform
            }else {
                mirrorView.transform = .identity
            }
        }
    }
    
    var isFixedRatio: Bool {
        get {
            frameView.isFixedRatio
        }
        set {
            frameView.isFixedRatio = newValue
            if newValue {
                frameView.aspectRatio = .init(width: frameView.controlView.width, height: frameView.controlView.height)
            }else {
                frameView.aspectRatio = .zero
            }
        }
    }
    
    var originalAspectRatio: CGSize {
        baseContentSize
    }
    
    func setAspectRatio(_ ratio: CGSize, resetRound: Bool = true, animated: Bool) {
        if resetRound {
            frameView.isRoundCrop =  false
        }
        frameView.aspectRatio = ratio
        let controlBeforeRect = getControlInContentRect()
        updateMaskAspectRatio(animated)
        scrollView.minimumZoomScale = getScrollViewMinimumZoomScale(frameView.controlView.frame)
        if animated {
            UIView.animate {
                self.setScrollViewContentInset(self.frameView.controlView.frame)
                if self.scrollView.zoomScale < self.scrollView.minimumZoomScale {
                    self.scrollView.zoomScale = self.scrollView.minimumZoomScale
                }
                self.adjustedScrollContentOffset(controlBeforeRect)
                self.updateControlScaleSize()
            }
        }else {
            setScrollViewContentInset(frameView.controlView.frame)
            if scrollView.zoomScale < scrollView.minimumZoomScale {
                scrollView.zoomScale = scrollView.minimumZoomScale
            }
            adjustedScrollContentOffset(controlBeforeRect)
            updateControlScaleSize()
        }
    }
    
    func updateMaskAspectRatio(_ animated: Bool) {
        let aspectRatio = frameView.aspectRatio
        let maxWidth = containerView.width - contentInsets.left - contentInsets.right
        let maxHeight = containerView.height - contentInsets.top - contentInsets.bottom
        var maskWidth = maxWidth
        var maskHeight: CGFloat
        if aspectRatio == .zero {
            let baseSize = getInitializationRatioMaskRect().size
            maskWidth = baseSize.width
            maskHeight = baseSize.height
        }else {
            maskHeight = maxWidth / aspectRatio.width * aspectRatio.height
            if maskHeight > maxHeight {
                maskWidth *= maxHeight / maskHeight
                maskHeight = maxHeight
            }
        }
        let maskRect = CGRect(
            x: contentInsets.left + (maxWidth - maskWidth) * 0.5,
            y: contentInsets.top + (maxHeight - maskHeight) * 0.5,
            width: maskWidth,
            height: maskHeight
        )
        updateMaskRect(to: maskRect, animated: animated)
    }
    
    func updateMaskRect(to rect: CGRect, animated: Bool) {
        if rect.width.isNaN || rect.height.isNaN {
            return
        }
        frameView.updateFrame(to: rect, animated: animated)
//        if state == .edit {
//            scrollView.minimumZoomScale = getScrollViewMinimumZoomScale(rect)
//        }
    }
    
    var isRoundMask: Bool {
        get {
            frameView.isRoundCrop
        }
        set {
            frameView.isRoundCrop = newValue
        }
    }
    
    func setRoundCrop(isRound: Bool, animated: Bool) {
        frameView.setRoundCrop(isRound: isRound, animated: animated)
    }
    
    var isShowScaleSize: Bool {
        get {
            frameView.isShowScaleSize
        }
        set {
            frameView.isShowScaleSize = newValue
        }
    }
    
    var contentScale: CGFloat {
        contentView.contentScale
    }
    
    var contentViewFrame: CGRect {
        let maxWidth = containerView.width
        let maxHeight = containerView.height
        let imageWidth = maxWidth
        let imageHeight = imageWidth / contentScale
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
    
    var initialZoomScale: CGFloat {
        let maxWidth = containerView.width - contentInsets.left - contentInsets.right
        let maxHeight = containerView.height - contentInsets.top - contentInsets.bottom
        var imageWidth = maxWidth
        var imageHeight = imageWidth / contentScale
        if imageHeight > maxHeight {
            imageHeight = maxHeight
            imageWidth = imageHeight * contentScale
        }
        
        if !isOriginalRatio {
            let maskRect = getInitializationRatioMaskRect()
            if imageHeight < maskRect.height {
                imageWidth *= maskRect.height / imageHeight
            }
            if imageWidth < maskRect.width {
                imageWidth = maskRect.width
            }
        }
        let minimumZoomScale = imageWidth / baseContentSize.width
        return minimumZoomScale
    }
     
    func getContentBaseFrame() -> CGRect {
        let maxWidth = containerView.width
        let maxHeight = containerView.height
        let imageWidth = maxWidth
        let imageHeight = imageWidth / contentScale
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
    
    func getControlInRotateRect(_ rect: CGRect? = nil, isRound: Bool = false) -> CGRect {
        let controlFrame: CGRect
        if let rect = rect {
            controlFrame = rect
        }else {
            controlFrame = frameView.controlView.frame
        }
        var _rect = frameView.convert(controlFrame, to: rotateView)
        if isRoundMask || isRound {
            _rect = .init(
                x: _rect.midX - controlFrame.width * 0.5,
                y: _rect.midY - controlFrame.height * 0.5,
                width: controlFrame.width,
                height: controlFrame.height
            )
        }
        return _rect
    }
    
    func getControlInContentRect(_ isInner: Bool = false) -> CGRect {
        let controlFrame = frameView.controlView.frame
        if isInner {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            let currentTransform = scrollView.transform
            scrollView.transform = .identity
            let tmpRect = frameView.convert(controlFrame, to: contentView)
            scrollView.transform = currentTransform
            CATransaction.commit()
            return tmpRect
        }
        var rect = frameView.convert(controlFrame, to: contentView)
        if isRoundMask {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            let currentTransform = scrollView.transform
            scrollView.transform = .identity
            let tmpRect = frameView.convert(controlFrame, to: contentView)
            scrollView.transform = currentTransform
            CATransaction.commit()
            rect = CGRect(
                x: rect.midX - tmpRect.width * 0.5,
                y: rect.midY - tmpRect.height * 0.5,
                width: tmpRect.width, height: tmpRect.height
            )
        }
        return rect
    }
    
    func getZoomOffset(
        _ offset: CGPoint,
        _ scrollCotentInset: UIEdgeInsets
    ) -> CGPoint {
        var offsetX = offset.x
        var offsetY = offset.y
        let maxOffsetX = scrollView.contentSize.width - scrollView.bounds.width + scrollCotentInset.left
        let maxOffsetY = scrollView.contentSize.height - scrollView.bounds.height + scrollCotentInset.bottom
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
    
    func getZoomOffset(
        fromRect: CGRect,
        zoomScale: CGFloat,
        scrollCotentInset: UIEdgeInsets
    ) -> CGPoint {
        let offsetX = fromRect.minX * zoomScale - scrollView.contentInset.left
        let offsetY = fromRect.minY * zoomScale - scrollView.contentInset.top
        return getZoomOffset(
            CGPoint(x: offsetX, y: offsetY),
            scrollCotentInset
        )
    }
    
    func getScrollViewContentInset(
        _ rect: CGRect,
        _ isBase: Bool = false,
        isRound: Bool = false
    ) -> UIEdgeInsets {
        let rotateRect: CGRect
        if isBase {
            rotateRect = rect
        }else {
            let rotate_Rect = getControlInRotateRect(rect, isRound: isRound)
            if isRoundMask || isRound {
                rotateRect = .init(
                    x: rotate_Rect.midX - rect.width * 0.5,
                    y: rotate_Rect.midY - rect.height * 0.5,
                    width: rect.width, height: rect.height
                )
            }else {
                rotateRect = rotate_Rect
            }
        }
        let top = rotateRect.minY
        let bottom = containerView.height - rotateRect.maxY
        let left = rotateRect.minX
        let right = containerView.width - rotateRect.maxX
        return .init(top: top, left: left, bottom: bottom, right: right)
    }
    
    func getMaskRect(_ isBase: Bool = false) -> CGRect {
        if !isOriginalRatio {
            return getInitializationRatioMaskRect()
        }
        let zoomScale = scrollView.minimumZoomScale
        let maskWidth = isBase ? baseContentSize.width * zoomScale : contentView.width * zoomScale
        let maskHeight = isBase ? baseContentSize.height * zoomScale : contentView.height * zoomScale
        let maskX = (
            containerView.width - contentInsets.left - contentInsets.right - maskWidth
        ) * 0.5 + contentInsets.left
        let maskY = (
            containerView.height - contentInsets.top - contentInsets.bottom - maskHeight
        ) * 0.5 + contentInsets.top
        return CGRect(x: maskX, y: maskY, width: maskWidth, height: maskHeight)
    }
    
    func getInitializationRatioMaskRect() -> CGRect {
        let aspectRatio = frameView.aspectRatio
        let maxWidth = containerView.width - contentInsets.left - contentInsets.right
        let maxHeight = containerView.height - contentInsets.top - contentInsets.bottom
        var maskWidth = maxWidth
        var maskHeight: CGFloat
        if aspectRatio.equalTo(.zero) {
            maskHeight = maskWidth / contentScale
        }else {
            maskHeight = maskWidth * (aspectRatio.height / aspectRatio.width)
        }
        if maskHeight > maxHeight {
            maskWidth *= maxHeight / maskHeight
            maskHeight = maxHeight
        }
        let maskX = (maxWidth - maskWidth) * 0.5 + contentInsets.left
        let maskY = (maxHeight -  maskHeight) * 0.5 + contentInsets.top
        return CGRect(x: maskX, y: maskY, width: maskWidth, height: maskHeight)
    }
    
    func getMinimuzmControlSize(rect: CGRect, isRound: Bool = false) -> CGSize {
        let minRect = getControlInRotateRect(rect, isRound: isRound)
        return minRect.size
    }
    
    func getScrollViewMinimumZoomScale(_ rect: CGRect, isRound: Bool = false) -> CGFloat {
        var minZoomScale: CGFloat
        let minSize = getMinimuzmControlSize(rect: rect, isRound: isRound)
        let rectW = minSize.width
        let rectH = minSize.height
        if rectW >= rectH {
            minZoomScale = rectW / baseContentSize.width
            let scaleHeight = baseContentSize.height * minZoomScale
            if scaleHeight < rectH {
                minZoomScale *= rectH / scaleHeight
            }
        }else {
            minZoomScale = rectH / baseContentSize.height
            let scaleWidth = baseContentSize.width * minZoomScale
            if scaleWidth < rectW {
                minZoomScale *= rectW / scaleWidth
            }
        }
        return minZoomScale
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
        if isMaxZoom {
            return scrollView.zoomScale
        }else {
            return widthScale
        }
    }
    
    func getExactnessSize(_ size: CGSize) -> CGSize {
        CGSize(
            width: CGFloat(Float(String(format: "%.2f", size.width))!),
            height: CGFloat(Float(String(format: "%.2f", size.height))!)
        )
    }
    
    func resetAll() {
        reset(false)
        oldAdjustedFactor = nil
        adjustedFactor = .init()
        if !containerView.frame.equalTo(.zero) {
            cancelEdit(false)
        }
    }
    
    func resetScrollContent() {
        scrollView.contentOffset.y = -scrollView.contentInset.top
    }
    
    func getData() -> EditAdjustmentData {
        let adjustedData = getCurrentAdjusted()
        var adjusted: EditAdjustmentData.Content.Adjusted?
        if let factor = adjustedData.0 {
            let ratioFactor: EditorControlView.Factor?
            if state == .normal {
                ratioFactor = oldRatioFactor
            }else {
                ratioFactor = .init(fixedRatio: isFixedRatio, aspectRatio: currentAspectRatio)
            }
            adjusted = .init(
                angle: factor.angle,
                zoomScale: factor.zoomScale,
                contentOffset: factor.contentOffset,
                contentInset: factor.contentInset,
                maskRect: factor.maskRect,
                transform: factor.transform,
                rotateTransform: factor.rotateTransform,
                mirrorTransform: factor.mirrorTransform,
                contentOffsetScale: factor.contentOffsetScale,
                min_zoom_scale: factor.min_zoom_scale,
                isRoundMask: factor.isRoundMask,
                ratioFactor: ratioFactor
            )
        }
        let maskImage: UIImage?
        if let image = adjustedData.0?.maskImage {
            maskImage = image
        }else {
            maskImage = oldMaskImage
        }
        var canvasData: EditorCanvasData?
        if #available(iOS 13.0, *), let canvasView = contentView.canvasView as? EditorCanvasView {
            canvasData = canvasView.data
        }
        return .init(
            content: .init(
                editSize: adjustedData.1,
                contentOffset: scrollView.contentOffset,
                contentSize: scrollView.contentSize,
                contentInset: scrollView.contentInset,
                mirrorViewTransform: mirrorView.transform,
                rotateViewTransform: rotateView.transform,
                scrollViewTransform: scrollView.transform,
                scrollViewZoomScale: scrollView.zoomScale / scrollView.minimumZoomScale,
                controlScale: frameView.controlView.size.height / frameView.controlView.size.width,
                adjustedFactor: adjusted
            ),
            maskImage: maskImage,
            drawView: contentView.drawView.getBrushData(),
            canvasData: canvasData,
            mosaicView: contentView.mosaicView.getMosaicData(),
            stickersView: contentView.stickerView.getStickerItem()
        )
    }
    
    func setData(_ factor: EditAdjustmentData) {
        let contentData = factor.content
        resetOldViewData()
        
        editSize = factor.content.editSize
        resetMaskImageData(factor.maskImage)
        resetOldAdjustedFactor(factor)
        setContent(state == .edit)
        resetOldTransformData(contentData)
        
        let controlScale = contentData.controlScale
        let beforeZoomScale = contentData.scrollViewZoomScale
        resetOldMaskRectData(controlScale)
        
        let controlView = frameView.controlView!
        setScrollViewContentInset(controlView.frame, isRound: oldAdjustedFactor?.isRoundMask ?? false)
        let baseContentInset = scrollView.contentInset
        if state == .edit {
            let minimumZoomScale = getScrollViewMinimumZoomScale(controlView.frame)
            scrollView.minimumZoomScale = minimumZoomScale
            let zoomScale = max(minimumZoomScale, minimumZoomScale * beforeZoomScale)
            scrollView.zoomScale = zoomScale
        }else {
            if let data = oldAdjustedFactor {
                let minimumZoomScale = getScrollViewMinimumZoomScale(data.maskRect, isRound: data.isRoundMask)
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
            
            frameView.show(false)
            
            oldMaskImage = data.maskImage
            if let oldMaskImage = oldMaskImage {
                setMaskImage(oldMaskImage, animated: false)
            }else {
                setMaskImage(nil, animated: false)
            }
            if maskImage == nil {
                frameView.hideCustomMaskView(false)
            }else {
                frameView.hideImageMaskView(false)
            }
            
            oldIsRound = data.isRoundMask
            setRoundCrop(isRound: data.isRoundMask, animated: false)
            
            frameView.blackMask(isShow: true, animated: false)
            frameView.hide(isMaskBg: false, animated: false)
            clipsToBounds = true
        }
        let contentSize = scrollView.contentSize
        let contentInset = scrollView.contentInset
        if state == .edit {
            let offsetXScale = (contentData.contentOffset.x + contentData.contentInset.left) / contentData.contentSize.width
            let offsetYScale = (contentData.contentOffset.y + contentData.contentInset.top) / contentData.contentSize.height
            let offsetX = contentSize.width * offsetXScale - contentInset.left
            let offsetY = contentSize.height * offsetYScale - contentInset.top
            scrollView.contentOffset = CGPoint(x: offsetX, y: offsetY)
        }else {
            if let data = oldAdjustedFactor {
                let offsetX = contentSize.width * data.contentOffsetScale.x - baseContentInset.left
                let offsetY = contentSize.height * data.contentOffsetScale.y - baseContentInset.top
                scrollView.contentOffset = .init(x: offsetX, y: offsetY)
            }
        }
        contentView.zoomScale = zoomScale * scrollView.zoomScale
        contentView.drawView.setBrushData(factor.drawView, viewSize: contentView.bounds.size)
        if #available(iOS 13.0, *), let canvasView = contentView.canvasView as? EditorCanvasView {
            canvasView.setData(data: factor.canvasData, viewSize: contentView.bounds.size)
        }
        contentView.mosaicView.setMosaicData(mosaicDatas: factor.mosaicView, viewSize: contentView.bounds.size)
        contentView.stickerView.setStickerItem(factor.stickersView, viewSize: contentView.bounds.size)
    }
    
    private func resetOldViewData() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        mirrorView.transform = .identity
        rotateView.transform = .identity
        scrollView.transform = .identity
        CATransaction.commit()
        scrollView.minimumZoomScale = 1
        scrollView.zoomScale = 1
    }
    
    private func resetOldAdjustedFactor(_ factor: EditAdjustmentData) {
        guard let adjustedFactor = factor.content.adjustedFactor else {
            return
        }
        oldAdjustedFactor = .init(
            angle: adjustedFactor.angle,
            zoomScale: adjustedFactor.zoomScale,
            contentOffset: adjustedFactor.contentOffset,
            contentInset: adjustedFactor.contentInset,
            maskRect: adjustedFactor.maskRect,
            transform: adjustedFactor.transform,
            rotateTransform: adjustedFactor.rotateTransform,
            mirrorTransform: adjustedFactor.mirrorTransform,
            maskImage: factor.maskImage,
            contentOffsetScale: adjustedFactor.contentOffsetScale,
            min_zoom_scale: adjustedFactor.min_zoom_scale,
            isRoundMask: adjustedFactor.isRoundMask
        )
        oldAdjustedFactor?.maskImage = factor.maskImage
        oldRatioFactor = adjustedFactor.ratioFactor
        if let oldFactor = oldRatioFactor {
            isFixedRatio = oldFactor.fixedRatio
            frameView.aspectRatio = oldFactor.aspectRatio
        }
        self.adjustedFactor = oldAdjustedFactor!
    }
    
    private func resetMaskImageData(_ image: UIImage?) {
        oldMaskImage = image
        if oldMaskImage != nil {
            maskImage = oldMaskImage
            frameView.showCustomMaskView(false)
            frameView.hideImageMaskView(false)
        }
    }
    
    private func resetOldTransformData(_ content: EditAdjustmentData.Content) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        mirrorView.transform = content.mirrorViewTransform
        rotateView.transform = content.rotateViewTransform
        scrollView.transform = content.scrollViewTransform
        CATransaction.commit()
    }
    
    private func resetOldMaskRectData(_ controlScale: CGFloat) {
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
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            let currentMirrorTransform = mirrorView.transform
            let currentTotateTransform = rotateView.transform
            mirrorView.transform = oldData.mirrorTransform
            rotateView.transform = oldData.rotateTransform
            let zoomScale = getScrollViewMinimumZoomScale(maskRect, isRound: oldData.isRoundMask) * oldData.min_zoom_scale
            rotateView.transform = currentTotateTransform
            mirrorView.transform = currentMirrorTransform
            CATransaction.commit()
            oldAdjustedFactor?.zoomScale = zoomScale
        }
    }
    
    func getOldMaskRect() -> CGRect {
        guard let data = oldAdjustedFactor else {
            return .zero
        }
        func getControlRotateRect(_ rect: CGRect) -> CGRect {
            let controlFrame = rect
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            let currentMirrorTransform = mirrorView.transform
            let currentTotateTransform = rotateView.transform
            mirrorView.transform = data.mirrorTransform
            rotateView.transform = data.rotateTransform
            var _rect = frameView.convert(controlFrame, to: rotateView)
            if data.isRoundMask {
                _rect = .init(
                    x: _rect.midX - controlFrame.width * 0.5,
                    y: _rect.midY - controlFrame.height * 0.5,
                    width: controlFrame.width,
                    height: controlFrame.height
                )
            }
            rotateView.transform = currentTotateTransform
            mirrorView.transform = currentMirrorTransform
            CATransaction.commit()
            return _rect
        }
        let rect = data.maskRect
        let rotateRect: CGRect
        let rotate_Rect = getControlRotateRect(rect)
        if data.isRoundMask {
            rotateRect = .init(
                x: rotate_Rect.midX - rect.width * 0.5,
                y: rotate_Rect.midY - rect.height * 0.5,
                width: rect.width, height: rect.height
            )
        }else {
            rotateRect = rotate_Rect
        }
        return rotateRect
    }
    
    func getOldContentInsert() -> UIEdgeInsets {
        let rotateRect = getOldMaskRect()
        let top = rotateRect.minY
        let bottom = containerView.height - rotateRect.maxY
        let left = rotateRect.minX
        let right = containerView.width - rotateRect.maxX
        return .init(top: top, left: left, bottom: bottom, right: right)
    }
     
    class ContainerView: UIView {
        override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
            true
        }
    }
    class ScrollView: UIScrollView {
        override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
            true
        }
    }
}
