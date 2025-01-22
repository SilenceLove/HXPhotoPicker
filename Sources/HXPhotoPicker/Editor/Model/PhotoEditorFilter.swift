//
//  PhotoEditorFilter.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/6/23.
//

import UIKit
import MetalKit
import Metal

/// 需要添加滤镜的原始图片、上一次添加滤镜的图片，滤镜参数，是否是滤镜列表封面
public typealias PhotoEditorFilterHandler = (CIImage, UIImage?, [PhotoEditorFilterParameterInfo], Bool) -> CIImage?

/// 原始画面，滤镜参数
public typealias VideoEditorFilterHandler = (CIImage, [PhotoEditorFilterParameterInfo]) -> CIImage?

public struct PhotoEditorFilterInfo {
    
    /// 滤镜名称
    public let filterName: HX.TextManager.TextType
    
    /// 滤镜处理器，内部会传入未添加滤镜的图片，返回添加滤镜之后的图片
    /// 如果为视频编辑器时，处理的是底部滤镜预览的数据
    public let filterHandler: PhotoEditorFilterHandler?
    
    /// 视频滤镜
    public let videoFilterHandler: VideoEditorFilterHandler?
    
    /// 滤镜参数
    public let parameters: [PhotoEditorFilterParameter]
    
    public init(
        filterName: HX.TextManager.TextType,
        parameters: [PhotoEditorFilterParameter] = [],
        filterHandler: @escaping PhotoEditorFilterHandler,
        videoFilterHandler: VideoEditorFilterHandler? = nil
    ) {
        self.filterName = filterName
        self.filterHandler = filterHandler
        self.videoFilterHandler = videoFilterHandler
        self.parameters = parameters
    }
}

public struct PhotoEditorFilterParameter: Codable {
    
    public let id: String?
    
    public let title: String?
    
    public let defaultValue: Float
    
    public init(
        id: String? = nil,
        title: String? = nil,
        defaultValue: Float
    ) {
        self.id = id
        self.title = title
        self.defaultValue = defaultValue
    }
}

public class PhotoEditorFilter: Equatable, Codable {
    
    /// 滤镜名称
    public let filterName: HX.TextManager.TextType
    /// 滤镜列表的下标
    public var sourceIndex: Int = 0
    /// 标识符
    public let identifier: String
    /// 滤镜参数
    public let parameters: [PhotoEditorFilterParameterInfo]
    
    public init(
        filterName: HX.TextManager.TextType,
        identifier: String = "hx_editor_default",
        parameters: [PhotoEditorFilterParameterInfo] = []
    ) {
        self.filterName = filterName
        self.identifier = identifier
        self.parameters = parameters
    }
    
    var isOriginal: Bool = false
    var isSelected: Bool = false
    
    public static func == (
        lhs: PhotoEditorFilter,
        rhs: PhotoEditorFilter
    ) -> Bool {
        lhs === rhs
    }
}

public class PhotoEditorFilterParameterInfo: Equatable, Codable {
    
    /// 当前slider的value
    public var value: Float
    
    /// 对应的参数类型
    public let parameter: PhotoEditorFilterParameter
    
    let sliderType: ParameterSliderView.`Type`
    var isNormal: Bool
    
    init(
        parameter: PhotoEditorFilterParameter,
        sliderType: ParameterSliderView.`Type` = .normal
    ) {
        self.parameter = parameter
        self.value = parameter.defaultValue
        isNormal = self.value == 0
        self.sliderType = sliderType
    }
    
    public static func == (lhs: PhotoEditorFilterParameterInfo, rhs: PhotoEditorFilterParameterInfo) -> Bool {
        lhs === rhs
    }
}

public struct VideoEditorFilter: Codable {
    /// 滤镜列表的下标
    public let index: Int
    /// 标识符
    public let identifier: String
    /// 滤镜参数
    public let parameters: [PhotoEditorFilterParameterInfo]
    init(index: Int, identifier: String = "hx_editor_default", parameters: [PhotoEditorFilterParameterInfo]) {
        self.index = index
        self.identifier = identifier
        self.parameters = parameters
    }
}

public struct EditorFilterEditFator: Codable {
    /// 亮度
    public var brightness: Float
    /// 对比度
    public var contrast: Float
    /// 曝光度
    public var exposure: Float
    /// 饱和度
    public var saturation: Float
    /// 高光
    public var highlights: Float
    /// 阴影
    public var shadows: Float
    /// 色温
    public var warmth: Float
    /// 暗角
    public var sharpen: Float
    /// 锐化
    public var vignette: Float
    
    var isApply: Bool {
        brightness != 0 ||
        contrast != 1 ||
        exposure != 0 ||
        saturation != 1 ||
        highlights != 0 ||
        shadows != 0 ||
        warmth != 0 ||
        sharpen != 0 ||
        vignette != 0
    }
    
    public init(
        brightness: Float = 0,
        contrast: Float = 1,
        exposure: Float = 0,
        saturation: Float = 1,
        highlights: Float = 0,
        shadows: Float = 0,
        warmth: Float = 0,
        sharpen: Float = 0,
        vignette: Float = 0
    ) {
        self.brightness = brightness
        self.contrast = contrast
        self.exposure = exposure
        self.saturation = saturation
        self.highlights = highlights
        self.shadows = shadows
        self.warmth = warmth
        self.sharpen = sharpen
        self.vignette = vignette
    }
}

public struct EditorCropSizeFator: Codable {
    /// 是否固定比例
    public let isFixedRatio: Bool
    /// 裁剪框比例
    public let aspectRatio: CGSize
    /// 角度刻度值
    public let angle: CGFloat
    
    public init(isFixedRatio: Bool, aspectRatio: CGSize, angle: CGFloat) {
        self.isFixedRatio = isFixedRatio
        self.aspectRatio = aspectRatio
        self.angle = angle
    }
}
