//
//  VideoEditorPlayerView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/9.
//

import UIKit
import AVKit

protocol VideoEditorPlayerViewDelegate: AnyObject {
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
    var readyForDisplayObservation: NSKeyValueObservation?
    
    lazy var coverImageView: UIImageView = {
        let imageView = UIImageView.init()
        return imageView
    }()
    
    convenience init(videoURL: URL) {
        self.init(avAsset: AVAsset(url: videoURL))
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
            try? AVAudioSession.sharedInstance().setCategory(.playback)
            let playerItem = AVPlayerItem.init(asset: avAsset)
            player.replaceCurrentItem(with: playerItem)
            playerLayer.player = player
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(appDidEnterBackground),
                name: UIApplication.didEnterBackgroundNotification,
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(appDidEnterPlayGround),
                name: UIApplication.didBecomeActiveNotification,
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(playerItemDidPlayToEndTimeNotification(notifi:)),
                name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                object: player.currentItem
            )
            readyForDisplayObservation = playerLayer
                .observe(
                    \.isReadyForDisplay,
                    options: [.new, .old]
                ) { [weak self] playerLayer, change in
                    guard let self = self else { return }
                    if playerLayer.isReadyForDisplay {
                        self.coverImageView.isHidden = true
                        self.play()
                        self.delegate?.playerView(self)
                    }
            }
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
    func resetPlay(completion: ((CMTime) -> Void)? = nil) {
        isPlaying = false
        if let startTime = playStartTime {
            seek(to: startTime) { (isFinished) in
                if isFinished {
                    self.play()
                    completion?(self.player.currentTime())
                }
            }
        }else {
            seek(to: CMTime.zero) { (isFinished) in
                if isFinished {
                    self.play()
                    completion?(self.player.currentTime())
                }
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
        readyForDisplayObservation = nil
        NotificationCenter.default.removeObserver(self)
    }
}
