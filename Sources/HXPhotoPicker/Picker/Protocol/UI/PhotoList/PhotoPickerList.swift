//
//  PhotoPickerList.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/10/11.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit

public protocol PhotoPickerListDelegate: PhotoControllerEvent {
    
    /// 点击cell时调用
    func photoList(
        _ photoList: PhotoPickerList,
        didSelectCell asset: PhotoAsset,
        at index: Int,
        animated: Bool
    )
    
    func photoList(didLimitCell photoList: PhotoPickerList)
    
    /// 数据发生改变
    func photoList(selectedAssetDidChanged photoList: PhotoPickerList)
    
    /// 打开编辑器
    func photoList(
        _ photoList: PhotoPickerList,
        openEditor asset: PhotoAsset,
        with image: UIImage?
    )
    
    /// 打开预览界面
    func photoList(
        _ photoList: PhotoPickerList,
        openPreview assets: [PhotoAsset],
        with page: Int,
        animated: Bool
    )
    
    /// 跳转到相机界面
    func photoList(presentCamera photoList: PhotoPickerList)
    
    /// 跳转到筛选界面
    func photoList(presentFilter photoList: PhotoPickerList, modalPresentationStyle: UIModalPresentationStyle)
    
    func photoList(_ photoList: PhotoPickerList, didSelectedAsset asset: PhotoAsset)
    func photoList(_ photoList: PhotoPickerList, didDeselectedAsset asset: PhotoAsset)
    func photoList(_ photoList: PhotoPickerList, updateAsset asset: PhotoAsset)
}

public extension PhotoPickerListDelegate {
    func photoList(_ photoList: PhotoPickerList, didSelectedAsset asset: PhotoAsset) { }
    func photoList(_ photoList: PhotoPickerList, didDeselectedAsset asset: PhotoAsset) { }
}

public protocol PhotoPickerList:
    UIViewController,
    PhotoPickerListDelegateProperty,
    PhotoPickerListFectchCell,
    PhotoPickerListPickerConfig,
    PhotoPickerListFetchAssets
{
    var contentInset: UIEdgeInsets { get set }
    var scrollIndicatorInsets: UIEdgeInsets { get set }
    
    init(config: PickerConfiguration)
    
    func scrollTo(at indexPath: IndexPath, at scrollPosition: UICollectionView.ScrollPosition, animated: Bool)
    func scrollTo(_ asset: PhotoAsset?)
    func scrollToCenter(for photoAsset: PhotoAsset?)
    func scrollCellToVisibleArea(_ cell: PhotoPickerBaseViewCell)
    
    func addedAsset(for asset: PhotoAsset)
    
    func reloadCell(for asset: PhotoAsset)
    func reloadData()
    
    func updateCellLoadMode(_ mode: PhotoManager.ThumbnailLoadMode, judgmentIsEqual: Bool)
    func cellReloadImage()
}

public extension PhotoPickerList {
    
    func scrollTo(at indexPath: IndexPath, at scrollPosition: UICollectionView.ScrollPosition, animated: Bool) {
        if indexPath.item < assets.count {
            collectionView.scrollToItem(at: indexPath, at: scrollPosition, animated: animated)
        }
    }
    
    func scrollTo(_ asset: PhotoAsset?) {
        if assets.isEmpty {
            return
        }
        var item: Int
        if config.sort == .asc {
            item = assets.count - 1
        }else {
            item = 0
        }
        if let asset = asset,
           let index = assets.firstIndex(of: asset) {
            item = index
        }
        if config.sort == .asc {
            if canAddCamera && canAddLimit {
                item += 2
            }else if canAddCamera || canAddLimit {
                item += 1
            }
        }
        let indexPath = IndexPath(item: item, section: 0)
        let scrollPosition: UICollectionView.ScrollPosition
        if config.sort == .asc {
            scrollPosition = .bottom
        }else {
            scrollPosition = .top
        }
        DispatchQueue.main.async {
            self.collectionView.scrollToItem(
                at: indexPath,
                at: scrollPosition,
                animated: false
            )
        }
    }
    
    func scrollToCenter(for photoAsset: PhotoAsset?) {
        if assets.isEmpty {
            return
        }
        if let photoAsset = photoAsset,
           var item = assets.firstIndex(of: photoAsset) {
            if needOffset {
                item += offsetIndex
            }
            collectionView.scrollToItem(
                at: IndexPath(item: item, section: 0),
                at: .centeredVertically,
                animated: false
            )
        }
    }
    func scrollCellToVisibleArea(_ cell: PhotoPickerBaseViewCell) {
        if assets.isEmpty {
            return
        }
        let rect = cell.photoView.convert(cell.photoView.bounds, to: view)
        if rect.minY - collectionView.contentInset.top < 0 {
            if let indexPath = collectionView.indexPath(for: cell) {
                collectionView.scrollToItem(
                    at: indexPath,
                    at: .top,
                    animated: false
                )
            }
        }else if rect.maxY > view.height - collectionView.contentInset.bottom {
            if let indexPath = collectionView.indexPath(for: cell) {
                collectionView.scrollToItem(
                    at: indexPath,
                    at: .bottom,
                    animated: false
                )
            }
        }
    }
    
    func reloadCell(for asset: PhotoAsset) {
        let cell = getCell(for: asset)
        cell?.updatePhotoAsset(asset)
    }
    
    func reloadData() {
        collectionView.reloadData()
    }
    
    func updateCellLoadMode(_ mode: PhotoManager.ThumbnailLoadMode, judgmentIsEqual: Bool = true) { }
    func cellReloadImage() { }
}

public protocol PhotoPickerListDelegateProperty {
    var delegate: PhotoPickerListDelegate? { get set }
}
