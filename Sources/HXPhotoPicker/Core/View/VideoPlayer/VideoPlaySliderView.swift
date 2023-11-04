//
//  VideoPlaySliderView.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/4.
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
    
    private var playButton: PlayButton!
    private var sliderView: SliderView!
    private var currentTimeLb: UILabel!
    private var totalTimeLb: UILabel!
    
    private var isSliderChanged: Bool = false
    private let style: Style
    
    var playDuration: CGFloat = 0
    var videoDuration: CGFloat = 0 {
        didSet {
            totalTimeLb.text = PhotoTools.transformVideoDurationToString(duration: TimeInterval(videoDuration))
            currentTimeLb.text = "00:00"
            if style == .editor {
                currentTimeLb.width = currentTimeLb.textWidth
                totalTimeLb.width = totalTimeLb.textWidth
            }
        }
    }
    var bufferDuration: CGFloat = 0 {
        didSet {
            let duration: CGFloat
            if bufferDuration.isNaN {
                duration = 0
            }else {
                duration = bufferDuration
            }
            if videoDuration == 0 {
                sliderView.bufferValue = 0
            }else {
                sliderView.bufferValue = duration / videoDuration
            }
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
    
    init(style: Style = .picker) {
        self.style = style
        super.init(frame: .zero)
        initViews()
        addSubview(playButton)
        addSubview(sliderView)
        addSubview(currentTimeLb)
        addSubview(totalTimeLb)
    }
    
    private func initViews() {
        playButton = PlayButton()
        playButton.size = CGSize(width: 30, height: 40)
        playButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didPlayButton)))
        
        sliderView = SliderView(style)
        sliderView.delegate = self
        
        currentTimeLb = UILabel(frame: CGRect(x: 0, y: 0, width: 65, height: 30))
        currentTimeLb.text = "--:--"
        currentTimeLb.textColor = .white
        currentTimeLb.font = .regularPingFang(ofSize: 15)
        currentTimeLb.layer.shadowColor = UIColor.black.withAlphaComponent(0.7).cgColor
        currentTimeLb.layer.shadowOpacity = 0.5
        currentTimeLb.layer.shadowOffset = .init(width: -1, height: 1)
        
        totalTimeLb = UILabel(frame: CGRect(x: 0, y: 0, width: 65, height: 30))
        totalTimeLb.text = "--:--"
        totalTimeLb.textColor = .white
        totalTimeLb.font = .regularPingFang(ofSize: 15)
        totalTimeLb.layer.shadowColor = UIColor.black.withAlphaComponent(0.7).cgColor
        totalTimeLb.layer.shadowOpacity = 0.5
        totalTimeLb.layer.shadowOffset = .init(width: -1, height: 1)
        
        if style == .editor {
            currentTimeLb.alpha = 0
            currentTimeLb.textAlignment = .left
            totalTimeLb.alpha = 0
            totalTimeLb.textAlignment = .right
        }else {
            currentTimeLb.textAlignment = .center
            totalTimeLb.textAlignment = .center
        }
    }
    
    @objc
    private func didPlayButton() {
        playButton.isSelected = !playButton.isSelected
        delegate?.videoSliderView(self, didPlayButtonClick: playButton.isSelected)
    }
    
    func setPlayDuration(_ duration: CGFloat, isAnimation: Bool) {
        playDuration = duration
        let currentPlayTime: String = PhotoTools.transformVideoDurationToString(duration: TimeInterval(playDuration))
        currentTimeLb.text = currentPlayTime
        let value: CGFloat
        if videoDuration == 0 {
            value = 0
        }else {
            value = playDuration / videoDuration
        }
        sliderView.setValue(value, isAnimation: isAnimation)
        if style == .editor {
            currentTimeLb.width = currentTimeLb.textWidth
        }
    }
    
    func sliderView(_ sliderView: SliderView, didChangedValue value: CGFloat, state: VideoControlEvent) {
        delegate?.videoSliderView(self, didChangedPlayDuration: videoDuration * value, state: state)
    }
    
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
            let timeY: CGFloat = rect.minY - currentTimeLb.height
            if currentTimeLb.y != timeY {
                UIView.animate(withDuration: 0.2) {
                    self.currentTimeLb.y = timeY
                }
            }
        }else {
            let timeY: CGFloat = height * 0.5 - currentTimeLb.height
            if currentTimeLb.y != timeY {
                UIView.animate(withDuration: 0.2) {
                    self.currentTimeLb.y = timeY
                }
            }
        }
        if width >= 140 {
            if rect.maxX > totalTimeLb.x {
                let timeY: CGFloat = rect.minY - totalTimeLb.height
                if totalTimeLb.y != timeY {
                    UIView.animate(withDuration: 0.2) {
                        self.totalTimeLb.y = timeY
                    }
                }
            }else {
                let timeY: CGFloat = height * 0.5 - totalTimeLb.height
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
            
            let sliderX: CGFloat = currentTimeLb.frame.maxX + 5
            let sliderW: CGFloat = totalTimeLb.x - 5 - sliderX
            sliderView.frame = .init(x: sliderX, y: 0, width: sliderW, height: height)
            sliderView.centerY = totalTimeLb.centerY
        }else {
            let sliderX: CGFloat
            if width < 100 {
                sliderX = 0
                playButton.isHidden = true
            }else {
                playButton.isHidden = false
                playButton.x = 0
                playButton.centerY = height * 0.5
                sliderX = playButton.frame.maxX + 10
            }
            let sliderW: CGFloat = width - sliderX - 5
            sliderView.frame = .init(x: sliderX, y: 0, width: sliderW, height: height)
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
