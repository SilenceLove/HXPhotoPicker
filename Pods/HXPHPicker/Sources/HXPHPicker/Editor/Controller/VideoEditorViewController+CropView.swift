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
        if state == .cropping && !orientationDidChange {
            stopPlayTimer()
            playerView.shouldPlay = false
            playerView.playStartTime = time
            playerView.pause()
            playerView.seek(to: time)
            cropView.stopLineAnimation()
        }
    }
    func startPlay(at time: CMTime) {
        if state == .cropping && !orientationDidChange {
            playerView.playStartTime = time
            playerView.playEndTime = cropView.getEndTime(real: true)
            playerView.resetPlay()
            playerView.shouldPlay = true
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
            let seconds = playerView.player.currentTime().seconds - cropView.getStartTime(real: true).seconds
            microseconds = seconds * 1000000
        }
        playTimer.schedule(deadline: .now(), repeating: .microseconds(Int(microseconds)), leeway: .microseconds(0))
        playTimer.setEventHandler(handler: {
            DispatchQueue.main.sync {
                self.playerView.resetPlay()
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
