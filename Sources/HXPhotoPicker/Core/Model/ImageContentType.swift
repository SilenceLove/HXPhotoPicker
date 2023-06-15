//
//  ImageContentType.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/5/21.
//

import UIKit

public enum ImageContentType: String {
    case jpg, png, gif, unknown
    public var fileExtension: String {
        return self.rawValue
    }
}

enum FileType: String {
    case unknown
    case image
    case auido
    case video
}
