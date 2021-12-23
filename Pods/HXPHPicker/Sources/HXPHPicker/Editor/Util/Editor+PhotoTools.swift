//
//  Editor+PhotoTools.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/9.
//

import UIKit
import ImageIO
import CoreImage
import CoreServices

extension PhotoTools {
    static func createAnimatedImage(
        images: [UIImage],
        delays: [Double]
    ) -> URL? {
        if images.isEmpty || delays.isEmpty {
            return nil
        }
        let frameCount = images.count
        let imageURL = getImageTmpURL(.gif)
        guard let destination = CGImageDestinationCreateWithURL(
                imageURL as CFURL,
                kUTTypeGIF as CFString,
                frameCount, nil
        ) else {
            return nil
        }
        let gifProperty = [
            kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFHasGlobalColorMap: true,
                kCGImagePropertyColorModel: kCGImagePropertyColorModelRGB,
                kCGImagePropertyDepth: 8,
                kCGImagePropertyGIFLoopCount: 0
            ]
        ]
        CGImageDestinationSetProperties(destination, gifProperty as CFDictionary)
        for (index, image) in images.enumerated() {
            let delay = delays[index]
            let framePreperty = [
                kCGImagePropertyGIFDictionary: [
                    kCGImagePropertyGIFDelayTime: delay
                ]
            ]
            if let cgImage = image.cgImage {
                CGImageDestinationAddImage(destination, cgImage, framePreperty as CFDictionary)
            }
        }
        if CGImageDestinationFinalize(destination) {
            return imageURL
        }
        removeFile(fileURL: imageURL)
        return nil
    }
    
    static func checkNetworkURL(for url: URL) -> Bool {
        if checkLocalURL(for: url.path) {
            return false
        }
        if let scheme = url.scheme {
            if scheme == "http" || scheme == "https" {
                return true
            }
        }
        return UIApplication.shared.canOpenURL(url)
    }
    
    static func checkLocalURL(for path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }
    
    static func getFrameDuration(from gifInfo: [String: Any]?) -> TimeInterval {
        let defaultFrameDuration = 0.1
        guard let gifInfo = gifInfo else { return defaultFrameDuration }
        
        let unclampedDelayTime = gifInfo[kCGImagePropertyGIFUnclampedDelayTime as String] as? NSNumber
        let delayTime = gifInfo[kCGImagePropertyGIFDelayTime as String] as? NSNumber
        let duration = unclampedDelayTime ?? delayTime
        
        guard let frameDuration = duration else { return defaultFrameDuration }
        return frameDuration.doubleValue > 0.011 ? frameDuration.doubleValue : defaultFrameDuration
    }

    static func getFrameDuration(
        from imageSource: CGImageSource,
        at index: Int
    ) -> TimeInterval {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, index, nil)
            as? [String: Any] else { return 0.0 }

        let gifInfo = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any]
        return getFrameDuration(from: gifInfo)
    }
    
    public static func defaultColors() -> [String] {
        ["#ffffff", "#2B2B2B", "#FA5150", "#FEC200", "#07C160", "#10ADFF", "#6467EF"]
    }
    static func defaultMusicInfos() -> [VideoEditorMusicInfo] {
        var infos: [VideoEditorMusicInfo] = []
        if let audioURL = URL(string: "http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/chartle/%E5%A4%A9%E5%A4%96%E6%9D%A5%E7%89%A9.mp3"), // swiftlint:disable:this line_length
           let lrc = "天外来物".lrc {
            let info = VideoEditorMusicInfo(
                audioURL: audioURL,
                lrc: lrc,
                urlType: .network
            )
            infos.append(info)
        }
        return infos
    }
    #if canImport(Kingfisher)
    public static func defaultTitleChartlet() -> [EditorChartlet] {
        let title = EditorChartlet(
            url: URL(string: "http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/chartle/xxy_s_highlighted.png")
        )
        return [title]
    }
    
    public static func defaultNetworkChartlet() -> [EditorChartlet] {
        var chartletList: [EditorChartlet] = []
        for index in 1...40 {
            let urlString = "http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/chartle/xxy" + String(index) + ".png"
            let chartlet = EditorChartlet(
                url: .init(string: urlString)
            )
            chartletList.append(chartlet)
        }
        return chartletList
    }
    #endif
    
    /// 默认滤镜
    public static func defaultFilters() -> [PhotoEditorFilterInfo] {
        [
            PhotoEditorFilterInfo(
                filterName: "老电影".localized,
                defaultValue: 1
            ) { (image, lastImage, value, event) in
                if event == .touchUpInside {
                    return oldMovie(image, value: value)
                }
                return nil
            },
            PhotoEditorFilterInfo(
                filterName: "怀旧".localized
            ) { (image, _, _, _) in
                image.filter(
                    name: "CIPhotoEffectInstant",
                    parameters: [:]
                )
            },
            PhotoEditorFilterInfo(
                filterName: "黑白".localized
            ) { (image, _, _, _) in
                image.filter(
                    name: "CIPhotoEffectNoir",
                    parameters: [:]
                )
            },
            PhotoEditorFilterInfo(
                filterName: "色调".localized
            ) { (image, _, _, _) in
                image.filter(
                    name: "CIPhotoEffectTonal",
                    parameters: [:]
                )
            },
            PhotoEditorFilterInfo(
                filterName: "模糊".localized,
                defaultValue: 0.5
            ) { (image, lastImage, value, event) in
                if event == .touchUpInside {
                    return image.filter(
                        name: "CIGaussianBlur",
                        parameters: [
                            kCIInputRadiusKey: NSNumber(value: 10 * value)
                        ]
                    )
                }
                return nil
            },
            PhotoEditorFilterInfo(
                filterName: "岁月".localized
            ) { (image, _, _, _) in
                image.filter(
                    name: "CIPhotoEffectTransfer",
                    parameters: [:]
                )
            },
            PhotoEditorFilterInfo(
                filterName: "单色".localized
            ) { (image, _, _, _) in
                image.filter(
                    name: "CIPhotoEffectMono",
                    parameters: [:]
                )
            },
            PhotoEditorFilterInfo(
                filterName: "褪色".localized
            ) { (image, _, _, _) in
                image.filter(
                    name: "CIPhotoEffectFade",
                    parameters: [:]
                )
            },
            PhotoEditorFilterInfo(
                filterName: "冲印".localized
            ) { (image, _, _, _) in
                image.filter(
                    name: "CIPhotoEffectProcess",
                    parameters: [:]
                )
            },
            PhotoEditorFilterInfo(
                filterName: "铬黄".localized
            ) { (image, _, _, _) in
                image.filter(
                    name: "CIPhotoEffectChrome",
                    parameters: [:]
                )
            }
        ]
    }
    
    static func oldMovie(
        _ image: UIImage,
        value: Float
    ) -> UIImage? {
        let inputImage = CIImage.init(image: image)!
        let sepiaToneFilter = CIFilter(name: "CISepiaTone")!
        sepiaToneFilter.setValue(inputImage, forKey: kCIInputImageKey)
        sepiaToneFilter.setValue(value, forKey: kCIInputIntensityKey)
        let whiteSpecksFilter = CIFilter(name: "CIColorMatrix")!
        whiteSpecksFilter.setValue(
            CIFilter(
                name: "CIRandomGenerator"
            )!.outputImage!.cropped(
                to: inputImage.extent
            ),
            forKey: kCIInputImageKey
        )
        whiteSpecksFilter.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputRVector")
        whiteSpecksFilter.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputGVector")
        whiteSpecksFilter.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputBVector")
        whiteSpecksFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBiasVector")
        let sourceOverCompositingFilter = CIFilter(name: "CISourceOverCompositing")!
        sourceOverCompositingFilter.setValue(whiteSpecksFilter.outputImage, forKey: kCIInputBackgroundImageKey)
        sourceOverCompositingFilter.setValue(sepiaToneFilter.outputImage, forKey: kCIInputImageKey)
        let affineTransformFilter = CIFilter(name: "CIAffineTransform")!
        affineTransformFilter.setValue(
            CIFilter(
                name: "CIRandomGenerator"
            )!.outputImage!.cropped(
                to: inputImage.extent
            ),
            forKey: kCIInputImageKey
        )
        affineTransformFilter.setValue(
            NSValue(
                cgAffineTransform: CGAffineTransform(scaleX: 1.5, y: 25)
            ),
            forKey: kCIInputTransformKey
        )
        let darkScratchesFilter = CIFilter(name: "CIColorMatrix")!
        darkScratchesFilter.setValue(affineTransformFilter.outputImage, forKey: kCIInputImageKey)
        darkScratchesFilter.setValue(CIVector(x: 4, y: 0, z: 0, w: 0), forKey: "inputRVector")
        darkScratchesFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputGVector")
        darkScratchesFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBVector")
        darkScratchesFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputAVector")
        darkScratchesFilter.setValue(CIVector(x: 0, y: 1, z: 1, w: 1), forKey: "inputBiasVector")
        let minimumComponentFilter = CIFilter(name: "CIMinimumComponent")!
        minimumComponentFilter.setValue(darkScratchesFilter.outputImage, forKey: kCIInputImageKey)
        let multiplyCompositingFilter = CIFilter(name: "CIMultiplyCompositing")!
        multiplyCompositingFilter.setValue(minimumComponentFilter.outputImage, forKey: kCIInputBackgroundImageKey)
        multiplyCompositingFilter.setValue(sourceOverCompositingFilter.outputImage, forKey: kCIInputImageKey)
        let outputImage = multiplyCompositingFilter.outputImage!
        let context = CIContext(options: nil)
        if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        return nil
    }
}
