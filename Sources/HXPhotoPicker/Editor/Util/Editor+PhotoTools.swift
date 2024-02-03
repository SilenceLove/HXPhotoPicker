//
//  Editor+PhotoTools.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/1/9.
//

import UIKit

extension PhotoTools {
    
    static func getCompressionQuality(_ dataCount: CGFloat) -> CGFloat? {
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
    
    public static func defaultColors() -> [String] {
        if #available(iOS 14.0, *) {
            return ["#ffffff", "#2B2B2B", "#FA5150", "#FEC200", "#07C160", "#10ADFF", "#6467EF", "#9EB6DC"]
        }
        return ["#ffffff", "#2B2B2B", "#FA5150", "#FEC200", "#07C160", "#10ADFF", "#6467EF"]
    }
    static func defaultMusicInfos() -> [VideoEditorMusicInfo] {
        var infos: [VideoEditorMusicInfo] = []
        if let audioURL = URL(string: "http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/chartle/%E5%A4%A9%E5%A4%96%E6%9D%A5%E7%89%A9.mp3"), // swiftlint:disable:this line_length
           let lrc = "天外来物".lrc {
            let info = VideoEditorMusicInfo(
                audioURL: .network(url: audioURL),
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
        var filters: [PhotoEditorFilterInfo] = []
        filters.append(contentsOf: [
            PhotoEditorFilterInfo(
                filterName: "唯美"
            ) { image, _, _, _ in
                nashvilleFilter(image)
            },
            PhotoEditorFilterInfo(
                filterName: "梦幻"
            ) { (image, _, _, _) in
                toasterFilter(image)
            },
            PhotoEditorFilterInfo(
                filterName: "1977"
            ) { (image, _, _, _) in
                apply1977Filter(image)
            },
            PhotoEditorFilterInfo(
                filterName: "怀旧"
            ) { (image, _, _, _) in
                image.filter(
                    name: "CIPhotoEffectInstant",
                    parameters: [:]
                )
            },
            PhotoEditorFilterInfo(
                filterName: "岁月"
            ) { (image, _, _, _) in
                image.filter(
                    name: "CIPhotoEffectTransfer",
                    parameters: [:]
                )
            },
            PhotoEditorFilterInfo(
                filterName: "模糊",
                parameters: [.init(defaultValue: 0.2)],
                filterHandler: { image, _, parameters, isCover in
                    image.blurredImage(isCover ? 10 : 50 * parameters[0].value)
            }),
            PhotoEditorFilterInfo(
                filterName: "褪色"
            ) { (image, _, _, _) in
                image.filter(
                    name: "CIPhotoEffectFade",
                    parameters: [:]
                )
            },
            PhotoEditorFilterInfo(
                filterName: "冲印"
            ) { (image, _, _, _) in
                image.filter(
                    name: "CIPhotoEffectProcess",
                    parameters: [:]
                )
            },
            PhotoEditorFilterInfo(
                filterName: "铬黄"
            ) { (image, _, _, _) in
                image.filter(
                    name: "CIPhotoEffectChrome",
                    parameters: [:]
                )
            },
            PhotoEditorFilterInfo(
                filterName: "老电影",
                parameters: [.init(defaultValue: 1)],
                filterHandler: { image, _, parameters, isCover in
                    return oldMovie(image, value: isCover ? 1 : parameters[0].value)
            }),
            PhotoEditorFilterInfo(
                filterName: "色调"
            ) { (image, _, _, _) in
                image.filter(
                    name: "CIPhotoEffectTonal",
                    parameters: [:]
                )
            },
            PhotoEditorFilterInfo(
                filterName: "单色"
            ) { (image, _, _, _) in
                image.filter(
                    name: "CIPhotoEffectMono",
                    parameters: [:]
                )
            },
            PhotoEditorFilterInfo(
                filterName: "黑白"
            ) { (image, _, _, _) in
                image.filter(
                    name: "CIPhotoEffectNoir",
                    parameters: [:]
                )
            }
        ])
        return filters
    }
    
    public static func defaultVideoFilters() -> [PhotoEditorFilterInfo] {
        [
            PhotoEditorFilterInfo(
                filterName: "唯美"
            ) { (image, _, _, _) in
                nashvilleFilter(image)
            } videoFilterHandler: { ciImage, _ in
                nashvilleFilter(ciImage)
            },
            PhotoEditorFilterInfo(
                filterName: "梦幻"
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
                filterName: "怀旧"
            ) { image, _, _, _ in
                image.filter(
                    name: "CIPhotoEffectInstant",
                    parameters: [:]
                )
            } videoFilterHandler: { ciImage, _ in
                ciImage.filter(name: "CIPhotoEffectInstant", parameters: [:])
            },
            PhotoEditorFilterInfo(
                filterName: "岁月"
            ) { (image, _, _, _) in
                image.filter(
                    name: "CIPhotoEffectTransfer",
                    parameters: [:]
                )
            } videoFilterHandler: { ciImage, _ in
                ciImage.filter(name: "CIPhotoEffectTransfer", parameters: [:])
            },
            PhotoEditorFilterInfo(
                filterName: "模糊",
                parameters: [.init(defaultValue: 0.2)],
                filterHandler: { image, _, _, _ in
                    return image.blurredImage(10)
            }, videoFilterHandler: {
                $0.filter(
                    name: "CIGaussianBlur",
                    parameters: [kCIInputRadiusKey: 50.0 * $1[0].value]
                )
            }),
            PhotoEditorFilterInfo(
                filterName: "褪色"
            ) { (image, _, _, _) in
                image.filter(
                    name: "CIPhotoEffectFade",
                    parameters: [:]
                )
            } videoFilterHandler: { ciImage, _ in
                ciImage.filter(name: "CIPhotoEffectFade", parameters: [:])
            },
            PhotoEditorFilterInfo(
                filterName: "冲印"
            ) { (image, _, _, _) in
                image.filter(
                    name: "CIPhotoEffectProcess",
                    parameters: [:]
                )
            } videoFilterHandler: { ciImage, _ in
                ciImage.filter(name: "CIPhotoEffectProcess", parameters: [:])
            },
            PhotoEditorFilterInfo(
                filterName: "铬黄"
            ) { (image, _, _, _) in
                image.filter(
                    name: "CIPhotoEffectChrome",
                    parameters: [:]
                )
            } videoFilterHandler: { ciImage, _ in
                ciImage.filter(name: "CIPhotoEffectChrome", parameters: [:])
            },
            PhotoEditorFilterInfo(
                filterName: "老电影",
                parameters: [.init(defaultValue: 1)],
                filterHandler: { image, _, _, _ in
                    oldMovie(image, value: 1)
            }, videoFilterHandler: {
                oldMovie($0, value: $1[0].value)
            }),
            PhotoEditorFilterInfo(
                filterName: "色调"
            ) { (image, _, _, _) in
                image.filter(
                    name: "CIPhotoEffectTonal",
                    parameters: [:]
                )
            } videoFilterHandler: { ciImage, _ in
                ciImage.filter(name: "CIPhotoEffectTonal", parameters: [:])
            },
            PhotoEditorFilterInfo(
                filterName: "单色"
            ) { (image, _, _, _) in
                image.filter(
                    name: "CIPhotoEffectMono",
                    parameters: [:]
                )
            } videoFilterHandler: { ciImage, _ in
                ciImage.filter(name: "CIPhotoEffectMono", parameters: [:])
            },
            PhotoEditorFilterInfo(
                filterName: "黑白"
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
