//
//  PhotoPickerViewController+AlbumView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/8/27.
//

import UIKit

// MARK: AlbumViewDelegate
extension PhotoPickerViewController: PhotoAlbumListDelegate {
    
    func initAlbumView() {
        titleView = config.navigationTitle.init(config: pickerConfig, isSplit: pickerController.splitType.isSplit)
        titleView.addTarget(self, action: #selector(didTitleViewClick))
        
        albumBackgroudView = UIView()
        albumBackgroudView.isHidden = true
        albumBackgroudView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        albumBackgroudView.addGestureRecognizer(
            UITapGestureRecognizer(
                target: self,
                action: #selector(didAlbumBackgroudViewClick)
            )
        )
        
        albumView = pickerConfig.albumList.albumList.init(
            config: pickerConfig,
            isSplit: pickerController.splitType.isSplit
        )
        albumView.delegate = self
        if pickerConfig.albumShowMode == .popup {
            view.addSubview(albumBackgroudView)
            view.addSubview(albumView)
        }
    }
    
    @objc
    func didTitleViewClick() {
        titleView.isSelected = !titleView.isSelected
        if titleView.isSelected {
            // 展开
            if albumView.assetCollections.isEmpty {
//                ProgressHUD.showLoading(addedTo: view, animated: true)
//                ProgressHUD.hide(forView: weakSelf?.navigationController?.view, animated: true)
                titleView.isSelected = false
                return
            }
            openAlbumView()
        }else {
            // 收起
            closeAlbumView()
        }
    }
    
    @objc func didAlbumBackgroudViewClick() {
        titleView.isSelected = false
        closeAlbumView()
    }
    
    func openAlbumView() {
        listView.collectionView.scrollsToTop = false
        listView.isUserInteractionEnabled = false
        albumBackgroudView.alpha = 0
        albumBackgroudView.isHidden = false
        albumView.scrollSelectToMiddle()
        UIView.animate(withDuration: 0.25) {
            self.albumBackgroudView.alpha = 1
            self.updateAlbumViewFrame()
        }
    }
    
    func closeAlbumView() {
        listView.collectionView.scrollsToTop = true
        listView.isUserInteractionEnabled = true
        UIView.animate(withDuration: 0.25) {
            self.albumBackgroudView.alpha = 0
            self.updateAlbumViewFrame()
        } completion: { _ in
            if self.albumBackgroudView.alpha == 0 {
                self.albumBackgroudView.isHidden = true
            }
        }
    }
    
    func updateAlbumViewFrame() {
        self.albumView.size = CGSize(width: view.width, height: getAlbumViewHeight())
        if titleView.isSelected {
            if self.navigationController?.modalPresentationStyle == UIModalPresentationStyle.fullScreen &&
                UIDevice.isPortrait {
                self.albumView.y = UIDevice.navigationBarHeight
            }else {
                if let barHeight = self.navigationController?.navigationBar.height {
                    self.albumView.y = barHeight
                }else {
                    self.albumView.y = 0
                }
            }
        }else {
            self.albumView.y = -self.albumView.height
        }
    }
    
    func getAlbumViewHeight() -> CGFloat {
        var albumViewHeight = CGFloat(albumView.assetCollections.count) * pickerConfig.albumList.cellHeight
        if AssetManager.authorizationStatusIsLimited() &&
            pickerConfig.allowLoadPhotoLibrary {
            albumViewHeight += 40
        }
        if albumViewHeight > view.height * 0.75 {
            albumViewHeight = view.height * 0.75
        }
        return albumViewHeight
    }
    
    public func albumList(
        _ albumList: PhotoAlbumList,
        didSelectAt index: Int,
        with assetCollection: PhotoAssetCollection
    ) {
        didAlbumBackgroudViewClick()
        if self.assetCollection == assetCollection {
            return
        }
        titleView.title = assetCollection.albumName
        self.assetCollection = assetCollection
        ProgressHUD.showLoading(
            addedTo: navigationController?.view,
            animated: true
        )
        fetchPhotoAssets()
        albumList.reloadData()
    }
}
