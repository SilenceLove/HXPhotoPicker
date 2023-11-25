//
//  PhotoPickerListFectchCell.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/10/11.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit

public protocol PhotoPickerListFectchCell: 
    PhotoPickerListCollectionView,
    PhotoPickerListConfig,
    PhotoPickerListAssets,
    PhotoPickerListCondition,
    PhotoPickerControllerFectch
{
    
    var limitAddCell: PhotoPickerLimitCell { get }
    #if !targetEnvironment(macCatalyst)
    var cameraCell: PickerCameraViewCell { get }
    #endif
    func dequeueReusableAdditiveCell(_ indexPath: IndexPath) -> UICollectionViewCell?
    func dequeueReusableCell(for indexPath: IndexPath, with asset: PhotoAsset) -> PhotoPickerBaseViewCell
    func getCell(for item: Int) -> PhotoPickerBaseViewCell?
    func getCell(for asset: PhotoAsset) -> PhotoPickerBaseViewCell?
    func getIndexPath(for asset: PhotoAsset) -> IndexPath?
    func updateCellSelectedTitle()
    func updateCell(for asset: PhotoAsset)
    func resetICloud(for asset: PhotoAsset)
    func selectCell(for asset: PhotoAsset, isSelected: Bool)
}

public extension PhotoPickerListFectchCell {
    
    var limitAddCell: PhotoPickerLimitCell {
        let indexPath: IndexPath
        if config.sort == .asc {
            if canAddCamera {
                indexPath = IndexPath(item: assets.count - 1, section: 0)
            }else {
                indexPath = IndexPath(item: assets.count, section: 0)
            }
        }else {
            if canAddCamera {
                indexPath = IndexPath(item: 1, section: 0)
            }else {
                indexPath = IndexPath(item: 0, section: 0)
            }
        }
        let cell: PhotoPickerLimitCell = collectionView.dequeueReusableCell(for: indexPath)
        cell.config = config.limitCell
        return cell
    }
    
    #if !targetEnvironment(macCatalyst)
    var cameraCell: PickerCameraViewCell {
        let indexPath: IndexPath
        if config.sort == .asc {
            indexPath = IndexPath(item: assets.count, section: 0)
        }else {
            indexPath = IndexPath(item: 0, section: 0)
        }
        let cell: PickerCameraViewCell = collectionView.dequeueReusableCell(for: indexPath)
        cell.config = config.cameraCell
        return cell
    }
    #endif
    
    func dequeueReusableCell(for indexPath: IndexPath, with asset: PhotoAsset) -> PhotoPickerBaseViewCell {
        let cell: PhotoPickerBaseViewCell
        let isPickerCell: Bool
        if pickerConfig.selectMode == .single {
            isPickerCell = true
        }else if asset.mediaType == .video && pickerConfig.isSingleVideo {
            isPickerCell = true
        }else {
            isPickerCell = false
        }
        if isPickerCell {
            cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: PhotoPickerViewCell.className,
                for: indexPath
            ) as! PhotoPickerBaseViewCell
        }else {
            cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: PhotoPickerSelectableViewCell.className,
                for: indexPath
            ) as! PhotoPickerBaseViewCell
        }
        return cell
    }
    
    func dequeueReusableAdditiveCell(_ indexPath: IndexPath) -> UICollectionViewCell? {
        if canAddCamera && canAddLimit {
            if config.sort == .asc {
                if indexPath.item == assets.count + 1 {
                    #if !targetEnvironment(macCatalyst)
                    return cameraCell
                    #endif
                }
                if indexPath.item == assets.count {
                    return limitAddCell
                }
            }else {
                if indexPath.item == 0 {
                    #if !targetEnvironment(macCatalyst)
                    return cameraCell
                    #endif
                }
                if indexPath.item == 1 {
                    return limitAddCell
                }
            }
        }else if canAddCamera || canAddLimit {
            if config.sort == .asc {
                if indexPath.item == assets.count {
                    if canAddCamera {
                        #if !targetEnvironment(macCatalyst)
                        return cameraCell
                        #endif
                    }
                    return limitAddCell
                }
            }else {
                if indexPath.item == 0 {
                    if canAddCamera {
                        #if !targetEnvironment(macCatalyst)
                        return cameraCell
                        #endif
                    }
                    return limitAddCell
                }
            }
        }
        return nil
    }
    
    func getCell(for item: Int) -> PhotoPickerBaseViewCell? {
        if assets.isEmpty {
            return nil
        }
        let cell = collectionView.cellForItem(
            at: IndexPath(item: item, section: 0)
        ) as? PhotoPickerBaseViewCell
        return cell
    }
    func getCell(for asset: PhotoAsset) -> PhotoPickerBaseViewCell? {
        guard let item = getIndexPath(for: asset)?.item else {
            return nil
        }
        return getCell(for: item)
    }
    func getIndexPath(for asset: PhotoAsset) -> IndexPath? {
        if assets.isEmpty { return nil }
        guard var item = assets.firstIndex(of: asset) else {
            return nil
        }
        if needOffset {
            item += offsetIndex
        }
        return IndexPath(item: item, section: 0)
    }
    
    func updateCellSelectedTitle() {
        for case let cell as PhotoPickerBaseViewCell in collectionView.visibleCells {
            guard let photoAsset = cell.photoAsset else { continue }
            if !photoAsset.isSelected &&
                config.cell.isShowDisableMask &&
                pickerConfig.maximumSelectedVideoFileSize == 0  &&
                pickerConfig.maximumSelectedPhotoFileSize == 0 {
                cell.canSelect = pickerController.pickerData.canSelect(
                    photoAsset,
                    isShowHUD: false
                )
            }
            cell.updateSelectedState(
                isSelected: photoAsset.isSelected,
                animated: false
            )
        }
    }
    
    func updateCell(for asset: PhotoAsset) {
        let cell = getCell(for: asset)
        cell?.updatePhotoAsset(asset)
    }
    
    func resetICloud(for asset: PhotoAsset) {
        guard let cell = getCell(for: asset),
              cell.inICloud else {
            return
        }
        cell.requestICloudState()
    }
}
