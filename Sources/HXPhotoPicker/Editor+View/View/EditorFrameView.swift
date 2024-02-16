//
//  EditorFrameView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2022/11/12.
//

import UIKit

protocol EditorFrameViewDelegate: AnyObject {
    func frameView(beganChanged frameView: EditorFrameView, _ rect: CGRect)
    func frameView(didChanged frameView: EditorFrameView, _ rect: CGRect)
    func frameView(endChanged frameView: EditorFrameView, _ rect: CGRect)
    func frameView(_ frameView: EditorFrameView, didChangedPlayTime time: CGFloat, for state: VideoControlEvent)
    func frameView(_ frameView: EditorFrameView, didPlayButtonClick isSelected: Bool)
}

class EditorFrameView: UIView {
    weak var delegate: EditorFrameViewDelegate?
    
    var maskBgView: EditorMaskView!
    var customMaskView: EditorMaskView!
    var maskLinesView: EditorMaskView!
    var controlView: EditorControlView!
    var videoSliderView: VideoPlaySliderView!
    
    var state: EditorView.State = .normal
    var maskBgShowTimer: Timer?
    var controlTimer: Timer?
    var inControlTimer: Bool = false
    
    var maskType: EditorView.MaskType {
        get {
            maskBgView.maskType
        }
        set {
            setMaskType(newValue, animated: false)
        }
    }
    func setMaskType(_ maskType: EditorView.MaskType, animated: Bool) {
        maskBgView.setMaskType(maskType, animated: animated)
        customMaskView.setMaskType(maskType, animated: animated)
    }
    
    var maskImage: UIImage? {
        get {
            customMaskView.tmpMaskImage
        }
        set {
            setMaskImage(newValue, animated: false)
        }
    }
    
    func setMaskImage(_ image: UIImage?, animated: Bool, completion: (() -> Void)? = nil) {
        let maskImage = image?.convertBlackImage()
        customMaskView.setMaskImage(maskImage, animated: animated, completion: completion)
        setRoundCrop(isRound: false, animated: animated)
    }
    
    var maskColor: UIColor? {
        didSet {
            maskBgView.maskColor = maskColor
            customMaskView.maskColor = maskColor
        }
    }
    
    var contentType: EditorContentViewType = .unknown
    
    init(maskColor: UIColor?) {
        self.maskColor = maskColor
        super.init(frame: .zero)
        initViews()
        addSubview(maskBgView)
        addSubview(customMaskView)
        addSubview(maskLinesView)
        addSubview(controlView)
        addSubview(videoSliderView)
    }
    
    private func initViews() {
        maskBgView = EditorMaskView(type: .mask, maskColor: maskColor)
        maskBgView.alpha = 0
        maskBgView.isHidden = true
        maskBgView.isUserInteractionEnabled = false
        
        customMaskView = EditorMaskView(type: .customMask, maskColor: maskColor)
        customMaskView.isUserInteractionEnabled = false
        
        maskLinesView = EditorMaskView(type: .frame)
        maskLinesView.isUserInteractionEnabled = false
        maskLinesView.alpha = 0
        maskLinesView.isHidden = true
        
        controlView = EditorControlView()
        controlView.delegate = self
        controlView.isUserInteractionEnabled = false
        
        videoSliderView = VideoPlaySliderView(style: .editor)
        videoSliderView.isHidden = true
        videoSliderView.alpha = 0
        videoSliderView.delegate = self
    }
    
    
    func setMaskBgFrame(_ rect: CGRect, insets: UIEdgeInsets) {
        maskBgView.maskInsets = insets
        maskBgView.frame = rect
        
        setCustomMaskFrame(rect, insets: insets)
    }
    
    func setCustomMaskFrame(_ rect: CGRect, insets: UIEdgeInsets) {
        customMaskView.maskInsets = insets
        customMaskView.frame = rect
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if videoSliderView.frame.contains(point), videoSliderView.alpha == 1 {
            return super.hitTest(point, with: event)
        }
        if !controlView.isUserInteractionEnabled {
            return nil
        }
        let view = super.hitTest(point, with: event)
        let controlPoint = convert(point, to: controlView)
        if let cView = controlView.canUserEnabled(controlPoint) {
            if let view = view {
                return view
            }
            return cView
        }
        return nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        maskLinesView.frame = bounds
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension EditorFrameView {
    
    var isFixedRatio: Bool {
        get {
            controlView.factor.fixedRatio
        }
        set {
            controlView.factor.fixedRatio = newValue
        }
    }
    var aspectRatio: CGSize {
        get {
            controlView.factor.aspectRatio
        }
        set {
            controlView.factor.aspectRatio = newValue
        }
    }
    
    var isControlPanning: Bool {
        controlView.panning
    }
    var isControlEnable: Bool {
        get { controlView.isUserInteractionEnabled }
        set { controlView.isUserInteractionEnabled = newValue }
    }
    
    var maxControlRect: CGRect {
        get { controlView.maxImageresizerFrame }
        set { controlView.maxImageresizerFrame = newValue }
    }
    
    var isHide: Bool {
        maskBgView.isHidden
    }
    
    func show(isLines: Bool = true, isMaskBg: Bool = true, _ animated: Bool) {
        if isMaskBg {
            maskBgView.isHidden = false
        }
        if isLines {
            maskLinesView.isHidden = false
        }
        if animated {
            UIView.animate {
                if isMaskBg {
                    self.maskBgView.alpha = 1
                }
                if isLines {
                    self.maskLinesView.alpha = 1
                }
            }
        }else {
            if isMaskBg {
                maskBgView.alpha = 1
            }
            if isLines {
                maskLinesView.alpha = 1
            }
        }
    }
    
    func hide(isLines: Bool = true, isMaskBg: Bool = true, animated: Bool) {
        if animated {
            UIView.animate {
                if isLines {
                    self.maskLinesView.alpha = 0
                }
                if isMaskBg {
                    self.maskBgView.alpha = 0
                }
            } completion: { (isFinished) in
                if !isFinished { return }
                if isLines {
                    self.maskLinesView.isHidden = true
                }
                if isMaskBg {
                    self.maskBgView.isHidden = true
                }
            }
        }else {
            if isLines {
                maskLinesView.isHidden = true
                maskLinesView.alpha = 0
            }
            if isMaskBg {
                maskBgView.isHidden = true
                maskBgView.alpha = 0
            }
        }
    }
    
    func showLinesShadow() {
        maskLinesView.setShadows(true)
    }
    func hideLinesShadow() {
        maskLinesView.setShadows(false)
    }
    func showGridlinesLayer() {
        maskLinesView.showGridlinesLayer(true, animated: true)
    }
    func hideGridlinesLayer() {
        maskLinesView.showGridlinesLayer(false, animated: true)
    }
    func showGridGraylinesLayer(animated: Bool = true) {
        maskLinesView.showGridlinesLayer(true, animated: true)
        maskLinesView.showGridGraylinesView(animated: animated)
    }
    func hideGridGraylinesLayer() {
        maskLinesView.showGridlinesLayer(false, animated: true)
        maskLinesView.hideGridGraylinesView(animated: true)
    }
    
    func showBlackMask(animated: Bool = true, completion: (() -> Void)? = nil) {
        maskBgView.alpha = 1
        maskBgView.isHidden = false
        blackMask(
            isShow: true,
            animated: animated,
            completion: completion
        )
    }
    
    func blackMask(
        isShow: Bool,
        animated: Bool,
        completion: (() -> Void)? = nil
    ) {
        maskBgView.updateBlackMask(
            isShow: isShow,
            animated: animated,
            completion: completion
        )
    }
    
    func showImageMaskView(_ animated: Bool) {
        customMaskView.showImageMaskView(animated)
    }
    
    func hideImageMaskView(_ animated: Bool) {
        customMaskView.hideImageMaskView(animated)
    }
    
    func showCustomMaskView(_ animated: Bool) {
        if animated {
            UIView.animate {
                self.customMaskView.alpha = 1
            }
        }else {
            customMaskView.alpha = 1
        }
    }
    
    func hideCustomMaskView(_ animated: Bool) {
        if animated {
            UIView.animate {
                self.customMaskView.alpha = 0
            }
        }else {
            customMaskView.alpha = 0
        }
    }
    
    func updateFrame(to rect: CGRect, animated: Bool) {
        if rect.width.isNaN || rect.height.isNaN {
            return
        }
        controlView.frame = rect
        maskBgView.updateLayers(rect, animated)
        customMaskView.updateLayers(rect, animated)
        maskLinesView.updateLayers(rect, animated)
        updateVideoSlider(to: rect, animated: animated)
    }
    
    func updateVideoSlider(to rect: CGRect, animated: Bool) {
        let sliderRect: CGRect = .init(x: rect.minX + 10, y: rect.maxY - 50, width: rect.width - 20, height: 40)
        if videoSliderView.frame.equalTo(sliderRect) {
            return
        }
        if animated {
            UIView.animate {
                self.videoSliderView.frame = sliderRect
            }
        }else {
            videoSliderView.frame = sliderRect
        }
    }
    
    func showVideoSlider(_ animated: Bool) {
        if contentType != .video {
            return
        }
        if isRoundCrop {
            return
        }
        if !videoSliderView.isHidden && videoSliderView.alpha == 1 {
            return
        }
        videoSliderView.isHidden = false
        if animated {
            UIView.animate {
                self.videoSliderView.alpha = 1
            }
        }else {
            videoSliderView.alpha = 1
        }
    }
    
    func hideVideoSilder(_ animated: Bool) {
        if videoSliderView.isHidden && videoSliderView.alpha == 0 {
            return
        }
        if animated {
            UIView.animate {
                self.videoSliderView.alpha = 0
            } completion: {
                if $0 {
                    self.videoSliderView.isHidden = true
                }
            }
        }else {
            videoSliderView.alpha = 0
            videoSliderView.isHidden = true
        }
    }
    
    var imageSizeScale: CGSize {
        get {
            maskLinesView.imageSize
        }
        set {
            maskLinesView.imageSize = newValue
        }
    }
    
    var isRoundCrop: Bool {
        get {
            maskBgView.isRoundCrop
        }
        set {
            if newValue {
                hideVideoSilder(false)
            }
            maskBgView.isRoundCrop = newValue
            maskLinesView.isRoundCrop = newValue
        }
    }
    
    func setRoundCrop(isRound: Bool, animated: Bool) {
        if isRound {
            hideVideoSilder(animated)
        }
        maskBgView.updateRoundCrop(isRound: isRound, animated: animated)
        maskLinesView.updateRoundCrop(isRound: isRound, animated: animated)
    }
    
    var isShowScaleSize: Bool {
        get {
            maskLinesView.isShowScaleSize
        }
        set {
            maskLinesView.isShowScaleSize = newValue
        }
    }
    
    func startShowMaskBgTimer() {
        maskBgShowTimer?.invalidate()
        maskBgShowTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [weak self] _ in
            guard let self = self else {
                return
            }
            self.showMaskBgView()
            if self.state == .edit {
                self.showVideoSlider(true)
            }
        }
    }
    
    var maskBgViewIsHidden: Bool {
        maskBgView.maskViewIsHidden
    }
    
    func hideMaskBgView(animated: Bool = true) {
        stopShowMaskBgTimer()
        if maskBgView.maskViewIsHidden {
            return
        }
        maskBgView.layer.removeAllAnimations()
        maskBgView.hideMaskView(animated)
        if maskImage != nil {
            customMaskView.layer.removeAllAnimations()
            customMaskView.hideMaskView(animated)
        }else {
            maskLinesView.showGridlinesLayer(true, animated: animated)
        }
        
    }
    
    func showMaskBgView(animated: Bool = true) {
        if !maskBgView.maskViewIsHidden {
            return
        }
        maskBgView.layer.removeAllAnimations()
        maskBgView.showMaskView(animated)
        if maskImage != nil {
            customMaskView.layer.removeAllAnimations()
            customMaskView.showMaskView(animated)
        }else {
            maskLinesView.showGridlinesLayer(false, animated: animated)
        }
    }
    
    func stopShowMaskBgTimer() {
        maskBgShowTimer?.invalidate()
        maskBgShowTimer = nil
    }
    
    func stopControlTimer() {
        controlTimer?.invalidate()
        controlTimer = nil
    }
    
    func startControlTimer() {
        controlTimer?.invalidate()
        controlTimer = Timer.scheduledTimer(
            withTimeInterval: 0.5,
            repeats: false
        ) { [weak self] _ in
            guard let self = self else { return }
//            self.showMaskBgView()
            self.stopControlTimer()
            self.delegate?.frameView(endChanged: self, self.controlView.frame)
        }
        inControlTimer = true
    }
    
    func stopTimer() {
        stopControlTimer()
        stopShowMaskBgTimer()
        inControlTimer = false
    }
}
