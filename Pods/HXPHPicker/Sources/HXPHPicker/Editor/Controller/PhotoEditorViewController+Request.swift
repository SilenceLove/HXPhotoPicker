//
//  PhotoEditorViewController+Request.swift
//  HXPHPicker
//
//  Created by Slience on 2021/7/14.
//

import UIKit
#if canImport(Kingfisher)
import Kingfisher
#endif

extension PhotoEditorViewController {
    #if HXPICKER_ENABLE_PICKER
    func requestImage() {
        if photoAsset.isLocalAsset {
            ProgressHUD.showLoading(addedTo: view, animated: true)
            DispatchQueue.global().async {
                if self.photoAsset.mediaType == .photo {
                    var image = self.photoAsset.localImageAsset!.image!
                    if self.photoAsset.mediaSubType.isGif {
                        if let imageData = self.photoAsset.localImageAsset?.imageData {
                            #if canImport(Kingfisher)
                            if let gifImage = DefaultImageProcessor.default.process(item: .data(imageData), options: .init([]))  {
                                image = gifImage
                            }
                            #endif
                        }else if let imageURL = self.photoAsset.localImageAsset?.imageURL {
                            do {
                                let imageData = try Data.init(contentsOf: imageURL)
                                #if canImport(Kingfisher)
                                if let gifImage = DefaultImageProcessor.default.process(item: .data(imageData), options: .init([]))  {
                                    image = gifImage
                                }
                                #endif
                            }catch {}
                        }
                    }
                    self.filterHDImageHandler(image: image)
                    DispatchQueue.main.async {
                        ProgressHUD.hide(forView: self.view, animated: true)
                        self.requestAssetCompletion(image: image)
                    }
                }else {
                    self.filterHDImageHandler(image: self.photoAsset.localVideoAsset!.image!)
                    DispatchQueue.main.async {
                        ProgressHUD.hide(forView: self.view, animated: true)
                        self.requestAssetCompletion(image: self.photoAsset.localVideoAsset!.image!)
                    }
                }
            }
        }else if photoAsset.isNetworkAsset {
            #if canImport(Kingfisher)
            let loadingView = ProgressHUD.showLoading(addedTo: view, animated: true)
            photoAsset.getNetworkImage(urlType: .original, filterEditor: true) { (receiveSize, totalSize) in
                let progress = Double(receiveSize) / Double(totalSize)
                if progress > 0 {
                    loadingView?.updateText(text: "图片下载中".localized + "(" + String(Int(progress * 100)) + "%)")
                }
            } resultHandler: { [weak self] (image) in
                guard let self = self else { return }
                if let image = image {
                    DispatchQueue.global().async {
                        self.filterHDImageHandler(image: image)
                        DispatchQueue.main.async {
                            ProgressHUD.hide(forView: self.view, animated: true)
                            self.requestAssetCompletion(image: image)
                        }
                    }
                }else {
                    ProgressHUD.hide(forView: self.view, animated: true)
                    PhotoTools.showConfirm(viewController: self, title: "提示".localized, message: "图片获取失败!".localized, actionTitle: "确定".localized) { (alertAction) in
                        self.didBackClick()
                    }
                }
            }
            #endif
        } else {
            ProgressHUD.showLoading(addedTo: view, animated: true)
            if photoAsset.phAsset != nil && !photoAsset.isGifAsset {
                photoAsset.requestImageData(filterEditor: true,
                                            iCloudHandler: nil,
                                            progressHandler: nil) {
                    [weak self] (asset, imageData, imageOrientation, info) in
                    guard let self = self else { return }
                    let image = UIImage.init(data: imageData)?.scaleSuitableSize()
                    DispatchQueue.global().async {
                        self.filterHDImageHandler(image: image!)
                        DispatchQueue.main.async {
                            ProgressHUD.hide(forView: self.view, animated: true)
                            self.requestAssetCompletion(image: image!)
                        }
                    }
                } failure: { [weak self] (asset, info) in
                    ProgressHUD.hide(forView: self?.view, animated: true)
                    self?.requestAssetFailure()
                }
                return
            }
            photoAsset.requestAssetImageURL(filterEditor: true) {
                [weak self] (imageUrl) in
                guard let self = self else { return }
                DispatchQueue.global().async {
                    if let imageUrl = imageUrl {
                        #if canImport(Kingfisher)
                        if self.photoAsset.isGifAsset == true {
                            do {
                                let imageData = try Data.init(contentsOf: imageUrl)
                                if let gifImage = DefaultImageProcessor.default.process(item: .data(imageData), options: .init([]))  {
                                    self.filterHDImageHandler(image: gifImage)
                                    DispatchQueue.main.async {
                                        ProgressHUD.hide(forView: self.view, animated: true)
                                        self.requestAssetCompletion(image: gifImage)
                                    }
                                    return
                                }
                            }catch {}
                        }
                        #endif
                        if let image = UIImage.init(contentsOfFile: imageUrl.path)?.scaleSuitableSize() {
                            self.filterHDImageHandler(image: image)
                            DispatchQueue.main.async {
                                ProgressHUD.hide(forView: self.view, animated: true)
                                self.requestAssetCompletion(image: image)
                            }
                            return
                        }
                    }
                    DispatchQueue.main.async {
                        ProgressHUD.hide(forView: self.view, animated: true)
                        self.requestAssetFailure()
                    }
                }
            }
        }
    }
    #endif
    
    #if canImport(Kingfisher)
    func requestNetworkImage() {
        let url = networkImageURL!
        let loadingView = ProgressHUD.showLoading(addedTo: view, animated: true)
        PhotoTools.downloadNetworkImage(with: url, options: [.backgroundDecode]) { (receiveSize, totalSize) in
            let progress = Double(receiveSize) / Double(totalSize)
            if progress > 0 {
                loadingView?.updateText(text: "图片下载中".localized + "(" + String(Int(progress * 100)) + "%)")
            }
        } completionHandler: { [weak self] (image) in
            guard let self = self else { return }
            if let image = image {
                DispatchQueue.global().async {
                    self.filterHDImageHandler(image: image)
                    DispatchQueue.main.async {
                        ProgressHUD.hide(forView: self.view, animated: true)
                        self.requestAssetCompletion(image: image)
                    }
                }
            }else {
                self.requestAssetFailure()
            }
        }
    }
    #endif
    
    func requestAssetCompletion(image: UIImage) {
        if imageInitializeCompletion == true {
            imageView.setImage(image)
            filterView.image = filterImage
            if let editedData = editResult?.editedData {
                imageView.setEditedData(editedData: editedData)
                brushColorView.canUndo = imageView.canUndoDraw
                mosaicToolView.canUndo = imageView.canUndoMosaic
            }
            if state == .cropping {
                imageView.startCropping(true)
                croppingAction()
            }
        }
        setFilterImage()
        setImage(image)
    }
    func requestAssetFailure() {
        ProgressHUD.hide(forView: view, animated: true)
        PhotoTools.showConfirm(viewController: self, title: "提示".localized, message: "图片获取失败!".localized, actionTitle: "确定".localized) { (alertAction) in
            self.didBackClick()
        }
    }
    func filterHDImageHandler(image: UIImage) {
        if config.fixedCropState {
            guard let editedData = editResult?.editedData else {
                return
            }
            if editedData.mosaicData.isEmpty &&
               editedData.filter == nil {
                return
            }
        }
        var value: Float = 0
        var minSize: CGFloat = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        DispatchQueue.main.sync {
            value = filterView.sliderView.value
            if !view.size.equalTo(.zero) {
                minSize = min(view.width, view.height) * 2
            }
        }
        if image.width > minSize {
            let thumbnailScale = minSize / image.width
            thumbnailImage = image.scaleImage(toScale: thumbnailScale)
        }
        if thumbnailImage == nil {
            thumbnailImage = image
        }
        if let filter = editResult?.editedData.filter {
            var newImage: UIImage?
            if !config.filterConfig.infos.isEmpty {
                let info = config.filterConfig.infos[filter.sourceIndex]
                newImage = info.filterHandler(thumbnailImage, image, value, .touchUpInside)
            }
            if let newImage = newImage {
                filterHDImage = newImage
                mosaicImage = newImage.mosaicImage(level: config.mosaicConfig.mosaicWidth)
            }
        }else {
            mosaicImage = thumbnailImage.mosaicImage(level: config.mosaicConfig.mosaicWidth)
        }
        filterImage = image.scaleToFillSize(size: CGSize(width: 80, height: 80), equalRatio: true)
    }
    func setFilterImage() {
        if let image = filterHDImage {
            imageView.updateImage(image)
        }
        imageView.setMosaicOriginalImage(mosaicImage)
        filterView.image = filterImage
    }
    func localImageHandler() {
        ProgressHUD.showLoading(addedTo: view, animated: true)
        DispatchQueue.global().async {
            self.filterHDImageHandler(image: self.image)
            DispatchQueue.main.async {
                ProgressHUD.hide(forView: self.view, animated: true)
                self.requestAssetCompletion(image: self.image)
            }
        }
    }
}
