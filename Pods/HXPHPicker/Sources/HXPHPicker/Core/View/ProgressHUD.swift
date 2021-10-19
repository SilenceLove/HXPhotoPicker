//
//  ProgressHUD.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/8.
//

import UIKit

extension ProgressHUD {
    enum Mode {
        case indicator
        case image
        case circleProgress
        case success
    }
}

final class ProgressHUD: UIView {
    var mode: Mode {
        didSet {
            if mode == oldValue {
                return
            }
            switch oldValue {
            case .indicator:
                indicatorView.removeFromSuperview()
            case .image:
                imageView.removeFromSuperview()
            case .success:
                tickView.removeFromSuperview()
            case .circleProgress:
                circleView.removeFromSuperview()
            }
            if mode == .indicator {
                contentView.addSubview(indicatorView)
            }else if mode == .image {
                contentView.addSubview(imageView)
            }else if mode == .success {
                contentView.addSubview(tickView)
            }else if mode == .circleProgress {
                contentView.addSubview(circleView)
            }
            updateFrame()
        }
    }
    
    private lazy var backgroundView: UIView = {
        let backgroundView = UIView.init()
        backgroundView.layer.cornerRadius = 5
        backgroundView.layer.masksToBounds = true
        backgroundView.alpha = 0
        backgroundView.addSubview(blurEffectView)
        return backgroundView
    }()
    
    private lazy var contentView: UIView = {
        let contentView = UIView.init()
        return contentView
    }()
    
    private lazy var blurEffectView: UIVisualEffectView = {
        let effect = UIBlurEffect.init(style: .dark)
        let blurEffectView = UIVisualEffectView(effect: effect)
        return blurEffectView
    }()
    
    private lazy var indicatorView: UIView = {
        if indicatorType == .circle {
            let indicatorView = ProgressIndefiniteView(
                frame: CGRect(
                    origin: .zero,
                    size: CGSize(width: 40, height: 40)
                )
            )
            indicatorView.startAnimating()
            return indicatorView
        }else {
            let indicatorView = UIActivityIndicatorView(style: .whiteLarge)
            indicatorView.hidesWhenStopped = true
            indicatorView.startAnimating()
            return indicatorView
        }
    }()
    
    private lazy var textLb: UILabel = {
        let textLb = UILabel.init()
        textLb.textColor = .white
        textLb.textAlignment = .center
        textLb.font = UIFont.systemFont(ofSize: 16)
        textLb.numberOfLines = 0
        return textLb
    }()
    
    private lazy var imageView: ProgressImageView = {
        let imageView = ProgressImageView(
            frame: CGRect(
                x: 0, y: 0,
                width: 60, height: 60
            )
        )
        return imageView
    }()
    var progress: CGFloat = 0 {
        didSet {
            circleView.progress = progress
        }
    }
    private lazy var circleView: ProgressCircleView = {
        let view = ProgressCircleView(
            frame: CGRect(
                origin: .zero,
                size: CGSize(width: 50, height: 50)
            )
        )
        return view
    }()
    
    lazy var tickView: ProgressImageView = {
        let tickView = ProgressImageView(
            tickFrame: CGRect(
                x: 0, y: 0,
                width: 80, height: 80
            )
        )
        return tickView
    }()
    
    /// 加载指示器类型
    let indicatorType: BaseConfiguration.IndicatorType
    
    var text: String? {
        didSet {
            textLb.text = text
            updateFrame()
        }
    }
    var finished: Bool = false
    var showDelayTimer: Timer?
    var hideDelayTimer: Timer?
    
    init(
        addedTo view: UIView,
        mode: Mode,
        indicatorType: BaseConfiguration.IndicatorType = .system
    ) {
        self.indicatorType = indicatorType
        self.mode = mode
        super.init(frame: view.bounds)
        initView()
    }
    private func initView() {
        addSubview(backgroundView)
        contentView.addSubview(textLb)
        if mode == .indicator {
            contentView.addSubview(indicatorView)
        }else if mode == .image {
            contentView.addSubview(imageView)
        }else if mode == .success {
            contentView.addSubview(tickView)
        }else if mode == .circleProgress {
            contentView.addSubview(circleView)
        }
        backgroundView.addSubview(contentView)
        
    }
    
    private func showHUD(
        text: String?,
        animated: Bool,
        afterDelay: TimeInterval
    ) {
        self.text = text
        if afterDelay > 0 {
            let timer = Timer.scheduledTimer(
                timeInterval: afterDelay,
                target: self,
                selector: #selector(handleShowTimer(timer:)),
                userInfo: animated,
                repeats: false
            )
            showDelayTimer = timer
        }else {
            showViews(animated: animated)
        }
    }
    @objc func handleShowTimer(timer: Timer) {
        showViews(animated: (timer.userInfo != nil))
    }
    private func showViews(animated: Bool) {
        if finished {
            return
        }
        if animated {
            UIView.animate(withDuration: 0.25) {
                self.backgroundView.alpha = 1
            }
        }else {
            self.backgroundView.alpha = 1
        }
    }
    func hide(
        withAnimated animated: Bool,
        afterDelay: TimeInterval
    ) {
        finished = true
        self.showDelayTimer?.invalidate()
        if afterDelay > 0 {
            let timer = Timer(
                timeInterval: afterDelay,
                target: self,
                selector: #selector(handleHideTimer(timer:)),
                userInfo: animated,
                repeats: false
            )
            RunLoop.current.add(timer, forMode: RunLoop.Mode.common)
            self.hideDelayTimer = timer
        }else {
            hideViews(animated: animated)
        }
    }
    @objc func handleHideTimer(timer: Timer) {
        hideViews(animated: (timer.userInfo != nil))
    }
    func hideViews(animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.25) {
                self.backgroundView.alpha = 0
            } completion: { (finished) in
                self.indicatorView._stopAnimating()
                self.removeFromSuperview()
            }
        }else {
            backgroundView.alpha = 0
            removeFromSuperview()
            indicatorView._stopAnimating()
        }
    }
    private func updateFrame() {
        if text != nil {
            var textWidth = text!.width(ofFont: textLb.font, maxHeight: 15)
            if textWidth < 60 {
                textWidth = 60
            }
            if textWidth > width - 100 {
                textWidth = width - 100
            }
            let height = text!.height(ofFont: textLb.font, maxWidth: textWidth)
            textLb.size = CGSize(width: textWidth, height: height)
        }
        var textMaxWidth = textLb.width + 60
        if textMaxWidth < 100 {
            textMaxWidth = 100
        }
        
        let centenrX = textMaxWidth / 2
        textLb.centerX = centenrX
        if mode == .indicator {
            indicatorView.centerX = centenrX
            if text != nil {
                textLb.y = indicatorView.frame.maxY + 12
            }else {
                textLb.y = indicatorView.frame.maxY
            }
        }else if mode == .image {
            imageView.centerX = centenrX
            if text != nil {
                textLb.y = imageView.frame.maxY + 15
            }else {
                textLb.y = imageView.frame.maxY
            }
        }else if mode == .circleProgress {
            circleView.centerX = centenrX
            if text != nil {
                textLb.y = circleView.frame.maxY + 12
            }else {
                textLb.y = circleView.frame.maxY
            }
        }else if mode == .success {
            tickView.centerX = centenrX
            textLb.y = tickView.frame.maxY
        }
        
        contentView.height = textLb.frame.maxY
        contentView.width = textMaxWidth
        if contentView.height + 40 < 100 {
            backgroundView.height = 100
        }else {
            backgroundView.height = contentView.height + 40
        }
        if textMaxWidth < backgroundView.height {
            backgroundView.width = backgroundView.height
        }else {
            backgroundView.width = textMaxWidth
        }
        contentView.center = CGPoint(x: backgroundView.width * 0.5, y: backgroundView.height * 0.5)
        backgroundView.center = CGPoint(x: width * 0.5, y: height * 0.5)
        blurEffectView.frame = backgroundView.bounds
    }
    @discardableResult
    class func showLoading(
        addedTo view: UIView?,
        animated: Bool
    ) -> ProgressHUD? {
        showLoading(
            addedTo: view,
            text: nil,
            animated: animated
        )
    }
    @discardableResult
    class func showLoading(
        addedTo view: UIView?,
        afterDelay: TimeInterval,
        animated: Bool
    ) -> ProgressHUD? {
        showLoading(
            addedTo: view,
            text: nil,
            afterDelay: afterDelay,
            animated: animated
        )
    }
    @discardableResult
    class func showLoading(
        addedTo view: UIView?,
        text: String?,
        animated: Bool
    ) -> ProgressHUD? {
        showLoading(
            addedTo: view,
            text: text,
            afterDelay: 0,
            animated: animated
        )
    }
    @discardableResult
    class func showLoading(
        addedTo view: UIView?,
        text: String?,
        afterDelay: TimeInterval ,
        animated: Bool,
        indicatorType: BaseConfiguration.IndicatorType? = nil
    ) -> ProgressHUD? {
        guard let view = view else { return nil }
        let type: BaseConfiguration.IndicatorType
        if let indicatorType = indicatorType {
            type = indicatorType
        }else {
            type = PhotoManager.shared.indicatorType
        }
        let progressView = ProgressHUD(
            addedTo: view,
            mode: .indicator,
            indicatorType: type
        )
        progressView.showHUD(
            text: text,
            animated: animated,
            afterDelay: afterDelay
        )
        view.addSubview(progressView)
        return progressView
    }
    class func showWarning(
        addedTo view: UIView?,
        text: String?,
        animated: Bool,
        delayHide: TimeInterval
    ) {
        self.showWarning(
            addedTo: view,
            text: text,
            afterDelay: 0,
            animated: animated
        )
        self.hide(
            forView: view,
            animated: animated,
            afterDelay: delayHide
        )
    }
    class func showWarning(
        addedTo view: UIView?,
        text: String?,
        afterDelay: TimeInterval,
        animated: Bool
    ) {
        guard let view = view else { return }
        let progressView = ProgressHUD(
            addedTo: view,
            mode: .image
        )
        progressView.showHUD(
            text: text,
            animated: animated,
            afterDelay: afterDelay
        )
        view.addSubview(progressView)
    }
    class func showProgress(
        addedTo view: UIView?,
        progress: CGFloat = 0,
        text: String? = nil,
        animated: Bool
    ) -> ProgressHUD? {
        guard let view = view else { return nil}
        let progressView = ProgressHUD(
            addedTo: view,
            mode: .circleProgress
        )
        progressView.showHUD(
            text: text,
            animated: animated,
            afterDelay: 0
        )
        view.addSubview(progressView)
        return progressView
    }
    class func showSuccess(
        addedTo view: UIView?,
        text: String?,
        animated: Bool,
        delayHide: TimeInterval
    ) {
        self.showSuccess(
            addedTo: view,
            text: text,
            afterDelay: 0,
            animated: animated
        )
        self.hide(
            forView: view,
            animated: animated,
            afterDelay: delayHide
        )
    }
    class func showSuccess(
        addedTo view: UIView?,
        text: String?,
        afterDelay: TimeInterval,
        animated: Bool
    ) {
        guard let view = view else { return }
        let progressView = ProgressHUD(
            addedTo: view,
            mode: .success
        )
        progressView.showHUD(
            text: text,
            animated: animated,
            afterDelay: afterDelay
        )
        view.addSubview(progressView)
    }
    
    class func hide(
        forView view: UIView?,
        animated: Bool
    ) {
        hide(
            forView: view,
            animated: animated,
            afterDelay: 0
        )
    }
    
    class func hide(
        forView view: UIView?,
        animated: Bool,
        afterDelay: TimeInterval
    ) {
        guard let view = view else { return }
        for subView in view.subviews where
            subView is ProgressHUD {
            (subView as! ProgressHUD).hide(
                withAnimated: animated,
                afterDelay: afterDelay
            )
        }
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        if !frame.equalTo(superview?.bounds ?? frame) {
            frame = superview?.bounds ?? frame
            updateFrame()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ProgressIndefiniteView: UIView {
    
    lazy var circleLayer: CAShapeLayer = {
        let circleLayer = CAShapeLayer()
        circleLayer.frame = bounds
        circleLayer.contentsScale = UIScreen.main.scale
        circleLayer.strokeColor = UIColor.white.cgColor
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.lineCap = .round
        circleLayer.lineJoin = .bevel
        circleLayer.lineWidth = lineWidth
        let path = UIBezierPath(
            arcCenter: CGPoint(x: width * 0.5, y: height * 0.5),
            radius: width * 0.5 - lineWidth * 0.5,
            startAngle: -CGFloat.pi * 0.5,
            endAngle: -CGFloat.pi * 0.5 + CGFloat.pi * 4,
            clockwise: true
        )
        circleLayer.path = path.cgPath
        circleLayer.mask = maskLayer
        return circleLayer
    }()
    
    lazy var maskLayer: CALayer = {
        let maskLayer = CALayer()
        maskLayer.contentsScale = UIScreen.main.scale
        maskLayer.frame = bounds
        let topLayer = CAGradientLayer.init()
        topLayer.frame = CGRect(x: width * 0.5, y: 0, width: width * 0.5, height: height)
        topLayer.colors = [
            UIColor.white.withAlphaComponent(0.8).cgColor,
            UIColor.white.withAlphaComponent(0.4).cgColor
        ]
        topLayer.startPoint = CGPoint(x: 0, y: 0)
        topLayer.endPoint = CGPoint(x: 0, y: 1)
        maskLayer.addSublayer(topLayer)
        let bottomLayer = CAGradientLayer.init()
        bottomLayer.frame = CGRect(x: 0, y: 0, width: width * 0.5, height: height)
        bottomLayer.colors = [
            UIColor.white.withAlphaComponent(0.4).cgColor,
            UIColor.white.withAlphaComponent(0).cgColor
        ]
        bottomLayer.startPoint = CGPoint(x: 0, y: 1)
        bottomLayer.endPoint = CGPoint(x: 0, y: 0)
        maskLayer.addSublayer(bottomLayer)
        return maskLayer
    }()
    var isAnimating: Bool = false
    let lineWidth: CGFloat
    
    init(frame: CGRect, lineWidth: CGFloat = 3.5) {
        self.lineWidth = lineWidth
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if newSuperview != nil {
            layer.addSublayer(circleLayer)
        }else {
            circleLayer.removeFromSuperlayer()
            _stopAnimating()
        }
    }
    func startAnimating() {
        if isAnimating { return }
        isAnimating = true
        let duration: CFTimeInterval = 0.4
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.fromValue = 0
        animation.toValue = CGFloat.pi * 2
        animation.duration = duration
        animation.repeatCount = MAXFLOAT
        animation.isRemovedOnCompletion = false
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        circleLayer.mask?.add(animation, forKey: nil)

        let animationGroup = CAAnimationGroup()
        animationGroup.duration = duration
        animationGroup.repeatCount = MAXFLOAT
        animationGroup.isRemovedOnCompletion = false
        animationGroup.timingFunction = CAMediaTimingFunction(name: .linear)

        let strokeStartAnimation = CABasicAnimation(keyPath: "strokeStart")
        strokeStartAnimation.fromValue = 0.015
        strokeStartAnimation.toValue = 0.515

        let strokeEndAnimation = CABasicAnimation(keyPath: "strokeEnd")
        strokeEndAnimation.fromValue = 0.485
        strokeEndAnimation.toValue = 0.985

        animationGroup.animations = [strokeStartAnimation, strokeEndAnimation]
        circleLayer.add(animationGroup, forKey: nil)
    }
    func stopAnimating() {
        if !isAnimating { return }
        maskLayer.removeAllAnimations()
        isAnimating = false
    }
}

fileprivate extension UIView {
    func _startAnimating() {
        if let indefiniteView = self as? ProgressIndefiniteView {
            indefiniteView.startAnimating()
        }else if let indefiniteView = self as? UIActivityIndicatorView {
            indefiniteView.startAnimating()
        }
    }
    func _stopAnimating() {
        if let indefiniteView = self as? ProgressIndefiniteView {
            indefiniteView.stopAnimating()
        }else if let indefiniteView = self as? UIActivityIndicatorView {
            indefiniteView.stopAnimating()
        }
    }
}
