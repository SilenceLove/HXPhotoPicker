//
//  PreviewVideoControlViewCell.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/6/30.
//

import UIKit

open class PreviewVideoControlViewCell: PreviewVideoViewCell, VideoPlaySliderViewDelegate {
    
    public var maskLayer: CAGradientLayer!
    public var maskBackgroundView: UIView!
    public var sliderView: VideoPlaySliderView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        maskBackgroundView = UIView()
        maskBackgroundView.alpha = 0
        maskLayer = PhotoTools.getGradientShadowLayer(false)
        maskBackgroundView.layer.addSublayer(maskLayer)
        contentView.addSubview(maskBackgroundView)
        sliderView = VideoPlaySliderView()
        sliderView.delegate = self
        sliderView.alpha = 0
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
        if maskBackgroundView.alpha == 0 {
            maskBackgroundView.isHidden = false
            UIView.animate(withDuration: 0.15) {
                self.maskBackgroundView.alpha = 1
            }
        }
    }
    public override func hideMask() {
        if maskBackgroundView.alpha == 1 {
            UIView.animate(withDuration: 0.15) {
                self.maskBackgroundView.alpha = 0
            } completion: { isFinished in
                if isFinished && self.maskBackgroundView.alpha == 0 {
                    self.maskBackgroundView.isHidden = true
                }
            }
        }
    }
    
    func videoSliderView(
        _ videoSliderView: VideoPlaySliderView,
        didChangedPlayDuration duration: CGFloat,
        state: VideoControlEvent
    ) {
        seek(to: TimeInterval(duration), isPlay: state == .touchUpInSide)
    }
    func videoSliderView(_ videoSliderView: VideoPlaySliderView, didPlayButtonClick isSelected: Bool) {
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
        maskBackgroundView.frame = sliderView.frame
        maskLayer.frame = CGRect(x: 0, y: -20, width: width, height: maskBackgroundView.height + 20)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
