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
        
        albumView = pickerConfig.albumList.albumList.init(
            config: pickerConfig,
            isSplit: pickerController.splitType.isSplit
        )
        if pickerConfig.albumShowMode.isPopView {
            albumBackgroudView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
            albumBackgroudView.addGestureRecognizer(
                UITapGestureRecognizer(
                    target: self,
                    action: #selector(didAlbumBackgroudViewClick)
                )
            )
            albumView.delegate = self
            view.addSubview(albumBackgroudView)
            view.addSubview(albumView)
        }
    }
    
    @objc
    func didTitleViewClick() {
        switch pickerConfig.albumShowMode {
        case .present(let style):
            let assetCollections = pickerController.fetchData.assetCollections
            if assetCollections.isEmpty {
                return
            }
            let vc = pickerConfig.albumController.albumController.init(config: pickerConfig)
            vc.delegate = self
            vc.assetCollections = assetCollections
            vc.selectedAssetCollection = assetCollection
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = style
            present(nav, animated: true)
            return
        default:
            break
        }
        titleView.isSelected = !titleView.isSelected
        if titleView.isSelected {
            // 展开
            if albumView.assetCollections.isEmpty {
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
        listView.view.isUserInteractionEnabled = false
        albumBackgroudView.alpha = 0
        albumBackgroudView.isHidden = false
        albumView.scrollSelectToMiddle()
        UIView.animate(withDuration: 0.25) {
            self.albumBackgroudView.alpha = 1
            self.updateAlbumViewFrame()
        }
    }
    
    func closeAlbumView() {
        listView.view.isUserInteractionEnabled = true
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
                if let barHeight = self.navigationController?.navigationBar.frame.maxY {
                    self.albumView.y = barHeight
                }else {
                    self.albumView.y = UIDevice.navigationBarHeight
                }
            }else {
                if let barHeight = self.navigationController?.navigationBar.frame.maxY {
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
        if AssetPermissionsUtil.isLimitedAuthorizationStatus &&
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
        PhotoManager.HUDView.show(with: nil, delay: 0, animated: true, addedTo: navigationController?.view)
        fetchPhotoAssets()
        albumList.reloadData()
    }
}

extension PhotoPickerViewController: PhotoAlbumControllerDelegate {
    public func albumController(_ albumController: PhotoAlbumController, didSelectedWith assetCollection: PhotoAssetCollection) {
        albumController.dismiss(animated: true)
        if self.assetCollection == assetCollection {
            return
        }
        titleView.title = assetCollection.albumName
        self.assetCollection = assetCollection
        PhotoManager.HUDView.show(with: nil, delay: 0, animated: true, addedTo: navigationController?.view)
        fetchPhotoAssets()
    }
    public func albumController(willAppear viewController: PhotoAlbumController) {
        pickerController.viewControllersWillAppear(viewController)
    }
    public func albumController(didAppear viewController: PhotoAlbumController) {
        pickerController.viewControllersDidAppear(viewController)
    }
    public func albumController(willDisappear viewController: PhotoAlbumController) {
        pickerController.viewControllersWillDisappear(viewController)
    }
    public func albumController(didDisappear viewController: PhotoAlbumController) {
        pickerController.viewControllersDidDisappear(viewController)
    }
}
