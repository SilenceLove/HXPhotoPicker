//
//  EditorType.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/1/14.
//

import UIKit
 
public struct EditorRatioToolConfig {
    public let title: HX.TextManager.TextType
    let titleNormalColor: String
    let titleSelectedColor: String
    let backgroundNormalColor: String
    let backgroundSelectedColor: String
    public let ratio: CGSize
    
    public init(
        title: HX.TextManager.TextType,
        titleNormalColor: String = "#a1a1a1",
        titleSelectedColor: String = "#ebebeb",
        backgroundNormalColor: String = "",
        backgroundSelectedColor: String = "#66D6D6D6",
        ratio: CGSize
    ) {
        self.title = title
        self.titleNormalColor = titleNormalColor
        self.titleSelectedColor = titleSelectedColor
        self.backgroundNormalColor = backgroundNormalColor
        self.backgroundSelectedColor = backgroundSelectedColor
        self.ratio = ratio
    }
}

extension EditedResult: Codable {
    enum CodingKeys: CodingKey {
        case imageEditedResult
        case imageEditedData
        case videoEditedResult
        case videoEditedData
        case error
    }
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let imageEditedResult = try? container.decode(ImageEditedResult.self, forKey: .imageEditedResult),
           let imageEditedData = try? container.decode(ImageEditedData.self, forKey: .imageEditedData) {
            self = .image(imageEditedResult, imageEditedData)
            return
        }
        if let videoEditedResult = try? container.decode(VideoEditedResult.self, forKey: .videoEditedResult),
           let videoEditedData = try? container.decode(VideoEditedData.self, forKey: .videoEditedData) {
            self = .video(videoEditedResult, videoEditedData)
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
        case .image(let imageEditedResult, let imageEditedData):
            try container.encode(imageEditedResult, forKey: .imageEditedResult)
            try container.encode(imageEditedData, forKey: .imageEditedData)
        case .video(let videoEditedResult, let videoEditedData):
            try container.encode(videoEditedResult, forKey: .videoEditedResult)
            try container.encode(videoEditedData, forKey: .videoEditedData)
        }
    }
}

extension VideoEditedData: Codable {
    enum CodingKeys: CodingKey {
        case music
        case cropTime
        case filterEdit
        case filter
        case cropSize
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        music = try? container.decode(VideoEditedMusic.self, forKey: .music)
        cropTime = try? container.decode(EditorVideoCropTime.self, forKey: .cropTime)
        filterEdit = try? container.decode(EditorFilterEditFator.self, forKey: .filterEdit)
        filter = try? container.decode(VideoEditorFilter.self, forKey: .filter)
        cropSize = try? container.decode(EditorCropSizeFator.self, forKey: .cropSize)
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(music, forKey: .music)
        try container.encode(cropTime, forKey: .cropTime)
        try container.encode(filterEdit, forKey: .filterEdit)
        try container.encode(filter, forKey: .filter)
        try container.encode(cropSize, forKey: .cropSize)
    }
}
