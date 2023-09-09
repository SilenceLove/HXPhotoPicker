//
//  EditorViewController.swift
//  HXPhotoPicker
//
//  Created by Slience on 2023/1/11.
//

import UIKit
import AVFoundation
import Photos

extension EditorViewController {
    public typealias FinishHandler = (EditorAsset, EditorViewController) -> Void
    public typealias CancelHandler = (EditorViewController) -> Void
}

open class EditorViewController: BaseViewController {
    
    public weak var delegate: EditorViewControllerDelegate?
    public var config: EditorConfiguration
    public let assets: [EditorAsset]
    public var selectedAsset: EditorAsset
    public var editedResult: EditedResult?
    public var finishHandler: FinishHandler?
    public var cancelHandler: CancelHandler?
    
    public private(set) var selectedIndex: Int = 0
    
    public var topMaskView: UIView!
    public var bottomMaskView: UIView!
    public var topMaskLayer: CAGradientLayer!
    public var bottomMaskLayer: CAGradientLayer!
    
    public var selectedTool: EditorConfiguration.ToolsView.Options?
    
    public init(
        _ asset: EditorAsset,
        config: EditorConfiguration = .init(),
        delegate: EditorViewControllerDelegate? = nil,
        finish: FinishHandler? = nil,
        cancel: CancelHandler? = nil
    ) {
        PhotoManager.shared.createLanguageBundle(languageType: config.languageType)
        self.assets = [asset]
        self.selectedAsset = asset
        self.config = config
        self.delegate = delegate
        finishHandler = finish
        cancelHandler = cancel
        editedResult = asset.result
        finishRatioIndex = config.cropSize.defaultSeletedIndex
        super.init(nibName: nil, bundle: nil)
    }
    
    var videoControlView: EditorVideoControlView!
    var brushColorView: EditorBrushColorView!
    var brushSizeView: EditorBrushSizeView!
    var brushBlockView: EditorBrushBlockView!
    var filterEditView: EditorFilterEditView!
    var filtersView: EditorFiltersView!
    var filterParameterView: EditorFilterParameterView!
    var rotateScaleView: EditorScaleView!
    var ratioToolView: EditorRatioToolView!
    var mosaicToolView: EditorMosaicToolView!
    var musicView: EditorMusicView!
    var volumeView: EditorVolumeView!
    var toolsView: EditorToolsView!
    var cancelButton: UIButton!
    var finishButton: UIButton!
    var resetButton: UIButton!
    var leftRotateButton: UIButton!
    var rightRotateButton: UIButton!
    var mirrorHorizontallyButton: UIButton!
    var mirrorVerticallyButton: UIButton!
    var changeButton: UIButton!
    var maskListButton: UIButton!
    var scaleSwitchView: UIView!
    var scaleSwitchLeftBtn: UIButton!
    var scaleSwitchRightBtn: UIButton!
    var editorView: EditorView!
    
    var finishScaleAngle: CGFloat = 0
    var lastScaleAngle: CGFloat = 0
    var finishRatioIndex: Int
    
    var scaleSwitchSelectType: Int?
    var finishScaleSwitchSelectType: Int?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        imageFilterQueue = OperationQueue()
        imageFilterQueue.maxConcurrentOperationCount = 1
        
        initViews()
        addViews()
        initAsset()
    }
    
    private func initViews() {
        var cropTime = config.video.cropTime
        if config.isFixedCropSizeState && config.isIgnoreCropTimeWhenFixedCropSizeState {
            cropTime.maximumTime = 0
        }
        videoControlView = EditorVideoControlView(config: cropTime)
        videoControlView.delegate = self
        videoControlView.alpha = 0
        videoControlView.isHidden = true
        
        brushColorView = EditorBrushColorView(config: config.brush)
        brushColorView.delegate = self
        brushColorView.alpha = 0
        brushColorView.isHidden = true
        
        brushSizeView = EditorBrushSizeView()
        brushSizeView.alpha = 0
        brushSizeView.isHidden = true
        brushSizeView.value = config.brush.lineWidth / (config.brush.maximumLinewidth - config.brush.minimumLinewidth)
        brushSizeView.blockBeganChanged = { [weak self] _ in
            guard let self = self else { return }
            let lineWidth = self.editorView.drawLineWidth + 4
            self.brushBlockView.size = CGSize(width: lineWidth, height: lineWidth)
            self.showBrushBlockView()
        }
        brushSizeView.blockDidChanged = { [weak self] in
            guard let self = self else { return }
            let config = self.config.brush
            let lineWidth = (
                config.maximumLinewidth -  config.minimumLinewidth
            ) * $0 + config.minimumLinewidth
            self.editorView.drawLineWidth = lineWidth
            self.brushBlockView.size = CGSize(width: lineWidth + 4, height: lineWidth + 4)
            self.brushBlockView.center = CGPoint(x: self.view.width * 0.5, y: self.view.height * 0.5)
        }
        brushSizeView.blockEndedChanged = { [weak self] _ in
            guard let self = self else { return }
            self.hideBrushBlockView()
        }
        
        let lineWidth = config.brush.lineWidth + 4
        brushBlockView = EditorBrushBlockView()
        brushBlockView.color = config.brush.colors[config.brush.defaultColorIndex].color
        brushBlockView.size = .init(width: lineWidth, height: lineWidth)
        
        filterEditView = EditorFilterEditView()
        filterEditView.delegate = self
        filterEditView.alpha = 0
        filterEditView.isHidden = true
        
        filtersView = EditorFiltersView(
            filterConfig: selectedAsset.contentType == .image ? config.photo.filter : config.video.filter
        )
        filtersView.delegate = self
        filtersView.alpha = 0
        filtersView.isHidden = true
        
        let sliderColor: UIColor
        if selectedAsset.contentType == .image {
            sliderColor = config.photo.filter.selectedColor
        }else {
            sliderColor = config.video.filter.selectedColor
        }
        filterParameterView = EditorFilterParameterView(sliderColor: sliderColor)
        filterParameterView.delegate = self
        
        rotateScaleView = EditorScaleView()
        rotateScaleView.themeColor = config.cropSize.angleScaleColor
        rotateScaleView.angleChanged = { [weak self] in
            guard let self = self else { return }
            if self.editorView.state == .normal {
                return
            }
            if $1 == .begin {
                self.editorView.isContinuousRotation = true
            }
            self.editorView.rotate(self.lastScaleAngle - $0, animated: false)
            self.lastScaleAngle = $0
            if $1 == .end {
                self.editorView.isContinuousRotation = false
                self.resetButton.isEnabled = self.isReset
            }
        }
        rotateScaleView.alpha = 0
        rotateScaleView.isHidden = true
        
        ratioToolView = EditorRatioToolView(
            ratios: config.cropSize.aspectRatios,
            selectedIndex: config.cropSize.defaultSeletedIndex
        )
        ratioToolView.delegate = self
        ratioToolView.alpha = 0
        ratioToolView.isHidden = true
        
        mosaicToolView = EditorMosaicToolView(selectedColor: config.toolsView.toolSelectedColor)
        mosaicToolView.delegate = self
        mosaicToolView.alpha = 0
        mosaicToolView.isHidden = true
        
        musicView = EditorMusicView(config: config.video.music)
        musicView.delegate = self
        
        volumeView = EditorVolumeView(config.video.music.tintColor)
        volumeView.hasMusic = false
        volumeView.delegate = self
        
        toolsView = EditorToolsView(config: config.toolsView, contentType: selectedAsset.type.contentType)
        toolsView.delegate = self
        
        cancelButton = UIButton(type: .custom)
        cancelButton.setTitle("取消".localized, for: .normal)
        cancelButton.setTitleColor(config.cancelButtonTitleColor, for: .normal)
        cancelButton.setTitleColor(config.cancelButtonTitleColor.withAlphaComponent(0.5), for: .highlighted)
        cancelButton.titleLabel?.font = UIFont.regularPingFang(ofSize: 17)
        cancelButton.contentHorizontalAlignment = .left
        cancelButton.addTarget(self, action: #selector(didCancelButtonClick(button:)), for: .touchUpInside)
        
        finishButton = UIButton(type: .custom)
        finishButton.setTitle("完成".localized, for: .normal)
        finishButton.setTitleColor(config.finishButtonTitleNormalColor, for: .normal)
        finishButton.setTitleColor(config.finishButtonTitleNormalColor.withAlphaComponent(0.5), for: .highlighted)
        finishButton.setTitleColor(config.finishButtonTitleDisableColor.withAlphaComponent(0.5), for: .disabled)
        finishButton.titleLabel?.font = UIFont.regularPingFang(ofSize: 17)
        finishButton.contentHorizontalAlignment = .right
        finishButton.addTarget(self, action: #selector(didFinishButtonClick(button:)), for: .touchUpInside)
        finishButton.isEnabled = !config.isWhetherFinishButtonDisabledInUneditedState
        
        resetButton = UIButton(type: .custom)
        resetButton.setTitle("还原".localized, for: .normal)
        resetButton.setTitleColor(.white, for: .normal)
        resetButton.setTitleColor(.white.withAlphaComponent(0.5), for: .highlighted)
        resetButton.setTitleColor(.white.withAlphaComponent(0.5), for: .disabled)
        resetButton.titleLabel?.font = UIFont.regularPingFang(ofSize: 17)
        resetButton.addTarget(self, action: #selector(didResetButtonClick(button:)), for: .touchUpInside)
        resetButton.alpha = 0
        resetButton.isHidden = true
        
        leftRotateButton = UIButton.init(type: .system)
        leftRotateButton.setImage("hx_editor_photo_rotate_left".image, for: .normal)
        leftRotateButton.size = leftRotateButton.currentImage?.size ?? .zero
        leftRotateButton.tintColor = .white
        leftRotateButton.addTarget(self, action: #selector(didLeftRotateButtonClick(button:)), for: .touchUpInside)
        leftRotateButton.alpha = 0
        leftRotateButton.isHidden = true
        
        rightRotateButton = UIButton.init(type: .system)
        rightRotateButton.setImage("hx_editor_photo_rotate_right".image, for: .normal)
        rightRotateButton.size = rightRotateButton.currentImage?.size ?? .zero
        rightRotateButton.tintColor = .white
        rightRotateButton.addTarget(self, action: #selector(didRightRotateButtonClick(button:)), for: .touchUpInside)
        rightRotateButton.alpha = 0
        rightRotateButton.isHidden = true
        
        mirrorHorizontallyButton = UIButton.init(type: .system)
        mirrorHorizontallyButton.setImage("hx_editor_photo_mirror_horizontally".image, for: .normal)
        mirrorHorizontallyButton.size = mirrorHorizontallyButton.currentImage?.size ?? .zero
        mirrorHorizontallyButton.tintColor = .white
        mirrorHorizontallyButton.addTarget(self, action: #selector(didMirrorHorizontallyButtonClick(button:)), for: .touchUpInside)
        mirrorHorizontallyButton.alpha = 0
        mirrorHorizontallyButton.isHidden = true
        
        mirrorVerticallyButton = UIButton.init(type: .system)
        mirrorVerticallyButton.setImage("hx_editor_photo_mirror_vertically".image, for: .normal)
        mirrorVerticallyButton.size = mirrorVerticallyButton.currentImage?.size ?? .zero
        mirrorVerticallyButton.tintColor = .white
        mirrorVerticallyButton.addTarget(self, action: #selector(didMirrorVerticallyButtonClick(button:)), for: .touchUpInside)
        mirrorVerticallyButton.alpha = 0
        mirrorVerticallyButton.isHidden = true
        
        changeButton = UIButton(type: .custom)
        changeButton.setImage("hx_editor_change_asset".image, for: .normal)
        changeButton.size = changeButton.currentImage?.size ?? .zero
        changeButton.addTarget(self, action: #selector(didChangeButtonClick(button:)), for: .touchUpInside)
        changeButton.layer.shadowColor = UIColor.black.withAlphaComponent(0.5).cgColor
        changeButton.layer.shadowOpacity = 1
        changeButton.layer.shadowRadius = 10
        changeButton.alpha = 0
        changeButton.isHidden = true
        
        maskListButton = UIButton(type: .custom)
        maskListButton.setImage("hx_editor_crop_mask_list".image, for: .normal)
        maskListButton.size = maskListButton.currentImage?.size ?? .zero
        maskListButton.tintColor = .white
        maskListButton.addTarget(self, action: #selector(didMaskListButtonClick(button:)), for: .touchUpInside)
        maskListButton.alpha = 0
        maskListButton.isHidden = true
        
        scaleSwitchLeftBtn = UIButton(type: .custom)
        scaleSwitchLeftBtn.setImage("hx_editor_crop_scale_switch_left".image, for: .normal)
        scaleSwitchLeftBtn.setImage("hx_editor_crop_scale_switch_left_selected".image, for: .selected)
        scaleSwitchLeftBtn.size = scaleSwitchLeftBtn.currentImage?.size ?? .zero
        scaleSwitchLeftBtn.addTarget(self, action: #selector(didScaleSwitchLeftBtn(button:)), for: .touchUpInside)
        
        scaleSwitchRightBtn = UIButton(type: .custom)
        scaleSwitchRightBtn.setImage("hx_editor_crop_scale_switch_right".image, for: .normal)
        scaleSwitchRightBtn.setImage("hx_editor_crop_scale_switch_right_selected".image, for: .selected)
        scaleSwitchRightBtn.size = scaleSwitchRightBtn.currentImage?.size ?? .zero
        scaleSwitchRightBtn.addTarget(self, action: #selector(didScaleSwitchRightBtn(button:)), for: .touchUpInside)
        
        scaleSwitchView = UIView()
        scaleSwitchView.alpha = 0
        scaleSwitchView.isHidden = true
        scaleSwitchView.addSubview(scaleSwitchLeftBtn)
        scaleSwitchView.addSubview(scaleSwitchRightBtn)
        
        editorView = EditorView()
        editorView.editContentInset = { [weak self] _ in
            guard let self = self else {
                return .zero
            }
            if UIDevice.isPortrait {
                let isFullScreen: Bool
                if let nav = self.navigationController {
                    isFullScreen = nav.modalPresentationStyle == .fullScreen || nav.modalPresentationStyle == .custom
                }else {
                    isFullScreen = self.modalPresentationStyle == .fullScreen || self.modalPresentationStyle == .custom
                }
                let top: CGFloat
                let bottom: CGFloat
                if self.config.buttonType == .bottom {
                    if isFullScreen {
                        top = UIDevice.isPad ? 50 : UIDevice.topMargin + 10
                    }else {
                        top = 30
                    }
                    bottom = UIDevice.bottomMargin + 55 + 140
                }else {
                    let navHeight: CGFloat
                    if let barHeight = self.navigationController?.navigationBar.height {
                        navHeight = barHeight
                    }else {
                        navHeight = UIDevice.navigationBarHeight - UIDevice.generalStatusBarHeight
                    }
                    if isFullScreen {
                        let navY: CGFloat
                        if UIDevice.isPad {
                            navY = UIDevice.generalStatusBarHeight
                        }else {
                            if let barY = self.navigationController?.navigationBar.y, barY >= 0 {
                                navY = barY
                            }else {
                                navY = UIDevice.generalStatusBarHeight
                            }
                        }
                        top = navY + navHeight + 10
                    }else {
                        top = navHeight + 10
                    }
                    if UIDevice.isPad {
                        bottom = UIDevice.bottomMargin + 150
                    }else {
                        bottom = UIDevice.bottomMargin + 140
                    }
                }
                let left = UIDevice.isPad ? 30 : UIDevice.leftMargin + 15
                let right = UIDevice.isPad ? 30 : UIDevice.rightMargin + 15
                return .init(top: top, left: left, bottom: bottom, right: right)
            }else {
                let margin = self.view.width - self.rotateScaleView.x + 15
                return .init(
                    top: UIDevice.topMargin + 55,
                    left: margin,
                    bottom: UIDevice.bottomMargin + 15,
                    right: margin
                )
            }
        }
        editorView.urlConfig = config.urlConfig
        editorView.exportScale = config.photo.scale
        editorView.initialRoundMask = config.cropSize.isRoundCrop
        editorView.initialFixedRatio = config.cropSize.isFixedRatio
        editorView.initialAspectRatio = config.cropSize.aspectRatio
        editorView.maskType = config.cropSize.maskType
        editorView.isShowScaleSize = config.cropSize.isShowScaleSize
        if config.cropSize.isFixedRatio {
            editorView.isResetIgnoreFixedRatio = config.cropSize.isResetToOriginal
        }else {
            editorView.isResetIgnoreFixedRatio = true
        }
        if !config.brush.colors.isEmpty {
            editorView.drawLineColor = config.brush.colors[
                min(max(config.brush.defaultColorIndex, 0), config.brush.colors.count - 1)
            ].color
        }
        editorView.drawLineWidth = config.brush.lineWidth
        editorView.mosaicWidth = config.mosaic.mosaiclineWidth
        editorView.smearWidth = config.mosaic.smearWidth
        editorView.editDelegate = self
        editorView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapClick)))
        
        topMaskLayer = PhotoTools.getGradientShadowLayer(true)
        topMaskView = UIView()
        topMaskView.isUserInteractionEnabled = false
        topMaskView.layer.addSublayer(topMaskLayer)
        
        bottomMaskLayer = PhotoTools.getGradientShadowLayer(false)
        bottomMaskView = UIView()
        bottomMaskView.isUserInteractionEnabled = false
        bottomMaskView.layer.addSublayer(bottomMaskLayer)
    }
    
    private func addViews() {
        view.clipsToBounds = true
        view.backgroundColor = .black
        view.addSubview(editorView)
        view.addSubview(bottomMaskView)
        view.addSubview(topMaskView)
        view.addSubview(videoControlView)
        view.addSubview(brushColorView)
        view.addSubview(brushSizeView)
        view.addSubview(filtersView)
        view.addSubview(filterEditView)
        view.addSubview(rotateScaleView)
        if !config.cropSize.aspectRatios.isEmpty {
            view.addSubview(ratioToolView)
            for aspectRatio in config.cropSize.aspectRatios
                where aspectRatio.ratio.width < 0 || aspectRatio.ratio.height < 0 {
                view.addSubview(scaleSwitchView)
            }
        }
        view.addSubview(mosaicToolView)
        if !config.isFixedCropSizeState {
            view.addSubview(toolsView)
        }
        
        view.addSubview(resetButton)
        view.addSubview(cancelButton)
        view.addSubview(finishButton)
        
        view.addSubview(leftRotateButton)
        view.addSubview(rightRotateButton)
        view.addSubview(mirrorHorizontallyButton)
        view.addSubview(mirrorVerticallyButton)
        
        if !config.cropSize.maskList.isEmpty {
            view.addSubview(maskListButton)
        }
        
        view.addSubview(changeButton)
        
        view.addSubview(filterParameterView)
        
        view.addSubview(musicView)
        view.addSubview(volumeView)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterPlayGround),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    var didEnterPlayGround: Bool = false
    @objc
    func appDidEnterBackground() {
        didEnterPlayGround = true
        musicPlayer?.pausePlay()
    }
    
    @objc
    func appDidEnterPlayGround() {
        if didEnterPlayGround {
            musicPlayer?.startPlay()
        }
        didEnterPlayGround = false
    }
    
    var isDismissed: Bool = false
    var isPopTransition: Bool = false
    var isTransitionCompletion: Bool = true
    var loadAssetStatus: LoadAssetStatus = .loadding()
    var assetLoadingView: ProgressHUD?
    
    var selectedOriginalImage: UIImage?
    var selectedThumbnailImage: UIImage?
    var selectedMosaicImage: CGImage?
    
    var assetRequestID: PHImageRequestID?
    var isLoadCompletion: Bool = false
    var isLoadVideoControl: Bool = false
    var lastSelectedTool: EditorConfiguration.ToolsView.Options?
    var isToolsDisplay: Bool = true
    weak var videoPlayTimer: Timer?
    var orientationDidChange: Bool = false
    var videoControlInfo: EditorVideoControlInfo?
    
    weak var audioSticker: EditorStickersItemBaseView?
    var isSelectedOriginalSound: Bool = true {
        didSet {
            volumeView.hasOriginalSound = isSelectedOriginalSound
            checkFinishButtonState()
        }
    }
    var selectedMusicURL: VideoEditorMusicURL? {
        didSet {
            if let task = lastMusicDownloadTask {
                task.cancel()
                lastMusicDownloadTask = nil
            }
            toolsView.musicCellShowBox = selectedMusicURL != nil
            checkFinishButtonState()
        }
    }
    
    var videoVolume: Float = 1 {
        didSet {
            editorView.videoVolume = CGFloat(videoVolume)
            checkFinishButtonState()
        }
    }
    var musicVolume: Float = 1 {
        didSet {
            musicPlayer?.volume = musicVolume
            checkFinishButtonState()
        }
    }
    var musicPlayer: EditorPlayAuido? {
        didSet {
            volumeView.hasMusic = musicPlayer != nil
            checkFinishButtonState()
        }
    }
    var imageFilter: PhotoEditorFilter?
    var videoFilterInfo: PhotoEditorFilterInfo?
    var videoFilter: VideoEditorFilter?
    var filterEditFator: EditorFilterEditFator = .init()
    var imageFilterContext: CIContext = CIContext(options: nil)
    var imageFilterQueue: OperationQueue!
    
    var isStartFilterParameterTime: CMTime?
    var lastMusicDownloadTask: URLSessionDownloadTask?
    weak var videoTool: EditorVideoTool?
    
    public override func deviceOrientationWillChanged(notify: Notification) {
        orientationDidChange = true
        if editorView.type == .video {
            if #available(iOS 14.0, *), ProcessInfo.processInfo.isiOSAppOnMac, editorView.isVideoPlaying {
                stopPlayVideo()
                editorView.pauseVideo()
            }
            videoControlView.stopScroll()
            videoControlView.stopLineAnimation()
            videoControlInfo = videoControlView.controlInfo
        }
    }
    
    var navFrame: CGRect?
    
    var firstAppear = true
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        editorView.frame = view.bounds
        let buttonHeight: CGFloat
        if UIDevice.isPortrait && config.buttonType == .bottom {
            buttonHeight = 50
        }else {
            buttonHeight = 44
        }
        let cancelWidth: CGFloat
        if let title = cancelButton.currentTitle,
           let font = cancelButton.titleLabel?.font {
            cancelWidth = title.width(ofFont: font, maxHeight: buttonHeight)
        }else {
            cancelWidth = 0
        }
        let finishWidth: CGFloat
        if let title = finishButton.currentTitle,
           let font = finishButton.titleLabel?.font {
            finishWidth = title.width(ofFont: font, maxHeight: buttonHeight)
        }else {
            finishWidth = 0
        }
        let resetWidth: CGFloat
        if let title = resetButton.currentTitle,
           let font = resetButton.titleLabel?.font {
            resetWidth = title.width(ofFont: font, maxHeight: buttonHeight)
        }else {
            resetWidth = 0
        }
        
        cancelButton.height = buttonHeight
        finishButton.height = buttonHeight
        cancelButton.width = cancelWidth + 10
        finishButton.width = finishWidth + 10
        
        let buttonMargin: CGFloat
        if #available(iOS 14.0, *), ProcessInfo.processInfo.isiOSAppOnMac {
            buttonMargin = 12
        }else {
            buttonMargin = UIDevice.isPad ? 20 : 12
        }
        cancelButton.x = UIDevice.leftMargin + buttonMargin
        finishButton.x = view.width - finishButton.width - buttonMargin - UIDevice.rightMargin
        
        resetButton.size = .init(width: resetWidth, height: buttonHeight)
        resetButton.centerX = view.width * 0.5
        brushSizeView.size = .init(width: 30, height: 200)
        brushSizeView.centerY = view.height * 0.5
        bottomMaskLayer.removeFromSuperlayer()
        
        changeButton.centerX = view.width / 2
        
        if UIDevice.isPortrait {
            layoutPortraitViews(buttonHeight)
        }else {
            layoutNotPortraitViews()
        }
        topMaskLayer.frame = topMaskView.bounds
        updateBottomMaskLayer()
        filterEditView.frame = filtersView.frame
        updateMusicViewFrame()
        updateVolumeViewFrame()
        updateFilterParameterViewFrame()
        if firstAppear {
            loadVideoControl()
            if isLoadCompletion {
                selectedDefaultTool()
            }
            loadCorpSizeData()
            editorView.layoutSubviews()
            checkLastResultState()
            firstAppear = false
        }
        updateVideoControlInfo()
        if orientationDidChange {
            editorView.update()
            DispatchQueue.main.async {
                self.filtersView.scrollToSelectedCell()
                if let selectedTool = self.selectedTool {
                    self.toolsView.scrollToOption(with: selectedTool.type)
                }
                self.musicView.scrollToSelected()
            }
            orientationDidChange = false
        }
    }
    
    func layoutPortraitViews(_ buttonHeight: CGFloat) {
        changeButton.y = UIDevice.topMargin
        bottomMaskLayer = PhotoTools.getGradientShadowLayer(false)
        bottomMaskView.layer.addSublayer(bottomMaskLayer)
        if isToolsDisplay {
            if config.buttonType == .bottom {
                topMaskView.alpha = 0
                topMaskView.isHidden = true
            }else {
                if isTransitionCompletion && !isPopTransition {
                    topMaskView.alpha = 1
                }
                topMaskView.isHidden = false
            }
            if isTransitionCompletion && !isPopTransition {
                bottomMaskView.alpha = 1
            }
            bottomMaskView.isHidden = false
        }
        
        if config.buttonType == .bottom {
            cancelButton.y = view.height - UIDevice.bottomMargin - buttonHeight
            finishButton.centerY = cancelButton.centerY
            resetButton.centerY = cancelButton.centerY
            
            toolsView.frame = CGRect(
                x: cancelButton.frame.maxX,
                y: view.height - UIDevice.bottomMargin - buttonHeight,
                width: finishButton.x - cancelButton.frame.maxX,
                height: buttonHeight + UIDevice.bottomMargin
            )
            if !config.cropSize.aspectRatios.isEmpty {
                ratioToolView.frame = .init(x: 0, y: toolsView.y - 40, width: view.width, height: 40)
                rotateScaleView.frame = .init(x: 0, y: ratioToolView.y - 45, width: view.width, height: 45)
            }else {
                rotateScaleView.frame = .init(x: 0, y: toolsView.y - 45, width: view.width, height: 45)
            }
        }else {
            let toolsHeight: CGFloat
            let ratioToolHeight: CGFloat
            #if targetEnvironment(macCatalyst)
            toolsHeight = 55
            ratioToolHeight = 50
            #else
            if UIDevice.isPad {
                toolsHeight = 55
                ratioToolHeight = 50
            }else {
                toolsHeight = buttonHeight
                ratioToolHeight = 40
            }
            #endif
            let isFullScreen: Bool
            if let nav = navigationController {
                isFullScreen = nav.modalPresentationStyle == .fullScreen || nav.modalPresentationStyle == .custom
            }else {
                isFullScreen = modalPresentationStyle == .fullScreen || modalPresentationStyle == .custom
            }
            if navFrame == nil {
                navFrame = navigationController?.navigationBar.frame
            }
            let navHeight: CGFloat
            if let frameHeight = navFrame?.height {
                navHeight = frameHeight
            }else {
                navHeight = UIDevice.navigationBarHeight - UIDevice.generalStatusBarHeight
            }
            if isFullScreen {
                let navY: CGFloat
                if UIDevice.isPad {
                    navY = UIDevice.generalStatusBarHeight
                }else {
                    if let minY = navFrame?.minY, minY >= 0 {
                        navY = minY
                    }else {
                        navY = UIDevice.generalStatusBarHeight
                    }
                }
                cancelButton.centerY = navY + navHeight / 2
                topMaskView.frame = .init(x: 0, y: 0, width: view.width, height: navY + navHeight + 10)
            }else {
                cancelButton.centerY = navHeight / 2
                topMaskView.frame = .init(x: 0, y: 0, width: view.width, height: navHeight)
            }
            finishButton.centerY = cancelButton.centerY
            resetButton.centerY = cancelButton.centerY
            
            toolsView.frame = CGRect(
                x: 0,
                y: view.height - UIDevice.bottomMargin - toolsHeight,
                width: view.width,
                height: toolsHeight + UIDevice.bottomMargin
            )
            let rotateBottom: CGFloat
            if #available(iOS 14.0, *), ProcessInfo.processInfo.isiOSAppOnMac {
                rotateBottom = UIDevice.bottomMargin + 5
            }else {
                rotateBottom = UIDevice.bottomMargin
            }
            if !config.cropSize.aspectRatios.isEmpty {
                ratioToolView.frame = .init(
                    x: 0,
                    y: view.height - rotateBottom - ratioToolHeight,
                    width: view.width,
                    height: ratioToolHeight
                )
                rotateScaleView.frame = .init(x: 0, y: ratioToolView.y - 45, width: view.width, height: 45)
            }else {
                rotateScaleView.frame = .init(
                    x: 0,
                    y: view.height - rotateBottom - 45,
                    width: view.width,
                    height: 45
                )
            }
            if UIDevice.isPad {
                leftRotateButton.centerY = cancelButton.centerY
                leftRotateButton.x = cancelButton.frame.maxX + 20
                rightRotateButton.centerY = leftRotateButton.centerY
                rightRotateButton.x = leftRotateButton.frame.maxX + 20
                
                mirrorHorizontallyButton.x = finishButton.x - mirrorHorizontallyButton.width - 20
                mirrorVerticallyButton.x = mirrorHorizontallyButton.x - 20 - mirrorVerticallyButton.width
                mirrorHorizontallyButton.centerY = leftRotateButton.centerY
                mirrorVerticallyButton.centerY = mirrorHorizontallyButton.centerY
                
                maskListButton.y = rotateScaleView.y - maskListButton.height - 10
                maskListButton.centerX = view.width / 2
            }
        }
        
        filtersView.frame = .init(x: 0, y: toolsView.y - 120, width: view.width, height: 120)
        brushColorView.frame = .init(x: 0, y: toolsView.y - 65, width: view.width, height: 65)
        brushSizeView.x = view.width - 45 - UIDevice.rightMargin
        mosaicToolView.frame =  .init(x: 0, y: toolsView.y - 65, width: view.width, height: 65)
        
        if !UIDevice.isPad || config.buttonType == .bottom {
            leftRotateButton.y = rotateScaleView.y - leftRotateButton.height - 10
            leftRotateButton.x = UIDevice.leftMargin + 20
            rightRotateButton.centerY = leftRotateButton.centerY
            rightRotateButton.x = leftRotateButton.frame.maxX + 15
            
            mirrorHorizontallyButton.x = view.width - UIDevice.rightMargin - mirrorHorizontallyButton.width - 20
            mirrorVerticallyButton.x = mirrorHorizontallyButton.x - 15 - mirrorVerticallyButton.width
            mirrorHorizontallyButton.centerY = leftRotateButton.centerY
            mirrorVerticallyButton.centerY = mirrorHorizontallyButton.centerY
            
            maskListButton.centerY = mirrorVerticallyButton.centerY
            maskListButton.centerX = view.width / 2
        }
        
        scaleSwitchLeftBtn.x = 0
        scaleSwitchRightBtn.x = scaleSwitchLeftBtn.frame.maxX + 15
        scaleSwitchView.height = scaleSwitchLeftBtn.height
        scaleSwitchView.width = scaleSwitchRightBtn.frame.maxX
        scaleSwitchRightBtn.centerY = scaleSwitchView.height / 2
        scaleSwitchView.x = view.width / 2 - (scaleSwitchLeftBtn.width + 7.5)
        if UIDevice.isPad {
            scaleSwitchView.y = rotateScaleView.y - scaleSwitchView.height - 10
        }else {
            scaleSwitchView.centerY = leftRotateButton.centerY
        }
        if let type = selectedTool?.type {
            switch type {
            case .cropSize:
                if let ratio = ratioToolView.selectedRatio?.ratio, (ratio.width < 0 || ratio.height < 0) {
                    showScaleSwitchView(true)
                }else {
                    showScaleSwitchView(false)
                }
            default:
                break
            }
        }
        
        if orientationDidChange || firstAppear {
            videoControlView.frame = .init(x: 0, y: toolsView.y - 80, width: view.width, height: 50)
        }
    }
    
    func layoutNotPortraitViews() {
        bottomMaskLayer = PhotoTools.getGradientShadowLayer(
            startPoint: .init(x: 0, y: 0),
            endPoint: .init(x: 1, y: 0)
        )
        bottomMaskView.isHidden = true
        if isTransitionCompletion && !isPopTransition {
            bottomMaskView.alpha = 0
        }
        bottomMaskView.layer.addSublayer(bottomMaskLayer)
        if isToolsDisplay {
            topMaskView.isHidden = false
            bottomMaskView.isHidden = false
            if isTransitionCompletion && !isPopTransition {
                topMaskView.alpha = 1
                bottomMaskView.alpha = 1
            }
        }
        topMaskView.frame = .init(x: 0, y: 0, width: view.width, height: UIDevice.topMargin + 50)
        
        cancelButton.y = UIDevice.topMargin
        finishButton.centerY = cancelButton.centerY
        resetButton.centerY = cancelButton.centerY
        changeButton.centerY = cancelButton.centerY
        
        leftRotateButton.centerY = cancelButton.centerY
        leftRotateButton.x = cancelButton.frame.maxX + 15
        rightRotateButton.centerY = cancelButton.centerY
        rightRotateButton.x = leftRotateButton.frame.maxX + 15
        
        mirrorHorizontallyButton.x = finishButton.x - mirrorHorizontallyButton.width - 15
        mirrorVerticallyButton.x = mirrorHorizontallyButton.x - 15 - mirrorVerticallyButton.width
        mirrorHorizontallyButton.centerY = cancelButton.centerY
        mirrorVerticallyButton.centerY = mirrorHorizontallyButton.centerY
        
        maskListButton.centerY = mirrorVerticallyButton.centerY
        maskListButton.x = mirrorVerticallyButton.x - 15 - maskListButton.width
        
        toolsView.frame = CGRect(
            x: view.width - UIDevice.rightMargin - 50,
            y: cancelButton.frame.maxY,
            width: 50 + UIDevice.rightMargin,
            height: view.height - cancelButton.frame.maxY
        )
        if !config.cropSize.aspectRatios.isEmpty {
            var ratioWidth: CGFloat = 50
            for ratio in ratioToolView.ratios {
                let itemWidth = ratio.title.width(ofFont: .systemFont(ofSize: 14), maxHeight: .max) + 12
                if itemWidth > ratioWidth {
                    ratioWidth = itemWidth
                }
            }
            ratioWidth = min(120, ratioWidth)
            ratioToolView.frame = .init(
                x: view.width - UIDevice.rightMargin - ratioWidth,
                y: cancelButton.frame.maxY,
                width: ratioWidth,
                height: view.height - cancelButton.frame.maxY
            )
            rotateScaleView.frame = .init(
                x: ratioToolView.x - 50,
                y: ratioToolView.y,
                width: 50,
                height: view.height - ratioToolView.y
            )
        }else {
            rotateScaleView.frame = .init(
                x: view.width - UIDevice.rightMargin - 50,
                y: cancelButton.frame.maxY,
                width: 50,
                height: view.height - cancelButton.frame.maxY
            )
        }
        filtersView.frame = .init(x: toolsView.x - 120, y: toolsView.y, width: 120, height: toolsView.height)
        brushColorView.frame = .init(x: toolsView.x - 65, y: 0, width: 65, height: view.height)
        brushSizeView.x = UIDevice.leftMargin + 12
        mosaicToolView.frame =  .init(x: toolsView.x - 65, y: 0, width: 65, height: view.height)
        if orientationDidChange || firstAppear {
            videoControlView.frame = .init(
                x: 0,
                y: view.height - UIDevice.bottomMargin - 60,
                width: view.width, height: 40
            )
        }
        scaleSwitchRightBtn.x = 0
        scaleSwitchRightBtn.y = scaleSwitchLeftBtn.frame.maxY + 15
        scaleSwitchView.height = scaleSwitchRightBtn.frame.maxY
        scaleSwitchView.width = scaleSwitchRightBtn.width
        scaleSwitchLeftBtn.centerX = scaleSwitchView.width / 2
        
        scaleSwitchView.x = UIDevice.leftMargin + 15
        scaleSwitchView.centerY = view.height / 2
        
        if let type = selectedTool?.type {
            switch type {
            case .cropSize:
                if let ratio = ratioToolView.selectedRatio?.ratio, (ratio.width < 0 || ratio.height < 0) {
                    showScaleSwitchView()
                    maskListButton.isHidden = false
                    maskListButton.alpha = 1
                }else {
                    hideScaleSwitchView(true)
                }
            default:
                break
            }
        }
    }
    
    func updateVideoControlInfo() {
        if let videoControlInfo = videoControlInfo {
            videoControlView.reloadVideo()
            videoControlView.layoutIfNeeded()
            if #available(iOS 14.0, *), ProcessInfo.processInfo.isiOSAppOnMac {
                videoControlView.setControlInfo(videoControlInfo)
                videoControlView.resetLineViewFrsme(at: editorView.videoPlayTime)
                updateVideoTimeRange()
            }else {
                DispatchQueue.main.async {
                    self.videoControlView.setControlInfo(videoControlInfo)
                    self.videoControlView.resetLineViewFrsme(at: self.editorView.videoPlayTime)
                    self.updateVideoTimeRange()
                }
            }
            self.videoControlInfo = nil
        }
    }
    
    func updateBottomMaskLayer() {
        if UIDevice.isPortrait {
            let layerHeight: CGFloat
            if let selectedTool = selectedTool {
                switch selectedTool.type {
                case .graffiti, .mosaic:
                    layerHeight = UIDevice.bottomMargin + 130
                case .music:
                    layerHeight = UIDevice.bottomMargin + 55
                default:
                    layerHeight = UIDevice.bottomMargin + 180
                }
            }else {
                layerHeight = UIDevice.bottomMargin + 55
            }
            bottomMaskView.frame = .init(x: 0, y: view.height - layerHeight, width: view.width, height: layerHeight)
        }else {
            let layerWidth: CGFloat
            if let selectedTool = selectedTool, selectedTool.type != .time {
                switch selectedTool.type {
                case .graffiti, .mosaic:
                    layerWidth = 130 + UIDevice.rightMargin
                case .music:
                    layerWidth = 65 + UIDevice.rightMargin
                default:
                    layerWidth = 180 + UIDevice.rightMargin
                }
            }else {
                layerWidth = 65 + UIDevice.rightMargin
            }
            bottomMaskView.frame = .init(x: view.width - layerWidth, y: 0, width: layerWidth, height: view.height)
        }
        bottomMaskLayer.frame = bottomMaskView.bounds
    }
    
    func updateMusicViewFrame() {
        let marginHeight: CGFloat = 190
        let musicY: CGFloat
        let musicHeight: CGFloat
        let bottomMargin: CGFloat
        if #available(iOS 14.0, *), ProcessInfo.processInfo.isiOSAppOnMac {
            bottomMargin = UIDevice.bottomMargin + 5
        }else {
            bottomMargin = UIDevice.bottomMargin
        }
        if let type = selectedTool?.type,
           type == .music {
            musicY = view.height - marginHeight - bottomMargin
            musicHeight = marginHeight + bottomMargin
        }else {
            musicY = view.height
            musicHeight = marginHeight + bottomMargin
        }
        musicView.frame = CGRect(
            x: 0,
            y: musicY,
            width: view.width,
            height: musicHeight
        )
    }
    
    var isShowVolume: Bool = false
    
    func updateVolumeViewFrame() {
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
        let marginWidth: CGFloat
        if UIDevice.isPortrait {
            marginWidth = UIDevice.leftMargin + UIDevice.rightMargin + 30
        }else {
            marginWidth = UIDevice.leftMargin + UIDevice.rightMargin + 100
        }
        volumeView.frame = CGRect(
            x: marginWidth * 0.5,
            y: volumeY,
            width: view.width - marginWidth,
            height: volumeHeight
        )
    }
    
    var isShowFilterParameter: Bool = false
    func updateFilterParameterViewFrame() {
        let viewFrame: CGRect
        if UIDevice.isPortrait {
            let editHeight = max(
                CGFloat(filterParameterView.models.count) * 40 + 30 + UIDevice.bottomMargin,
                150 + UIDevice.bottomMargin
            )
            if isShowFilterParameter {
                viewFrame = .init(
                    x: 0,
                    y: view.height - editHeight,
                    width: view.width,
                    height: editHeight
                )
            }else {
                viewFrame = .init(
                    x: 0,
                    y: view.height,
                    width: view.width,
                    height: editHeight
                )
            }
        }else {
            let editWidth = max(
                CGFloat(filterParameterView.models.count) * 40 + 30 + UIDevice.rightMargin,
                150 + UIDevice.rightMargin
            )
            if isShowFilterParameter {
                viewFrame = .init(
                    x: view.width - editWidth,
                    y: 0,
                    width: editWidth,
                    height: view.height
                )
            }else {
                viewFrame = .init(
                    x: view.width,
                    y: 0,
                    width: editWidth,
                    height: view.height
                )
            }
        }
        filterParameterView.frame = viewFrame
    }
    
    public override var shouldAutorotate: Bool {
        config.shouldAutorotate
    }
    public override var prefersStatusBarHidden: Bool {
        config.prefersStatusBarHidden
    }
    open override var prefersHomeIndicatorAutoHidden: Bool {
        false
    }
    open override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        .all
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
        if navigationController?.viewControllers.count == 1 {
            navigationController?.setNavigationBarHidden(true, animated: false)
        }else {
            navigationController?.setNavigationBarHidden(true, animated: true)
        }
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let isHidden = navigationController?.navigationBar.isHidden, !isHidden {
            navigationController?.setNavigationBarHidden(true, animated: false)
        }
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let vcs = navigationController?.viewControllers {
            if !vcs.contains(self) {
                if !isDismissed {
                    cancelHandler?(self)
                }
                removeVideo()
            }
        }else if presentingViewController == nil {
            if !isDismissed {
                cancelHandler?(self)
            }
            removeVideo()
        }
    }
    
    func removeVideo() {
        if editorView.type == .video {
            editorView.pauseVideo()
            musicPlayer?.stopPlay()
            musicPlayer = nil
            editorView.cancelVideoCroped()
            videoTool?.cancelExport()
            videoTool = nil
        }
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        removeVideo()
    }
}
