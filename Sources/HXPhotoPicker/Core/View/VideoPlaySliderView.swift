//
//  VideoPlaySliderView.swift
//  HXPhotoPicker
//
//  Created by 洪欣 on 2023/5/4.
//

import UIKit

protocol VideoPlaySliderViewDelegate: AnyObject {
    func videoSliderView(
        _ videoSliderView: VideoPlaySliderView,
        didChangedPlayDuration duration: CGFloat,
        state: VideoControlEvent
    )
    func videoSliderView(
        _ videoSliderView: VideoPlaySliderView,
        didPlayButtonClick isSelected: Bool
    )
}

extension VideoPlaySliderViewDelegate {
    func videoSliderView(
        _ videoSliderView: VideoPlaySliderView,
        didChangedPlayDuration duration: CGFloat,
        state: VideoControlEvent
    ) { }
    func videoSliderView(
        _ videoSliderView: VideoPlaySliderView,
        didPlayButtonClick isSelected: Bool
    ) { }
}

public class VideoPlaySliderView: UIView, SliderViewDelegate {
    
    weak var delegate: VideoPlaySliderViewDelegate?
    
    lazy var playButton: PlayButton = {
        let button = PlayButton()
        button.size = CGSize(width: 30, height: 40)
        button.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didPlayButton)))
        return button
    }()
    
    @objc func didPlayButton() {
        playButton.isSelected = !playButton.isSelected
        delegate?.videoSliderView(self, didPlayButtonClick: playButton.isSelected)
    }
    
    lazy var sliderView: SliderView = {
        let view = SliderView(style)
        view.delegate = self
        return view
    }()
    
    lazy var currentTimeLb: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 65, height: 30))
        label.text = "--:--"
        label.textColor = .white
        label.font = .regularPingFang(ofSize: 15)
        label.layer.shadowColor = UIColor.black.withAlphaComponent(0.7).cgColor
        label.layer.shadowOpacity = 0.5
        label.layer.shadowOffset = .init(width: -1, height: 1)
        if style == .editor {
            label.alpha = 0
            label.textAlignment = .left
        }else {
            label.textAlignment = .center
        }
        return label
    }()
    
    lazy var totalTimeLb: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 65, height: 30))
        label.text = "--:--"
        label.textColor = .white
        label.font = .regularPingFang(ofSize: 15)
        label.layer.shadowColor = UIColor.black.withAlphaComponent(0.7).cgColor
        label.layer.shadowOpacity = 0.5
        label.layer.shadowOffset = .init(width: -1, height: 1)
        if style == .editor {
            label.alpha = 0
            label.textAlignment = .right
        }else {
            label.textAlignment = .center
        }
        return label
    }()
    
    var videoDuration: CGFloat = 0 {
        didSet {
            let totalVideoTime = PhotoTools.transformVideoDurationToString(duration: TimeInterval(videoDuration))
            totalTimeLb.text = totalVideoTime
            currentTimeLb.text = "00:00"
            if style == .editor {
                currentTimeLb.width = currentTimeLb.textWidth
                totalTimeLb.width = totalTimeLb.textWidth
            }
        }
    }
    
    var playDuration: CGFloat = 0
    
    func setPlayDuration(_ duration: CGFloat, isAnimation: Bool) {
        playDuration = duration
        let currentPlayTime = PhotoTools.transformVideoDurationToString(duration: TimeInterval(playDuration))
        currentTimeLb.text = currentPlayTime
        let value = videoDuration == 0 ? 0 : playDuration / videoDuration
        sliderView.setValue(value, isAnimation: isAnimation)
        if style == .editor {
            currentTimeLb.width = currentTimeLb.textWidth
        }
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
    
    let style: Style
    init(style: Style = .picker) {
        self.style = style
        super.init(frame: .zero)
        addSubview(playButton)
        addSubview(sliderView)
        addSubview(currentTimeLb)
        addSubview(totalTimeLb)
    }
    
    func sliderView(_ sliderView: SliderView, didChangedValue value: CGFloat, state: VideoControlEvent) {
        delegate?.videoSliderView(self, didChangedPlayDuration: videoDuration * value, state: state)
    }
    
    
    var isSliderChanged: Bool = false
    
    func sliderView(_ sliderView: SliderView, didChangedAt rect: CGRect, state: VideoControlEvent) {
        if style == .picker {
            return
        }
        isSliderChanged = true
        updateTimeLabels(rect)
        switch state {
        case .touchDown:
            if width >= 50 && width < 130 {
                UIView.animate(withDuration: 0.2) {
                    self.currentTimeLb.alpha = 1
                }
            }else if width >= 130 {
                UIView.animate(withDuration: 0.2) {
                    self.currentTimeLb.alpha = 1
                    self.totalTimeLb.alpha = 1
                }
            }
        case .changed:
            break
        case .touchUpInSide:
            UIView.animate(withDuration: 0.2) {
                self.currentTimeLb.alpha = 0
                self.totalTimeLb.alpha = 0
            }
            isSliderChanged = false
        }
    }
    
    private func updateTimeLabels(_ rect: CGRect) {
        if rect.minX < currentTimeLb.frame.maxX {
            let timeY = rect.minY - currentTimeLb.height
            if currentTimeLb.y != timeY {
                UIView.animate(withDuration: 0.2) {
                    self.currentTimeLb.y = timeY
                }
            }
        }else {
            let timeY = height * 0.5 - currentTimeLb.height
            if currentTimeLb.y != timeY {
                UIView.animate(withDuration: 0.2) {
                    self.currentTimeLb.y = timeY
                }
            }
        }
        if width >= 140 {
            if rect.maxX > totalTimeLb.x {
                let timeY = rect.minY - totalTimeLb.height
                if totalTimeLb.y != timeY {
                    UIView.animate(withDuration: 0.2) {
                        self.totalTimeLb.y = timeY
                    }
                }
            }else {
                let timeY = height * 0.5 - totalTimeLb.height
                if totalTimeLb.y != timeY {
                    UIView.animate(withDuration: 0.2) {
                        self.totalTimeLb.y = timeY
                    }
                }
            }
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        if style == .picker {
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
        }else {
            if width < 100 {
                sliderView.x = 0
                playButton.isHidden = true
            }else {
                playButton.isHidden = false
                playButton.x = 0
                playButton.centerY = height * 0.5
                sliderView.x = playButton.frame.maxX + 10
            }
            sliderView.width = width - sliderView.x - 5
            sliderView.height = height
            sliderView.centerY = height * 0.5
            
            currentTimeLb.x = sliderView.x
            totalTimeLb.x = sliderView.frame.maxX - totalTimeLb.width
            if !isSliderChanged {
                currentTimeLb.y = sliderView.centerY - currentTimeLb.height
                totalTimeLb.y = sliderView.centerY - totalTimeLb.height
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    enum Style {
        case picker
        case editor
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
        
        playLayer.shadowColor = UIColor.black.withAlphaComponent(0.3).cgColor
        playLayer.shadowOpacity = 0.3
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
        state: VideoControlEvent
    )
    
    func sliderView(
        _ sliderView: SliderView,
        didChangedAt rect: CGRect,
        state: VideoControlEvent
    )
}

public enum VideoControlEvent {
   case touchDown
   case touchUpInSide
   case changed
}

class SliderView: UIView {
    
    weak var delegate: SliderViewDelegate?
    lazy var panGR: PhotoPanGestureRecognizer = {
        let pan = PhotoPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerClick(pan:)))
        return pan
    }()
    let thumbScale: CGFloat = 0.7
    lazy var thumbView: UIImageView = {
        let imageSize = CGSize(width: 18, height: 18)
        let view = UIImageView(image: .image(for: .white, havingSize: imageSize, radius: 9))
        view.size = imageSize
        view.layer.shadowColor = UIColor.black.withAlphaComponent(0.3).cgColor
        view.layer.shadowOpacity = 0.3
        if style == .editor {
            view.transform = .init(scaleX: thumbScale, y: thumbScale)
        }
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
            if style == .editor {
                UIView.animate(withDuration: 0.2) {
                    self.thumbView.transform = .identity
                }
            }
            if thumbViewFrame.equalTo(.zero) {
                thumbViewFrame = thumbView.frame
            }
            delegate?.sliderView(self, didChangedValue: value, state: .touchDown)
            delegate?.sliderView(self, didChangedAt: convert(thumbView.frame, to: superview), state: .touchDown)
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
            delegate?.sliderView(self, didChangedValue: value, state: .changed)
            delegate?.sliderView(self, didChangedAt: convert(thumbView.frame, to: superview), state: .changed)
        case .cancelled, .ended, .failed:
            thumbViewFrame = .zero
            delegate?.sliderView(self, didChangedValue: value, state: .touchUpInSide)
            delegate?.sliderView(self, didChangedAt: convert(thumbView.frame, to: superview), state: .touchUpInSide)
            if style == .editor {
                UIView.animate(withDuration: 0.2) {
                    self.thumbView.transform = .init(scaleX: self.thumbScale, y: self.thumbScale)
                }
            }
        default:
            break
        }
    }
    
    lazy var trackView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 1
        view.layer.shadowColor = UIColor.black.withAlphaComponent(0.3).cgColor
        view.layer.shadowOpacity = 0.3
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
    let style: VideoPlaySliderView.Style
    init(_ style: VideoPlaySliderView.Style) {
        self.style = style
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
