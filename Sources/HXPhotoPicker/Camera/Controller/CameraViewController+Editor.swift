//
//  CameraViewController+Editor.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/8/31.
//

import UIKit

#if HXPICKER_ENABLE_EDITOR && !targetEnvironment(macCatalyst)
extension CameraViewController: EditorViewControllerDelegate {
    public func editorViewController(_ editorViewController: EditorViewController, didFinish asset: EditorAsset) {
        guard let result = asset.result else {
            if let image = asset.type.image {
                didFinish(withImage: image)
            }
            if let videoURL = asset.type.videoURL {
                didFinish(withVideo: videoURL)
            }
            return
        }
        switch result {
        case .image(let editedResult, _):
            if let image = UIImage(contentsOfFile: editedResult.url.path) {
                didFinish(withImage: image)
            }
        case .video(let editedResult, _):
            didFinish(withVideo: editedResult.url)
        }
    }
}

extension CameraViewController {
    func openPhotoEditor(_ image: UIImage) {
        config.editor.isAutoBack = autoDismiss
        let vc = EditorViewController(
            .init(type: .image(image)),
            config: config.editor,
            delegate: self
        )
        navigationController?.pushViewController(vc, animated: false)
    }
}

extension CameraViewController {
    func openVideoEditor(_ videoURL: URL) {
        config.editor.isAutoBack = autoDismiss
        let vc = EditorViewController(
            .init(type: .video(videoURL)),
            config: config.editor,
            delegate: self
        )
        navigationController?.pushViewController(vc, animated: false)
    }
}
#endif
