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
    func photoEditorViewController(_ photoEditorViewController: PhotoEditorViewController, didFinish result: PhotoEditResult)
    
    /// 点击完成按钮，但是照片未编辑
    /// - Parameters:
    ///   - photoEditorViewController: 对应的 PhotoEditorViewController
    func photoEditorViewController(didFinishWithUnedited photoEditorViewController: PhotoEditorViewController)
    
    /// 取消编辑
    /// - Parameter photoEditorViewController: 对应的 PhotoEditorViewController
    func photoEditorViewController(didCancel photoEditorViewController: PhotoEditorViewController)
}
public extension PhotoEditorViewControllerDelegate {
    func photoEditorViewController(_ photoEditorViewController: PhotoEditorViewController, didFinish result: PhotoEditResult) {}
    func photoEditorViewController(didFinishWithUnedited photoEditorViewController: PhotoEditorViewController) {}
    func photoEditorViewController(didCancel photoEditorViewController: PhotoEditorViewController) {}
}

open class PhotoEditorViewController: BaseViewController {
    
    public weak var delegate: PhotoEditorViewControllerDelegate?
    
    /// 配置
    public let config: PhotoEditorConfiguration
    
    /// 当前编辑的图片
    public private(set) var image: UIImage!
    
    /// 资源类型
    public let assetType: EditorController.AssetType
    
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
        assetType = .local
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
        assetType = .picker
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
        assetType = .network
        requestType = 2
        needRequest = true
        self.networkImageURL = networkImageURL
        self.config = config
        self.editResult = editResult
        super.init(nibName: nil, bundle: nil)
    }
    #endif
    
    var needRequest: Bool = false
    var requestType: Int = 0
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var imageView: PhotoEditorView = {
        let imageView = PhotoEditorView.init(config: config)
        imageView.editorDelegate = self
        let singleTap = UITapGestureRecognizer.init(target: self, action: #selector(singleTap(tap:)))
        imageView.addGestureRecognizer(singleTap)
        return imageView
    }()
    var topViewIsHidden: Bool = false
    @objc func singleTap(tap: UITapGestureRecognizer) {
        if state == .cropping {
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
                        blackColor.withAlphaComponent(0.15).cgColor,
                        blackColor.withAlphaComponent(0.35).cgColor,
                        blackColor.withAlphaComponent(0.6).cgColor]
        layer.startPoint = CGPoint(x: 0, y: 1)
        layer.endPoint = CGPoint(x: 0, y: 0)
        layer.locations = [0.15, 0.35, 0.6, 0.9]
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
    
    lazy var cropToolView: PhotoEditorCropToolView = {
        var showRatios = true
        if config.cropConfig.fixedRatio || config.cropConfig.isRoundCrop {
            showRatios = false
        }
        let view = PhotoEditorCropToolView.init(showRatios: showRatios)
        view.delegate = self
        view.themeColor = config.cropConfig.aspectRatioSelectedColor
        view.alpha = 0
        view.isHidden = true
        return view
    }()
    
    var imageInitializeCompletion = false
    var orientationDidChange: Bool = false
    var imageViewDidChange: Bool = true
    var currentToolOption: EditorToolOptions?
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        if config.fixedCropState {
            state = .cropping
            toolView.alpha = 0
            toolView.isHidden = true
            topView.alpha = 0
            topView.isHidden = true
        }else {
            state = config.state
        }
        view.backgroundColor = .black
        view.clipsToBounds = true
        view.addSubview(imageView)
        view.addSubview(toolView)
        view.addSubview(brushColorView)
        view.addSubview(cropConfirmView)
        view.addSubview(cropToolView)
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
        }
    }
    open override func deviceOrientationWillChanged(notify: Notification) {
        imageView.undoAllDraw()
        brushColorView.canUndo = imageView.canUndoDraw
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
        cropToolView.updateContentInset()
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
                if let editedData = editResult?.editedData {
                    imageView.setEditedData(editedData: editedData)
                    brushColorView.canUndo = imageView.canUndoDraw
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
}
extension PhotoEditorViewController {
    #if HXPICKER_ENABLE_PICKER
    func requestImage() {
        if photoAsset.isLocalAsset {
            if photoAsset.mediaType == .photo {
                var image = photoAsset.localImageAsset!.image!
                if photoAsset.mediaSubType.isGif {
                    if let imageData = photoAsset.localImageAsset?.imageData {
                        #if canImport(Kingfisher)
                        if let gifImage = DefaultImageProcessor.default.process(item: .data(imageData), options: .init([]))  {
                            image = gifImage
                        }
                        #endif
                    }else if let imageURL = photoAsset.localImageAsset?.imageURL {
                        do {
                            let imageData = try Data.init(contentsOf: imageURL)
                            #if canImport(Kingfisher)
                            if let gifImage = DefaultImageProcessor.default.process(item: .data(imageData), options: .init([]))  {
                                image = gifImage
                            }
                            #endif
                        }catch {}
                    }
                }
                requestAssetCompletion(image: image)
            }else {
                requestAssetCompletion(image: photoAsset.localVideoAsset!.image!)
            }
        }else if photoAsset.isNetworkAsset {
            #if canImport(Kingfisher)
            let loadingView = ProgressHUD.showLoading(addedTo: view, animated: true)
            photoAsset.getNetworkImage(urlType: .original, filterEditor: true) { (receiveSize, totalSize) in
                let progress = Double(receiveSize) / Double(totalSize)
                if progress > 0 {
                    loadingView?.updateText(text: "图片下载中".localized + "(" + String(Int(progress * 100)) + "%)")
                }
            } resultHandler: { [weak self] (image) in
                if let image = image {
                    ProgressHUD.hide(forView: self?.view, animated: true)
                    self?.requestAssetCompletion(image: image)
                }else {
                    ProgressHUD.hide(forView: self?.view, animated: true)
                    PhotoTools.showConfirm(viewController: self, title: "提示".localized, message: "图片获取失败!".localized, actionTitle: "确定".localized) { (alertAction) in
                        self?.didBackClick()
                    }
                }
            }
            #endif
        } else {
            ProgressHUD.showLoading(addedTo: view, animated: true)
            if photoAsset.phAsset != nil && !photoAsset.isGifAsset {
                photoAsset.requestImageData(filterEditor: true,
                                            iCloudHandler: nil,
                                            progressHandler: nil) {
                    [weak self] (asset, imageData, imageOrientation, info) in
                    let image = UIImage.init(data: imageData)?.scaleSuitableSize()
                    ProgressHUD.hide(forView: self?.view, animated: true)
                    self?.requestAssetCompletion(image: image!)
                } failure: { [weak self] (asset, info) in
                    ProgressHUD.hide(forView: self?.view, animated: true)
                    self?.requestAssetFailure()
                }
                return
            }
            photoAsset.requestAssetImageURL(filterEditor: true) {
                [weak self] (imageUrl) in
                DispatchQueue.global().async {
                    if let imageUrl = imageUrl {
                        #if canImport(Kingfisher)
                        if self?.photoAsset.isGifAsset == true {
                            do {
                                let imageData = try Data.init(contentsOf: imageUrl)
                                if let gifImage = DefaultImageProcessor.default.process(item: .data(imageData), options: .init([]))  {
                                    DispatchQueue.main.async {
                                        ProgressHUD.hide(forView: self?.view, animated: true)
                                        self?.requestAssetCompletion(image: gifImage)
                                    }
                                    return
                                }
                            }catch {}
                        }
                        #endif
                        if let image = UIImage.init(contentsOfFile: imageUrl.path)?.scaleSuitableSize() {
                            DispatchQueue.main.async {
                                ProgressHUD.hide(forView: self?.view, animated: true)
                                self?.requestAssetCompletion(image: image)
                            }
                            return
                        }
                    }
                    DispatchQueue.main.async {
                        ProgressHUD.hide(forView: self?.view, animated: true)
                        self?.requestAssetFailure()
                    }
                }
            }
        }
    }
    #endif
    
    #if canImport(Kingfisher)
    func requestNetworkImage() {
        let url = networkImageURL!
        let loadingView = ProgressHUD.showLoading(addedTo: view, animated: true)
        PhotoTools.downloadNetworkImage(with: url, options: [.backgroundDecode]) { (receiveSize, totalSize) in
            let progress = Double(receiveSize) / Double(totalSize)
            if progress > 0 {
                loadingView?.updateText(text: "图片下载中".localized + "(" + String(Int(progress * 100)) + "%)")
            }
        } completionHandler: { [weak self] (image) in
            ProgressHUD.hide(forView: self?.view, animated: true)
            if let image = image {
                self?.requestAssetCompletion(image: image)
            }else {
                self?.requestAssetFailure()
            }
        }
    }
    #endif
    
    func requestAssetCompletion(image: UIImage) {
        if imageInitializeCompletion == true {
            imageView.setImage(image)
            if let editedData = editResult?.editedData {
                imageView.setEditedData(editedData: editedData)
                brushColorView.canUndo = imageView.canUndoDraw
            }
            if state == .cropping {
                imageView.startCropping(true)
                croppingAction()
            }
        }
        self.image = image
    }
    func requestAssetFailure() {
        ProgressHUD.hide(forView: view, animated: true)
        PhotoTools.showConfirm(viewController: self, title: "提示".localized, message: "图片获取失败!".localized, actionTitle: "确定".localized) { (alertAction) in
            self.didBackClick()
        }
    }
}
// MARK: EditorToolViewDelegate
extension PhotoEditorViewController: EditorToolViewDelegate {
     
    func toolView(didFinishButtonClick toolView: EditorToolView) {
        editResources()
    }
    func editResources() {
        if imageView.canReset() ||
            imageView.imageResizerView.hasCropping ||
            imageView.canUndoDraw {
            
            ProgressHUD.showLoading(addedTo: view, animated: true)
            imageView.cropping { [weak self] (result) in
                if let result = result, let self = self {
                    self.delegate?.photoEditorViewController(self, didFinish: result)
                    self.didBackClick()
                }else {
                    ProgressHUD.hide(forView: self?.view, animated: true)
                    ProgressHUD.showWarning(addedTo: self?.view, text: "图片获取失败!".localized, animated: true, delayHide: 1.5)
                }
            }
        }else {
            delegate?.photoEditorViewController(didFinishWithUnedited: self)
            didBackClick()
        }
    }
    func toolView(_ toolView: EditorToolView, didSelectItemAt model: EditorToolOptions) {
        if model.type == .graffiti {
            imageView.drawEnabled = !imageView.drawEnabled
            toolView.stretchMask = imageView.drawEnabled
            toolView.layoutSubviews()
            if imageView.drawEnabled {
                showBrushColorView()
                currentToolOption = model
            }else {
                hiddenBrushColorView()
                currentToolOption = nil
            }
        }else if model.type == .cropping {
            imageView.drawEnabled = false
            state = .cropping
            imageView.startCropping(true)
            croppingAction()
        }
    }
    
    func showBrushColorView() {
        brushColorView.isHidden = false
        UIView.animate(withDuration: 0.25) {
            self.brushColorView.alpha = 1
        }
    }
    
    func hiddenBrushColorView() {
        if brushColorView.isHidden {
            return
        }
        UIView.animate(withDuration: 0.25) {
            self.brushColorView.alpha = 0
        } completion: { (_) in
            guard let option = self.currentToolOption, option.type == .graffiti else {
                return
            }
            self.brushColorView.isHidden = true
        }
    }
    
    func croppingAction() {
        if state == .cropping {
            cropConfirmView.isHidden = false
            cropToolView.isHidden = false
            hidenTopView()
        }else {
            if let option = currentToolOption {
                if option.type == .graffiti {
                    imageView.drawEnabled = true
                }
            }
            showTopView()
        }
        UIView.animate(withDuration: 0.25) {
            self.cropConfirmView.alpha = self.state == .cropping ? 1 : 0
            self.cropToolView.alpha = self.state == .cropping ? 1 : 0
        } completion: { (isFinished) in
            if self.state != .cropping {
                self.cropConfirmView.isHidden = true
                self.cropToolView.isHidden = true
            }
        }

    }
    func showTopView() {
        topViewIsHidden = false
        toolView.isHidden = false
        topView.isHidden = false
        var showBrush = false
        if let option = currentToolOption {
            if option.type == .graffiti {
                showBrush = true
                brushColorView.isHidden = false
            }
        }
        UIView.animate(withDuration: 0.25) {
            self.toolView.alpha = 1
            self.topView.alpha = 1
            self.topMaskLayer.isHidden = false
            if showBrush {
                self.brushColorView.alpha = 1
            }
        }
    }
    func hidenTopView() {
        topViewIsHidden = true
        var hiddenBrush = false
        if let option = currentToolOption {
            if option.type == .graffiti {
                hiddenBrush = true
            }
        }
        UIView.animate(withDuration: 0.25) {
            self.toolView.alpha = 0
            self.topView.alpha = 0
            self.topMaskLayer.isHidden = true
            if hiddenBrush {
                self.brushColorView.alpha = 0
            }
        } completion: { (isFinished) in
            if self.topViewIsHidden {
                self.toolView.isHidden = true
                self.topView.isHidden = true
                self.brushColorView.isHidden = true
            }
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
            editResources()
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
