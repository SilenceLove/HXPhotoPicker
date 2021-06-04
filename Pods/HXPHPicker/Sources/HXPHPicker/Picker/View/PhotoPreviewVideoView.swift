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
}

class PhotoPreviewVideoView: VideoPlayerView {
    weak var delegate: PhotoPreviewVideoViewDelegate?
    override var avAsset: AVAsset? {
        didSet {
            delegate?.videoView(showPlayButton: self)
            let playerItem = AVPlayerItem.init(asset: avAsset!)
            player.replaceCurrentItem(with: playerItem)
            playerLayer.player = player
            addedPlayerObservers()
        }
    }
    
    var isPlaying: Bool = false
    var didEnterBackground: Bool = false
    var enterPlayGroundShouldPlay: Bool = false
    var canRemovePlayerObservers: Bool = false
    var videoPlayType: PhotoPreviewViewController.VideoPlayType = .normal
    
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
        delegate?.videoView(hidePlayButton: self)
    }
    func showPlayButton() {
        delegate?.videoView(showPlayButton: self)
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
                switch player.currentItem!.status {
                case AVPlayerItem.Status.readyToPlay:
                    // 可以播放了
                    break
                case AVPlayerItem.Status.failed:
                    // 初始化失败
                    
                    break
                default:
                    // 未知状态
                    break
                }
            }else if keyPath == "loadedTimeRanges" {
                
            }else if keyPath == "playbackBufferEmpty" {
                
            }else if keyPath == "playbackLikelyToKeepUp" {
                if !player.currentItem!.isPlaybackLikelyToKeepUp {
                    // 缓冲完成
                    ProgressHUD.showLoading(addedTo: self, animated: true)
                }else {
                    // 缓冲中
                    ProgressHUD.hide(forView: self, animated: true)
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
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    deinit {
        playerLayer.removeObserver(self, forKeyPath: "readyForDisplay")
        NotificationCenter.default.removeObserver(self)
    }
}
