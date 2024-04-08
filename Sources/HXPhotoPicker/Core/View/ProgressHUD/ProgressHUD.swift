//
//  ProgressHUD.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/1/8.
//

import UIKit

final class ProgressHUD: UIView {
    enum Mode {
        case indicator
        case image
        case circleProgress
        case success
    }
    
    private var backgroundView: UIView!
    private var contentView: UIView!
    private var blurEffectView: UIVisualEffectView!
    private var indicatorView: UIView!
    private var textLb: UILabel!
    private var imageView: ProgressImageView!
    private var circleView: ProgressCircleView!
    private var tickView: ProgressImageView!
    
    private let indicatorType: IndicatorType
    private var finished: Bool = false
    private var showDelayTimer: Timer?
    private var hideDelayTimer: Timer?
    
    var progress: CGFloat = 0 {
        didSet {
            circleView.progress = progress
        }
    }
    var text: String? {
        didSet {
            textLb.text = text
            updateFrame()
        }
    }
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
    
    init(
        addedTo view: UIView,
        mode: Mode,
        indicatorType: IndicatorType = .system
    ) {
        self.indicatorType = indicatorType
        self.mode = mode
        super.init(frame: view.bounds)
        initView()
    }
    
    private func initView() {
        contentView = UIView()
        
        let effect: UIBlurEffect = .init(style: .dark)
        blurEffectView = .init(effect: effect)
        
        backgroundView = UIView()
        backgroundView.layer.cornerRadius = 5
        backgroundView.layer.masksToBounds = true
        backgroundView.alpha = 0
        backgroundView.addSubview(blurEffectView)
        
        switch indicatorType {
        case .circle:
            let indicatorView: ProgressIndefiniteView = .init(
                frame: CGRect(
                    origin: .zero,
                    size: CGSize(width: 32, height: 32)
                )
            )
            indicatorView.startAnimating()
            self.indicatorView = indicatorView
        case .circleJoin:
            let indicatorView: ProgressCricleJoinView = .init(
                frame: CGRect(
                    origin: .zero,
                    size: CGSize(width: 32, height: 32)
                )
            )
            indicatorView.startAnimating()
            self.indicatorView = indicatorView
        case .system:
            let indicatorView: UIActivityIndicatorView = .init(style: .whiteLarge)
            indicatorView.hidesWhenStopped = true
            indicatorView.startAnimating()
            self.indicatorView = indicatorView
        }
        
        textLb = UILabel()
        textLb.textColor = .white
        textLb.textAlignment = .center
        textLb.font = UIFont.systemFont(ofSize: 16)
        textLb.numberOfLines = 0
        
        imageView = ProgressImageView(
            frame: CGRect(
                x: 0, y: 0,
                width: 60, height: 60
            )
        )
        
        circleView = ProgressCircleView(
            frame: CGRect(
                origin: .zero,
                size: CGSize(width: 50, height: 50)
            )
        )
        
        tickView = ProgressImageView(
            tickFrame: CGRect(
                x: 0, y: 0,
                width: 80, height: 80
            )
        )
        
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
            let timer: Timer = .scheduledTimer(
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
    @objc
    private func handleShowTimer(timer: Timer) {
        showViews(animated: (timer.userInfo != nil))
    }
    
    private func showViews(animated: Bool) {
        if finished {
            return
        }
        if animated {
            backgroundView.transform = .init(scaleX: 0.75, y: 0.75)
            UIView.animate(
                withDuration: 0.25,
                delay: 0,
                usingSpringWithDamping: 0.6,
                initialSpringVelocity: 0,
                options: [.layoutSubviews]
            ) {
                self.backgroundView.alpha = 1
                self.backgroundView.transform = .identity
            }
        }else {
            backgroundView.alpha = 1
            backgroundView.transform = .identity
        }
    }
    
    func hide(
        withAnimated animated: Bool,
        afterDelay: TimeInterval
    ) {
        finished = true
        showDelayTimer?.invalidate()
        showDelayTimer = nil
        if afterDelay > 0 {
            let timer: Timer = .scheduledTimer(
                timeInterval: afterDelay,
                target: self,
                selector: #selector(handleHideTimer(timer:)),
                userInfo: animated,
                repeats: false
            )
            self.hideDelayTimer = timer
        }else {
            hideViews(animated: animated)
        }
    }
    
    @objc
    private func handleHideTimer(timer: Timer) {
        hideViews(animated: (timer.userInfo != nil))
        hideDelayTimer?.invalidate()
        hideDelayTimer = nil
    }
    
    private func hideViews(animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.2) {
                self.backgroundView.alpha = 0
                self.backgroundView.transform = .init(scaleX: 0.8, y: 0.8)
            } completion: { _ in
                self.stopAnimating()
                self.removeFromSuperview()
            }
        }else {
            backgroundView.alpha = 0
            removeFromSuperview()
            stopAnimating()
        }
    }
    
    private func updateFrame() {
        if text != nil {
            var textWidth: CGFloat = text!.width(ofFont: textLb.font, maxHeight: 15)
            if textWidth < 60 {
                textWidth = 60
            }
            if textWidth > width - 100 {
                textWidth = width - 100
            }
            let height: CGFloat = text!.height(ofFont: textLb.font, maxWidth: textWidth)
            textLb.size = CGSize(width: textWidth, height: height)
        }
        var textMaxWidth: CGFloat = textLb.width + 60
        if textMaxWidth < 100 {
            textMaxWidth = 100
        }
        
        let centenrX: CGFloat = textMaxWidth / 2
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
    static func showLoading(
        addedTo view: UIView?,
        text: String? = nil,
        afterDelay: TimeInterval = 0,
        animated: Bool = true,
        indicatorType: IndicatorType? = nil
    ) -> ProgressHUD? {
        guard let view = view else { return nil }
        let type: IndicatorType
        if let indicatorType = indicatorType {
            type = indicatorType
        }else {
            type = PhotoManager.shared.indicatorType
        }
        let progressView: ProgressHUD = .init(
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
    
    static func showWarning(
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
    
    static func showWarning(
        addedTo view: UIView?,
        text: String?,
        afterDelay: TimeInterval,
        animated: Bool
    ) {
        guard let view = view else { return }
        let progressView: ProgressHUD = .init(
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
    static func showProgress(
        addedTo view: UIView?,
        progress: CGFloat = 0,
        text: String? = nil,
        animated: Bool
    ) -> ProgressHUD? {
        guard let view = view else { return nil}
        let progressView: ProgressHUD = .init(
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
    static func showSuccess(
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
    static func showSuccess(
        addedTo view: UIView?,
        text: String?,
        afterDelay: TimeInterval,
        animated: Bool
    ) {
        guard let view = view else { return }
        let progressView: ProgressHUD = .init(
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
    
    static func hide(
        forView view: UIView?,
        animated: Bool = true
    ) {
        hide(
            forView: view,
            animated: animated,
            afterDelay: 0
        )
    }
    
    static func hide(
        forView view: UIView?,
        animated: Bool,
        afterDelay: TimeInterval
    ) {
        guard let view = view else { return }
        for case let subView as ProgressHUD in view.subviews {
            subView.hide(
                withAnimated: animated,
                afterDelay: afterDelay
            )
        }
    }
    
    private func startAnimating() {
        if let indefiniteView = indicatorView as? ProgressIndefiniteView {
            indefiniteView.startAnimating()
        }else if let indefiniteView = indicatorView as? UIActivityIndicatorView {
            indefiniteView.startAnimating()
        }else if let indefiniteView = indicatorView as? ProgressCricleJoinView {
            indefiniteView.startAnimating()
        }
        
    }
    private func stopAnimating() {
        if let indefiniteView = indicatorView as? ProgressIndefiniteView {
            indefiniteView.stopAnimating()
        }else if let indefiniteView = indicatorView as? UIActivityIndicatorView {
            indefiniteView.stopAnimating()
        }else if let indefiniteView = indicatorView as? ProgressCricleJoinView {
            indefiniteView.stopAnimating()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let superRect: CGRect
        if let superBounds = superview?.bounds {
            superRect = superBounds
        }else {
            superRect = frame
        }
        if !frame.equalTo(superRect) {
            frame = superRect
            updateFrame()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
