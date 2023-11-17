//
//  PhotoPreviewSelectedView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

protocol PhotoPreviewSelectedViewDelegate: AnyObject {
    func selectedView(_ selectedView: PhotoPreviewSelectedView, didSelectItemAt photoAsset: PhotoAsset)
    func selectedView(_ selectedView: PhotoPreviewSelectedView, moveItemAt fromIndex: Int, toIndex: Int)
}

class PhotoPreviewSelectedView: UIView,
                                UICollectionViewDataSource,
                                UICollectionViewDelegate,
                                UICollectionViewDelegateFlowLayout {
    
    weak var delegate: PhotoPreviewSelectedViewDelegate?
    
    var collectionViewLayout: UICollectionViewFlowLayout!
    var collectionView: UICollectionView!
    var tickColor: UIColor?
    
    var allowDrop: Bool = true
    var assetCount: Int { photoAssetArray.count }
    
    private var photoAssetArray: [PhotoAsset] = []
    private var currentSelectedIndexPath: IndexPath?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.scrollDirection = .horizontal
        collectionViewLayout.minimumLineSpacing = 5
        collectionViewLayout.minimumInteritemSpacing = 5
        collectionViewLayout.sectionInset = .init(
            top: 10,
            left: 12 + UIDevice.leftMargin,
            bottom: 5,
            right: 12 + UIDevice.rightMargin
        )
        collectionView = UICollectionView(frame: bounds, collectionViewLayout: collectionViewLayout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            collectionView.dragDelegate = self
            collectionView.dropDelegate = self
            collectionView.dragInteractionEnabled = true
        }
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }
        addSubview(collectionView)
    }
    func reloadSectionInset() {
        if x == 0 {
            collectionViewLayout.sectionInset = UIEdgeInsets(
                top: 10,
                left: 12 + UIDevice.leftMargin,
                bottom: 5,
                right: 12 + UIDevice.rightMargin
            )
        }
    }
    func reloadData(photoAssets: [PhotoAsset]) {
        isHidden = photoAssets.isEmpty
        photoAssetArray = photoAssets
        collectionView.reloadData()
    }
    func reloadData(photoAsset: PhotoAsset) {
        if let index = photoAssetArray.firstIndex(of: photoAsset) {
            collectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
            collectionView.selectItem(
                at: currentSelectedIndexPath,
                animated: false,
                scrollPosition: .centeredHorizontally
            )
        }
    }
    
    func insertPhotoAsset(photoAsset: PhotoAsset) {
        let beforeIsEmpty = photoAssetArray.isEmpty
        let item = photoAssetArray.count
        let indexPath = IndexPath(item: item, section: 0)
        photoAssetArray.append(photoAsset)
        collectionView.insertItems(at: [indexPath])
        collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
        currentSelectedIndexPath = indexPath
        if beforeIsEmpty {
            alpha = 0
            isHidden = false
            UIView.animate(withDuration: 0.25) {
                self.alpha = 1
            }
        }
    }
    
    func removePhotoAssets(_ photoAssets: [PhotoAsset]) {
        if photoAssets.isEmpty {
            return
        }
        let beforeIsEmpty = photoAssetArray.isEmpty
        var indexPaths: [IndexPath] = []
        let tempAssets = photoAssetArray
        for photoAsset in photoAssets {
            guard let item = photoAssetArray.firstIndex(of: photoAsset) else {
                continue
            }
            if let indexPath = currentSelectedIndexPath, item == indexPath.item {
                currentSelectedIndexPath = nil
            }
            photoAssetArray.remove(at: item)
            if let item = tempAssets.firstIndex(of: photoAsset) {
                indexPaths.append(.init(item: item, section: 0))
            }
            
        }
        collectionView.deleteItems(at: indexPaths)
        if !beforeIsEmpty && photoAssetArray.isEmpty {
            UIView.animate(withDuration: 0.25) {
                self.alpha = 0
            } completion: { (isFinish) in
                if isFinish {
                    self.isHidden = true
                }
            }
        }
    }
    
    func replacePhotoAsset(at index: Int, with photoAsset: PhotoAsset) {
        photoAssetArray[index] = photoAsset
        collectionView.reloadItems(at: [IndexPath.init(item: index, section: 0)])
    }
    func scrollTo(photoAsset: PhotoAsset?, isAnimated: Bool = true) {
        guard let photoAsset = photoAsset else {
            deselectedCurrentIndexPath()
            return
        }
        if let item = photoAssetArray.firstIndex(of: photoAsset) {
            if let indexPath = currentSelectedIndexPath, item == indexPath.item {
                return
            }
            let indexPath = IndexPath(item: item, section: 0)
            collectionView.selectItem(at: indexPath, animated: isAnimated, scrollPosition: .centeredHorizontally)
            currentSelectedIndexPath = indexPath
        }else {
            deselectedCurrentIndexPath()
        }
    }
    func deselectedCurrentIndexPath() {
        if let indexPath = currentSelectedIndexPath {
            collectionView.deselectItem(at: indexPath, animated: true)
            currentSelectedIndexPath = nil
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        photoAssetArray.count
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell: PhotoPreviewSelectedViewCell = collectionView.dequeueReusableCell(for: indexPath)
        cell.tickColor = tickColor
        cell.photoAsset = photoAssetArray[indexPath.item]
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        currentSelectedIndexPath = indexPath
        delegate?.selectedView(self, didSelectItemAt: photoAssetArray[indexPath.item])
    }
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let photoAsset = photoAssetArray[indexPath.item]
        return getItemSize(photoAsset: photoAsset)
    }
    func collectionView(
        _ collectionView: UICollectionView,
        didEndDisplaying cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        let myCell = cell as! PhotoPreviewSelectedViewCell
        myCell.cancelRequest()
    }
    func getItemSize(photoAsset: PhotoAsset) -> CGSize {
        let minWidth: CGFloat = 70 - collectionViewLayout.sectionInset.top - collectionViewLayout.sectionInset.bottom
//        let maxWidth: CGFloat = minWidth / 9 * 16
        let maxHeight: CGFloat = minWidth
//        let aspectRatio = maxHeight / photoAsset.imageSize.height
        let itemHeight = maxHeight
//        var itemWidth = photoAsset.imageSize.width * aspectRatio
//        if itemWidth < minWidth {
           let itemWidth = minWidth
//        }else if itemWidth > maxWidth {
//            itemWidth = maxWidth
//        }
        return CGSize(width: itemWidth, height: itemHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, canEditItemAt indexPath: IndexPath) -> Bool {
        true
    }
    
    override func layoutSubviews() {
        collectionView.frame = bounds
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@available(iOS 11.0, *)
extension PhotoPreviewSelectedView: UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    
    func collectionView(
        _ collectionView: UICollectionView,
        itemsForBeginning session: UIDragSession,
        at indexPath: IndexPath
    ) -> [UIDragItem] {
        if !allowDrop {
            return []
        }
        let itemProvider = NSItemProvider.init()
        let dragItem = UIDragItem.init(itemProvider: itemProvider)
        dragItem.localObject = indexPath
        return [dragItem]
    }
    
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        allowDrop
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        dropSessionDidUpdate session: UIDropSession,
        withDestinationIndexPath
            destinationIndexPath: IndexPath?
    ) -> UICollectionViewDropProposal {
        var dropProposal: UICollectionViewDropProposal
        if session.localDragSession != nil {
            dropProposal = UICollectionViewDropProposal.init(operation: .move, intent: .insertAtDestinationIndexPath)
        }else {
            dropProposal = UICollectionViewDropProposal.init(operation: .copy, intent: .insertAtDestinationIndexPath)
        }
        return dropProposal
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        performDropWith coordinator: UICollectionViewDropCoordinator
    ) {
        if let destinationIndexPath = coordinator.destinationIndexPath,
           let sourceIndexPath = coordinator.items.first?.sourceIndexPath {
            collectionView.isUserInteractionEnabled = false
            deselectedCurrentIndexPath()
            collectionView.performBatchUpdates {
                let sourceAsset = photoAssetArray[sourceIndexPath.item]
                photoAssetArray.remove(at: sourceIndexPath.item)
                photoAssetArray.insert(sourceAsset, at: destinationIndexPath.item)
                collectionView.moveItem(at: sourceIndexPath, to: destinationIndexPath)
                delegate?.selectedView(self, moveItemAt: sourceIndexPath.item, toIndex: destinationIndexPath.item)
            } completion: { _ in
                collectionView.isUserInteractionEnabled = true
            }
            if let dragItem = coordinator.items.first?.dragItem {
                coordinator.drop(dragItem, toItemAt: destinationIndexPath)
            }
        }
    }
}
