//
//  AlbumViewBaseCell.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/10/9.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit

open class AlbumViewBaseCell: UITableViewCell {
    open var assetCollection: PhotoAssetCollection!
    
    open var config: AlbumListConfiguration = .init()
    
    open func updateSelectedStatus(_ isSelected: Bool) { }
}
