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
                lrc: lrc
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
                filterName: "唯美".localized
            ) { image, _, _, _ in
                nashvilleFilter(image)
            },
            PhotoEditorFilterInfo(
                filterName: "梦幻".localized
            ) { (image, _, _, _) in
                toasterFilter(image)
            },
            PhotoEditorFilterInfo(
                filterName: "1977"
            ) { (image, _, _, _) in
                apply1977Filter(image)
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
                filterName: "岁月".localized
            ) { (image, _, _, _) in
                image.filter(
                    name: "CIPhotoEffectTransfer",
                    parameters: [:]
                )
            },
            PhotoEditorFilterInfo(
                filterName: "模糊".localized,
                defaultValue: 0.2
            ) { (image, lastImage, value, event) in
                if event == .touchUpInside {
                    return image.blurredImage(50 * value)
                }
                return nil
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
            },
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
                filterName: "色调".localized
            ) { (image, _, _, _) in
                image.filter(
                    name: "CIPhotoEffectTonal",
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
                filterName: "黑白".localized
            ) { (image, _, _, _) in
                image.filter(
                    name: "CIPhotoEffectNoir",
                    parameters: [:]
                )
            }
        ]
    }
    
    public static func defaultVideoFilters() -> [PhotoEditorFilterInfo] {
        [
            PhotoEditorFilterInfo(
                filterName: "唯美".localized
            ) { (image, _, _, _) in
                nashvilleFilter(image)
            } videoFilterHandler: { ciImage, _ in
                nashvilleFilter(ciImage)
            },
            PhotoEditorFilterInfo(
                filterName: "梦幻".localized
            ) { (image, _, _, _) in
                toasterFilter(image)
            } videoFilterHandler: { ciImage, _ in
                toasterFilter(ciImage)
            },
            PhotoEditorFilterInfo(
                filterName: "1977"
            ) { (image, _, _, _) in
                apply1977Filter(image)
            } videoFilterHandler: { ciImage, _ in
                apply1977Filter(ciImage)
            },
            PhotoEditorFilterInfo(
                filterName: "怀旧".localized
            ) { (image, _, _, _) in
                image.filter(
                    name: "CIPhotoEffectInstant",
                    parameters: [:]
                )
            } videoFilterHandler: { ciImage, _ in
                ciImage.filter(name: "CIPhotoEffectInstant", parameters: [:])
            },
            PhotoEditorFilterInfo(
                filterName: "岁月".localized
            ) { (image, _, _, _) in
                image.filter(
                    name: "CIPhotoEffectTransfer",
                    parameters: [:]
                )
            } videoFilterHandler: { ciImage, _ in
                ciImage.filter(name: "CIPhotoEffectTransfer", parameters: [:])
            },
            PhotoEditorFilterInfo(
                filterName: "模糊".localized,
                defaultValue: 0.2
            ) { (image, lastImage, value, event) in
                if event == .touchUpInside {
                    return image.blurredImage(50.0 * value)
                }
                return nil
            } videoFilterHandler: {
                $0.filter(
                    name: "CIGaussianBlur",
                    parameters: [kCIInputRadiusKey: 50.0 * $1]
                )
            },
            PhotoEditorFilterInfo(
                filterName: "褪色".localized
            ) { (image, _, _, _) in
                image.filter(
                    name: "CIPhotoEffectFade",
                    parameters: [:]
                )
            } videoFilterHandler: { ciImage, _ in
                ciImage.filter(name: "CIPhotoEffectFade", parameters: [:])
            },
            PhotoEditorFilterInfo(
                filterName: "冲印".localized
            ) { (image, _, _, _) in
                image.filter(
                    name: "CIPhotoEffectProcess",
                    parameters: [:]
                )
            } videoFilterHandler: { ciImage, _ in
                ciImage.filter(name: "CIPhotoEffectProcess", parameters: [:])
            },
            PhotoEditorFilterInfo(
                filterName: "铬黄".localized
            ) { (image, _, _, _) in
                image.filter(
                    name: "CIPhotoEffectChrome",
                    parameters: [:]
                )
            } videoFilterHandler: { ciImage, _ in
                ciImage.filter(name: "CIPhotoEffectChrome", parameters: [:])
            },
            PhotoEditorFilterInfo(
                filterName: "老电影".localized,
                defaultValue: 1
            ) { (image, lastImage, value, event) in
                if event == .touchUpInside {
                    return oldMovie(image, value: value)
                }
                return nil
            } videoFilterHandler: {
                oldMovie($0, value: $1)
            },
            PhotoEditorFilterInfo(
                filterName: "色调".localized
            ) { (image, _, _, _) in
                image.filter(
                    name: "CIPhotoEffectTonal",
                    parameters: [:]
                )
            } videoFilterHandler: { ciImage, _ in
                ciImage.filter(name: "CIPhotoEffectTonal", parameters: [:])
            },
            PhotoEditorFilterInfo(
                filterName: "单色".localized
            ) { (image, _, _, _) in
                image.filter(
                    name: "CIPhotoEffectMono",
                    parameters: [:]
                )
            } videoFilterHandler: { ciImage, _ in
                ciImage.filter(name: "CIPhotoEffectMono", parameters: [:])
            },
            PhotoEditorFilterInfo(
                filterName: "黑白".localized
            ) { (image, _, _, _) in
                image.filter(
                    name: "CIPhotoEffectNoir",
                    parameters: [:]
                )
            } videoFilterHandler: { ciImage, _ in
                ciImage.filter(name: "CIPhotoEffectNoir", parameters: [:])
            }
        ]
    }
    
    public static func nashvilleFilter(
        _ image: CIImage
    ) -> CIImage? {
        let backgroundImage = getColorImage(red: 247, green: 176, blue: 153, alpha: Int(255 * 0.56),
                                            rect: image.extent)
        let backgroundImage2 = getColorImage(red: 0, green: 70, blue: 150, alpha: Int(255 * 0.4),
                                             rect: image.extent)
        return image
            .applyingFilter("CIDarkenBlendMode", parameters: [
                "inputBackgroundImage": backgroundImage
                ])
            .applyingFilter("CISepiaTone", parameters: [
                "inputIntensity": 0.2
                ])
            .applyingFilter("CIColorControls", parameters: [
                "inputSaturation": 1.2,
                "inputBrightness": 0.05,
                "inputContrast": 1.1
                ])
            .applyingFilter("CILightenBlendMode", parameters: [
                "inputBackgroundImage": backgroundImage2
                ])
    }
    
    public static func oldMovie(
        _ image: CIImage,
        value: Float
    ) -> CIImage? {
        let inputImage = image
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
        return multiplyCompositingFilter.outputImage
    }
    
    public static func toasterFilter(_ ciImage: CIImage) -> CIImage? {
        let width = ciImage.extent.width
        let height = ciImage.extent.height
        let centerWidth = width / 2.0
        let centerHeight = height / 2.0
        let radius0 = min(width / 4.0, height / 4.0)
        let radius1 = min(width / 1.5, height / 1.5)
        
        let color0 = getColor(red: 128, green: 78, blue: 15, alpha: 255)
        let color1 = getColor(red: 79, green: 0, blue: 79, alpha: 255)
        let circle = CIFilter(name: "CIRadialGradient", parameters: [
            "inputCenter": CIVector(x: centerWidth, y: centerHeight),
            "inputRadius0": radius0,
            "inputRadius1": radius1,
            "inputColor0": color0,
            "inputColor1": color1
            ])?.outputImage?.cropped(to: ciImage.extent)
        
        return ciImage
            .applyingFilter("CIColorControls", parameters: [
                "inputSaturation": 1.0,
                "inputBrightness": 0.01,
                "inputContrast": 1.1
                ])
            .applyingFilter("CIScreenBlendMode", parameters: [
                "inputBackgroundImage": circle!
                ])
    }
    
    public static func apply1977Filter(_ ciImage: CIImage) -> CIImage? {
        let filterImage = getColorImage(red: 243, green: 106, blue: 188, alpha: Int(255 * 0.1), rect: ciImage.extent)
        let backgroundImage = ciImage
            .applyingFilter("CIColorControls", parameters: [
                "inputSaturation": 1.3,
                "inputBrightness": 0.1,
                "inputContrast": 1.05
                ])
            .applyingFilter("CIHueAdjust", parameters: [
                "inputAngle": 0.3
                ])
        return filterImage
            .applyingFilter("CIScreenBlendMode", parameters: [
                "inputBackgroundImage": backgroundImage
                ])
            .applyingFilter("CIToneCurve", parameters: [
                "inputPoint0": CIVector(x: 0, y: 0),
                "inputPoint1": CIVector(x: 0.25, y: 0.20),
                "inputPoint2": CIVector(x: 0.5, y: 0.5),
                "inputPoint3": CIVector(x: 0.75, y: 0.80),
                "inputPoint4": CIVector(x: 1, y: 1)
                ])
    }
}
