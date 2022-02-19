//
//  VideoEditorViewController.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/9.
//

import UIKit
import AVKit
import Photos

open class VideoEditorViewController: BaseViewController {
    public weak var delegate: VideoEditorViewControllerDelegate?
    
    /// 当前编辑的AVAsset
    public var avAsset: AVAsset! { pAVAsset }
    
    /// 编辑配置
    public let config: VideoEditorConfiguration
    
    /// 当前编辑状态
    public var state: State { pState }
    
    /// 资源类型
    public let sourceType: EditorController.SourceType
    
    /// 在视频未获取成功之前展示的视频封面
    public var coverImage: UIImage?
    
    /// 当前编辑的网络视频地址
    public var networkVideoURL: URL? { pNetworkVideoURL }
    
    /// 当前配乐的音频路径
    public var backgroundMusicPath: String? {
        didSet { toolView.reloadMusic(isSelected: backgroundMusicPath != nil) }
    }
    
    /// 配乐音量
    public var backgroundMusicVolume: Float = 1 {
        didSet { PhotoManager.shared.changeAudioPlayerVolume(backgroundMusicVolume) }
    }
    
    /// 播放视频
    public func playVideo() { startPlayTimer() }
    
    /// 视频原声音量
    public var videoVolume: Float = 1 {
        didSet { videoView.playerView.player.volume = videoVolume }
    }
    
    /// 界面消失之后取消下载网络视频
    public var viewDidDisappearCancelDownload = true
    
    /// 上一次的编辑数据
    public private(set) var editResult: VideoEditResult?
    
    /// 当前被编辑的视频地址，只有通过videoURL初始化的时候才有值
    public private(set) var videoURL: URL?
    
    /// 确认/取消之后自动退出界面
    public var autoBack: Bool = true
    
    public var finishHandler: FinishHandler?
    
    public var cancelHandler: CancelHandler?
    
    public typealias FinishHandler = (VideoEditorViewController, VideoEditResult?) -> Void
    public typealias CancelHandler = (VideoEditorViewController) -> Void
    
    /// 根据视频地址初始化
    /// - Parameters:
    ///   - videoURL: 本地视频地址
    ///   - editResult: 上一次编辑的结果，传入可在基础上进行编辑
    ///   - config: 编辑配置
    public convenience init(
        videoURL: URL,
        editResult: VideoEditResult? = nil,
        config: VideoEditorConfiguration
    ) {
        self.init(
            avAsset: AVAsset.init(url: videoURL),
            editResult: editResult,
            config: config
        )
        self.videoURL = videoURL
    }
    
    /// 根据AVAsset初始化
    /// - Parameters:
    ///   - avAsset: 视频对应的AVAsset对象
    ///   - editResult: 上一次编辑的结果，传入可在基础上进行编辑
    ///   - config: 编辑配置
    public init(
        avAsset: AVAsset,
        editResult: VideoEditResult? = nil,
        config: VideoEditorConfiguration
    ) {
        PhotoManager.shared.appearanceStyle = config.appearanceStyle
        PhotoManager.shared.createLanguageBundle(languageType: config.languageType)
        if config.mustBeTailored {
            onceState = config.defaultState
        }
        needRequest = true
        requestType = 3
        self.sourceType = .local
        self.editResult = editResult
        self.pState = config.defaultState
        self.config = config
        self.pAVAsset = avAsset
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = config.modalPresentationStyle
    }
    
    /// 编辑网络视频
    /// - Parameters:
    ///   - networkVideoURL: 对应的网络视频地址
    ///   - editResult: 上一次编辑的结果，传入可在基础上进行编辑
    ///   - config: 编辑配置
    public init(
        networkVideoURL: URL,
        editResult: VideoEditResult? = nil,
        config: VideoEditorConfiguration
    ) {
        PhotoManager.shared.appearanceStyle = config.appearanceStyle
        PhotoManager.shared.createLanguageBundle(languageType: config.languageType)
        if config.mustBeTailored {
            onceState = config.defaultState
        }
        requestType = 2
        needRequest = true
        self.sourceType = .network
        self.editResult = editResult
        self.pState = config.defaultState
        self.config = config
        self.pNetworkVideoURL = networkVideoURL
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = config.modalPresentationStyle
    }
    
    #if HXPICKER_ENABLE_PICKER
    /// 视频对应的 PhotoAsset
    public private(set) var photoAsset: PhotoAsset!
    
    /// 根据PhotoAsset初始化
    /// - Parameters:
    ///   - photoAsset: 视频对应的PhotoAsset对象
    ///   - editResult: 上一次编辑的结果，传入可在基础上进行编辑
    ///   - config: 编辑配置
    public init(
        photoAsset: PhotoAsset,
        editResult: VideoEditResult? = nil,
        config: VideoEditorConfiguration
    ) {
        PhotoManager.shared.appearanceStyle = config.appearanceStyle
        PhotoManager.shared.createLanguageBundle(languageType: config.languageType)
        if config.mustBeTailored {
            onceState = config.defaultState
        }
        requestType = 1
        needRequest = true
        sourceType = .picker
        self.editResult = editResult
        self.pState = config.defaultState
        self.config = config
        self.photoAsset = photoAsset
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = config.modalPresentationStyle
    }
    #endif
    
    var hasOriginalSound: Bool = true {
        didSet {
            volumeView.hasOriginalSound = hasOriginalSound
        }
    }
    var pState: State
    var pAVAsset: AVAsset!
    var pNetworkVideoURL: URL?
    
    /// 请求获取AVAsset完成
    var reqeustAssetCompletion: Bool = false
    private var needRequest: Bool = false
    private var requestType: Int = 0
    var loadingView: ProgressHUD?
    
    var videoInitializeCompletion = false
    var setAssetCompletion: Bool = false
    var transitionCompletion: Bool = true
    var onceState: State = .normal
    var assetRequestID: PHImageRequestID?
    var didEdited: Bool = false
    var firstPlay: Bool = true
    var videoSize: CGSize = .zero
    
    /// 不是在音乐列表选中的音乐数据（不包括搜索）
    var otherMusic: VideoEditorMusic?
    lazy var videoView: PhotoEditorView = {
        let videoView = PhotoEditorView(
            editType: .video,
            cropConfig: .init(),
            mosaicConfig: .init(),
            brushConfig: .init(),
            exportScale: 1
        )
        if let avAsset = avAsset {
            let image = coverImage ?? PhotoTools.getVideoThumbnailImage(avAsset: avAsset, atTime: 0.1)
            videoView.setAVAsset(avAsset, coverImage: image ?? .init())
        }
        videoView.playerView.delegate = self
        videoView.editorDelegate = self
        return videoView
    }()
    lazy var musicView: VideoEditorMusicView = {
        let view = VideoEditorMusicView.init(config: config.music)
        view.delegate = self
        return view
    }()
    lazy var searchMusicView: VideoEditorSearchMusicView = {
        let view = VideoEditorSearchMusicView(config: config.music)
        view.delegate = self
        return view
    }()
    lazy var volumeView: VideoEditorVolumeView = {
        let view = VideoEditorVolumeView(config.music.tintColor)
        view.delegate = self
        return view
    }()
    var isMusicState = false
    var isSearchMusic = false
    var isShowVolume = false
    lazy var brushColorView: PhotoEditorBrushColorView = {
        let view = PhotoEditorBrushColorView(config: config.brush)
        view.delegate = self
        view.alpha = 0
        view.isHidden = true
        return view
    }()
    lazy var brushSizeView: PhotoEditorViewController.BrushSizeView = {
        let lineWidth = videoView.brushLineWidth + 4
        let view = PhotoEditorViewController.BrushSizeView(
            frame: CGRect(
                origin: .zero,
                size: CGSize(width: lineWidth, height: lineWidth)
            )
        )
        return view
    }()
    lazy var cropToolView: PhotoEditorCropToolView = {
        var showRatios = true
        if config.cropSize.fixedRatio || config.cropSize.isRoundCrop {
            showRatios = false
        }
        let view = PhotoEditorCropToolView(
            showRatios: showRatios,
            scaleArray: config.cropSize.aspectRatios
        )
        view.delegate = self
        view.themeColor = config.cropSize.aspectRatioSelectedColor
        view.alpha = 0
        view.isHidden = true
        return view
    }()
    lazy var cropView: VideoEditorCropView = {
        let cropView: VideoEditorCropView
        if needRequest {
            cropView = VideoEditorCropView.init(config: config.cropTime)
        }else {
            cropView = VideoEditorCropView.init(avAsset: avAsset, config: config.cropTime)
        }
        cropView.delegate = self
        cropView.alpha = 0
        cropView.isHidden = true
        return cropView
    }()
    var isFilter = false
    lazy var filterView: PhotoEditorFilterView = {
        let view = PhotoEditorFilterView(
            filterConfig: config.filter,
            hasLastFilter: editResult?.sizeData?.filter != nil,
            isVideo: true
        )
        view.delegate = self
        return view
    }()
    public lazy var toolView: EditorToolView = {
        let toolView = EditorToolView.init(config: config.toolView)
        toolView.delegate = self
        return toolView
    }()
    lazy var cropConfirmView: EditorCropConfirmView = {
        let cropConfirmView = EditorCropConfirmView.init(config: config.cropConfirmView)
        cropConfirmView.alpha = 0
        cropConfirmView.isHidden = true
        cropConfirmView.delegate = self
        return cropConfirmView
    }()
    lazy var topView: UIView = {
        let view = UIView.init(frame: CGRect(x: 0, y: 0, width: 0, height: 44))
        let cancelBtn = UIButton.init(frame: CGRect(x: 0, y: 0, width: 57, height: 44))
        cancelBtn.setImage(UIImage.image(for: "hx_editor_back"), for: .normal)
        cancelBtn.addTarget(self, action: #selector(didBackClick), for: .touchUpInside)
        view.addSubview(cancelBtn)
        return view
    }()
    
    lazy var topMaskLayer: CAGradientLayer = {
        let layer = PhotoTools.getGradientShadowLayer(true)
        return layer
    }()
    
    var showChartlet: Bool = false
    lazy var chartletView: EditorChartletView = {
        let view = EditorChartletView(
            config: config.chartlet,
            editorType: .video
        )
        view.delegate = self
        return view
    }()
    var isPresentText = false
    var orientationDidChange: Bool = true
    var videoViewDidChange: Bool = true
    /// 当前裁剪框的位置大小
    var currentValidRect: CGRect = .zero
    /// 当前裁剪框帧画面的偏移量
    var currentCropOffset: CGPoint?
    var beforeStartTime: CMTime?
    var beforeEndTime: CMTime?
    /// 旋转之前vc存储的当前编辑数据
    var rotateBeforeStorageData: (CGFloat, CGFloat, CGFloat)? // swiftlint:disable:this large_tuple
    /// 旋转之前cropview存储的裁剪框数据
    var rotateBeforeData: (CGFloat, CGFloat, CGFloat)? // swiftlint:disable:this large_tuple
    var playTimer: DispatchSourceTimer?
    
    /// 视频导出会话
    var exportSession: AVAssetExportSession?
    var exportLoadingView: ProgressHUD?
    
    var toolOptions: EditorToolView.Options = []
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    open override func viewDidLoad() {
        super.viewDidLoad()
        initView()
    }
    func initOptions() {
        for options in config.toolView.toolOptions {
            switch options.type {
            case .graffiti:
                toolOptions.insert(.graffiti)
            case .chartlet:
                toolOptions.insert(.chartlet)
            case .text:
                toolOptions.insert(.text)
            case .cropSize:
                toolOptions.insert(.cropSize)
            case .cropTime:
                toolOptions.insert(.cropTime)
            case .mosaic:
                toolOptions.insert(.mosaic)
            case .filter:
                toolOptions.insert(.filter)
            case .music:
                toolOptions.insert(.music)
            }
        }
    }
    func initView() {
        initOptions()
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(singleTap))
        singleTap.delegate = self
        view.addGestureRecognizer(singleTap)
        view.isExclusiveTouch = true
        view.backgroundColor = .black
        view.clipsToBounds = true
        view.addSubview(videoView)
        view.addSubview(cropToolView)
        view.addSubview(cropView)
        view.addSubview(cropConfirmView)
        view.addSubview(toolView)
        if toolOptions.contains(.graffiti) {
            view.addSubview(brushColorView)
        }
        if toolOptions.contains(.music) {
            view.addSubview(musicView)
            view.addSubview(searchMusicView)
            view.addSubview(volumeView)
        }
        if toolOptions.contains(.filter) {
            view.addSubview(filterView)
        }
        if toolOptions.isSticker {
            view.addSubview(chartletView)
        }
        view.layer.addSublayer(topMaskLayer)
        view.addSubview(topView)
        if needRequest {
            if requestType == 1 {
                #if HXPICKER_ENABLE_PICKER
                requestAVAsset()
                #endif
            }else if requestType == 2 {
                downloadNetworkVideo()
            }else if requestType == 3 {
                avassetLoadValuesAsynchronously()
            }
        }
        if let editResult = editResult {
            didEdited = true
            if let cropData = editResult.cropData {
                videoView.playerView.playStartTime = CMTimeMakeWithSeconds(
                    cropData.startTime,
                    preferredTimescale: cropData.preferredTimescale
                )
                videoView.playerView.playEndTime = CMTimeMakeWithSeconds(
                    cropData.endTime,
                    preferredTimescale: cropData.preferredTimescale
                )
                rotateBeforeStorageData = (
                    cropData.cropingData.offsetX,
                    cropData.cropingData.validX,
                    cropData.cropingData.validWidth
                )
                rotateBeforeData = (
                    cropData.cropRectData.offsetX,
                    cropData.cropRectData.validX,
                    cropData.cropRectData.validWidth
                )
            }
        }
    }
    @objc func didBackClick() {
        backAction()
        cancelHandler?(self)
        delegate?.videoEditorViewController(didCancel: self)
    }
    func backAction() {
        hiddenBrushColorView()
        stopAllOperations()
        if let requestID = assetRequestID {
            PHImageManager.default().cancelImageRequest(requestID)
        }
        if autoBack {
            if let navigationController = navigationController, navigationController.viewControllers.count > 1 {
                navigationController.popViewController(animated: true)
            }else {
                dismiss(animated: true, completion: nil)
            }
        }
    }
    open override func deviceOrientationWillChanged(notify: Notification) {
        orientationDidChange = true
        videoViewDidChange = false
        if let currentCropOffset = currentCropOffset {
            rotateBeforeStorageData = cropView.getRotateBeforeData(
                offsetX: currentCropOffset.x,
                validX: currentValidRect.minX,
                validWidth: currentValidRect.width
            )
        }
        if showChartlet {
            singleTap()
        }
        videoView.undoAllSticker()
        videoView.undoAllDraw()
        videoView.reset(false)
        if state == .cropSize {
            pState = .normal
            toolCropSizeAnimation()
        }else if state == .cropTime {
            cancelCropTime(false)
        }
        videoView.finishCropping(false)
        rotateBeforeData = cropView.getRotateBeforeData()
        videoView.playerView.pause()
        if toolOptions.contains(.music) {
            searchMusicView.deselect()
            musicView.reset()
        }
        backgroundMusicPath = nil
        stopPlayTimer()
    }
    open override func deviceOrientationDidChanged(notify: Notification) {
//        orientationDidChange = true
//        videoViewDidChange = false
    }
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        toolView.frame = CGRect(
            x: 0,
            y: view.height - UIDevice.bottomMargin - 50,
            width: view.width,
            height: 50 + UIDevice.bottomMargin
        )
        toolView.reloadContentInset()
        topView.width = view.width
        topView.height = navigationController?.navigationBar.height ?? 44
        if let modalPresentationStyle = navigationController?.modalPresentationStyle, UIDevice.isPortrait {
            if modalPresentationStyle == .fullScreen || modalPresentationStyle == .custom {
                topView.y = UIDevice.generalStatusBarHeight
            }
        }else if (modalPresentationStyle == .fullScreen || modalPresentationStyle == .custom) && UIDevice.isPortrait {
            topView.y = UIDevice.generalStatusBarHeight
        }
        topMaskLayer.frame = CGRect(x: 0, y: 0, width: view.width, height: topView.frame.maxY + 10)
        cropView.frame = CGRect(x: 0, y: toolView.y - (UIDevice.isPortrait ? 100 : 90), width: view.width, height: 100)
        cropConfirmView.frame = toolView.frame
        if !videoView.frame.equalTo(view.bounds) && !videoView.frame.isEmpty && !videoViewDidChange {
            videoView.frame = view.bounds
            videoView.reset(false)
            videoView.finishCropping(false)
            orientationDidChange = true
        }else {
            videoView.frame = view.bounds
        }
        if toolOptions.contains(.cropSize) {
            let cropToolFrame = CGRect(x: 0, y: toolView.y - 60, width: view.width, height: 60)
            cropConfirmView.frame = toolView.frame
            cropToolView.frame = cropToolFrame
            cropToolView.updateContentInset()
        }
        if toolOptions.contains(.graffiti) {
            brushColorView.frame = CGRect(x: 0, y: toolView.y - 85, width: view.width, height: 85)
        }
        if toolOptions.isSticker {
            setChartletViewFrame()
        }
        if toolOptions.contains(.music) {
            setMusicViewFrame()
            setSearchMusicViewFrame()
            setVolumeViewFrame()
            if orientationDidChange {
                searchMusicView.reloadData()
            }
        }
        if toolOptions.contains(.filter) {
            setFilterViewFrame()
        }
        if orientationDidChange {
            if videoView.playerView.avAsset != nil && !videoViewDidChange {
                videoView.orientationDidChange()
            }
            videoViewDidChange = true
        }
        if needRequest {
            if reqeustAssetCompletion {
                setCropViewFrame()
            }
        }else {
            setCropViewFrame()
        }
    }
    open override var prefersStatusBarHidden: Bool {
        return config.prefersStatusBarHidden
    }
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isPresentText = false
    }
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isPresentText {
            return
        }
        stopAllOperations()
    }
    public func stopAllOperations() {
        stopPlayTimer()
        PhotoManager.shared.stopPlayMusic()
        if let url = networkVideoURL, viewDidDisappearCancelDownload {
            PhotoManager.shared.suspendTask(url)
            pNetworkVideoURL = nil
        }
        viewDidDisappearCancelDownload = true
    }
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if navigationController?.topViewController != self &&
            navigationController?.viewControllers.contains(self) == false {
            navigationController?.setNavigationBarHidden(false, animated: true)
        }
    }
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    deinit {
        if let asset = avAsset {
            asset.cancelLoading()
        }
        exportSession?.cancelExport()
    }
}

extension VideoEditorViewController: UINavigationControllerDelegate {
    public func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        if operation == .push {
            return EditorTransition(mode: .push)
        }else if operation == .pop {
            return EditorTransition(mode: .pop)
        }
        return nil
    }
}

extension VideoEditorViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view is EditorStickerContentView {
            return false
        }
        if let isDescendant = touch.view?.isDescendant(of: videoView), isDescendant {
            return true
        }
        return false
    }
    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        if otherGestureRecognizer is UILongPressGestureRecognizer &&
            otherGestureRecognizer.view is PhotoEditorContentView {
            return false
        }
        return true
    }
}

// MARK: singleTap
extension VideoEditorViewController {
    
    @objc func singleTap() {
        if state != .normal {
            return
        }
        if toolOptions.isSticker {
            videoView.deselectedSticker()
        }
        if isSearchMusic {
            hideSearchMusicView()
            return
        }
        if isShowVolume {
            hiddenVolumeView()
            return
        }
        if isFilter {
            videoView.stickerEnabled = true
            hiddenFilterView()
            videoView.canLookOriginal = false
        }
        if showChartlet {
            showChartlet = false
            videoView.stickerEnabled = true
            hiddenChartletView()
        }
        if isMusicState {
            videoView.stickerEnabled = true
            isMusicState = false
            updateMusicView()
        }
        if topView.isHidden == true {
            showTopView()
        }else {
            hidenTopView()
        }
    }
    func showTopView() {
        if videoView.drawEnabled {
            showBrushColorView()
        }
        toolView.isHidden = false
        topView.isHidden = false
        UIView.animate(withDuration: 0.25) {
            self.toolView.alpha = 1
            self.topView.alpha = 1
            self.topMaskLayer.isHidden = false
        }
    }
    func hidenTopView() {
        if videoView.drawEnabled {
            hiddenBrushColorView()
        }
        UIView.animate(withDuration: 0.25) {
            self.toolView.alpha = 0
            self.topView.alpha = 0
            self.topMaskLayer.isHidden = true
        } completion: { (isFinished) in
            if self.toolView.alpha == 0 {
                self.toolView.isHidden = true
                self.topView.isHidden = true
            }
        }
    }
}

// MARK: setup frame
extension VideoEditorViewController {
    
    func setChartletViewFrame() {
        var viewHeight = config.chartlet.viewHeight
        if viewHeight > view.height {
            viewHeight = view.height * 0.6
        }
        if showChartlet {
            chartletView.frame = CGRect(
                x: 0,
                y: view.height - viewHeight - UIDevice.bottomMargin,
                width: view.width,
                height: viewHeight + UIDevice.bottomMargin
            )
        }else {
            chartletView.frame = CGRect(
                x: 0,
                y: view.height,
                width: view.width,
                height: viewHeight + UIDevice.bottomMargin
            )
        }
    }
    /// 设置裁剪框frame
    func setCropViewFrame() {
        if !orientationDidChange {
            return
        }
        cropView.configData()
        if let rotateBeforeData = rotateBeforeData {
            cropView.layoutSubviews()
            cropView.rotateAfterSetData(
                offsetXScale: rotateBeforeData.0,
                validXScale: rotateBeforeData.1,
                validWithScale: rotateBeforeData.2
            )
            cropView.updateTimeLabels()
            if state == .cropTime || didEdited {
                videoView.playerView.playStartTime = cropView.getStartTime(real: true)
                videoView.playerView.playEndTime = cropView.getEndTime(real: true)
            }
            if let rotateBeforeStorageData = rotateBeforeStorageData {
                rotateAfterSetStorageData(
                    offsetXScale: rotateBeforeStorageData.0,
                    validXScale: rotateBeforeStorageData.1,
                    validWithScale: rotateBeforeStorageData.2
                )
            }
            if transitionCompletion {
                videoView.playerView.resetPlay()
                startPlayTimer()
            }
        }
        DispatchQueue.main.async {
            self.orientationDidChange = false
        }
    }
    func setMusicViewFrame() {
        let marginHeight: CGFloat = 190
        let musicY: CGFloat
        let musicHeight: CGFloat
        if !isMusicState {
            musicY = view.height
            musicHeight = marginHeight + UIDevice.bottomMargin
        }else {
            musicY = view.height - marginHeight - UIDevice.bottomMargin
            musicHeight = marginHeight + UIDevice.bottomMargin
        }
        musicView.frame = CGRect(
            x: 0,
            y: musicY,
            width: view.width,
            height: musicHeight
        )
    }
    func setFilterViewFrame() {
        if isFilter {
            filterView.frame = CGRect(
                x: 0,
                y: view.height - 150 - UIDevice.bottomMargin,
                width: view.width,
                height: 150 + UIDevice.bottomMargin
            )
        }else {
            filterView.frame = CGRect(
                x: 0,
                y: view.height + 10,
                width: view.width,
                height: 150 + UIDevice.bottomMargin
            )
        }
    }
    func setSearchMusicViewFrame() {
        var viewHeight: CGFloat = view.height * 0.75 + UIDevice.bottomMargin
        if !UIDevice.isPad && !UIDevice.isPortrait {
            viewHeight = view.height * 0.85 + UIDevice.bottomMargin
        }
        if !isSearchMusic {
            searchMusicView.frame = CGRect(x: 0, y: view.height, width: view.width, height: viewHeight)
        }else {
            searchMusicView.frame = CGRect(x: 0, y: view.height - viewHeight, width: view.width, height: viewHeight)
        }
    }
    func setVolumeViewFrame() {
        let marginHeight: CGFloat = 120
        let volumeY: CGFloat
        let volumeHeight: CGFloat
        if !isShowVolume {
            volumeY = view.height
            volumeHeight = marginHeight
        }else {
            volumeY = view.height - marginHeight - UIDevice.bottomMargin - 20
            volumeHeight = marginHeight
        }
        let marginWidth = UIDevice.leftMargin + UIDevice.rightMargin + 30
        volumeView.frame = CGRect(
            x: marginWidth * 0.5,
            y: volumeY,
            width: view.width - marginWidth,
            height: volumeHeight
        )
    }
    func rotateAfterSetStorageData(offsetXScale: CGFloat, validXScale: CGFloat, validWithScale: CGFloat) {
        let insert = cropView.collectionView.contentInset
        let offsetX = -insert.left + cropView.contentWidth * offsetXScale
        currentCropOffset = CGPoint(x: offsetX, y: -insert.top)
        let validInitialX = cropView.validRectX + cropView.imageWidth * 0.5
        let validMaxWidth = cropView.width - validInitialX * 2
        let validX = validMaxWidth * validXScale + validInitialX
        let vaildWidth = validMaxWidth * validWithScale
        currentValidRect = CGRect(x: validX, y: 0, width: vaildWidth, height: cropView.itemHeight)
    }
}
