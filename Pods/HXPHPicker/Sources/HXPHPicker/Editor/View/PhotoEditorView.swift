//
//  PhotoEditorView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/4/17.
//

import UIKit

protocol PhotoEditorViewDelegate: AnyObject {
    func editorView(willBeginEditing editorView: PhotoEditorView)
    func editorView(didEndEditing editorView: PhotoEditorView)
    func editorView(willAppearCrop editorView: PhotoEditorView)
    func editorView(didAppear editorView: PhotoEditorView)
    func editorView(willDisappearCrop editorView: PhotoEditorView)
    func editorView(didDisappearCrop editorView: PhotoEditorView)
}

class PhotoEditorView: UIScrollView {
    weak var editorDelegate: PhotoEditorViewDelegate?
    lazy var imageView: EditorImageResizerView = {
        let imageView = EditorImageResizerView.init(cropConfig: cropConfig)
        imageView.delegate = self
        return imageView
    }()
    
    /// 裁剪配置
    var cropConfig: PhotoCroppingConfiguration
    
    var state: State = .normal
    var imageScale: CGFloat = 1
    var canZoom = true
    var cropSize: CGSize = .zero
    
    init(cropConfig: PhotoCroppingConfiguration) {
        self.cropConfig = cropConfig
        super.init(frame: .zero)
        delegate = self
        minimumZoomScale = 1.0
        maximumZoomScale = 10.0
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        clipsToBounds = false
        scrollsToTop = false
        if #available(iOS 11.0, *) {
            contentInsetAdjustmentBehavior = .never
        }
        addSubview(imageView)
    }
    
    func updateImageViewFrame() {
        let imageWidth = width
        var imageHeight: CGFloat
        if cropSize.equalTo(.zero) {
            imageHeight = imageWidth / imageScale
        }else {
            imageHeight = cropSize.height
        }
        let imageX: CGFloat = 0
        var imageY: CGFloat = 0
        if imageHeight < height {
            imageY = (height - imageHeight) * 0.5
            imageView.setViewFrame(CGRect(x: 0, y: -imageY, width: width, height: height))
        }else {
            imageView.setViewFrame(bounds)
        }
        contentSize = CGSize(width: imageWidth, height: imageHeight)
        imageView.frame = CGRect(x: imageX, y: imageY, width: imageWidth, height: imageHeight)
    }
    
    func setImage(_ image: UIImage) {
        imageScale = image.width / image.height
        updateImageViewFrame()
        imageView.setImage(image)
    }
    func getEditedData() -> PhotoEditData {
        imageView.getEditedData()
    }
    func setEditedData(editedData: PhotoEditData) {
        if editedData.isPortrait != UIDevice.isPortrait {
            return
        }
        cropSize = editedData.cropSize
        imageView.setEditedData(editedData: editedData)
        cancelCropping(canShowMask: false, false)
        updateImageViewFrame()
        if cropConfig.isRoundCrop {
            imageView.layer.cornerRadius = cropSize.width * 0.5
        }
    }
    
    func resetZoomScale(_ animated: Bool) {
        if state == .normal {
            canZoom = true
        }
        if animated {
            UIView.animate(withDuration: 0.25, delay: 0, options: [.curveLinear]) {
                if self.zoomScale != 1 {
                    self.zoomScale = 1
                }
            } completion: { (isFinished) in
                if self.state == .cropping {
                    self.canZoom = false
                }
            }
        }else {
            if zoomScale != 1 {
                zoomScale = 1
            }
            if state == .cropping {
                canZoom = false
            }
        }
        setContentOffset(CGPoint(x: -contentInset.left, y: -contentInset.top), animated: false)
    }
    
    func startCropping(_ animated: Bool) {
        editorDelegate?.editorView(willAppearCrop: self)
        state = .cropping
        isScrollEnabled = false
        resetZoomScale(animated)
        imageView.startCorpping(animated) { [weak self] () in
            if self != nil {
                self?.editorDelegate?.editorView(didAppear: self!)
            }
        }
    }
    
    func cancelCropping(canShowMask: Bool = true, _ animated: Bool) {
        editorDelegate?.editorView(willDisappearCrop: self)
        state = .normal
        isScrollEnabled = true
        resetZoomScale(animated)
        imageView.cancelCropping(canShowMask: canShowMask, animated) { [weak self] () in
            if self != nil {
                self?.editorDelegate?.editorView(didDisappearCrop: self!)
            }
        }
    }
    func canReset() -> Bool {
        return imageView.canReset()
    }
    
    func reset(_ animated: Bool) {
        imageView.reset(animated)
    }
    
    func finishCropping(_ animated: Bool, completion: (() -> Void)? = nil) {
        editorDelegate?.editorView(willDisappearCrop: self)
        state = .normal
        isScrollEnabled = true
        resetZoomScale(animated)
        imageView.finishCropping(animated) { [weak self] () in
            if self != nil {
                self?.editorDelegate?.editorView(didDisappearCrop: self!)
                if self!.cropConfig.isRoundCrop {
                    self?.imageView.layer.cornerRadius = self!.cropSize.width * 0.5
                }
            }
            completion?()
        }
        cropSize = imageView.cropSize
        updateImageViewFrame()
    } 
    func cropping(completion: @escaping (PhotoEditResult?) -> Void) {
        let toRect = imageView.getCroppingRect()
        let inputImage = imageView.imageView.image
        let viewWidth = imageView.imageView.width
        let viewHeight = imageView.imageView.height
        DispatchQueue.global().async {
            if let imageOptions = self.imageView.cropping(inputImage, toRect: toRect, viewWidth: viewWidth, viewHeight: viewHeight) {
                DispatchQueue.main.async {
                    let editResult = PhotoEditResult.init(editedImage: imageOptions.0, editedImageURL: imageOptions.1, imageType: imageOptions.2, editedData: self.getEditedData())
                    completion(editResult)
                }
            }else {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    func changedAspectRatio(of aspectRatio: CGSize) {
        imageView.changedAspectRatio(of: aspectRatio)
    }
    func rotate() {
        imageView.rotate()
    }
    func mirrorHorizontally(animated: Bool) {
        imageView.mirrorHorizontally(animated: animated)
    }
    
    func orientationDidChange() {
        cropSize = .zero
        updateImageViewFrame()
        imageView.updateBaseConfig()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
extension PhotoEditorView: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        if !canZoom {
            return nil
        }
        return imageView
    }
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        if !canZoom {
            return
        }
        let offsetX = (scrollView.width > scrollView.contentSize.width) ? (scrollView.width - scrollView.contentSize.width) * 0.5 : 0
        let offsetY = (scrollView.height > scrollView.contentSize.height) ? (scrollView.height - scrollView.contentSize.height) * 0.5 : 0
        let centerX = scrollView.contentSize.width * 0.5 + offsetX
        let centerY = scrollView.contentSize.height * 0.5 + offsetY
        imageView.center = CGPoint(x: centerX, y: centerY);
    }
}
extension PhotoEditorView: EditorImageResizerViewDelegate {
    func imageResizerView(willChangedMaskRect imageResizerView: EditorImageResizerView) {
        editorDelegate?.editorView(willBeginEditing: self)
    }
    
    func imageResizerView(didEndChangedMaskRect imageResizerView: EditorImageResizerView) {
        editorDelegate?.editorView(didEndEditing: self)
    }
    
    func imageResizerView(willBeginDragging imageResizerView: EditorImageResizerView) {
        editorDelegate?.editorView(willBeginEditing: self)
    }
    
    func imageResizerView(didEndDecelerating imageResizerView: EditorImageResizerView) {
        editorDelegate?.editorView(didEndEditing: self)
    }
    
    func imageResizerView(WillBeginZooming imageResizerView: EditorImageResizerView) {
        editorDelegate?.editorView(willBeginEditing: self)
    }
    
    func imageResizerView(didEndZooming imageResizerView: EditorImageResizerView) {
        editorDelegate?.editorView(didEndEditing: self)
    }
    
    
}
