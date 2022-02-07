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
        videoView.deselectedSticker()
        let timeRang: CMTimeRange
        if let startTime = videoView.playerView.playStartTime,
           let endTime = videoView.playerView.playEndTime {
            if endTime.seconds - startTime.seconds > config.cropTime.maximumVideoCroppingTime {
                let seconds = Double(config.cropTime.maximumVideoCroppingTime)
                timeRang = CMTimeRange(
                    start: startTime,
                    duration: CMTime(
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
        if backgroundMusicPath != nil || videoVolume < 1 || !hasOriginalSound {
            hasAudio = true
        }else {
            hasAudio = false
        }
        let hasCropSize: Bool
        if videoView.canReset() ||
            videoView.imageResizerView.hasCropping ||
            videoView.canUndoDraw ||
            videoView.hasFilter ||
            videoView.hasSticker ||
            videoView.imageResizerView.videoFilter != nil {
            hasCropSize = true
        }else {
            hasCropSize = false
        }
        if hasAudio || timeRang != .zero || hasCropSize {
            exportLoadingView = ProgressHUD.showProgress(
                addedTo: view,
                text: "正在处理...".localized,
                animated: true
            )
            exportVideoURL(
                timeRang: timeRang,
                hasCropSize: hasCropSize,
                cropSizeData: videoView.getVideoCropData()
            )
            return
        }
        delegate?.videoEditorViewController(didFinishWithUnedited: self)
        finishHandler?(self, nil)
        backAction()
    }
    func exportVideoURL(
        timeRang: CMTimeRange,
        hasCropSize: Bool,
        cropSizeData: VideoEditorCropSizeData
    ) {
        avAsset.loadValuesAsynchronously(
            forKeys: ["tracks"]
        ) { [weak self] in
            guard let self = self else { return }
            DispatchQueue.global().async {
                if self.avAsset.statusOfValue(forKey: "tracks", error: nil) != .loaded {
                    self.showErrorHUD()
                    return
                }
                var audioURL: URL?
                if let musicPath = self.backgroundMusicPath {
                    audioURL = URL(fileURLWithPath: musicPath)
                }
                self.exportSession = PhotoTools.exportEditVideo(
                    for: self.avAsset,
                    outputURL: self.config.videoExportURL,
                    timeRang: timeRang,
                    cropSizeData: cropSizeData,
                    audioURL: audioURL,
                    audioVolume: self.backgroundMusicVolume,
                       originalAudioVolume: self.hasOriginalSound ? self.videoVolume : 0,
                    exportPreset: self.config.exportPreset,
                    videoQuality: self.config.videoQuality
                ) {  [weak self] videoURL, error in
                    if let videoURL = videoURL {
                        ProgressHUD.hide(forView: self?.view, animated: true)
                        self?.editFinishCallBack(videoURL)
                        self?.backAction()
                    }else {
                        self?.showErrorHUD()
                    }
                }
                DispatchQueue.main.async {
                    Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
                        guard let self = self,
                              let session = self.exportSession else {
                            timer.invalidate()
                            return
                        }
                        let progress = session.progress
                        self.exportLoadingView?.progress = CGFloat(progress)
                        if progress >= 1 ||
                            session.status == .completed ||
                            session.status == .failed ||
                            session.status == .cancelled {
                            timer.invalidate()
                        }
                    }
                }
            }
        }
    }
    func showErrorHUD() {
        ProgressHUD.hide(forView: view, animated: true)
        ProgressHUD.showWarning(addedTo: view, text: "处理失败".localized, animated: true, delayHide: 1.5)
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
        if let startTime = videoView.playerView.playStartTime,
           let endTime = videoView.playerView.playEndTime,
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
        let editResult = VideoEditResult(
            editedURL: videoURL,
            cropData: cropData,
            hasOriginalSound: hasOriginalSound,
            videoSoundVolume: videoVolume,
            backgroundMusicURL: backgroundMusicURL,
            backgroundMusicVolume: backgroundMusicVolume,
            sizeData: videoView.getVideoEditedData()
        )
        delegate?.videoEditorViewController(self, didFinish: editResult)
        finishHandler?(self, editResult)
    }
    func toolView(_ toolView: EditorToolView, didSelectItemAt model: EditorToolOptions) {
        videoView.stickerEnabled = false
        videoView.deselectedSticker()
        switch model.type {
        case .graffiti:
            toolGraffitiClick()
        case .music:
            toolMusicClick()
        case .cropSize:
            toolCropSizeClick()
        case .cropTime:
            toolCropTimeClick()
        case .chartlet:
            toolChartletClick()
        case .text:
            toolTextClick()
        case .filter:
            toolFilterClick()
        default:
            break
        }
    }
    
    func toolGraffitiClick() {
        videoView.drawEnabled = !videoView.drawEnabled
        toolView.stretchMask = videoView.drawEnabled
        toolView.layoutSubviews()
        if videoView.drawEnabled {
            videoView.stickerEnabled = false
            showBrushColorView()
        }else {
            videoView.stickerEnabled = true
            hiddenBrushColorView()
        }
    }
    
    func toolMusicClick() {
        if let shouldClick = delegate?.videoEditorViewController(shouldClickMusicTool: self),
           !shouldClick {
            return
        }
        toolView.deselected()
        videoView.drawEnabled = false
        hiddenBrushColorView()
        if musicView.musics.isEmpty {
            if let loadHandler = config.music.handler {
                let showLoading = loadHandler { [weak self] infos in
                    self?.musicView.reloadData(infos: infos)
                }
                if showLoading {
                    musicView.showLoading()
                }
            }else {
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
                        ProgressHUD.showWarning(
                            addedTo: view,
                            text: "暂无配乐".localized,
                            animated: true,
                            delayHide: 1.5
                        )
                        return
                    }else {
                        musicView.reloadData(infos: infos)
                    }
                }
            }
        }
        isMusicState = !isMusicState
        musicView.reloadContentOffset()
        updateMusicView()
        hidenTopView()
    }
    
    func toolCropSizeClick() {
        toolView.deselected()
        videoView.drawEnabled = false
        hiddenBrushColorView()
        videoView.stickerEnabled = false
        videoView.startCropping(true)
        pState = .cropSize
        toolCropSizeAnimation()
    }
    
    func toolCropSizeAnimation() {
        if state == .cropSize {
            cropConfirmView.showReset = true
            cropConfirmView.isHidden = false
            cropToolView.isHidden = false
            hidenTopView()
        }else {
            showTopView()
        }
        UIView.animate(withDuration: 0.25) {
            self.cropConfirmView.alpha = self.state == .cropSize ? 1 : 0
            self.cropToolView.alpha = self.state == .cropSize ? 1 : 0
        } completion: { (isFinished) in
            if self.state != .cropSize {
                self.cropConfirmView.isHidden = true
                self.cropToolView.isHidden = true
            }
        }
    }
    
    func toolChartletClick() {
        toolView.deselected()
        videoView.drawEnabled = false
        hiddenBrushColorView()
        chartletView.firstRequest()
        showChartlet = true
        hidenTopView()
        showChartletView()
    }
    
    func toolTextClick() {
        toolView.deselected()
        videoView.drawEnabled = false
        hiddenBrushColorView()
        videoView.stickerEnabled = true
        if config.text.modalPresentationStyle == .fullScreen {
            isPresentText = true
        }
        let textVC = EditorStickerTextViewController(config: config.text)
        textVC.delegate = self
        let nav = EditorStickerTextController(rootViewController: textVC)
        nav.modalPresentationStyle = config.text.modalPresentationStyle
        present(nav, animated: true, completion: nil)
    }
    
    func toolFilterClick() {
        toolView.deselected()
        videoView.drawEnabled = false
        videoView.stickerEnabled = false
        hiddenBrushColorView()
        hidenTopView()
        showFilterView()
        videoView.canLookOriginal = true
    }
    
    func showBrushColorView() {
        brushColorView.isHidden = false
        UIView.animate(withDuration: 0.25) {
            self.brushColorView.alpha = 1
        }
    }
    
    func hiddenBrushColorView() {
        if brushColorView.isHidden {
            return
        }
        UIView.animate(withDuration: 0.25) {
            self.brushColorView.alpha = 0
        } completion: { (_) in
            if self.videoView.drawEnabled { return }
            self.brushColorView.isHidden = true
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
    
    /// 进入裁剪时长界面
    func toolCropTimeClick() {
        if state == .normal {
            toolView.deselected()
            videoView.drawEnabled = false
            hiddenBrushColorView()
            cropConfirmView.showReset = false
            beforeStartTime = videoView.playerView.playStartTime
            beforeEndTime = videoView.playerView.playEndTime
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
                cropView.startLineAnimation(at: videoView.playerView.player.currentTime())
            }
            videoView.playerView.playStartTime = cropView.getStartTime(real: true)
            videoView.playerView.playEndTime = cropView.getEndTime(real: true)
            cropConfirmView.isHidden = false
            cropView.isHidden = false
            cropView.updateTimeLabels()
            pState = .cropTime
            if currentValidRect.equalTo(.zero) {
                videoView.playerView.resetPlay()
                startPlayTimer()
            }
            hidenTopView()
            videoView.startCropTime(true)
            UIView.animate(withDuration: 0.25, delay: 0, options: [.layoutSubviews]) {
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
        videoView.updateSticker(item: stickerItem)
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
        videoView.addSticker(item: item, isSelected: false)
    }
}

extension VideoEditorViewController: PhotoEditorCropToolViewDelegate {
    func cropToolView(didRotateButtonClick cropToolView: PhotoEditorCropToolView) {
        videoView.rotate()
    }
    
    func cropToolView(didMirrorHorizontallyButtonClick cropToolView: PhotoEditorCropToolView) {
        videoView.mirrorHorizontally(animated: true)
    }
    
    func cropToolView(didChangedAspectRatio cropToolView: PhotoEditorCropToolView, at model: PhotoEditorCropToolModel) {
        videoView.changedAspectRatio(of: CGSize(width: model.widthRatio, height: model.heightRatio))
    }
}
