//
//  EditorVideoPlayerView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2022/11/12.
//

import UIKit
import AVFoundation

protocol EditorVideoPlayerViewDelegate: AnyObject {
    func playerView(_ playerView: EditorVideoPlayerView, didPlayAt time: CMTime)
    func playerView(_ playerView: EditorVideoPlayerView, didPauseAt time: CMTime)
    func playerView(readyForDisplay playerView: EditorVideoPlayerView)
    func playerView(_ playerView: EditorVideoPlayerView, isPlaybackLikelyToKeepUp: Bool)
    func playerView(resetPlay playerView: EditorVideoPlayerView)
    func playerView(_ playerView: EditorVideoPlayerView, readyToPlay duration: CMTime)
    func playerView(_ playerView: EditorVideoPlayerView, didChangedBuffer time: CMTime)
    func playerView(_ playerView: EditorVideoPlayerView, didChangedTimeAt time: CMTime)
    
    func playerView(_ playerView: EditorVideoPlayerView, applyFilter sourceImage: CIImage, at time: CMTime) -> CIImage
}

class EditorVideoPlayerView: VideoPlayerView {
    weak var delegate: EditorVideoPlayerViewDelegate?
    var playbackTimeObserver: Any?
    var isPlaying: Bool = false
    var shouldPlay = true
    var readyForDisplayObservation: NSKeyValueObservation?
    var rateObservation: NSKeyValueObservation?
    var statusObservation: NSKeyValueObservation?
    var loadedTimeRangesObservation: NSKeyValueObservation?
    var playbackLikelyToKeepUpObservation: NSKeyValueObservation?
    var videoSize: CGSize = .zero
    
    var coverImageView: UIImageView!
    
    var volume: CGFloat {
        get {
            CGFloat(player.volume)
        }
        set {
            player.volume = Float(newValue)
        }
    }
    
    var playTime: CMTime {
        player.currentTime()
    }
    var duration: CMTime {
        guard let duration = avAsset?.duration else {
            return .zero
        }
        return duration
    }
    var startTime: CMTime? {
        didSet {
            guard let timeRange = player.currentItem?.loadedTimeRanges.first?.timeRangeValue else {
                return
            }
            let startSeconds = timeRange.start.seconds
            let durationSeconds = timeRange.duration.seconds
            let bufferSeconds = startSeconds + durationSeconds
            delegate?.playerView(
                self,
                didChangedBuffer: .init(
                    seconds: bufferSeconds,
                    preferredTimescale: timeRange.duration.timescale
                )
            )
        }
    }
    var endTime: CMTime? {
        didSet {
            guard let timeRange = player.currentItem?.loadedTimeRanges.first?.timeRangeValue else {
                return
            }
            let startSeconds = timeRange.start.seconds
            let durationSeconds = timeRange.duration.seconds
            let bufferSeconds = startSeconds + durationSeconds
            delegate?.playerView(
                self,
                didChangedBuffer: .init(
                    seconds: bufferSeconds,
                    preferredTimescale: timeRange.duration.timescale
                )
            )
        }
    }
    convenience init(videoURL: URL, isPlay: Bool) {
        self.init(avAsset: AVAsset(url: videoURL), isPlay: isPlay)
    }
    convenience init(avAsset: AVAsset, isPlay: Bool) {
        self.init()
        self.avAsset = avAsset
        configAsset(isPlay: isPlay)
    }
    override init() {
        super.init()
        playerLayer.videoGravity = .resizeAspectFill
        coverImageView = UIImageView()
        addSubview(coverImageView)
    }
    var autoPlay: Bool = false
    func configAsset(isPlay: Bool, _ completion: ((Bool) -> Void)? = nil) {
        guard let avAsset = avAsset else {
            completion?(false)
            return
        }
        autoPlay = isPlay
        avAsset.loadValuesAsynchronously(forKeys: ["tracks"]) { [weak self] in
            DispatchQueue.main.async {
                if avAsset.statusOfValue(forKey: "tracks", error: nil) != .loaded {
                    completion?(false)
                    return
                }
                self?.setupAsset(avAsset, completion: completion)
            }
        }
    }
    func setupAsset(_ avAsset: AVAsset, completion: ((Bool) -> Void)? = nil) {
        delegate?.playerView(resetPlay: self)
        if let videoTrack = avAsset.tracks(withMediaType: .video).first {
            self.videoSize = videoTrack.naturalSize
        }
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        let playerItem = AVPlayerItem(asset: avAsset)
        playerItem.videoComposition = videoComposition(avAsset)
        player.replaceCurrentItem(with: playerItem)
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill
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
//        rateObservation = player
//            .observe(
//                \.rate,
//                options: [.new, .old]
//            ) { [weak self] player, change in
//                guard let self = self else { return }
//                if player.rate == 0 && self.isPlaying {
//                    self.pause()
//                }
//        }
        statusObservation = playerItem
            .observe(
                \.status,
                options: [.new, .old]
            ) { [weak self] playerItem, _ in
                guard let self = self else { return }
                switch playerItem.status {
                case .readyToPlay:
                    self.delegate?.playerView(self, readyToPlay: playerItem.duration)
                    self.delegate?.playerView(self, isPlaybackLikelyToKeepUp: true)
                    if self.playbackTimeObserver == nil {
                        self.playbackTimeObserver = self.player.addPeriodicTimeObserver(
                            forInterval: CMTimeMake(
                                value: 1,
                                timescale: 10
                            ),
                            queue: .main
                        ) { [weak self] in
                            guard let self = self else { return }
                            self.delegate?.playerView(self, didChangedTimeAt: $0)
                        }
                    }
                    completion?(true)
                case .failed:
                    completion?(false)
                case .unknown:
                    break
                @unknown default:
                    break
                }
        }
        readyForDisplayObservation = playerLayer
            .observe(
                \.isReadyForDisplay,
                options: [.new, .old]
            ) { [weak self] playerLayer, _ in
                guard let self = self else { return }
                if playerLayer.isReadyForDisplay {
                    self.coverImageView.isHidden = true
                    if self.autoPlay && !self.didEnterBackground {
                        self.play()
                    }
                    self.delegate?.playerView(readyForDisplay: self)
                }
        }
        loadedTimeRangesObservation = playerItem
            .observe(
                \.loadedTimeRanges,
                options: [.new],
                changeHandler: { [weak self] playerItem, _ in
            guard let self = self,
                  let timeRange = playerItem.loadedTimeRanges.first?.timeRangeValue else {
                return
            }
            let startSeconds = CMTimeGetSeconds(timeRange.start)
            let durationSeconds = CMTimeGetSeconds(timeRange.duration)
            let bufferSeconds = startSeconds + durationSeconds
            self.delegate?.playerView(
                self, didChangedBuffer: .init(
                    seconds: bufferSeconds,
                    preferredTimescale: timeRange.duration.timescale
                )
            )
        })
        playbackLikelyToKeepUpObservation = playerItem
            .observe(
                \.isPlaybackLikelyToKeepUp,
                options: [.new],
                changeHandler: { [weak self] playerItem, _ in
            guard let self = self else { return }
            let isPlaybackLikelyToKeepUp = playerItem.isPlaybackLikelyToKeepUp
            self.delegate?.playerView(self, isPlaybackLikelyToKeepUp: isPlaybackLikelyToKeepUp)
        })
    }
    func videoComposition(_ avAsset: AVAsset) -> AVMutableVideoComposition {
        let videoComposition = AVMutableVideoComposition(
            asset: avAsset
        ) { [weak self] request in
            let sourceImage = request.sourceImage
            guard let self = self,
                  let ciImage = self.delegate?.playerView(
                    self,
                    applyFilter: sourceImage,
                    at: request.compositionTime
                  )
            else {
                request.finish(
                    with: NSError(
                        domain: "videoComposition filter error：ciImage is nil",
                        code: 500,
                        userInfo: nil
                    )
                )
                return
            }
            request.finish(with: ciImage, context: nil)
        }
        videoComposition.renderScale = 1
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        return videoComposition
    }
    
    func getDisplayedImage(at time: TimeInterval) -> UIImage? {
        avAsset?.getImage(at: time, videoComposition: player.currentItem?.videoComposition)
    }
    
    var beforEnterIsPlaying: Bool = false
    var didEnterBackground: Bool = false
    @objc func appDidEnterBackground() {
        didEnterBackground = true
        beforEnterIsPlaying = isPlaying
        pause()
    }
    @objc  func appDidEnterPlayGround() {
        if beforEnterIsPlaying, didEnterBackground {
            play()
        }
        didEnterBackground = false
    }
    var isPlayToEndTimeAutoPlay: Bool = true
    @objc func playerItemDidPlayToEndTimeNotification(notifi: Notification) {
        if isPlayToEndTimeAutoPlay {
            resetPlay()
        }
    }
    func seek(to time: CMTime, isPlay: Bool = false, comletion: ((Bool) -> Void)? = nil) {
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] (isFinished) in
            comletion?(isFinished)
            guard let self = self else {
                return
            }
            if isPlay && isFinished {
                self.play()
            }
        }
    }
    func seek(to time: TimeInterval, isPlay: Bool, comletion: ((Bool) -> Void)? = nil) {
        guard let playerItem = player.currentItem else {
            return
        }
        if !isPlay {
            pause()
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
                self?.play()
            }
        }
    }
    func pause() {
        if isPlaying {
            isPlaying = false
            if player.rate != 0 {
                player.pause()
            }
            player.currentItem?.seekingWaitsForVideoCompositionRendering = true
            delegate?.playerView(self, didPauseAt: player.currentTime())
        }
    }
    func play() {
        if !isPlaying {
            player.currentItem?.seekingWaitsForVideoCompositionRendering = false
            isPlaying = true
            player.play()
            delegate?.playerView(self, didPlayAt: player.currentTime())
        }
    }
    func resetPlay(completion: ((CMTime) -> Void)? = nil) {
        isPlaying = false
        if let startTime = startTime {
            seek(to: startTime) { [weak self] isFinished in
                guard let self = self, isFinished else {
                    return
                }
                self.play()
                completion?(self.player.currentTime())
            }
        }else {
            seek(to: .zero) { [weak self] isFinished in
                guard let self = self, isFinished else {
                    return
                }
                self.play()
                completion?(self.player.currentTime())
            }
        }
    }
    func clear() {
        avAsset?.cancelLoading()
        NotificationCenter.default.removeObserver(self)
        statusObservation = nil
        rateObservation = nil
        readyForDisplayObservation = nil
        loadedTimeRangesObservation = nil
        playbackLikelyToKeepUpObservation = nil
        if let timeObserver = playbackTimeObserver {
            player.removeTimeObserver(timeObserver)
            playbackTimeObserver = nil
        }
        player.replaceCurrentItem(with: nil)
        playerLayer.player = nil
        avAsset = nil
        coverImageView.isHidden = false
        isPlaying = false
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        coverImageView.frame = bounds
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        clear()
    }
} 
