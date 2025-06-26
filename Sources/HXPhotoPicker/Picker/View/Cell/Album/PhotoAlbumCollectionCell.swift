//
//  PhotoAlbumCollectionCell.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/10/19.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit

public protocol PhotoAlbumCollectionCellDelegate: AnyObject {
    func collectionCell(didSelected assetCollection: PhotoAssetCollection)
}
public class PhotoAlbumCollectionCell: UITableViewCell, UICollectionViewDataSource, UICollectionViewDelegate {
    public weak var delegate: PhotoAlbumCollectionCellDelegate?
    var flowLayout: UICollectionViewFlowLayout!
    var collectionView: UICollectionView!
    var lineView: UIView!
    
    var rowCount: CGFloat {
        (UIDevice.isPad || !UIDevice.isPortrait) ? 4 : 2
    }
    
    public var config: PhotoAlbumControllerConfiguration = .init() {
        didSet {
            updateColors()
        }
    }
    public var assetCollections: [PhotoAssetCollection] = [] {
        didSet {
            collectionView.reloadData()
        }
    }
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 12
        flowLayout.minimumInteritemSpacing = 12
        flowLayout.sectionInset = .init(top: 10, left: 15, bottom: 10, right: 15)
        collectionView = HXCollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.delaysContentTouches = false
        collectionView.register(PhotoAlbumCollectionViewCell.self)
        contentView.addSubview(collectionView)
        
        if PhotoManager.isRTL {
            collectionView.semanticContentAttribute = .forceRightToLeft
        }else {
            collectionView.semanticContentAttribute = .forceLeftToRight
        }
        lineView = UIView()
        lineView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.15)
        contentView.addSubview(lineView)
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        assetCollections.count
    }
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: PhotoAlbumCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
        cell.config = config
        cell.assetCollection = assetCollections[indexPath.item]
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        delegate?.collectionCell(didSelected: assetCollections[indexPath.item])
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.hxPicker_frame = contentView.bounds
        let count = rowCount - 1
        let margin: CGFloat = assetCollections.count > Int(rowCount) * 2 ? 5 : 0
        let itemWidth = (contentView.width - (30 + 12 * count)) / rowCount - margin
        let fontHeight = config.albumNameFont.lineHeight + config.photoCountFont.lineHeight + 8
        flowLayout.itemSize = .init(width: itemWidth, height: itemWidth + fontHeight)
        lineView.hxPicker_frame = .init(x: 15, y: contentView.height - 0.5, width: contentView.width - 15, height: 0.5)
    }
    
    func updateColors() {
        lineView.backgroundColor = PhotoManager.isDark ? config.separatorLineDarkColor : config.separatorLineColor
        backgroundColor = PhotoManager.isDark ? config.cellBackgroundDarkColor : config.cellBackgroundColor
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                updateColors()
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
