//
//  EditorTransition.swift
//  HXPHPicker
//
//  Created by Slience on 2021/10/5.
//

import UIKit
import Photos

public enum EditorTransitionMode {
    case push
    case pop
//    case present
//    case dismiss
}

class EditorTransition: NSObject, UIViewControllerAnimatedTransitioning {
    let mode: EditorTransitionMode
    var requestID: PHImageRequestID?
    lazy var previewView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    var transitionView: UIView?
    
    init(mode: EditorTransitionMode) {
        self.mode = mode
        super.init()
    }
    
    func transitionDuration(
        using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        if let editorVC = transitionContext?.viewController(
            forKey: mode == .push ? .to : .from
        ) as? PhotoEditorViewController {
            return editorVC.delegate?.photoEditorViewController(editorVC, transitionDuration: mode) ?? 0.55
        }
        if let editorVC = transitionContext?.viewController(
            forKey: mode == .push ? .to : .from
        ) as? VideoEditorViewController {
            return editorVC.delegate?.videoEditorViewController(editorVC, transitionDuration: mode) ?? 0.55
        }
        return 0.55
    }
    func animateTransition(
        using transitionContext: UIViewControllerContextTransitioning
    ) {
        if mode == .push || mode == .pop {
            pushTransition(using: transitionContext)
        }
    }
    // swiftlint:disable cyclomatic_complexity
    // swiftlint:disable function_body_length
    func pushTransition(
        using transitionContext: UIViewControllerContextTransitioning
    ) {
        // swiftlint:enable cyclomatic_complexity
        // swiftlint:enable function_body_length
        guard let fromVC = transitionContext.viewController(forKey: .from),
              let toVC = transitionContext.viewController(forKey: .to) else {
            return
        }
        let containerView = transitionContext.containerView
        let contentView = UIView(frame: fromVC.view.bounds)
        if mode == .push {
            containerView.addSubview(fromVC.view)
            containerView.addSubview(toVC.view)
            #if HXPICKER_ENABLE_PICKER
            if fromVC is PhotoPickerViewController || fromVC is PhotoPreviewViewController {
                fromVC.view.insertSubview(contentView, at: 1)
            }else {
                fromVC.view.addSubview(contentView)
            }
            #else
            fromVC.view.addSubview(contentView)
            #endif
            contentView.backgroundColor = .clear
        }else {
            containerView.addSubview(toVC.view)
            containerView.addSubview(fromVC.view)
            #if HXPICKER_ENABLE_PICKER
            if let pickerVC = toVC as? PhotoPickerViewController {
                pickerVC.bottomView.alpha = 0
                toVC.view.insertSubview(contentView, at: 1)
            }else if let previewVC = toVC as? PhotoPreviewViewController {
                previewVC.bottomView.alpha = 0
                toVC.view.insertSubview(contentView, at: 1)
            }else {
                toVC.view.addSubview(contentView)
            }
            #else
            toVC.view.addSubview(contentView)
            #endif
            contentView.backgroundColor = .black
        }
        contentView.addSubview(previewView)
        #if HXPICKER_ENABLE_PICKER
        var photoAsset: PhotoAsset?
        #endif
        var fromRect: CGRect = .zero
        var toRect: CGRect = .zero
        var imageTransform: CGAffineTransform?
        let editorVC = mode == .push ? toVC : fromVC
        var isSpring: Bool = true
        if let editorVC = editorVC as? PhotoEditorViewController {
            if mode == .push {
                editorVC.transitionCompletion = false
                if editorVC.state == .cropping {
                    isSpring = false
                }
                if editorVC.config.fixedCropState {
                    editorVC.cropToolView.alpha = 0
                    editorVC.cropConfirmView.alpha = 0
                }else {
                    editorVC.toolView.alpha = 0
                }
                if let view = editorVC.delegate?.photoEditorViewController(transitioBegenPreviewView: editorVC) {
                    transitionView = view
                    fromRect = view.convert(view.bounds, to: contentView)
                }else {
                    fromRect = editorVC.delegate?.photoEditorViewController(
                        transitioBegenPreviewFrame: editorVC
                    ) ?? .zero
                }
                let image = editorVC.delegate?.photoEditorViewController(transitionPreviewImage: editorVC)
                previewView.image = image
                if let image = image {
                    editorVC.imageView.frame = editorVC.view.bounds
                    editorVC.imageView.setImage(image)
                }
                #if HXPICKER_ENABLE_PICKER
                photoAsset = editorVC.photoAsset
                if let photoAsset = photoAsset {
                    toRect = editorVC.imageView.getTransitionImageViewFrame(
                        with: photoAsset.imageSize,
                        viewSize: toVC.view.size
                    )
                }else if let image = editorVC.image {
                    toRect = editorVC.imageView.getTransitionImageViewFrame(
                        with: image.size,
                        viewSize: toVC.view.size
                    )
                }else {
                    if let image = image {
                        toRect = editorVC.imageView.getTransitionImageViewFrame(
                            with: image.size,
                            viewSize: toVC.view.size
                        )
                    }else {
                        toRect = .zero
                    }
                }
                #else
                if let image = editorVC.image {
                    toRect = editorVC.imageView.getTransitionImageViewFrame(
                        with: image.size,
                        viewSize: toVC.view.size
                    )
                }else {
                    if let image = image {
                        toRect = editorVC.imageView.getTransitionImageViewFrame(
                            with: image.size,
                            viewSize: toVC.view.size
                        )
                    }else {
                        toRect = .zero
                    }
                }
                #endif
            }else {
                let view = editorVC.imageView.imageResizerView
                fromRect = view.convert(view.bounds, to: contentView)
                previewView.frame = fromRect
                let imageView = UIImageView()
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                if editorVC.isFinishedBack {
                    imageView.image = editorVC.transitionalImage
                    imageView.frame = previewView.bounds
                }else {
                    if editorVC.editResult != nil {
                        imageView.image = view.layer.convertedToImage()
                        imageView.frame = previewView.bounds
                    }else {
                        imageTransform = .identity
                        imageView.image = editorVC.transitionalImage
                        let transformRect = view.imageView.convert(view.imageView.bounds, to: previewView)
                        let imageRect = view.convert(view.imageView.bounds, to: previewView)
                        imageView.frame = imageRect
                        imageView.transform = view.scrollView.transform
                        imageView.frame = transformRect
                    }
                    if view.layer.cornerRadius > 0 && view.layer.masksToBounds {
                        previewView.layer.cornerRadius = previewView.width * 0.5
                        previewView.layer.masksToBounds = true
                    }
                }
                previewView.addSubview(imageView)
                if let view = editorVC.delegate?.photoEditorViewController(transitioEndPreviewView: editorVC) {
                    transitionView = view
                    toRect = view.convert(view.bounds, to: contentView)
                }else {
                    toRect = editorVC.delegate?.photoEditorViewController(
                        transitioEndPreviewFrame: editorVC
                    ) ?? .zero
                }
            }
            editorVC.imageView.isHidden = true
            editorVC.view.backgroundColor = .clear
        }else if let editorVC = editorVC as? VideoEditorViewController {
            if mode == .push {
                editorVC.transitionCompletion = false
                editorVC.toolView.alpha = 0
                if editorVC.state == .cropTime {
                    isSpring = false
                }
                if let view = editorVC.delegate?.videoEditorViewController(transitioBegenPreviewView: editorVC) {
                    transitionView = view
                    fromRect = view.convert(view.bounds, to: contentView)
                }else {
                    fromRect = editorVC.delegate?.videoEditorViewController(
                        transitioBegenPreviewFrame: editorVC
                    ) ?? .zero
                }
                let image = editorVC.delegate?.videoEditorViewController(transitionPreviewImage: editorVC)
                previewView.image = image
                #if HXPICKER_ENABLE_PICKER
                photoAsset = editorVC.photoAsset
                if let photoAsset = photoAsset {
                    toRect = editorVC.videoView.getTransitionImageViewFrame(
                        with: photoAsset.imageSize,
                        viewSize: toVC.view.size
                    )
                }else {
                    if let image = image {
                        toRect = editorVC.videoView.getTransitionImageViewFrame(
                            with: image.size,
                            viewSize: toVC.view.size
                        )
                    }else {
                        toRect = .zero
                    }
                }
                #else
                if let image = image {
                    toRect = editorVC.videoView.getTransitionImageViewFrame(
                        with: image.size,
                        viewSize: toVC.view.size
                    )
                }else {
                    toRect = .zero
                }
                #endif
                if toRect.width < editorVC.view.width {
                    toRect.origin.x = (editorVC.view.width - toRect.width) * 0.5
                }
                if toRect.height < editorVC.view.height {
                    toRect.origin.y = (editorVC.view.height - toRect.height) * 0.5
                }
            }else {
                let view = editorVC.videoView.playerView
                view.playerLayer.videoGravity = .resizeAspectFill
                fromRect = view.convert(view.bounds, to: contentView)
                previewView.frame = fromRect
                previewView.addSubview(view)
                view.frame = previewView.bounds
                if let view = editorVC.delegate?.videoEditorViewController(transitioEndPreviewView: editorVC) {
                    transitionView = view
                    toRect = view.convert(view.bounds, to: contentView)
                }else {
                    toRect = editorVC.delegate?.videoEditorViewController(
                        transitioEndPreviewFrame: editorVC
                    ) ?? .zero
                }
            }
            editorVC.videoView.isHidden = true
            editorVC.view.backgroundColor = .clear
        }else {
            previewView.removeFromSuperview()
            contentView.removeFromSuperview()
            transitionContext.completeTransition(true)
            return
        }
        if mode == .push {
            #if HXPICKER_ENABLE_PICKER
            if let photoAsset = photoAsset, !(fromVC is PhotoPreviewViewController) {
                var reqeustAsset = photoAsset.phAsset != nil
                if photoAsset.videoEdit != nil || photoAsset.photoEdit != nil {
                    reqeustAsset = false
                }
                if let phAsset = photoAsset.phAsset, reqeustAsset {
                    requestAssetImage(for: phAsset)
                }else if previewView.image == nil || photoAsset.isLocalAsset {
                    previewView.image = photoAsset.originalImage
                }
            }
            #endif
        }
        previewView.frame = fromRect
        transitionView?.isHidden = true
        let duration = transitionDuration(using: transitionContext)
        UIView.animate(withDuration: duration - 0.15) {
            contentView.backgroundColor = self.mode == .push ? .black : .clear
            if self.mode == .push {
                #if HXPICKER_ENABLE_PICKER
                if let pickerVC = fromVC as? PhotoPickerViewController {
                    pickerVC.bottomView.alpha = 0
                }else if let previewVC = fromVC as? PhotoPreviewViewController {
                    previewVC.bottomView.alpha = 0
                }
                #endif
            }else if self.mode == .pop {
                #if HXPICKER_ENABLE_PICKER
                if let pickerVC = toVC as? PhotoPickerViewController {
                    pickerVC.bottomView.alpha = 1
                }else if let previewVC = toVC as? PhotoPreviewViewController {
                    previewVC.bottomView.alpha = 1
                }
                #endif
            }
            if let editorVC = editorVC as? PhotoEditorViewController {
                if editorVC.config.fixedCropState {
                    editorVC.cropToolView.alpha = self.mode == .push ? 1 : 0
                    editorVC.cropConfirmView.alpha = self.mode == .push ? 1 : 0
                }else {
                    editorVC.toolView.alpha = self.mode == .push ? 1 : 0
                }
            }else if let editorVC = editorVC as? VideoEditorViewController {
                if editorVC.state != .cropTime {
                    editorVC.toolView.alpha = self.mode == .push ? 1 : 0
                }
                if self.mode == .pop {
                    if editorVC.onceState == .cropTime {
                        editorVC.cropView.alpha = 0
                        editorVC.cropConfirmView.alpha = 0
                    }
                }
            }
        }
        let tempView = UIView()
        let frameIsSame = previewView.frame.equalTo(toRect)
        if frameIsSame {
            contentView.addSubview(tempView)
        }
        animate(
            withDuration: duration,
            isSpring: isSpring
        ) { [weak self] in
            guard let self = self else { return }
            if toRect.equalTo(.zero) {
                self.previewView.alpha = 0
                return
            }
            if frameIsSame {
                tempView.alpha = 0
            }else {
                self.previewView.frame = toRect
            }
            if self.previewView.layer.cornerRadius > 0 {
                self.previewView.layer.cornerRadius = self.previewView.width * 0.5
            }
            if let subView = self.previewView.subviews.first {
                subView.frame = CGRect(origin: .zero, size: toRect.size)
                if let transform = imageTransform {
                    subView.transform = transform
                }
            }
        } completion: { [weak self] isFinished in
            guard let self = self else {
                contentView.removeFromSuperview()
                transitionContext.completeTransition(true)
                return
            }
            self.transitionView?.isHidden = false
            if self.mode == .push {
                if let requestID = self.requestID {
                    PHImageManager.default().cancelImageRequest(requestID)
                    self.requestID = nil
                }
                #if HXPICKER_ENABLE_PICKER
                if let pickerVC = fromVC as? PhotoPickerViewController {
                    pickerVC.bottomView.alpha = 1
                }else if let previewVC = fromVC as? PhotoPreviewViewController {
                    previewVC.bottomView.alpha = 1
                }
                #endif
                if let editorVC = editorVC as? PhotoEditorViewController {
                    if let image = self.previewView.image,
                       editorVC.editResult == nil,
                       editorVC.imageView.image == nil {
                        editorVC.imageView.setImage(image)
                    }
                    editorVC.view.backgroundColor = .black
                    editorVC.imageView.isHidden = false
                    editorVC.transitionCompletion = true
                    editorVC.initializeStartCropping()
                }else if let editorVC = editorVC as? VideoEditorViewController {
                    editorVC.view.backgroundColor = .black
                    editorVC.videoView.isHidden = false
                    editorVC.transitionCompletion = true
                    if editorVC.reqeustAssetCompletion {
                        editorVC.setAsset()
                    }
                }
                self.previewView.removeFromSuperview()
                contentView.removeFromSuperview()
                transitionContext.completeTransition(true)
            }else if self.mode == .pop {
                #if HXPICKER_ENABLE_PICKER
                if let previewVC = toVC as? PhotoPreviewViewController {
                    previewVC.navigationController?.delegate = previewVC.beforeNavDelegate
                }
                #endif
                UIView.animate(
                    withDuration: 0.25,
                    delay: 0,
                    options: [.allowUserInteraction]) {
                    self.previewView.alpha = 0
                } completion: { (isFinished) in
                    self.previewView.removeFromSuperview()
                    contentView.removeFromSuperview()
                    transitionContext.completeTransition(true)
                }
            }
        }
    }
    
    func animate(
        withDuration duration: TimeInterval,
        isSpring: Bool,
        animations: @escaping () -> Void,
        completion: ((Bool) -> Void)? = nil
    ) {
        if isSpring {
            UIView.animate(
                withDuration: duration,
                delay: 0,
                usingSpringWithDamping: 0.8,
                initialSpringVelocity: 0,
                options: [.layoutSubviews, .curveEaseOut]
            ) {
                animations()
            } completion: { isFinished in
                completion?(isFinished)
            }
        }else {
            UIView.animate(
                withDuration: duration,
                animations: animations,
                completion: completion
            )
        }
    }
    
    func requestAssetImage(for asset: PHAsset) {
        let options = PHImageRequestOptions()
        options.resizeMode = .fast
        requestID = AssetManager.requestImageData(
            for: asset,
            options: options
        ) { (result) in
            var info: [AnyHashable: Any]?
            switch result {
            case .success(let dataResult):
                info = dataResult.info
                DispatchQueue.global().async {
                    var image: UIImage?
                    if dataResult.imageOrientation != .up {
                        image = UIImage(data: dataResult.imageData)?.normalizedImage()
                    }else {
                        image = UIImage(data: dataResult.imageData)
                    }
                    if !AssetManager.assetIsDegraded(for: info) &&
                        dataResult.imageData.count > 3000000 {
                        image = image?.scaleSuitableSize()
                    }
                    DispatchQueue.main.async {
                        if self.previewView.superview != nil {
                            self.previewView.image = image
                        }
                    }
                }
            case .failure(let error):
                info = error.info
            }
            if AssetManager.assetDownloadFinined(for: info) ||
                AssetManager.assetCancelDownload(for: info) {
                self.requestID = nil
            }
        }
    }
}
