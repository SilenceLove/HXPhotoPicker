//
//  VideoEditorViewController.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/9.
//

import UIKit
import AVKit
import Photos

public protocol VideoEditorViewControllerDelegate: AnyObject {
    
    /// 编辑完成
    /// - Parameters:
    ///   - videoEditorViewController: 对应的 VideoEditorViewController
    ///   - result: 编辑后的数据
    func videoEditorViewController(_ videoEditorViewController: VideoEditorViewController, didFinish result: VideoEditResult)
    
    /// 点击完成按钮，但是视频未编辑
    /// - Parameters:
    ///   - videoEditorViewController: 对应的 VideoEditorViewController
    func videoEditorViewController(didFinishWithUnedited videoEditorViewController: VideoEditorViewController)
    
    /// 将要点击工具栏音乐按钮
    /// - Parameter videoEditorViewController: 对应的 VideoEditorViewController
    func videoEditorViewController(shouldClickMusicTool videoEditorViewController: VideoEditorViewController) -> Bool
    
    /// 加载配乐信息，当musicConfig.infos为空时触发
    /// 返回 true 内部会显示加载状态，调用 completionHandler 后恢复
    /// - Parameters:
    ///   - videoEditorViewController: 对应的 VideoEditorViewController
    ///   - completionHandler: 传入配乐信息
    func videoEditorViewController(_ videoEditorViewController: VideoEditorViewController,
                                   loadMusic completionHandler: @escaping ([VideoEditorMusicInfo]) -> Void) -> Bool
    
    /// 搜索配乐信息
    /// - Parameters:
    ///   - videoEditorViewController: 对应的 VideoEditorViewController
    ///   - text: 搜索的文字内容
    ///   - completion: 传入配乐信息，是否需要加载更多
    func videoEditorViewController(_ videoEditorViewController: VideoEditorViewController,
                                   didSearch text: String?,
                                   completionHandler: @escaping ([VideoEditorMusicInfo], Bool) -> Void)
    
    /// 加载更多配乐信息
    /// - Parameters:
    ///   - videoEditorViewController: 对应的 VideoEditorViewController
    ///   - text: 搜索的文字内容
    ///   - completion: 传入配乐信息，是否还有更多数据
    func videoEditorViewController(_ videoEditorViewController: VideoEditorViewController,
                                   loadMore text: String?,
                                   completionHandler: @escaping ([VideoEditorMusicInfo], Bool) -> Void)
    
    /// 取消编辑
    /// - Parameter videoEditorViewController: 对应的 VideoEditorViewController
    func videoEditorViewController(didCancel videoEditorViewController: VideoEditorViewController)
}

public extension VideoEditorViewControllerDelegate {
    func videoEditorViewController(_ videoEditorViewController: VideoEditorViewController, didFinish result: VideoEditResult) {}
    func videoEditorViewController(didFinishWithUnedited videoEditorViewController: VideoEditorViewController) {}
    func videoEditorViewController(shouldClickMusicTool videoEditorViewController: VideoEditorViewController) -> Bool { true }
    func videoEditorViewController(_ videoEditorViewController: VideoEditorViewController, loadMusic completionHandler: @escaping ([VideoEditorMusicInfo]) -> Void) -> Bool {
        var infos: [VideoEditorMusicInfo] = []
        if let audioURL = URL(string: "http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/chartle/%E5%A4%A9%E5%A4%96%E6%9D%A5%E7%89%A9.mp3"),
           let lrc = "天外来物".lrc {
            let info = VideoEditorMusicInfo(audioURL: audioURL, lrc: lrc)
            infos.append(info)
        }
        return false
    }
    func videoEditorViewController(_ videoEditorViewController: VideoEditorViewController,
                                   didSearch text: String?,
                                   completionHandler: @escaping ([VideoEditorMusicInfo], Bool) -> Void) {
        completionHandler([], false)
    }
    func videoEditorViewController(_ videoEditorViewController: VideoEditorViewController,
                                   loadMore text: String?,
                                   completionHandler: @escaping ([VideoEditorMusicInfo], Bool) -> Void) {
        completionHandler([], false)
    }
    func videoEditorViewController(didCancel videoEditorViewController: VideoEditorViewController) {}
}

open class VideoEditorViewController: BaseViewController {
    public weak var delegate: VideoEditorViewControllerDelegate?
    
    /// 当前编辑的AVAsset
    public private(set) var avAsset: AVAsset!
    
    /// 编辑配置
    public let config: VideoEditorConfiguration
    
    /// 当前编辑状态
    public private(set) var state: State
    
    /// 资源类型
    public let sourceType: EditorController.SourceType
    
    /// 在视频未获取成功之前展示的视频封面
    public var coverImage: UIImage?
    
    /// 当前编辑的网络视频地址
    public private(set) var networkVideoURL: URL?
    
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
    
    /// 根据视频地址初始化
    /// - Parameters:
    ///   - videoURL: 本地视频地址
    ///   - editResult: 上一次编辑的结果，传入可在基础上进行编辑
    ///   - config: 编辑配置
    public convenience init(videoURL: URL,
                            editResult: VideoEditResult? = nil,
                            config: VideoEditorConfiguration) {
        self.init(avAsset: AVAsset.init(url: videoURL), editResult: editResult, config: config)
    }
    
    /// 根据AVAsset初始化
    /// - Parameters:
    ///   - avAsset: 视频对应的AVAsset对象
    ///   - editResult: 上一次编辑的结果，传入可在基础上进行编辑
    ///   - config: 编辑配置
    public init(avAsset: AVAsset,
                editResult: VideoEditResult? = nil,
                config: VideoEditorConfiguration) {
        PhotoManager.shared.appearanceStyle = config.appearanceStyle
        PhotoManager.shared.createLanguageBundle(languageType: config.languageType)
        if config.mustBeTailored {
            onceState = config.defaultState
        }
        if config.defaultState == .cropping {
            firstPlay = true
        }
        needRequest = true
        requestType = 3
        self.sourceType = .local
        self.editResult = editResult
        self.state = config.defaultState
        self.config = config
        self.avAsset = avAsset
        super.init(nibName: nil, bundle: nil)
    }
    
    /// 编辑网络视频
    /// - Parameters:
    ///   - networkVideoURL: 对应的网络视频地址
    ///   - editResult: 上一次编辑的结果，传入可在基础上进行编辑
    ///   - config: 编辑配置
    public init(networkVideoURL: URL,
                editResult: VideoEditResult? = nil,
                config: VideoEditorConfiguration) {
        PhotoManager.shared.appearanceStyle = config.appearanceStyle
        PhotoManager.shared.createLanguageBundle(languageType: config.languageType)
        if config.mustBeTailored {
            onceState = config.defaultState
        }
        if config.defaultState == .cropping {
            firstPlay = true
        }
        requestType = 2
        needRequest = true
        self.sourceType = .network
        self.editResult = editResult
        self.state = config.defaultState
        self.config = config
        self.networkVideoURL = networkVideoURL
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
    public init(photoAsset: PhotoAsset,
                editResult: VideoEditResult? = nil,
                config: VideoEditorConfiguration) {
        PhotoManager.shared.appearanceStyle = config.appearanceStyle
        PhotoManager.shared.createLanguageBundle(languageType: config.languageType)
        if config.mustBeTailored {
            onceState = config.defaultState
        }
        if config.defaultState == .cropping {
            firstPlay = true
        }
        requestType = 1
        needRequest = true
        sourceType = .picker
        self.editResult = editResult
        self.state = config.defaultState
        self.config = config
        self.photoAsset = photoAsset
        super.init(nibName: nil, bundle: nil)
    }
    #endif
    
    /// 请求获取AVAsset完成
    var reqeustAssetCompletion: Bool = false
    var needRequest: Bool = false
    var requestType: Int = 0
    var loadingView: ProgressHUD?
    
    var onceState: State = .normal
    var assetRequestID: PHImageRequestID?
    var didEdited: Bool = false
    var firstPlay: Bool = false
    var firstLayoutSubviews: Bool = true
    var videoSize: CGSize = .zero
    lazy var scrollView : UIScrollView = {
        let scrollView = UIScrollView.init()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        let singleTap = UITapGestureRecognizer.init(target: self, action: #selector(singleTap(tap:)))
        scrollView.addGestureRecognizer(singleTap)
        scrollView.addSubview(playerView)
        return scrollView
    }()
    @objc func singleTap(tap: UITapGestureRecognizer) {
        if state != .normal {
            return
        }
        if isSearchMusic {
            hideSearchMusicView()
            return
        }
        if isMusicState {
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
        let cropView : VideoEditorCropView
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
    lazy var toolView: EditorToolView = {
        let toolView = EditorToolView.init(config: config.toolView)
        toolView.delegate = self
        return toolView
    }()
    lazy var cropConfirmView: EditorCropConfirmView = {
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
        let layer = CAGradientLayer.init()
        layer.contentsScale = UIScreen.main.scale
        let blackColor = UIColor.black
        layer.colors = [blackColor.withAlphaComponent(0).cgColor,
                        blackColor.withAlphaComponent(0.3).cgColor,
                        blackColor.withAlphaComponent(0.4).cgColor,
                        blackColor.withAlphaComponent(0.5).cgColor,
                        blackColor.withAlphaComponent(0.6).cgColor]
        layer.startPoint = CGPoint(x: 0, y: 1)
        layer.endPoint = CGPoint(x: 0, y: 0)
        layer.locations = [0.1, 0.3, 0.5, 0.7, 0.9]
        layer.borderWidth = 0.0
        return layer
    }()
    var orientationDidChange : Bool = true
    /// 当前裁剪框的位置大小
    var currentValidRect: CGRect = .zero
    /// 当前裁剪框帧画面的偏移量
    var currentCropOffset: CGPoint?
    var beforeStartTime: CMTime?
    var beforeEndTime: CMTime?
    /// 旋转之前vc存储的当前编辑数据
    var rotateBeforeStorageData: (CGFloat, CGFloat, CGFloat)?
    /// 旋转之前cropview存储的裁剪框数据
    var rotateBeforeData: (CGFloat, CGFloat, CGFloat)?
    var playTimer: DispatchSourceTimer?
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    open override func viewDidLoad() {
        super.viewDidLoad()
        initView()
    }
    func initView() {
        view.backgroundColor = .black
        view.addSubview(scrollView)
        view.addSubview(cropView)
        view.addSubview(cropConfirmView)
        view.addSubview(toolView)
        view.addSubview(musicView)
        view.addSubview(searchMusicView)
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
                playerView.playStartTime = CMTimeMakeWithSeconds(cropData.startTime, preferredTimescale: cropData.preferredTimescale)
                playerView.playEndTime = CMTimeMakeWithSeconds(cropData.endTime,
                                                               preferredTimescale: cropData.preferredTimescale)
                rotateBeforeStorageData = (cropData.cropingData.offsetX, cropData.cropingData.validX, cropData.cropingData.validWidth)
                rotateBeforeData = (cropData.cropRectData.offsetX, cropData.cropRectData.validX, cropData.cropRectData.validWidth)
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
        if let navigationController = navigationController, navigationController.viewControllers.count > 1 {
            navigationController.popViewController(animated: true)
        }else {
            dismiss(animated: true, completion: nil)
        }
    }
    open override func deviceOrientationWillChanged(notify: Notification) {
        if let currentCropOffset = currentCropOffset {
            rotateBeforeStorageData = cropView.getRotateBeforeData(offsetX: currentCropOffset.x, validX: currentValidRect.minX, validWidth: currentValidRect.width)
        }
        rotateBeforeData = cropView.getRotateBeforeData()
        playerView.pause()
        musicView.reset()
        searchMusicView.deselect()
        backgroundMusicPath = nil
        stopPlayTimer()
    }
    open override func deviceOrientationDidChanged(notify: Notification) {
        orientationDidChange = true
    }
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        toolView.frame = CGRect(x: 0, y: view.height - UIDevice.bottomMargin - 50, width: view.width, height: 50 + UIDevice.bottomMargin)
        toolView.reloadContentInset()
        cropView.frame = CGRect(x: 0, y: toolView.y - 100, width: view.width, height: 100)
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
        cropConfirmView.frame = toolView.frame
        scrollView.frame = view.bounds
        setMusicViewFrame()
        setSearchMusicViewFrame()
        if orientationDidChange {
            searchMusicView.reloadData()
        }
        if needRequest {
            firstLayoutSubviews = false
            if reqeustAssetCompletion {
                setCropViewFrame()
                setPlayerViewFrame()
            }else {
                if let size = coverImage?.size {
                    if UIDevice.isPad {
                        playerView.frame = PhotoTools.transformImageSize(size, toViewSize: view.size, directions: [.horizontal])
                    }else {
                        playerView.frame = PhotoTools.transformImageSize(size, to: view)
                    }
                }else {
                    playerView.frame = scrollView.bounds
                }
                scrollView.contentSize = playerView.size
            }
        }else {
            setCropViewFrame()
            setPlayerViewFrame()
            if firstLayoutSubviews {
                if state == .cropping {
                    state = .normal
                    croppingAction()
                }
                firstLayoutSubviews = false
            }
        }
    }
    /// 设置裁剪框frame
    func setCropViewFrame() {
        if orientationDidChange {
            cropView.configData()
            if let rotateBeforeData = rotateBeforeData {
                cropView.layoutSubviews()
                cropView.rotateAfterSetData(offsetXScale: rotateBeforeData.0, validXScale: rotateBeforeData.1, validWithScale: rotateBeforeData.2)
                cropView.updateTimeLabels()
                if state == .cropping || didEdited {
                    playerView.playStartTime = cropView.getStartTime(real: true)
                    playerView.playEndTime = cropView.getEndTime(real: true)
                }
                if let rotateBeforeStorageData = rotateBeforeStorageData {
                    rotateAfterSetStorageData(offsetXScale: rotateBeforeStorageData.0, validXScale: rotateBeforeStorageData.1, validWithScale: rotateBeforeStorageData.2)
                }
                playerView.resetPlay()
                startPlayTimer()
            }
            DispatchQueue.main.async {
                self.orientationDidChange = false
            }
        }
    }
    func setMusicViewFrame() {
        let musicHeight: CGFloat = 190
        if !isMusicState {
            musicView.frame = CGRect(x: 0, y: view.height, width: view.width, height: musicHeight + UIDevice.bottomMargin)
        }else {
            musicView.frame = CGRect(x: 0, y: view.height - musicHeight - UIDevice.bottomMargin, width: view.width, height: musicHeight + UIDevice.bottomMargin)
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
    func setPlayerViewFrame() {
        if state == .normal {
            if UIDevice.isPad {
                playerView.frame = PhotoTools.transformImageSize(videoSize, toViewSize: view.size, directions: [.horizontal])
            }else {
                playerView.frame = PhotoTools.transformImageSize(videoSize, to: view)
            }
        }else {
            let leftMargin = 30 + UIDevice.leftMargin
            let width = view.width - leftMargin * 2
            var y: CGFloat = 10
            var height = cropView.y - y - 5
            if let modalPresentationStyle = navigationController?.modalPresentationStyle, UIDevice.isPortrait {
                if modalPresentationStyle == .fullScreen || modalPresentationStyle == .custom { height -= UIDevice.generalStatusBarHeight
                    y += UIDevice.generalStatusBarHeight
                }
            }else if (modalPresentationStyle == .fullScreen || modalPresentationStyle == .custom) && UIDevice.isPortrait {
                height -= UIDevice.generalStatusBarHeight
                y += UIDevice.generalStatusBarHeight
            }
            let rect = PhotoTools.transformImageSize(videoSize, toViewSize: CGSize(width: width, height: height), directions: [.horizontal])
            let playerFrame = CGRect(x: leftMargin + (width - rect.width) * 0.5, y: y + (height - rect.height) * 0.5, width: rect.width, height: rect.height)
            if !playerView.frame.equalTo(playerFrame) {
                playerView.frame = playerFrame
            }
        }
        if !scrollView.contentSize.equalTo(playerView.size) {
            scrollView.contentSize = playerView.size
        }
    }
    open override var prefersStatusBarHidden: Bool {
        return config.prefersStatusBarHidden
    }
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopAllOperations()
    }
    public func stopAllOperations() {
        stopPlayTimer()
        PhotoManager.shared.stopPlayMusic()
        if let url = networkVideoURL, viewDidDisappearCancelDownload {
            PhotoManager.shared.suspendTask(url)
            networkVideoURL = nil
        }
        viewDidDisappearCancelDownload = true
    }
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if navigationController?.topViewController != self && navigationController?.viewControllers.contains(self) == false {
            navigationController?.setNavigationBarHidden(false, animated: true)
        }
    }
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    deinit {
//        print("deinit \(self)")
    }
}

// MARK: PhotoAsset Request AVAsset
extension VideoEditorViewController {
    #if HXPICKER_ENABLE_PICKER
    func requestAVAsset() {
        if photoAsset.isNetworkAsset {
            networkVideoURL = photoAsset.networkVideoAsset?.videoURL
            downloadNetworkVideo()
            return
        }
        let loadingView = ProgressHUD.showLoading(addedTo: view, text: nil, animated: true)
        view.bringSubviewToFront(topView)
        assetRequestID = photoAsset.requestAVAsset(filterEditor: true, deliveryMode: .highQualityFormat) { [weak self] (photoAsset, requestID) in
            self?.assetRequestID = requestID
            loadingView?.updateText(text: "正在同步iCloud".localized + "...")
        } progressHandler: { (photoAsset, progress) in
            if progress > 0 {
                loadingView?.updateText(text: "正在同步iCloud".localized + "(" + String(Int(progress * 100)) + "%)")
            }
        } success: { [weak self] (photoAsset, avAsset, info) in
            ProgressHUD.hide(forView: self?.view, animated: false)
            self?.avAsset = avAsset
            self?.reqeustAssetCompletion = true
            self?.assetRequestComplete()
        } failure: { [weak self] (photoAsset, info, error) in
            if let info = info, !info.isCancel {
                ProgressHUD.hide(forView: self?.view, animated: false)
                if info.inICloud {
                    self?.assetRequestFailure(message: "iCloud同步失败".localized)
                }else {
                    self?.assetRequestFailure()
                }
            }
        }
    }
    #endif
    
    func assetRequestFailure(message: String = "视频获取失败!".localized) {
        PhotoTools.showConfirm(viewController: self, title: "提示".localized, message: message, actionTitle: "确定".localized) { (alertAction) in
            self.backAction()
        }
    }
    
    func assetRequestComplete() {
        videoSize = PhotoTools.getVideoThumbnailImage(avAsset: avAsset, atTime: 0.1)?.size ?? view.size
        playerView.avAsset = avAsset
        playerView.configAsset()
        cropView.avAsset = avAsset
        if orientationDidChange {
            setCropViewFrame()
        }
        if state == .cropping {
            state = .normal
            if playerView.playerLayer.isReadyForDisplay {
                firstPlay = false
                croppingAction()
            }
        }else {
            setPlayerViewFrame()
        }
        if let editResult = editResult {
            playerView.player.volume = editResult.videoSoundVolume
            musicView.originalSoundButton.isSelected = editResult.videoSoundVolume > 0
            if let audioURL = editResult.backgroundMusicURL {
                backgroundMusicPath = audioURL.path
                musicView.backgroundButton.isSelected = true
                PhotoManager.shared.playMusic(filePath: audioURL.path) {
                }
                backgroundMusicVolume = editResult.backgroundMusicVolume
            }
        }
    }
}

// MARK: DownloadNetworkVideo
extension VideoEditorViewController {
    func downloadNetworkVideo() {
        if let videoURL = networkVideoURL {
            let key = videoURL.absoluteString
            if PhotoTools.isCached(forVideo: key) {
                let localURL = PhotoTools.getVideoCacheURL(for: key)
                avAsset = AVAsset.init(url: localURL)
                avassetLoadValuesAsynchronously()
                return
            }
            loadingView = ProgressHUD.showLoading(addedTo: view, text: "视频下载中".localized, animated: true)
            view.bringSubviewToFront(topView)
            PhotoManager.shared.downloadTask(with: videoURL) {
                [weak self] (progress, task) in
                if progress > 0 {
                    self?.loadingView?.updateText(text: "视频下载中".localized + "(" + String(Int(progress * 100)) + "%)")
                }
            } completionHandler: { [weak self] (url, error, _) in
                if let url = url {
                    #if HXPICKER_ENABLE_PICKER
                    if let photoAsset = self?.photoAsset {
                        photoAsset.networkVideoAsset?.fileSize = url.fileSize
                    }
                    #endif
                    self?.loadingView = nil
                    ProgressHUD.hide(forView: self?.view, animated: false)
                    self?.avAsset = AVAsset.init(url: url)
                    self?.avassetLoadValuesAsynchronously()
                }else {
                    if let error = error as NSError?, error.code == NSURLErrorCancelled {
                        return
                    }
                    self?.loadingView = nil
                    ProgressHUD.hide(forView: self?.view, animated: false)
                    self?.assetRequestFailure()
                }
            }
        }
    }
    
    func avassetLoadValuesAsynchronously() {
        avAsset.loadValuesAsynchronously(forKeys: ["duration"]) { [weak self] in
            DispatchQueue.main.async {
                self?.reqeustAssetCompletion = true
                self?.assetRequestComplete()
            }
        }
    }
}

// MARK: VideoEditorPlayerViewDelegate
extension VideoEditorViewController: VideoEditorPlayerViewDelegate {
    func playerView(_ playerViewReadyForDisplay: VideoEditorPlayerView) {
        if firstPlay {
            croppingAction()
            firstPlay = false
        }
    }
    
    func playerView(_ playerView: VideoEditorPlayerView, didPlayAt time: CMTime) {
        if state == .cropping {
            cropView.startLineAnimation(at: time)
        }
    }
    
    func playerView(_ playerView: VideoEditorPlayerView, didPauseAt time: CMTime) {
        if state == .cropping {
            cropView.stopLineAnimation()
        }
    }
}

// MARK: VideoEditorCropViewDelegate
extension VideoEditorViewController: VideoEditorCropViewDelegate {
    func cropView(_ cropView: VideoEditorCropView, didScrollAt time: CMTime) {
        pausePlay(at: time)
    }
    func cropView(_ cropView: VideoEditorCropView, endScrollAt time: CMTime) {
        startPlay(at: time)
    }
    func cropView(_ cropView: VideoEditorCropView, didChangedValidRectAt time: CMTime) {
        pausePlay(at: time)
    }
    func cropView(_ cropView: VideoEditorCropView, endChangedValidRectAt time: CMTime) {
        startPlay(at: time)
    }
    func cropView(_ cropView: VideoEditorCropView, progressLineDragEndAt time: CMTime) {
        
    }
    func cropView(_ cropView: VideoEditorCropView, progressLineDragBeganAt time: CMTime) {
        
    }
    func cropView(_ cropView: VideoEditorCropView, progressLineDragChangedAt time: CMTime) {
        
    }
    func pausePlay(at time: CMTime) {
        if state == .cropping && !orientationDidChange {
            stopPlayTimer()
            playerView.shouldPlay = false
            playerView.playStartTime = time
            playerView.pause()
            playerView.seek(to: time)
            cropView.stopLineAnimation()
        }
    }
    func startPlay(at time: CMTime) {
        if state == .cropping && !orientationDidChange {
            playerView.playStartTime = time
            playerView.playEndTime = cropView.getEndTime(real: true)
            playerView.resetPlay()
            playerView.shouldPlay = true
            startPlayTimer()
        }
    }
    func startPlayTimer(reset: Bool = true) {
        startPlayTimer(reset: reset, startTime: cropView.getStartTime(real: true), endTime: cropView.getEndTime(real: true))
    }
    func startPlayTimer(reset: Bool = true, startTime: CMTime, endTime: CMTime) {
        stopPlayTimer()
        let playTimer = DispatchSource.makeTimerSource()
        var microseconds: Double
        if reset {
            microseconds = (endTime.seconds - startTime.seconds) * 1000000
        }else {
            microseconds = (playerView.player.currentTime().seconds - cropView.getStartTime(real: true).seconds) * 1000000
        }
        playTimer.schedule(deadline: .now(), repeating: .microseconds(Int(microseconds)), leeway: .microseconds(0))
        playTimer.setEventHandler(handler: {
            DispatchQueue.main.sync {
                self.playerView.resetPlay()
            }
        })
        playTimer.resume()
        self.playTimer = playTimer
    }
    func stopPlayTimer() {
        if let playTimer = playTimer {
            playTimer.cancel()
            self.playTimer = nil
        }
    }
}

// MARK: EditorToolViewDelegate
extension VideoEditorViewController: EditorToolViewDelegate {
    
    /// 导出视频
    /// - Parameter toolView: 底部工具视频
    func toolView(didFinishButtonClick toolView: EditorToolView) {
        if let startTime = playerView.playStartTime, let endTime = playerView.playEndTime {
            ProgressHUD.showLoading(addedTo: view, text: "视频导出中".localized, animated: true)
            PhotoTools.exportEditVideo(for: avAsset, timeRang: CMTimeRange(start: startTime, end: endTime), presentName: config.exportPresetName) { [weak self] (videoURL, error) in
                guard let self = self else {
                    return
                }
                if let videoURL = videoURL {
                    if self.backgroundMusicPath != nil || self.playerView.player.volume == 0 {
                        self.addBackgroundMusic(forVideo: videoURL)
                        return
                    }
                    self.editFinishCallBack(videoURL)
                    self.backAction()
                }else {
                    self.showErrorHUD()
                }
            }
        }else {
            if backgroundMusicPath != nil || playerView.player.volume == 0 {
                ProgressHUD.showLoading(addedTo: view, text: "视频导出中".localized, animated: true)
                let videoURL = PhotoTools.getVideoTmpURL()
                AssetManager.exportVideoURL(forVideo: avAsset, toFile: videoURL, exportPreset: config.exportPresetName) { [weak self] (url, error) in
                    if let url = url {
                        self?.addBackgroundMusic(forVideo: url)
                    }else {
                        self?.showErrorHUD()
                    }
                }
                return
            }
            delegate?.videoEditorViewController(didFinishWithUnedited: self)
            backAction()
        }
    }
    func addBackgroundMusic(forVideo videoURL: URL) {
        var audioURL: URL?
        if let musicPath = backgroundMusicPath {
            audioURL = URL(fileURLWithPath: musicPath)
        }
        PhotoTools.videoAddBackgroundMusic(forVideo: videoURL,
                                           audioURL: audioURL,
                                           audioVolume: backgroundMusicVolume,
                                           originalAudioVolume: playerView.player.volume,
                                           presentName: config.exportPresetName) { [weak self] (url) in
            if let url = url {
                self?.editFinishCallBack(url)
                self?.backAction()
            }else {
                self?.showErrorHUD()
            }
        }
    }
    func showErrorHUD() {
        ProgressHUD.hide(forView: view, animated: true)
        ProgressHUD.showWarning(addedTo: view, text: "导出失败".localized, animated: true, delayHide: 1.5)
    }
    func editFinishCallBack(_ videoURL: URL) {
        if let currentCropOffset = currentCropOffset {
            rotateBeforeStorageData = cropView.getRotateBeforeData(offsetX: currentCropOffset.x, validX: currentValidRect.minX, validWidth: currentValidRect.width)
        }
        rotateBeforeData = cropView.getRotateBeforeData()
        var cropData: VideoCropData?
        if let startTime = playerView.playStartTime,
           let endTime = playerView.playEndTime,
           let rotateBeforeStorageData = rotateBeforeStorageData,
           let rotateBeforeData = rotateBeforeData {
            cropData = VideoCropData.init(startTime: startTime.seconds,
                                          endTime: endTime.seconds,
                                          preferredTimescale: avAsset.duration.timescale,
                                          cropingData: .init(offsetX: rotateBeforeStorageData.0, validX: rotateBeforeStorageData.1, validWidth: rotateBeforeStorageData.2),
                                          cropRectData: .init(offsetX: rotateBeforeData.0, validX: rotateBeforeData.1, validWidth: rotateBeforeData.2))
        }
        var backgroundMusicURL: URL?
        if let audioPath = backgroundMusicPath {
            backgroundMusicURL = URL(fileURLWithPath: audioPath)
        }
        let editResult = VideoEditResult.init(editedURL: videoURL,
                                              cropData: cropData,
                                              videoSoundVolume: playerView.player.volume,
                                              backgroundMusicURL: backgroundMusicURL,
                                              backgroundMusicVolume: backgroundMusicVolume)
        delegate?.videoEditorViewController(self, didFinish: editResult)
    }
    func toolView(_ toolView: EditorToolView, didSelectItemAt model: EditorToolOptions) {
        if model.type == .music {
            if let shouldClick = delegate?.videoEditorViewController(shouldClickMusicTool: self),
               !shouldClick {
                return
            }
            if musicView.musics.isEmpty {
                if let showLoading = delegate?.videoEditorViewController(self, loadMusic: { [weak self] (infos) in
                    self?.musicView.reloadData(infos: infos)
                }) {
                    if showLoading {
                        musicView.showLoading()
                    }
                }else {
                    ProgressHUD.showWarning(addedTo: view, text: "暂无配乐".localized, animated: true, delayHide: 1.5)
                    return
                }
            }
            isMusicState = !isMusicState
            musicView.reloadContentOffset()
            updateMusicView()
            hidenTopView()
        }else if model.type == .cropping {
            croppingAction()
        }
    }
    
    func updateMusicView() {
        UIView.animate(withDuration: 0.25) {
            self.toolView.alpha = self.isMusicState ? 0 : 1
            self.setMusicViewFrame()
        } completion: { (_) in
            self.toolView.alpha = self.isMusicState ? 0 : 1
            self.setMusicViewFrame()
        }
    }
    
    /// 进入裁剪界面
    func croppingAction() {
        if state == .normal {
            beforeStartTime = playerView.playStartTime
            beforeEndTime = playerView.playEndTime
            if let offset = currentCropOffset {
                cropView.collectionView.setContentOffset(offset, animated: false)
            }else {
                let insetLeft = cropView.collectionView.contentInset.left
                let insetTop = cropView.collectionView.contentInset.top
                cropView.collectionView.setContentOffset(CGPoint(x: -insetLeft, y: -insetTop), animated: false)
            }
            if currentValidRect.equalTo(.zero) {
                cropView.resetValidRect()
            }else {
                cropView.frameMaskView.validRect = currentValidRect
                cropView.startLineAnimation(at: playerView.player.currentTime())
            }
            playerView.playStartTime = cropView.getStartTime(real: true)
            playerView.playEndTime = cropView.getEndTime(real: true)
            cropConfirmView.isHidden = false
            cropView.isHidden = false
            cropView.updateTimeLabels()
            state = .cropping
            if currentValidRect.equalTo(.zero) {
                playerView.resetPlay()
                startPlayTimer()
            }
            hidenTopView()
            UIView.animate(withDuration: 0.25, delay: 0, options: [.layoutSubviews]) {
                self.setPlayerViewFrame()
                self.cropView.alpha = 1
                self.cropConfirmView.alpha = 1
            } completion: { (isFinished) in
            }
        }
    }
}

// MARK: EditorCropConfirmViewDelegate
extension VideoEditorViewController: EditorCropConfirmViewDelegate {
    
    /// 点击完成按钮
    /// - Parameter cropConfirmView: 裁剪视图
    func cropConfirmView(didFinishButtonClick cropConfirmView: EditorCropConfirmView) {
        if onceState == .cropping {
            onceState = .normal
        }
        didEdited = true
        state = .normal
        cropView.stopScroll()
        currentCropOffset = cropView.collectionView.contentOffset
        currentValidRect = cropView.frameMaskView.validRect
        playerView.playStartTime = cropView.getStartTime(real: true)
        playerView.playEndTime = cropView.getEndTime(real: true)
        playerView.play()
        hiddenCropConfirmView()
    }
    
    /// 点击取消按钮
    /// - Parameter cropConfirmView: 裁剪视图
    func cropConfirmView(didCancelButtonClick cropConfirmView: EditorCropConfirmView) {
        if onceState == .cropping {
            backAction()
            return
        }
        state = .normal
        cropView.stopScroll()
        cropView.stopLineAnimation()
        playerView.playStartTime = beforeStartTime
        playerView.playEndTime = beforeEndTime
        hiddenCropConfirmView()
        guard let currentCropOffset = currentCropOffset, cropView.collectionView.contentOffset.equalTo(currentCropOffset) && cropView.frameMaskView.validRect.equalTo(currentValidRect) else {
            cropView.stopLineAnimation()
            playerView.resetPlay()
            if let startTime = beforeStartTime, let endTime = beforeEndTime {
                startPlayTimer(startTime: startTime, endTime: endTime)
            }else {
                stopPlayTimer()
            }
            return
        }
    }
    
    func hiddenCropConfirmView() {
        showTopView()
        UIView.animate(withDuration: 0.25) {
            self.cropView.alpha = 0
            self.cropConfirmView.alpha = 0
            self.setPlayerViewFrame()
        } completion: { (isFinished) in
            self.cropView.isHidden = true
            self.cropConfirmView.isHidden = true
        }
    }
}
// MARK: VideoEditorMusicViewDelegate
extension VideoEditorViewController: VideoEditorMusicViewDelegate {
    func musicView(_ musicView: VideoEditorMusicView, didSelectMusic audioPath: String?) {
        backgroundMusicPath = audioPath
    }
    func musicView(deselectMusic musicView: VideoEditorMusicView) {
        backgroundMusicPath = nil
    }
    func musicView(didSearchButton musicView: VideoEditorMusicView) {
        searchMusicView.searchView.becomeFirstResponder()
        isSearchMusic = true
        UIView.animate(withDuration: 0.25) {
            self.setSearchMusicViewFrame()
        }
    }
    func musicView(_ musicView: VideoEditorMusicView, didOriginalSoundButtonClick isSelected: Bool) {
        if isSelected {
            playerView.player.volume = 1
        }else {
            playerView.player.volume = 0
        }
    }
}
// MARK: VideoEditorSearchMusicViewDelegate
extension VideoEditorViewController: VideoEditorSearchMusicViewDelegate {
    func searchMusicView(didCancelClick searchMusicView: VideoEditorSearchMusicView) {
        hideSearchMusicView()
    }
    func searchMusicView(didFinishClick searchMusicView: VideoEditorSearchMusicView) {
        hideSearchMusicView(deselect: false)
    }
    func searchMusicView(_ searchMusicView: VideoEditorSearchMusicView, didSelectItem audioPath: String?) {
        musicView.reset()
        musicView.backgroundButton.isSelected = true
        backgroundMusicPath = audioPath
    }
    func searchMusicView(_ searchMusicView: VideoEditorSearchMusicView, didSearch text: String?, completion: @escaping ([VideoEditorMusicInfo], Bool) -> Void) {
        delegate?.videoEditorViewController(self, didSearch: text, completionHandler: completion)
    }
    func searchMusicView(_ searchMusicView: VideoEditorSearchMusicView, loadMore text: String?, completion: @escaping ([VideoEditorMusicInfo], Bool) -> Void) {
        delegate?.videoEditorViewController(self, loadMore: text, completionHandler: completion)
    }
    func searchMusicView(deselectItem searchMusicView: VideoEditorSearchMusicView) {
        backgroundMusicPath = nil
        musicView.backgroundButton.isSelected = false
    }
    func hideSearchMusicView(deselect: Bool = true) {
        searchMusicView.endEditing(true)
        isSearchMusic = false
        UIView.animate(withDuration: 0.25) {
            self.setSearchMusicViewFrame()
        } completion: { _ in
            if deselect {
                self.searchMusicView.deselect()
            }
            self.searchMusicView.clearData()
        }
    }
}
