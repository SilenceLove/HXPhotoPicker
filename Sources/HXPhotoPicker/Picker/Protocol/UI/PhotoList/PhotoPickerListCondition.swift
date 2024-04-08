//
//  PhotoPickerListCondition.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/10/11.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit

public protocol PhotoPickerListCondition: PhotoPickerListConfig, PhotoPickerListPickerConfig, PhotoPickerListAssets {
    var didFetchAsset: Bool { get set }
    
    var canAddCamera: Bool { get }
    var canAddLimit: Bool { get }
    var needOffset: Bool { get }
    var offsetIndex: Int { get }
    
    var numberOfItems: Int { get }
}

public extension PhotoPickerListCondition {
    
    var canAddCamera: Bool {
        #if targetEnvironment(macCatalyst)
        return false
        #else
        if #available(iOS 14.0, *), ProcessInfo.processInfo.isiOSAppOnMac {
            return false
        }
        if didFetchAsset && config.allowAddCamera {
            return true
        }
        return false
        #endif
    }
    
    var canAddLimit: Bool {
        #if targetEnvironment(macCatalyst)
        return false
        #else
        if didFetchAsset,
           config.allowAddLimit,
           AssetPermissionsUtil.isLimitedAuthorizationStatus {
            return true
        }
        return false
        #endif
    }
    var needOffset: Bool {
        if config.sort == .desc {
            if canAddCamera || canAddLimit {
                return true
            }
        }
        return false
    }
    var offsetIndex: Int {
        if !needOffset {
            return 0
        }
        if canAddCamera && canAddLimit {
            return 2
        }else if canAddCamera {
            return 1
        }else {
            return 1
        }
    }
    var numberOfItems: Int {
        if canAddCamera && canAddLimit {
            return assets.count + 2
        }else if canAddCamera || canAddLimit {
            return assets.count + 1
        }else {
            return assets.count
        }
    }
}
