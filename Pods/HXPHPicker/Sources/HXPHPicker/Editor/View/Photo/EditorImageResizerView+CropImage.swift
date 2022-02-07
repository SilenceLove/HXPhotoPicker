//
//  EditorImageResizerView+CropImage.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/25.
//

import UIKit

extension EditorImageResizerView {
    
    func cropping(
        _ inputImage: UIImage?,
        toRect cropRect: CGRect,
        mosaicLayer: CALayer?,
        drawLayer: CALayer?,
        stickerLayer: CALayer?,
        isRoundCrop: Bool,
        viewWidth: CGFloat,
        viewHeight: CGFloat
    ) -> (UIImage, URL, PhotoEditResult.ImageType)? { // swiftlint:disable:this large_tuple
        if var inputImage = inputImage {
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
                let fillSize: CGSize
                let inpuSize = inputImage.width * inputImage.height
                if inpuSize > 15000000,
                   let image = inputImage.scaleImage(toScale: 0.6) {
                    inputImage = image
                    fillSize = image.size
                }else {
                    fillSize = inputImage.size
                }
                otherImage = otherImage?.scaleToFillSize(
                    size: fillSize
                )
            }
            var crop_Rect = cropRect
            if exportScale != inputImage.scale && otherImage != nil {
                let scale = exportScale / inputImage.scale
                crop_Rect.origin.x *= scale
                crop_Rect.origin.y *= scale
                crop_Rect.size.width *= scale
                crop_Rect.size.height *= scale
            }
            
            if let option = inputImage.animateImageFrame() {
                var images = [UIImage]()
                var delays = [Double]()
                for (index, image) in option.0.enumerated() {
                    var currentImage = image
                    if let otherImage = otherImage,
                       let newImage = image.merge(
                        images: [otherImage],
                        scale: exportScale
                       ) {
                        currentImage = newImage
                    }
                    if let newImage = cropImage(
                        currentImage,
                        toRect: crop_Rect,
                        isRoundCrop: isRoundCrop,
                        viewWidth: viewWidth,
                        viewHeight: viewHeight
                    ) {
                        images.append(newImage)
                        delays.append(option.1[index])
                    }
                }
                if let image = images.first,
                   let imageURL = PhotoTools.createAnimatedImage(
                    images: images,
                    delays: delays
                   ) {
                    return (image, imageURL, .gif)
                }
                return nil
            }
            if let otherImage = otherImage,
               let image = inputImage.merge(
                images: [otherImage],
                scale: exportScale
               ) {
                inputImage = image
            }
            if let image = cropImage(
                inputImage,
                toRect: crop_Rect,
                isRoundCrop: isRoundCrop,
                viewWidth: viewWidth,
                viewHeight: viewHeight
            ),
               let imageURL = PhotoTools.write(image: image) {
                if let thumbnailImage = image.scaleImage(toScale: 0.6) {
                    return (thumbnailImage, imageURL, .normal)
                }
                return (image, imageURL, .normal)
            }
        }
        return nil
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
