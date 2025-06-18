//
//  EditorViewController+LoadAsset.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/20.
//

import UIKit
import AVFoundation

extension EditorViewController {
    
    enum LoadAssetStatus {
        case loadding(Bool = false)
        case succeed(EditorAsset.AssetType)
        case failure
    }
    
    func initAsset() {
        let asset = selectedAsset
        initAssetType(asset.type)
    }
    func initAssetType(_ type: EditorAsset.AssetType) {
        let viewSize = UIDevice.screenSize
        switch type {
        case .image(let image):
            if !isTransitionCompletion {
                loadAssetStatus = .succeed(.image(image))
                return
            }
            editorView.setImage(image)
            DispatchQueue.global().async {
                self.loadThumbnailImage(image, viewSize: viewSize)
            }
            loadCompletion()
            loadLastEditedData()
        case .imageData(let imageData):
            if !isTransitionCompletion {
                loadAssetStatus = .succeed(.imageData(imageData))
                return
            }
            editorView.isHEICImage = imageData.isHEIC
            editorView.setImageData(imageData)
            let image = self.editorView.image
            DispatchQueue.global().async {
                self.loadThumbnailImage(image, viewSize: viewSize)
            }
            loadCompletion()
            loadLastEditedData()
        case .video(let url):
            if !isTransitionCompletion {
                loadAssetStatus = .succeed(.video(url))
                return
            }
            let avAsset = AVAsset(url: url)
            let image = avAsset.getImage(at: 0.1)
            editorView.setAVAsset(avAsset, coverImage: image)
            editorView.loadVideo(isPlay: false)
            loadCompletion()
            loadLastEditedData()
        case .videoAsset(let avAsset):
            if !isTransitionCompletion {
                loadAssetStatus = .succeed(.videoAsset(avAsset))
                return
            }
            let image = avAsset.getImage(at: 0.1)
            editorView.setAVAsset(avAsset, coverImage: image)
            editorView.loadVideo(isPlay: false)
            loadCompletion()
            loadLastEditedData()
        case .networkVideo(let videoURL):
            downloadNetworkVideo(videoURL)
        case .networkImage(let url):
            downloadNetworkImage(url)
        #if HXPICKER_ENABLE_PICKER
        case .photoAsset(let photoAsset):
            loadPhotoAsset(photoAsset)
        #endif
        }
    }
    
    func loadLastEditedData() {
        guard let result = selectedAsset.result else {
            filtersViewDidLoad()
            return
        }
        switch result {
        case .image(let editedResult, let editedData):
            loadFilterEditData(editedData.filterEdit)
            editorView.setAdjustmentData(editedResult.data)
        case .video(let editedResult, let editedData):
            if let music = editedData.music {
                loadMusicData(music, audioInfos: editedResult.data?.audioInfos ?? [])
            }
            loadFilterEditData(editedData.filterEdit)
            editorView.setAdjustmentData(editedResult.data)
            loadVideoCropTimeData(editedData.cropTime)
        }
        loadFilterData()
        if !firstAppear {
            editorView.layoutSubviews()
            checkLastResultState()
        }
        if config.video.isAutoPlay, selectedAsset.contentType == .video {
            DispatchQueue.main.async {
                self.videoControlView.resetLineViewFrsme(at: self.videoControlView.startTime)
                self.editorView.seekVideo(to: self.videoControlView.startTime)
                self.editorView.playVideo()
                if let musicURL = self.selectedMusicURL {
                    switch musicURL {
                    case .network(let url):
                        let key = url.absoluteString
                        let audioTmpURL = PhotoTools.getAudioTmpURL(for: key)
                        if PhotoTools.isCached(forAudio: key) {
                            self.musicPlayer?.play(audioTmpURL)
                            self.musicPlayer?.volume = self.musicVolume
                        }else {
                            self.lastMusicDownloadTask = PhotoManager.shared.downloadTask(
                                with: url,
                                toFile: audioTmpURL
                            ) { [weak self] audioURL, _, _ in
                                guard let self = self, let audioURL = audioURL else { return }
                                self.musicPlayer?.play(audioURL)
                                self.musicPlayer?.volume = self.musicVolume
                            }
                        }
                    default:
                        if let url = musicURL.url {
                            self.musicPlayer?.play(url)
                            self.musicPlayer?.volume = self.musicVolume
                        }
                    }
                }
                if self.isSelectedOriginalSound {
                    self.editorView.videoVolume = CGFloat(self.videoVolume)
                }else {
                    self.editorView.videoVolume = 0
                }
            }
        }
    }
    
    func loadMusicData(_ data: VideoEditedMusic, audioInfos: [EditorStickerAudio]) {
        isSelectedOriginalSound = data.hasOriginalSound
        videoVolume = data.videoSoundVolume
        volumeView.originalVolume = videoVolume
        musicView.originalSoundButton.isSelected = data.hasOriginalSound
        guard let url = data.backgroundMusicURL else {
            volumeView.hasMusic = false
            return
        }
        selectedMusicURL = data.backgroundMusicURL
        musicPlayer = .init()
        data.music?.parseLrc()
        musicPlayer?.music = data.music
        for audioInfo in audioInfos {
            var isSame: Bool = false
            if let musicIdentifier = data.musicIdentifier,
               audioInfo.identifier == musicIdentifier {
                isSame = true
            }
            if audioInfo.url == url || isSame {
                audioInfo.contentsHandler = { [weak self] in
                    guard let self = self,
                          let musicPlayer = self.musicPlayer,
                          let music = musicPlayer.music,
                          musicPlayer.audio == $0 else {
                        return nil
                    }
                    var texts: [EditorStickerAudioText] = []
                    for lyric in music.lyrics {
                        texts.append(.init(text: lyric.lyric, startTime: lyric.startTime, endTime: lyric.endTime))
                    }
                    return .init(time: music.time ?? 0, texts: texts)
                }
                musicPlayer?.audio = audioInfo
                musicView.showLyricButton.isSelected = true
                break
            }
        }
        volumeView.hasMusic = true
        musicView.backgroundButton.isSelected = true
        musicVolume = data.backgroundMusicVolume
        volumeView.musicVolume = musicVolume
    }
    
    func loadFilterEditData(_ data: EditorFilterEditFator?) {
        guard let data = data else {
            return
        }
        for model in filterEditView.models {
            let parameter = model.parameters.first
            switch model.type {
            case .brightness:
                parameter?.value = data.brightness / 0.5
            case .contrast:
                parameter?.value = data.contrast - 1
            case .exposure:
                parameter?.value = data.exposure / 5
            case .saturation:
                parameter?.value = data.saturation - 1
            case .highlights:
                parameter?.value = data.highlights
            case .shadows:
                parameter?.value = data.shadows
            case .warmth:
                parameter?.value = data.warmth
            case .vignette:
                parameter?.value = data.vignette / 2
            case .sharpen:
                parameter?.value = data.sharpen
            }
            if parameter?.value != 0 {
                parameter?.isNormal = false
            }else {
                parameter?.isNormal = true
            }
        }
        filterEditView.reloadData()
        filterEditView.scrollToValue()
        filterEditFator = data
    }
    
    func loadFilterData() {
        guard let result = selectedAsset.result else {
            return
        }
        switch result {
        case .image(_, let editedData):
            loadImageFilterData(editedData.filter)
        case .video(_, let editedData):
            loadVideoFilterData(editedData.filter)
        }
        filtersViewDidLoad()
    }
    
    private func loadImageFilterData(_ filter: PhotoEditorFilter?) {
        var filterInfo: PhotoEditorFilterInfo?
        var selectedIndex: Int = -1
        var selectedParameters: [PhotoEditorFilterParameterInfo] = []
        if let filter = filter {
            if filter.identifier == "hx_editor_default" {
                selectedIndex = filter.sourceIndex + 1
                selectedParameters = filter.parameters
                filterInfo = config.photo.filter.infos[filter.sourceIndex]
            }else {
                filterInfo = delegate?.editorViewcOntroller(self, fetchLastImageFilterInfo: filter)
            }
        }
        let originalImage = selectedOriginalImage
        if let filter = filter, let handler = filterInfo?.filterHandler {
            imageFilter = filter
            let lastImage = editorView.image
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
            imageFilterQueue.addOperation(operation)
            if filtersView.didLoad {
                filtersView.updateFilters(selectedIndex: selectedIndex, selectedParameters: selectedParameters)
            }else {
                filtersView.loadCompletion = {
                    $0.updateFilters(selectedIndex: selectedIndex, selectedParameters: selectedParameters)
                }
            }
        }else {
            if filterEditFator.isApply {
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
                       let cgImage = self.imageFilterContext.createCGImage(ciImage, from: ciImage.extent) {
                        let image = UIImage(cgImage: cgImage)
                        if operation.isCancelled { return }
                        DispatchQueue.main.async {
                            self.editorView.updateImage(image)
                        }
                        if let mosaicImage = ciImage.applyMosaic(level: self.config.mosaic.mosaicWidth) {
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
                imageFilterQueue.addOperation(operation)
                if filtersView.didLoad {
                    filtersView.updateFilters(selectedIndex: selectedIndex, selectedParameters: selectedParameters)
                }else {
                    filtersView.loadCompletion = {
                        $0.updateFilters(selectedIndex: selectedIndex, selectedParameters: selectedParameters)
                    }
                }
            }
        }
    }
    
    private func loadVideoFilterData(_ data: VideoEditorFilter?) {
        guard let data = data else {
            return
        }
        if data.identifier == "hx_editor_default" {
            videoFilterInfo = config.video.filter.infos[data.index]
            videoFilter = data
            if filtersView.didLoad {
                filtersView.updateFilters(
                    selectedIndex: data.index + 1,
                    selectedParameters: data.parameters,
                    isVideo: true
                )
            }else {
                filtersView.loadCompletion = {
                    $0.updateFilters(
                        selectedIndex: data.index + 1,
                        selectedParameters: data.parameters,
                        isVideo: true
                    )
                }
            }
        }else {
            if let filterInfo = delegate?.editorViewcOntroller(self, fetchLastVideoFilterInfo: data) {
                videoFilterInfo = filterInfo
                videoFilter = data
                if filtersView.didLoad {
                    filtersView.updateFilters(selectedIndex: -1, isVideo: true)
                }
            }
        }
    }
    
    func loadCorpSizeData() {
        guard let result = selectedAsset.result else {
            return
        }
        ratioToolView.layoutSubviews()
        rotateScaleView.layoutSubviews()
        func loadData(_ data: EditorCropSizeFator?, isRound: Bool) {
            guard let data = data else {
                return
            }
            ratioToolView.deselected()
            finishRatioIndex = -1
            for (index, aspectRatio) in config.cropSize.aspectRatios.enumerated() {
                if data.isFixedRatio {
                    if aspectRatio.ratio.equalTo(.init(width: -1, height: -1)) || aspectRatio.ratio.equalTo(.zero) {
                        continue
                    }
                    let scale1 = CGFloat(Int(aspectRatio.ratio.width / aspectRatio.ratio.height * 1000)) / 1000
                    let scale2 = CGFloat(Int(data.aspectRatio.width / data.aspectRatio.height * 1000)) / 1000
                    if scale1 == scale2, !isRound {
                        finishRatioIndex = index
                        break
                    }
                }else {
                    if aspectRatio.ratio.equalTo(.zero) {
                        finishRatioIndex = index
                        break
                    }
                }
            }
            DispatchQueue.main.async {
                self.ratioToolView.scrollToIndex(at: self.finishRatioIndex, animated: false)
            }
            if data.angle != 0 {
                finishScaleAngle = data.angle
                lastScaleAngle = data.angle
                rotateScaleView.updateAngle(data.angle)
            }
        }
        DispatchQueue.main.async {
            switch result {
            case .image(let editedResult, let editedData):
                loadData(
                    editedData.cropSize,
                    isRound: editedResult.data?.content.adjustedFactor?.isRoundMask ?? false
                )
            case .video(let editedResult, let editedData):
                loadData(
                    editedData.cropSize,
                    isRound: editedResult.data?.content.adjustedFactor?.isRoundMask ?? false
                )
            }
        }
    }
    
    func loadVideoCropTimeData(_ data: EditorVideoCropTime?) {
        guard let data = data else {
            return
        }
        videoControlInfo = data.controlInfo
        if !firstAppear {
            updateVideoControlInfo()
        }
        controlViewStartEndTime(at: .init(seconds: data.startTime, preferredTimescale: data.preferredTimescale))
        if !firstAppear {
            DispatchQueue.main.async {
                self.updateVideoTimeRange()
            }
        }
    }
    
    func loadVideoControl() {
        let asset = selectedAsset
        switch asset.type {
        case .video(let videoURL):
            videoControlView.layoutSubviews()
            videoControlView.loadData(.init(url: videoURL))
            updateVideoTimeRange()
            isLoadVideoControl = true
        case .networkVideo:
            if let avAsset = editorView.avAsset {
                videoControlView.layoutSubviews()
                videoControlView.loadData(avAsset)
                updateVideoTimeRange()
                isLoadVideoControl = true
            }
        #if HXPICKER_ENABLE_PICKER
        case .photoAsset:
            if let avAsset = editorView.avAsset {
                videoControlView.layoutSubviews()
                videoControlView.loadData(avAsset)
                updateVideoTimeRange()
                isLoadVideoControl = true
            }
        #endif
        default:
            break
        }
    }
    
    func downloadNetworkVideo(_ videoURL: URL) {
        let key = videoURL.absoluteString
        if PhotoTools.isCached(forVideo: key) {
            let localURL = PhotoTools.getVideoCacheURL(for: key)
            if !isTransitionCompletion {
                loadAssetStatus = .succeed(.video(localURL))
                return
            }
            let avAsset = AVAsset(url: localURL)
            let image = avAsset.getImage(at: 0.1)
            editorView.setAVAsset(avAsset, coverImage: image)
            editorView.loadVideo(isPlay: false)
            loadCompletion()
            loadLastEditedData()
            return
        }
        if isTransitionCompletion {
            assetLoadingView = PhotoManager.HUDView.show(with: .textManager.editor.videoLoadTitle.text, delay: 0, animated: true, addedTo: view)
            bringViews()
        }else {
            loadAssetStatus = .loadding(true)
        }
        PhotoManager.shared.downloadTask(
            with: videoURL
        ) { [weak self] (progress, _) in
            if progress > 0 {
                self?.assetLoadingView?.setProgress(.init(progress))
            }
        } completionHandler: { [weak self] (url, error, _) in
            guard let self = self else {
                return
            }
            if let url = url {
                if !self.isTransitionCompletion {
                    self.loadAssetStatus = .succeed(.video(url))
                    return
                }
                #if HXPICKER_ENABLE_PICKER
                if let photoAsset = self.selectedAsset.type.photoAsset {
                    photoAsset.networkVideoAsset?.fileSize = url.fileSize
                }
                #endif
                self.assetLoadingView = nil
                PhotoManager.HUDView.dismiss(delay: 0, animated: false, for: self.view)
                let avAsset = AVAsset(url: url)
                let image = avAsset.getImage(at: 0.1)
                self.editorView.setAVAsset(avAsset, coverImage: image)
                self.editorView.loadVideo(isPlay: false)
                self.loadCompletion()
                self.loadLastEditedData()
            }else {
                if let error = error as NSError?, error.code == NSURLErrorCancelled {
                    return
                }
                if !self.isTransitionCompletion {
                    self.loadAssetStatus = .failure
                    return
                }
                self.assetLoadingView = nil
                PhotoManager.HUDView.dismiss(delay: 0, animated: false, for: self.view)
                self.loadFailure()
            }
        }
    }
    
    func downloadNetworkImage(_ url: URL) {
        if isTransitionCompletion {
            assetLoadingView = PhotoManager.HUDView.show(with: nil, delay: 0, animated: true, addedTo: view)
        }else {
            loadAssetStatus = .loadding(true)
        }
        PhotoManager.ImageView.download(with: .init(downloadURL: url), options: nil) { [weak self] progress in
            if progress > 0 {
                self?.assetLoadingView?.setText(.textManager.editor.photoLoadTitle.text)
                self?.assetLoadingView?.setProgress(.init(progress))
            }
        } completionHandler: { [weak self] in
            guard let self = self else { return }
            self.assetLoadingView = nil
            switch $0 {
            case .success(let result):
                if !self.isTransitionCompletion {
                    if let image = result.image {
                        self.loadAssetStatus = .succeed(.image(image))
                    }else if let imageData = result.imageData {
                        self.loadAssetStatus = .succeed(.imageData(imageData))
                    }
                    return
                }
                if let image  = result.image {
                    self.editorView.setImage(image)
                }else if let imageData = result.imageData {
                    self.editorView.setImageData(imageData)
                }
                self.loadCompletion()
                self.loadLastEditedData()
                let viewSize = UIDevice.screenSize
                DispatchQueue.global().async {
                    if let image = result.image {
                        self.loadThumbnailImage(image, viewSize: viewSize)
                    }else if let imageData = result.imageData, let image = UIImage(data: imageData) {
                        self.loadThumbnailImage(image, viewSize: viewSize)
                    }
                }
                PhotoManager.HUDView.dismiss(delay: 0, animated: true, for: self.view)
            case .failure:
                if !self.isTransitionCompletion {
                    self.loadAssetStatus = .failure
                    return
                }
                self.loadFailure(message: .textManager.editor.photoLoadFailedAlertMessage.text)
            }
        }
    }
    
    #if HXPICKER_ENABLE_PICKER
    func loadPhotoAsset(_ photoAsset: PhotoAsset) {
        if photoAsset.mediaType == .photo {
            if photoAsset.isLocalAsset {
                if let localLivePhoto = photoAsset.localLivePhoto,
                   !localLivePhoto.imageURL.isFileURL {
                    requestNetworkAsset()
                    return
                }
                requestLocalAsset()
            }else if photoAsset.isNetworkAsset {
                requestNetworkAsset()
            } else {
                if photoAsset.phAsset != nil && !photoAsset.isGifAsset {
                    requestAssetImage()
                    return
                }
                requestAssetURL()
            }
        }else {
            requestAVAsset()
        }
    }
    
    func requestLocalAsset() {
        guard let photoAsset = selectedAsset.type.photoAsset else {
            return
        }
        if isTransitionCompletion {
            PhotoManager.HUDView.show(with: nil, delay: 0, animated: true, addedTo: view)
        }
        let viewSize = UIDevice.screenSize
        DispatchQueue.global().async {
            if photoAsset.mediaType == .photo {
                var image: UIImage?
                if let img = photoAsset.localImageAsset?.image?.normalizedImage() {
                    image = img
                }else if let localLivePhoto = photoAsset.localLivePhoto,
                         localLivePhoto.imageURL.isFileURL,
                         let img = UIImage(contentsOfFile: localLivePhoto.imageURL.path)?.normalizedImage() {
                    image = img
                }
                var imageData: Data?
                if photoAsset.mediaSubType.isGif {
                    if let data = photoAsset.localImageAsset?.imageData {
                        imageData = data
                    }else if let imageURL = photoAsset.localImageAsset?.imageURL,
                             let data = try? Data(contentsOf: imageURL) {
                        imageData = data
                    }
                }
                DispatchQueue.main.async {
                    if let imageData {
                        if !self.isTransitionCompletion {
                            self.loadAssetStatus = .succeed(.imageData(imageData))
                            return
                        }
                        PhotoManager.HUDView.dismiss(delay: 0, animated: true, for: self.view)
                        self.editorView.setImageData(imageData)
                        self.loadCompletion()
                        self.loadLastEditedData()
                        DispatchQueue.global().async {
                            self.loadThumbnailImage(.init(data: imageData), viewSize: viewSize)
                        }
                    }else if let image {
                        if !self.isTransitionCompletion {
                            self.loadAssetStatus = .succeed(.image(image))
                            return
                        }
                        PhotoManager.HUDView.dismiss(delay: 0, animated: true, for: self.view)
                        self.editorView.setImage(image)
                        self.loadCompletion()
                        self.loadLastEditedData()
                        DispatchQueue.global().async {
                            self.loadThumbnailImage(image, viewSize: viewSize)
                        }
                    }else {
                        if !self.isTransitionCompletion {
                            self.loadAssetStatus = .failure
                            return
                        }
                        PhotoManager.HUDView.dismiss(delay: 0, animated: true, for: self.view)
                        self.loadFailure(message: .textManager.editor.photoLoadFailedAlertMessage.text)
                    }
                }
            }else {
                let image = photoAsset.localVideoAsset?.image
                DispatchQueue.main.async {
                    if !self.isTransitionCompletion {
                        self.loadAssetStatus = .succeed(.image(image!))
                        return
                    }
                    self.editorView.setImage(image)
                    self.loadCompletion()
                    self.loadLastEditedData()
                    let viewSize = UIDevice.screenSize
                    DispatchQueue.global().async {
                        self.loadThumbnailImage(image, viewSize: viewSize)
                    }
                    PhotoManager.HUDView.dismiss(delay: 0, animated: true, for: self.view)
                }
            }
        }
    }
    func requestNetworkAsset() {
        guard let photoAsset = selectedAsset.type.photoAsset else {
            return
        }
        if isTransitionCompletion {
            assetLoadingView = PhotoManager.HUDView.show(with: nil, delay: 0, animated: true, addedTo: view)
        }else {
            loadAssetStatus = .loadding(true)
        }
        photoAsset.getNetworkImage(urlType: .original, filterEditor: true) { [weak self] progress in
            if progress > 0 {
                self?.assetLoadingView?.setText(.textManager.editor.photoLoadTitle.text)
                self?.assetLoadingView?.setProgress(progress)
            }
        } resultHandler: { [weak self] image, imageData in
            guard let self = self else { return }
            self.assetLoadingView = nil
            if image != nil || imageData != nil {
                if !self.isTransitionCompletion {
                    if let imageData {
                        self.loadAssetStatus = .succeed(.imageData(imageData))
                    }else if let image {
                        self.loadAssetStatus = .succeed(.image(image))
                    }
                    return
                }
                PhotoManager.HUDView.dismiss(delay: 0, animated: true, for: self.view)
                if let imageData {
                    self.editorView.setImageData(imageData)
                }else if let image {
                    self.editorView.setImage(image)
                }
                self.loadCompletion()
                self.loadLastEditedData()
                let viewSize = UIDevice.screenSize
                DispatchQueue.global().async {
                    self.loadThumbnailImage(image, viewSize: viewSize)
                }
            }else {
                if !self.isTransitionCompletion {
                    self.loadAssetStatus = .failure
                    return
                }
                PhotoManager.HUDView.dismiss(delay: 0, animated: true, for: self.view)
                self.loadFailure(message: .textManager.editor.photoLoadFailedAlertMessage.text)
            }
        }
    }
    
    func requestAssetImage() {
        guard let photoAsset = selectedAsset.type.photoAsset else {
            return
        }
        if isTransitionCompletion {
            assetLoadingView = PhotoManager.HUDView.show(with: nil, delay: 0, animated: true, addedTo: view)
            bringViews()
        }else {
            loadAssetStatus = .loadding(true)
        }
        assetRequestID = photoAsset.requestImageData(
            filterEditor: true,
            iCloudHandler: { [weak self] _, requestID in
                self?.assetRequestID = requestID
                self?.assetLoadingView?.setText(.textManager.editor.iCloudSyncHudTitle.text + "...")
            },
            progressHandler: { [weak self] _, progress in
                if progress > 0 {
                    DispatchQueue.main.async {
                        self?.assetLoadingView?.setProgress(CGFloat(progress))
                    }
                }
            },
            resultHandler: { [weak self] asset, result in
                guard let self else { return }
                self.assetLoadingView = nil
                DispatchQueue.main.async {
                    switch result {
                    case .success(let dataResult):
                        if AssetManager.assetDownloadFinined(for: dataResult.info) || AssetManager.assetCancelDownload(for: dataResult.info) {
                            let image = UIImage(data: dataResult.imageData)
                            guard let image = image else {
                                self.loadAssetStatus = .failure
                                PhotoManager.HUDView.dismiss(delay: 0, animated: true, for: self.view)
                                return
                            }
                            if let dataUTI = dataResult.dataUTI {
                                self.editorView.isHEICImage = dataUTI.contains("heic")
                                self.editorView.isJPEGImage = dataUTI.contains("jpeg")
                            }
                            if !self.isTransitionCompletion {
                                self.loadAssetStatus = .succeed(.image(image))
                                return
                            }
                            self.editorView.setImage(image)
                            self.loadCompletion()
                            self.loadLastEditedData()
                            let viewSize = UIDevice.screenSize
                            DispatchQueue.global().async {
                                self.loadThumbnailImage(image, viewSize: viewSize)
                            }
                            PhotoManager.HUDView.dismiss(delay: 0, animated: true, for: self.view)
                        }
                    case .failure(let error):
                        if !self.isTransitionCompletion {
                            self.loadAssetStatus = .failure
                            return
                        }
                        PhotoManager.HUDView.dismiss(delay: 0, animated: true, for: self.view)
                        if let inICloud = error.info?.inICloud {
                            self.loadFailure(message: inICloud ? .textManager.editor.iCloudSyncFailedAlertMessage.text : .textManager.editor.photoLoadFailedAlertMessage.text)
                        }else {
                            self.loadFailure(message: .textManager.editor.photoLoadFailedAlertMessage.text)
                        }
                        return
                    }
                }
            }
        )
    }
    
    func requestAssetURL() {
        guard let photoAsset = selectedAsset.type.photoAsset else {
            return
        }
        if isTransitionCompletion {
            PhotoManager.HUDView.show(with: nil, delay: 0, animated: true, addedTo: view)
            bringViews()
        }else {
            loadAssetStatus = .loadding(true)
        }
        photoAsset.requestAssetImageURL(
            filterEditor: true
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                DispatchQueue.global().async {
                    let imageURL = response.url
                    if photoAsset.isGifAsset == true,
                       let imageData = try? Data(contentsOf: imageURL) {
                        DispatchQueue.main.async {
                            if !self.isTransitionCompletion {
                                self.loadAssetStatus = .succeed(.imageData(imageData))
                                return
                            }
                            self.editorView.setImageData(imageData)
                            self.loadCompletion()
                            self.loadLastEditedData()
                            let viewSize = UIDevice.screenSize
                            DispatchQueue.global().async {
                                self.loadThumbnailImage(.init(contentsOfFile: imageURL.path), viewSize: viewSize)
                            }
                            PhotoManager.HUDView.dismiss(delay: 0, animated: true, for: self.view)
                        }
                        return
                    }
                    if let image = UIImage(contentsOfFile: imageURL.path)?.scaleSuitableSize()?.normalizedImage() {
                        DispatchQueue.main.async {
                            if !self.isTransitionCompletion {
                                self.loadAssetStatus = .succeed(.image(image))
                                return
                            }
                            self.editorView.setImage(image)
                            self.loadCompletion()
                            self.loadLastEditedData()
                            let viewSize = UIDevice.screenSize
                            DispatchQueue.global().async {
                                self.loadThumbnailImage(image, viewSize: viewSize)
                            }
                            PhotoManager.HUDView.dismiss(delay: 0, animated: true, for: self.view)
                        }
                        return
                    }
                }
            case .failure:
                if !self.isTransitionCompletion {
                    self.loadAssetStatus = .failure
                    return
                }
                PhotoManager.HUDView.dismiss(delay: 0, animated: true, for: self.view)
                self.loadFailure(message: .textManager.editor.photoLoadFailedAlertMessage.text)
            }
        }
    }
    func requestAVAsset() {
        guard let photoAsset = selectedAsset.type.photoAsset else {
            return
        }
        if photoAsset.isNetworkAsset {
            if let url = photoAsset.networkVideoAsset?.videoURL {
                downloadNetworkVideo(url)
            }
            return
        }
        if isTransitionCompletion {
            assetLoadingView = PhotoManager.HUDView.show(with: nil, delay: 0, animated: true, addedTo: view)
            bringViews()
        }else {
            loadAssetStatus = .loadding(true)
        }
        assetRequestID = photoAsset.requestAVAsset(
            filterEditor: true,
            deliveryMode: .highQualityFormat
        ) { [weak self] (_, requestID) in
            self?.assetRequestID = requestID
            self?.assetLoadingView?.setText(.textManager.editor.iCloudSyncHudTitle.text + "...")
        } progressHandler: { [weak self] (_, progress) in
            if progress > 0 {
                self?.assetLoadingView?.setProgress(CGFloat(progress))
            }
        } success: { [weak self] _, avAsset, _ in
            guard let self = self else { return }
            self.assetLoadingView = nil
            if !self.isTransitionCompletion {
                self.loadAssetStatus = .succeed(.videoAsset(avAsset))
                return
            }
            PhotoManager.HUDView.dismiss(delay: 0, animated: false, for: self.view)
            let image = avAsset.getImage(at: 0.1)
            self.editorView.setAVAsset(avAsset, coverImage: image)
            self.editorView.loadVideo(isPlay: false)
            self.loadCompletion()
            self.loadLastEditedData()
        } failure: { [weak self] (_, info, _) in
            guard let self = self else { return }
            self.assetLoadingView = nil
            if !self.isTransitionCompletion {
                self.loadAssetStatus = .failure
                return
            }
            PhotoManager.HUDView.dismiss(delay: 0, animated: false, for: self.view)
            guard let info = info else {
                self.loadFailure(message: .textManager.editor.videoLoadFailedAlertMessage.text)
                return
            }
            self.loadFailure(message: info.inICloud ? .textManager.editor.iCloudSyncFailedAlertMessage.text : .textManager.editor.videoLoadFailedAlertMessage.text)
        }
    }
    #endif
    
    func bringViews() {
        view.bringSubviewToFront(cancelButton)
        view.bringSubviewToFront(finishButton)
        view.bringSubviewToFront(filterParameterView)
    }
    
    func loadThumbnailImage(_ image: UIImage?, viewSize: CGSize) {
        guard let image = image else {
            selectedThumbnailImage = selectedOriginalImage
            return
        }
        var maxSize: CGFloat = max(viewSize.width, viewSize.height)
        DispatchQueue.main.sync {
            if !view.size.equalTo(.zero) {
                maxSize = min(view.width, view.height) * 2
            }
        }
        let maxLength = max(image.width, image.height)
        if maxLength > maxSize {
            let thumbnailScale = maxSize / maxLength
            let _image = image.scaleImage(toScale: max(thumbnailScale, config.photo.filterScale))
            selectedThumbnailImage = _image
            if imageFilter == nil && !filterEditFator.isApply {
                if let img = _image?.ci_Image?.applyMosaic(level: self.config.mosaic.mosaicWidth),
                   let mosaicImage = self.imageFilterContext.createCGImage(img, from: img.extent) {
                    selectedMosaicImage = mosaicImage
                    DispatchQueue.main.async {
                        self.editorView.mosaicCGImage = mosaicImage
                    }
                }
            }
        }else {
            if imageFilter == nil && !filterEditFator.isApply {
                if let img = image.ci_Image?.applyMosaic(level: self.config.mosaic.mosaicWidth),
                   let mosaicImage = self.imageFilterContext.createCGImage(img, from: img.extent) {
                    selectedMosaicImage = mosaicImage
                    DispatchQueue.main.async {
                        self.editorView.mosaicCGImage = mosaicImage
                    }
                }
            }
        }
        if selectedThumbnailImage == nil {
            selectedThumbnailImage = image
        }
    }
    
    func filtersViewDidLoad() {
        if editorView.type == .image {
            if let image = editorView.image {
                filtersView.loadFilters(originalImage: image, selectedIndex: imageFilter != nil ? -1 : 0)
            }
        }else if editorView.type == .video {
            if let avAsset = editorView.avAsset {
                avAsset.getImage(at: 0.1) { [weak self] _, image, _ in
                    guard let self = self,
                          let image = image else {
                        return
                    }
                    let selectedIndex: Int
                    if self.videoFilter != nil {
                        selectedIndex = -1
                    }else {
                        selectedIndex = 0
                    }
                    self.filtersView.loadFilters(
                        originalImage: image,
                        selectedIndex: selectedIndex,
                        isVideo: true
                    )
                }
            }
        }
    }
    
    func loadCompletion() {
        isLoadCompletion = true
        if !isLoadVideoControl && !firstAppear {
            loadVideoControl()
        }
        if editorView.type == .image {
            selectedOriginalImage = editorView.image
        }else if editorView.type == .video {
            selectedOriginalImage = nil
        }
        if !firstAppear {
            selectedDefaultTool()
        }
    }
    
    func checkLastResultState() {
        resetButton.isEnabled = isReset
        brushColorView.canUndo = editorView.isCanUndoDraw
        mosaicToolView.canUndo = editorView.isCanUndoMosaic
        checkFinishButtonState()
    }
    
    func selectedDefaultTool() {
        if config.isFixedCropSizeState {
            UIView.animate {
                self.showTools(true)
            }
            toolsView.selectedOptionType(.cropSize)
            return
        }
        if selectedAsset.contentType == .image {
            if let optionType = config.photo.defaultSelectedToolOption {
                UIView.animate {
                    self.showTools(optionType == .cropSize)
                }
                toolsView.selectedOptionType(optionType)
            }
        }else if selectedAsset.contentType == .video {
            if let optionType = config.video.defaultSelectedToolOption {
                UIView.animate {
                    self.showTools(optionType == .cropSize)
                }
                toolsView.selectedOptionType(optionType)
            }
        }
    }
    
    func loadFailure(message: String = .textManager.editor.videoLoadFailedAlertMessage.text) {
        if isDismissed {
            return
        }
        PhotoTools.showConfirm(
            viewController: self,
            title: .textManager.editor.loadFailedAlertTitle.text,
            message: message,
            actionTitle: .textManager.editor.loadFailedAlertDoneTitle.text
        ) { [weak self] _ in
            self?.backClick(true)
        }
    }
}
