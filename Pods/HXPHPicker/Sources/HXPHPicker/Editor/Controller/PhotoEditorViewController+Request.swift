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
            requestLocalAsset()
        }else if photoAsset.isNetworkAsset {
            requestNetworkAsset()
        } else {
            ProgressHUD.showLoading(addedTo: view, animated: true)
            if photoAsset.phAsset != nil && !photoAsset.isGifAsset {
                requestAssetData()
                return
            }
            requestAssetURL()
        }
    }
    func requestLocalAsset() {
        ProgressHUD.showLoading(addedTo: view, animated: true)
        DispatchQueue.global().async {
            if self.photoAsset.mediaType == .photo {
                var image = self.photoAsset.localImageAsset!.image!
                image = self.fixImageOrientation(image)
                if self.photoAsset.mediaSubType.isGif {
                    if let imageData = self.photoAsset.localImageAsset?.imageData {
                        #if canImport(Kingfisher)
                        if let gifImage = DefaultImageProcessor.default.process(
                            item: .data(imageData),
                            options: .init([])
                        ) {
                            image = gifImage
                        }
                        #endif
                    }else if let imageURL = self.photoAsset.localImageAsset?.imageURL {
                        do {
                            let imageData = try Data.init(contentsOf: imageURL)
                            #if canImport(Kingfisher)
                            if let gifImage = DefaultImageProcessor.default.process(
                                item: .data(imageData),
                                options: .init([])
                            ) {
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
                let image = self.fixImageOrientation(self.photoAsset.localVideoAsset!.image!)
                self.filterHDImageHandler(image: image)
                DispatchQueue.main.async {
                    ProgressHUD.hide(forView: self.view, animated: true)
                    self.requestAssetCompletion(image: image)
                }
            }
        }
    }
    func requestNetworkAsset() {
        #if canImport(Kingfisher)
        let loadingView = ProgressHUD.showLoading(addedTo: view, animated: true)
        photoAsset.getNetworkImage(urlType: .original, filterEditor: true) { (receiveSize, totalSize) in
            let progress = Double(receiveSize) / Double(totalSize)
            if progress > 0 {
                loadingView?.updateText(text: "图片下载中".localized + "(" + String(Int(progress * 100)) + "%)")
            }
        } resultHandler: { [weak self] (image) in
            guard let self = self else { return }
            if var image = image {
                DispatchQueue.global().async {
                    image = self.fixImageOrientation(image)
                    self.filterHDImageHandler(image: image)
                    DispatchQueue.main.async {
                        ProgressHUD.hide(forView: self.view, animated: true)
                        self.requestAssetCompletion(image: image)
                    }
                }
            }else {
                ProgressHUD.hide(forView: self.view, animated: true)
                PhotoTools.showConfirm(
                    viewController: self,
                    title: "提示".localized,
                    message: "图片获取失败!".localized,
                    actionTitle: "确定".localized
                ) { (alertAction) in
                    self.didBackClick()
                }
            }
        }
        #endif
    }
    
    func requestAssetData() {
        photoAsset.requestImageData(
            filterEditor: true,
            iCloudHandler: nil,
            progressHandler: nil
        ) { [weak self] asset, result in
            guard let self = self else { return }
            switch result {
            case .success(let dataResult):
                guard var image = UIImage(data: dataResult.imageData) else {
                    ProgressHUD.hide(forView: self.view, animated: true)
                    self.requestAssetFailure(isICloud: false)
                    return
                }
                if dataResult.imageData.count > 3000000,
                   let sImage = image.scaleSuitableSize() {
                    image = sImage
                }
                DispatchQueue.global().async {
                    image = self.fixImageOrientation(image)
                    self.filterHDImageHandler(image: image)
                    DispatchQueue.main.async {
                        ProgressHUD.hide(forView: self.view, animated: true)
                        self.requestAssetCompletion(image: image)
                    }
                }
            case .failure(let error):
                ProgressHUD.hide(forView: self.view, animated: true)
                if let inICloud = error.info?.inICloud {
                    self.requestAssetFailure(isICloud: inICloud)
                }else {
                    self.requestAssetFailure(isICloud: false)
                }
            }
        }
    }
    
    func requestAssetURL() {
        photoAsset.requestAssetImageURL(
            filterEditor: true
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                DispatchQueue.global().async {
                    let imageURL = response.url
                    #if canImport(Kingfisher)
                    if self.photoAsset.isGifAsset == true,
                       let imageData = try? Data.init(contentsOf: imageURL) {
                        if let gifImage = DefaultImageProcessor.default.process(
                            item: .data(imageData),
                            options: .init([])
                        ) {
                            self.filterHDImageHandler(image: gifImage)
                            DispatchQueue.main.async {
                                ProgressHUD.hide(forView: self.view, animated: true)
                                self.requestAssetCompletion(image: gifImage)
                            }
                            return
                        }
                    }
                    #endif
                    if var image = UIImage.init(contentsOfFile: imageURL.path)?.scaleSuitableSize() {
                        image = self.fixImageOrientation(image)
                        self.filterHDImageHandler(image: image)
                        DispatchQueue.main.async {
                            ProgressHUD.hide(forView: self.view, animated: true)
                            self.requestAssetCompletion(image: image)
                        }
                        return
                    }
                }
            case .failure(_):
                ProgressHUD.hide(forView: self.view, animated: true)
                self.requestAssetFailure(isICloud: false)
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
                self.requestAssetFailure(isICloud: false)
            }
        }
    }
    #endif
    
    func requestAssetCompletion(image: UIImage) {
        if !imageInitializeCompletion {
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
            imageInitializeCompletion = true
        }
        setFilterImage()
        setImage(image)
    }
    func requestAssetFailure(isICloud: Bool) {
        ProgressHUD.hide(forView: view, animated: true)
        let text = isICloud ? "iCloud同步失败".localized : "图片获取失败!".localized
        PhotoTools.showConfirm(
            viewController: self,
            title: "提示".localized,
            message: text.localized,
            actionTitle: "确定".localized
        ) { (alertAction) in
            self.didBackClick()
        }
    }
    func fixImageOrientation(_ image: UIImage) -> UIImage {
        var image = image
        if image.imageOrientation != .up,
           let nImage = image.normalizedImage() {
            image = nImage
        }
        return image
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
        var hasMosaic = false
        var hasFilter = false
        for option in config.toolView.toolOptions {
            if option.type == .filter {
                hasFilter = true
            }else if option.type == .mosaic {
                hasMosaic = true
            }
        }
        var value: Float = 0
        if hasFilter {
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
        }
        if let filter = editResult?.editedData.filter, hasFilter {
            var newImage: UIImage?
            if !config.filter.infos.isEmpty {
                let info = config.filter.infos[filter.sourceIndex]
                newImage = info.filterHandler(thumbnailImage, image, value, .touchUpInside)
            }
            if let newImage = newImage {
                filterHDImage = newImage
                if hasMosaic {
                    mosaicImage = newImage.mosaicImage(level: config.mosaic.mosaicWidth)
                }
            }
        }else {
            if hasMosaic {
                mosaicImage = thumbnailImage.mosaicImage(level: config.mosaic.mosaicWidth)
            }
        }
        if hasFilter {
            filterImage = image.scaleToFillSize(size: CGSize(width: 80, height: 80), equalRatio: true)
        }
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
