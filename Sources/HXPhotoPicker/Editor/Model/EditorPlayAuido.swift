//
//  EditorPlayAuido.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/20.
//

import UIKit
import AVFoundation

class EditorPlayAuido: NSObject, AVAudioPlayerDelegate {
    
    var player: AVAudioPlayer?
    
    var volume: Float = 1 {
        didSet {
            player?.volume = volume
        }
    }
    
    var audio: EditorStickerAudio?
    var music: VideoEditorMusic?
    weak var itemView: EditorStickersItemBaseView?
    var playCompletion: (() -> Void)?
    
    override init() {
        super.init()
    }
    weak var timer: Timer?
    
    @discardableResult
    func play(_ url: URL) -> Bool {
        stopPlay()
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.prepareToPlay()
            self.player = player
            startPlay()
            return true
        } catch {
            return false
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            playCompletion?()
            player.currentTime = 0
            player.play()
        }
    }
    
    func startPlay() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: { [weak self] in
            if $0 != self?.timer {
                $0.invalidate()
            }
            self?.updateAudioText()
        })
        player?.play()
        updateAudioText()
    }
    
    func updateAudioText() {
        guard let currentTime = player?.currentTime,
              let lyric = music?.lyric(atTime: currentTime)?.lyric else {
            return
        }
        audio?.text = lyric
    }
    
    func stopPlay() {
        timer?.invalidate()
        timer = nil
        player?.stop()
        player = nil
    }
    
    func pausePlay() {
        timer?.invalidate()
        timer = nil
        player?.pause()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        stopPlay()
    }
}
