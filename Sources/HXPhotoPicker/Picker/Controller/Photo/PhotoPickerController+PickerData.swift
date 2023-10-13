//
//  PhotoPickerController+PickerData.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/8/25.
//

import UIKit
import Photos

extension PhotoPickerController: PhotoPickerDataDelegate {
    public func pickerData(_ pickerData: PhotoPickerData, shouldSelectedAsset photoAsset: PhotoAsset, at index: Int) -> Bool {
        pickerDelegate?.pickerController(self, shouldSelectedAsset: photoAsset, atIndex: index) ?? true
    }
    
    public func pickerData(_ pickerData: PhotoPickerData, willSelectAsset photoAsset: PhotoAsset, at index: Int) {
        pickerDelegate?.pickerController(self, willSelectAsset: photoAsset, atIndex: index)
    }
    
    public func pickerData(_ pickerData: PhotoPickerData, didSelectAsset photoAsset: PhotoAsset, at index: Int) {
        pickerDelegate?.pickerController(self, didSelectAsset: photoAsset, atIndex: index)
    }
    
    public func pickerData(_ pickerData: PhotoPickerData, willUnselectAsset photoAsset: PhotoAsset, at index: Int) {
        pickerDelegate?.pickerController(self, willUnselectAsset: photoAsset, atIndex: index)
    }
    
    public func pickerData(_ pickerData: PhotoPickerData, didUnselectAsset photoAsset: PhotoAsset, at index: Int) {
        pickerDelegate?.pickerController(self, didUnselectAsset: photoAsset, atIndex: index)
    }
}

extension PhotoPickerController: PhotoFetchDataDelegate {
    public func fetchData(_ fetchData: PhotoFetchData, didFetchAssetCollections collection: PHAssetCollection) -> Bool {
        pickerDelegate?.pickerController(self, didFetchAssetCollections: collection) ?? true
    }
    
    public func fetchData(_ fetchData: PhotoFetchData, didFetchAssets asset: PHAsset) -> Bool {
        pickerDelegate?.pickerController(self, didFetchAssets: asset) ?? true
    }
}
