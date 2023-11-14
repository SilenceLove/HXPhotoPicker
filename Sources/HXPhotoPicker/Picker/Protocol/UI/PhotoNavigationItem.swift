//
//  PhotoPickerNavigationItem.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/10/16.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit

public enum PhotoNavigationItemType {
    case cancel
//    case select
    case filter
    case finish
}

public protocol PhotoNavigationItemDelegate: PhotoControllerEvent {
    func photoItem(_ photoItem: PhotoNavigationItem, didSelected isSelected: Bool)
    func photoItem(presentFilterAssets photoItem: PhotoNavigationItem, modalPresentationStyle: UIModalPresentationStyle)
}

public extension PhotoNavigationItemDelegate {
    func photoItem(_ photoItem: PhotoNavigationItem, didSelected isSelected: Bool) { }
    func photoItem(presentFilterAssets photoItem: PhotoNavigationItem, modalPresentationStyle: UIModalPresentationStyle) { }
}

public protocol PhotoNavigationItem: UIView, PhotoPickerDataStatus {
    
    var itemDelegate: PhotoNavigationItemDelegate? { get set}
    
    var isSelected: Bool { get set }
    
    var itemType: PhotoNavigationItemType { get }
    
    init(config: PickerConfiguration)
    
}

public extension PhotoNavigationItem {
    var isSelected: Bool { get { false } set { } }
    func selectedAssetDidChanged(_ photoAssets: [PhotoAsset]) { }
}
