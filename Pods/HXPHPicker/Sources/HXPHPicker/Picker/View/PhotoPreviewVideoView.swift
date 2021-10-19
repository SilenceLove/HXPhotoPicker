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
    
    func videoView(readyForDisplay videoView: VideoPlayerView)
    func videoView(resetPlay videoView: VideoPlayerView)
    func videoView(_ videoView: VideoPlayerView, readyToPlay duration: CGFloat)
    func videoView(_ videoView: VideoPlayerView, didChangedBuffer duration: CGFloat)
    func videoView(_ videoView: VideoPlayerView, didChangedPlayerTime duration: CGFloat)
}

extension PhotoPreviewVideoViewDelegate {
    func videoView(startPlay videoView: VideoPlayerView) {}
    func videoView(stopPlay videoView: VideoPlayerView) {}
    func videoView(showPlayButton videoView: VideoPlayerView) {}
    func videoView(hidePlayButton videoView: VideoPlayerView) {}
    func videoView(showMaskView videoView: VideoPlayerView) {}
    func videoView(hideMaskView videoView: VideoPlayerView) {}
    func videoView(_ videoView: VideoPlayerView, isPlaybackLikelyToKeepUp: Bool) {}
    func videoView(readyForDisplay videoView: VideoPlayerView) {}
    func videoView(resetPlay videoView: VideoPlayerView) {}
    func videoView(_ videoView: VideoPlayerView, readyToPlay duration: CGFloat) {}
    func videoView(_ videoView: VideoPlayerView, didChangedBuffer duration: CGFloat) {}
    func videoView(_ videoView: VideoPlayerView, didChangedPlayerTime duration: CGFloat) {}
}

class PhotoPreviewVideoView: VideoPlayerView {
    weak var delegate: PhotoPreviewVideoViewDelegate?
    var isNetwork: Bool = false
    var playerTime: CGFloat = 0
    override var avAsset: AVAsset? {
        didSet {
            try? AVAudioSession.sharedInstance().setCategory(.playback)
            delegate?.videoView(showPlayButton: self)
            if isNetwork && PhotoManager.shared.loadNetworkVideoMode == .play {
                delegate?.videoView(self, isPlaybackLikelyToKeepUp: false)
                loadingView = ProgressHUD.showLoading(addedTo: loadingSuperview(), animated: true)
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
    var videoPlayType: PhotoPreviewViewController.PlayType = .normal
    
    var playbackTimeObserver: Any?
    var readyForDisplayObservation: NSKeyValueObservation?
    override init() {
        super.init()
        layer.masksToBounds = true
        playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        readyForDisplayObservation = playerLayer
            .observe(
                \.isReadyForDisplay,
                options: [.new, .old]
            ) { [weak self] playerLayer, change in
            guard let self = self else { return }
            if playerLayer.isReadyForDisplay {
                self.delegate?.videoView(readyForDisplay: self)
                if !self.didEnterBackground &&
                    (self.videoPlayType == .auto || self.videoPlayType == .once) {
                    self.startPlay()
                }
            }
            if self.playerTime > 0 {
                self.seek(to: TimeInterval(self.playerTime), isPlay: true)
            }
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterPlayGround),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
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
        hideLoading()
        loadingView = nil
        delegate?.videoView(hidePlayButton: self)
    }
    func showPlayButton() {
        delegate?.videoView(showPlayButton: self)
        if let status = player.currentItem?.status,
           status != .readyToPlay {
            if isNetwork && PhotoManager.shared.loadNetworkVideoMode == .play && loadingView == nil {
                delegate?.videoView(self, isPlaybackLikelyToKeepUp: false)
                loadingView = ProgressHUD.showLoading(addedTo: loadingSuperview(), animated: true)
            }
        }
    }
    func hiddenMaskView() {
        delegate?.videoView(hideMaskView: self)
    }
    func showMaskView() {
        delegate?.videoView(showMaskView: self)
//        if let status = player.currentItem?.status,
//           status != .readyToPlay {
//            if isNetwork && PhotoManager.shared.loadNetworkVideoMode == .play && loadingView == nil {
//                delegate?.videoView(self, isPlaybackLikelyToKeepUp: false)
//                loadingView = ProgressHUD.showLoading(addedTo: loadingSuperview(), animated: true)
//            }
//        }
    }
    func loadingSuperview() -> UIView? {
        if let view = superview as? PhotoPreviewContentView {
            return view.hudSuperview()
        }
        return self
    }
    func hideLoading() {
        ProgressHUD.hide(
            forView: loadingSuperview() ?? loadingView?.superview,
            animated: true
        )
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
            hideLoading()
            loadingView = nil
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
        let duration = CMTimeGetSeconds(playerItem.duration)
        if duration.isNaN {
            return
        }
        if time < 0 {
            seconds = 0
        }else if time > duration {
            seconds = duration
        }
        player.seek(
            to: CMTimeMakeWithSeconds(
                seconds,
                preferredTimescale: playerItem.duration.timescale
            ),
            toleranceBefore: .zero,
            toleranceAfter: .zero
        ) { [weak self] isFinished in
            if isFinished && isPlay {
                self?.startPlay()
            }
        }
    }
    @objc func playerItemDidPlayToEndTimeNotification(notifi: Notification) {
        stopPlay()
        player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
        if videoPlayType == .auto {
            startPlay()
        }
    }
    
    var statusObservation: NSKeyValueObservation?
    var loadedTimeRangesObservation: NSKeyValueObservation?
    var playbackLikelyToKeepUpObservation: NSKeyValueObservation?
    func addedPlayerObservers() {
        if canRemovePlayerObservers {
            return
        }
        statusObservation = player
            .currentItem?
            .observe(
                \.status,
                options: [.new, .old],
                changeHandler: { [weak self] playerItem, change in
            guard let self = self else { return }
            switch playerItem.status {
            case AVPlayerItem.Status.readyToPlay:
                // 可以播放了
                self.delegate?.videoView(self, readyToPlay: CGFloat(CMTimeGetSeconds(playerItem.duration)))
                self.loadingView?.isHidden = true
                self.delegate?.videoView(self, isPlaybackLikelyToKeepUp: true)
                if self.playbackTimeObserver == nil {
                    self.playbackTimeObserver = self.player.addPeriodicTimeObserver(
                        forInterval: CMTimeMake(
                            value: 1,
                            timescale: 10
                        ),
                        queue: .main
                    ) { [weak self] (time) in
                        guard let self = self else { return }
                        let currentTime = CMTimeGetSeconds(time)
                        self.delegate?.videoView(self, didChangedPlayerTime: CGFloat(currentTime))
                    }
                }
            case AVPlayerItem.Status.failed:
                // 初始化失败
                self.cancelPlayer()
                ProgressHUD.showWarning(addedTo: self, text: "视频加载失败!".localized, animated: true, delayHide: 1.5)
            default:
                break
            }
        })
        loadedTimeRangesObservation = player
            .currentItem?
            .observe(
                \.loadedTimeRanges,
                options: [.new],
                changeHandler: { [weak self] playerItem, change in
            guard let self = self,
                  let timeRange = playerItem.loadedTimeRanges.first?.timeRangeValue else {
                return
            }
            let startSeconds = CMTimeGetSeconds(timeRange.start)
            let durationSeconds = CMTimeGetSeconds(timeRange.duration)
            let bufferSeconds = startSeconds + durationSeconds
            self.delegate?.videoView(self, didChangedBuffer: CGFloat(bufferSeconds))
        })
        playbackLikelyToKeepUpObservation = player
            .currentItem?
            .observe(
                \.isPlaybackLikelyToKeepUp,
                options: [.new],
                changeHandler: { [weak self] playerItem, change in
            guard let self = self else { return }
            let isPlaybackLikelyToKeepUp = playerItem.isPlaybackLikelyToKeepUp
            self.delegate?.videoView(self, isPlaybackLikelyToKeepUp: isPlaybackLikelyToKeepUp)
            if !isPlaybackLikelyToKeepUp {
                // 缓冲中
                if self.loadingView == nil {
                    self.loadingView = ProgressHUD.showLoading(addedTo: self.loadingSuperview(), animated: true)
                }else {
                    self.loadingView?.isHidden = false
                }
            }else {
                // 缓冲完成
                self.loadingView?.isHidden = true
            }
        })
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidPlayToEndTimeNotification(notifi:)),
            name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
            object: player.currentItem
        )
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
        statusObservation = nil
        loadedTimeRangesObservation = nil
        playbackLikelyToKeepUpObservation = nil
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
            object: player.currentItem
        )
        canRemovePlayerObservers = false
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    deinit {
        readyForDisplayObservation = nil
        NotificationCenter.default.removeObserver(self)
    }
}
