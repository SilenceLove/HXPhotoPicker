//
//  HXPHVideoView.swift
//  HXPHPickerExample
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit
import AVKit

class HXPHVideoView: UIView {
    
    var avAsset: AVAsset? {
        didSet {
            if playButton.alpha == 0 {
                UIView.animate(withDuration: 0.25) {
                    self.playButton.alpha = 1
                }
            }
            let playerItem = AVPlayerItem.init(asset: avAsset!)
            player.replaceCurrentItem(with: playerItem)
            playerLayer.player = player
            addedPlayerObservers()
        }
    }
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    lazy var player: AVPlayer = {
        let player = AVPlayer.init()
        return player
    }()
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
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
            startPlay()
        }else {
            stopPlay()
        }
    }
    var isPlaying: Bool = false
    var didEnterBackground: Bool = false
    var enterPlayGroundShouldPlay: Bool = false
    var canRemovePlayerObservers: Bool = false
    var videoPlayType: HXPHPicker.PreviewView.VideoPlayType = .normal  {
        didSet {
            if videoPlayType == .auto || videoPlayType == .once {
                playButton.isSelected = true
            }
        }
    }
    
    init() {
        super.init(frame: CGRect.zero)
        layer.masksToBounds = true
        playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        addSubview(playButton)
        
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
        playButton.isSelected = true
        isPlaying = true
    }
    func stopPlay() {
        if !isPlaying {
            return
        }
        player.pause()
        playButton.isSelected = false
        isPlaying = false
    }
    func hiddenPlayButton() {
        HXPHProgressHUD.hideHUD(forView: self, animated: true)
        UIView.animate(withDuration: 0.15) {
            self.playButton.alpha = 0
        }
    }
    func showPlayButton() {
        UIView.animate(withDuration: 0.25) {
            self.playButton.alpha = 1
        }
    }
    func cancelPlayer() {
        if player.currentItem != nil {
            stopPlay()
            if videoPlayType == .auto || videoPlayType == .once {
                playButton.isSelected = true
            }
            player.seek(to: CMTime.zero)
            player.cancelPendingPrerolls()
            player.currentItem?.cancelPendingSeeks()
            player.currentItem?.asset.cancelLoading()
            
            player.replaceCurrentItem(with: nil)
            playerLayer.player = nil
            removePlayerObservers()
            HXPHProgressHUD.hideHUD(forView: self, animated: true)
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
                    _ = HXPHProgressHUD.showLoadingHUD(addedTo: self, animated: true)
                }else {
                    // 缓冲中
                    HXPHProgressHUD.hideHUD(forView: self, animated: true)
                }
            }
        }else if object is AVPlayerLayer && keyPath == "readyForDisplay" {
            if object as? AVPlayerLayer != playerLayer {
                return
            }
            if self.playerLayer.isReadyForDisplay && !didEnterBackground && (videoPlayType == .auto || videoPlayType == .once) {
                startPlay()
            }
        }
    }
    
    @objc func playerItemDidPlayToEndTimeNotification(notifi: Notification) {
        stopPlay()
        player.currentItem?.seek(to: CMTime.init(value: 0, timescale: 1))
        
        if videoPlayType == .auto {
            startPlay()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
        playButton.centerX = width * 0.5
        playButton.centerY = height * 0.5
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    deinit {
        playerLayer.removeObserver(self, forKeyPath: "readyForDisplay")
        NotificationCenter.default.removeObserver(self)
    }
}
