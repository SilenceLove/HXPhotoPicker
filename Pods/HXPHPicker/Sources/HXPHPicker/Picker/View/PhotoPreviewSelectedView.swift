//
//  PhotoPreviewSelectedView.swift
//  HXPHPickerExample
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

protocol PhotoPreviewSelectedViewDelegate: AnyObject {
    func selectedView(_ selectedView: PhotoPreviewSelectedView, didSelectItemAt photoAsset: PhotoAsset)
}

class PhotoPreviewSelectedView: UIView,
                                UICollectionViewDataSource,
                                UICollectionViewDelegate,
                                UICollectionViewDelegateFlowLayout {
    weak var delegate: PhotoPreviewSelectedViewDelegate?
    
    lazy var collectionViewLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout.init()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 5
        layout.minimumInteritemSpacing = 5
        layout.sectionInset = UIEdgeInsets(
            top: 10,
            left: 12 + UIDevice.leftMargin,
            bottom: 5,
            right: 12 + UIDevice.rightMargin
        )
        return layout
    }()

    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView.init(frame: bounds, collectionViewLayout: collectionViewLayout)
        collectionView.backgroundColor = UIColor.clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }
        return collectionView
    }()
    
    var photoAssetArray: [PhotoAsset] = []
    var currentSelectedIndexPath: IndexPath?
    var tickColor: UIColor?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
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
    
    func removePhotoAsset(photoAsset: PhotoAsset) {
        let beforeIsEmpty = photoAssetArray.isEmpty
        
        if let item = photoAssetArray.firstIndex(of: photoAsset) {
            if item == currentSelectedIndexPath?.item {
                currentSelectedIndexPath = nil
            }
            photoAssetArray.remove(at: item)
            collectionView.deleteItems(at: [IndexPath(item: item, section: 0)])
        }
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
        if photoAsset == nil {
            deselectedCurrentIndexPath()
            return
        }
        if photoAssetArray.contains(photoAsset!) {
            let item = photoAssetArray.firstIndex(of: photoAsset!) ?? 0
            if item == currentSelectedIndexPath?.item {
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
        if currentSelectedIndexPath != nil {
            collectionView.deselectItem(at: currentSelectedIndexPath!, animated: true)
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
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: NSStringFromClass(PhotoPreviewSelectedViewCell.self),
            for: indexPath
        ) as! PhotoPreviewSelectedViewCell
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
    
    override func layoutSubviews() {
        collectionView.frame = bounds
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
