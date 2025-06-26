//
//  PhotoMyAlbumViewController.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/10/19.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit

public protocol PhotoMyAlbumViewControllerDelegate: AnyObject {
    func myAlbumViewController(_ myAlbumViewController: PhotoMyAlbumViewController, didSelectedWith assetCollection: PhotoAssetCollection)
    func myAlbumViewController(willAppear myAlbumViewController: PhotoMyAlbumViewController)
    func myAlbumViewController(didAppear myAlbumViewController: PhotoMyAlbumViewController)
    func myAlbumViewController(willDisappear myAlbumViewController: PhotoMyAlbumViewController)
    func myAlbumViewController(didDisappear myAlbumViewController: PhotoMyAlbumViewController)
}

public class PhotoMyAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    public weak var delegate: PhotoMyAlbumViewControllerDelegate?
    
    public var config: PhotoAlbumControllerConfiguration = .init()
    public var assetCollections: [PhotoAssetCollection] = []
    
    var flowLayout: UICollectionViewFlowLayout!
    var collectionView: UICollectionView!
    var rowCount: CGFloat {
        (UIDevice.isPad || !UIDevice.isPortrait) ? 4 : 2
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        title = .textManager.picker.albumList.myAlbumNavigationTitle.text
        flowLayout = UICollectionViewFlowLayout()
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
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        view.addSubview(collectionView)
        if PhotoManager.isRTL {
            collectionView.semanticContentAttribute = .forceRightToLeft
        }else {
            collectionView.semanticContentAttribute = .forceLeftToRight
        }
        updateColors()
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
        delegate?.myAlbumViewController(self, didSelectedWith: assetCollections[indexPath.item])
    }
    
    func updateColors() {
        view.backgroundColor = PhotoManager.isDark ? config.backgroundDarkColor : config.backgroundColor
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        delegate?.myAlbumViewController(willAppear: self)
    }
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        delegate?.myAlbumViewController(didAppear: self)
    }
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.myAlbumViewController(willDisappear: self)
    }
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        delegate?.myAlbumViewController(didDisappear: self)
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.frame = view.bounds
        let navHeight = navigationController?.navigationBar.frame.maxY ?? 0
        let margin = rowCount - 1
        let itemWidth = (view.width - (30 + 12 * margin) - UIDevice.leftMargin - UIDevice.rightMargin) / rowCount
        let fontHeight = config.albumNameFont.lineHeight + config.photoCountFont.lineHeight + 8
        flowLayout.itemSize = .init(width: itemWidth, height: itemWidth + fontHeight)
        collectionView.contentInset = .init(top: navHeight, left: UIDevice.leftMargin, bottom: UIDevice.bottomMargin, right: UIDevice.rightMargin)
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                updateColors()
            }
        }
    }
}
