//
//  PhotoPickerListSwipeSelect.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/10/11.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit

public enum PhotoPickerListSwipeSelectState {
    case select
    case unselect
}

public protocol PhotoPickerListSwipeSelect:
    UIViewController,
    PhotoPickerListDelegateProperty,
    PhotoPickerListCollectionView,
    PhotoPickerControllerFectch,
    PhotoPickerListFectchCell,
    PhotoPickerListFetchAssets
{
    var swipeSelectBeganIndexPath: IndexPath? { get set }
    var swipeSelectedIndexArray: [Int]?  { get set }
    var swipeSelectState: PhotoPickerListSwipeSelectState?  { get set }
    var swipeSelectAutoScrollTimer: DispatchSourceTimer?  { get set }
    var swipeSelectPanGR: UIPanGestureRecognizer?  { get set }
    var swipeSelectLastLocalPoint: CGPoint?  { get set }
    
    func beganPanGestureRecognizer(panGR: UIPanGestureRecognizer, localPoint: CGPoint)
    func changedPanGestureRecognizer(panGR: UIPanGestureRecognizer, localPoint: CGPoint)
    func endedPanGestureRecognizer()
    
    func recallSwipeSelectAction()
}

public extension PhotoPickerListSwipeSelect {
    
    func beganPanGestureRecognizer(
        panGR: UIPanGestureRecognizer,
        localPoint: CGPoint
    ) {
        if let indexPath = collectionView.indexPathForItem(at: localPoint),
           let photoAsset = getCell(for: indexPath.item)?.photoAsset {
            if photoAsset.mediaType == .video &&
                pickerController.pickerData.videoDurationExceedsTheLimit(photoAsset) {
                return
            }
            if !pickerController.pickerData.canSelect(photoAsset, isShowHUD: false) && !photoAsset.isSelected {
                return
            }
            swipeSelectedIndexArray = []
            swipeSelectBeganIndexPath = collectionView.indexPathForItem(at: localPoint)
            swipeSelectState = photoAsset.isSelected ? .unselect : .select
            updateCellSelectedState(for: indexPath.item, isSelected: swipeSelectState == .select)
            swipeSelectedIndexArray?.append(indexPath.item)
            swipeSelectAutoScroll()
        }
    }
    
    // swiftlint:disable function_body_length
    func changedPanGestureRecognizer(
        panGR: UIPanGestureRecognizer,
        localPoint: CGPoint
    ) {
        // swiftlint:enable function_body_length
        let lastIndexPath = collectionView.indexPathForItem(at: localPoint)
        if let lastIndex = lastIndexPath?.item,
           let lastIndexPath = lastIndexPath {
            if let beganIndex = swipeSelectBeganIndexPath?.item,
               let swipeSelectState = swipeSelectState,
               var indexArray = swipeSelectedIndexArray {
                if swipeSelectState == .select {
                    if let lastPhotoAsset = pickerController.selectedAssetArray.last,
                       let cellIndexPath = getIndexPath(for: lastPhotoAsset) {
                        if lastIndex < beganIndex && cellIndexPath.item < lastIndex {
                            for index in cellIndexPath.item...lastIndex where indexArray.contains(index) {
                                updateCellSelectedState(for: index, isSelected: !(swipeSelectState == .select))
                                let firstIndex = swipeSelectedIndexArray!.firstIndex(of: index)!
                                swipeSelectedIndexArray?.remove(at: firstIndex)
                            }
                        }else if lastIndex > beganIndex && cellIndexPath.item > lastIndex {
                            for index in lastIndex...cellIndexPath.item where indexArray.contains(index) {
                                updateCellSelectedState(for: index, isSelected: !(swipeSelectState == .select))
                                let firstIndex = swipeSelectedIndexArray!.firstIndex(of: index)!
                                swipeSelectedIndexArray?.remove(at: firstIndex)
                            }
                        }else {
                            for index in indexArray {
                                if lastIndex <= beganIndex && index > beganIndex {
                                    updateCellSelectedState(for: index, isSelected: !(swipeSelectState == .select))
                                    let firstIndex = swipeSelectedIndexArray!.firstIndex(of: index)!
                                    swipeSelectedIndexArray?.remove(at: firstIndex)
                                }else if lastIndex >= beganIndex && index < beganIndex {
                                    updateCellSelectedState(for: index, isSelected: !(swipeSelectState == .select))
                                    let firstIndex = swipeSelectedIndexArray!.firstIndex(of: index)!
                                    swipeSelectedIndexArray?.remove(at: firstIndex)
                                }
                            }
                        }
                    }
                }else {
                    let photoAsset = pickerController.selectedAssetArray.first
                    if let lastPhotoAsset = photoAsset,
                       let cellIndexPath = getIndexPath(for: lastPhotoAsset) {
                        if lastIndex > cellIndexPath.item {
                            indexArray.sort { $0 < $1 }
                        }else {
                            indexArray.sort { $0 > $1 }
                        }
                    }
                    for index in indexArray {
                        if lastIndex < beganIndex {
                            if index < lastIndex || index > beganIndex {
                                updateCellSelectedState(for: index, isSelected: !(swipeSelectState == .select))
                                let firstIndex = swipeSelectedIndexArray!.firstIndex(of: index)!
                                swipeSelectedIndexArray?.remove(at: firstIndex)
                            }
                        }else if lastIndex > beganIndex {
                            if index > lastIndex || index < beganIndex {
                                updateCellSelectedState(for: index, isSelected: !(swipeSelectState == .select))
                                let firstIndex = swipeSelectedIndexArray!.firstIndex(of: index)!
                                swipeSelectedIndexArray?.remove(at: firstIndex)
                            }
                        }else {
                            if index != lastIndex {
                                updateCellSelectedState(for: index, isSelected: !(swipeSelectState == .select))
                                let firstIndex = swipeSelectedIndexArray!.firstIndex(of: index)!
                                swipeSelectedIndexArray?.remove(at: firstIndex)
                            }
                        }
                    }
                }
                if beganIndex > lastIndex {
                    var index = beganIndex
                    while index >= lastIndex {
                        panGRChangedUpdateState(index: index, state: swipeSelectState)
                        index -= 1
                    }
                }else if beganIndex < lastIndex {
                    for index in beganIndex ... lastIndex {
                        panGRChangedUpdateState(index: index, state: swipeSelectState)
                    }
                }else {
                    panGRChangedUpdateState(index: beganIndex, state: swipeSelectState)
                }
                updateCellSelectedTitle()
            }else {
                if let photoAsset = getCell(for: lastIndex)?.photoAsset {
                    if photoAsset.mediaType == .video &&
                        pickerController.pickerData.videoDurationExceedsTheLimit(photoAsset) {
                        return
                    }
                    if !pickerController.pickerData.canSelect(photoAsset, isShowHUD: false) && !photoAsset.isSelected {
                        return
                    }
                    swipeSelectedIndexArray = []
                    swipeSelectBeganIndexPath = lastIndexPath
                    swipeSelectState = photoAsset.isSelected ? .unselect : .select
                    updateCellSelectedState(for: lastIndex, isSelected: swipeSelectState == .select)
                    swipeSelectedIndexArray?.append(lastIndex)
                    swipeSelectAutoScroll()
                }
            }
        }else {
            if let beganIndex = swipeSelectBeganIndexPath?.item,
               let swipeSelectState = swipeSelectState,
               let indexArray = swipeSelectedIndexArray,
               let point = swipeSelectLastLocalPoint {
                let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
                let itemHieght: CGFloat
                if let height = flowLayout?.itemSize.height {
                    itemHieght = height
                } else {
                    itemHieght = 50
                }
                let largeHeight = collectionView.contentSize.height > collectionView.height
                var exceedBottom: Bool
                let offsety = collectionView.contentOffset.y
                let maxOffsetY =
                    collectionView.contentSize.height -
                    collectionView.height +
                    collectionView.contentInset.bottom - 1
                if offsety > maxOffsetY {
                    let exceedOffset_1 =
                        collectionView.height -
                        collectionView.contentInset.bottom - 1 - itemHieght
                    let exceedOffset_2 = collectionView.contentSize.height - 1 - itemHieght
                    exceedBottom = largeHeight ? point.y > exceedOffset_1 : localPoint.y > exceedOffset_2
                }else {
                    exceedBottom = largeHeight ?
                        false :
                        localPoint.y > collectionView.contentSize.height - 1 - itemHieght
                }
                let inScope = point.x >= 0 && point.x <= collectionView.width
                if exceedBottom && inScope {
                    for index in indexArray where index < beganIndex {
                        updateCellSelectedState(for: index, isSelected: !(swipeSelectState == .select))
                        let firstIndex = swipeSelectedIndexArray!.firstIndex(of: index)!
                        swipeSelectedIndexArray?.remove(at: firstIndex)
                    }
                    let endIndex = needOffset ? assets.count : assets.count - 1
                    for index in beganIndex ... endIndex {
                        panGRChangedUpdateState(index: index, state: swipeSelectState)
                    }
                }else if localPoint.y < 0 && inScope {
                    for index in indexArray where index > beganIndex {
                        updateCellSelectedState(for: index, isSelected: !(swipeSelectState == .select))
                        let firstIndex = swipeSelectedIndexArray!.firstIndex(of: index)!
                        swipeSelectedIndexArray?.remove(at: firstIndex)
                    }
                    for index in 0 ... beganIndex {
                        panGRChangedUpdateState(index: index, state: swipeSelectState)
                    }
                }
            }
        }
    }
    
    func endedPanGestureRecognizer() {
        swipeSelectAutoScrollTimer?.cancel()
        swipeSelectAutoScrollTimer = nil
        swipeSelectBeganIndexPath = nil
        swipeSelectState = nil
        swipeSelectedIndexArray = nil
    }
    private func panGRChangedUpdateState(index: Int, state: PhotoPickerListSwipeSelectState) {
        if needOffset {
            if index < offsetIndex {
                return
            }
        }else {
            if index >= assets.count {
                return
            }
        }
        let photoAsset = getAsset(for: index)
        if photoAsset.mediaType == .video &&
            pickerController.pickerData.videoDurationExceedsTheLimit(photoAsset) {
            return
        }
        if swipeSelectState == .select {
            if let array = swipeSelectedIndexArray,
               !photoAsset.isSelected,
               !array.contains(index) {
                swipeSelectedIndexArray?.append(index)
            }
        }else {
            if let array = swipeSelectedIndexArray,
               photoAsset.isSelected, !array.contains(index) {
                swipeSelectedIndexArray?.append(index)
            }
        }
        updateCellSelectedState(for: index, isSelected: state == .select)
    }
    private func swipeSelectAutoScroll() {
        if !config.swipeSelectAllowAutoScroll {
            return
        }
        swipeSelectAutoScrollTimer = DispatchSource.makeTimerSource()
        swipeSelectAutoScrollTimer?.schedule(
            deadline: .now() + .milliseconds(250),
            repeating: .milliseconds(250),
            leeway: .microseconds(0)
        )
        swipeSelectAutoScrollTimer?.setEventHandler(handler: {
            DispatchQueue.main.async {
                self.startAutoScroll()
            }
        })
        swipeSelectAutoScrollTimer?.resume()
    }
    private func startAutoScroll() {
        if let localPoint = swipeSelectLastLocalPoint {
            let topRect = CGRect(
                x: 0,
                y: 0,
                width: view.width,
                height: config.autoSwipeTopAreaHeight + collectionView.contentInset.top
            )
            let bottomRect = CGRect(
                x: 0,
                y: collectionView.height - collectionView.contentInset.bottom - config.autoSwipeBottomAreaHeight,
                width: view.width,
                height: config.autoSwipeBottomAreaHeight + collectionView.contentInset.bottom
            )
            let margin: CGFloat = 140 * config.swipeSelectScrollSpeed
            var offsety: CGFloat
            if topRect.contains(localPoint) {
                offsety = self.collectionView.contentOffset.y - margin
                if offsety < -collectionView.contentInset.top {
                    offsety = -collectionView.contentInset.top
                }
                UIView.animate(withDuration: 0.25, delay: 0, options: .curveLinear) {
                    self.collectionView.contentOffset = CGPoint(x: self.collectionView.contentOffset.x, y: offsety)
                }
            }else if bottomRect.contains(localPoint) {
                offsety = self.collectionView.contentOffset.y + margin
                let maxOffsetY = collectionView.contentSize.height -
                    collectionView.height +
                    collectionView.contentInset.bottom
                if offsety > maxOffsetY {
                    offsety = maxOffsetY
                }
                UIView.animate(withDuration: 0.25, delay: 0, options: .curveLinear) {
                    self.collectionView.contentOffset = CGPoint(x: self.collectionView.contentOffset.x, y: offsety)
                }
            }
            recallSwipeSelectAction()
        }
    }
    
    func updateCellSelectedState(for item: Int, isSelected: Bool) {
        if item >= assets.count && !needOffset {
            return
        }
        var showHUD = false
        let photoAsset = getAsset(for: item)
        let cell = getCell(for: item)
        if photoAsset.isSelected != isSelected {
            if isSelected {
                func addAsset(showTip: Bool) {
                    if pickerController.pickerData.canSelect(photoAsset, isShowHUD: showTip) {
                        if pickerController.pickerData.append(photoAsset) {
                            delegate?.photoList(self as! PhotoPickerList, didSelectedAsset: photoAsset)
                        }
                        if let cell = cell {
                            cell.updateSelectedState(
                                isSelected: isSelected,
                                animated: false
                            )
                        }
                    }else {
                        showHUD = true
                    }
                }
                if let pickerCell = cell as? PhotoPickerViewCell {
                    if photoAsset.downloadStatus != .succeed {
                        let inICloud = pickerCell.checkICloundStatus(
                            allowSyncPhoto: pickerController.config.allowSyncICloudWhenSelectPhoto
                        )
                        if !inICloud {
                            addAsset(showTip: false)
                        }
                    }else {
                        addAsset(showTip: false)
                    }
                }else {
                    let inICloud = photoAsset.checkICloundStatus(
                        allowSyncPhoto: pickerController.config.allowSyncICloudWhenSelectPhoto,
                        hudAddedTo: view,
                        completion: { _, isSuccess in
                        if isSuccess {
                            addAsset(showTip: true)
                        }
                    })
                    if inICloud {
                        swipeSelectPanGR?.isEnabled = false
                        endedPanGestureRecognizer()
                        swipeSelectPanGR?.isEnabled = true
                    }else {
                        addAsset(showTip: false)
                    }
                }
            }else {
                if pickerController.pickerData.remove(photoAsset) {
                    delegate?.photoList(self as! PhotoPickerList, didDeselectedAsset: photoAsset)
                }
                if let cell = cell {
                    cell.updateSelectedState(isSelected: isSelected, animated: false)
                }
            }
            delegate?.photoList(selectedAssetDidChanged: self as! PhotoPickerList)
        }
        if pickerController.pickerData.isFull && showHUD {
            swipeSelectPanGR?.isEnabled = false
            PhotoManager.HUDView.showInfo(
                with: .textManager.picker.maximumSelectedHudTitle.text,
                delay: 1.5,
                animated: true,
                addedTo: navigationController?.view
            )
            endedPanGestureRecognizer()
            swipeSelectPanGR?.isEnabled = true
        }
    }
}
