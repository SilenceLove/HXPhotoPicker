//
//  VideoEditorViewController+PlayerView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/6.
//

import UIKit
import AVKit

// MARK: VideoEditorPlayerViewDelegate
extension VideoEditorViewController: VideoEditorPlayerViewDelegate {
    func playerView(_ playerViewReadyForDisplay: VideoEditorPlayerView) {
        if firstPlay {
            croppingAction()
            firstPlay = false
        }
    }
    
    func playerView(_ playerView: VideoEditorPlayerView, didPlayAt time: CMTime) {
        if state == .cropping {
            cropView.startLineAnimation(at: time)
        }
    }
    
    func playerView(_ playerView: VideoEditorPlayerView, didPauseAt time: CMTime) {
        if state == .cropping {
            cropView.stopLineAnimation()
        }
    }
    func playerView(beganDrag playerView: VideoEditorPlayerView) {
        if !topView.isHidden {
            hidenTopView()
        }
    }
    func playerView(endDrag playerView: VideoEditorPlayerView) {
        if topView.isHidden {
            showTopView()
        }
    }
    func playerView(_ playerView: VideoEditorPlayerView, updateStickerText item: EditorStickerItem) {
        if config.text.modalPresentationStyle == .fullScreen {
            isPresentText = true
        }
        let textVC = EditorStickerTextViewController(
            config: config.text,
            stickerItem: item
        )
        textVC.delegate = self
        let nav = EditorStickerTextController(rootViewController: textVC)
        nav.modalPresentationStyle = config.text.modalPresentationStyle
        present(nav, animated: true, completion: nil)
    }
    func playerView(didRemoveAudio playerView: VideoEditorPlayerView) {
        musicView.showLyricButton.isSelected = false
    }
}

extension VideoEditorViewController: EditorChartletViewDelegate {
    func chartletView(backClick chartletView: EditorChartletView) {
        singleTap()
    }
    
    func chartletView(
        _ chartletView: EditorChartletView,
        loadTitleChartlet response: @escaping EditorTitleChartletResponse
    ) {
        if let editorDelegate = delegate {
            editorDelegate.videoEditorViewController(
                self,
                loadTitleChartlet: response
            )
        }else {
            #if canImport(Kingfisher)
            let titles = PhotoTools.defaultTitleChartlet()
            response(titles)
            #else
            response([])
            #endif
        }
    }
    
    func chartletView(
        _ chartletView: EditorChartletView,
        titleChartlet: EditorChartlet,
        titleIndex: Int,
        loadChartletList response: @escaping EditorChartletListResponse
    ) {
        if let editorDelegate = delegate {
            editorDelegate.videoEditorViewController(
                self,
                titleChartlet: titleChartlet,
                titleIndex: titleIndex,
                loadChartletList: response
            )
        }else {
            // 默认加载这些贴图
            #if canImport(Kingfisher)
            let chartletList = PhotoTools.defaultNetworkChartlet()
            response(titleIndex, chartletList)
            #else
            response(titleIndex, [])
            #endif
        }
    }
    
    func chartletView(
        _ chartletView: EditorChartletView,
        didSelectImage image: UIImage,
        imageData: Data?
    ) {
        let item = EditorStickerItem(
            image: image,
            imageData: imageData,
            text: nil
        )
        playerView.stickerView.add(sticker: item, isSelected: false)
        singleTap()
    }
}
