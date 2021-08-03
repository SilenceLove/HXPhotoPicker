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

public protocol PhotoEditorViewControllerDelegate: AnyObject {
    
    /// 编辑完成
    /// - Parameters:
    ///   - photoEditorViewController: 对应的 PhotoEditorViewController
    ///   - result: 编辑后的数据
    func photoEditorViewController(_ photoEditorViewController: PhotoEditorViewController,
                                   didFinish result: PhotoEditResult)
    
    /// 点击完成按钮，但是照片未编辑
    /// - Parameters:
    ///   - photoEditorViewController: 对应的 PhotoEditorViewController
    func photoEditorViewController(didFinishWithUnedited photoEditorViewController: PhotoEditorViewController)
    
    /// 加载贴图标题资源
    /// - Parameters:
    ///   - photoEditorViewController: 对应的 PhotoEditorViewController 
    ///   - loadTitleChartlet: 传入标题数组
    func photoEditorViewController(_ photoEditorViewController: PhotoEditorViewController,
                                   loadTitleChartlet response: @escaping EditorTitleChartletResponse)
    /// 加载贴图资源
    /// - Parameters:
    ///   - photoEditorViewController: 对应的 PhotoEditorViewController
    ///   - titleChartlet: 对应配置的 title
    ///   - titleIndex: 对应配置的 title 的位置索引
    ///   - response: 传入 title索引 和 贴图数据
    func photoEditorViewController(_ photoEditorViewController: PhotoEditorViewController,
                                   titleChartlet: EditorChartlet,
                                   titleIndex: Int,
                                   loadChartletList response: @escaping EditorChartletListResponse)
    
    /// 取消编辑
    /// - Parameter photoEditorViewController: 对应的 PhotoEditorViewController
    func photoEditorViewController(didCancel photoEditorViewController: PhotoEditorViewController)
}
public extension PhotoEditorViewControllerDelegate {
    func photoEditorViewController(_ photoEditorViewController: PhotoEditorViewController, didFinish result: PhotoEditResult) {}
    func photoEditorViewController(didFinishWithUnedited photoEditorViewController: PhotoEditorViewController) {}
    func photoEditorViewController(didCancel photoEditorViewController: PhotoEditorViewController) {}
    func photoEditorViewController(_ photoEditorViewController: PhotoEditorViewController,
                                   loadTitleChartlet response: @escaping EditorTitleChartletResponse) {
        #if canImport(Kingfisher)
        let titles = PhotoTools.defaultTitleChartlet()
        response(titles)
        #endif
    }
    func photoEditorViewController(_ photoEditorViewController: PhotoEditorViewController,
                                   titleChartlet: EditorChartlet,
                                   titleIndex: Int,
                                   loadChartletList response: @escaping EditorChartletListResponse) {
        /// 默认加载这些贴图
        #if canImport(Kingfisher)
        let chartletList = PhotoTools.defaultNetworkChartlet()
        response(titleIndex, chartletList)
        #endif
    }
}

open class PhotoEditorViewController: BaseViewController {
    
    public weak var delegate: PhotoEditorViewControllerDelegate?
    
    /// 配置
    public let config: PhotoEditorConfiguration
    
    /// 当前编辑的图片
    public private(set) var image: UIImage!
    
    /// 资源类型
    public let sourceType: EditorController.SourceType
    
    /// 当前编辑状态
    public private(set) var state: State = .normal
    
    /// 上一次的编辑结果
    public let editResult: PhotoEditResult?
    
    /// 编辑image
    /// - Parameters:
    ///   - image: 对应的 UIImage
    ///   - editResult: 上一次编辑结果
    ///   - config: 编辑配置
    public init(image: UIImage,
                editResult: PhotoEditResult? = nil,
                config: PhotoEditorConfiguration) {
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
    public init(photoAsset: PhotoAsset,
                editResult: PhotoEditResult? = nil,
                config: PhotoEditorConfiguration) {
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
    public var networkImageURL: URL?
    
    /// 编辑网络图片
    /// - Parameters:
    ///   - networkImageURL: 对应的网络地址
    ///   - editResult: 上一次编辑结果
    ///   - config: 编辑配置
    public init(networkImageURL: URL,
                editResult: PhotoEditResult? = nil,
                config: PhotoEditorConfiguration) {
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
    var needRequest: Bool = false
    var requestType: Int = 0
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var imageView: PhotoEditorView = {
        let imageView = PhotoEditorView.init(config: config)
        imageView.editorDelegate = self
        return imageView
    }()
    var topViewIsHidden: Bool = false
    @objc func singleTap() {
        if state == .cropping {
            return
        }
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
    lazy var cropConfirmView: EditorCropConfirmView = {
        let cropConfirmView = EditorCropConfirmView.init(config: config.cropConfimView, showReset: true)
        cropConfirmView.alpha = 0
        cropConfirmView.isHidden = true
        cropConfirmView.delegate = self
        return cropConfirmView
    }()
    lazy var toolView: EditorToolView = {
        let toolView = EditorToolView.init(config: config.toolView)
        toolView.delegate = self
        return toolView
    }()
    
    lazy var topView: UIView = {
        let view = UIView.init(frame: CGRect(x: 0, y: 0, width: 0, height: 44))
        let cancelBtn = UIButton.init(frame: CGRect(x: 0, y: 0, width: 57, height: 44))
        cancelBtn.setImage(UIImage.image(for: "hx_editor_back"), for: .normal)
        cancelBtn.addTarget(self, action: #selector(didBackClick), for: .touchUpInside)
        view.addSubview(cancelBtn)
        return view
    }()
    @objc func didBackClick() {
        delegate?.photoEditorViewController(didCancel: self)
        if let navigationController = navigationController, navigationController.viewControllers.count > 1 {
            navigationController.popViewController(animated: true)
        }else {
            dismiss(animated: true, completion: nil)
        }
    }
    
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
    
    lazy var brushColorView: PhotoEditorBrushColorView = {
        let view = PhotoEditorBrushColorView.init(frame: .zero)
        view.delegate = self
        view.brushColors = config.brushColors
        view.currentColorIndex = config.defaultBrushColorIndex
        view.alpha = 0
        view.isHidden = true
        return view
    }()
    var showChartlet: Bool = false
    lazy var chartletView: EditorChartletView = {
        let view = EditorChartletView(config: config.chartlet)
        view.delegate = self
        return view
    }()
    
    lazy var cropToolView: PhotoEditorCropToolView = {
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
    var filterImage: UIImage? = nil
    lazy var filterView: PhotoEditorFilterView = {
        let filter = editResult?.editedData.filter
        let value = editResult?.editedData.filterValue
        let view = PhotoEditorFilterView.init(filterConfig: config.filter,
                                              sourceIndex: filter?.sourceIndex ?? -1,
                                              value: value ?? 0)
        view.delegate = self
        return view
    }()
    
    var imageInitializeCompletion = false
    var orientationDidChange: Bool = false
    var imageViewDidChange: Bool = true
    var currentToolOption: EditorToolOptions?
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        let singleTap = UITapGestureRecognizer.init(target: self, action: #selector(singleTap))
        singleTap.delegate = self
        view.addGestureRecognizer(singleTap)
        view.isExclusiveTouch = true
        view.backgroundColor = .black
        view.clipsToBounds = true
        view.addSubview(imageView)
        view.addSubview(toolView)
        view.addSubview(cropConfirmView)
        view.addSubview(cropToolView)
        if config.fixedCropState {
            state = .cropping
            toolView.alpha = 0
            toolView.isHidden = true
            topView.alpha = 0
            topView.isHidden = true
        }else {
            state = config.state
            view.addSubview(brushColorView)
            view.addSubview(chartletView)
            view.addSubview(mosaicToolView)
            view.addSubview(filterView)
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
            localImageHandler()
        }
    }
    open override func deviceOrientationWillChanged(notify: Notification) {
        if showChartlet {
            singleTap()
        }
        imageView.undoAllDraw()
        imageView.undoAllMosaic()
        imageView.undoAllSticker()
        brushColorView.canUndo = imageView.canUndoDraw
        mosaicToolView.canUndo = imageView.canUndoMosaic
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
        toolView.frame = CGRect(x: 0, y: view.height - UIDevice.bottomMargin - 50, width: view.width, height: 50 + UIDevice.bottomMargin)
        toolView.reloadContentInset()
        topView.width = view.width
        topView.height = navigationController?.navigationBar.height ?? 44
        let cancelButton = topView.subviews.first
        cancelButton?.x = UIDevice.leftMargin
        if let modalPresentationStyle = navigationController?.modalPresentationStyle, UIDevice.isPortrait {
            if modalPresentationStyle == .fullScreen || modalPresentationStyle == .custom {
                topView.y = UIDevice.generalStatusBarHeight
            }
        }else if (modalPresentationStyle == .fullScreen || modalPresentationStyle == .custom) && UIDevice.isPortrait {
            topView.y = UIDevice.generalStatusBarHeight
        }
        topMaskLayer.frame = CGRect(x: 0, y: 0, width: view.width, height: topView.frame.maxY + 10)
        cropConfirmView.frame = toolView.frame
        cropToolView.frame = CGRect(x: 0, y: cropConfirmView.y - 60, width: view.width, height: 60)
        brushColorView.frame = cropToolView.frame
        mosaicToolView.frame = brushColorView.frame
        cropToolView.updateContentInset()
        setChartletViewFrame()
        setFilterViewFrame()
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
                    brushColorView.canUndo = imageView.canUndoDraw
                    mosaicToolView.canUndo = imageView.canUndoMosaic
                }
                if state == .cropping {
                    imageView.startCropping(true)
                    croppingAction()
                }
            }
            imageInitializeCompletion = true
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
    func setChartletViewFrame() {
        var viewHeight = config.chartlet.viewHeight
        if viewHeight > view.height {
            viewHeight = view.height * 0.6
        }
        if showChartlet {
            chartletView.frame = CGRect(x: 0, y: view.height - viewHeight - UIDevice.bottomMargin, width: view.width, height: viewHeight + UIDevice.bottomMargin)
        }else {
            chartletView.frame = CGRect(x: 0, y: view.height, width: view.width, height: viewHeight + UIDevice.bottomMargin)
        }
    }
    func setFilterViewFrame() {
        if isFilter {
            filterView.frame = CGRect(x: 0, y: view.height - 150 - UIDevice.bottomMargin, width: view.width, height: 150 + UIDevice.bottomMargin)
        }else {
            filterView.frame = CGRect(x: 0, y: view.height + 10, width: view.width, height: 150 + UIDevice.bottomMargin)
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
        if navigationController?.topViewController != self && navigationController?.viewControllers.contains(self) == false {
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
}

extension PhotoEditorViewController: EditorToolViewDelegate {
    func toolView(didFinishButtonClick toolView: EditorToolView) {
        exportResources()
    }
    func toolView(_ toolView: EditorToolView, didSelectItemAt model: EditorToolOptions) {
        switch model.type {
        case .graffiti:
            currentToolOption = nil
            imageView.mosaicEnabled = false
            hiddenMosaicToolView()
            imageView.drawEnabled = !imageView.drawEnabled
            toolView.stretchMask = imageView.drawEnabled
            toolView.layoutSubviews()
            if imageView.drawEnabled {
                imageView.stickerEnabled = false
                showBrushColorView()
                currentToolOption = model
            }else {
                imageView.stickerEnabled = true
                hiddenBrushColorView()
            }
        case .chartlet:
            chartletView.firstRequest()
            imageView.deselectedSticker()
            imageView.drawEnabled = false
            imageView.mosaicEnabled = false
            imageView.stickerEnabled = false
            imageView.isEnabled = false
            showChartlet = true
            hidenTopView()
            showChartletView()
        case .text:
            imageView.deselectedSticker()
            let textVC = EditorStickerTextViewController(config: config.text)
            textVC.delegate = self
            let nav = EditorStickerTextController(rootViewController: textVC)
            nav.modalPresentationStyle = config.text.modalPresentationStyle
            present(nav, animated: true, completion: nil)
        case .cropping:
            imageView.drawEnabled = false
            imageView.mosaicEnabled = false
            imageView.stickerEnabled = false
            state = .cropping
            imageView.startCropping(true)
            croppingAction()
        case .mosaic:
            currentToolOption = nil
            imageView.drawEnabled = false
            hiddenBrushColorView()
            imageView.mosaicEnabled = !imageView.mosaicEnabled
            toolView.stretchMask = imageView.mosaicEnabled
            toolView.layoutSubviews()
            if imageView.mosaicEnabled {
                imageView.stickerEnabled = false
                showMosaicToolView()
                currentToolOption = model
            }else {
                imageView.stickerEnabled = true
                hiddenMosaicToolView()
            }
        case .filter:
            imageView.drawEnabled = false
            imageView.mosaicEnabled = false
            imageView.stickerEnabled = false
            isFilter = true
            hidenTopView()
            showFilterView()
        default:
            break
        }
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
            didBackClick()
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
        let textVC = EditorStickerTextViewController(config: config.text,
                                                     stickerItem: item)
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
    func mosaicToolView(_ mosaicToolView: PhotoEditorMosaicToolView, didChangedMosaicType type: PhotoEditorMosaicView.MosaicType) {
        imageView.mosaicType = type
    }
    
    func mosaicToolView(didUndoClick mosaicToolView: PhotoEditorMosaicToolView) {
        imageView.undoMosaic()
        mosaicToolView.canUndo = imageView.canUndoMosaic
    }
}
extension PhotoEditorViewController: PhotoEditorFilterViewDelegate {
    func filterView(shouldSelectFilter filterView: PhotoEditorFilterView) -> Bool {
        true
    }
    
    func filterView(_ filterView: PhotoEditorFilterView,
                    didSelected filter: PhotoEditorFilter,
                    atItem: Int) {
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
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}

extension PhotoEditorViewController: EditorStickerTextViewControllerDelegate {
    func stickerTextViewController(_ controller: EditorStickerTextViewController, didFinish stickerItem: EditorStickerItem) {
        imageView.updateSticker(item: stickerItem)
    }
    
    func stickerTextViewController(_ controller: EditorStickerTextViewController, didFinish stickerText: EditorStickerText) {
        let item = EditorStickerItem(image: stickerText.image, text: stickerText)
        imageView.addSticker(item: item, isSelected: false)
    }
}

extension PhotoEditorViewController: EditorChartletViewDelegate {
    func chartletView(_ chartletView: EditorChartletView, loadTitleChartlet response: @escaping ([EditorChartlet]) -> Void) {
        delegate?.photoEditorViewController(self, loadTitleChartlet: response)
    }
    func chartletView(backClick chartletView: EditorChartletView) {
        singleTap()
    }
    func chartletView(_ chartletView: EditorChartletView,
                      titleChartlet: EditorChartlet,
                      titleIndex: Int,
                      loadChartletList response: @escaping (Int, [EditorChartlet]) -> Void) {
        delegate?.photoEditorViewController(self,
                                            titleChartlet: titleChartlet,
                                            titleIndex: titleIndex,
                                            loadChartletList: response)
    }
    func chartletView(_ chartletView: EditorChartletView, didSelectImage image: UIImage) {
        let item = EditorStickerItem(image: image, text: nil)
        imageView.addSticker(item: item, isSelected: false)
        singleTap()
    }
}
