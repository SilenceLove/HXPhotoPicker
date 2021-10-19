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
        didSet { playerView.player.volume = videoVolume }
    }
    
    /// 界面消失之后取消下载网络视频
    public var viewDidDisappearCancelDownload = true
    
    /// 上一次的编辑数据
    public private(set) var editResult: VideoEditResult?
    
    /// 当前被编辑的视频地址，只有通过videoURL初始化的时候才有值
    public private(set) var videoURL: URL?
    
    /// 确认/取消之后自动退出界面
    public var autoBack: Bool = true
    
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
    }
    #endif
    
    var pState: State
    var pAVAsset: AVAsset!
    var pNetworkVideoURL: URL?
    
    /// 请求获取AVAsset完成
    var reqeustAssetCompletion: Bool = false
    private var needRequest: Bool = false
    private var requestType: Int = 0
    var loadingView: ProgressHUD?
    
    var setAssetCompletion: Bool = false
    var transitionCompletion: Bool = true
    var onceState: State = .normal
    var assetRequestID: PHImageRequestID?
    var didEdited: Bool = false
    var firstPlay: Bool = true
    var videoSize: CGSize = .zero
    
    /// 不是在音乐列表选中的音乐数据（不包括搜索）
    var otherMusic: VideoEditorMusic?
    
    lazy var scrollView: ScrollView = {
        let scrollView = ScrollView.init()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.delegate = self
        scrollView.isScrollEnabled = false
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 2.0
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        let singleTap = UITapGestureRecognizer.init(target: self, action: #selector(singleTap))
        singleTap.delegate = self
        scrollView.addGestureRecognizer(singleTap)
        scrollView.addSubview(playerView)
        return scrollView
    }()
    @objc func singleTap() {
        if state != .normal {
            return
        }
        if toolOptions.isSticker {
            playerView.stickerView.deselectedSticker()
        }
        if isSearchMusic {
            hideSearchMusicView()
            return
        }
        if showChartlet {
            showChartlet = false
            playerView.stickerView.isUserInteractionEnabled = true
            hiddenChartletView()
        }
        if isMusicState {
            playerView.stickerView.isUserInteractionEnabled = true
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
        toolView.isHidden = false
        topView.isHidden = false
        UIView.animate(withDuration: 0.25) {
            self.toolView.alpha = 1
            self.topView.alpha = 1
            self.topMaskLayer.isHidden = false
        }
    }
    func hidenTopView() {
        UIView.animate(withDuration: 0.25) {
            self.toolView.alpha = 0
            self.topView.alpha = 0
            self.topMaskLayer.isHidden = true
        } completion: { (isFinished) in
            self.toolView.isHidden = true
            self.topView.isHidden = true
        }
    }
    lazy var playerView: VideoEditorPlayerView = {
        let playerView: VideoEditorPlayerView
        if needRequest {
            playerView = VideoEditorPlayerView.init()
        }else {
            playerView = VideoEditorPlayerView.init(avAsset: avAsset)
        }
        playerView.coverImageView.image = coverImage
        playerView.delegate = self
        return playerView
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
    var isMusicState = false
    var isSearchMusic = false
    lazy var cropView: VideoEditorCropView = {
        let cropView: VideoEditorCropView
        if needRequest {
            cropView = VideoEditorCropView.init(config: config.cropping)
        }else {
            cropView = VideoEditorCropView.init(avAsset: avAsset, config: config.cropping)
        }
        cropView.delegate = self
        cropView.alpha = 0
        cropView.isHidden = true
        return cropView
    }()
    public lazy var toolView: EditorToolView = {
        let toolView = EditorToolView.init(config: config.toolView)
        toolView.delegate = self
        return toolView
    }()
    public lazy var cropConfirmView: EditorCropConfirmView = {
        let cropConfirmView = EditorCropConfirmView.init(config: config.cropView)
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
    var playerFrame: CGRect = .zero
    var orientationDidChange: Bool = true
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
    func initView() {
        for options in config.toolView.toolOptions {
            switch options.type {
            case .graffiti:
                toolOptions.insert(.graffiti)
            case .chartlet:
                toolOptions.insert(.chartlet)
            case .text:
                toolOptions.insert(.text)
            case .cropping:
                toolOptions.insert(.cropping)
            case .mosaic:
                toolOptions.insert(.mosaic)
            case .filter:
                toolOptions.insert(.filter)
            case .music:
                toolOptions.insert(.music)
            }
        }
        view.backgroundColor = .black
        view.addSubview(scrollView)
        view.addSubview(cropView)
        view.addSubview(cropConfirmView)
        view.addSubview(toolView)
        if toolOptions.contains(.music) {
            view.addSubview(musicView)
            view.addSubview(searchMusicView)
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
                playerView.playStartTime = CMTimeMakeWithSeconds(
                    cropData.startTime,
                    preferredTimescale: cropData.preferredTimescale
                )
                playerView.playEndTime = CMTimeMakeWithSeconds(
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
        delegate?.videoEditorViewController(didCancel: self)
    }
    func backAction() {
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
        playerView.stickerView.removeAllSticker()
        rotateBeforeData = cropView.getRotateBeforeData()
        playerView.pause()
        if toolOptions.contains(.music) {
            searchMusicView.deselect()
            musicView.reset()
        }
        backgroundMusicPath = nil
        stopPlayTimer()
    }
    open override func deviceOrientationDidChanged(notify: Notification) {
        orientationDidChange = true
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
        cropView.frame = CGRect(x: 0, y: toolView.y - 100, width: view.width, height: 100)
        cropConfirmView.frame = toolView.frame
        scrollView.frame = view.bounds
        if toolOptions.isSticker {
            setChartletViewFrame()
        }
        if toolOptions.contains(.music) {
            setMusicViewFrame()
            setSearchMusicViewFrame()
            if orientationDidChange {
                searchMusicView.reloadData()
            }
        }
        if needRequest {
            if reqeustAssetCompletion {
                setPlayerViewFrame()
                setCropViewFrame()
            }else {
                if let size = coverImage?.size {
                    playerView.frame = getPlayerViewFrame(size)
                }else {
                    playerView.frame = scrollView.bounds
                }
                scrollView.contentSize = playerView.size
            }
        }else {
            setPlayerViewFrame()
            setCropViewFrame()
        }
    }
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
            if state == .cropping || didEdited {
                playerView.playStartTime = cropView.getStartTime(real: true)
                playerView.playEndTime = cropView.getEndTime(real: true)
            }
            if let rotateBeforeStorageData = rotateBeforeStorageData {
                rotateAfterSetStorageData(
                    offsetXScale: rotateBeforeStorageData.0,
                    validXScale: rotateBeforeStorageData.1,
                    validWithScale: rotateBeforeStorageData.2
                )
            }
            if transitionCompletion {
                playerView.resetPlay()
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
    func getPlayerViewFrame(_ videoSize: CGSize) -> CGRect {
        let playerFrame: CGRect
        if UIDevice.isPad {
            playerFrame = PhotoTools.transformImageSize(videoSize, toViewSize: view.size, directions: [.horizontal])
        }else {
            playerFrame = PhotoTools.transformImageSize(videoSize, to: view)
        }
        return playerFrame
    }
    func setPlayerViewFrame() {
        scrollView.minimumZoomScale = 1
        scrollView.zoomScale = 1
        let playerFrame = getPlayerViewFrame(videoSize)
        if !playerView.frame.equalTo(playerFrame) && orientationDidChange {
            playerView.frame = playerFrame
        }
        self.playerFrame = playerFrame
        if !scrollView.contentSize.equalTo(playerView.size) {
            scrollView.contentSize = playerView.size
        }
        if state == .normal && UIDevice.isPad {
            scrollView.minimumZoomScale = 1.1
            scrollView.zoomScale = 1.1
            setupScrollViewScale()
        }else if state == .cropping && transitionCompletion {
            setupScrollViewScale()
        }
    }
    func setupScrollViewScale() {
        if state == .normal {
            scrollView.minimumZoomScale = 1
            scrollView.zoomScale = 1
        }else if state == .cropping {
            let scale = cropVideoRect().width / playerFrame.width
            scrollView.minimumZoomScale = scale
            scrollView.zoomScale = scale
        }
    }
    func cropVideoRect() -> CGRect {
        let leftMargin = 30 + UIDevice.leftMargin
        let width = view.width - leftMargin * 2
        var y: CGFloat = 10
        var height = cropView.y - y - 5
        if let modalPresentationStyle = navigationController?.modalPresentationStyle, UIDevice.isPortrait {
            if modalPresentationStyle == .fullScreen ||
                modalPresentationStyle == .custom {
                height -= UIDevice.generalStatusBarHeight
                y += UIDevice.generalStatusBarHeight
            }
        }else if (modalPresentationStyle == .fullScreen || modalPresentationStyle == .custom) && UIDevice.isPortrait {
            height -= UIDevice.generalStatusBarHeight
            y += UIDevice.generalStatusBarHeight
        }
        let rect = PhotoTools.transformImageSize(
            videoSize,
            toViewSize: CGSize(width: width, height: height),
            directions: [.horizontal]
        )
        return CGRect(
            x: leftMargin + (width - rect.width) * 0.5,
            y: y + (height - rect.height) * 0.5,
            width: rect.width,
            height: rect.height
        )
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

extension VideoEditorViewController: UIScrollViewDelegate, UIGestureRecognizerDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return playerView
    }
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = (scrollView.width > scrollView.contentSize.width) ?
            (scrollView.width - scrollView.contentSize.width) * 0.5 : 0
        let offsetY = (scrollView.height > scrollView.contentSize.height) ?
            (scrollView.height - scrollView.contentSize.height) * 0.5 : 0
        let centerX = scrollView.contentSize.width * 0.5 + offsetX
        let centerY = scrollView.contentSize.height * 0.5 + offsetY
        playerView.center = CGPoint(x: centerX, y: centerY)
        if state == .cropping {
            playerView.y = cropVideoRect().minY
        }
    }
    class ScrollView: UIScrollView, UIGestureRecognizerDelegate {
        
        public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            return false
        }
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
