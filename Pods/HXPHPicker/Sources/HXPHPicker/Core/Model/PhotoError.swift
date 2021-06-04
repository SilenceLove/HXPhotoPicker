//
//  PhotoError.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/7.
//

import Foundation

public enum PhotoError: LocalizedError {
    case error(message: String)
}

public extension PhotoError {
     var errorDescription: String? {
        switch self {
            case let .error(message):
                return message
        }
    }
}
