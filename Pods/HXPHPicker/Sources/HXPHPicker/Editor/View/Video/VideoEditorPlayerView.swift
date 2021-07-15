//
//  VideoEditorPlayerView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/9.
//

import UIKit
import AVKit

protocol VideoEditorPlayerViewDelegate: NSObjectProtocol {
    func playerView(_ playerView: VideoEditorPlayerView, didPlayAt time: CMTime)
    func playerView(_ playerView: VideoEditorPlayerView, didPauseAt time: CMTime)
    func playerView(_ playerViewReadyForDisplay: VideoEditorPlayerView)
}

class VideoEditorPlayerView: VideoPlayerView {
    weak var delegate: VideoEditorPlayerViewDelegate?
    var playbackTimeObserver: Any?
    var playStartTime: CMTime?
    var playEndTime: CMTime?
    var isPlaying: Bool = false
    var shouldPlay = true
    var addObserverReadyForDisplay = false
    
    lazy var coverImageView: UIImageView = {
        let imageView = UIImageView.init()
        return imageView
    }()
    
    convenience init(videoURL: URL) {
        self.init(avAsset: AVAsset.init(url: videoURL))
    }
    convenience init(avAsset: AVAsset) {
        self.init()
        self.avAsset = avAsset
        configAsset()
    }
    override init() {
        super.init()
        addSubview(coverImageView)
    }
    func configAsset() {
        if let avAsset = avAsset {
            do { try AVAudioSession.sharedInstance().setCategory(.playback) } catch {}
            let playerItem = AVPlayerItem.init(asset: avAsset)
            player.replaceCurrentItem(with: playerItem)
            playerLayer.player = player
            NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterPlayGround), name: UIApplication.didBecomeActiveNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidPlayToEndTimeNotification(notifi:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player.currentItem)
            
            playerLayer.addObserver(self, forKeyPath: "readyForDisplay", options: [.new, .old], context: nil)
            addObserverReadyForDisplay = true
        }
    }
    @objc func appDidEnterBackground() {
        pause()
    }
    @objc  func appDidEnterPlayGround() {
        play()
    }
    @objc func playerItemDidPlayToEndTimeNotification(notifi: Notification) {
        resetPlay()
    }
    func seek(to time: CMTime, comletion: ((Bool) -> Void)? = nil) {
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { (isFinished) in
            comletion?(isFinished)
        }
    }
    func pause() {
        if isPlaying {
            player.pause()
            isPlaying = false
            delegate?.playerView(self, didPauseAt: player.currentTime())
        }
    }
    func play() {
        if !isPlaying {
            player.play()
            isPlaying = true
            delegate?.playerView(self, didPlayAt: player.currentTime())
        }
    }
    func resetPlay() {
        isPlaying = false
        if let startTime = playStartTime {
            seek(to: startTime) { (isFinished) in
                if isFinished {
                    self.play()
                }
            }
        }else {
            seek(to: CMTime.zero) { (isFinished) in
                if isFinished {
                    self.play()
                }
            }
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if object is AVPlayerLayer && keyPath == "readyForDisplay" {
            if object as? AVPlayerLayer != playerLayer {
                return
            }
            if playerLayer.isReadyForDisplay {
                coverImageView.isHidden = true
                play()
                delegate?.playerView(self)
            }
        }
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        coverImageView.frame = bounds
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        if addObserverReadyForDisplay {
            playerLayer.removeObserver(self, forKeyPath: "readyForDisplay")
        }
        NotificationCenter.default.removeObserver(self)
    }
}
