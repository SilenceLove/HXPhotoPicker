//
//  PhotoEditorViewController.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/9.
//

import UIKit
import Photos

#if canImport(Kingfisher)
import Kingfisher
#endif

open class PhotoEditorViewController: BaseViewController {
    
    public weak var delegate: PhotoEditorViewControllerDelegate?
    
    /// 配置
    public let config: PhotoEditorConfiguration
    
    /// 当前编辑的图片
    public private(set) var image: UIImage!
    
    /// 来源
    public let sourceType: EditorController.SourceType
    
    /// 当前编辑状态
    public private(set) var state: State = .normal
    
    /// 上一次的编辑结果
    public let editResult: PhotoEditResult?
    
    /// 确认/取消之后自动退出界面
    public var autoBack: Bool = true
    
    /// 编辑image
    /// - Parameters:
    ///   - image: 对应的 UIImage
    ///   - editResult: 上一次编辑结果
    ///   - config: 编辑配置
    public init(
        image: UIImage,
        editResult: PhotoEditResult? = nil,
        config: PhotoEditorConfiguration
    ) {
        PhotoManager.shared.appearanceStyle = config.appearanceStyle
        PhotoManager.shared.createLanguageBundle(languageType: config.languageType)
        sourceType = .local
        self.image = image
        self.config = config
        self.editResult = editResult
        super.init(nibName: nil, bundle: nil)
    }
    
    #if HXPICKER_ENABLE_PICKER
    /// 当前编辑的PhotoAsset对象
    public private(set) var photoAsset: PhotoAsset!
    
    /// 编辑 PhotoAsset
    /// - Parameters:
    ///   - photoAsset: 对应数据的 PhotoAsset
    ///   - editResult: 上一次编辑结果
    ///   - config: 编辑配置
    public init(
        photoAsset: PhotoAsset,
        editResult: PhotoEditResult? = nil,
        config: PhotoEditorConfiguration
    ) {
        PhotoManager.shared.appearanceStyle = config.appearanceStyle
        PhotoManager.shared.createLanguageBundle(languageType: config.languageType)
        sourceType = .picker
        requestType = 1
        needRequest = true
        self.config = config
        self.editResult = editResult
        self.photoAsset = photoAsset
        super.init(nibName: nil, bundle: nil)
    }
    #endif
    
    #if canImport(Kingfisher)
    /// 当前编辑的网络图片地址
    public private(set) var networkImageURL: URL?
    
    /// 编辑网络图片
    /// - Parameters:
    ///   - networkImageURL: 对应的网络地址
    ///   - editResult: 上一次编辑结果
    ///   - config: 编辑配置
    public init(
        networkImageURL: URL,
        editResult: PhotoEditResult? = nil,
        config: PhotoEditorConfiguration
    ) {
        PhotoManager.shared.appearanceStyle = config.appearanceStyle
        PhotoManager.shared.createLanguageBundle(languageType: config.languageType)
        sourceType = .network
        requestType = 2
        needRequest = true
        self.networkImageURL = networkImageURL
        self.config = config
        self.editResult = editResult
        super.init(nibName: nil, bundle: nil)
    }
    #endif
    var filterHDImage: UIImage?
    var mosaicImage: UIImage?
    var thumbnailImage: UIImage!
    var transitionalImage: UIImage?
    var transitionCompletion: Bool = true
    var isFinishedBack: Bool = false
    private var needRequest: Bool = false
    private var requestType: Int = 0
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    lazy var imageView: PhotoEditorView = {
        let imageView = PhotoEditorView(config: config)
        imageView.editorDelegate = self
        return imageView
    }()
    var topViewIsHidden: Bool = false
    @objc func singleTap() {
        if state == .cropping {
            return
        }
        imageView.deselectedSticker()
        func resetOtherOption() {
            if let option = currentToolOption {
                if option.type == .graffiti {
                    imageView.drawEnabled = true
                }else if option.type == .mosaic {
                    imageView.mosaicEnabled = true
                }
            }
            showTopView()
        }
        if isFilter {
            isFilter = false
            resetOtherOption()
            hiddenFilterView()
            return
        }
        if showChartlet {
            imageView.isEnabled = true
            showChartlet = false
            resetOtherOption()
            hiddenChartletView()
            return
        }
        if topViewIsHidden {
            showTopView()
        }else {
            hidenTopView()
        }
    }
    
    /// 裁剪确认视图
    public lazy var cropConfirmView: EditorCropConfirmView = {
        let cropConfirmView = EditorCropConfirmView.init(config: config.cropConfimView, showReset: true)
        cropConfirmView.alpha = 0
        cropConfirmView.isHidden = true
        cropConfirmView.delegate = self
        return cropConfirmView
    }()
    public lazy var toolView: EditorToolView = {
        let toolView = EditorToolView.init(config: config.toolView)
        toolView.delegate = self
        return toolView
    }()
    
    public lazy var topView: UIView = {
        let view = UIView.init(frame: CGRect(x: 0, y: 0, width: 0, height: 44))
        let cancelBtn = UIButton.init(frame: CGRect(x: 0, y: 0, width: 57, height: 44))
        cancelBtn.setImage(UIImage.image(for: "hx_editor_back"), for: .normal)
        cancelBtn.addTarget(self, action: #selector(didBackButtonClick), for: .touchUpInside)
        view.addSubview(cancelBtn)
        return view
    }()
    
    @objc func didBackButtonClick() {
        transitionalImage = image
        didBackClick(true)
    }
    
    func didBackClick(_ isCancel: Bool = false) {
        imageView.imageResizerView.stopShowMaskBgTimer()
        if isCancel {
            delegate?.photoEditorViewController(didCancel: self)
        }
        if autoBack {
            if let navigationController = navigationController, navigationController.viewControllers.count > 1 {
                navigationController.popViewController(animated: true)
            }else {
                dismiss(animated: true, completion: nil)
            }
        }
    }
    
    public lazy var topMaskLayer: CAGradientLayer = {
        let layer = PhotoTools.getGradientShadowLayer(true)
        return layer
    }()
    lazy var brushSizeView: BrushSizeView = {
        let lineWidth = imageView.brushLineWidth + 4
        let view = BrushSizeView(frame: CGRect(origin: .zero, size: CGSize(width: lineWidth, height: lineWidth)))
        return view
    }()
    public lazy var brushColorView: PhotoEditorBrushColorView = {
        let view = PhotoEditorBrushColorView(config: config.brush)
        view.delegate = self
        view.alpha = 0
        view.isHidden = true
        return view
    }()
    var showChartlet: Bool = false
    lazy var chartletView: EditorChartletView = {
        let view = EditorChartletView(
            config: config.chartlet,
            editorType: .photo
        )
        view.delegate = self
        return view
    }()
    
    public lazy var cropToolView: PhotoEditorCropToolView = {
        var showRatios = true
        if config.cropping.fixedRatio || config.cropping.isRoundCrop {
            showRatios = false
        }
        let view = PhotoEditorCropToolView.init(showRatios: showRatios)
        view.delegate = self
        view.themeColor = config.cropping.aspectRatioSelectedColor
        view.alpha = 0
        view.isHidden = true
        return view
    }()
    lazy var mosaicToolView: PhotoEditorMosaicToolView = {
        let view = PhotoEditorMosaicToolView(selectedColor: config.toolView.toolSelectedColor)
        view.delegate = self
        view.alpha = 0
        view.isHidden = true
        return view
    }()
    var isFilter = false
    var filterImage: UIImage?
    lazy var filterView: PhotoEditorFilterView = {
        let filter = editResult?.editedData.filter
        let value = editResult?.editedData.filterValue
        let view = PhotoEditorFilterView(
            filterConfig: config.filter,
            sourceIndex: filter?.sourceIndex ?? -1,
            value: value ?? 0
        )
        view.delegate = self
        return view
    }()
    
    var imageInitializeCompletion = false
    var orientationDidChange: Bool = false
    var imageViewDidChange: Bool = true
    var currentToolOption: EditorToolOptions?
    var toolOptions: EditorToolView.Options = []
    open override func viewDidLoad() {
        super.viewDidLoad()
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
        let singleTap = UITapGestureRecognizer.init(target: self, action: #selector(singleTap))
        singleTap.delegate = self
        view.addGestureRecognizer(singleTap)
        view.isExclusiveTouch = true
        view.backgroundColor = .black
        view.clipsToBounds = true
        view.addSubview(imageView)
        view.addSubview(toolView)
        if toolOptions.contains(.cropping) {
            view.addSubview(cropConfirmView)
            view.addSubview(cropToolView)
        }
        if config.fixedCropState {
            state = .cropping
            toolView.alpha = 0
            toolView.isHidden = true
            topView.alpha = 0
            topView.isHidden = true
        }else {
            state = config.state
            if toolOptions.contains(.graffiti) {
                view.addSubview(brushColorView)
            }
            if toolOptions.contains(.chartlet) {
                view.addSubview(chartletView)
            }
            if toolOptions.contains(.mosaic) {
                view.addSubview(mosaicToolView)
            }
            if toolOptions.contains(.filter) {
                view.addSubview(filterView)
            }
        }
        view.layer.addSublayer(topMaskLayer)
        view.addSubview(topView)
        if needRequest {
            if requestType == 1 {
                #if HXPICKER_ENABLE_PICKER
                requestImage()
                #endif
            }else if requestType == 2 {
                #if canImport(Kingfisher)
                requestNetworkImage()
                #endif
            }
        }else {
            if !config.fixedCropState {
                localImageHandler()
            }
        }
    }
    open override func deviceOrientationWillChanged(notify: Notification) {
        if showChartlet {
            singleTap()
        }
        imageView.undoAllDraw()
        if toolOptions.contains(.graffiti) {
            brushColorView.canUndo = imageView.canUndoDraw
        }
        imageView.undoAllMosaic()
        if toolOptions.contains(.mosaic) {
            mosaicToolView.canUndo = imageView.canUndoMosaic
        }
        imageView.undoAllSticker()
        imageView.reset(false)
        imageView.finishCropping(false)
        if config.fixedCropState {
            return
        }
        state = .normal
        croppingAction()
    }
    open override func deviceOrientationDidChanged(notify: Notification) {
        orientationDidChange = true
        imageViewDidChange = false
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
        let cancelButton = topView.subviews.first
        cancelButton?.x = UIDevice.leftMargin
        if let modalPresentationStyle = navigationController?.modalPresentationStyle,
           UIDevice.isPortrait {
            if modalPresentationStyle == .fullScreen || modalPresentationStyle == .custom {
                topView.y = UIDevice.generalStatusBarHeight
            }
        }else if (modalPresentationStyle == .fullScreen || modalPresentationStyle == .custom) && UIDevice.isPortrait {
            topView.y = UIDevice.generalStatusBarHeight
        }
        topMaskLayer.frame = CGRect(x: 0, y: 0, width: view.width, height: topView.frame.maxY + 10)
        let cropToolFrame = CGRect(x: 0, y: cropConfirmView.y - 60, width: view.width, height: 60)
        if toolOptions.contains(.cropping) {
            cropConfirmView.frame = toolView.frame
            cropToolView.frame = cropToolFrame
            cropToolView.updateContentInset()
        }
        if toolOptions.contains(.graffiti) {
            brushColorView.frame = CGRect(x: 0, y: cropConfirmView.y - 85, width: view.width, height: 85)
        }
        if toolOptions.contains(.mosaic) {
            mosaicToolView.frame = cropToolFrame
        }
        if toolOptions.isSticker {
            setChartletViewFrame()
        }
        if toolOptions.contains(.filter) {
            setFilterViewFrame()
        }
        if !imageView.frame.equalTo(view.bounds) && !imageView.frame.isEmpty && !imageViewDidChange {
            imageView.frame = view.bounds
            imageView.reset(false)
            imageView.finishCropping(false)
            orientationDidChange = true
        }else {
            imageView.frame = view.bounds
        }
        if !imageInitializeCompletion {
            if !needRequest || image != nil {
                imageView.setImage(image)
//                setFilterImage()
                if let editedData = editResult?.editedData {
                    imageView.setEditedData(editedData: editedData)
                    if toolOptions.contains(.graffiti) {
                        brushColorView.canUndo = imageView.canUndoDraw
                    }
                    if toolOptions.contains(.mosaic) {
                        mosaicToolView.canUndo = imageView.canUndoMosaic
                    }
                }
                imageInitializeCompletion = true
                if transitionCompletion {
                    initializeStartCropping()
                }
            }
        }
        if orientationDidChange {
            imageView.orientationDidChange()
            if config.fixedCropState {
                imageView.startCropping(false)
            }
            orientationDidChange = false
            imageViewDidChange = true
        }
    }
    func initializeStartCropping() {
        if !imageInitializeCompletion || state != .cropping {
            return
        }
        imageView.startCropping(true)
        croppingAction()
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
    open override var prefersStatusBarHidden: Bool {
        return config.prefersStatusBarHidden
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
    
    func setImage(_ image: UIImage) {
        self.image = image
    }
    func setState(_ state: State) {
        self.state = state
    }
}

extension PhotoEditorViewController: PhotoEditorBrushColorViewDelegate {
    func brushColorView(didUndoButton colorView: PhotoEditorBrushColorView) {
        imageView.undoDraw()
        brushColorView.canUndo = imageView.canUndoDraw
    }
    func brushColorView(_ colorView: PhotoEditorBrushColorView, changedColor colorHex: String) {
        imageView.drawColorHex = colorHex
    }
    func brushColorView(touchDown colorView: PhotoEditorBrushColorView) {
        let lineWidth = imageView.brushLineWidth + 4
        brushSizeView.size = CGSize(width: lineWidth, height: lineWidth)
        brushSizeView.center = CGPoint(x: view.width * 0.5, y: view.height * 0.5)
        brushSizeView.alpha = 0
        view.addSubview(brushSizeView)
        UIView.animate(withDuration: 0.2) {
            self.brushSizeView.alpha = 1
        }
    }
    func brushColorView(touchUpOutside colorView: PhotoEditorBrushColorView) {
        UIView.animate(withDuration: 0.2) {
            self.brushSizeView.alpha = 0
        } completion: { _ in
            self.brushSizeView.removeFromSuperview()
        }
    }
    func brushColorView(
        _ colorView: PhotoEditorBrushColorView,
        didChangedBrushLine lineWidth: CGFloat
    ) {
        imageView.brushLineWidth = lineWidth
        brushSizeView.size = CGSize(width: lineWidth + 4, height: lineWidth + 4)
        brushSizeView.center = CGPoint(x: view.width * 0.5, y: view.height * 0.5)
    }
    
    class BrushSizeView: UIView {
        lazy var borderLayer: CAShapeLayer = {
            let borderLayer = CAShapeLayer()
            borderLayer.strokeColor = UIColor.white.cgColor
            borderLayer.fillColor = UIColor.clear.cgColor
            borderLayer.lineWidth = 2
            borderLayer.shadowColor = UIColor.black.withAlphaComponent(0.4).cgColor
            borderLayer.shadowRadius = 2
            borderLayer.shadowOpacity = 0.5
            borderLayer.shadowOffset = CGSize(width: 0, height: 0)
            return borderLayer
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            layer.addSublayer(borderLayer)
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            borderLayer.frame = bounds
            
            let path = UIBezierPath(
                arcCenter: CGPoint(x: width * 0.5, y: height * 0.5),
                radius: width * 0.5 - 1,
                startAngle: 0,
                endAngle: CGFloat.pi * 2,
                clockwise: true
            )
            borderLayer.path = path.cgPath
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

// MARK: EditorCropConfirmViewDelegate
extension PhotoEditorViewController: EditorCropConfirmViewDelegate {
    
    /// 点击完成按钮
    /// - Parameter cropConfirmView: 裁剪视图
    func cropConfirmView(didFinishButtonClick cropConfirmView: EditorCropConfirmView) {
        if config.fixedCropState {
            imageView.imageResizerView.finishCropping(false, completion: nil, updateCrop: false)
            exportResources()
            return
        }
        state = .normal
        imageView.finishCropping(true)
        croppingAction()
    }
    
    /// 点击还原按钮
    /// - Parameter cropConfirmView: 裁剪视图
    func cropConfirmView(didResetButtonClick cropConfirmView: EditorCropConfirmView) {
        cropConfirmView.resetButton.isEnabled = false
        imageView.reset(true)
        cropToolView.reset(animated: true)
    }
    
    /// 点击取消按钮
    /// - Parameter cropConfirmView: 裁剪视图
    func cropConfirmView(didCancelButtonClick cropConfirmView: EditorCropConfirmView) {
        if config.fixedCropState {
            transitionalImage = image
            didBackClick(true)
            return
        }
        state = .normal
        imageView.cancelCropping(true)
        croppingAction()
    }
}

// MARK: PhotoEditorViewDelegate
extension PhotoEditorViewController: PhotoEditorViewDelegate {
    func checkResetButton() {
        cropConfirmView.resetButton.isEnabled = imageView.canReset()
    }
    func editorView(willBeginEditing editorView: PhotoEditorView) {
    }
    
    func editorView(didEndEditing editorView: PhotoEditorView) {
        checkResetButton()
    }
    
    func editorView(willAppearCrop editorView: PhotoEditorView) {
        cropToolView.reset(animated: false)
        cropConfirmView.resetButton.isEnabled = false
    }
    
    func editorView(didAppear editorView: PhotoEditorView) {
        checkResetButton()
    }
    
    func editorView(willDisappearCrop editorView: PhotoEditorView) {
    }
    
    func editorView(didDisappearCrop editorView: PhotoEditorView) {
    }
    
    func editorView(drawViewBeganDraw editorView: PhotoEditorView) {
        hidenTopView()
    }
    
    func editorView(drawViewEndDraw editorView: PhotoEditorView) {
        showTopView()
        brushColorView.canUndo = editorView.canUndoDraw
        mosaicToolView.canUndo = editorView.canUndoMosaic
    }
    func editorView(_ editorView: PhotoEditorView, updateStickerText item: EditorStickerItem) {
        let textVC = EditorStickerTextViewController(
            config: config.text,
            stickerItem: item
        )
        textVC.delegate = self
        let nav = EditorStickerTextController(rootViewController: textVC)
        nav.modalPresentationStyle = config.text.modalPresentationStyle
        present(nav, animated: true, completion: nil)
    }
}

extension PhotoEditorViewController: PhotoEditorCropToolViewDelegate {
    func cropToolView(didRotateButtonClick cropToolView: PhotoEditorCropToolView) {
        imageView.rotate()
    }
    
    func cropToolView(didMirrorHorizontallyButtonClick cropToolView: PhotoEditorCropToolView) {
        imageView.mirrorHorizontally(animated: true)
    }
    
    func cropToolView(didChangedAspectRatio cropToolView: PhotoEditorCropToolView, at model: PhotoEditorCropToolModel) {
        imageView.changedAspectRatio(of: CGSize(width: model.widthRatio, height: model.heightRatio))
    }
}
extension PhotoEditorViewController: PhotoEditorMosaicToolViewDelegate {
    func mosaicToolView(
        _ mosaicToolView: PhotoEditorMosaicToolView,
        didChangedMosaicType type: PhotoEditorMosaicView.MosaicType
    ) {
        imageView.mosaicType = type
    }
    
    func mosaicToolView(didUndoClick mosaicToolView: PhotoEditorMosaicToolView) {
        imageView.undoMosaic()
        mosaicToolView.canUndo = imageView.canUndoMosaic
    }
}
extension PhotoEditorViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view is EditorStickerContentView {
            return false
        }
        if let isDescendant = touch.view?.isDescendant(of: imageView), isDescendant {
            return true
        }
        return false
    }
    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}

extension PhotoEditorViewController: UINavigationControllerDelegate {
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
