//
//  VideoEditorViewController+CropView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/6.
//

import UIKit
import AVKit

// MARK: VideoEditorCropViewDelegate
extension VideoEditorViewController: VideoEditorCropViewDelegate {
    func cropView(_ cropView: VideoEditorCropView, didScrollAt time: CMTime) {
        pausePlay(at: time)
    }
    func cropView(_ cropView: VideoEditorCropView, endScrollAt time: CMTime) {
        startPlay(at: time)
    }
    func cropView(_ cropView: VideoEditorCropView, didChangedValidRectAt time: CMTime) {
        pausePlay(at: time)
    }
    func cropView(_ cropView: VideoEditorCropView, endChangedValidRectAt time: CMTime) {
        startPlay(at: time)
    }
    func cropView(_ cropView: VideoEditorCropView, progressLineDragEndAt time: CMTime) {
        
    }
    func cropView(_ cropView: VideoEditorCropView, progressLineDragBeganAt time: CMTime) {
        
    }
    func cropView(_ cropView: VideoEditorCropView, progressLineDragChangedAt time: CMTime) {
        
    }
    func pausePlay(at time: CMTime) {
        if state == .cropTime && !orientationDidChange {
            stopPlayTimer()
            videoView.playerView.shouldPlay = false
            videoView.playerView.playStartTime = time
            videoView.playerView.pause()
            videoView.playerView.seek(to: time)
            cropView.stopLineAnimation()
        }
    }
    func startPlay(at time: CMTime) {
        if state == .cropTime && !orientationDidChange {
            videoView.playerView.playStartTime = time
            videoView.playerView.playEndTime = cropView.getEndTime(real: true)
            videoView.playerView.resetPlay()
            videoView.playerView.shouldPlay = true
            startPlayTimer()
        }
    }
    func startPlayTimer(reset: Bool = true) {
        startPlayTimer(
            reset: reset,
            startTime: cropView.getStartTime(real: true),
            endTime: cropView.getEndTime(real: true)
        )
    }
    func startPlayTimer(reset: Bool = true, startTime: CMTime, endTime: CMTime) {
        stopPlayTimer()
        let playTimer = DispatchSource.makeTimerSource()
        var microseconds: Double
        if reset {
            microseconds = (endTime.seconds - startTime.seconds) * 1000000
        }else {
            let seconds = videoView.playerView.player.currentTime().seconds - cropView.getStartTime(real: true).seconds
            microseconds = seconds * 1000000
        }
        playTimer.schedule(deadline: .now(), repeating: .microseconds(Int(microseconds)), leeway: .microseconds(0))
        playTimer.setEventHandler(handler: {
            DispatchQueue.main.sync {
                self.videoView.playerView.resetPlay { [weak self] time in
                    guard let self = self else { return }
                    self.cropView.startLineAnimation(at: time)
                }
            }
        })
        playTimer.resume()
        self.playTimer = playTimer
    }
    func stopPlayTimer() {
        if let playTimer = playTimer {
            playTimer.cancel()
            self.playTimer = nil
        }
    }
}
