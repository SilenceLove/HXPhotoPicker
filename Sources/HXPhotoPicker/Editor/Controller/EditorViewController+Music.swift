//
//  EditorViewController+Music.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/20.
//

import UIKit
import AVFoundation

extension EditorViewController: EditorMusicViewDelegate {
    func removeAudioSticker() {
        guard let itemView = audioSticker else {
            return
        }
        editorView.removeSticker(at: itemView)
    }
    func musicView(_ musicView: EditorMusicView, didShowLyricButton isSelected: Bool, music: VideoEditorMusic?) {
        removeAudioSticker()
        if !isSelected {
            return
        }
        deselectedDrawTool()
        updateBottomMaskLayer()
        if let music = music {
            if musicPlayer == nil {
                musicPlayer = .init()
            }
            musicPlayer?.music = music
        }
        if let music = musicPlayer?.music {
            let audio = EditorStickerAudio(music.audioURL) { [weak self] in
                guard let self = self,
                      let musicPlayer = self.musicPlayer,
                      let music = musicPlayer.music,
                      musicPlayer.audio == $0 else {
                    return nil
                }
                var texts: [EditorStickerAudioText] = []
                for lyric in music.lyrics {
                    texts.append(.init(text: lyric.lyric, startTime: lyric.startTime, endTime: lyric.endTime))
                }
                return .init(time: music.time ?? 0, texts: texts)
            }
            let itemView = editorView.addSticker(audio)
            musicPlayer?.audio = audio
            musicPlayer?.itemView = itemView
            audioSticker = itemView
        }
    }
    func musicView(_ musicView: EditorMusicView, didSelectMusic musicURL: VideoEditorMusicURL?) {
        selectedMusicURL = musicURL
        musicPlayer?.volume = musicVolume
    }
    func musicView(_ musicView: EditorMusicView, deselectMusic didStop: Bool) {
        selectedMusicURL = nil
        if didStop {
            musicPlayer?.stopPlay()
            musicPlayer = nil
            removeAudioSticker()
        }
    }
    func musicView(didSearchButton musicView: EditorMusicView) {
        let vc = EditorMusicListViewController(config: config.video.music, defaultMusics: musicView.musics)
        vc.delegate = self
        let nav = UINavigationController(rootViewController: vc)
        nav.view.backgroundColor = .clear
        present(nav, animated: true)
    }
    func musicView(didVolumeButton musicView: EditorMusicView) {
        showVolumeView()
    }
    func musicView(_ musicView: EditorMusicView, didOriginalSoundButtonClick isSelected: Bool) {
        isSelectedOriginalSound = isSelected
        if isSelected {
            editorView.videoVolume = CGFloat(videoVolume)
        }else {
            editorView.videoVolume = 0
        }
    }
    func musicView(
        _ musicView: EditorMusicView,
        didPlay musicURL: VideoEditorMusicURL,
        playCompletion: @escaping (() -> Void)
    ) -> Bool {
        if musicPlayer == nil {
            musicPlayer = .init()
        }
        let playURL: URL?
        switch musicURL {
        case .network(let url):
            playURL = PhotoTools.getAudioTmpURL(for: url.absoluteString)
        default:
            playURL = musicURL.url
        }
        if let url = playURL {
            let isPlaying = musicPlayer?.play(url)
            musicPlayer?.playCompletion = playCompletion
            musicPlayer?.volume = musicVolume
            return isPlaying ?? false
        }
        return false
    }
    func musicView(
        _ musicView: EditorMusicView,
        didPlayWithFilePath filePath: String,
        playCompletion: @escaping (() -> Void)
    ) -> Bool {
        if musicPlayer == nil {
            musicPlayer = .init()
        }
        let isPlaying = musicPlayer?.play(.init(fileURLWithPath: filePath))
        musicPlayer?.playCompletion = playCompletion
        musicPlayer?.volume = musicVolume
        return isPlaying ?? false
    }
    func musicView(_ musicView: EditorMusicView, playCompletion: @escaping (() -> Void)) {
        musicPlayer?.playCompletion = playCompletion
    }
    func musicView(playTime musicView: EditorMusicView) -> TimeInterval? {
        musicPlayer?.player?.currentTime
    }
    func musicView(musicDuration musicView: EditorMusicView) -> TimeInterval? {
        musicPlayer?.player?.duration
    }
    func musicView(stopPlay musicView: EditorMusicView) {
        musicPlayer?.stopPlay()
    }
    func showVolumeView() {
        isShowVolume = true
        UIView.animate(withDuration: 0.25) {
            self.updateVolumeViewFrame()
            self.musicView.alpha = 0
        }
    }
    func hideVolumeView() {
        isShowVolume = false
        UIView.animate(withDuration: 0.25) {
            self.updateVolumeViewFrame()
            self.musicView.alpha = 1
        }
    }
}

extension EditorViewController: EditorMusicListViewControllerDelegate {
    func musicViewController(
        _ musicViewController: EditorMusicListViewController,
        didSelectItem musicURL: VideoEditorMusicURL,
        music: VideoEditorMusic
    ) {
        if musicPlayer == nil {
            musicPlayer = .init()
        }
        musicPlayer?.music = music
        musicView.deselected()
        selectedMusicURL = musicURL
        musicView.backgroundButton.isSelected = true
        musicView.selectedMusic(music)
    }
    
    func musicViewController(
        _ musicViewController: EditorMusicListViewController,
        didSearch text: String?,
        completion: @escaping ([VideoEditorMusicInfo], Bool) -> Void
    ) {
        delegate?.editorViewController(self, didSearchMusic: text, completionHandler: completion)
    }
    
    func musicViewController(
        _ musicViewController: EditorMusicListViewController,
        loadMore text: String?,
        completion: @escaping ([VideoEditorMusicInfo], Bool) -> Void
    ) {
        delegate?.editorViewController(self, loadMoreMusic: text, completionHandler: completion)
    }
    
    func musicViewController(clearSearch musicViewController: EditorMusicListViewController) {
        delegate?.editorViewController(didClearSearch: self)
    }
    
    func musicViewController(deselectItem musicViewController: EditorMusicListViewController) {
        selectedMusicURL = nil
        musicView.backgroundButton.isSelected = false
        musicView(musicView, didShowLyricButton: false, music: nil)
        musicView.showLyricButton.isSelected = false
        musicView.selectedMusic(nil)
    }
    
    func musicViewController(
        _ musicViewController: EditorMusicListViewController,
        didPlay musicURL: VideoEditorMusicURL,
        playCompletion: @escaping (() -> Void)
    ) -> Bool {
        if musicPlayer == nil {
            musicPlayer = .init()
        }
        let playURL: URL?
        switch musicURL {
        case .network(let url):
            playURL = PhotoTools.getAudioTmpURL(for: url.absoluteString)
        default:
            playURL = musicURL.url
        }
        if let url = playURL {
            let isPlaying = musicPlayer?.play(url)
            musicPlayer?.playCompletion = playCompletion
            musicPlayer?.volume = musicVolume
            return isPlaying ?? false
        }
        return false
    }
    
    func musicViewController(
        _ musicViewController: EditorMusicListViewController,
        playCompletion: @escaping (() -> Void)
    ) {
        musicPlayer?.playCompletion = playCompletion
    }
    
    func musicViewController(playTime musicViewController: EditorMusicListViewController) -> TimeInterval? {
        musicPlayer?.player?.currentTime
    }
    
    func musicViewController(musicDuration musicViewController: EditorMusicListViewController) -> TimeInterval? {
        musicPlayer?.player?.duration
    }
    
    func musicViewController(stopPlay musicViewController: EditorMusicListViewController) {
        musicPlayer?.stopPlay()
    }
}
// MARK: EditorVolumeViewDelegate
extension EditorViewController: EditorVolumeViewDelegate {
    func volumeView(didChanged volumeView: EditorVolumeView) {
        musicVolume = volumeView.musicVolume
        if isSelectedOriginalSound {
            videoVolume = volumeView.originalVolume
        }
    }
}
