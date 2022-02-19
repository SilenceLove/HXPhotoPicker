//
//  EditorImageResizerView+Initial.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/25.
//

import UIKit
import AVFoundation

extension EditorImageResizerView {
    func setCropData(cropData: PhotoEditCropData) {
        hasCropping = true
        // 记录当前数据
        oldAngle = cropData.angle
        oldMirrorType = cropData.mirrorType
        oldTransform = cropData.transform
        cropSize = cropData.cropSize
        oldContentInset = cropData.contentInset
        let rect = AVMakeRect(aspectRatio: cropData.maskRect.size, insideRect: getEditableArea())
        let widthScale = rect.width / cropData.maskRect.width
        oldZoomScale = cropData.zoomScale * widthScale
        oldMinimumZoomScale = cropData.minimumZoomScale * widthScale
        oldMaximumZoomScale = cropData.maximumZoomScale * widthScale
        let scrollViewContentInset = getScrollViewContentInset(rect, true)
        let offsetX = baseImageSize.width * cropData.offsetScale.x * oldZoomScale - scrollViewContentInset.left
        let offsetY = baseImageSize.height * cropData.offsetScale.y * oldZoomScale - scrollViewContentInset.top
        oldContentOffset = CGPoint(x: offsetX, y: offsetY)
        oldMaskRect = rect
        
        imageView.stickerView.angle = oldAngle
        imageView.stickerView.mirrorType = oldMirrorType
    }
    func setStickerData(stickerData: EditorStickerData?) {
        if let stickerData = stickerData {
            imageView.stickerView.setStickerData(stickerData: stickerData, viewSize: imageView.bounds.size)
        }
    }
    func setBrushData(brushData: [PhotoEditorBrushData]) {
        if !brushData.isEmpty {
            imageView.drawView.setBrushData(brushData, viewSize: imageView.bounds.size)
        }
    }
    func setMosaicData(mosaicData: [PhotoEditorMosaicData]) {
        if !mosaicData.isEmpty {
            imageView.mosaicView.setMosaicData(mosaicDatas: mosaicData, viewSize: imageView.bounds.size)
        }
    }
    func getEditableArea() -> CGRect {
        let editWidth = containerView.width - contentInsets.left - contentInsets.right
        let editHeight = containerView.height - contentInsets.top - contentInsets.bottom
        let editX = contentInsets.left
        let editY = contentInsets.top
        return CGRect(x: editX, y: editY, width: editWidth, height: editHeight)
    }
    func setImage(_ image: UIImage) {
        updateContentInsets()
        if image.size.equalTo(.zero) {
            imageScale = 1
        }else {
            imageScale = image.width / image.height
        }
        imageView.setImage(image)
        configAspectRatio()
        updateScrollView()
        updateImageViewFrame(getImageViewFrame())
        /// 手势最大范围
        let maxControlRect = CGRect(
            x: contentInsets.left,
            y: contentInsets.top,
            width: containerView.width - contentInsets.left - contentInsets.right,
            height: containerView.height - contentInsets.top - contentInsets.bottom
        )
        controlView.maxImageresizerFrame = maxControlRect
    }
    func setAVAsset(_ asset: AVAsset, coverImage: UIImage) {
        setImage(coverImage)
        imageView.videoView.avAsset = asset
    }
    /// 更新图片
    func updateImage(_ image: UIImage) {
        imageView.setImage(image)
    }
    func setMosaicOriginalImage(_ image: UIImage?) {
        imageView.setMosaicOriginalImage(image)
    }
    /// 配置宽高比数据
    func configAspectRatio() {
        controlView.fixedRatio = cropConfig.fixedRatio
        controlViewAspectRatio()
        if cropConfig.isRoundCrop {
            controlView.fixedRatio = true
            controlView.aspectRatio = CGSize(width: 1, height: 1)
        }
        isFixedRatio = controlView.fixedRatio
        currentAspectRatio = controlView.aspectRatio
        checkOriginalRatio()
    }
    /// 裁剪框的宽高比
    func controlViewAspectRatio() {
        switch cropConfig.aspectRatioType {
        case .original:
            if cropConfig.fixedRatio {
                controlView.aspectRatio = imageView.image!.size
            }else {
                controlView.aspectRatio = .zero
            }
        case .ratio_1x1:
            controlView.aspectRatio = CGSize(width: 1, height: 1)
        case .ratio_2x3:
            controlView.aspectRatio = CGSize(width: 2, height: 3)
        case .ratio_3x2:
            controlView.aspectRatio = CGSize(width: 3, height: 2)
        case .ratio_3x4:
            controlView.aspectRatio = CGSize(width: 3, height: 4)
        case .ratio_4x3:
            controlView.aspectRatio = CGSize(width: 4, height: 3)
        case .ratio_9x16:
            controlView.aspectRatio = CGSize(width: 9, height: 16)
        case .ratio_16x9:
            controlView.aspectRatio = CGSize(width: 16, height: 9)
        case .custom(let aspectRatio):
            if aspectRatio.equalTo(.zero) && cropConfig.fixedRatio {
                controlView.aspectRatio = imageView.image!.size
            }else {
                controlView.aspectRatio = aspectRatio
            }
        }
    }
    /// 检测是否原始宽高比
    func checkOriginalRatio() {
        isOriginalRatio = false
        let aspectRatio = controlView.aspectRatio
        if aspectRatio.equalTo(.zero) {
            isOriginalRatio = true
        }else {
            if aspectRatio.width / aspectRatio.height == imageScale {
                isOriginalRatio = true
            }
        }
    }
    /// 获取当前宽高比下裁剪框的位置大小
    func getInitializationRatioMaskRect() -> CGRect {
        let maxWidth = containerView.width - contentInsets.left - contentInsets.right
        let maxHeight = containerView.height - contentInsets.top - contentInsets.bottom
        var maskWidth = maxWidth
        var maskHeight = maskWidth * (currentAspectRatio.height / currentAspectRatio.width)
        if maskHeight > maxHeight {
            maskWidth = maskWidth * (maxHeight / maskHeight)
            maskHeight = maxHeight
        }
        let maskX = (maxWidth - maskWidth) * 0.5 + contentInsets.left
        let maskY = (maxHeight -  maskHeight) * 0.5 + contentInsets.top
        return CGRect(x: maskX, y: maskY, width: maskWidth, height: maskHeight)
    }
    
    /// 获取初始缩放比例
    func getInitialZoomScale() -> CGFloat {
        let maxWidth = containerView.width - contentInsets.left - contentInsets.right
        let maxHeight = containerView.height - contentInsets.top - contentInsets.bottom
        var imageWidth: CGFloat
        var imageHeight: CGFloat
        
        switch getImageOrientation() {
        case .up, .down:
            imageWidth = maxWidth
            imageHeight = imageWidth / imageScale
            if imageHeight > maxHeight {
                imageHeight = maxHeight
                imageWidth = imageHeight * imageScale
            }
            
            if !isOriginalRatio {
                let maskRect = getInitializationRatioMaskRect()
                if imageHeight < maskRect.height {
                    imageWidth = imageWidth * (maskRect.height / imageHeight)
                }
                if imageWidth < maskRect.width {
                    imageWidth = maskRect.width
                }
            }
        case .left, .right:
            imageHeight = maxWidth
            imageWidth = imageHeight * imageScale
            if imageWidth > maxHeight {
                imageWidth = maxHeight
                imageHeight = imageWidth / imageScale
            }
            
            if !isOriginalRatio {
                let maskRect = getInitializationRatioMaskRect()
                if imageWidth < maskRect.height {
                    imageHeight = imageHeight * (maskRect.height / imageWidth)
                }
                if imageHeight < maskRect.width {
                    imageHeight = maskRect.width
                }
                imageWidth = imageHeight * imageScale
            }
        }
        let minimumZoomScale = imageWidth / baseImageSize.width
        return minimumZoomScale
    }
    
    /// 获取imageView初始位置大小
    func getImageViewFrame() -> CGRect {
        let maxWidth = containerView.width
        let maxHeight = containerView.height
        let imageWidth = maxWidth
        let imageHeight = imageWidth / imageScale
        var imageX: CGFloat = 0
        var imageY: CGFloat = 0
        if imageHeight < maxHeight {
            imageY = (maxHeight - imageHeight) * 0.5
        }
        if imageWidth < maxWidth {
            imageX = (maxWidth - imageWidth) * 0.5
        }
        return CGRect(x: imageX, y: imageY, width: imageWidth, height: imageHeight)
    }
    
    /// 更新imageView位置大小
    func updateImageViewFrame(_ imageFrame: CGRect) {
        imageView.size = imageFrame.size
        baseImageSize = imageView.size
        scrollView.contentSize = imageView.size
        if imageView.height < containerView.height {
            let top = (containerView.height - imageView.height) * 0.5
            let left = (containerView.width - imageView.width) * 0.5
            scrollView.contentInset = UIEdgeInsets(top: top, left: left, bottom: top, right: left)
        }
    }
    
    /// 更新边距
    func updateContentInsets(_ isCropTime: Bool = false) {
        if UIDevice.isPortrait {
            contentInsets = UIEdgeInsets(
                top: isCropTime ? 10 + UIDevice.topMargin : 20 + UIDevice.generalStatusBarHeight,
                left: 30 + UIDevice.leftMargin,
                bottom: isCropTime ? 155 + UIDevice.bottomMargin : 125 + UIDevice.bottomMargin,
                right: 30 + UIDevice.rightMargin
            )
        }else {
            contentInsets = UIEdgeInsets(
                top: isCropTime ? 10 + UIDevice.topMargin : 20,
                left: 30 + UIDevice.leftMargin,
                bottom: isCropTime ? 160 + UIDevice.bottomMargin : 125 + UIDevice.bottomMargin,
                right: 30 + UIDevice.rightMargin
            )
        }
    }
    /// 屏幕旋转时需要还原到初始配置
    func updateBaseConfig() {
        updateContentInsets()
        scrollView.contentInset = .zero
        updateImageViewFrame(getImageViewFrame())
        /// 手势最大范围
        let maxControlRect = CGRect(
            x: contentInsets.left,
            y: contentInsets.top,
            width: containerView.width - contentInsets.left - contentInsets.right,
            height: containerView.height - contentInsets.top - contentInsets.bottom
        )
        controlView.maxImageresizerFrame = maxControlRect
    }
    
    func setViewFrame(_ frame: CGRect) {
        containerView.frame = frame
        maskBgView.frame = containerView.bounds
        maskLinesView.frame = containerView.bounds
        scrollView.frame = containerView.bounds
    }
    
    func getEditedData(
        _ filterImageURL: URL?
    ) -> PhotoEditData {
        let brushData = imageView.drawView.getBrushData()
        let rect = maskBgView.convert(controlView.frame, to: imageView)
        
        let offsetScale = CGPoint(x: rect.minX / baseImageSize.width, y: rect.minY / baseImageSize.height)
        var cropData: PhotoEditCropData?
        if canReset() {
            cropData = .init(
                cropSize: cropSize,
                isRoundCrop: layer.cornerRadius > 0 ? cropConfig.isRoundCrop : false,
                zoomScale: oldZoomScale,
                contentInset: oldContentInset,
                offsetScale: offsetScale,
                minimumZoomScale: oldMinimumZoomScale,
                maximumZoomScale: oldMaximumZoomScale,
                maskRect: oldMaskRect,
                angle: oldAngle,
                transform: oldTransform,
                mirrorType: oldMirrorType
            )
        }
        let mosaicData = imageView.mosaicView.getMosaicData()
        let stickerData = imageView.stickerView.stickerData()
        let editedData = PhotoEditData(
            isPortrait: UIDevice.isPortrait,
            cropData: cropData,
            brushData: brushData,
            hasFilter: hasFilter,
            filterImageURL: filterImageURL,
            mosaicData: mosaicData,
            stickerData: stickerData
        )
        return editedData
    }
    
    func getVideoEditedData() -> VideoEditedCropSize {
        let brushData = imageView.drawView.getBrushData()
        let rect = maskBgView.convert(controlView.frame, to: imageView)
        
        let offsetScale = CGPoint(x: rect.minX / baseImageSize.width, y: rect.minY / baseImageSize.height)
        var cropData: PhotoEditCropData?
        if canReset() {
            cropData = .init(
                cropSize: cropSize,
                isRoundCrop: layer.cornerRadius > 0 ? cropConfig.isRoundCrop : false,
                zoomScale: oldZoomScale,
                contentInset: oldContentInset,
                offsetScale: offsetScale,
                minimumZoomScale: oldMinimumZoomScale,
                maximumZoomScale: oldMaximumZoomScale,
                maskRect: oldMaskRect,
                angle: oldAngle,
                transform: oldTransform,
                mirrorType: oldMirrorType
            )
        }
        let stickerData = imageView.stickerView.stickerData()
        return .init(
            isPortrait: UIDevice.isPortrait,
            cropData: cropData,
            brushData: brushData,
            stickerData: stickerData,
            filter: videoFilter
        )
    }
}
