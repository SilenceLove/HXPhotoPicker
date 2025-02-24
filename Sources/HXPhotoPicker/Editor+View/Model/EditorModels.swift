//
//  EditorModels.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/4/29.
//

import UIKit
import AVFoundation

public class EditorStickerAudio: Codable, Equatable {
    
    /// 当前贴纸显示的文本内容
    public var text: String = "" {
        didSet {
            textDidChange?(text)
        }
    }
    
    /// 当前贴纸对应的URL
    public let url: VideoEditorMusicURL
    
    /// 标识
    public let identifier: String
    
    /// 音频贴纸导出时的配置
    /// 视频导出时会通过此闭包获取音频贴纸显示的内容
    public var contentsHandler: ((EditorStickerAudio) -> EditorStickerAudioContent?)?
    
    public init(
        _ url: VideoEditorMusicURL,
        identifier: String = "",
        handler: @escaping (EditorStickerAudio) -> EditorStickerAudioContent?
    ) {
        self.url = url
        self.identifier = identifier
        self.contentsHandler = handler
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(url, forKey: .url)
        try container.encode(identifier, forKey: .identifier)
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        url = try container.decode(VideoEditorMusicURL.self, forKey: .url)
        identifier = try container.decode(String.self, forKey: .identifier)
    }
    
    public static func == (lhs: EditorStickerAudio, rhs: EditorStickerAudio) -> Bool {
        lhs === rhs
    }
    
    var textDidChange: ((String) -> Void)?
}

public struct EditorStickerAudioContent {
    
    /// 音频总时长
    public let time: TimeInterval
    /// 音频的文本内容
    public let texts: [EditorStickerAudioText]
    
    public let contentsScale: CGFloat
    
    public init(
        time: TimeInterval,
        texts: [EditorStickerAudioText],
        contentsScale: CGFloat = 1
    ) {
        self.time = time
        self.texts = texts
        self.contentsScale = contentsScale
    }
}

public class EditorStickerAudioText {
    /// 显示的内容
    public let text: String
    /// 内容开始时间
    public let startTime: TimeInterval
    /// 内容结束时间
    public let endTime: TimeInterval
    
    public init(text: String, startTime: TimeInterval, endTime: TimeInterval) {
        self.text = text
        self.startTime = startTime
        self.endTime = endTime
    }
}

public struct EditorVideoFactor {
    /// 时间区域
    public let timeRang: CMTimeRange
    /// 原始视频音量
    public let volume: Float
    /// 需要添加的音频数据
    public let audios: [Audio]
    /// 裁剪圆切或者自定义蒙版时，被遮住的部分的处理类型
    /// 可自定义颜色，毛玻璃效果统一为 .light
    public let maskType: EditorView.MaskType?
    /// 导出视频的分辨率
    public let preset: ExportPreset
    /// 导出视频的质量 [0-10]
    public let quality: Int
    public init(
        timeRang: CMTimeRange = .zero,
        volume: Float = 1,
        audios: [Audio] = [],
        maskType: EditorView.MaskType? = nil,
        preset: ExportPreset,
        quality: Int
    ) {
        self.timeRang = timeRang
        self.volume = volume
        self.audios = audios
        self.maskType = maskType
        self.preset = preset
        self.quality = quality
    }
    
    public struct Audio {
        let url: URL
        let volume: Float
        
        public init(url: URL, volume: Float = 1) {
            self.url = url
            self.volume = volume
        }
    }
}

extension EditorVideoFactor {
    
    func isEqual(_ facotr: EditorVideoFactor) -> Bool {
        if timeRang.start.seconds != facotr.timeRang.start.seconds {
            return false
        }
        if timeRang.duration.seconds != facotr.timeRang.duration.seconds {
            return false
        }
        if volume != facotr.volume {
            return false
        }
        if audios.count != facotr.audios.count {
            return false
        }
        for (index, audio) in audios.enumerated() {
            let tmpAudio = facotr.audios[index]
            if audio.url.path != tmpAudio.url.path {
                return false
            }
            if audio.volume != tmpAudio.volume {
                return false
            }
        }
        if preset != facotr.preset {
            return false
        }
        if quality != facotr.quality {
            return false
        }
        return true
    }
}

public struct EditorStickerText {
    public let image: UIImage
    public let text: String
    public let textColor: UIColor
    public let showBackgroud: Bool
    
    public init(image: UIImage, text: String, textColor: UIColor, showBackgroud: Bool) {
        self.image = image
        self.text = text
        self.textColor = textColor
        self.showBackgroud = showBackgroud
    }
}

public enum VideoEditorMusicURL: Equatable {
    case document(fileName: String)
    case caches(fileName: String)
    case temp(fileName: String)
    case bundle(resource: String, type: String?)
    case network(url: URL)
    
    public var url: URL? {
        switch self {
        case .document(let fileName):
            let filePath = FileManager.documentPath + "/" + fileName
            return .init(fileURLWithPath: filePath)
        case .caches(fileName: let fileName):
            let filePath = FileManager.cachesPath + "/" + fileName
            return .init(fileURLWithPath: filePath)
        case .temp(fileName: let fileName):
            let filePath = FileManager.tempPath + fileName
            return .init(fileURLWithPath: filePath)
        case .bundle(resource: let resource, type: let type):
            if let path = Bundle.main.path(forResource: resource, ofType: type) {
                return .init(fileURLWithPath: path)
            }
            return nil
        case .network(url: let url):
            return url
        }
    }
    
    public static func == (
        lhs: VideoEditorMusicURL,
        rhs: VideoEditorMusicURL
    ) -> Bool {
        switch lhs {
        case .document(let fileName):
            switch rhs {
            case .document(let _fileName):
                return fileName == _fileName
            default:
                return false
            }
        case .caches(let fileName):
            switch rhs {
            case .caches(let _fileName):
                return fileName == _fileName
            default:
                return false
            }
        case .temp(let fileName):
            switch rhs {
            case .temp(let _fileName):
                return fileName == _fileName
            default:
                return false
            }
        case .bundle(let resource, let type):
            switch rhs {
            case .bundle(let _resource, let _type):
                return resource == _resource && type == _type
            default:
                return false
            }
        case .network(let url):
            switch rhs {
            case .network(let _url):
                return url.absoluteString == _url.absoluteString
            default:
                return false
            }
        }
    }
}

extension VideoEditorMusicURL: Codable {
    enum CodingKeys: CodingKey {
        case document
        case caches
        case temp
        case bundleResource
        case bundleType
        case network
        case error
    }
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let fileName = try? container.decode(String.self, forKey: .document) {
            self = .document(fileName: fileName)
            return
        }
        if let fileName = try? container.decode(String.self, forKey: .caches) {
            self = .caches(fileName: fileName)
            return
        }
        if let fileName = try? container.decode(String.self, forKey: .temp) {
            self = .temp(fileName: fileName)
            return
        }
        if let resource = try? container.decode(String.self, forKey: .bundleResource) {
            let type = try? container.decode(String.self, forKey: .bundleType)
            self = .bundle(resource: resource, type: type)
            return
        }
        if let url = try? container.decode(URL.self, forKey: .network) {
            self = .network(url: url)
            return
        }
        throw DecodingError.dataCorruptedError(
            forKey: CodingKeys.error,
            in: container,
            debugDescription: "Invalid type"
        )
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .document(let fileName):
            try container.encode(fileName, forKey: .document)
        case .caches(let fileName):
            try container.encode(fileName, forKey: .caches)
        case .temp(let fileName):
            try container.encode(fileName, forKey: .temp)
        case .bundle(let resource, let type):
            try container.encode(resource, forKey: .bundleResource)
            if let type = type {
                try container.encode(type, forKey: .bundleType)
            }
        case .network(let url):
            try container.encode(url, forKey: .network)
        }
    }
}

struct EditorStickerItem: Codable {
    
    var type: EditorStickerItemType
    
    var text: EditorStickerText? { type.text }
    
    var image: UIImage? { type.image }
    
    var imageData: Data? { type.imageData }
    
    var isText: Bool { type.isText }
    
    var audio: EditorStickerAudio? { type.audio }
    
    var isAudio: Bool { type.isAudio }
     
    var frame: CGRect = .zero
    
    init(
        _ type: EditorStickerItemType
    ) {
        self.type = type
    }
}

public enum EditorStickerItemType {
    case image(UIImage)
    case imageData(Data)
    case text(EditorStickerText)
    case audio(EditorStickerAudio)
    
    var image: UIImage? {
        switch self {
        case .image(let image):
            return image
        case .imageData(let data):
            return .init(data: data)
        case .text(let text):
            return text.image
        default:
            return nil
        }
    }
    
    var imageData: Data? {
        switch self {
        case .imageData(let data):
            return data
        default:
            return nil
        }
    }
    
    var text: EditorStickerText? {
        switch self {
        case .text(let text):
            return text
        default:
            return nil
        }
    }
    
    var isText: Bool {
        switch self {
        case .text:
            return true
        default:
            return false
        }
    }
    
    var audio: EditorStickerAudio? {
        switch self {
        case .audio(let audio):
            return audio
        default:
            return nil
        }
    }
    
    var isAudio: Bool {
        switch self {
        case .audio:
            return true
        default:
            return false
        }
    }
}

extension EditorStickerItem {
    
    func itemFrame(_ maxWidth: CGFloat) -> CGRect {
        var width = maxWidth - 60
        if type.isAudio {
            let height: CGFloat = 60
            return CGRect(origin: .zero, size: CGSize(width: width, height: height))
            
        }
        if type.isText {
            width = maxWidth - 30
        }
        let imageSize = type.image?.size ?? .init(width: 1, height: 1)
        let height = width
        var itemWidth: CGFloat = 0
        var itemHeight: CGFloat = 0
        let imageWidth = imageSize.width
        var imageHeight = imageSize.height
        if imageWidth > width {
            imageHeight = width / imageWidth * imageHeight
        }
        if imageHeight > height {
            itemWidth = height / imageSize.height * imageWidth
            itemHeight = height
        }else {
            if imageWidth > width {
                itemWidth = width
            }else {
                itemWidth = imageWidth
            }
            itemHeight = imageHeight
        }
        return CGRect(x: 0, y: 0, width: itemWidth, height: itemHeight)
    }
}

extension EditorStickerText: Codable {
    enum CodingKeys: CodingKey {
        case image
        case text
        case textColor
        case showBackgroud
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let imageData = try container.decode(Data.self, forKey: .image)
        if #available(iOS 11.0, *) {
            image = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIImage.self, from: imageData)!
        }else {
            image = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(imageData) as! UIImage
        }
        text = try container.decode(String.self, forKey: .text)
        let colorData = try container.decode(Data.self, forKey: .textColor)
        if #available(iOS 11.0, *) {
            textColor = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData)!
        }else {
            textColor = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as! UIColor
        }
        showBackgroud = try container.decode(Bool.self, forKey: .showBackgroud)
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if #available(iOS 11.0, *) {
            let imageData = try NSKeyedArchiver.archivedData(withRootObject: image, requiringSecureCoding: false)
            try container.encode(imageData, forKey: .image)
            let colorData = try NSKeyedArchiver.archivedData(withRootObject: textColor, requiringSecureCoding: false)
            try container.encode(colorData, forKey: .textColor)
        } else {
            let imageData = NSKeyedArchiver.archivedData(withRootObject: image)
            try container.encode(imageData, forKey: .image)
            let colorData = NSKeyedArchiver.archivedData(withRootObject: textColor)
            try container.encode(colorData, forKey: .textColor)
        }
        try container.encode(text, forKey: .text)
        try container.encode(showBackgroud, forKey: .showBackgroud)
    }
}

extension EditorStickerItemType: Codable {
    enum CodingKeys: CodingKey {
        case image
        case imageData
        case text
        case audio
        case error
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .image(let image):
            if #available(iOS 11.0, *) {
                let imageData = try NSKeyedArchiver.archivedData(withRootObject: image, requiringSecureCoding: false)
                try container.encode(imageData, forKey: .image)
            } else {
                let imageData = NSKeyedArchiver.archivedData(withRootObject: image)
                try container.encode(imageData, forKey: .image)
            }
        case .imageData(let imageData):
            try container.encode(imageData, forKey: .imageData)
        case .text(let text):
            try container.encode(text, forKey: .text)
        case .audio(let audio):
            try container.encode(audio, forKey: .audio)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let imageData = try? container.decode(Data.self, forKey: .image) {
            let image: UIImage?
            if #available(iOS 11.0, *) {
                image = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIImage.self, from: imageData)
            }else {
                image = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(imageData) as? UIImage
            }
            if let image = image {
                self = .image(image)
                return
            }
        }
        if let data = try? container.decode(Data.self, forKey: .imageData) {
            self = .imageData(data)
            return
        }
        if let text = try? container.decode(EditorStickerText.self, forKey: .text) {
            self = .text(text)
            return
        }
        if let audio = try? container.decode(EditorStickerAudio.self, forKey: .audio) {
            self = .audio(audio)
            return
        }
        throw DecodingError.dataCorruptedError(
            forKey: CodingKeys.error,
            in: container,
            debugDescription: "Invalid type"
        )
    }
}

extension EditorStickerAudio {
    enum CodingKeys: CodingKey {
        case url
        case identifier
    }
}

public struct EditAdjustmentData: CustomStringConvertible {
    let content: Content
    let maskImage: UIImage?
    let drawView: [EditorDrawView.BrushInfo]
    let canvasData: EditorCanvasData?
    let mosaicView: [EditorMosaicView.MosaicData]
    let stickersView: EditorStickersView.Item?
    
    public var audioInfos: [EditorStickerAudio] {
        guard let items = stickersView?.items else {
            return []
        }
        var audios: [EditorStickerAudio] = []
        for item in items where item.item.isAudio {
            if let audio = item.item.audio {
                audios.append(audio)
            }
        }
        return audios
    }
    
    public var description: String {
        "data of adjustment."
    }
}

extension ImageEditedResult: Codable {
    enum CodingKeys: CodingKey {
        case image
        case urlConfig
        case imageType
        case data
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let imageData = try container.decode(Data.self, forKey: .image)
        if #available(iOS 11.0, *) {
            image = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIImage.self, from: imageData)!
        }else {
            image = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(imageData) as! UIImage
        }
        urlConfig = try container.decode(EditorURLConfig.self, forKey: .urlConfig)
        imageType = try container.decode(ImageType.self, forKey: .imageType)
        data = try container.decode(EditAdjustmentData.self, forKey: .data)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if #available(iOS 11.0, *) {
            let imageData = try NSKeyedArchiver.archivedData(withRootObject: image, requiringSecureCoding: false)
            try container.encode(imageData, forKey: .image)
        } else {
            let imageData = NSKeyedArchiver.archivedData(withRootObject: image)
            try container.encode(imageData, forKey: .image)
        }
        try container.encode(urlConfig, forKey: .urlConfig)
        try container.encode(imageType, forKey: .imageType)
        try container.encode(data, forKey: .data)
    }
}

extension VideoEditedResult: Codable {
    enum CodingKeys: CodingKey {
        case urlConfig
        case coverImage
        case fileSize
        case videoTime
        case videoDuration
        case data
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let imageData = try container.decode(Data.self, forKey: .coverImage)
        if #available(iOS 11.0, *) {
            coverImage = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIImage.self, from: imageData)
        }else {
            coverImage = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(imageData) as? UIImage
        }
        urlConfig = try container.decode(EditorURLConfig.self, forKey: .urlConfig)
        fileSize = try container.decode(Int.self, forKey: .fileSize)
        videoTime = try container.decode(String.self, forKey: .videoTime)
        videoDuration = try container.decode(TimeInterval.self, forKey: .videoDuration)
        data = try container.decode(EditAdjustmentData.self, forKey: .data)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let image = coverImage {
            if #available(iOS 11.0, *) {
                let imageData = try NSKeyedArchiver.archivedData(withRootObject: image, requiringSecureCoding: false)
                try container.encode(imageData, forKey: .coverImage)
            } else {
                let imageData = NSKeyedArchiver.archivedData(withRootObject: image)
                try container.encode(imageData, forKey: .coverImage)
            }
        }
        try container.encode(urlConfig, forKey: .urlConfig)
        try container.encode(fileSize, forKey: .fileSize)
        try container.encode(videoTime, forKey: .videoTime)
        try container.encode(videoDuration, forKey: .videoDuration)
        try container.encode(data, forKey: .data)
    }
}

extension EditAdjustmentData {
    struct Content: Codable {
        let editSize: CGSize
        let contentOffset: CGPoint
        let contentSize: CGSize
        let contentInset: UIEdgeInsets
        let mirrorViewTransform: CGAffineTransform
        let rotateViewTransform: CGAffineTransform
        let scrollViewTransform: CGAffineTransform
        let scrollViewZoomScale: CGFloat
        let controlScale: CGFloat
        let adjustedFactor: Adjusted?
        
        struct Adjusted: Codable {
            let angle: CGFloat
            let zoomScale: CGFloat
            let contentOffset: CGPoint
            let contentInset: UIEdgeInsets
            let maskRect: CGRect
            let transform: CGAffineTransform
            let rotateTransform: CGAffineTransform
            let mirrorTransform: CGAffineTransform
            
            let contentOffsetScale: CGPoint
            let min_zoom_scale: CGFloat
            let isRoundMask: Bool
            
            let ratioFactor: EditorControlView.Factor?
        }
    }
}

extension EditAdjustmentData: Codable {
    enum CodingKeys: CodingKey {
        case content
        case maskImage
        case canvasData
        case drawView
        case mosaicView
        case stickersView
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        content = try container.decode(Content.self, forKey: .content)
        let imageData = try? container.decode(Data.self, forKey: .maskImage)
        if let imageData = imageData {
            if #available(iOS 11.0, *) {
                maskImage = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIImage.self, from: imageData)
            }else {
                maskImage = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(imageData) as? UIImage
            }
        }else {
            maskImage = nil
        }
        canvasData = try container.decode(EditorCanvasData.self, forKey: .canvasData)
        drawView = try container.decode([EditorDrawView.BrushInfo].self, forKey: .drawView)
        mosaicView = try container.decode([EditorMosaicView.MosaicData].self, forKey: .mosaicView)
        stickersView = try? container.decode(EditorStickersView.Item.self, forKey: .stickersView)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(content, forKey: .content)
        if let image = maskImage {
            if #available(iOS 11.0, *) {
                let imageData = try NSKeyedArchiver.archivedData(withRootObject: image, requiringSecureCoding: false)
                try container.encode(imageData, forKey: .maskImage)
            } else {
                let imageData = NSKeyedArchiver.archivedData(withRootObject: image)
                try container.encode(imageData, forKey: .maskImage)
            }
        }
        try container.encode(canvasData, forKey: .canvasData)
        try container.encode(drawView, forKey: .drawView)
        try container.encode(mosaicView, forKey: .mosaicView)
        try? container.encode(stickersView, forKey: .stickersView)
    }
}

public struct EditorVideoFilterInfo {
    
    /// 视频滤镜
    public let filterHandler: ((CIImage, CGFloat) -> CIImage?)?
    
    /// 滤镜参数
    public let parameterValue: CGFloat
    
    public init(
        parameterValue: CGFloat = 1,
        filterHandler: @escaping (CIImage, CGFloat) -> CIImage?
    ) {
        self.parameterValue = parameterValue
        self.filterHandler = filterHandler
    }
}
