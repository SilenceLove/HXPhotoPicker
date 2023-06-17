//
//  EditorViewController.swift
//  HXPhotoPicker
//
//  Created by Slience on 2023/1/11.
//

import UIKit
import AVKit
import Photos

extension EditorViewController {
    public typealias FinishHandler = (EditedResult?, EditorViewController) -> Void
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
    
    public init(
        _ asset: EditorAsset,
        config: EditorConfiguration = .init(),
        delegate: EditorViewControllerDelegate? = nil,
        finish: FinishHandler? = nil,
        cancel: CancelHandler? = nil
    ) {
        self.assets = [asset]
        self.selectedAsset = asset
        self.config = config
        self.delegate = delegate
        finishHandler = finish
        cancelHandler = cancel
        editedResult = asset.result
        super.init(nibName: nil, bundle: nil)
    }
    
    public private(set) var selectedIndex: Int = 0
    
    lazy var videoControlView: EditorVideoControlView = {
        var cropTime = config.video.cropTime
        if config.isFixedCropSizeState && config.isIgnoreCropTimeWhenFixedCropSizeState {
            cropTime.maximumTime = 0
        }
        let view = EditorVideoControlView(config: cropTime)
        view.delegate = self
        view.alpha = 0
        view.isHidden = true
        return view
    }()
    
    lazy var brushColorView: EditorBrushColorView = {
        let view = EditorBrushColorView(config: config.brush)
        view.delegate = self
        view.alpha = 0
        view.isHidden = true
        return view
    }()
    
    lazy var brushSizeView: EditorBrushSizeView = {
        let view = EditorBrushSizeView()
        view.alpha = 0
        view.isHidden = true
        view.value = config.brush.lineWidth / (config.brush.maximumLinewidth - config.brush.minimumLinewidth)
        view.blockBeganChanged = { [weak self] _ in
            guard let self = self else { return }
            let lineWidth = self.editorView.drawLineWidth + 4
            self.brushBlockView.size = CGSize(width: lineWidth, height: lineWidth)
            self.showBrushBlockView()
        }
        view.blockDidChanged = { [weak self] in
            guard let self = self else { return }
            let config = self.config.brush
            let lineWidth = (
                config.maximumLinewidth -  config.minimumLinewidth
            ) * $0 + config.minimumLinewidth
            self.editorView.drawLineWidth = lineWidth
            self.brushBlockView.size = CGSize(width: lineWidth + 4, height: lineWidth + 4)
            self.brushBlockView.center = CGPoint(x: self.view.width * 0.5, y: self.view.height * 0.5)
        }
        view.blockEndedChanged = { [weak self] _ in
            guard let self = self else { return }
            self.hideBrushBlockView()
        }
        return view
    }()
    
    lazy var brushBlockView: EditorBrushBlockView = {
        let lineWidth = config.brush.lineWidth + 4
        let view = EditorBrushBlockView()
        view.color = config.brush.colors[config.brush.defaultColorIndex].color
        view.size = .init(width: lineWidth, height: lineWidth)
        return view
    }()
    
    lazy var filterEditView: EditorFilterEditView = {
        let view = EditorFilterEditView()
        view.delegate = self
        view.alpha = 0
        view.isHidden = true
        return view
    }()
    
    lazy var filtersView: EditorFiltersView = {
        let view = EditorFiltersView(
            filterConfig: selectedAsset.contentType == .image ? config.photo.filter : config.video.filter
        )
        view.delegate = self
        view.alpha = 0
        view.isHidden = true
        return view
    }()
    
    lazy var filterParameterView: EditorFilterParameterView = {
        let view = EditorFilterParameterView(
            sliderColor: selectedAsset.contentType == .image ? config.photo.filter.selectedColor : config.video.filter.selectedColor
        )
        view.delegate = self
        return view
    }()
    
    var finishScaleAngle: CGFloat = 0
    var lastScaleAngle: CGFloat = 0
    lazy var rotateScaleView: EditorScaleView = {
        let view = EditorScaleView()
        view.themeColor = config.cropSize.angleScaleColor
        view.angleChanged = { [weak self] in
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
        view.alpha = 0
        view.isHidden = true
        return view
    }()
    
    lazy var finishRatioIndex: Int = config.cropSize.defaultSeletedIndex
    lazy var ratioToolView: EditorRatioToolView = {
        let view = EditorRatioToolView(ratios: config.cropSize.aspectRatios, selectedIndex: config.cropSize.defaultSeletedIndex)
        view.delegate = self
        view.alpha = 0
        view.isHidden = true
        return view
    }()
    
    lazy var mosaicToolView: EditorMosaicToolView = {
        let view = EditorMosaicToolView(selectedColor: config.toolsView.toolSelectedColor)
        view.delegate = self
        view.alpha = 0
        view.isHidden = true
        return view
    }()
    
    lazy var musicView: EditorMusicView = {
        let view = EditorMusicView(config: config.video.music)
        view.delegate = self
        return view
    }()
    lazy var volumeView: EditorVolumeView = {
        let view = EditorVolumeView(config.video.music.tintColor)
        view.hasMusic = false
        view.delegate = self
        return view
    }()
    
    lazy var toolsView: EditorToolsView = {
        let view = EditorToolsView(config: config.toolsView, contentType: selectedAsset.type.contentType)
        view.delegate = self
        return view
    }()
    
    lazy var cancelButton: UIButton = {
        let cancelButton = UIButton(type: .custom)
        cancelButton.setTitle("取消".localized, for: .normal)
        cancelButton.setTitleColor(config.cancelButtonTitleColor, for: .normal)
        cancelButton.setTitleColor(config.cancelButtonTitleColor.withAlphaComponent(0.5), for: .highlighted)
        cancelButton.titleLabel?.font = UIFont.regularPingFang(ofSize: 17)
        cancelButton.contentHorizontalAlignment = .left
        cancelButton.addTarget(self, action: #selector(didCancelButtonClick(button:)), for: .touchUpInside)
        return cancelButton
    }()
    
    lazy var finishButton: UIButton = {
        let finishButton = UIButton(type: .custom)
        finishButton.setTitle("完成".localized, for: .normal)
        finishButton.setTitleColor(config.finishButtonTitleNormalColor, for: .normal)
        finishButton.setTitleColor(config.finishButtonTitleNormalColor.withAlphaComponent(0.5), for: .highlighted)
        finishButton.setTitleColor(config.finishButtonTitleDisableColor.withAlphaComponent(0.5), for: .disabled)
        finishButton.titleLabel?.font = UIFont.regularPingFang(ofSize: 17)
        finishButton.contentHorizontalAlignment = .right
        finishButton.addTarget(self, action: #selector(didFinishButtonClick(button:)), for: .touchUpInside)
        finishButton.isEnabled = !config.isWhetherFinishButtonDisabledInUneditedState
        return finishButton
    }()
    
    lazy var resetButton: UIButton = {
        let resetButton = UIButton(type: .custom)
        resetButton.setTitle("还原".localized, for: .normal)
        resetButton.setTitleColor(.white, for: .normal)
        resetButton.setTitleColor(.white.withAlphaComponent(0.5), for: .highlighted)
        resetButton.setTitleColor(.white.withAlphaComponent(0.5), for: .disabled)
        resetButton.titleLabel?.font = UIFont.regularPingFang(ofSize: 17)
        resetButton.addTarget(self, action: #selector(didResetButtonClick(button:)), for: .touchUpInside)
        resetButton.alpha = 0
        resetButton.isHidden = true
        return resetButton
    }()
    
    lazy var leftRotateButton: UIButton = {
        let button = UIButton.init(type: .system)
        button.setImage("hx_editor_photo_rotate_left".image, for: .normal)
        button.size = button.currentImage?.size ?? .zero
        button.tintColor = .white
        button.addTarget(self, action: #selector(didLeftRotateButtonClick(button:)), for: .touchUpInside)
        button.alpha = 0
        button.isHidden = true
        return button
    }()
    
    lazy var rightRotateButton: UIButton = {
        let button = UIButton.init(type: .system)
        button.setImage("hx_editor_photo_rotate_right".image, for: .normal)
        button.size = button.currentImage?.size ?? .zero
        button.tintColor = .white
        button.addTarget(self, action: #selector(didRightRotateButtonClick(button:)), for: .touchUpInside)
        button.alpha = 0
        button.isHidden = true
        return button
    }()
    
    lazy var mirrorHorizontallyButton: UIButton = {
        let button = UIButton.init(type: .system)
        button.setImage("hx_editor_photo_mirror_horizontally".image, for: .normal)
        button.size = button.currentImage?.size ?? .zero
        button.tintColor = .white
        button.addTarget(self, action: #selector(didMirrorHorizontallyButtonClick(button:)), for: .touchUpInside)
        button.alpha = 0
        button.isHidden = true
        return button
    }()
    
    lazy var mirrorVerticallyButton: UIButton = {
        let button = UIButton.init(type: .system)
        button.setImage("hx_editor_photo_mirror_vertically".image, for: .normal)
        button.size = button.currentImage?.size ?? .zero
        button.tintColor = .white
        button.addTarget(self, action: #selector(didMirrorVerticallyButtonClick(button:)), for: .touchUpInside)
        button.alpha = 0
        button.isHidden = true
        return button
    }()
    
    lazy var changeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage("hx_editor_change_asset".image, for: .normal)
        button.size = button.currentImage?.size ?? .zero
        button.addTarget(self, action: #selector(didChangeButtonClick(button:)), for: .touchUpInside)
        button.layer.shadowColor = UIColor.black.withAlphaComponent(0.5).cgColor
        button.layer.shadowOpacity = 1
        button.layer.shadowRadius = 10
        button.alpha = 0
        button.isHidden = true
        return button
    }()
    
    lazy var maskListButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage("hx_editor_crop_mask_list".image, for: .normal)
        button.size = button.currentImage?.size ?? .zero
        button.tintColor = .white
        button.addTarget(self, action: #selector(didMaskListButtonClick(button:)), for: .touchUpInside)
        button.alpha = 0
        button.isHidden = true
        return button
    }()
    
    lazy var editorView: EditorView = {
        let view = EditorView()
        view.editContentInset = { _ in
            if UIDevice.isPortrait {
                let top = UIDevice.isPad ? 30 : UIDevice.topMargin + 10
                let left = UIDevice.isPad ? 30 : UIDevice.leftMargin + 15
                let right = UIDevice.isPad ? 30 : UIDevice.rightMargin + 15
                return .init(top: top, left: left, bottom: UIDevice.bottomMargin + 50 + 140, right: right)
            }else {
                return .init(top: UIDevice.topMargin + 55, left: UIDevice.leftMargin + 165, bottom: UIDevice.bottomMargin + 15, right: UIDevice.rightMargin + 165)
            }
        }
        view.urlConfig = config.urlConfig
        view.exportScale = config.photo.scale
        view.initialRoundMask = config.cropSize.isRoundCrop
        view.initialFixedRatio = config.cropSize.isFixedRatio
        view.initialAspectRatio = config.cropSize.aspectRatio
        view.maskType = config.cropSize.maskType
        view.isShowScaleSize = config.cropSize.isShowScaleSize
        if config.cropSize.isFixedRatio {
            view.isResetIgnoreFixedRatio = config.cropSize.isResetToOriginal
        }else {
            view.isResetIgnoreFixedRatio = true
        }
        if !config.brush.colors.isEmpty {
            view.drawLineColor = config.brush.colors[min(max(config.brush.defaultColorIndex, 0), config.brush.colors.count - 1)].color
        }
        view.drawLineWidth = config.brush.lineWidth
        view.mosaicWidth = config.mosaic.mosaiclineWidth
        view.smearWidth = config.mosaic.smearWidth
        view.editDelegate = self
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapClick)))
        return view
    }()
    
    public lazy var topMaskView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.layer.addSublayer(topMaskLayer)
        return view
    }()
    
    public lazy var bottomMaskView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.layer.addSublayer(bottomMaskLayer)
        return view
    }()
    
    public lazy var topMaskLayer: CAGradientLayer = {
        let layer = PhotoTools.getGradientShadowLayer(true)
        return layer
    }()
    
    public lazy var bottomMaskLayer: CAGradientLayer = {
        let layer = PhotoTools.getGradientShadowLayer(false)
        return layer
    }()
    
    public var selectedTool: EditorConfiguration.ToolsView.Options?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        initView()
        initAsset()
    }
    
    func initView() {
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
    lazy var filterEditFator: EditorFilterEditFator = .init()
    lazy var imageFilterContext: CIContext = CIContext(options: nil)
    lazy var imageFilterQueue: OperationQueue = {
        let imageFilterQueue = OperationQueue()
        imageFilterQueue.maxConcurrentOperationCount = 1
        return imageFilterQueue
    }()
    
    var isStartFilterParameterTime: CMTime?
    var lastMusicDownloadTask: URLSessionDownloadTask?
    weak var videoTool: EditorVideoTool?
    
    public override func deviceOrientationWillChanged(notify: Notification) {
        orientationDidChange = true
        if editorView.type == .video {
            videoControlView.stopScroll()
            videoControlView.stopLineAnimation()
            videoControlInfo = videoControlView.controlInfo
        }
    }
    
    var firstAppear = true
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        editorView.frame = view.bounds
        
        let buttonHeight: CGFloat = UIDevice.isPortrait ? 50 : 44
        
        let cancelWidth = cancelButton.currentTitle?.width(
                            ofFont: cancelButton.titleLabel!.font,
                            maxHeight: buttonHeight) ?? 0
        let finishWidth = finishButton.currentTitle?.width(
                            ofFont: finishButton.titleLabel!.font,
                            maxHeight: buttonHeight) ?? 0
        let resetWidth = resetButton.currentTitle?.width(
            ofFont: resetButton.titleLabel!.font,
            maxHeight: buttonHeight) ?? 0
        
        cancelButton.height = buttonHeight
        finishButton.height = buttonHeight
        cancelButton.width = cancelWidth + 10
        finishButton.width = finishWidth + 10
        cancelButton.x = UIDevice.leftMargin + 12
        finishButton.x = view.width - finishButton.width - 12 - UIDevice.rightMargin
        
        resetButton.size = .init(width: resetWidth, height: buttonHeight)
        resetButton.centerX = view.width * 0.5
        brushSizeView.size = .init(width: 30, height: 200)
        brushSizeView.centerY = view.height * 0.5
        bottomMaskLayer.removeFromSuperlayer()
        
        changeButton.centerX = view.width / 2
        
        if UIDevice.isPortrait {
            changeButton.y = UIDevice.topMargin
            bottomMaskLayer = PhotoTools.getGradientShadowLayer(false)
            bottomMaskView.layer.addSublayer(bottomMaskLayer)
            if isToolsDisplay {
                topMaskView.alpha = 0
                topMaskView.isHidden = true
                bottomMaskView.alpha = 1
                bottomMaskView.isHidden = false
            }
            
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
            filtersView.frame = .init(x: 0, y: toolsView.y - 120, width: view.width, height: 120)
            brushColorView.frame = .init(x: 0, y: toolsView.y - 65, width: view.width, height: 65)
            brushSizeView.x = view.width - 45 - UIDevice.rightMargin
            mosaicToolView.frame =  .init(x: 0, y: toolsView.y - 65, width: view.width, height: 65)
            
            leftRotateButton.y = rotateScaleView.y - leftRotateButton.height - 10
            leftRotateButton.x = UIDevice.leftMargin + 15
            rightRotateButton.centerY = leftRotateButton.centerY
            rightRotateButton.x = leftRotateButton.frame.maxX + 12
            
            mirrorHorizontallyButton.x = view.width - UIDevice.rightMargin - mirrorHorizontallyButton.width - 12
            mirrorVerticallyButton.x = mirrorHorizontallyButton.x - 12 - mirrorVerticallyButton.width
            mirrorHorizontallyButton.centerY = leftRotateButton.centerY
            mirrorVerticallyButton.centerY = mirrorHorizontallyButton.centerY
            
            maskListButton.centerY = mirrorVerticallyButton.centerY
            maskListButton.centerX = view.width / 2
            
            if orientationDidChange || firstAppear {
                videoControlView.frame = .init(x: 0, y: toolsView.y - 80, width: view.width, height: 50)
            }
        }else {
            bottomMaskLayer = PhotoTools.getGradientShadowLayer(startPoint: .init(x: 0, y: 0), endPoint: .init(x: 1, y: 0))
            bottomMaskView.isHidden = true
            bottomMaskView.alpha = 0
            bottomMaskView.layer.addSublayer(bottomMaskLayer)
            if isToolsDisplay {
                topMaskView.isHidden = false
                topMaskView.alpha = 1
                bottomMaskView.isHidden = false
                bottomMaskView.alpha = 1
            }
            topMaskView.frame = .init(x: 0, y: 0, width: view.width, height: UIDevice.topMargin + 50)
            
            cancelButton.y = UIDevice.topMargin
            finishButton.centerY = cancelButton.centerY
            resetButton.centerY = cancelButton.centerY
            changeButton.centerY = cancelButton.centerY
            
            leftRotateButton.centerY = cancelButton.centerY
            leftRotateButton.x = cancelButton.frame.maxX + 12
            rightRotateButton.centerY = cancelButton.centerY
            rightRotateButton.x = leftRotateButton.frame.maxX + 12
            
            mirrorHorizontallyButton.x = finishButton.x - mirrorHorizontallyButton.width - 12
            mirrorVerticallyButton.x = mirrorHorizontallyButton.x - 12 - mirrorVerticallyButton.width
            mirrorHorizontallyButton.centerY = cancelButton.centerY
            mirrorVerticallyButton.centerY = mirrorHorizontallyButton.centerY
            
            maskListButton.centerY = mirrorVerticallyButton.centerY
            maskListButton.x = mirrorVerticallyButton.x - 12 - maskListButton.width
            
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
                ratioToolView.frame = .init(x: view.width - UIDevice.rightMargin - ratioWidth, y: cancelButton.frame.maxY, width: ratioWidth, height: view.height - cancelButton.frame.maxY)
                rotateScaleView.frame = .init(x: ratioToolView.x - 50, y: ratioToolView.y, width: 50, height: view.height - ratioToolView.y)
            }else {
                rotateScaleView.frame = .init(x: view.width - UIDevice.rightMargin - 50, y: cancelButton.frame.maxY, width: 50, height: view.height - cancelButton.frame.maxY)
            }
            filtersView.frame = .init(x: toolsView.x - 120, y: toolsView.y, width: 120, height: toolsView.height)
            brushColorView.frame = .init(x: toolsView.x - 65, y: 0, width: 65, height: view.height)
            brushSizeView.x = UIDevice.leftMargin + 12
            mosaicToolView.frame =  .init(x: toolsView.x - 65, y: 0, width: 65, height: view.height)
            if orientationDidChange || firstAppear {
                videoControlView.frame = .init(x: 0, y: view.height - UIDevice.bottomMargin - 60, width: view.width, height: 40)
            }
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
    
    func updateVideoControlInfo() {
        if let videoControlInfo = videoControlInfo {
            videoControlView.reloadVideo()
            videoControlView.layoutIfNeeded()
            DispatchQueue.main.async {
                self.videoControlView.setControlInfo(videoControlInfo)
                self.videoControlView.resetLineViewFrsme(at: self.editorView.videoPlayTime)
                self.updateVideoTimeRange()
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
        if let type = selectedTool?.type,
           type == .music {
            musicY = view.height - marginHeight - UIDevice.bottomMargin
            musicHeight = marginHeight + UIDevice.bottomMargin
        }else {
            musicY = view.height
            musicHeight = marginHeight + UIDevice.bottomMargin
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
            let editHeight = max(CGFloat(filterParameterView.models.count) * 40 + 30 + UIDevice.bottomMargin, 150 + UIDevice.bottomMargin)
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
            let editWidth = max(CGFloat(filterParameterView.models.count) * 40 + 30 + UIDevice.rightMargin, 150 + UIDevice.rightMargin)
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
                removeVideo()
            }
        }else if presentingViewController == nil {
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

extension EditorViewController {
    
    @objc
    func didCancelButtonClick(button: UIButton) {
        if let selectedTool = selectedTool {
            switch selectedTool.type {
            case .cropSize:
                if config.isFixedCropSizeState {
                    backClick(true)
                    return
                }
                editorView.cancelEdit(true, completion: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    self.rotateScaleView.updateAngle(self.finishScaleAngle)
                    self.lastScaleAngle = self.finishScaleAngle
                    if !self.config.cropSize.aspectRatios.isEmpty {
                        self.ratioToolView.scrollToIndex(at: self.finishRatioIndex, animated: false)
                    }
                })
                hideCropSizeToolsView()
                if let lastSelectedTool = lastSelectedTool {
                    switch lastSelectedTool.type {
                    case .graffiti:
                        editorView.isStickerEnabled = false
                        editorView.isDrawEnabled = true
                    case .mosaic:
                        editorView.isStickerEnabled = false
                        editorView.isMosaicEnabled = true
                    default:
                        editorView.isStickerEnabled = true
                    }
                }else {
                    editorView.isStickerEnabled = true
                }
                showChangeButton()
                checkFinishButtonState()
                return
            default:
                break
            }
        }
        backClick(true)
    }
    
    @objc
    func didFinishButtonClick(button: UIButton) {
        if let selectedTool = selectedTool {
            switch selectedTool.type {
            case .cropSize:
                finishScaleAngle = rotateScaleView.angle
                if !config.cropSize.aspectRatios.isEmpty {
                    finishRatioIndex = ratioToolView.selectedIndex
                }
                if config.isFixedCropSizeState {
                    processing()
                    return
                }
                editorView.finishEdit(true)
                hideCropSizeToolsView()
                if let lastSelectedTool = lastSelectedTool {
                    switch lastSelectedTool.type {
                    case .graffiti:
                        editorView.isStickerEnabled = false
                        editorView.isDrawEnabled = true
                    case .mosaic:
                        editorView.isStickerEnabled = false
                        editorView.isMosaicEnabled = true
                    default:
                        editorView.isStickerEnabled = true
                    }
                }else {
                    editorView.isStickerEnabled = true
                }
                showChangeButton()
                checkFinishButtonState()
                return
            default:
                break
            }
        }
        processing()
    }
    
    @objc
    func didResetButtonClick(button: UIButton) {
        if editorView.maskImage != nil {
            editorView.setMaskImage(nil, animated: true)
        }
        editorView.reset(true)
        lastScaleAngle = 0
        rotateScaleView.reset()
        if !config.cropSize.aspectRatios.isEmpty {
            ratioToolView.scrollToFree(animated: true)
        }
        button.isEnabled = false
    }
    
    @objc
    func didLeftRotateButtonClick(button: UIButton) {
        editorView.rotateLeft(true)
    }
    
    @objc
    func didRightRotateButtonClick(button: UIButton) {
        editorView.rotateRight(true)
    }
    
    @objc
    func didMirrorHorizontallyButtonClick(button: UIButton) {
        editorView.mirrorHorizontally(true)
    }
    
    @objc
    func didMirrorVerticallyButtonClick(button: UIButton) {
        editorView.mirrorVertically(true)
    }
    
    @objc
    func didChangeButtonClick(button: UIButton) {
        
    }
    
    @objc
    func didMaskListButtonClick(button: UIButton) {
        let vc = EditorMaskListViewController(config: config.cropSize)
        vc.delegate = self
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }
    
    func checkFinishButtonState() {
        if editorView.state == .edit {
            finishButton.isEnabled = true
        }else {
            if config.isWhetherFinishButtonDisabledInUneditedState {
                finishButton.isEnabled = isEdited
            }else {
                finishButton.isEnabled = true
            }
        }
    }
    
    var isEdited: Bool {
        var isCropTime: Bool = false
        if selectedAsset.contentType == .video {
            if editorView.videoDuration.seconds != videoControlView.middleDuration {
                isCropTime = true
            }
        }
        var isSelectMusic: Bool = false
        if selectedMusicURL != nil {
            isSelectMusic = true
        }
        if !isSelectedOriginalSound {
            isSelectMusic = true
        }
        if videoVolume < 1 {
            isSelectMusic = true
        }
        var isCropSize: Bool = false
        if selectedAsset.contentType == .image {
            isCropSize = editorView.isCropedImage
        }else if selectedAsset.contentType == .video {
            isCropSize = editorView.isCropedVideo
        }
        var isFilterEdited: Bool = false
        if filterEditFator.isApply {
            isFilterEdited = true
        }
        var isSelectFilter: Bool = false
        if selectedAsset.contentType == .image {
            isSelectFilter = imageFilter != nil
        }else if selectedAsset.contentType == .video {
            isSelectFilter = videoFilter != nil
        }
        return isCropTime || isSelectMusic || isCropSize || isFilterEdited || isSelectFilter
    }
}

extension EditorViewController {
    func processing() {
        switch selectedAsset.contentType {
        case .image:
            imageProcessing()
        case .video:
            videoProcessing()
        default:
            break
        }
        view.bringSubviewToFront(cancelButton)
    }
    
    func imageProcessing() {
        if editorView.isCropedImage || imageFilter != nil || filterEditFator.isApply {
            ProgressHUD.showLoading(addedTo: view, text: "正在处理...".localized, animated: true)
            if editorView.isCropedImage {
                editorView.cropImage { [weak self] result in
                    guard let self = self else { return }
                    ProgressHUD.hide(forView: self.view)
                    switch result {
                    case .success(let imageResult):
                        self.imageProcessCompletion(imageResult)
                    case .failure(_):
                        ProgressHUD.showWarning(
                            addedTo: self.view,
                            text: "处理失败".localized,
                            animated: true,
                            delayHide: 1.5
                        )
                    }
                }
            }else {
                imageFilterProcessing { [weak self] in
                    guard let self = self else {
                        return
                    }
                    ProgressHUD.hide(forView: self.view)
                    guard let result = $0 else {
                        ProgressHUD.showWarning(
                            addedTo: self.view,
                            text: "处理失败".localized,
                            animated: true,
                            delayHide: 1.5
                        )
                        return
                    }
                    self.imageProcessCompletion(result)
                }
            }
        }else {
            editedResult = nil
            selectedAsset.result = nil
            delegate?.editorViewController(self, didFinish: selectedAsset)
//            delegate?.editorViewController(self, didFinish: [])
            finishHandler?(nil, self)
            backClick()
        }
    }
    
    func imageFilterProcessing(completion: @escaping (ImageEditedResult?) -> Void) {
        guard let image = editorView.image else {
            completion(nil)
            return
        }
        PhotoTools.getImageData(image, queueLabel: "HXPhotoPicker.editor.ImageFilterProcessingQueue") {
            guard let imageData = $0 else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            let compressionQuality = PhotoTools.getCompressionQuality(CGFloat(imageData.count))
            PhotoTools.compressImageData(
                imageData,
                compressionQuality: compressionQuality,
                queueLabel: "HXPhotoPicker.editor.CompressImageFilterProcessingQueue"
            ) {
                guard let data = $0 else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                let urlConfig: EditorURLConfig
                if let config = self.config.urlConfig {
                    urlConfig = config
                }else {
                    let fileName = String.fileName(suffix: data.isGif ? "gif" : "png")
                    urlConfig = .init(fileName: fileName, type: .temp)
                }
                guard let _ = PhotoTools.write(toFile: urlConfig.url, imageData: data) else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                PhotoTools.compressImageData(
                    data,
                    compressionQuality: 0.3,
                    queueLabel: "HXPhotoPicker.editor.CompressThumbImageFilterProcessingQueue"
                ) { thumbData in
                    if let thumbData = thumbData,
                       let thumbnailImage = UIImage(data: thumbData) {
                        DispatchQueue.main.async {
                            completion(.init(image: thumbnailImage, urlConfig: urlConfig, imageType: .normal, data: nil))
                        }
                    }else {
                        DispatchQueue.main.async {
                            completion(nil)
                        }
                    }
                }
            }
        }
    }
    
    func imageProcessCompletion(_ result: ImageEditedResult) {
        let imageEditedResult: ImageEditedData
        var filter: PhotoEditorFilter?
        var filterEdit: EditorFilterEditFator?
        let aspectRatio = editorView.aspectRatio
        let angle = lastScaleAngle
        let isFixedRatio = editorView.isFixedRatio
        if imageFilter != nil || filterEditFator.isApply {
            filter = imageFilter
            filterEdit = filterEditFator
        }
        imageEditedResult = .init(
            filter: filter,
            filterEdit: filterEdit,
            cropSize: .init(
                isFixedRatio: isFixedRatio,
                aspectRatio: aspectRatio,
                angle: angle
            )
        )
        let editedResult = EditedResult.image(result, imageEditedResult)
        self.editedResult = editedResult
        selectedAsset.result = editedResult
        delegate?.editorViewController(self, didFinish: selectedAsset)
        finishHandler?(editedResult, self)
//        delegate?.editorViewController(self, didFinish: [editedResult])
        backClick()
    }
    
    func videoProcessing() {
        let isCropTime: Bool = editorView.videoDuration.seconds != videoControlView.middleDuration
        var isSelectMusic: Bool = false
        if selectedMusicURL != nil {
            isSelectMusic = true
        }
        if !isSelectedOriginalSound {
            isSelectMusic = true
        }
        if videoVolume < 1 {
            isSelectMusic = true
        }
        if editorView.isCropedVideo || videoFilter != nil || filterEditFator.isApply || isSelectMusic || isCropTime {
            let timeRange: CMTimeRange
            if isCropTime {
                timeRange = .init(start: videoControlView.startTime, end: videoControlView.endTime)
            }else {
                timeRange = .zero
            }
            var audios: [EditorVideoFactor.Audio] = []
            if let musicURL = selectedMusicURL {
                let volume = musicPlayer?.volume ?? 1
                let audioURL: URL?
                switch musicURL {
                case .network(let url):
                    audioURL = PhotoTools.getAudioTmpURL(for: url.absoluteString)
                default:
                    audioURL = musicURL.url
                }
                if let audioURL = audioURL {
                    audios.append(.init(url: audioURL, volume: volume))
                }
            }
            let videoVolume: Float
            if isSelectedOriginalSound {
                videoVolume = self.videoVolume
            }else {
                videoVolume = 0
            }
            let factor = EditorVideoFactor(
                timeRang: timeRange,
                volume: videoVolume,
                audios: audios,
                maskType: config.cropSize.maskType,
                preset: config.video.preset,
                quality: config.video.quality
            )
            if editorView.isCropedVideo {
                let progressView = ProgressHUD.showProgress(
                    addedTo: view,
                    text: "正在处理...".localized,
                    animated: true
                )
                editorView.cropVideo(
                    factor: factor
                ) { [weak self] in
                    guard let self = self else {
                        return nil
                    }
                    return self.videoFilterHandler($0, at: $1)
                } progress: {
                    progressView?.progress = $0
                } completion: { [weak self] result in
                    guard let self = self else {
                        return
                    }
                    switch result {
                    case .success(let videoResult):
                        DispatchQueue.global(qos: .userInteractive).async {
                            DispatchQueue.main.async {
                                ProgressHUD.hide(forView: self.view)
                                self.videoProcessCompletion(videoResult)
                            }
                        }
                        break
                    case .failure(let error):
                        ProgressHUD.hide(forView: self.view, animated: true)
                        if error.isCancel {
                            return
                        }
                        ProgressHUD.showWarning(addedTo: self.view, text: "处理失败".localized, animated: true, delayHide: 1.5)
                    }
                }
            }else {
                if config.isFixedCropSizeState && config.isIgnoreCropTimeWhenFixedCropSizeState {
                    if (videoFilter != nil || filterEditFator.isApply || isSelectMusic) && !isCropTime {
                        videoFilterProcessing(factor)
                    }else {
                        editedResult = nil
                        selectedAsset.result = nil
                        delegate?.editorViewController(self, didFinish: selectedAsset)
                        finishHandler?(nil, self)
                        backClick()
                    }
                }else {
                    videoFilterProcessing(factor)
                }
            }
        }else {
            editedResult = nil
            selectedAsset.result = nil
            delegate?.editorViewController(self, didFinish: selectedAsset)
            finishHandler?(nil, self)
//            delegate?.editorViewController(self, didFinish: [])
            backClick()
        }
    }
    
    func videoFilterHandler(_ pixelBuffer: CVPixelBuffer, at time: CMTime) -> CVPixelBuffer? {
        var ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let size = CGSize(
            width: CVPixelBufferGetWidth(pixelBuffer),
            height: CVPixelBufferGetHeight(pixelBuffer)
        )
        if let videoFilter = videoFilter,
           let videoFilterInfo = videoFilterInfo {
            if filterEditFator.isApply, let image = ciImage.apply(filterEditFator) {
                ciImage = image
            }
            if let resultImage = videoFilterInfo.videoFilterHandler?(ciImage.clampedToExtent(), videoFilter.parameters),
               let newPixelBuffer = PhotoTools.createPixelBuffer(size) {
                imageFilterContext.render(resultImage, to: newPixelBuffer)
                return newPixelBuffer
            }
        }else {
            if filterEditFator.isApply {
                if let image = ciImage.apply(filterEditFator),
                   let newPixelBuffer = PhotoTools.createPixelBuffer(size) {
                    imageFilterContext.render(image, to: newPixelBuffer)
                    return newPixelBuffer
                }
            }
        }
        return nil
    }
    
    func videoFilterProcessing(_ factor: EditorVideoFactor) {
        guard let avAsset = editorView.avAsset else {
            ProgressHUD.hide(forView: self.view, animated: true)
            ProgressHUD.showWarning(addedTo: self.view, text: "处理失败".localized, animated: true, delayHide: 1.5)
            return
        }
        let progressView = ProgressHUD.showProgress(
            addedTo: view,
            text: "正在处理...".localized,
            animated: true
        )
        let urlConfig: EditorURLConfig
        if let _urlConfig = config.urlConfig {
            urlConfig = _urlConfig
        }else {
            urlConfig = .init(fileName: .fileName(suffix: "mp4"), type: .temp)
        }
        videoTool?.cancelExport()
        let videoTool = EditorVideoTool(
            avAsset: avAsset,
            outputURL: urlConfig.url,
            factor: factor,
            maskType: config.cropSize.maskType
        ) { [weak self] in
            guard let self = self else {
                return nil
            }
            return self.videoFilterHandler($0, at: $1)
        }
        videoTool.export {
            progressView?.progress = $0
        } completionHandler: { [weak self] result in
            guard let self = self else {
                return
            }
            switch result {
            case .success(let url):
                DispatchQueue.global(qos: .userInteractive).async {
                    let fileSize = url.fileSize
                    let videoDuration = PhotoTools.getVideoDuration(videoURL: url)
                    let coverImage = PhotoTools.getVideoThumbnailImage(videoURL: url, atTime: 0.1)
                    let videoTime = PhotoTools.transformVideoDurationToString(duration: videoDuration)
                    DispatchQueue.main.async {
                        ProgressHUD.hide(forView: self.view)
                        self.videoProcessCompletion(
                            .init(
                                urlConfig: urlConfig,
                                coverImage: coverImage,
                                fileSize: fileSize,
                                videoTime: videoTime,
                                videoDuration: videoDuration,
                                data: nil
                            )
                        )
                    }
                }
                break
            case .failure(let error):
                ProgressHUD.hide(forView: self.view, animated: true)
                if error.isCancel {
                    return
                }
                ProgressHUD.showWarning(addedTo: self.view, text: "处理失败".localized, animated: true, delayHide: 1.5)
            }
        }
        self.videoTool = videoTool
    }
    
    func videoProcessCompletion(
        _ result: VideoEditedResult
    ) {
        let editedData: VideoEditedData
        var filter: VideoEditorFilter?
        var filterEdit: EditorFilterEditFator?
        let aspectRatio = editorView.aspectRatio
        let angle = lastScaleAngle
        let isFixedRatio = editorView.isFixedRatio
        if videoFilter != nil || filterEditFator.isApply {
            filter = videoFilter
            filterEdit = filterEditFator
        }
        var cropTime: EditorVideoCropTime?
        let isCropTime: Bool = editorView.videoDuration.seconds != videoControlView.middleDuration
        if isCropTime {
            cropTime = .init(
                startTime: videoControlView.startDuration,
                endTime: videoControlView.endDuration,
                preferredTimescale: videoControlView.startTime.timescale,
                controlInfo: videoControlView.controlInfo
            )
        }
        let music = musicPlayer?.music
        editedData = .init(
            music: .init(
                hasOriginalSound: isSelectedOriginalSound,
                videoSoundVolume: videoVolume,
                backgroundMusicURL: selectedMusicURL,
                backgroundMusicVolume: musicVolume,
                musicIdentifier: musicPlayer?.audio?.identifier,
                music: music
            ),
            cropTime: cropTime,
            filterEdit: filterEdit,
            filter: filter,
            cropSize: .init(
                isFixedRatio: isFixedRatio,
                aspectRatio: aspectRatio,
                angle: angle
            )
        )
        let editedResult = EditedResult.video(result, editedData)
        self.editedResult = editedResult
        selectedAsset.result = editedResult
        delegate?.editorViewController(self, didFinish: selectedAsset)
        finishHandler?(editedResult, self)
//        delegate?.editorViewController(self, didFinish: [editedResult])
        backClick()
    }
}

extension EditorViewController {
    
    func backClick(_ isCancel: Bool = false) {
        switch selectedAsset.type {
        case .networkVideo(let url):
            PhotoManager.shared.suspendTask(url)
        #if HXPICKER_ENABLE_PICKER
        case .photoAsset(let photoAsset):
            if let url = photoAsset.networkVideoAsset?.videoURL {
                PhotoManager.shared.suspendTask(url)
            }
        #endif
        default:
            break
        }
        ProgressHUD.hide(forView: view)
        removeVideo()
        if let assetRequestID = assetRequestID {
            PHImageManager.default().cancelImageRequest(assetRequestID)
        }
        if isCancel {
            delegate?.editorViewController(didCancel: self)
            cancelHandler?(self)
        }
        if config.isAutoBack {
            if let navigationController = navigationController, navigationController.viewControllers.count > 1 {
                navigationController.popViewController(animated: true)
            }else {
                dismiss(animated: true, completion: nil)
            }
        }
    }
}

extension EditorViewController {
    func startPlayVideo() {
        if videoControlView.startDuration == videoControlView.currentDuration {
            videoPlayTimer = Timer.scheduledTimer(
                withTimeInterval: videoControlView.middleDuration,
                repeats: true,
                block: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    if self.videoPlayTimer == nil || $0 != self.videoPlayTimer {
                        $0.invalidate()
                        return
                    }
                    self.editorView.seekVideo(to: self.videoControlView.startTime)
                }
            )
        }else {
            videoPlayTimer = Timer.scheduledTimer(
                withTimeInterval: videoControlView.endDuration - videoControlView.currentDuration,
                repeats: false,
                block: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    $0.invalidate()
                    if self.videoPlayTimer == nil || $0 != self.videoPlayTimer {
                        return
                    }
                    self.editorView.seekVideo(to: self.videoControlView.startTime)
                    self.videoPlayTimer = Timer.scheduledTimer(
                        withTimeInterval: self.videoControlView.middleDuration,
                        repeats: true,
                        block: { [weak self] in
                            guard let self = self else {
                                return
                            }
                            if self.videoPlayTimer == nil || $0 != self.videoPlayTimer {
                                $0.invalidate()
                                return
                            }
                            self.editorView.seekVideo(to: self.videoControlView.startTime)
                        }
                    )
                }
            )
        }
    }
    
    func stopPlayVideo() {
        videoPlayTimer?.invalidate()
        videoPlayTimer = nil
    }
}

extension EditorViewController {
    
    func setTransitionImage(_ image: UIImage) {
        editorView.setImage(image)
    }
    
    func transitionHide() {
        cancelButton.alpha = 0
        toolsView.alpha = 0
        finishButton.alpha = 0
        bottomMaskView.alpha = 0
        topMaskView.alpha = 0
        if let tool = selectedTool {
            switch tool.type {
            case .time:
                videoControlView.alpha = 0
            case .graffiti:
                brushColorView.alpha = 0
                brushSizeView.alpha = 0
            case .mosaic:
                mosaicToolView.alpha = 0
            case .filterEdit:
                filterEditView.alpha = 0
            case .filter:
                filtersView.alpha = 0
            case .cropSize:
                if !config.cropSize.aspectRatios.isEmpty {
                    ratioToolView.alpha = 0
                }
                rotateScaleView.alpha = 0
                resetButton.alpha = 0
                leftRotateButton.alpha = 0
                rightRotateButton.alpha = 0
                mirrorVerticallyButton.alpha = 0
                mirrorHorizontallyButton.alpha = 0
                maskListButton.alpha = 0
            default:
                break
            }
        }
    }
    
    func transitionShow() {
        cancelButton.alpha = 1
        toolsView.alpha = 1
        finishButton.alpha = 1
        if UIDevice.isPortrait {
            if isToolsDisplay {
                topMaskView.alpha = 0
                bottomMaskView.alpha = 1
            }
        }else {
            if isToolsDisplay {
                topMaskView.alpha = 1
                bottomMaskView.alpha = 1
            }
        }
    }
    
    func transitionCompletion() {
        switch loadAssetStatus {
        case .loadding(let isProgress):
            if isProgress {
                switch selectedAsset.type {
                case .networkVideo(_):
                    assetLoadingView = ProgressHUD.showLoading(addedTo: view, text: "视频下载中".localized, animated: true)
                default:
                    assetLoadingView = ProgressHUD.showLoading(addedTo: view, animated: true)
                }
            }else {
                ProgressHUD.showLoading(addedTo: view, animated: true)
            }
            bringViews()
        case .successful(let type):
            initAssetType(type)
        case .failure:
            if selectedAsset.contentType == .video {
                loadFailure(message: "视频获取失败!".localized)
            }else {
                loadFailure(message: "图片获取失败!".localized)
            }
        }
    }
}

extension EditorViewController: UINavigationControllerDelegate {
    public func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        if operation == .push {
            isTransitionCompletion = false
            return EditorTransition(mode: .push)
        }else if operation == .pop {
            return EditorTransition(mode: .pop)
        }
        return nil
    }
}
