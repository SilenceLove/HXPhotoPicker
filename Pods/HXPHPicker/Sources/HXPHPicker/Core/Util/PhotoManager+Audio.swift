//
//  PhotoManager+Audio.swift
//  HXPHPicker
//
//  Created by Slience on 2021/6/28.
//

import AVKit

extension PhotoManager: AVAudioPlayerDelegate {
    
    @discardableResult
    func playMusic(filePath path: String, finished: @escaping () -> Void) -> Bool {
        audioPlayFinish = finished
        let url = URL(fileURLWithPath: path)
        if let currentURL = audioPlayer?.url,
           currentURL.absoluteString == url.absoluteString {
            audioPlayer?.currentTime = 0
            audioPlayer?.play()
            return true
        }
        do {
            try audioSession.setCategory(.playback)
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            return true
        } catch {
            audioPlayFinish = nil
            return false
        }
    }
    
    func stopPlayMusic() {
        audioPlayer?.stop()
        audioPlayer = nil
        audioPlayFinish = nil
    }
    
    
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            audioPlayer?.currentTime = 0
            audioPlayer?.play()
            audioPlayFinish?()
        }
    }
}
