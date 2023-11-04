//
//  PhotoPickerListCollectionView.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/10/11.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit

public protocol PhotoPickerListCollectionView {
    var collectionView: UICollectionView! { get set }
}

public protocol PhotopickerListRegisterClass: PhotoPickerListCollectionView, PhotoPickerListConfig {
    func registerClass()
}

public extension PhotopickerListRegisterClass {
    func registerClass() {
        if let cellClass = config.cell.customSingleCellClass {
            collectionView.register(cellClass, forCellWithReuseIdentifier: PhotoPickerViewCell.className)
        }else {
            collectionView.register(PhotoPickerViewCell.self, forCellWithReuseIdentifier: PhotoPickerViewCell.className)
        }
        if let cellClass = config.cell.customSelectableCellClass {
            collectionView.register(cellClass, forCellWithReuseIdentifier: PhotoPickerSelectableViewCell.className)
        }else {
            collectionView.register(PhotoPickerSelectableViewCell.self, forCellWithReuseIdentifier: PhotoPickerSelectableViewCell.className)
        }
        if config.allowAddCamera {
            #if !targetEnvironment(macCatalyst)
            collectionView.register(PickerCameraViewCell.self)
            #endif
        }
        if #available(iOS 14.0, *), config.allowAddLimit {
            collectionView.register(PhotoPickerLimitCell.self)
        }
        if config.isShowAssetNumber {
            collectionView.register(
                PhotoPickerBottomNumberView.self,
                forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                withReuseIdentifier: PhotoPickerBottomNumberView.className
            )
        }
    }
}
