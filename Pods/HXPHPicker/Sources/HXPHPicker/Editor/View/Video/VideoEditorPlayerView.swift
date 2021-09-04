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
    func playerView(beganDrag playerView: VideoEditorPlayerView)
    func playerView(endDrag playerView: VideoEditorPlayerView)
    func playerView(_ playerView: VideoEditorPlayerView, updateStickerText item: EditorStickerItem)
    func playerView(didRemoveAudio playerView: VideoEditorPlayerView)
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
    
    var cropMargin: CGPoint = .zero
    lazy var stickerView: EditorStickerView = {
        let view = EditorStickerView(frame: .zero)
        view.delegate = self
        return view
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
        addSubview(stickerView)
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
            playerLayer.addObserver(
                self,
                forKeyPath: "readyForDisplay",
                options: [.new, .old],
                context: nil
            )
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
    // swiftlint:disable block_based_kvo
    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        // swiftlint:enable block_based_kvo
        if object is AVPlayerLayer &&
            keyPath == "readyForDisplay" {
            if object as? AVPlayerLayer != playerLayer {
                return
            }
            if playerLayer.isReadyForDisplay {
                setupStickerViewFrame()
                coverImageView.isHidden = true
                play()
                delegate?.playerView(self)
            }
        }
    }
    func setupStickerViewFrame() {
        stickerView.frame = bounds
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        coverImageView.frame = bounds
        setupStickerViewFrame()
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

extension VideoEditorPlayerView: EditorStickerViewDelegate {
    func stickerView(touchBegan stickerView: EditorStickerView) {
        delegate?.playerView(beganDrag: self)
    }
    
    func stickerView(touchEnded stickerView: EditorStickerView) {
        delegate?.playerView(endDrag: self)
    }
    
    func stickerView(_ stickerView: EditorStickerView, moveToCenter rect: CGRect) -> Bool {
        let videoRect = playerLayer.videoRect
        guard let superViewSize = superview?.size,
              !videoRect.isEmpty else {
            return true
        }
        let x = (superViewSize.width - videoRect.width) * 0.5
        let y = (superViewSize.height - videoRect.height) * 0.5
        let newRect = CGRect(origin: .init(x: x, y: y), size: videoRect.size)
        let marginWidth = rect.width - 20
        let marginHeight = rect.height - 20
        if CGRect(
            x: newRect.minX - marginWidth,
            y: newRect.minY - marginHeight,
            width: newRect.width + marginWidth * 2,
            height: newRect.height + marginHeight * 2
        ).contains(rect) {
            return false
        }
        return true
    }
    
    func stickerView(_ stickerView: EditorStickerView, minScale itemSize: CGSize) -> CGFloat {
        min(35 / itemSize.width, 35 / itemSize.height)
    }
    
    func stickerView(_ stickerView: EditorStickerView, maxScale itemSize: CGSize) -> CGFloat {
        let maxScale = min(itemSize.width, itemSize.height)
        return max((stickerView.width + 35) / maxScale, (stickerView.height + 35) / maxScale)
    }
    
    func stickerView(_ stickerView: EditorStickerView, updateStickerText item: EditorStickerItem) {
        delegate?.playerView(self, updateStickerText: item)
    }
    
    func stickerView(didRemoveAudio stickerView: EditorStickerView) {
        delegate?.playerView(didRemoveAudio: self)
    }
}
