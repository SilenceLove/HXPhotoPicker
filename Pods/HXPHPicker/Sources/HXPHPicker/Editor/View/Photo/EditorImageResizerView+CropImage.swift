//
//  EditorImageResizerView+CropImage.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/25.
//

import UIKit

extension EditorImageResizerView {
    
    private func getOtherImage(
        imageSize: CGSize,
        mosaicLayer: CALayer?,
        drawLayer: CALayer?,
        stickerLayer: CALayer?
    ) -> UIImage? {
        var otherImages: [UIImage] = []
        if let mosaicLayer = mosaicLayer {
            if let image = mosaicLayer.convertedToImage() {
                otherImages.append(image)
            }
            mosaicLayer.contents = nil
        }
        if let drawLayer = drawLayer {
            if let image = drawLayer.convertedToImage() {
                otherImages.append(image)
            }
            drawLayer.contents = nil
        }
        if let stickerLayer = stickerLayer {
            if let image = stickerLayer.convertedToImage() {
                otherImages.append(image)
            }
            stickerLayer.contents = nil
        }
        var otherImage: UIImage?
        if !otherImages.isEmpty {
            otherImage = UIImage.merge(
                images: otherImages
            )
            otherImage = otherImage?.scaleToFillSize(
                size: imageSize
            )
        }
        return otherImage
    }
    func cropAmimateImage(
        _ option: ([UIImage], [Double], Double),
        otherImage: UIImage?,
        crop_Rect: CGRect,
        isRoundCrop: Bool,
        viewWidth: CGFloat,
        viewHeight: CGFloat,
        completion: @escaping ((UIImage, EditorURLConfig, PhotoEditResult.ImageType)?) -> Void
    ) {
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "hxphpicker.editor.cropAmimateImage")
        
        var images = [UIImage]()
        var delays = [Double]()
        for (index, image) in option.0.enumerated() {
            queue.async(
                group: group,
                execute: DispatchWorkItem(block: {
                    autoreleasepool {
                        let semaphore = DispatchSemaphore(value: 0)
                        var currentImage = image
                        if let otherImage = otherImage,
                           let newImage = image.merge(
                            images: [otherImage],
                            scale: self.exportScale
                           ) {
                            currentImage = newImage
                        }
                        
                        if let newImage = self.cropImage(
                            currentImage,
                            toRect: crop_Rect,
                            isRoundCrop: isRoundCrop,
                            viewWidth: viewWidth,
                            viewHeight: viewHeight
                        ) {
                            self.getImageData(image) { [weak self] data1 in
                                guard let self = self else { return }
                                self.getImageData(newImage) { data2 in
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
                                                delays.append(option.1[index])
                                            }
                                            semaphore.signal()
                                        }
                                    }else {
                                        images.append(newImage)
                                        delays.append(option.1[index])
                                        semaphore.signal()
                                    }
                                }
                            }
                        }
                        semaphore.wait()
                    }
                })
            )
        }
        group.notify(queue: .main) {
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
                completion((image, urlConfig, .gif))
                return
            }
            completion(nil)
        }
    }
    func cropping(
        _ inputImage: UIImage?,
        toRect cropRect: CGRect,
        mosaicLayer: CALayer?,
        drawLayer: CALayer?,
        stickerLayer: CALayer?,
        isRoundCrop: Bool,
        viewWidth: CGFloat,
        viewHeight: CGFloat,
        completion: @escaping ((UIImage, EditorURLConfig, PhotoEditResult.ImageType)?) -> Void
    ) {
        guard var inputImage = inputImage else {
            completion(nil)
            return
        }
        let otherImage = getOtherImage(
            imageSize: inputImage.size,
            mosaicLayer: mosaicLayer,
            drawLayer: drawLayer,
            stickerLayer: stickerLayer
        )
        var crop_Rect = cropRect
        if exportScale != inputImage.scale && otherImage != nil {
            let scale = exportScale / inputImage.scale
            crop_Rect.origin.x *= scale
            crop_Rect.origin.y *= scale
            crop_Rect.size.width *= scale
            crop_Rect.size.height *= scale
        }
        
        if let option = inputImage.animateImageFrame() {
            cropAmimateImage(
                option,
                otherImage: otherImage,
                crop_Rect: crop_Rect,
                isRoundCrop: isRoundCrop,
                viewWidth: viewWidth,
                viewHeight: viewHeight
            ) { result in
                completion(result)
            }
            return
        }
        if let otherImage = otherImage,
           let image = inputImage.merge(
            images: [otherImage],
            scale: exportScale
           ) {
            inputImage = image
        }
        guard let image = cropImage(
            inputImage,
            toRect: crop_Rect,
            isRoundCrop: isRoundCrop,
            viewWidth: viewWidth,
            viewHeight: viewHeight
        ) else {
            completion(nil)
            return
        }
        getImageData(image) { [weak self] imageData in
            guard let self = self,
                  let imageData = imageData
            else {
                completion(nil)
                return
            }
            let compressionQuality = self.getCompressionQuality(CGFloat(imageData.count))
            self.compressImageData(
                imageData,
                compressionQuality: compressionQuality
            ) { data in
                guard let data = data else {
                    completion(nil)
                    return
                }
                let urlConfig: EditorURLConfig
                if let config = self.urlConfig {
                    urlConfig = config
                }else {
                    let fileName = String.fileName(suffix: data.isGif ? "gif" : "png")
                    urlConfig = .init(fileName: fileName, type: .temp)
                }
                if PhotoTools.write(
                    toFile: urlConfig.url,
                    imageData: data
                   ) != nil {
                    self.compressImageData(
                        data,
                        compressionQuality: 0.3
                    ) { thumbData in
                        if let thumbData = thumbData,
                           let thumbnailImage = UIImage(data: thumbData) {
                            completion((thumbnailImage, urlConfig, .normal))
                        }else {
                            completion(nil)
                        }
                    }
                    return
                }
            }
        }
    }
    
    private func getCompressionQuality(_ dataCount: CGFloat) -> CGFloat? {
        var compressionQuality: CGFloat?
        if dataCount > 30000000 {
            compressionQuality = 25000000 / dataCount
        }else if dataCount > 15000000 {
            compressionQuality = 10000000 / dataCount
        }else if dataCount > 10000000 {
            compressionQuality = 6000000 / dataCount
        }else if dataCount > 3000000 {
            compressionQuality = 3000000 / dataCount
        }
        return compressionQuality
    }
    private func compressImageData(
        _ imageData: Data,
        compressionQuality: CGFloat?,
        completion: @escaping (Data?) -> Void
    ) {
        let serialQueue = DispatchQueue(label: "hxphpicker.editor.compressImageDataQueue", qos: .utility, attributes: [], autoreleaseFrequency: .workItem, target: nil)
        serialQueue.async {
            autoreleasepool {
                if let compressionQuality = compressionQuality {
                    if let data = PhotoTools.imageCompress(
                        imageData,
                        compressionQuality: compressionQuality
                    ) {
                        completion(data)
                        return
                    }
                }
                completion(imageData)
            }
        }
    }
    
    private func getImageData(_ image: UIImage, completion: @escaping (Data?) -> Void) {
        let serialQueue = DispatchQueue(label: "hxphpicker.editor.cropImageQueue", qos: .utility, attributes: [], autoreleaseFrequency: .workItem, target: nil)
        serialQueue.async {
            autoreleasepool {
                guard let imageData = PhotoTools.getImageData(for: image) else {
                    completion(nil)
                    return
                }
                completion(imageData)
            }
        }
    }
    func cropImage(
        _ inputImage: UIImage?,
        toRect cropRect: CGRect,
        isRoundCrop: Bool,
        viewWidth: CGFloat,
        viewHeight: CGFloat
    ) -> UIImage? {
        var image = inputImage?.cropImage(
            toRect: cropRect,
            viewWidth: viewWidth,
            viewHeight: viewHeight
        )
        if isRoundCrop {
            image = image?.roundCropping()
        }
        var rotate = CGFloat.pi * currentAngle / 180
        if rotate != 0 {
            rotate = CGFloat.pi * 2 + rotate
        }
        let isHorizontal = mirrorType == .horizontal
        if rotate > 0 || isHorizontal {
            let angle = Int(currentAngle)
            image = image?.rotation(angle: angle, isHorizontal: isHorizontal)
        }
        return image
    }
}
