//
//  PhotoControllerEvent.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/10/22.
//  Copyright © 2023 Silence. All rights reserved.
//

import Foundation

public protocol PhotoControllerEvent: AnyObject {
    func photoControllerDidFinish()
    func photoControllerDidCancel()
}

public extension PhotoControllerEvent {
    func photoControllerDidFinish() { }
    func photoControllerDidCancel() { }
}
