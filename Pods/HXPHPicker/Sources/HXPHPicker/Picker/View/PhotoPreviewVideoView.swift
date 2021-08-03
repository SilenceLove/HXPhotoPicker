//
//  PhotoPreviewVideoView.swift
//  HXPHPickerExample
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit
import AVKit

protocol PhotoPreviewVideoViewDelegate: AnyObject {
    func videoView(startPlay videoView: VideoPlayerView)
    func videoView(stopPlay videoView: VideoPlayerView)
    func videoView(showPlayButton videoView: VideoPlayerView)
    func videoView(hidePlayButton videoView: VideoPlayerView)
    func videoView(showMaskView videoView: VideoPlayerView)
    func videoView(hideMaskView videoView: VideoPlayerView)
    
    func videoView(_ videoView: VideoPlayerView, isPlaybackLikelyToKeepUp: Bool)
    
    func videoView(resetPlay videoView: VideoPlayerView)
    func videoView(_ videoView: VideoPlayerView, readyToPlay duration: CGFloat)
    func videoView(_ videoView: VideoPlayerView, didChangedBuffer duration: CGFloat)
    func videoView(_ videoView: VideoPlayerView, didChangedPlayerTime duration: CGFloat)
}

class PhotoPreviewVideoView: VideoPlayerView {
    weak var delegate: PhotoPreviewVideoViewDelegate?
    var isNetwork: Bool = false
    override var avAsset: AVAsset? {
        didSet {
            do { try AVAudioSession.sharedInstance().setCategory(.playback) } catch {}
            delegate?.videoView(showPlayButton: self)
            if isNetwork && PhotoManager.shared.loadNetworkVideoMode == .play {
                delegate?.videoView(self, isPlaybackLikelyToKeepUp: false)
                loadingView = ProgressHUD.showLoading(addedTo: self, animated: true)
            }
            delegate?.videoView(resetPlay: self)
            let playerItem = AVPlayerItem.init(asset: avAsset!)
            player.replaceCurrentItem(with: playerItem)
            playerLayer.player = player
            addedPlayerObservers()
        }
    }
    var loadingView: ProgressHUD?
    var isPlaying: Bool = false
    var didEnterBackground: Bool = false
    var enterPlayGroundShouldPlay: Bool = false
    var canRemovePlayerObservers: Bool = false
    var videoPlayType: PhotoPreviewViewController.VideoPlayType = .normal
    
    var playbackTimeObserver: Any?
    
    override init() {
        super.init()
        layer.masksToBounds = true
        playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        playerLayer.addObserver(self, forKeyPath: "readyForDisplay", options: [.new, .old], context: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterPlayGround), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    @objc func appDidEnterBackground() {
        didEnterBackground = true
        if isPlaying {
            enterPlayGroundShouldPlay = true
            stopPlay()
        }
    }
    @objc  func appDidEnterPlayGround() {
        didEnterBackground = false
        if enterPlayGroundShouldPlay {
            startPlay()
            enterPlayGroundShouldPlay = false
        }
    }
    func startPlay() {
        if isPlaying {
            return
        }
        player.play()
        isPlaying = true
        delegate?.videoView(startPlay: self)
    }
    func stopPlay() {
        if !isPlaying {
            return
        }
        player.pause()
        isPlaying = false
        delegate?.videoView(stopPlay: self)
    }
    func hiddenPlayButton() {
        ProgressHUD.hide(forView: self, animated: true)
        loadingView = nil
        delegate?.videoView(hidePlayButton: self)
    }
    func showPlayButton() {
        delegate?.videoView(showPlayButton: self)
    }
    func hiddenMaskView() {
        delegate?.videoView(hideMaskView: self)
    }
    func showMaskView() {
        delegate?.videoView(showMaskView: self)
    }
    func cancelPlayer() {
        if player.currentItem != nil {
            stopPlay()
            if videoPlayType == .auto || videoPlayType == .once {
                delegate?.videoView(startPlay: self)
            }else {
                delegate?.videoView(hidePlayButton: self)
            }
            player.seek(to: CMTime.zero)
            player.cancelPendingPrerolls()
            player.currentItem?.cancelPendingSeeks()
            player.currentItem?.asset.cancelLoading()
            
            player.replaceCurrentItem(with: nil)
            playerLayer.player = nil
            removePlayerObservers()
            ProgressHUD.hide(forView: self, animated: true)
            loadingView = nil
        }
    }
    func addedPlayerObservers() {
        if canRemovePlayerObservers {
            return
        }
        player.currentItem?.addObserver(self, forKeyPath: "status", options:[.new, .old], context: nil)
        player.currentItem?.addObserver(self, forKeyPath: "loadedTimeRanges", options:.new, context: nil)
        player.currentItem?.addObserver(self, forKeyPath: "playbackBufferEmpty", options:.new, context: nil)
        player.currentItem?.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options:.new, context: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidPlayToEndTimeNotification(notifi:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player.currentItem)
        canRemovePlayerObservers = true
    }
    func removePlayerObservers() {
        if !canRemovePlayerObservers {
            return
        }
        if let timeObserver = playbackTimeObserver {
            player.removeTimeObserver(timeObserver)
            playbackTimeObserver = nil
        }
        player.currentItem?.removeObserver(self, forKeyPath: "status", context: nil)
        player.currentItem?.removeObserver(self, forKeyPath: "loadedTimeRanges", context: nil)
        player.currentItem?.removeObserver(self, forKeyPath: "playbackBufferEmpty", context: nil)
        player.currentItem?.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp", context: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player.currentItem)
        canRemovePlayerObservers = false
    }
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if object is AVPlayerItem {
            if object as? AVPlayerItem != player.currentItem {
                return
            }
            if keyPath == "status" {
                guard let playerItem = player.currentItem else {
                    return
                }
                switch playerItem.status {
                case AVPlayerItem.Status.readyToPlay:
                    // 可以播放了
                    delegate?.videoView(self, readyToPlay: CGFloat(CMTimeGetSeconds(playerItem.duration)))
                    loadingView?.isHidden = true
                    delegate?.videoView(self, isPlaybackLikelyToKeepUp: true)
                    if playbackTimeObserver == nil {
                        playbackTimeObserver = player.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 10), queue: .main) { [weak self] (time) in
                            guard let self = self else { return }
                            let currentTime = CMTimeGetSeconds(time)
                            self.delegate?.videoView(self, didChangedPlayerTime: CGFloat(currentTime))
                        }
                    }
                    break
                case AVPlayerItem.Status.failed:
                    // 初始化失败
                    cancelPlayer()
                    ProgressHUD.showWarning(addedTo: self, text: "视频加载失败!", animated: true, delayHide: 1.5)
                    break
                default:
                    break
                }
            }else if keyPath == "loadedTimeRanges" {
                let loadedTimeRanges = player.currentItem?.loadedTimeRanges
                guard let timeRange = loadedTimeRanges?.first?.timeRangeValue else {
                    return
                }
                let startSeconds = CMTimeGetSeconds(timeRange.start)
                let durationSeconds = CMTimeGetSeconds(timeRange.duration)
                let bufferSeconds = startSeconds + durationSeconds
                delegate?.videoView(self, didChangedBuffer: CGFloat(bufferSeconds))
            }else if keyPath == "playbackBufferEmpty" {
                
            }else if keyPath == "playbackLikelyToKeepUp" {
                let isPlaybackLikelyToKeepUp = player.currentItem!.isPlaybackLikelyToKeepUp
                delegate?.videoView(self, isPlaybackLikelyToKeepUp: isPlaybackLikelyToKeepUp)
                if !isPlaybackLikelyToKeepUp {
                    // 缓冲中
                    if loadingView == nil {
                        loadingView = ProgressHUD.showLoading(addedTo: self, animated: true)
                    }else {
                        loadingView?.isHidden = false
                    }
                }else {
                    // 缓冲完成
                    loadingView?.isHidden = true
                }
            }
        }else if object is AVPlayerLayer && keyPath == "readyForDisplay" {
            if object as? AVPlayerLayer != playerLayer {
                return
            }
            if playerLayer.isReadyForDisplay && !didEnterBackground && (videoPlayType == .auto || videoPlayType == .once) {
                startPlay()
            }
        }
    }
    
    @objc func playerItemDidPlayToEndTimeNotification(notifi: Notification) {
        stopPlay()
        player.currentItem?.seek(to: CMTime.init(value: 0, timescale: 1), completionHandler: { (_) in
        })
        
        if videoPlayType == .auto {
            startPlay()
        }
    }
    
    func seek(to time: TimeInterval, isPlay: Bool) {
        guard let playerItem = player.currentItem else {
            return
        }
        if !isPlay {
            stopPlay()
        }
        var seconds = time
        if time < 0 {
            seconds = 0
        }else if time > CMTimeGetSeconds(playerItem.duration) {
            seconds = CMTimeGetSeconds(playerItem.duration)
        }
        player.seek(to: CMTimeMakeWithSeconds(seconds, preferredTimescale: playerItem.duration.timescale), toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] isFinished in
            if isFinished && isPlay {
                self?.startPlay()
            }
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    deinit {
        playerLayer.removeObserver(self, forKeyPath: "readyForDisplay")
        NotificationCenter.default.removeObserver(self)
    }
}
