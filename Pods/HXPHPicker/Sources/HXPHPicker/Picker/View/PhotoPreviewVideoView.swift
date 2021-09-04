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
            do { try AVAudioSession.sharedInstance().setCategory(.playback) } catch {}
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
    
    override init() {
        super.init()
        layer.masksToBounds = true
        playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        playerLayer.addObserver(self, forKeyPath: "readyForDisplay", options: [.new, .old], context: nil)
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
        ProgressHUD.hide(forView: loadingSuperview(), animated: true)
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
    func addedPlayerObservers() {
        if canRemovePlayerObservers {
            return
        }
        player.currentItem?.addObserver(
            self,
            forKeyPath: "status",
            options: [.new, .old],
            context: nil
        )
        player.currentItem?.addObserver(
            self,
            forKeyPath: "loadedTimeRanges",
            options: .new,
            context: nil
        )
        player.currentItem?.addObserver(
            self,
            forKeyPath: "playbackBufferEmpty",
            options: .new,
            context: nil
        )
        player.currentItem?.addObserver(
            self,
            forKeyPath: "playbackLikelyToKeepUp",
            options: .new,
            context: nil
        )
        
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
        player.currentItem?.removeObserver(
            self,
            forKeyPath: "status",
            context: nil
        )
        player.currentItem?.removeObserver(
            self,
            forKeyPath: "loadedTimeRanges",
            context: nil
        )
        player.currentItem?.removeObserver(
            self,
            forKeyPath: "playbackBufferEmpty",
            context: nil
        )
        player.currentItem?.removeObserver(
            self,
            forKeyPath: "playbackLikelyToKeepUp",
            context: nil
        )
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
            object: player.currentItem
        )
        canRemovePlayerObservers = false
    }
    // swiftlint:disable block_based_kvo
    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?) {
        // swiftlint:enable block_based_kvo
        if object is AVPlayerLayer && keyPath == "readyForDisplay" {
            if object as? AVPlayerLayer != playerLayer {
                return
            }
            if playerLayer.isReadyForDisplay {
                delegate?.videoView(readyForDisplay: self)
                if !didEnterBackground &&
                    (videoPlayType == .auto || videoPlayType == .once) {
                    startPlay()
                }
            }
            if playerTime > 0 {
                seek(to: TimeInterval(playerTime), isPlay: true)
            }
            return
        }
        guard let item = object as? AVPlayerItem,
              let playerItem = player.currentItem,
              item == playerItem else {
            return
        }
        if keyPath == "status" {
            switch playerItem.status {
            case AVPlayerItem.Status.readyToPlay:
                // 可以播放了
                delegate?.videoView(self, readyToPlay: CGFloat(CMTimeGetSeconds(playerItem.duration)))
                loadingView?.isHidden = true
                delegate?.videoView(self, isPlaybackLikelyToKeepUp: true)
                if playbackTimeObserver == nil {
                    playbackTimeObserver = player.addPeriodicTimeObserver(
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
                cancelPlayer()
                ProgressHUD.showWarning(addedTo: self, text: "视频加载失败!".localized, animated: true, delayHide: 1.5)
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
                    loadingView = ProgressHUD.showLoading(addedTo: loadingSuperview(), animated: true)
                }else {
                    loadingView?.isHidden = false
                }
            }else {
                // 缓冲完成
                loadingView?.isHidden = true
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
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    deinit {
        playerLayer.removeObserver(self, forKeyPath: "readyForDisplay")
        NotificationCenter.default.removeObserver(self)
    }
}
