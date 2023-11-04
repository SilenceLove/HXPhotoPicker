//
//  PhotoAlbumList.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/10/9.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit

public protocol PhotoAlbumListDelegate: AnyObject {
    func albumList(
        _ albumList: PhotoAlbumList,
        didSelectAt index: Int,
        with assetCollection: PhotoAssetCollection
    )
}

public protocol PhotoAlbumList: UIView {
    
    var delegate: PhotoAlbumListDelegate? { get set }
    
    /// 相册集合
    var assetCollections: [PhotoAssetCollection] { get set }
    
    /// 选中的相册
    var selectedAssetCollection: PhotoAssetCollection? { get set }
    
    /// 相册列表的边距
    var contentInset: UIEdgeInsets { get set }
    
    /// 中心位置相册
    var middleIndex: Int { get }
    
    /// isSplit: 是否使用了 UISplitViewControoler
    init(config: PickerConfiguration, isSplit: Bool)
    
    /// 滚动到指定位置
    func scroll(to index: Int, animated: Bool)
    
    /// 将选中相册的滚动到中心位置
    func scrollSelectToMiddle()
    
    /// 刷新列表
    func reloadData()
}

public extension PhotoAlbumList {
    var middleIndex: Int { 0 }
}
