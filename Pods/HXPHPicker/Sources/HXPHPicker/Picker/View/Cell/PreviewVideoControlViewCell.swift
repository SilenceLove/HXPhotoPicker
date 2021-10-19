//
//  PreviewVideoControlViewCell.swift
//  HXPHPicker
//
//  Created by Slience on 2021/6/30.
//

import UIKit

public class PreviewVideoControlViewCell: PreviewVideoViewCell, PreviewVideoSliderViewDelegate {
    
    lazy var maskLayer: CAGradientLayer = {
        let layer = PhotoTools.getGradientShadowLayer(false)
        return layer
    }()
    lazy var sliderView: PreviewVideoSliderView = {
        let view = PreviewVideoSliderView()
        view.delegate = self
        view.alpha = 0
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.addSublayer(maskLayer)
        contentView.addSubview(sliderView)
    }
    
    public override func videoReadyToPlay(duration: CGFloat) {
        sliderView.videoDuration = duration
    }
    public override func videoDidChangedBuffer(duration: CGFloat) {
        sliderView.bufferDuration = duration
    }
    
    public override func videoDidChangedPlayTime(duration: CGFloat, isAnimation: Bool) {
        sliderView.setPlayDuration(duration, isAnimation: isAnimation)
    }
    public override func videoDidPlay() {
        sliderView.isPlaying = true
    }
    public override func videoDidPause() {
        sliderView.isPlaying = false
    }
    public override func showToolView() {
        if sliderView.alpha == 0 {
            sliderView.isHidden = false
            UIView.animate(withDuration: 0.15) {
                self.sliderView.alpha = 1
            }
        }
        showMask()
    }
    public override func hideToolView() {
        if sliderView.alpha == 1 {
            UIView.animate(withDuration: 0.15) {
                self.sliderView.alpha = 0
            } completion: { isFinished in
                if isFinished && self.sliderView.alpha == 0 {
                    self.sliderView.isHidden = true
                }
            }
        }
        hideMask()
    }
    public override func showMask() {
        if maskLayer.isHidden {
            maskLayer.isHidden = false
        }
    }
    public override func hideMask() {
        if !maskLayer.isHidden {
            maskLayer.isHidden = true
        }
    }
    
    func videoSliderView(
        _ videoSliderView: PreviewVideoSliderView,
        didChangedPlayDuration duration: CGFloat,
        state: SliderView.Event
    ) {
        seek(to: TimeInterval(duration), isPlay: state == .touchUpInSide)
    }
    func videoSliderView(_ videoSliderView: PreviewVideoSliderView, didPlayButtonClick isSelected: Bool) {
        if isSelected {
            playVideo()
        }else {
            pauseVideo()
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        sliderView.frame = CGRect(
            x: 0,
            y: height - 50 - UIDevice.bottomMargin,
            width: width,
            height: 50 + UIDevice.bottomMargin
        )
        
        maskLayer.frame = CGRect(x: 0, y: sliderView.y - 20, width: width, height: sliderView.height + 20)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

protocol PreviewVideoSliderViewDelegate: AnyObject {
    func videoSliderView(
        _ videoSliderView: PreviewVideoSliderView,
        didChangedPlayDuration duration: CGFloat,
        state: SliderView.Event
    )
    func videoSliderView(
        _ videoSliderView: PreviewVideoSliderView,
        didPlayButtonClick isSelected: Bool
    )
}

class PreviewVideoSliderView: UIView, SliderViewDelegate {
    
    weak var delegate: PreviewVideoSliderViewDelegate?
    
    lazy var playButton: PlayButton = {
        let button = PlayButton()
        button.size = CGSize(width: 30, height: 40)
        button.addTarget(self, action: #selector(didPlayButton(button:)), for: .touchUpInside)
        return button
    }()
    
    @objc func didPlayButton(button: PlayButton) {
        button.isSelected = !button.isSelected
        delegate?.videoSliderView(self, didPlayButtonClick: button.isSelected)
    }
    
    lazy var sliderView: SliderView = {
        let view = SliderView()
        view.delegate = self
        return view
    }()
    
    lazy var currentTimeLb: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 65, height: 30))
        label.text = "--:--"
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 15)
        return label
    }()
    
    lazy var totalTimeLb: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 65, height: 30))
        label.text = "--:--"
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 15)
        return label
    }()
    
    var videoDuration: CGFloat = 0 {
        didSet {
            let totalVideoTime = PhotoTools.transformVideoDurationToString(duration: TimeInterval(videoDuration))
            totalTimeLb.text = totalVideoTime
            currentTimeLb.text = "00:00"
        }
    }
    
    var playDuration: CGFloat = 0
    
    func setPlayDuration(_ duration: CGFloat, isAnimation: Bool) {
        playDuration = duration
        let currentPlayTime = PhotoTools.transformVideoDurationToString(duration: TimeInterval(playDuration))
        currentTimeLb.text = currentPlayTime
        let value = videoDuration == 0 ? 0 : playDuration / videoDuration
        sliderView.setValue(value, isAnimation: isAnimation)
    }
    
    var bufferDuration: CGFloat = 0 {
        didSet {
            sliderView.bufferValue = videoDuration == 0 ? 0 : bufferDuration / videoDuration
        }
    }
    
    var isPlaying: Bool = false {
        didSet {
            if playButton.isSelected == isPlaying {
                return
            }
            playButton.isSelected = isPlaying
        }
    }
    
    init() {
        super.init(frame: .zero)
        addSubview(playButton)
        addSubview(sliderView)
        addSubview(currentTimeLb)
        addSubview(totalTimeLb)
    }
    
    func sliderView(_ sliderView: SliderView, didChangedValue value: CGFloat, state: SliderView.Event) {
        delegate?.videoSliderView(self, didChangedPlayDuration: videoDuration * value, state: state)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playButton.x = 15 + UIDevice.leftMargin
        playButton.centerY = 25
        
        currentTimeLb.x = playButton.frame.maxX + 5
        currentTimeLb.centerY = playButton.centerY
        
        totalTimeLb.x = width - totalTimeLb.width - 15 - UIDevice.rightMargin
        totalTimeLb.centerY = currentTimeLb.centerY
        
        sliderView.x = currentTimeLb.frame.maxX + 5
        sliderView.width = totalTimeLb.x - 5 - sliderView.x
        sliderView.height = height
        sliderView.centerY = totalTimeLb.centerY
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class PlayButton: UIControl {
    lazy var playLayer: CAShapeLayer = {
        let playLayer = CAShapeLayer()
        playLayer.fillColor = UIColor.white.cgColor
        playLayer.strokeColor = UIColor.white.cgColor
        playLayer.lineCap = .round
        playLayer.lineJoin = .round
        playLayer.contentsScale = UIScreen.main.scale
        return playLayer
    }()
    
    override var isSelected: Bool {
        didSet {
            updatePlay()
        }
    }
    
    init() {
        super.init(frame: .zero)
        layer.addSublayer(playLayer)
    }
    
    func updatePlay() {
        let path = UIBezierPath()
        let widthMargin: CGFloat = 13
        let heightMargin: CGFloat = 18
        if isSelected {
            let leftLineStartPoint = CGPoint(x: width * 0.5 - widthMargin * 0.5, y: height * 0.5 - heightMargin * 0.5)
            path.move(to: leftLineStartPoint)
            path.addLine(to: .init(x: leftLineStartPoint.x + 3, y: leftLineStartPoint.y))
            path.addLine(to: .init(x: leftLineStartPoint.x + 3, y: leftLineStartPoint.y + heightMargin))
            path.addLine(to: .init(x: leftLineStartPoint.x, y: leftLineStartPoint.y + heightMargin))
            path.close()
            
            let rightLineStartPoint = CGPoint(x: width * 0.5 + widthMargin * 0.5, y: height * 0.5 - heightMargin * 0.5)
            path.move(to: rightLineStartPoint)
            path.addLine(to: .init(x: rightLineStartPoint.x - 3, y: rightLineStartPoint.y))
            path.addLine(to: .init(x: rightLineStartPoint.x - 3, y: rightLineStartPoint.y + heightMargin))
            path.addLine(to: .init(x: rightLineStartPoint.x, y: rightLineStartPoint.y + heightMargin))
            path.close()
        }else {
            let startPoint = CGPoint(x: width * 0.5 + widthMargin * 0.5, y: height * 0.5)
            path.move(to: startPoint)
            path.addLine(to: .init(x: startPoint.x - widthMargin, y: startPoint.y + heightMargin * 0.5))
            path.addLine(to: .init(x: startPoint.x - widthMargin, y: startPoint.y - heightMargin * 0.5))
            path.close()
        }
        let animation = getAnimation(playLayer.path, path.cgPath, 0.25)
        playLayer.add(animation, forKey: nil)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playLayer.path = path.cgPath
        CATransaction.commit()
    }
    
    func getAnimation(
        _ fromValue: Any?,
        _ toValue: Any?,
        _ duration: TimeInterval
    ) -> CABasicAnimation {
        let animation = CABasicAnimation.init(keyPath: "path")
        animation.fromValue = fromValue
        animation.toValue = toValue
        animation.duration = duration
        animation.fillMode = .backwards
        animation.timingFunction = .init(name: CAMediaTimingFunctionName.linear)
        return animation
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playLayer.frame = bounds
        updatePlay()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

protocol SliderViewDelegate: AnyObject {
    func sliderView(
        _ sliderView: SliderView,
        didChangedValue value: CGFloat,
        state: SliderView.Event
    )
}

class SliderView: UIView {
    
    enum Event {
        case touchDown
        case touchUpInSide
        case Changed
    }
    weak var delegate: SliderViewDelegate?
    lazy var panGR: PhotoPanGestureRecognizer = {
        let pan = PhotoPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerClick(pan:)))
        return pan
    }()
    lazy var thumbView: UIImageView = {
        let imageSize = CGSize(width: 18, height: 18)
        let view = UIImageView(image: .image(for: .white, havingSize: imageSize, radius: 9))
        view.size = imageSize
        return view
    }()
    var value: CGFloat = 0
    var thumbViewFrame: CGRect = .zero
    
    @objc func panGestureRecognizerClick(pan: UIPanGestureRecognizer) {
        switch pan.state {
        case .began:
            let point = pan.location(in: self)
            let rect = CGRect(
                x: thumbView.x - 20,
                y: thumbView.y - 20,
                width: thumbView.width + 40,
                height: thumbView.height + 40
            )
            if !rect.contains(point) {
                pan.isEnabled = false
                pan.isEnabled = true
                return
            }
            if thumbViewFrame.equalTo(.zero) {
                thumbViewFrame = thumbView.frame
            }
            delegate?.sliderView(self, didChangedValue: value, state: .touchDown)
        case .changed:
            let specifiedPoint = pan.translation(in: self)
            var rect = thumbViewFrame
            rect.origin.x += specifiedPoint.x
            if rect.midX < 5 {
                rect.origin.x = -thumbView.width * 0.5 + 5
            }
            if rect.midX > width - 5 {
                rect.origin.x = width - 5 - thumbView.width * 0.5
            }
            value = (rect.midX - 5) / (width - 10)
            trackView.width = width * value
            thumbView.frame = rect
            delegate?.sliderView(self, didChangedValue: value, state: .Changed)
        case .cancelled, .ended, .failed:
            thumbViewFrame = .zero
            delegate?.sliderView(self, didChangedValue: value, state: .touchUpInSide)
        default:
            break
        }
    }
    
    lazy var trackView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 1
        return view
    }()
    
    lazy var progressView: UIView = {
        let view = UIView()
        view.backgroundColor = .white.withAlphaComponent(0.2)
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 1
        return view
    }()
    
    var bufferValue: CGFloat = 0 {
        didSet {
            bufferView.width = width * bufferValue
        }
    }
    
    lazy var bufferView: UIView = {
        let view = UIView()
        view.backgroundColor = .white.withAlphaComponent(0.4)
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 1
        return view
    }()
    
    init() {
        super.init(frame: .zero)
        addSubview(progressView)
        addSubview(bufferView)
        addSubview(trackView)
        addSubview(thumbView)
        addGestureRecognizer(panGR)
    }
    
    func setValue(
        _ value: CGFloat,
        isAnimation: Bool
    ) {
        switch panGR.state {
        case .began, .changed, .ended:
            return
        default:
            break
        }
        if value < 0 {
            self.value = 0
        }else if value > 1 {
            self.value = 1
        }else {
            self.value = value
        }
        let currentWidth = self.value * width
        if isAnimation {
            UIView.animate(
                withDuration: 0.1,
                delay: 0,
                options: [
                    .curveLinear,
                    .allowUserInteraction
                ]
            ) {
                self.thumbView.centerX = 5 + (self.width - 10) * self.value
                self.trackView.width = currentWidth
            }
        }else {
            thumbView.centerX = 5 + (width - 10) * value
            trackView.width = currentWidth
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        trackView.frame = CGRect(x: 0, y: (height - 3) * 0.5, width: width * value, height: 3)
        progressView.frame = CGRect(x: 0, y: (height - 3) * 0.5, width: width, height: 3)
        bufferView.frame = CGRect(x: 0, y: (height - 3) * 0.5, width: width * bufferValue, height: 3)
        thumbView.centerY = height * 0.5
        thumbView.centerX = 5 + (width - 10) * value
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
