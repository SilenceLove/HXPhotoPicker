//
//  VideoEditorViewController+ToolView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/6.
//

import UIKit
import AVKit

// MARK: EditorToolViewDelegate
extension VideoEditorViewController: EditorToolViewDelegate {
    
    /// 导出视频
    /// - Parameter toolView: 底部工具视频
    func toolView(didFinishButtonClick toolView: EditorToolView) {
        playerView.stickerView.deselectedSticker()
        let hasSticker = playerView.stickerView.count > 0
        let timeRang: CMTimeRange
        if let startTime = playerView.playStartTime,
           let endTime = playerView.playEndTime {
            if endTime.seconds - startTime.seconds > config.cropping.maximumVideoCroppingTime {
                let seconds = Double(config.cropping.maximumVideoCroppingTime)
                timeRang = CMTimeRange(
                    start: startTime,
                    end: CMTime(
                        seconds: seconds,
                        preferredTimescale: endTime.timescale
                    )
                )
            }else {
                timeRang = CMTimeRange(start: startTime, end: endTime)
            }
        }else {
            timeRang = .zero
        }
        let hasAudio: Bool
        if backgroundMusicPath != nil || playerView.player.volume < 1 {
            hasAudio = true
        }else {
            hasAudio = false
        }
        if hasAudio || timeRang != .zero || hasSticker {
            let stickerInfos = playerView.stickerView.getStickerInfo()
            ProgressHUD.showLoading(
                addedTo: view,
                text: "视频导出中".localized,
                animated: true
            )
            exportVideoURL(
                timeRang: timeRang,
                hasSticker: hasSticker,
                stickerInfos: stickerInfos
            )
            return
        }
        delegate?.videoEditorViewController(didFinishWithUnedited: self)
        backAction()
    }
    func exportVideoURL(
        timeRang: CMTimeRange,
        hasSticker: Bool,
        stickerInfos: [EditorStickerInfo]
    ) {
        DispatchQueue.global().async {
            var audioURL: URL?
            if let musicPath = self.backgroundMusicPath {
                audioURL = URL(fileURLWithPath: musicPath)
            }
            self.exportSession = PhotoTools.exportEditVideo(
                for: self.avAsset,
                outputURL: self.config.videoExportURL,
                timeRang: timeRang,
                stickerInfos: stickerInfos,
                audioURL: audioURL,
                audioVolume: self.backgroundMusicVolume,
                originalAudioVolume: self.playerView.player.volume,
                exportPreset: self.config.exportPreset,
                videoQuality: self.config.videoQuality
            ) {  [weak self] videoURL, error in
                if let videoURL = videoURL {
                    self?.editFinishCallBack(videoURL)
                    self?.backAction()
                }else {
                    self?.showErrorHUD()
                }
            }
        }
    }
    func showErrorHUD() {
        ProgressHUD.hide(forView: view, animated: true)
        ProgressHUD.showWarning(addedTo: view, text: "导出失败".localized, animated: true, delayHide: 1.5)
    }
    func editFinishCallBack(_ videoURL: URL) {
        if let currentCropOffset = currentCropOffset {
            rotateBeforeStorageData = cropView.getRotateBeforeData(
                offsetX: currentCropOffset.x,
                validX: currentValidRect.minX,
                validWidth: currentValidRect.width
            )
        }
        rotateBeforeData = cropView.getRotateBeforeData()
        var cropData: VideoCropData?
        if let startTime = playerView.playStartTime,
           let endTime = playerView.playEndTime,
           let rotateBeforeStorageData = rotateBeforeStorageData,
           let rotateBeforeData = rotateBeforeData {
            cropData = VideoCropData(
                startTime: startTime.seconds,
                endTime: endTime.seconds,
                preferredTimescale: avAsset.duration.timescale,
                cropingData: .init(
                    offsetX: rotateBeforeStorageData.0,
                    validX: rotateBeforeStorageData.1,
                    validWidth: rotateBeforeStorageData.2
                ),
                cropRectData: .init(
                    offsetX: rotateBeforeData.0,
                    validX: rotateBeforeData.1,
                    validWidth: rotateBeforeData.2
                )
            )
        }
        var backgroundMusicURL: URL?
        if let audioPath = backgroundMusicPath {
            backgroundMusicURL = URL(fileURLWithPath: audioPath)
        }
        let stickerData = playerView.stickerView.stickerData()
        let editResult = VideoEditResult(
            editedURL: videoURL,
            cropData: cropData,
            videoSoundVolume: playerView.player.volume,
            backgroundMusicURL: backgroundMusicURL,
            backgroundMusicVolume: backgroundMusicVolume,
            stickerData: stickerData
        )
        delegate?.videoEditorViewController(self, didFinish: editResult)
    }
    func toolView(_ toolView: EditorToolView, didSelectItemAt model: EditorToolOptions) {
        playerView.stickerView.isUserInteractionEnabled = false
        playerView.stickerView.deselectedSticker()
        if model.type == .music {
            if let shouldClick = delegate?.videoEditorViewController(shouldClickMusicTool: self),
               !shouldClick {
                return
            }
            if musicView.musics.isEmpty {
                if let editorDelegate = delegate {
                    if editorDelegate.videoEditorViewController(
                        self,
                        loadMusic: { [weak self] infos in
                            self?.musicView.reloadData(infos: infos)
                    }) {
                        musicView.showLoading()
                    }
                }else {
                    let infos = PhotoTools.defaultMusicInfos()
                    if infos.isEmpty {
                        ProgressHUD.showWarning(addedTo: view, text: "暂无配乐".localized, animated: true, delayHide: 1.5)
                        return
                    }else {
                        musicView.reloadData(infos: infos)
                    }
                }
            }
            isMusicState = !isMusicState
            musicView.reloadContentOffset()
            updateMusicView()
            hidenTopView()
        }else if model.type == .cropping {
            croppingAction()
        }else if model.type == .chartlet {
            chartletView.firstRequest()
            showChartlet = true
            hidenTopView()
            showChartletView()
        }else if model.type == .text {
            playerView.stickerView.isUserInteractionEnabled = true
            if config.text.modalPresentationStyle == .fullScreen {
                isPresentText = true
            }
            let textVC = EditorStickerTextViewController(config: config.text)
            textVC.delegate = self
            let nav = EditorStickerTextController(rootViewController: textVC)
            nav.modalPresentationStyle = config.text.modalPresentationStyle
            present(nav, animated: true, completion: nil)
        }
    }
    
    func showChartletView() {
        UIView.animate(withDuration: 0.25) {
            self.setChartletViewFrame()
        }
    }
    func hiddenChartletView() {
        UIView.animate(withDuration: 0.25) {
            self.setChartletViewFrame()
        }
    }
    
    func updateMusicView() {
        UIView.animate(withDuration: 0.25) {
            self.toolView.alpha = self.isMusicState ? 0 : 1
            self.setMusicViewFrame()
        } completion: { (_) in
            self.toolView.alpha = self.isMusicState ? 0 : 1
            self.setMusicViewFrame()
        }
    }
    
    /// 进入裁剪界面
    func croppingAction() {
        if state == .normal {
            beforeStartTime = playerView.playStartTime
            beforeEndTime = playerView.playEndTime
            if let offset = currentCropOffset {
                cropView.collectionView.setContentOffset(offset, animated: false)
            }else {
                let insetLeft = cropView.collectionView.contentInset.left
                let insetTop = cropView.collectionView.contentInset.top
                cropView.collectionView.setContentOffset(CGPoint(x: -insetLeft, y: -insetTop), animated: false)
            }
            if currentValidRect.equalTo(.zero) {
                cropView.resetValidRect()
            }else {
                cropView.frameMaskView.validRect = currentValidRect
                cropView.startLineAnimation(at: playerView.player.currentTime())
            }
            playerView.playStartTime = cropView.getStartTime(real: true)
            playerView.playEndTime = cropView.getEndTime(real: true)
            cropConfirmView.isHidden = false
            cropView.isHidden = false
            cropView.updateTimeLabels()
            pState = .cropping
            if currentValidRect.equalTo(.zero) {
                playerView.resetPlay()
                startPlayTimer()
            }
            hidenTopView()
            UIView.animate(withDuration: 0.25, delay: 0, options: [.layoutSubviews]) {
                self.setupScrollViewScale()
                self.cropView.alpha = 1
                self.cropConfirmView.alpha = 1
            }
        }
    }
}

extension VideoEditorViewController: EditorStickerTextViewControllerDelegate {
    
    func stickerTextViewController(
        _ controller: EditorStickerTextViewController,
        didFinish stickerItem: EditorStickerItem
    ) {
        playerView.stickerView.update(item: stickerItem)
    }
    
    func stickerTextViewController(
        _ controller: EditorStickerTextViewController,
        didFinish stickerText: EditorStickerText
    ) {
        let item = EditorStickerItem(
            image: stickerText.image,
            imageData: nil,
            text: stickerText
        )
        playerView.stickerView.add(
            sticker: item,
            isSelected: false
        )
    }
}
