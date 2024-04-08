//
//  PhotoError.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/1/7.
//

import Foundation

public enum PhotoError: LocalizedError {
    
    public enum `Type` {
        case imageEmpty
        case videoEmpty
        case exportFailed
    }
    case error(type: Type, message: String)
}

extension PhotoError {
    public var errorDescription: String? {
        switch self {
        case let .error(_, message):
            return message
        }
    }
}
