//
//  PhotoEditorViewController+Filter.swift
//  HXPHPicker
//
//  Created by Slience on 2021/9/16.
//

import UIKit

extension PhotoEditorViewController: PhotoEditorFilterViewDelegate {
    func filterView(shouldSelectFilter filterView: PhotoEditorFilterView) -> Bool {
        true
    }
    
    func filterView(
        _ filterView: PhotoEditorFilterView,
        didSelected filter: PhotoEditorFilter,
        atItem: Int
    ) {
        if filter.isOriginal {
            imageView.imageResizerView.filter = nil
            imageView.updateImage(image)
            imageView.setMosaicOriginalImage(mosaicImage)
            return
        }
        imageView.imageResizerView.filter = filter
        ProgressHUD.showLoading(addedTo: view, animated: true)
        let value = filterView.sliderView.value
        let lastImage = imageView.image
        DispatchQueue.global().async {
            let filterInfo = self.config.filter.infos[atItem]
            if let newImage = filterInfo.filterHandler(self.thumbnailImage, lastImage, value, .touchUpInside) {
                let mosaicImage = newImage.mosaicImage(level: self.config.mosaic.mosaicWidth)
                DispatchQueue.main.sync {
                    ProgressHUD.hide(forView: self.view, animated: true)
                    self.imageView.updateImage(newImage)
                    self.imageView.imageResizerView.filterValue = value
                    self.imageView.setMosaicOriginalImage(mosaicImage)
                }
            }else {
                DispatchQueue.main.sync {
                    ProgressHUD.hide(forView: self.view, animated: true)
                    ProgressHUD.showWarning(addedTo: self.view, text: "设置失败!".localized, animated: true, delayHide: 1.5)
                }
            }
        }
    }
    func filterView(_ filterView: PhotoEditorFilterView,
                    didChanged value: Float) {
        let filterInfo = config.filter.infos[filterView.currentSelectedIndex - 1]
        if let newImage = filterInfo.filterHandler(thumbnailImage, imageView.image, value, .valueChanged) {
            imageView.updateImage(newImage)
            imageView.imageResizerView.filterValue = value
            if mosaicToolView.canUndo {
                let mosaicImage = newImage.mosaicImage(level: config.mosaic.mosaicWidth)
                imageView.setMosaicOriginalImage(mosaicImage)
            }
        }
    }
    func filterView(_ filterView: PhotoEditorFilterView, touchUpInside value: Float) {
        let filterInfo = config.filter.infos[filterView.currentSelectedIndex - 1]
        if let newImage = filterInfo.filterHandler(thumbnailImage, imageView.image, value, .touchUpInside) {
            imageView.updateImage(newImage)
            imageView.imageResizerView.filterValue = value
            let mosaicImage = newImage.mosaicImage(level: config.mosaic.mosaicWidth)
            imageView.setMosaicOriginalImage(mosaicImage)
        }
    }
}
