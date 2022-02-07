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
            imageView.imageResizerView.hasFilter = false
            imageView.updateImage(image)
            imageView.setMosaicOriginalImage(mosaicImage)
            return
        }
        imageView.imageResizerView.hasFilter = true
//        ProgressHUD.showLoading(addedTo: view, animated: true)
        let value = filterView.sliderView.value
        let lastImage = imageView.image
        DispatchQueue.global().async {
            let filterInfo = self.config.filter.infos[atItem]
            if let ciImage = self.thumbnailImage.ci_Image,
               let newImage = filterInfo.filterHandler(ciImage, lastImage, value, .touchUpInside)?.image {
                let mosaicImage = newImage.mosaicImage(level: self.config.mosaic.mosaicWidth)
                DispatchQueue.main.sync {
//                    ProgressHUD.hide(forView: self.view, animated: true)
                    self.imageView.updateImage(newImage)
                    self.imageView.setMosaicOriginalImage(mosaicImage)
                }
            }else {
                DispatchQueue.main.sync {
//                    ProgressHUD.hide(forView: self.view, animated: true)
                    ProgressHUD.showWarning(addedTo: self.view, text: "设置失败!".localized, animated: true, delayHide: 1.5)
                }
            }
        }
    }
    func filterView(_ filterView: PhotoEditorFilterView,
                    didChanged value: Float) {
        let filterInfo = config.filter.infos[filterView.currentSelectedIndex - 1]
        if let ciImage = thumbnailImage.ci_Image,
           let newImage = filterInfo.filterHandler(ciImage, imageView.image, value, .valueChanged)?.image {
            imageView.updateImage(newImage)
            if mosaicToolView.canUndo {
                let mosaicImage = newImage.mosaicImage(level: config.mosaic.mosaicWidth)
                imageView.setMosaicOriginalImage(mosaicImage)
            }
        }
    }
    func filterView(_ filterView: PhotoEditorFilterView, touchUpInside value: Float) {
        let filterInfo = config.filter.infos[filterView.currentSelectedIndex - 1]
        if let ciImage = thumbnailImage.ci_Image,
           let newImage = filterInfo.filterHandler(ciImage, imageView.image, value, .touchUpInside)?.image {
            imageView.updateImage(newImage)
            let mosaicImage = newImage.mosaicImage(level: config.mosaic.mosaicWidth)
            imageView.setMosaicOriginalImage(mosaicImage)
        }
    }
}
