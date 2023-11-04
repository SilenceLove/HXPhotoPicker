//
//  PhotoAlbumController.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/10/18.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit

public protocol PhotoAlbumControllerDelegate: AnyObject {
    func albumController(_ albumController: PhotoAlbumController, didSelectedWith assetCollection: PhotoAssetCollection)
    func albumController(willAppear viewController: PhotoAlbumController)
    func albumController(didAppear viewController: PhotoAlbumController)
    func albumController(willDisappear viewController: PhotoAlbumController)
    func albumController(didDisappear viewController: PhotoAlbumController)
}

public protocol PhotoAlbumController: UIViewController {
    var delegate: PhotoAlbumControllerDelegate? { get set }
    var assetCollections: [PhotoAssetCollection] { get set }
    var selectedAssetCollection: PhotoAssetCollection? { get set }
    init(config: PickerConfiguration)
    func reloadData()
}
