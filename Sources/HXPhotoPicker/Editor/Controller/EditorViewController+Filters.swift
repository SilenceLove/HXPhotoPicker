//
//  EditorViewController+Filters.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/21.
//

import UIKit

extension EditorViewController: EditorFiltersViewDelegate {
    func filterView(shouldSelectFilter filterView: EditorFiltersView) -> Bool {
        true
    }
    
    func filterView(_ filterView: EditorFiltersView, didSelected filter: PhotoEditorFilter, atItem: Int) {
        switch selectedAsset.type.contentType {
        case .image:
            var originalImage = selectedOriginalImage
            if !filter.isOriginal {
                originalImage = selectedThumbnailImage
            }
            if filter.isOriginal {
                imageFilter = nil
                imageFilterQueue.cancelAllOperations()
                if filterEditFator.isApply {
                    let operation = BlockOperation()
                    operation.addExecutionBlock { [unowned operation, weak self] in
                        guard let self = self else { return }
                        if operation.isCancelled { return }
                        if let image = originalImage?.ci_Image?.apply(self.filterEditFator),
                           let cgImage = self.imageFilterContext.createCGImage(image, from: image.extent) {
                            let resultImage = UIImage(cgImage: cgImage)
                            if operation.isCancelled { return }
                            DispatchQueue.main.async {
                                self.editorView.updateImage(resultImage)
                            }
                            var mosaicImage: CGImage?
                            if let mosaic_Image = self.selectedMosaicImage {
                                mosaicImage = mosaic_Image
                            }else {
                                if let mosaic_Image = image.applyMosaic(level: self.config.mosaic.mosaicWidth) {
                                    mosaicImage = self.imageFilterContext.createCGImage(
                                        mosaic_Image,
                                        from: mosaic_Image.extent
                                    )
                                }
                            }
                            if let mosaicImage = mosaicImage {
                                if operation.isCancelled { return }
                                DispatchQueue.main.async {
                                    self.editorView.mosaicCGImage = mosaicImage
                                }
                            }
                        }
                    }
                    imageFilterQueue.addOperation(operation)
                    checkFinishButtonState()
                    return
                }
                if let image = originalImage {
                    editorView.updateImage(image)
                    if let mosaicImage = selectedMosaicImage {
                        editorView.mosaicCGImage = mosaicImage
                    }else {
                        let operation = BlockOperation()
                        operation.addExecutionBlock { [unowned operation, weak self] in
                            guard let self = self else { return }
                            if operation.isCancelled { return }
                            if let mosaic_Image = image.ci_Image?.applyMosaic(level: self.config.mosaic.mosaicWidth) {
                                let mosaicCGImage = self.imageFilterContext.createCGImage(
                                    mosaic_Image,
                                    from: mosaic_Image.extent
                                )
                                if operation.isCancelled { return }
                                DispatchQueue.main.async {
                                    self.editorView.mosaicCGImage = mosaicCGImage
                                }
                            }
                        }
                        imageFilterQueue.addOperation(operation)
                    }
                }
                checkFinishButtonState()
                return
            }
            let lastImage = editorView.image
            let filterInfo = config.photo.filter.infos[atItem]
            if let handler = filterInfo.filterHandler {
                imageFilterQueue.cancelAllOperations()
                let operation = BlockOperation()
                operation.addExecutionBlock { [unowned operation, weak self] in
                    guard let self = self else { return }
                    if operation.isCancelled { return }
                    var ciImage = originalImage?.ci_Image
                    if self.filterEditFator.isApply {
                        ciImage = ciImage?.apply(self.filterEditFator)
                    }
                    if let ciImage = ciImage,
                       let newImage = handler(ciImage, lastImage, filter.parameters, false),
                       let cgImage = self.imageFilterContext.createCGImage(newImage, from: newImage.extent) {
                        let image = UIImage(cgImage: cgImage)
                        if operation.isCancelled { return }
                        DispatchQueue.main.async {
                            self.editorView.updateImage(image)
                        }
                        if let mosaicImage = newImage.applyMosaic(level: self.config.mosaic.mosaicWidth) {
                            let mosaicResultImage = self.imageFilterContext.createCGImage(
                                mosaicImage,
                                from: mosaicImage.extent
                            )
                            if operation.isCancelled { return }
                            DispatchQueue.main.async {
                                self.editorView.mosaicCGImage = mosaicResultImage
                            }
                        }
                    }
                }
                imageFilter = filter
                imageFilterQueue.addOperation(operation)
            }
            checkFinishButtonState()
        case .video:
            if editorView.isVideoPlaying {
                isStartFilterParameterTime = nil
            }else {
                isStartFilterParameterTime = editorView.videoPlayTime
            }
            if filter.isOriginal {
                videoFilter = nil
                videoFilterInfo = nil
                adjustmentVideoFilter()
                checkFinishButtonState()
                return
            }
            videoFilterInfo = config.video.filter.infos[atItem]
            videoFilter = .init(
                index: atItem,
                identifier: config.video.filter.identifier,
                parameters: filter.parameters
            )
            adjustmentVideoFilter()
            checkFinishButtonState()
        case .unknown:
            break
        }
    }
    
    func filterView(_ filterView: EditorFiltersView, didSelectedParameter filter: PhotoEditorFilter, at index: Int) {
        filterParameterView.type = .filter
        filterParameterView.title = filter.filterName.localized
        filterParameterView.models = filter.parameters
        showFilterParameterView()
    }
    
    func showFilterParameterView() {
        filtersView.reloadData()
        isShowFilterParameter = true
        UIView.animate(withDuration: 0.2) {
            self.updateFilterParameterViewFrame()
        }
    }
    func hideFilterParameterView() {
        isShowFilterParameter = false
        UIView.animate(withDuration: 0.2) {
            self.updateFilterParameterViewFrame()
        }
    }
}

extension EditorViewController: EditorFilterParameterViewDelegate {
    func filterParameterView(
        didStart filterParameterView: EditorFilterParameterView
    ) {
        isStartFilterParameterTime = editorView.videoPlayTime
    }
    func filterParameterView(
        didEnded filterParameterView: EditorFilterParameterView
    ) {
        isStartFilterParameterTime = nil
    }
    func filterParameterView(
        _ filterParameterView: EditorFilterParameterView,
        didChanged model: PhotoEditorFilterParameterInfo
    ) {
        let index = filtersView.currentSelectedIndex
        switch filterParameterView.type {
        case .filter:
            if index < 0 {
                return
            }
            let filter = filtersView.filters[index]
            if filter.sourceIndex != index - 1 {
                filter.sourceIndex = index - 1
            }
            filtersView.reloadData()
            switch selectedAsset.type.contentType {
            case .image:
                let filterInfo = config.photo.filter.infos[index - 1]
                if let handler = filterInfo.filterHandler {
                    let originalImage = selectedThumbnailImage
                    let lastImage = self.editorView.image
                    var ciImage = originalImage?.ci_Image
                    imageFilterQueue.cancelAllOperations()
                    let operation = BlockOperation()
                    operation.addExecutionBlock { [unowned operation, weak self] in
                        guard let self = self else { return }
                        if operation.isCancelled { return }
                        if self.filterEditFator.isApply {
                            ciImage = ciImage?.apply(self.filterEditFator)
                        }
                        if let ciImage = ciImage,
                           let newImage = handler(ciImage, lastImage, filter.parameters, false),
                           let cgImage = self.imageFilterContext.createCGImage(newImage, from: newImage.extent) {
                            let resultImage = UIImage(cgImage: cgImage)
                            if operation.isCancelled { return }
                            DispatchQueue.main.async {
                                self.editorView.updateImage(resultImage)
                            }
                            var mosaicImage: CIImage?
                            if self.mosaicToolView.canUndo {
                                mosaicImage = newImage.applyMosaic(level: self.config.mosaic.mosaicWidth)
                            }
                            if let mosaicImage = mosaicImage {
                                let mosaicResultImage = self.imageFilterContext.createCGImage(
                                    mosaicImage,
                                    from: mosaicImage.extent
                                )
                                DispatchQueue.main.async {
                                    self.editorView.mosaicCGImage = mosaicResultImage
                                }
                            }
                        }
                    }
                    imageFilterQueue.addOperation(operation)
                }
                imageFilter = filter
            case .video:
                videoFilter = .init(
                    index: index - 1,
                    identifier: config.video.filter.identifier,
                    parameters: filter.parameters
                )
                videoFilterInfo = config.video.filter.infos[index - 1]
                adjustmentVideoFilter()
            case .unknown:
                break
            }
        case .edit:
            filterEditView.reloadData()
            var brightness: Float = 0
            var contrast: Float = 1
            var exposure: Float = 0
            var saturation: Float = 1
            var highlights: Float = 0
            var shadows: Float = 0
            var warmth: Float = 0
            var sharpen: Float = 0
            var vignette: Float = 0
            for model in filterEditView.models {
                guard let value = model.parameters.first?.value else {
                    break
                }
                switch model.type {
                case .brightness:
                    brightness = 0.5 * value
                case .contrast:
                    contrast = 1 + value
                case .exposure:
                    exposure = value * 5
                case .saturation:
                    saturation = 1 + value
                case .highlights:
                    highlights = value
                case .shadows:
                    shadows = value
                case .warmth:
                    warmth = value
                case .vignette:
                    vignette = value * 2
                case .sharpen:
                    sharpen = value
                }
            }
            filterEditFator.brightness = brightness
            filterEditFator.contrast = contrast
            filterEditFator.exposure = exposure
            filterEditFator.saturation = saturation
            filterEditFator.highlights = highlights
            filterEditFator.shadows = shadows
            filterEditFator.warmth = warmth
            filterEditFator.sharpen = sharpen
            filterEditFator.vignette = vignette
            
            switch selectedAsset.contentType {
            case .image:
                applyImageFilterParameter(index)
            case .video:
                adjustmentVideoFilter()
            case .unknown:
                break
            }
        }
        checkFinishButtonState()
    }
    
    func applyImageFilterParameter(_ index: Int) {
        let originalImage = selectedThumbnailImage
        var ciImage = originalImage?.ci_Image
        let lastImage = editorView.image
        imageFilterQueue.cancelAllOperations()
        let operation = BlockOperation()
        operation.addExecutionBlock { [unowned operation, weak self] in
            guard let self = self else { return }
            if operation.isCancelled { return }
            if self.filterEditFator.isApply {
                ciImage = ciImage?.apply(self.filterEditFator)
            }
            var filter: PhotoEditorFilter?
            var filterInfo: PhotoEditorFilterInfo?
            if index > 0 {
                filter = self.filtersView.filters[index]
                filterInfo = self.config.photo.filter.infos[index - 1]
            }else {
                if let _filter = self.imageFilter {
                    filter = _filter
                    if _filter.identifier == "hx_editor_default" {
                        filterInfo = self.config.photo.filter.infos[_filter.sourceIndex]
                    }else {
                        filterInfo = self.delegate?.editorViewcOntroller(
                            self,
                            fetchLastImageFilterInfo: _filter
                        )
                    }
                }
            }
            
            if let filter = filter, let handler = filterInfo?.filterHandler {
                if let ciImage = ciImage,
                   let newImage = handler(ciImage, lastImage, filter.parameters, false),
                   let cgImage = self.imageFilterContext.createCGImage(newImage, from: newImage.extent) {
                    let resultImage = UIImage(cgImage: cgImage)
                    if operation.isCancelled { return }
                    DispatchQueue.main.async {
                        self.editorView.updateImage(resultImage)
                    }
                    var mosaicImage: CGImage?
                    if self.mosaicToolView.canUndo {
                        if let mosaic_Image = newImage.applyMosaic(level: self.config.mosaic.mosaicWidth) {
                            mosaicImage = self.imageFilterContext.createCGImage(
                                mosaic_Image,
                                from: mosaic_Image.extent
                            )
                        }
                    }
                    if let mosaicImage = mosaicImage {
                        if operation.isCancelled { return }
                        DispatchQueue.main.async {
                            self.editorView.mosaicCGImage = mosaicImage
                        }
                    }
                }
            }else {
                if !self.filterEditFator.isApply {
                    DispatchQueue.main.async {
                        self.editorView.updateImage(self.selectedOriginalImage)
                    }
                    return
                }
                if let ciImage = ciImage,
                   let cgImage = self.imageFilterContext.createCGImage(ciImage, from: ciImage.extent) {
                    let resultImage = UIImage(cgImage: cgImage)
                    if operation.isCancelled { return }
                    DispatchQueue.main.async {
                        self.editorView.updateImage(resultImage)
                    }
                    var mosaicImage: CGImage?
                    if self.mosaicToolView.canUndo {
                        if let mosaic_Image = ciImage.applyMosaic(level: self.config.mosaic.mosaicWidth) {
                            mosaicImage = self.imageFilterContext.createCGImage(
                                mosaic_Image,
                                from: mosaic_Image.extent
                            )
                        }
                    }
                    if let mosaicImage = mosaicImage {
                        if operation.isCancelled { return }
                        DispatchQueue.main.async {
                            self.editorView.mosaicCGImage = mosaicImage
                        }
                    }
                }
            }
        }
        imageFilterQueue.addOperation(operation)
    }
    
    func adjustmentVideoFilter() {
        if !editorView.isVideoPlaying {
            guard let currentTime = isStartFilterParameterTime else {
                return
            }
            editorView.seekVideo(
                to: .init(seconds: currentTime.seconds + 0.1, preferredTimescale: 1000)
            ) { [weak self] in
                if $0 {
                    self?.editorView.seekVideo(to: currentTime)
                }
            }
        }
    }
}

extension EditorViewController: EditorFilterEditViewDelegate {
    func filterEditView(_ filterEditView: EditorFilterEditView, didSelected editModel: EditorFilterEditModel) {
        filterParameterView.type = .edit(type: editModel.type)
        filterParameterView.title = editModel.type.title
        filterParameterView.models = editModel.parameters
        showFilterParameterView()
    }
}
