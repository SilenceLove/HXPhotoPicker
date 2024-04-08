//
//  EditorTransition.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/10/5.
//

import UIKit
import Photos

public enum EditorTransitionMode {
    case push
    case pop
    case present
    case dismiss
}

// swiftlint:disable type_body_length
class EditorTransition: NSObject, UIViewControllerAnimatedTransitioning {
    // swiftlint:enable type_body_length
    private let mode: EditorTransitionMode
    private var requestID: PHImageRequestID?
    private var transitionView: UIView?
    private var previewView: UIImageView!
    
    init(mode: EditorTransitionMode) {
        self.mode = mode
        super.init()
        previewView = UIImageView()
        previewView.contentMode = .scaleAspectFill
        previewView.clipsToBounds = true
    }

    func transitionDuration(
        using transitionContext: UIViewControllerContextTransitioning?
    ) -> TimeInterval {
        if let editorVC = transitionContext?.viewController(
            forKey: (mode == .push || mode == .present) ? .to : .from) as? EditorViewController,
           let duration = editorVC.delegate?.editorViewController(
            editorVC, transitionDuration: mode) {
            return duration
        }
        return 0.55
    }
    func animateTransition(
        using transitionContext: UIViewControllerContextTransitioning
    ) {
        pushTransition(using: transitionContext)
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
        let editorVC: UIViewController
        switch mode {
        case .push, .present:
            if mode == .push {
                containerView.addSubview(fromVC.view)
            }
            containerView.addSubview(toVC.view)
            #if HXPICKER_ENABLE_PICKER
            if  fromVC is PhotoPickerViewController ||
                fromVC is PhotoPreviewViewController {
                fromVC.view.insertSubview(contentView, at: 1)
            }else if fromVC is PhotoSplitViewController {
                fromVC.view.insertSubview(contentView, at: 1)
            }else {
                fromVC.view.addSubview(contentView)
            }
            #else
            fromVC.view.addSubview(contentView)
            #endif
            contentView.backgroundColor = .clear
            editorVC = toVC
        case .pop, .dismiss:
            if mode == .pop {
                containerView.addSubview(toVC.view)
                containerView.addSubview(fromVC.view)
            }
            #if HXPICKER_ENABLE_PICKER
            if let pickerVC = toVC as? PhotoPickerViewController {
                pickerVC.photoToolbar.alpha = 0
                toVC.view.insertSubview(contentView, at: 1)
            }else if let previewVC = toVC as? PhotoPreviewViewController {
                previewVC.photoToolbar.alpha = 0
                previewVC.navBgView?.alpha = 0
                toVC.view.insertSubview(contentView, at: 1)
            }else if toVC is PhotoPickerController || toVC is PhotoSplitViewController {
                var picker: PhotoPickerController?
                if let pickerController = toVC as? PhotoPickerController {
                    if let controller = pickerController.topViewController as? PhotoPickerController {
                        picker = controller
                    }else {
                        picker = pickerController
                    }
                }else if let splitVC = toVC as? PhotoSplitViewController {
                    if UIDevice.isPad {
                        toVC.view.addSubview(contentView)
                    }else {
                        if let pickerController = splitVC.viewControllers.last as? PhotoPickerController {
                            pickerController.navigationBar.alpha = 0
                            if let controller = pickerController.topViewController as? PhotoPickerController {
                                picker = controller
                            }else {
                                picker = pickerController
                            }
                        }
                    }
                }
                if let vc = picker?.topViewController as? PhotoPickerViewController {
                    vc.photoToolbar.alpha = 0
                    vc.view.insertSubview(contentView, at: 1)
                }else if let vc = picker?.topViewController as? PhotoPreviewViewController {
                    vc.photoToolbar.alpha = 0
                    vc.navBgView?.alpha = 0
                    vc.view.insertSubview(contentView, at: 1)
                }
                picker?.navigationBar.alpha = 0
            }else {
                toVC.view.addSubview(contentView)
            }
            #else
            toVC.view.addSubview(contentView)
            #endif
            contentView.backgroundColor = .black
            editorVC = fromVC
        }
        contentView.addSubview(previewView)
        #if HXPICKER_ENABLE_PICKER
        var photoAsset: PhotoAsset?
        #endif
        var fromRect: CGRect = .zero
        var toRect: CGRect = .zero
        let isSpring: Bool = true
        if let editorVC = editorVC as? EditorViewController {
            switch mode {
            case .push, .present:
                editorVC.isTransitionCompletion = false
                editorVC.transitionHide()
                if let view = editorVC.delegate?.editorViewController(transitioStartPreviewView: editorVC) {
                    transitionView = view
                    fromRect = view.convert(view.bounds, to: contentView)
                }else if let rect = editorVC.delegate?.editorViewController(
                    transitioStartPreviewFrame: editorVC
                ) {
                    fromRect = rect
                }
                let image = editorVC.delegate?.editorViewController(transitionPreviewImage: editorVC)
                previewView.image = image
                if let image = image {
                    editorVC.setTransitionImage(image)
                }
                #if HXPICKER_ENABLE_PICKER
                photoAsset = editorVC.selectedAsset.type.photoAsset
                if let photoAsset = photoAsset {
                    toRect = getTransitionFrame(
                        with: photoAsset.imageSize,
                        viewSize: toVC.view.size
                    )
                }else if let image = editorVC.editorView.image {
                    toRect = getTransitionFrame(
                        with: image.size,
                        viewSize: toVC.view.size
                    )
                }else {
                    if let image = image {
                        toRect = getTransitionFrame(
                            with: image.size,
                            viewSize: toVC.view.size
                        )
                    }else {
                        toRect = .zero
                    }
                }
                #else
                if let image = editorVC.editorView.image {
                    toRect = getTransitionFrame(
                        with: image.size,
                        viewSize: toVC.view.size
                    )
                }else {
                    if let image = image {
                        toRect = getTransitionFrame(
                            with: image.size,
                            viewSize: toVC.view.size
                        )
                    }else {
                        toRect = .zero
                    }
                }
                #endif
                if toRect.width < editorVC.view.width {
                    toRect.origin.x = (editorVC.view.width - toRect.width) * 0.5
                }
                if toRect.height < editorVC.view.height {
                    toRect.origin.y = (editorVC.view.height - toRect.height) * 0.5
                }
            case .pop, .dismiss:
                let view = editorVC.editorView.contentView
                let imageView = UIImageView()
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                if let image = editorVC.editedResult?.image {
                    imageView.image = image
                }else {
                    if let image = editorVC.editorView.image {
                        imageView.image = image
                    }else {
                        imageView.image = view.layer.convertedToImage()
                    }
                }
                let finalView = editorVC.editorView.finalView
                if let rect = finalView.superview?.convert(finalView.frame, to: contentView) {
                    fromRect = rect
                }
                previewView.frame = fromRect
                imageView.frame = previewView.bounds
                previewView.addSubview(imageView)
                view.frame = previewView.bounds
                if let view = editorVC.delegate?.editorViewController(transitioEndPreviewView: editorVC) {
                    transitionView = view
                    toRect = view.convert(view.bounds, to: contentView)
                }else if let rect = editorVC.delegate?.editorViewController(
                    transitioEndPreviewFrame: editorVC
                ) {
                    toRect = rect
                }
            }
            editorVC.editorView.isHidden = true
            editorVC.view.backgroundColor = .clear
        }else {
            previewView.removeFromSuperview()
            contentView.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            return
        }
        if mode == .push || mode == .present {
            #if HXPICKER_ENABLE_PICKER
            if let photoAsset = photoAsset, !(fromVC is PhotoPreviewViewController) {
                var reqeustAsset = photoAsset.phAsset != nil
                if photoAsset.editedResult != nil {
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
            switch self.mode {
            case .push, .present:
                contentView.backgroundColor = .black
                #if HXPICKER_ENABLE_PICKER
                if let pickerVC = fromVC as? PhotoPickerViewController {
                    pickerVC.photoToolbar.alpha = 0
                }else if let previewVC = fromVC as? PhotoPreviewViewController {
                    previewVC.photoToolbar.alpha = 0
                    previewVC.navBgView?.alpha = 0
                }else if fromVC is PhotoPickerController || fromVC is PhotoSplitViewController {
                    var picker: PhotoPickerController?
                    if let pickerController = fromVC as? PhotoPickerController {
                        if let controller = pickerController.topViewController as? PhotoPickerController {
                            picker = controller
                        }else {
                            picker = pickerController
                        }
                    }else if let splitVC = fromVC as? PhotoSplitViewController {
                        if let pickerController = splitVC.viewControllers.last as? PhotoPickerController {
                            if let controller = pickerController.topViewController as? PhotoPickerController {
                                picker = controller
                            }else {
                                picker = pickerController
                            }
                        }
                    }
                    if let vc = picker?.topViewController as? PhotoPickerViewController {
                        vc.photoToolbar.alpha = 0
                    }else if let vc = picker?.topViewController as? PhotoPreviewViewController {
                        vc.photoToolbar.alpha = 0
                        vc.navBgView?.alpha = 0
                    }
                }
                #endif
                if let editorVC = editorVC as? EditorViewController {
                    editorVC.transitionShow()
                }
            case .pop, .dismiss:
                contentView.backgroundColor = .clear
                #if HXPICKER_ENABLE_PICKER
                if let pickerVC = toVC as? PhotoPickerViewController {
                    pickerVC.photoToolbar.alpha = 1
                }else if let previewVC = toVC as? PhotoPreviewViewController {
                    previewVC.photoToolbar.alpha = 1
                    previewVC.navBgView?.alpha = 1
                }else if toVC is PhotoPickerController || toVC is PhotoSplitViewController {
                    var picker: PhotoPickerController?
                    if let pickerController = toVC as? PhotoPickerController {
                        if let controller = pickerController.topViewController as? PhotoPickerController {
                            picker = controller
                        }else {
                            picker = pickerController
                        }
                    }else if let splitVC = toVC as? PhotoSplitViewController {
                        if let pickerController = splitVC.viewControllers.last as? PhotoPickerController {
                            pickerController.navigationBar.alpha = 1
                            if let controller = pickerController.topViewController as? PhotoPickerController {
                                picker = controller
                            }else {
                                picker = pickerController
                            }
                        }
                    }
                    if let vc = picker?.topViewController as? PhotoPickerViewController {
                        vc.photoToolbar.alpha = 1
                    }else if let vc = picker?.topViewController as? PhotoPreviewViewController {
                        vc.photoToolbar.alpha = 1
                        vc.navBgView?.alpha = 1
                    }
                    picker?.navigationBar.alpha = 1
                }
                #endif
                if let editorVC = editorVC as? EditorViewController {
                    editorVC.transitionHide()
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
            }
        } completion: { [weak self] _ in
            guard let self = self else {
                contentView.removeFromSuperview()
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                return
            }
            self.transitionView?.isHidden = false
            switch self.mode {
            case .push, .present:
                if let requestID = self.requestID {
                    PHImageManager.default().cancelImageRequest(requestID)
                    self.requestID = nil
                }
                #if HXPICKER_ENABLE_PICKER
                if let pickerVC = fromVC as? PhotoPickerViewController {
                    pickerVC.photoToolbar.alpha = 1
                }else if let previewVC = fromVC as? PhotoPreviewViewController {
                    previewVC.photoToolbar.alpha = 1
                    previewVC.navBgView?.alpha = 1
                }else if fromVC is PhotoPickerController || fromVC is PhotoSplitViewController {
                    var picker: PhotoPickerController?
                    if let pickerController = fromVC as? PhotoPickerController {
                        if let controller = pickerController.topViewController as? PhotoPickerController {
                            picker = controller
                        }else {
                            picker = pickerController
                        }
                    }else if let splitVC = fromVC as? PhotoSplitViewController {
                        if let pickerController = splitVC.viewControllers.last as? PhotoPickerController {
                            if let controller = pickerController.topViewController as? PhotoPickerController {
                                picker = controller
                            }else {
                                picker = pickerController
                            }
                        }
                    }
                    if let vc = picker?.topViewController as? PhotoPickerViewController {
                        vc.photoToolbar.alpha = 1
                    }else if let vc = picker?.topViewController as? PhotoPreviewViewController {
                        vc.photoToolbar.alpha = 1
                        vc.navBgView?.alpha = 1
                    }
                }
                #endif
                if let editorVC = editorVC as? EditorViewController {
                    editorVC.view.backgroundColor = .black
                    editorVC.editorView.isHidden = false
                    editorVC.isTransitionCompletion = true
                    editorVC.transitionCompletion()
                }
                self.previewView.removeFromSuperview()
                contentView.removeFromSuperview()
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            case .pop, .dismiss:
                #if HXPICKER_ENABLE_PICKER
                if let previewVC = toVC as? PhotoPreviewViewController {
                    previewVC.navigationController?.delegate = previewVC.beforeNavDelegate
                }
                #endif
                UIView.animate(
                    withDuration: 0.25,
                    delay: 0,
                    options: [.allowUserInteraction]
                ) {
                    self.previewView.alpha = 0
                } completion: { _ in
                    self.previewView.removeFromSuperview()
                    contentView.removeFromSuperview()
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
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
    
    #if HXPICKER_ENABLE_PICKER
    func requestAssetImage(for asset: PHAsset) {
        let options = PHImageRequestOptions()
        options.resizeMode = .fast
        options.deliveryMode = .highQualityFormat
        requestID = AssetManager.requestImage(for: asset, targetSize: asset.thumTargetSize, options: options) { image, info in
            guard let image else { return }
            DispatchQueue.main.async {
                if self.previewView.superview != nil {
                    self.previewView.image = image
                }
            }
            if AssetManager.assetDownloadFinined(for: info) || AssetManager.assetCancelDownload(for: info) {
                self.requestID = nil
            }
        }
    }
    #endif
    
    func getTransitionFrame(with imageSize: CGSize, viewSize: CGSize) -> CGRect {
        let imageScale = imageSize.width / imageSize.height
        let imageWidth = viewSize.width
        let imageHeight = imageWidth / imageScale
        let imageX: CGFloat = 0
        var imageY: CGFloat = 0
        if imageHeight < viewSize.height {
            imageY = (viewSize.height - imageHeight) * 0.5
        }
        return CGRect(x: imageX, y: imageY, width: imageWidth, height: imageHeight)
    }
}
