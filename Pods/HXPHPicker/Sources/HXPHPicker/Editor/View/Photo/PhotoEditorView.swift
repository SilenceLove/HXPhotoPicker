//
//  PhotoEditorView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/4/17.
//

import UIKit
import AVFoundation

protocol PhotoEditorViewDelegate: AnyObject {
    func editorView(willBeginEditing editorView: PhotoEditorView)
    func editorView(didEndEditing editorView: PhotoEditorView)
    func editorView(willAppearCrop editorView: PhotoEditorView)
    func editorView(didAppear editorView: PhotoEditorView)
    func editorView(willDisappearCrop editorView: PhotoEditorView)
    func editorView(didDisappearCrop editorView: PhotoEditorView)
    
    func editorView(drawViewBeganDraw editorView: PhotoEditorView)
    func editorView(drawViewEndDraw editorView: PhotoEditorView)
    func editorView(_ editorView: PhotoEditorView, updateStickerText item: EditorStickerItem)
    func editorView(didRemoveAudio editorView: PhotoEditorView)
}

class PhotoEditorView: UIScrollView, UIGestureRecognizerDelegate {
    weak var editorDelegate: PhotoEditorViewDelegate?
    let editType: PhotoEditorContentView.EditType
    lazy var imageResizerView: EditorImageResizerView = {
        let imageResizerView = EditorImageResizerView(
            editType: editType,
            cropConfig: cropConfig,
            mosaicConfig: mosaicConfig
        )
        imageResizerView.exportScale = exportScale
        let brush = brushConfig
        imageResizerView.imageView.drawView.lineColor = brush.colors[brush.defaultColorIndex].color
        imageResizerView.imageView.drawView.lineWidth = brush.lineWidth
        imageResizerView.delegate = self
        imageResizerView.imageView.delegate = self
        return imageResizerView
    }()
    
    override var zoomScale: CGFloat {
        didSet { imageResizerView.zoomScale = zoomScale }
    }
    
    /// 编辑配置
    let cropConfig: EditorCropSizeConfiguration
    let mosaicConfig: PhotoEditorConfiguration.Mosaic
    let brushConfig: EditorBrushConfiguration
    let exportScale: CGFloat
    /// 当前裁剪状态
    var state: State = .normal
    /// 图片缩放比例
    var imageScale: CGFloat = 1
    /// 是否可以缩放
    var canZoom = true
    /// 裁剪大小
    var cropSize: CGSize = .zero
    /// 当前编辑的图片
    var image: UIImage? { imageResizerView.imageView.image }
    /// 画笔宽度
    var brushLineWidth: CGFloat {
        get {
            imageResizerView.imageView.drawView.lineWidth
        }
        set {
            imageResizerView.imageView.drawView.lineWidth = newValue
        }
    }
    
    var isEnabled: Bool = false {
        didSet {
            imageResizerView.isUserInteractionEnabled = isEnabled
            isScrollEnabled = isEnabled
        }
    }
    
    var drawEnabled: Bool {
        get { imageResizerView.drawEnabled }
        set { imageResizerView.drawEnabled = newValue }
    }
    var stickerEnabled: Bool {
        get { imageResizerView.stickerEnabled }
        set { imageResizerView.stickerEnabled = newValue }
    }
    var mosaicEnabled: Bool {
        get { imageResizerView.mosaicEnabled }
        set { imageResizerView.mosaicEnabled = newValue }
    }
    var drawColorHex: String = "#ffffff" {
        didSet { imageResizerView.imageView.drawView.lineColor = drawColorHex.color }
    }
    var drawColor: UIColor = .white {
        didSet { imageResizerView.imageView.drawView.lineColor = drawColor }
    }
    var mosaicType: PhotoEditorMosaicView.MosaicType = .mosaic {
        didSet { imageResizerView.imageView.mosaicView.type = mosaicType }
    }
    var playerView: VideoEditorPlayerView {
        imageResizerView.imageView.videoView
    }
    var canLookOriginal: Bool = false {
        didSet {
            imageResizerView.imageView.longPressGesture.isEnabled = canLookOriginal
        }
    }
    var canUndoDraw: Bool { imageResizerView.imageView.drawView.canUndo }
    var canUndoMosaic: Bool { imageResizerView.imageView.mosaicView.canUndo }
    var hasSticker: Bool { imageResizerView.imageView.stickerView.count > 0 }
    var hasFilter: Bool { imageResizerView.videoFilter != nil || imageResizerView.hasFilter }
    
    init(
        editType: PhotoEditorContentView.EditType,
        cropConfig: EditorCropSizeConfiguration,
        mosaicConfig: PhotoEditorConfiguration.Mosaic,
        brushConfig: EditorBrushConfiguration,
        exportScale: CGFloat
    ) {
        self.editType = editType
        self.cropConfig = cropConfig
        self.mosaicConfig = mosaicConfig
        self.brushConfig = brushConfig
        self.exportScale = exportScale
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
        addSubview(imageResizerView)
    }
    func getTransitionImageViewFrame(with imageSize: CGSize, viewSize: CGSize) -> CGRect {
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
            imageResizerView.setViewFrame(CGRect(x: 0, y: -imageY, width: width, height: height))
        }else {
            imageResizerView.setViewFrame(bounds)
        }
        contentSize = CGSize(width: imageWidth, height: imageHeight)
        imageResizerView.frame = CGRect(x: imageX, y: imageY, width: imageWidth, height: imageHeight)
    }
    func setAVAsset(_ asset: AVAsset, coverImage: UIImage) {
        if !coverImage.size.equalTo(.zero) {
            imageScale = coverImage.width / coverImage.height
        }else {
            imageScale = 1
        }
        updateImageViewFrame()
        imageResizerView.setAVAsset(asset, coverImage: coverImage)
    }
    func setImage(_ image: UIImage) {
        imageScale = image.width / image.height
        updateImageViewFrame()
        imageResizerView.setImage(image)
    }
    func updateImage(_ image: UIImage) {
        imageResizerView.updateImage(image)
    }
    func setMosaicOriginalImage(_ image: UIImage?) {
        imageResizerView.setMosaicOriginalImage(image)
    }
    func getEditedData(
        _ filterImageURL: URL?
    ) -> PhotoEditData {
        imageResizerView.getEditedData(filterImageURL)
    }
    func setEditedData(editedData: PhotoEditData) {
        imageResizerView.hasFilter = editedData.hasFilter
        if editedData.isPortrait != UIDevice.isPortrait {
            return
        }
        if let cropData = editedData.cropData {
            cropSize = cropData.cropSize
            imageResizerView.setCropData(cropData: cropData)
            cancelCropping(canShowMask: false, false)
            if cropData.isRoundCrop {
                imageResizerView.layer.cornerRadius = cropSize.width * 0.5
            }
        }
        imageResizerView.setBrushData(brushData: editedData.brushData)
        imageResizerView.setMosaicData(mosaicData: editedData.mosaicData)
        imageResizerView.setStickerData(stickerData: editedData.stickerData)
        updateImageViewFrame()
    }
    func getVideoEditedData() -> VideoEditedCropSize {
        imageResizerView.getVideoEditedData()
    }
    func setVideoEditedData(editedData: VideoEditedCropSize) {
        if editedData.isPortrait != UIDevice.isPortrait {
            return
        }
        if let cropData = editedData.cropData {
            cropSize = cropData.cropSize
            imageResizerView.setCropData(cropData: cropData)
            cancelCropping(canShowMask: false, false)
            if cropData.isRoundCrop {
                imageResizerView.layer.cornerRadius = cropSize.width * 0.5
            }
        }
        imageResizerView.setBrushData(brushData: editedData.brushData)
        imageResizerView.setStickerData(stickerData: editedData.stickerData)
        updateImageViewFrame()
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
    
    func startCropTime(_ animated: Bool) {
        editorDelegate?.editorView(willAppearCrop: self)
        state = .cropping
        isScrollEnabled = false
        resetZoomScale(animated)
        imageResizerView.startCropTime(animated)
    }
    func cancelCropTime(_ animated: Bool) {
        editorDelegate?.editorView(willDisappearCrop: self)
        state = .normal
        isScrollEnabled = true
        resetZoomScale(animated)
        imageResizerView.cancelCropTime(animated)
    }
    
    func startCropping(_ animated: Bool) {
        editorDelegate?.editorView(willAppearCrop: self)
        state = .cropping
        isScrollEnabled = false
        resetZoomScale(animated)
        imageResizerView.startCorpping(animated) { [weak self] () in
            guard let self = self else { return }
            self.imageResizerView.zoomScale = self.zoomScale
            self.editorDelegate?.editorView(didAppear: self)
        }
    }
    
    func cancelCropping(canShowMask: Bool = true, _ animated: Bool) {
        editorDelegate?.editorView(willDisappearCrop: self)
        state = .normal
        isScrollEnabled = true
        resetZoomScale(animated)
        imageResizerView.cancelCropping(
            canShowMask: canShowMask, animated
        ) { [weak self] in
            guard let self = self else { return }
            self.imageResizerView.zoomScale = self.zoomScale
            self.editorDelegate?.editorView(didDisappearCrop: self)
        }
    }
    func canReset() -> Bool {
        return imageResizerView.canReset()
    }
    
    func reset(_ animated: Bool) {
        imageResizerView.reset(animated)
    }
    
    func finishCropping(_ animated: Bool, completion: (() -> Void)? = nil) {
        editorDelegate?.editorView(willDisappearCrop: self)
        state = .normal
        isScrollEnabled = true
        resetZoomScale(animated)
        imageResizerView.finishCropping(
            animated
        ) { [weak self] in
            guard let self = self else { return }
            self.imageResizerView.zoomScale = self.zoomScale
            self.editorDelegate?.editorView(didDisappearCrop: self)
            if self.cropConfig.isRoundCrop {
                self.imageResizerView.layer.cornerRadius = self.cropSize.width * 0.5
            }else {
                self.imageResizerView.layer.cornerRadius = 0
            }
            completion?()
        }
        cropSize = imageResizerView.cropSize
        updateImageViewFrame()
    } 
    func cropping(completion: ((PhotoEditResult?) -> Void)?) {
        let toRect = imageResizerView.getCroppingRect()
        let inputImage = imageResizerView.imageView.image
        let viewWidth = imageResizerView.imageView.width
        let viewHeight = imageResizerView.imageView.height
        var drawLayer: CALayer?
        if imageResizerView.imageView.drawView.count > 0 {
            drawLayer = imageResizerView.imageView.drawView.layer
        }
        var stickerLayer: CALayer?
        if imageResizerView.imageView.stickerView.count > 0 {
            stickerLayer = imageResizerView.imageView.stickerView.layer
        }
        var mosaicLayer: CALayer?
        if imageResizerView.imageView.mosaicView.count > 0 {
            mosaicLayer = imageResizerView.imageView.mosaicView.layer
        }
        
        let isRoundCrop = cropConfig.isRoundCrop && imageResizerView.layer.cornerRadius > 0
        DispatchQueue.global().async {
            let filterImageURL = self.imageResizerView.hasFilter ?
                                    PhotoTools.write(image: inputImage) : nil
            let imageOptions = self.imageResizerView.cropping(
                inputImage,
                toRect: toRect,
                mosaicLayer: mosaicLayer,
                drawLayer: drawLayer,
                stickerLayer: stickerLayer,
                isRoundCrop: isRoundCrop,
                viewWidth: viewWidth,
                viewHeight: viewHeight
            )
            DispatchQueue.main.async {
                if let imageOptions = imageOptions {
                    let editResult = PhotoEditResult(
                        editedImage: imageOptions.0,
                        editedImageURL: imageOptions.1,
                        imageType: imageOptions.2,
                        editedData: self.getEditedData(filterImageURL)
                    )
                    completion?(editResult)
                }else {
                    completion?(nil)
                }
            }
        }
    }
    func getVideoCropData() -> VideoEditorCropSizeData {
        let toRect = imageResizerView.getCroppingRect()
        let viewSize = imageResizerView.imageView.size
        let cropRect = CGRect(
            x: CGFloat(Int(toRect.minX)) / viewSize.width,
            y: CGFloat(Int(toRect.minY)) / viewSize.height,
            width: toRect.width / viewSize.width,
            height: toRect.height / viewSize.height
        )
        var drawLayer: CALayer?
        if imageResizerView.imageView.drawView.count > 0 {
            drawLayer = imageResizerView.imageView.drawView.layer
        }
        return .init(
            canReset: canReset(),
            cropRect: cropRect,
            isRoundCrop: imageResizerView.layer.cornerRadius > 0 ? cropConfig.isRoundCrop : false,
            mirrorType: imageResizerView.mirrorType,
            angle: imageResizerView.currentAngle,
            drawLayer: drawLayer,
            stickerInfos: imageResizerView.imageView.stickerView.getStickerInfo(),
            filter: playerView.filterInfo,
            filterValue: playerView.filterValue
        )
    }
    func changedAspectRatio(of aspectRatio: CGSize) {
        imageResizerView.changedAspectRatio(of: aspectRatio)
    }
    func rotate() {
        imageResizerView.rotate()
    }
    func mirrorHorizontally(animated: Bool) {
        imageResizerView.mirrorHorizontally(animated: animated)
    }
    func addSticker(item: EditorStickerItem, isSelected: Bool) {
        imageResizerView.imageView.stickerView.add(sticker: item, isSelected: isSelected)
    }
    func updateSticker(item: EditorStickerItem) {
        imageResizerView.imageView.stickerView.update(item: item)
    }
    func deselectedSticker() {
        imageResizerView.imageView.stickerView.deselectedSticker()
    }
    
    func orientationDidChange() {
        cropSize = .zero
        updateImageViewFrame()
        imageResizerView.updateBaseConfig()
        cancelCropping(false)
    }
    
    func undoAllDraw() {
        imageResizerView.imageView.drawView.emptyCanvas()
    }
    func undoDraw() {
        imageResizerView.imageView.drawView.undo()
    }
    func undoMosaic() {
        imageResizerView.imageView.mosaicView.undo()
    }
    func undoAllMosaic() {
        imageResizerView.imageView.mosaicView.undoAll()
    }
    func undoAllSticker() {
        imageResizerView.imageView.stickerView.removeAllSticker()
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if state != .cropping && imageResizerView == view {
            if imageResizerView.drawEnabled {
                return imageResizerView.imageView.drawView
            }
            if imageResizerView.mosaicEnabled {
                return imageResizerView.imageView.mosaicView
            }
            return self
        }else if state == .cropping && self == view {
            return imageResizerView
        }
        return view
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if state == .cropping {
            return false
        }else if (imageResizerView.drawEnabled || imageResizerView.mosaicEnabled) &&
                    !gestureRecognizer.isKind(of: UIPinchGestureRecognizer.self) {
            return false
        }
        return true
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
        return imageResizerView
    }
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        if !canZoom {
            return
        }
        let offsetX = (scrollView.width > scrollView.contentSize.width) ?
            (scrollView.width - scrollView.contentSize.width) * 0.5 : 0
        let offsetY = (scrollView.height > scrollView.contentSize.height) ?
            (scrollView.height - scrollView.contentSize.height) * 0.5 : 0
        let centerX = scrollView.contentSize.width * 0.5 + offsetX
        let centerY = scrollView.contentSize.height * 0.5 + offsetY
        imageResizerView.center = CGPoint(x: centerX, y: centerY)
    }
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        imageResizerView.zoomScale = scale
    }
}
extension PhotoEditorView: PhotoEditorContentViewDelegate {
    func contentView(_ contentView: PhotoEditorContentView, updateStickerText item: EditorStickerItem) {
        editorDelegate?.editorView(self, updateStickerText: item)
    }
    func contentView(drawViewBeganDraw contentView: PhotoEditorContentView) {
        editorDelegate?.editorView(drawViewBeganDraw: self)
    }
    func contentView(drawViewEndDraw contentView: PhotoEditorContentView) {
        editorDelegate?.editorView(drawViewEndDraw: self)
    }
    func contentView(didRemoveAudio contentView: PhotoEditorContentView) {
        editorDelegate?.editorView(didRemoveAudio: self)
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

struct VideoEditorCropSizeData {
    let canReset: Bool
    let cropRect: CGRect
    let isRoundCrop: Bool
    let mirrorType: EditorImageResizerView.MirrorType
    let angle: CGFloat
    let drawLayer: CALayer?
    let stickerInfos: [EditorStickerInfo]
    let filter: PhotoEditorFilterInfo?
    let filterValue: Float
}
