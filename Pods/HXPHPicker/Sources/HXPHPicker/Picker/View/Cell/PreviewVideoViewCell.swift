//
//  PreviewVideoViewCell.swift
//  HXPHPicker
//
//  Created by Slience on 2021/3/12.
//

import UIKit
import AVFoundation

open class PreviewVideoViewCell: PhotoPreviewViewCell, PhotoPreviewContentViewDelete {
    
    lazy var playButton: UIButton = {
        let playButton = UIButton.init(type: UIButton.ButtonType.custom)
        playButton.setImage("hx_picker_cell_video_play".image, for: UIControl.State.normal)
        playButton.setImage(UIImage.init(), for: UIControl.State.selected)
        playButton.addTarget(self, action: #selector(didPlayButtonClick(button:)), for: UIControl.Event.touchUpInside)
        playButton.size = playButton.currentImage!.size
        playButton.alpha = 0
        return playButton
    }()
    
    @objc func didPlayButtonClick(button: UIButton) {
        if !button.isSelected {
            scrollContentView.videoView.startPlay()
        }else {
            scrollContentView.videoView.stopPlay()
        }
    }
    
    var videoPlayType: PhotoPreviewViewController.PlayType = .normal {
        didSet {
            if videoPlayType == .auto || videoPlayType == .once {
                playButton.isSelected = true
            }
            scrollContentView.videoView.videoPlayType = videoPlayType
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        scrollContentView = PhotoPreviewContentView.init(type: .video)
        scrollContentView.delegate = self
        scrollContentView.videoView.delegate = self
        initView()
        addSubview(playButton)
    }
    
    override func setupScrollViewContentSize() {
        if UIDevice.isPad {
            scrollView.zoomScale = 1
            setupLandscapeContentSize()
        }else {
            super.setupScrollViewContentSize()
        }
    }
    
    public func contentView(requestSucceed contentView: PhotoPreviewContentView) {
        delegate?.cell(requestSucceed: self)
    }
    public func contentView(requestFailed contentView: PhotoPreviewContentView) {
        delegate?.cell(requestFailed: self)
    }
    public func contentView(updateContentSize contentView: PhotoPreviewContentView) {
        setupScrollViewContentSize()
    }
    public func contentView(networkImagedownloadSuccess contentView: PhotoPreviewContentView) {
        
    }
    public func contentView(networkImagedownloadFailed contentView: PhotoPreviewContentView) {
        
    }
    
    /// 指定视频播放时间
    /// - Parameters:
    ///   - time: 指定的时间
    ///   - isPlay: 设置完是否需要播放
    public func seek(to time: TimeInterval, isPlay: Bool) {
        scrollContentView.videoView.seek(to: time, isPlay: isPlay)
    }
    /// 播放视频
    public func playVideo() {
        scrollContentView.videoView.startPlay()
    }
    /// 暂停视频
    public func pauseVideo() {
        scrollContentView.videoView.stopPlay()
    }
    
    /// 视频加载成功准备播放
    /// - Parameter duration: 视频总时长
    open func videoReadyToPlay(duration: CGFloat) {
        
    }
    
    /// 视频缓冲区发生改变
    /// - Parameter duration: 缓存时长
    open func videoDidChangedBuffer(duration: CGFloat) {
        
    }
    
    /// 视频播放时间发生改变
    /// - Parameter duration: 当前播放的时长
    open func videoDidChangedPlayTime(duration: CGFloat, isAnimation: Bool) {
    }
    
    /// 视频播放了
    open func videoDidPlay() {
        
    }
    
    /// 视频暂停了
    open func videoDidPause() {
        
    }
    
    /// 显示工具视图(例如滑动条)
    open func showToolView() {
        
    }
    
    /// 隐藏工具视图(例如滑动条)
    open func hideToolView() {
        
    }
    
    /// 显示遮罩层
    open func showMask() {
        
    }
    
    /// 隐藏遮罩层
    open func hideMask() {
        
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        playButton.centerX = width * 0.5
        playButton.centerY = height * 0.5
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension PreviewVideoViewCell: PhotoPreviewVideoViewDelegate {
    func videoView(readyForDisplay videoView: VideoPlayerView) {
    }
    func videoView(resetPlay videoView: VideoPlayerView) {
        videoDidChangedPlayTime(duration: 0, isAnimation: false)
    }
    func videoView(_ videoView: VideoPlayerView, readyToPlay duration: CGFloat) {
        videoReadyToPlay(duration: duration)
    }
    
    func videoView(_ videoView: VideoPlayerView, didChangedBuffer duration: CGFloat) {
        videoDidChangedBuffer(duration: duration)
    }
    
    func videoView(_ videoView: VideoPlayerView, didChangedPlayerTime duration: CGFloat) {
        videoDidChangedPlayTime(duration: duration, isAnimation: true)
    }
    
    func videoView(startPlay videoView: VideoPlayerView) {
        playButton.isSelected = true
        videoDidPlay()
    }
    
    func videoView(stopPlay videoView: VideoPlayerView) {
        playButton.isSelected = false
        videoDidPause()
    }
    
    func videoView(showPlayButton videoView: VideoPlayerView) {
        if playButton.alpha == 0 {
            playButton.isHidden = false
            UIView.animate(withDuration: 0.15) {
                self.playButton.alpha = 1
            }
        }
        if !statusBarShouldBeHidden {
            showToolView()
        }
    }
    
    func videoView(_ videoView: VideoPlayerView, isPlaybackLikelyToKeepUp: Bool) {
        playButton.isHidden = !isPlaybackLikelyToKeepUp
    }
    
    func videoView(hidePlayButton videoView: VideoPlayerView) {
        if playButton.alpha == 1 {
            UIView.animate(withDuration: 0.15) {
                self.playButton.alpha = 0
            } completion: { isFinished in
                if isFinished && self.playButton.alpha == 0 {
                    self.playButton.isHidden = true
                }
            }
        }
        hideToolView()
    }
    func videoView(showMaskView videoView: VideoPlayerView) {
        showMask()
    }
    func videoView(hideMaskView videoView: VideoPlayerView) {
        hideMask()
    }
    
    func videoView(_ videoView: VideoPlayerView, presentationSize: CGSize) {
        if let videoAsset = photoAsset.networkVideoAsset,
           videoAsset.videoSize.equalTo(.zero),
           !videoAsset.videoSize.equalTo(presentationSize) {
            photoAsset.networkVideoAsset?.videoSize = presentationSize
            scrollContentView.updateContentSize(presentationSize)
        }
    }
}
