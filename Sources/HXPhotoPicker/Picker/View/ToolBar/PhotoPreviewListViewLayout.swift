//
//  PhotoPreviewListViewLayout.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/11/23.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit

class PhotoPreviewListViewLayout: UICollectionViewLayout {
    enum Style {
        case expanded(IndexPath, expandingThumbnailWidthToHeight: CGFloat?)
        case collapsed
        
        var indexPathForExpandingItem: IndexPath? {
            switch self {
            case .expanded(let indexPath, _):
                return indexPath
            case .collapsed:
                return nil
            }
        }
    }
    
    let style: Style
    
    var expandedItemWidth: CGFloat?
    static let collapsedItemWidth: CGFloat = 55 / 16 * 9
    
    private var attributesDictionary: [IndexPath: UICollectionViewLayoutAttributes] = [:]
    private var contentSize: CGSize = .zero
    
    init(style: Style) {
        self.style = style
        super.init()
    }
    
    required init?(coder: NSCoder) {
        self.style = .collapsed
        super.init(coder: coder)
    }
    
    // MARK: - Override
    
    override var collectionViewContentSize: CGSize {
        contentSize
    }
    
    override func prepare() {
        // Reset
        attributesDictionary.removeAll(keepingCapacity: true)
        contentSize = .zero
        
        guard let collectionView, collectionView.numberOfSections == 1 else { return }
        let numberOfItems = collectionView.numberOfItems(inSection: 0)
        guard numberOfItems > 0 else { return }
        
        // NOTE: Cache and reuse expandedItemWidth for smooth animation.
        let expandedItemWidth = self.expandedItemWidth ?? expandingItemWidth(in: collectionView)
        self.expandedItemWidth = expandedItemWidth
        
        let collapsedItemSpacing = 1.0
        let expandedItemSpacing = 12.0
        
        // Calculate frames for each item
        var frames: [IndexPath: CGRect] = [:]
        for item in 0..<numberOfItems {
            let indexPath = IndexPath(item: item, section: 0)
            let previousIndexPath = IndexPath(item: item - 1, section: 0)
            let width: CGFloat
            let itemSpacing: CGFloat
            switch style.indexPathForExpandingItem {
            case indexPath:
                width = expandedItemWidth
                itemSpacing = expandedItemSpacing
            case previousIndexPath:
                width = Self.collapsedItemWidth
                itemSpacing = expandedItemSpacing
            default:
                width = Self.collapsedItemWidth
                itemSpacing = collapsedItemSpacing
            }
            let previousFrame = frames[previousIndexPath]
            let x = previousFrame.map { $0.maxX + itemSpacing } ?? 0
            frames[indexPath] = CGRect(
                x: x,
                y: 0,
                width: width,
                height: collectionView.bounds.height
            )
        }
        
        // Calculate the content size
        let lastItemFrame = frames[IndexPath(item: numberOfItems - 1, section: 0)]!
        contentSize = CGSize(
            width: lastItemFrame.maxX,
            height: collectionView.bounds.height
        )
        
        // Set up layout attributes
        for (indexPath, frame) in frames {
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = frame
            attributesDictionary[indexPath] = attributes
        }
    }
    
    private func expandingItemWidth(in collectionView: UICollectionView) -> CGFloat {
        let expandingThumbnailWidthToHeight: CGFloat
        switch style {
        case .expanded(let indexPath, let thumbnailWidthToHeight):
            if let thumbnailWidthToHeight {
                expandingThumbnailWidthToHeight = thumbnailWidthToHeight
            } else if let cell = collectionView.cellForItem(at: indexPath) {
                let cell = cell as! PhotoPreviewListViewCell
                let image = cell.imageView.image
                if let imageSize = image?.size, imageSize.height > 0 {
                    expandingThumbnailWidthToHeight = imageSize.width / imageSize.height
                } else {
                    expandingThumbnailWidthToHeight = 0
                }
            } else {
                expandingThumbnailWidthToHeight = 0
            }
        case .collapsed:
            expandingThumbnailWidthToHeight = 0
        }
        
        let minimumWidth = Self.collapsedItemWidth
        let maximumWidth = 84.0
        return min(
            max(
                collectionView.bounds.height * expandingThumbnailWidthToHeight,
                minimumWidth
            ),
            maximumWidth
        )
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        attributesDictionary.values.filter { $0.frame.intersects(rect) }
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        attributesDictionary[indexPath]
    }
    
    override func targetContentOffset(
        forProposedContentOffset proposedContentOffset: CGPoint
    ) -> CGPoint {
        let offset = super.targetContentOffset(
            forProposedContentOffset: proposedContentOffset
        )
        guard let collectionView else { 
            return offset
        }
        
        // Center the target item.
        let indexPathForCenterItem: IndexPath
        switch style {
        case .expanded(let indexPathForExpandingItem, _):
            indexPathForCenterItem = indexPathForExpandingItem
        case .collapsed:
            guard let indexPath = collectionView.indexPathForHorizontalCenterItem else {
                return offset
            }
            indexPathForCenterItem = indexPath
        }
        
        guard let centerItemAttributes = layoutAttributesForItem(at: indexPathForCenterItem) else {
            return offset
        }
        return CGPoint(
            x: centerItemAttributes.center.x - collectionView.bounds.width / 2,
            y: offset.y
        )
    }
}

extension UICollectionView {
    var indexPathForHorizontalCenterItem: IndexPath? {
        let centerX = CGPoint(x: contentOffset.x + bounds.width / 2, y: 0)
        return indexPathForItem(at: centerX)
    }
}
