//
//  HXPHPickerViewCell.swift
//  照片选择器-Swift
//
//  Created by Silence on 2019/6/29.
//  Copyright © 2019年 Silence. All rights reserved.
//

import UIKit
import Photos

@objc protocol HXPHPickerViewCellDelegate: NSObjectProtocol {
    @objc optional func cell(didSelectControl cell: HXPHPickerMultiSelectViewCell, isSelected: Bool)
}

class HXPHPickerViewCell: UICollectionViewCell {
    var config: HXPHPhotoListCellConfiguration? {
        didSet {
            configColor()
        }
    }
    func configColor() {
        backgroundColor = HXPHManager.shared.isDark ? config?.backgroundDarkColor : config?.backgroundColor
    }
    lazy var imageView: UIImageView = {
        let imageView = UIImageView.init()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.addSubview(assetTypeMaskView)
        imageView.layer.addSublayer(selectMaskLayer)
        return imageView
    }()
    lazy var assetTypeMaskView: UIView = {
        let assetTypeMaskView = UIView.init()
        assetTypeMaskView.isHidden = true
        assetTypeMaskView.layer.addSublayer(assetTypeMaskLayer)
        return assetTypeMaskView
    }()
    lazy var assetTypeMaskLayer: CAGradientLayer = {
        let layer = CAGradientLayer.init()
        layer.contentsScale = UIScreen.main.scale
        let blackColor = UIColor.black
        layer.colors = [blackColor.withAlphaComponent(0).cgColor,
                        blackColor.withAlphaComponent(0.15).cgColor,
                        blackColor.withAlphaComponent(0.35).cgColor,
                        blackColor.withAlphaComponent(0.6).cgColor]
        layer.startPoint = CGPoint(x: 0, y: 0)
        layer.endPoint = CGPoint(x: 0, y: 1)
        layer.locations = [0.15, 0.35, 0.6, 0.9]
        layer.borderWidth = 0.0
        return layer
    }()
    lazy var assetTypeLb: UILabel = {
        let assetTypeLb = UILabel.init()
        assetTypeLb.font = UIFont.hx_mediumPingFang(size: 14)
        assetTypeLb.textColor = .white
        assetTypeLb.textAlignment = .right
        return assetTypeLb
    }()
    lazy var videoIcon: UIImageView = {
        let videoIcon = UIImageView.init(image: UIImage.hx_named(named: "hx_picker_cell_video_icon"))
        videoIcon.hx_size = videoIcon.image?.size ?? CGSize.zero
        videoIcon.isHidden = true
        return videoIcon
    }()
    
    lazy var disableMaskLayer: CALayer = {
        let disableMaskLayer = CALayer.init()
        disableMaskLayer.backgroundColor = UIColor.white.withAlphaComponent(0.6).cgColor
        disableMaskLayer.frame = bounds
        disableMaskLayer.isHidden = true
        return disableMaskLayer
    }()
    var requestID: PHImageRequestID?
    var photoAsset: HXPHAsset? {
        didSet {
            switch photoAsset?.mediaSubType {
            case .imageAnimated:
                assetTypeLb.text = "GIF"
                assetTypeMaskView.isHidden = false
                break
            case .livePhoto:
                assetTypeLb.text = "Live"
                assetTypeMaskView.isHidden = false
                break
            case .video, .localVideo:
                assetTypeLb.text = photoAsset?.videoTime
                assetTypeMaskView.isHidden = false
                break
            default:
                assetTypeLb.text = nil
                assetTypeMaskView.isHidden = true
            }
            videoIcon.isHidden = photoAsset?.mediaType != .video
            requestThumbnailImage()
        }
    }
    /// 获取图片，重写此方法可以修改图片
    func requestThumbnailImage() {
        weak var weakSelf = self
        requestID = photoAsset?.requestThumbnailImage(targetWidth: hx_width * 2, completion: { (image, photoAsset, info) in
            if photoAsset == weakSelf?.photoAsset && image != nil {
                if !(weakSelf?.firstLoadCompletion ?? true) {
                    weakSelf?.isHidden = false
                    weakSelf?.firstLoadCompletion = true
                }
                weakSelf?.imageView.image = image
                if !HXPHAssetManager.assetDownloadIsDegraded(for: info) {
                    weakSelf?.requestID = nil
                }
            }
        })
    }
    
    lazy var selectMaskLayer: CALayer = {
        let selectMaskLayer = CALayer.init()
        selectMaskLayer.backgroundColor = UIColor.black.withAlphaComponent(0.6).cgColor
        selectMaskLayer.frame = bounds
        selectMaskLayer.isHidden = true
        return selectMaskLayer
    }()
    
    var canSelect = true {
        didSet {
            // 禁用遮罩
            setupDisableMask()
        }
    }
    private var firstLoadCompletion: Bool = false
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func initView() {
        isHidden = true
        contentView.addSubview(imageView)
        contentView.addSubview(assetTypeLb)
        contentView.addSubview(videoIcon)
        contentView.layer.addSublayer(disableMaskLayer)
    }
    
    /// 设置禁用遮罩
    func setupDisableMask() {
        disableMaskLayer.isHidden = canSelect
    }
    /// 设置高亮遮罩
    func setupHighlightedMask() {
        if let selected = photoAsset?.isSelected {
            if !selected {
                selectMaskLayer.isHidden = !isHighlighted
            }
        }
    }
    /// 布局，重写此方法修改布局
    func layoutView() {
        imageView.frame = bounds
        selectMaskLayer.frame = imageView.bounds
        disableMaskLayer.frame = imageView.bounds
        assetTypeMaskView.frame = CGRect(x: 0, y: imageView.hx_height - 25, width: hx_width, height: 25)
        assetTypeMaskLayer.frame = assetTypeMaskView.bounds
        assetTypeLb.frame = CGRect(x: 0, y: hx_height - 19, width: hx_width - 5, height: 18)
        videoIcon.hx_x = 5
        videoIcon.hx_y = hx_height - videoIcon.hx_height - 5
        assetTypeLb.hx_centerY = videoIcon.hx_centerY
    }
    
    func cancelRequest() {
        if requestID != nil {
            PHImageManager.default().cancelImageRequest(requestID!)
            requestID = nil
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            setupHighlightedMask()
        }
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutView()
    }
}

class HXPHPickerMultiSelectViewCell : HXPHPickerViewCell {
    
    weak var delegate: HXPHPickerViewCellDelegate?
    
    lazy var selectControl: HXPHPickerSelectBoxView = {
        let selectControl = HXPHPickerSelectBoxView.init()
        selectControl.backgroundColor = .clear
        selectControl.addTarget(self, action: #selector(didSelectControlClick(control:)), for: .touchUpInside)
        return selectControl
    }()
    
    override var photoAsset: HXPHAsset? {
        didSet {
            updateSelectedState(isSelected: photoAsset?.isSelected ?? false, animated: false)
        }
    }
    
    override var config: HXPHPhotoListCellConfiguration? {
        didSet {
            selectControl.config = config!.selectBox
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(selectControl)
        contentView.layer.addSublayer(disableMaskLayer)
    }
    
    /// 选择框点击事件
    /// - Parameter control: 选择框
    @objc func didSelectControlClick(control: HXPHPickerSelectBoxView) {
        delegate?.cell?(didSelectControl: self, isSelected: control.isSelected)
    }
    
    /// 更新已选状态
    /// 重写此方法时如果是自定义的选择按钮显示当前选择的下标文字，必须在此方法内更新文字内容，否则将会出现顺序显示错乱
    /// 当前选择的下标：photoAsset.selectIndex
    /// - Parameters:
    ///   - isSelected: 是否已选择
    ///   - animated: 是否需要动画效果
    func updateSelectedState(isSelected: Bool, animated: Bool) {
        let boxWidth = config!.selectBox.size.width
        let boxHeight = config!.selectBox.size.height
        if isSelected {
            selectMaskLayer.isHidden = false
            if config!.selectBox.type == .number {
                let text = String(format: "%d", arguments: [photoAsset!.selectIndex + 1])
                let font = UIFont.hx_mediumPingFang(size: config!.selectBox.titleFontSize)
                let textHeight = text.hx_stringHeight(ofFont: font, maxWidth: boxWidth)
                var textWidth = text.hx_stringWidth(ofFont: font, maxHeight: textHeight)
                selectControl.textSize = CGSize(width: textWidth, height: textHeight)
                textWidth += boxHeight * 0.5
                if textWidth < boxWidth {
                    textWidth = boxWidth
                }
                selectControl.text = text
                updateSelectControlSize(width: textWidth, height: boxHeight)
            }else {
                updateSelectControlSize(width: boxWidth, height: boxHeight)
            }
        }else {
            selectMaskLayer.isHidden = true
            updateSelectControlSize(width: boxWidth, height: boxHeight)
        }
        selectControl.isSelected = isSelected
        if animated {
            selectControl.layer.removeAnimation(forKey: "SelectControlAnimation")
            let keyAnimation = CAKeyframeAnimation.init(keyPath: "transform.scale")
            keyAnimation.duration = 0.3
            keyAnimation.values = [1.2, 0.8, 1.1, 0.9, 1.0]
            selectControl.layer.add(keyAnimation, forKey: "SelectControlAnimation")
        }
    }
    
    /// 更新选择框大小
    func updateSelectControlSize(width: CGFloat, height: CGFloat) {
        let topMargin = config?.selectBoxTopMargin ?? 5
        let rightMargin = config?.selectBoxRightMargin ?? 5
        selectControl.frame = CGRect(x: hx_width - rightMargin - width, y: topMargin, width: width, height: height)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if selectControl.hx_width != hx_width - 5 - selectControl.hx_width {
            updateSelectControlSize(width: selectControl.hx_width, height: selectControl.hx_height)
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                backgroundColor = HXPHManager.shared.isDark ? config?.backgroundDarkColor : config?.backgroundColor
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class HXPHPickerSelectBoxView: UIControl {
    var text: String = "0" {
        didSet {
            if config.type == .number {
                textLayer.string = text
            }
        }
    }
    override var isSelected: Bool {
        didSet {
            updateLayers()
        }
    }
    var textSize: CGSize = CGSize.zero
    lazy var config: HXPHSelectBoxConfiguration = {
        return HXPHSelectBoxConfiguration.init()
    }()
    lazy var backgroundLayer: CAShapeLayer = {
        let backgroundLayer = CAShapeLayer.init()
        backgroundLayer.contentsScale = UIScreen.main.scale
        return backgroundLayer
    }()
    lazy var textLayer: CATextLayer = {
        let textLayer = CATextLayer.init()
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.alignmentMode = .center
        textLayer.isWrapped = true
        return textLayer
    }()
    lazy var tickLayer: CAShapeLayer = {
        let tickLayer = CAShapeLayer.init()
        tickLayer.lineJoin = .round
        tickLayer.contentsScale = UIScreen.main.scale
        return tickLayer
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(backgroundLayer)
        layer.addSublayer(textLayer)
        layer.addSublayer(tickLayer)
    }
    
    func backgroundPath() -> CGPath {
        let strokePath = UIBezierPath.init(roundedRect: CGRect(x: 0, y: 0, width: hx_width, height: hx_height), cornerRadius: hx_height / 2)
        return strokePath.cgPath
    }
    func drawBackgroundLayer() {
        backgroundLayer.path = backgroundPath()
        if isSelected {
            backgroundLayer.fillColor = HXPHManager.shared.isDark ? config.selectedBackgroudDarkColor.cgColor : config.selectedBackgroundColor.cgColor
            backgroundLayer.lineWidth = 0
        }else {
            backgroundLayer.lineWidth = config.borderWidth
            backgroundLayer.fillColor = HXPHManager.shared.isDark ? config.darkBackgroundColor.cgColor : config.backgroundColor.cgColor
            backgroundLayer.strokeColor = HXPHManager.shared.isDark ? config.borderDarkColor.cgColor : config.borderColor.cgColor
        }
    }
    func drawTextLayer() {
        if config.type != .number {
            textLayer.isHidden = true
            return
        }
        if !isSelected {
            textLayer.string = nil
        }
        
        let font = UIFont.hx_mediumPingFang(size: config.titleFontSize)
        var textHeight: CGFloat
        var textWidth: CGFloat
        if textSize.equalTo(CGSize.zero) {
            textHeight = text.hx_stringHeight(ofFont: font, maxWidth: hx_width)
            textWidth = text.hx_stringWidth(ofFont: font, maxHeight: textHeight)
        }else {
            textHeight = textSize.height
            textWidth = textSize.width
        }
        textLayer.frame = CGRect(x: (hx_width - textWidth) * 0.5, y: (hx_height - textHeight) * 0.5, width: textWidth, height: textHeight)
        textLayer.font = CGFont.init(font.fontName as CFString)
        textLayer.fontSize = config.titleFontSize
        textLayer.foregroundColor = HXPHManager.shared.isDark ? config.titleDarkColor.cgColor : config.titleColor.cgColor
    }
    
    func tickPath() -> CGPath {
        let tickPath = UIBezierPath.init()
        tickPath.move(to: CGPoint(x: scale(8), y: hx_height * 0.5 + scale(1)))
        tickPath.addLine(to: CGPoint(x: hx_width * 0.5 - scale(2), y: hx_height - scale(8)))
        tickPath.addLine(to: CGPoint(x: hx_width - scale(7), y: scale(9)))
        return tickPath.cgPath
    }
    func drawTickLayer() {
        if config.type != .tick {
            tickLayer.isHidden = true
            return
        }
        tickLayer.isHidden = !isSelected
        tickLayer.path = tickPath()
        tickLayer.lineWidth = config.tickWidth
        tickLayer.strokeColor = HXPHManager.shared.isDark ? config.tickDarkColor.cgColor : config.tickColor.cgColor
        tickLayer.fillColor = UIColor.clear.cgColor
    }
    
    func updateLayers() {
        backgroundLayer.frame = bounds
        if config.type == .tick {
            tickLayer.frame = bounds
        }
        drawBackgroundLayer()
        drawTextLayer()
        drawTickLayer()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func scale(_ numerator: CGFloat) -> CGFloat {
        return numerator / 30 * hx_height
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if CGRect(x: -15, y: -15, width: hx_width + 30, height: hx_height + 30).contains(point) {
            return self
        }
        return super.hitTest(point, with: event)
    }
}
class HXPHPickerCamerViewCell: UICollectionViewCell {
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    var previewLayer: AVCaptureVideoPreviewLayer?
    var startSeesionCompletion: Bool = false
    lazy var imageView: UIImageView = {
        let imageView = UIImageView.init()
        return imageView
    }()
    
    var config: HXPHPhotoListCameraCellConfiguration? {
        didSet {
            configProperty()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        previewLayer = layer as? AVCaptureVideoPreviewLayer
        previewLayer?.videoGravity = .resizeAspectFill
        contentView.addSubview(imageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func configProperty() {
        imageView.image = UIImage.hx_named(named: HXPHManager.shared.isDark ? config?.cameraDarkImageName : config?.cameraImageName)
        backgroundColor = HXPHManager.shared.isDark ? config?.backgroundDarkColor : config?.backgroundColor
        imageView.hx_size = imageView.image?.size ?? .zero
        if let allowPreview = config?.allowPreview, allowPreview == true {
            requestCameraAccess()
        }
    }
    func requestCameraAccess() {
        if startSeesionCompletion {
            return
        }
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
//            HXPHProgressHUD.showWarningHUD(addedTo: hx_viewController()?.view, text: "相机不可用!".hx_localized, animated: true, delay: 1.5)
            return
        }
        HXPHAssetManager.requestCameraAccess { (granted) in
            if granted {
                self.startSeesion()
            }else {
                HXPHTools.showNotCameraAuthorizedAlert(viewController: self.hx_viewController())
            }
        }
    }
    func startSeesion() {
        self.startSeesionCompletion = true
        DispatchQueue.global().async {
            let session = AVCaptureSession.init()
            session.beginConfiguration()
            if session.canSetSessionPreset(AVCaptureSession.Preset.high) {
                session.sessionPreset = .high
            }
            if let videoDevice = AVCaptureDevice.default(for: .video) {
                do {
                    let videoInput = try AVCaptureDeviceInput.init(device: videoDevice)
                    session.addInput(videoInput)
                    session.commitConfiguration()
                    session.startRunning()
                    self.previewLayer?.session = session
                }catch {}
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.center = CGPoint(x: hx_width * 0.5, y: hx_height * 0.5)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                configProperty()
            }
        }
    }
}
