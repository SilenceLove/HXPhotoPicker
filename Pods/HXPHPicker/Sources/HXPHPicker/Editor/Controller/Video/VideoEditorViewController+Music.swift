//
//  VideoEditorViewController+Music.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/6.
//

import UIKit

// MARK: VideoEditorMusicViewDelegate
extension VideoEditorViewController: VideoEditorMusicViewDelegate {
    func removeAudioSticker() {
        videoView.imageResizerView.imageView.stickerView.removeAudioView()
    }
    func musicView(_ musicView: VideoEditorMusicView, didShowLyricButton isSelected: Bool, music: VideoEditorMusic?) {
        removeAudioSticker()
        if !isSelected {
            return
        }
        let item = EditorStickerItem(
            image: UIImage(),
            imageData: nil,
            text: nil,
            music: music ?? otherMusic
        )
        if item.music == nil {
            return
        }
        videoView.addSticker(item: item, isSelected: false)
    }
    func musicView(_ musicView: VideoEditorMusicView, didSelectMusic audioPath: String?) {
        backgroundMusicPath = audioPath
        otherMusic = nil
        PhotoManager.shared.changeAudioPlayerVolume(backgroundMusicVolume)
    }
    func musicView(deselectMusic musicView: VideoEditorMusicView) {
        backgroundMusicPath = nil
        removeAudioSticker()
    }
    func musicView(didSearchButton musicView: VideoEditorMusicView) {
        searchMusicView.searchView.becomeFirstResponder()
        isSearchMusic = true
        UIView.animate(withDuration: 0.25) {
            self.setSearchMusicViewFrame()
        }
    }
    func musicView(didVolumeButton musicView: VideoEditorMusicView) {
        showVolumeView()
    }
    func musicView(_ musicView: VideoEditorMusicView, didOriginalSoundButtonClick isSelected: Bool) {
        hasOriginalSound = isSelected
        if isSelected {
            videoView.playerView.player.volume = videoVolume
        }else {
            videoView.playerView.player.volume = 0
        }
    }
    func showVolumeView() {
        isShowVolume = true
        UIView.animate(withDuration: 0.25) {
            self.setVolumeViewFrame()
            self.musicView.alpha = 0
        }
    }
    func hiddenVolumeView() {
        isShowVolume = false
        UIView.animate(withDuration: 0.25) {
            self.setVolumeViewFrame()
            self.musicView.alpha = 1
        }
    }
}

// MARK: VideoEditorSearchMusicViewDelegate
extension VideoEditorViewController: VideoEditorSearchMusicViewDelegate {
    func searchMusicView(didCancelClick searchMusicView: VideoEditorSearchMusicView) {
        hideSearchMusicView()
    }
    func searchMusicView(didFinishClick searchMusicView: VideoEditorSearchMusicView) {
        hideSearchMusicView(deselect: false)
    }
    func searchMusicView(
        _ searchMusicView: VideoEditorSearchMusicView,
        didSelectItem audioPath: String?, music: VideoEditorMusic
    ) {
        musicView.reset()
        musicView.backgroundButton.isSelected = true
        musicView(musicView, didShowLyricButton: true, music: music)
        musicView.showLyricButton.isSelected = true
        backgroundMusicPath = audioPath
        otherMusic = music
    }
    func searchMusicView(
        _ searchMusicView: VideoEditorSearchMusicView,
        didSearch text: String?,
        completion: @escaping ([VideoEditorMusicInfo], Bool
        ) -> Void) {
        delegate?.videoEditorViewController(self, didSearch: text, completionHandler: completion)
    }
    func searchMusicView(
        _ searchMusicView: VideoEditorSearchMusicView,
        loadMore text: String?,
        completion: @escaping ([VideoEditorMusicInfo], Bool) -> Void
    ) {
        delegate?.videoEditorViewController(self, loadMore: text, completionHandler: completion)
    }
    func searchMusicView(
        deselectItem searchMusicView: VideoEditorSearchMusicView
    ) {
        backgroundMusicPath = nil
        musicView.backgroundButton.isSelected = false
        musicView(musicView, didShowLyricButton: false, music: nil)
        musicView.showLyricButton.isSelected = false
        otherMusic = nil
    }
    func hideSearchMusicView(deselect: Bool = true) {
        searchMusicView.endEditing(true)
        isSearchMusic = false
        UIView.animate(withDuration: 0.25) {
            self.setSearchMusicViewFrame()
        } completion: { _ in
            if deselect {
                self.searchMusicView.deselect()
            }
            self.searchMusicView.clearData()
        }
    }
}

// MARK: VideoEditorVolumeViewDelegate
extension VideoEditorViewController: VideoEditorVolumeViewDelegate {
    func volumeView(didChanged volumeView: VideoEditorVolumeView) {
        backgroundMusicVolume = volumeView.musicVolume
        if hasOriginalSound {
            videoVolume = volumeView.originalVolume
        }
    }
}
