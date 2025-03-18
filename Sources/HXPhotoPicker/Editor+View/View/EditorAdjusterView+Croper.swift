//
//  EditorAdjusterView+Croper.swift
//  HXPhotoPicker
//
//  Created by Slience on 2023/1/31.
//

import UIKit

extension EditorAdjusterView {
    
    var isCropRund: Bool {
        if state == .normal {
            if let isRoundMask = oldAdjustedFactor?.isRoundMask {
                return isRoundMask
            }
            return false
        } else {
            return isRoundMask
        }
    }
    
    var currentMirrorScale: CGPoint {
        if state == .normal {
            if let oldAdjustedFactor = oldAdjustedFactor {
                return .init(x: oldAdjustedFactor.mirrorTransform.a, y: oldAdjustedFactor.mirrorTransform.d)
            }
            return .init(x: 1, y: 1)
        } else {
            return .init(x: adjustedFactor.mirrorTransform.a, y: adjustedFactor.mirrorTransform.d)
        }
    }
    
    var isCropedImage: Bool {
        let cropRatio = getCropOption()
        var canvasImage: UIImage?
        if #available(iOS 13.0, *) {
            canvasImage = contentView.isCanvasEmpty ? nil : contentView.canvasImage
        }
        let cropFactor = CropFactor(
            drawLayer: contentView.drawView.count > 0 ? contentView.drawView.layer : nil,
            canvasImage: canvasImage,
            mosaicLayer: contentView.mosaicView.count > 0 ? contentView.mosaicView.layer : nil,
            stickersLayer: contentView.stickerView.count > 0 ? contentView.stickerView.layer : nil,
            isCropImage: isCropImage,
            isRound: isCropRund,
            maskImage: maskImage,
            angle: currentAngle,
            mirrorScale: currentMirrorScale,
            centerRatio: cropRatio.centerRatio,
            sizeRatio: cropRatio.sizeRatio,
            waterSizeRatio: .zero,
            waterCenterRatio: .zero
        )
        return cropFactor.allowCroped
    }
    
    var isCropImage: Bool {
        var isCropImage = canReset
        if !isCropImage, state == .edit {
            if isFixedRatio && !isResetIgnoreFixedRatio {
                let fromSize = getExactnessSize(contentView.size)
                let toSize = getExactnessSize(frameView.controlView.size)
                if !fromSize.equalTo(toSize) {
                    isCropImage = true
                }
            }
        }
        return isCropImage
    }
    
    func cropImage(completion: @escaping (Result<ImageEditedResult, EditorError>) -> Void) {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.cropImage(completion: completion)
            }
            return
        }
        deselectedSticker()
        let image = self.image
        let imageData = self.imageData
        let cropRect = getCropRect()
        let cropRatio = getCropOption()
        var canvasImage: UIImage?
        if #available(iOS 13.0, *) {
            canvasImage = contentView.isCanvasEmpty ? nil : contentView.canvasImage
        }
        let cropFactor = CropFactor(
            drawLayer: contentView.drawView.count > 0 ? contentView.drawView.layer : nil,
            canvasImage: canvasImage,
            mosaicLayer: contentView.mosaicView.count > 0 ? contentView.mosaicView.layer : nil,
            stickersLayer: contentView.stickerView.count > 0 ? contentView.stickerView.layer : nil,
            isCropImage: isCropImage,
            isRound: isCropRund,
            maskImage: maskImage,
            angle: currentAngle,
            mirrorScale: currentMirrorScale,
            centerRatio: cropRatio.centerRatio,
            sizeRatio: cropRatio.sizeRatio,
            waterSizeRatio: .zero,
            waterCenterRatio: .zero
        )
        if !cropFactor.allowCroped {
            completion(.failure(EditorError.error(type: .nothingProcess, message: "没有需要处理的操作")))
            return
        }
        DispatchQueue.global(qos: .userInteractive).async {
            if self.contentType == .image {
                self.cropImage(
                    image,
                    imageData: imageData,
                    rect: cropRect,
                    cropFactor: cropFactor,
                    completion: completion
                )
            }else {
                completion(.failure(EditorError.error(type: .typeError, message: "裁剪出错，不是图片类型")))
            }
        }
    }
}

extension EditorAdjusterView {
    
    func getCropRect() -> CGRect {
        let controlFrame = frameView.controlView.frame
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let currentTransform = scrollView.transform
        scrollView.transform = .identity
        var rect = frameView.convert(controlFrame, to: contentView)
        scrollView.transform = currentTransform
        CATransaction.commit()
        rect = CGRect(
            x: rect.minX * scrollView.zoomScale,
            y: rect.minY * scrollView.zoomScale,
            width: rect.width * scrollView.zoomScale,
            height: rect.height * scrollView.zoomScale
        )
        return rect
    }
    
    func getCropOption() -> (centerRatio: CGPoint, sizeRatio: CGPoint) {
        let viewSize = contentView.size
        
        let controlFrame = frameView.controlView.frame
        var rect = frameView.convert(controlFrame, to: contentView)
        rect = CGRect(
            x: rect.minX * scrollView.zoomScale,
            y: rect.minY * scrollView.zoomScale,
            width: rect.width * scrollView.zoomScale,
            height: rect.height * scrollView.zoomScale
        )
        
        let centerRatio = CGPoint(
            x: CGFloat(floor(rect.midX / viewSize.width * 10000) / 10000),
            y: CGFloat(floor(rect.midY / viewSize.height * 10000) / 10000))
        
        let cropRect = getCropRect()
        let sizeRatio = CGPoint(
            x: CGFloat(floor(cropRect.width / viewSize.width * 10000) / 10000),
            y: CGFloat(floor(cropRect.height / viewSize.height * 10000) / 10000)
        )
        
        return (centerRatio: centerRatio, sizeRatio: sizeRatio)
    }
    
    func cropImage(
        _ image: UIImage?,
        imageData: Data?,
        rect: CGRect,
        cropFactor: CropFactor,
        completion: @escaping (Result<ImageEditedResult, EditorError>) -> Void
    ) {
        guard var inputImage = image else {
            DispatchQueue.main.async {
                completion(.failure(EditorError.error(type: .inputIsEmpty, message: "源数据为空")))
            }
            return
        }
        var cropRect = rect
        let imageMaxSize = inputImage.size.width * inputImage.size.height * exportScale
        let overlayMaxSize: CGFloat = 1920 * 1080 * 3
        let overlayImageSize: CGSize
        if imageMaxSize > overlayMaxSize {
            let scale = overlayMaxSize / imageMaxSize
            overlayImageSize = .init(width: inputImage.width * scale, height: inputImage.height * scale)
        }else {
            overlayImageSize = inputImage.size
        }
        let overlayImage = getOverlayImage(overlayImageSize, cropFactor: cropFactor)
        var exportScale = exportScale
        if !isJPEGImage, !isHEICImage {
            let exportMaxSize = exportMaxSize * 0.7
            if imageMaxSize > exportMaxSize {
                exportScale = exportMaxSize / imageMaxSize
            }
        }else {
            if imageMaxSize > exportMaxSize {
                exportScale = exportMaxSize / imageMaxSize
            }
        }
        if exportScale != inputImage.scale && overlayImage != nil {
            let scale = exportScale / inputImage.scale
            cropRect.origin.x *= scale
            cropRect.origin.y *= scale
            cropRect.size.width *= scale
            cropRect.size.height *= scale
        }
        if let animateOption = imageData?.animateImageFrame() {
            cropAnimateImage(
                animateOption,
                overlayImage: overlayImage,
                cropFactor: cropFactor,
                completion: completion
            )
            return
        }
        if let overlayImage = overlayImage,
           let image = inputImage.merge(images: [overlayImage], opaque: isJPEGImage, isJPEG: isJPEGImage || isHEICImage, compressionQuality: 1, scale: exportScale) {
            inputImage = image
        }
        guard let image = PhotoTools.cropImage(inputImage, cropFactor: cropFactor) else {
            DispatchQueue.main.async {
                completion(.failure(EditorError.error(type: .cropImageFailed, message: "裁剪图片时发生错误")))
            }
            return
        }
        getImageData(image, compressionQuality: exportScale != self.exportScale ? 0.8 : 0.5) { [weak self] in
            guard let self = self,
                  let imageData = $0
            else {
                DispatchQueue.main.async {
                    completion(.failure(EditorError.error(type: .dataAcquisitionFailed, message: "imageData获取失败")))
                }
                return
            }
            let compressionQuality = cropFactor.isRound ? nil : self.getCompressionQuality(CGFloat(imageData.count), imageSize: image.size)
            self.compressImageData(
                imageData,
                compressionQuality: compressionQuality
            ) { [weak self] data in
                guard let self = self,
                      let data = data,
                      let image = UIImage(data: data)?.normalizedImage() else {
                    DispatchQueue.main.async {
                        completion(.failure(EditorError.error(type: .compressionFailed, message: "图片压缩失败")))
                    }
                    return
                }
                let urlConfig: EditorURLConfig
                if let config = self.urlConfig {
                    urlConfig = config
                }else {
                    let fileName = String.fileName(suffix: data.isGif ? "gif" : (isJPEGImage ? "jpeg" : "png"))
                    urlConfig = .init(fileName: fileName, type: .temp)
                }
                if PhotoTools.write(toFile: urlConfig.url, imageData: data) == nil {
                    DispatchQueue.main.async {
                        completion(.failure(.error(type: .writeFileFailed, message: "图片写入文件失败：\(urlConfig.url)")))
                    }
                    return
                }
                let thumbImage: UIImage?
                if image.width * image.height < 40000 {
                    thumbImage = image
                }else {
                    thumbImage = image.scaleToFillSize(size: .init(width: 200, height: 200))
                }
                DispatchQueue.main.async {
                    if let thumbImage {
                        completion(
                            .success(.init(
                                image: thumbImage,
                                urlConfig: urlConfig,
                                imageType: .normal,
                                data: self.getData()
                            ))
                        )
                    }else {
                        completion(.failure(.error(type: .compressionFailed, message: "封面图片压缩失败")))
                    }
                }
            }
        }
    }
}

extension EditorAdjusterView {
    func cropAnimateImage(
        _ option: (images: [UIImage], delays: [Double], duration: Double),
        overlayImage: UIImage?,
        cropFactor: CropFactor,
        completion: @escaping (Result<ImageEditedResult, EditorError>) -> Void
    ) {
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "HXPhotoPicker.editorview.cropAmimateImage", qos: .utility)
        
        var images: [UIImage] = []
        var delays: [Double] = []
        for (index, image) in option.images.enumerated() {
            queue.async(group: group) {
                autoreleasepool {
                    let semaphore = DispatchSemaphore(value: 0)
                    var currentImage = image
                    if let newImage = self.animateImageMerge(image, overlayImage: overlayImage) {
                        currentImage = newImage
                    }
                    if let newImage = PhotoTools.cropImage(currentImage, cropFactor: cropFactor) {
                        self.getImageData(image) { [weak self] data1 in
                            guard let self = self else { return }
                            self.getImageData(newImage) { [weak self] data2 in
                                guard let self = self else { return }
                                if let data1 = data1,
                                   let data2 = data2 {
                                    var compressionQuality = CGFloat(data1.count) / CGFloat(data2.count)
                                    let data2Count = CGFloat(data2.count)
                                    if data2Count > 800000 {
                                        if compressionQuality < 0.3 {
                                            compressionQuality = 0.3
                                        }
                                    }else if data2Count > 500000 {
                                        if compressionQuality < 0.5 {
                                            compressionQuality = 0.5
                                        }
                                    }else if data2Count > 200000 {
                                        if compressionQuality < 0.7 {
                                            compressionQuality = 0.7
                                        }
                                    }else {
                                        compressionQuality = 0.9
                                    }
                                    self.compressImageData(
                                        data2,
                                        compressionQuality: compressionQuality
                                    ) { imageData in
                                        if let imageData = imageData,
                                           let image = UIImage(data: imageData) {
                                            images.append(image)
                                            delays.append(option.delays[index])
                                        }
                                        semaphore.signal()
                                    }
                                }else {
                                    images.append(newImage)
                                    delays.append(option.delays[index])
                                    semaphore.signal()
                                }
                            }
                        }
                    }
                    semaphore.wait()
                }
            }
        }
        group.notify(queue: .global(qos: .userInitiated)) {
            let urlConfig: EditorURLConfig
            if let config = self.urlConfig {
                urlConfig = config
            }else {
                let fileName = String.fileName(suffix: "gif")
                urlConfig = .init(fileName: fileName, type: .temp)
            }
            if let image = images.first,
               PhotoTools.createAnimatedImage(
                images: images,
                delays: delays,
                toFile: urlConfig.url
               ) != nil {
                DispatchQueue.main.async {
                    completion(
                        .success(.init(
                            image: image,
                            urlConfig: urlConfig,
                            imageType: .gif,
                            data: self.getData()
                        ))
                    )
                }
                return
            }
            DispatchQueue.main.async {
                completion(.failure(EditorError.error(type: .blankFrame, message: "gif图片为空")))
            }
        }
    }
    
    private func animateImageMerge(_ image: UIImage, overlayImage: UIImage?) -> UIImage? {
        guard let overlayImage = overlayImage else {
            return nil
        }
        return image.merge(images: [overlayImage], scale: exportScale)
    }
    
    fileprivate func getCompressionQuality(_ dataCount: CGFloat, imageSize: CGSize) -> CGFloat? {
        if imageSize.width * imageSize.height < 3840 * 3840 {
            return nil
        }
        if dataCount > 30000000 {
            return 25000000 / dataCount
        }else if dataCount > 15000000 {
            return 10000000 / dataCount
        }else if dataCount > 10000000 {
            return 6000000 / dataCount
        }else if dataCount > 6000000 {
            return 4500000 / dataCount
        }else if dataCount > 3000000 {
            return 3000000 / dataCount
        }
        return nil
    }
    
    fileprivate func compressImageData(
        _ imageData: Data,
        compressionQuality: CGFloat?,
        completion: @escaping (Data?) -> Void
    ) {
        PhotoTools.compressImageData(
            imageData,
            compressionQuality: compressionQuality,
            queueLabel: "HXPhotoPicker.editorview.compressImageDataQueue"
        ) {
            completion($0)
        }
    }
    
    fileprivate func getImageData(_ image: UIImage, compressionQuality: CGFloat = 0.5, completion: @escaping (Data?) -> Void) {
        PhotoTools.getImageData(
            image,
            isHEIC: isHEICImage,
            isJPEG: isJPEGImage,
            compressionQuality: compressionQuality,
            queueLabel: "HXPhotoPicker.editor.cropImageQueue"
        ) {
            guard let imageData = $0 else {
                completion(nil)
                return
            }
            completion(imageData)
        }
    }
}

extension EditorAdjusterView {
    func getOverlayImage(_ imageSize: CGSize, cropFactor: CropFactor) -> UIImage? {
        var images: [UIImage] = []
        if let layer = cropFactor.drawLayer,
           let drawImage = layer.convertedToImage() {
            images.append(drawImage)
            layer.contents = nil
        }
        if let image = cropFactor.canvasImage {
            images.append(image)
        }
        if let layer = cropFactor.mosaicLayer,
           let mosaicImage = layer.convertedToImage() {
            images.append(mosaicImage)
            layer.contents = nil
        }
        if let layer = cropFactor.stickersLayer,
           let stickersImage = layer.convertedToImage() {
            images.append(stickersImage)
            layer.contents = nil
        }
        return UIImage.merge(images: images)?.scaleToFillSize(size: imageSize)
    }
}

extension EditorAdjusterView {
    
    struct CropFactor {
        let drawLayer: CALayer?
        let canvasImage: UIImage?
        let mosaicLayer: CALayer?
        let stickersLayer: CALayer?
        let isCropImage: Bool
        let isRound: Bool
        let maskImage: UIImage?
        let angle: CGFloat
        let mirrorScale: CGPoint
        let centerRatio: CGPoint
        let sizeRatio: CGPoint
        let waterSizeRatio: CGPoint
        let waterCenterRatio: CGPoint
        
        let allowCroped: Bool
        let isClip: Bool
        let isEmpty: Bool
        
        init(
            drawLayer: CALayer?,
            canvasImage: UIImage?,
            mosaicLayer: CALayer?,
            stickersLayer: CALayer?,
            isCropImage: Bool,
            isRound: Bool,
            maskImage: UIImage?,
            angle: CGFloat,
            mirrorScale: CGPoint,
            centerRatio: CGPoint,
            sizeRatio: CGPoint,
            waterSizeRatio: CGPoint,
            waterCenterRatio: CGPoint
        ) {
            self.drawLayer = drawLayer
            self.canvasImage = canvasImage
            self.mosaicLayer = mosaicLayer
            self.stickersLayer = stickersLayer
            self.isCropImage = isCropImage
            self.isRound = isRound
            self.maskImage = maskImage
            self.angle = angle
            self.mirrorScale = mirrorScale
            self.centerRatio = centerRatio
            self.sizeRatio = sizeRatio
            self.waterSizeRatio = waterSizeRatio
            self.waterCenterRatio = waterCenterRatio
            
            isEmpty = drawLayer == nil
            && canvasImage == nil
            && mosaicLayer == nil
            && stickersLayer == nil
            && !isCropImage
            && !isRound
            && maskImage == nil
            && angle == 0
            && mirrorScale == .zero
            && centerRatio == .zero
            && sizeRatio == .zero
            && waterSizeRatio == .zero
            && waterCenterRatio == .zero
            
            if isEmpty {
                allowCroped = false
            }else {
                allowCroped = !(!isCropImage &&
                                !isRound &&
                                maskImage == nil &&
                                mirrorScale.x * mirrorScale.y > 0 &&
                                drawLayer == nil &&
                                canvasImage == nil &&
                                mosaicLayer == nil &&
                                stickersLayer == nil)
            }
            isClip = isCropImage || isRound || maskImage != nil
        }
        
        func isEqual(_ facotr: CropFactor) -> Bool {
            if isCropImage != facotr.isCropImage {
                return false
            }
            if isRound != facotr.isRound {
                return false
            }
            if maskImage != facotr.maskImage {
                return false
            }
            if angle != facotr.angle {
                return false
            }
            if !mirrorScale.equalTo(facotr.mirrorScale) {
                return false
            }
            if !centerRatio.equalTo(facotr.centerRatio) {
                return false
            }
            if !sizeRatio.equalTo(facotr.sizeRatio) {
                return false
            }
            return true
        }
        
        static var empty: CropFactor {
            .init(
                drawLayer: nil,
                canvasImage: nil,
                mosaicLayer: nil,
                stickersLayer: nil,
                isCropImage: false,
                isRound: false,
                maskImage: nil,
                angle: 0,
                mirrorScale: .zero,
                centerRatio: .zero,
                sizeRatio: .zero,
                waterSizeRatio: .zero,
                waterCenterRatio: .zero
            )
        }
    }
    
}
