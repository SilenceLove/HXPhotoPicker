//
//  SliderView.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/9/5.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit

public enum VideoControlEvent {
   case touchDown
   case touchUpInSide
   case changed
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

class SliderView: UIView {
    
    weak var delegate: SliderViewDelegate?
    
    private var trackView: UIView!
    private var progressView: UIView!
    private var bufferView: UIView!
    private var panGR: PhotoPanGestureRecognizer!
    
    private let thumbScale: CGFloat = 0.7
    private var thumbView: UIImageView!
    private var value: CGFloat = 0
    private var thumbViewFrame: CGRect = .zero
    
    private let style: VideoPlaySliderView.Style
    
    var bufferValue: CGFloat = 0 {
        didSet {
            let value: CGFloat
            if bufferValue.isNaN {
                value = 0
            }else {
                value = bufferValue
            }
            bufferView.width = width * value
        }
    }
    
    init(_ style: VideoPlaySliderView.Style) {
        self.style = style
        super.init(frame: .zero)
        initViews()
        addSubview(progressView)
        addSubview(bufferView)
        addSubview(trackView)
        addSubview(thumbView)
        addGestureRecognizer(panGR)
    }
    
    private func initViews() {
        panGR = .init(target: self, action: #selector(panGestureRecognizerClick(pan:)))
        
        let imageSize: CGSize = .init(width: 18, height: 18)
        thumbView = UIImageView(image: .image(for: .white, havingSize: imageSize, radius: 9))
        thumbView.size = imageSize
        thumbView.layer.shadowColor = UIColor.black.withAlphaComponent(0.3).cgColor
        thumbView.layer.shadowOpacity = 0.3
        if style == .editor {
            thumbView.transform = .init(scaleX: thumbScale, y: thumbScale)
        }
        
        trackView = UIView()
        trackView.backgroundColor = .white
        trackView.layer.masksToBounds = true
        trackView.layer.cornerRadius = 1
        trackView.layer.shadowColor = UIColor.black.withAlphaComponent(0.3).cgColor
        trackView.layer.shadowOpacity = 0.3
        
        progressView = UIView()
        progressView.backgroundColor = .white.withAlphaComponent(0.2)
        progressView.layer.masksToBounds = true
        progressView.layer.cornerRadius = 1
        
        bufferView = UIView()
        bufferView.backgroundColor = .white.withAlphaComponent(0.4)
        bufferView.layer.masksToBounds = true
        bufferView.layer.cornerRadius = 1
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
        let currentWidth: CGFloat = self.value * width
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
    
    @objc
    private func panGestureRecognizerClick(pan: UIPanGestureRecognizer) {
        switch pan.state {
        case .began:
            let point: CGPoint = pan.location(in: self)
            let rect: CGRect = .init(
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
            let specifiedPoint: CGPoint = pan.translation(in: self)
            var rect: CGRect = thumbViewFrame
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
