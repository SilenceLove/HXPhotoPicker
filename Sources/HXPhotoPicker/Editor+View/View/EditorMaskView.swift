//
//  EditorMaskView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2022/11/13.
//

import UIKit

class EditorMaskView: UIView {
    
    private var customMaskView: UIView!
    private var maskImageView: UIImageView!
    private var customMaskEffectView: UIVisualEffectView!
    private var customMaskEffect: UIVisualEffect?
    private var visualEffect: UIVisualEffect?
    private var visualEffectView: UIVisualEffectView!
    private var blackMaskView: UIView!
    private var maskLayer: CAShapeLayer!
    private var frameLayer: CAShapeLayer!
    private var dotsLayer: CAShapeLayer!
    private var sizeLb: UILabel!
    private var frameView: UIView!
    private var gridlinesLayer: CAShapeLayer!
    private var gridGraylinesLayer: CAShapeLayer!
    
    var gridlinesView: UIView!
    var gridGraylinesView: UIView!
    
    var imageSize: CGSize = .zero {
        didSet {
            sizeLb.text = "\(Int(max(1, round(imageSize.width))))x\(Int(max(1, round(imageSize.height))))"
        }
    }
    
    /// 圆形裁剪框
    var isRoundCrop: Bool = false
    var animationDuration: TimeInterval = 0.3
    var type: `Type`
    var isShowScaleSize: Bool {
        get {
            !sizeLb.isHidden
        }
        set {
            sizeLb.isHidden = !newValue
        }
    }
    
    var maskType: EditorView.MaskType = {
        if #available(iOS 13.0, *) {
            return .blurEffect(style: .systemThickMaterialDark)
        } else {
            return .blurEffect(style: .dark)
        }
    }() {
        didSet {
            switch type {
            case .mask:
                switch maskType {
                case .customColor(let color):
                    backgroundColor = color
                    visualEffectView.effect = nil
                    visualEffect = nil
                case .blurEffect(let style):
                    backgroundColor = .clear
                    let visualEffect = UIBlurEffect(style: style)
                    visualEffectView.effect = visualEffect
                    self.visualEffect = visualEffect
                }
            case .customMask:
                switch maskType {
                case .customColor(let color):
                    customMaskView.backgroundColor = color
                    customMaskEffectView.effect = nil
                    customMaskEffect = nil
                case .blurEffect(let style):
                    customMaskView.backgroundColor = .clear
                    let visualEffect = UIBlurEffect(style: style)
                    customMaskEffectView.effect = visualEffect
                    self.customMaskEffect = visualEffect
                }
            default:
                break
            }
        }
    }
    
    func setMaskType(_ maskType: EditorView.MaskType, animated: Bool) {
        if animated {
            UIView.animate {
                self.maskType = maskType
            }
        }else {
            self.maskType = maskType
        }
    }
    
    var isCropTime: Bool = false {
        didSet {
            backgroundColor = .black.withAlphaComponent(isCropTime ? 1 : 0.6)
            visualEffectView.isHidden = isCropTime
        }
    }
    
    var maskInsets: UIEdgeInsets = .zero
    var maskImage: UIImage?
    var tmpMaskImage: UIImage?
    
    func setMaskImage(_ image: UIImage?, animated: Bool, completion: (() -> Void)? = nil) {
        maskImageView.frame = maskRect
        customMaskEffectView.frame = maskRect
        tmpMaskImage = image
        if animated {
            if image != nil {
                maskImage = image
                maskImageView.image = image
            }
            UIView.animate {
                self.customMaskView.alpha = image == nil ? 0 : 1
            } completion: {
                if !$0 { return }
                if image == nil {
                    self.maskImage = image
                    self.maskImageView.image = image
                }
                completion?()
            }
        }else {
            maskImage = image
            maskImageView.image = image
            customMaskView.alpha = image == nil ? 0 : 1
            completion?()
        }
    }
    
    var maskColor: UIColor? {
        didSet {
            switch type {
            case .mask:
                blackMaskView.backgroundColor = maskColor
            default:
                break
            }
        }
    }
    
    init(type: `Type`, maskColor: UIColor? = nil, maskImage: UIImage? = nil) {
        self.type = type
        self.maskColor = maskColor
        self.maskImage = maskImage
        super.init(frame: .zero)
        switch type {
        case .frame:
            initFrameView()
            initLineLayers()
            addSubview(frameView)
            addSubview(gridGraylinesView)
            addSubview(gridlinesView)
        case .mask:
            initBlackMaskView()
            initEffectViews()
            switch maskType {
            case .customColor(let color):
                backgroundColor = color
                visualEffectView.effect = nil
            case .blurEffect:
                break
            }
            addSubview(visualEffectView)
            maskLayer = CAShapeLayer()
            maskLayer.contentsScale = UIScreen._scale
            layer.mask = maskLayer
            addSubview(blackMaskView)
        case .customMask:
            initCustomEffectViews()
            addSubview(customMaskView)
        }
    }
    
    private func initFrameView() {
        dotsLayer = CAShapeLayer()
        dotsLayer.strokeColor = UIColor.white.cgColor
        dotsLayer.fillColor = UIColor.clear.cgColor
        dotsLayer.lineWidth = 3.5
        dotsLayer.contentsScale = UIScreen._scale
        
        frameLayer = CAShapeLayer()
        frameLayer.strokeColor = UIColor.white.cgColor
        frameLayer.fillColor = UIColor.clear.cgColor
        frameLayer.lineWidth = 1.2
//        frameLayer.shadowOffset = CGSize(width: -1, height: 1)
        frameLayer.contentsScale = UIScreen._scale
//        frameLayer.shouldRasterize = true
        frameLayer.rasterizationScale = layer.contentsScale
//        frameLayer.shadowOpacity = 0.5
        
        frameView = UIView()
        frameView.isUserInteractionEnabled = false
        frameView.layer.addSublayer(frameLayer)
        frameView.layer.addSublayer(dotsLayer)
    }
    
    private func initLineLayers() {
        
        gridlinesLayer = CAShapeLayer()
        gridlinesLayer.strokeColor = UIColor.white.cgColor
        gridlinesLayer.fillColor = UIColor.clear.cgColor
        gridlinesLayer.lineWidth = 0.5
//        gridlinesLayer.shadowOffset = CGSize(width: -1, height: 1)
        gridlinesLayer.contentsScale = UIScreen._scale
//        gridlinesLayer.shouldRasterize = true
        gridlinesLayer.rasterizationScale = layer.contentsScale
//        gridlinesLayer.shadowOpacity = 0.5
        
        sizeLb = UILabel()
        sizeLb.font = .semiboldPingFang(ofSize: UIDevice.isPad ? 18 : 15)
        sizeLb.textColor = .white
        sizeLb.textAlignment = .center
        sizeLb.isHighlighted = true
        sizeLb.highlightedTextColor = .white
        sizeLb.layer.shadowColor = UIColor.black.cgColor
        sizeLb.layer.shadowOpacity = 1
        sizeLb.layer.shadowRadius = 8
        sizeLb.layer.shouldRasterize = true
        sizeLb.layer.shadowOffset = CGSize(width: 0, height: 0)
        sizeLb.adjustsFontSizeToFitWidth = true
        
        gridlinesView = UIView()
        gridlinesView.alpha = 0
        gridlinesView.isUserInteractionEnabled = false
        gridlinesView.layer.addSublayer(gridlinesLayer)
        gridlinesView.addSubview(sizeLb)
        
        gridGraylinesLayer = CAShapeLayer()
        gridGraylinesLayer.strokeColor = UIColor.gray.withAlphaComponent(0.75).cgColor
        gridGraylinesLayer.fillColor = UIColor.clear.cgColor
        gridGraylinesLayer.lineWidth = 0.5
        gridGraylinesLayer.contentsScale = UIScreen._scale
//        gridGraylinesLayer.shouldRasterize = true
        gridGraylinesLayer.rasterizationScale = layer.contentsScale
        
        gridGraylinesView = UIView()
        gridGraylinesView.alpha = 0
        gridGraylinesView.isUserInteractionEnabled = false
        gridGraylinesView.layer.addSublayer(gridGraylinesLayer)
    }
    
    private func initBlackMaskView() {
        blackMaskView = UIView()
        blackMaskView.isHidden = true
        blackMaskView.alpha = 0
        blackMaskView.isUserInteractionEnabled = false
        blackMaskView.backgroundColor = maskColor
    }
    private func initEffectViews() {
        let style: UIBlurEffect.Style
        switch maskType {
        case .blurEffect(let _style):
            style = _style
        default:
            style = .light
        }
        let visualEffect = UIBlurEffect(style: style)
        visualEffectView = UIVisualEffectView(effect: visualEffect)
        self.visualEffect = visualEffect
        visualEffectView.isUserInteractionEnabled = false
    }
    
    private func initCustomEffectViews() {
        maskImageView = UIImageView(image: maskImage)
        
        let style: UIBlurEffect.Style
        switch maskType {
        case .blurEffect(let _style):
            style = _style
        default:
            style = .light
        }
        let visualEffect = UIBlurEffect(style: style)
        
        customMaskEffectView = UIVisualEffectView(effect: visualEffect)
        customMaskEffectView.isUserInteractionEnabled = false
        
        customMaskView = UIView()
        customMaskView.alpha = 0
        customMaskView.isUserInteractionEnabled = false
        switch maskType {
        case .customColor(let color):
            customMaskView.backgroundColor = color
            customMaskEffectView.effect = nil
        case .blurEffect:
            self.customMaskEffect = visualEffect
        }
        customMaskView.addSubview(customMaskEffectView)
        customMaskView.mask = maskImageView
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var maskViewIsHidden = false
    
    func updateBlackMask(isShow: Bool, animated: Bool, completion: (() -> Void)? = nil) {
        if animated {
            if isShow {
                blackMaskView.isHidden = false
            }
            UIView.animate {
                self.blackMaskView.alpha = isShow ? 1 : 0
            } completion: {
                if !$0 { return }
                if !isShow {
                    self.blackMaskView.isHidden = true
                }
                completion?()
            }
        }else {
            blackMaskView.alpha = isShow ? 1 : 0
            blackMaskView.isHidden = !isShow
            completion?()
        }
    }
    
    var maskRect: CGRect = .zero
    var layersRect: CGRect = .zero
    
    func updateLayers(_ rect: CGRect, _ animated: Bool) {
        layersRect = rect
        switch type {
        case .frame:
            updateFrameLayer(rect, animated)
        case .mask:
            let maskPath = UIBezierPath(rect: bounds)
            let maskRect = CGRect(
                x: rect.minX + maskInsets.left,
                y: rect.minY + maskInsets.top,
                width: rect.width, height: rect.height
            )
            maskPath.append(UIBezierPath(
                roundedRect: maskRect,
                cornerRadius: isRoundCrop ? min(rect.width, rect.height) * 0.5 : 0.1
            ).reversing())
            if animated {
                maskLayer.removeAnimation(forKey: "maskAnimation")
                let maskAnimation = PhotoTools.getBasicAnimation(
                    "path",
                    maskLayer.path,
                    maskPath.cgPath
                )
                maskLayer.add(maskAnimation, forKey: "maskAnimation")
            }
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            maskLayer.path = maskPath.cgPath
            CATransaction.commit()
        case .customMask:
            let maskRect = CGRect(
                x: rect.minX + maskInsets.left,
                y: rect.minY + maskInsets.top,
                width: rect.width, height: rect.height
            )
            self.maskRect = maskRect
            if animated {
                UIView.animate {
                    self.maskImageView.image = self.maskImage
                    self.maskImageView.frame = maskRect
                    self.customMaskEffectView.frame = maskRect
                }
            }else {
                maskImageView.image = maskImage
                maskImageView.frame = maskRect
                customMaskEffectView.frame = maskRect
            }
        }
    }
    
    private func updateFrameLayer(_ rect: CGRect, _ animated: Bool) {
        var framePath: UIBezierPath
        let frameRect = CGRect(
            x: rect.minX - frameLayer.lineWidth * 0.5,
            y: rect.minY - frameLayer.lineWidth * 0.5,
            width: rect.width + frameLayer.lineWidth,
            height: rect.height + frameLayer.lineWidth
        )
        framePath = UIBezierPath(
            roundedRect: frameRect,
            cornerRadius: isRoundCrop ? min(frameRect.width, frameRect.height) * 0.5 : 0.1
        )
        let gridlinePath = getGridlinePath(rect)
        let gridGraylinePath = getGridGraylinePath(rect)
        let dotsPath = getDotsPath(
            CGRect(
                x: rect.minX - frameLayer.lineWidth,
                y: rect.minY - frameLayer.lineWidth,
                width: rect.width + frameLayer.lineWidth * 2,
                height: rect.height + frameLayer.lineWidth * 2
            )
        )
        if animated {
            frameLayer.removeAnimation(forKey: "frameAnimation")
            gridGraylinesLayer.removeAnimation(forKey: "gridGraylinesAnimation")
            gridlinesLayer.removeAnimation(forKey: "gridlinesAnimation")
            dotsLayer.removeAnimation(forKey: "dotsGroupAnimation")
            dotsLayer.removeAnimation(forKey: "dotsAnimation")
            let frameAnimation = PhotoTools.getBasicAnimation(
                "path",
                frameLayer.path,
                framePath.cgPath
            )
            frameLayer.add(frameAnimation, forKey: "frameAnimation")
            let gridlinesAnimation = PhotoTools.getBasicAnimation(
                "path",
                gridlinesLayer.path,
                isRoundCrop ? nil : gridlinePath.cgPath
            )
            gridlinesLayer.add(gridlinesAnimation, forKey: "gridlinesAnimation")
            let gridGraylinesAnimation = PhotoTools.getBasicAnimation(
                "path",
                gridGraylinesLayer.path,
                isRoundCrop ? nil : gridGraylinePath.cgPath
            )
            gridGraylinesLayer.add(gridGraylinesAnimation, forKey: "gridGraylinesAnimation")
            
            let dotsAnimation = PhotoTools.getBasicAnimation(
                "path",
                dotsLayer.path,
                isRoundCrop ? nil : dotsPath.cgPath
            )
            let addDostOpactyAimation: Bool
            if isRoundCrop {
                addDostOpactyAimation = dotsLayer.opacity != 0
            }else {
                addDostOpactyAimation = dotsLayer.opacity != 1
            }
            if addDostOpactyAimation {
                let dotsOpacityAnimation = PhotoTools.getBasicAnimation(
                    "opacity",
                    dotsLayer.opacity,
                    isRoundCrop ? 0 : 1
                )
                let dotsGroupAnimation = CAAnimationGroup()
                dotsGroupAnimation.animations = [dotsAnimation, dotsOpacityAnimation]
                dotsLayer.add(dotsGroupAnimation, forKey: "dotsGroupAnimation")
            }else {
                dotsLayer.add(dotsAnimation, forKey: "dotsAnimation")
            }
            let beforCenter = sizeLb.center
            sizeLb.width = frameRect.width - 2
            sizeLb.center = beforCenter
            UIView.animate {
                self.sizeLb.center = .init(x: frameRect.midX, y: frameRect.midY)
            }
        }else {
            sizeLb.width = frameRect.width - 2
            sizeLb.height = frameRect.height
            sizeLb.center = .init(x: frameRect.midX, y: frameRect.midY)
        }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        frameLayer.path = framePath.cgPath
        if !isRoundCrop {
            gridlinesLayer.path = gridlinePath.cgPath
            gridGraylinesLayer.path = gridGraylinePath.cgPath
            dotsLayer.path = dotsPath.cgPath
            dotsLayer.opacity = 1
        }else {
            gridlinesLayer.path = nil
            gridGraylinesLayer.path = nil
            dotsLayer.path = nil
            dotsLayer.opacity = 0
        }
        CATransaction.commit()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        switch type {
        case .frame:
            frameView.frame = bounds
            frameLayer.frame = frameView.bounds
            dotsLayer.frame = frameView.bounds
            gridlinesView.frame = bounds
            gridlinesLayer.frame = gridlinesView.bounds
            gridGraylinesView.frame = bounds
            gridGraylinesLayer.frame = gridGraylinesView.bounds
        case .mask:
            visualEffectView.frame = bounds
            blackMaskView.frame = bounds
            maskLayer.frame = bounds
        case .customMask:
            customMaskView.frame = bounds
        }
    }
}

extension EditorMaskView {
    
    func show(_ animated: Bool) {
        switch type {
        case .frame:
            if animated {
                UIView.animate(withDuration: 0.2) {
                    self.frameView.alpha = 0
                }
            }else {
                self.frameView.alpha = 0
            }
        case .mask:
            showMaskView(animated)
        case .customMask:
            break
        }
    }
    
    func hide(_ animated: Bool) {
        switch type {
        case .frame:
            if animated {
                UIView.animate(withDuration: 0.2) {
                    self.frameView.alpha = 1
                }
            }else {
                self.frameView.alpha = 1
            }
        case .mask:
            hideMaskView(animated, isAll: true)
        case .customMask:
            break
        }
    }
    
    func showMaskView(_ animated: Bool = true) {
        if !maskViewIsHidden {
            return
        }
        maskViewIsHidden = false
        func animationHnadler() {
            switch type {
            case .mask:
                switch maskType {
                case .customColor(let color):
                    backgroundColor = color
                default:
                    backgroundColor = .clear
                    visualEffectView.effect = visualEffect
                }
            case .customMask:
                switch maskType {
                case .customColor(let color):
                    customMaskView.backgroundColor = color
                default:
                    customMaskView.backgroundColor = .clear
                    customMaskEffectView.effect = customMaskEffect
                }
            default:
                break
            }
        }
        if animated {
            UIView.animate {
                animationHnadler()
            }
        }else {
            animationHnadler()
        }
    }
    
    func hideMaskView(_ animated: Bool = true, isAll: Bool = false) {
        if maskViewIsHidden {
            return
        }
        maskViewIsHidden = true
        func animationHnadler() {
            switch type {
            case .mask:
                if isAll {
                    backgroundColor = .black.withAlphaComponent(0)
                }else {
                    backgroundColor = .black.withAlphaComponent(0.3)
                }
                switch maskType {
                case .customColor:
                    break
                default:
                    visualEffectView.effect = nil
                }
            case .customMask:
                customMaskView.backgroundColor = .black.withAlphaComponent(0.3)
                switch maskType {
                case .customColor:
                    break
                default:
                    customMaskEffectView.effect = nil
                }
            default:
                if isAll {
                    backgroundColor = .black.withAlphaComponent(0)
                }else {
                    backgroundColor = .black.withAlphaComponent(0.3)
                }
            }
        }
        if animated {
            UIView.animate {
                animationHnadler()
            }
        }else {
            animationHnadler()
        }
    }
    
    func showImageMaskView(_ animated: Bool) {
        func animationHandler() {
            switch maskType {
            case .customColor(let color):
                customMaskView.backgroundColor = color
            default:
                customMaskView.backgroundColor = .clear
                customMaskEffectView.effect = customMaskEffect
            }
        }
        if animated {
            UIView.animate {
                animationHandler()
            }
        }else {
            animationHandler()
        }
    }
    
    func hideImageMaskView(_ animated: Bool) {
        func animationHandler() {
            customMaskView.backgroundColor = maskColor
            switch maskType {
            case .customColor:
                break
            default:
                customMaskEffectView.effect = nil
            }
        }
        if animated {
            UIView.animate {
                animationHandler()
            }
        }else {
            animationHandler()
        }
    }
    
    func updateRoundCrop(isRound: Bool, animated: Bool) {
        if isRoundCrop == isRound {
            return
        }
        isRoundCrop = isRound
        updateLayers(layersRect, animated)
    }
    
    func setShadows(_ isShow: Bool) {
        if isShow {
            sizeLb.layer.shadowOpacity = 1
//            gridlinesLayer.shadowOpacity = 0.5
//            frameLayer.shadowOpacity = 0.5
        }else {
            sizeLb.layer.shadowOpacity = 0
//            gridlinesLayer.shadowOpacity = 0
//            frameLayer.shadowOpacity = 0
        }
    }
    
    func showGridlinesLayer(_ isShow: Bool, animated: Bool) {
        if isRoundCrop {
            if !gridlinesLayer.isHidden {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                gridlinesLayer.isHidden = true
                CATransaction.commit()
            }
        }else {
            if gridlinesLayer.isHidden {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                gridlinesLayer.isHidden = false
                CATransaction.commit()
            }
        }
        gridlinesView.layer.removeAllAnimations()
        if animated {
            UIView.animate(withDuration: animationDuration) {
                self.gridlinesView.alpha = isShow ? 1 : 0
            }
        }else {
            gridlinesView.alpha = isShow ? 1 : 0
        }
    }
    
    func showGridGraylinesView(animated: Bool) {
        if gridGraylinesView.alpha == 1 {
            return
        }
        if animated {
            UIView.animate(withDuration: animationDuration) {
                self.gridGraylinesView.alpha = 1
            }
        }else {
            gridGraylinesView.alpha = 1
        }
    }
    
    func hideGridGraylinesView(animated: Bool) {
        if gridGraylinesView.alpha == 0 {
            return
        }
        if animated {
            UIView.animate(withDuration: animationDuration) {
                self.gridGraylinesView.alpha = 0
            }
        }else {
            gridGraylinesView.alpha = 0
        }
    }
}

extension EditorMaskView {
    func getDotsPath(
        _ rect: CGRect
    ) -> UIBezierPath {
        let lineWidth: CGFloat = 20
        let path = UIBezierPath.init()
        let leftTopStartPoint = CGPoint(x: rect.minX + lineWidth, y: rect.minY)
        let leftTopMidPoint = CGPoint(x: rect.minX, y: rect.minY)
        let leftTopEndPoint = CGPoint(x: rect.minX, y: rect.minY + lineWidth)
        path.move(to: leftTopStartPoint)
        path.addLine(to: leftTopMidPoint)
        path.addLine(to: leftTopEndPoint)
        
        let leftBottomStartPoint = CGPoint(x: rect.minX + lineWidth, y: rect.maxY)
        let leftBottomMidPoint = CGPoint(x: rect.minX, y: rect.maxY)
        let leftBottomEndPoint = CGPoint(x: rect.minX, y: rect.maxY - lineWidth)
        path.move(to: leftBottomStartPoint)
        path.addLine(to: leftBottomMidPoint)
        path.addLine(to: leftBottomEndPoint)
        
        let rightTopStartPoint = CGPoint(x: rect.maxX - lineWidth, y: rect.minY)
        let rightTopMidPoint = CGPoint(x: rect.maxX, y: rect.minY)
        let rightTopEndPoint = CGPoint(x: rect.maxX, y: rect.minY + lineWidth)
        path.move(to: rightTopStartPoint)
        path.addLine(to: rightTopMidPoint)
        path.addLine(to: rightTopEndPoint)
        
        let rightBottomStartPoint = CGPoint(x: rect.maxX, y: rect.maxY - lineWidth)
        let rightBottomMidPoint = CGPoint(x: rect.maxX, y: rect.maxY)
        let rightBottomEndPoint = CGPoint(x: rect.maxX - lineWidth, y: rect.maxY)
        path.move(to: rightBottomStartPoint)
        path.addLine(to: rightBottomMidPoint)
        path.addLine(to: rightBottomEndPoint)
        
        let centerLineWidth: CGFloat = 30
        let topCenterStartPoint = CGPoint(x: rect.midX - centerLineWidth * 0.5, y: rect.minY)
        let topCenterEndPoint = CGPoint(x: rect.midX + centerLineWidth * 0.5, y: rect.minY)
        path.move(to: topCenterStartPoint)
        path.addLine(to: topCenterEndPoint)
        
        let leftCenterStartPoint = CGPoint(x: rect.minX, y: rect.midY - centerLineWidth * 0.5)
        let leftCenterEndPoint = CGPoint(x: rect.minX, y: rect.midY + centerLineWidth * 0.5)
        path.move(to: leftCenterStartPoint)
        path.addLine(to: leftCenterEndPoint)
        
        let rightCenterStartPoint = CGPoint(x: rect.maxX, y: rect.midY - centerLineWidth * 0.5)
        let rightCenterEndPoint = CGPoint(x: rect.maxX, y: rect.midY + centerLineWidth * 0.5)
        path.move(to: rightCenterStartPoint)
        path.addLine(to: rightCenterEndPoint)
        
        let bottomCenterStartPoint = CGPoint(x: rect.midX - centerLineWidth * 0.5, y: rect.maxY)
        let bottomCenterEndPoint = CGPoint(x: rect.midX + centerLineWidth * 0.5, y: rect.maxY)
        path.move(to: bottomCenterStartPoint)
        path.addLine(to: bottomCenterEndPoint)
        return path
    }
    
    func getGridlinePath(
        _ rect: CGRect
    ) -> UIBezierPath {
        let gridCount: Int = 3
        let horSpace = rect.width / CGFloat(gridCount)
        let verSpace = rect.height / CGFloat(gridCount)
        
        let path = UIBezierPath()
        for index in 1..<gridCount {
            var px = rect.minX
            var py = rect.minY + verSpace * CGFloat(index)
            path.move(to: CGPoint(x: px, y: py))
            path.addLine(to: CGPoint(x: px + rect.width, y: py))
            
            px = rect.minX + horSpace * CGFloat(index)
            py = rect.minY
            path.move(to: CGPoint(x: px, y: py))
            path.addLine(to: CGPoint(x: px, y: py + rect.height))
        }
        return path
    }
    
    func getGridGraylinePath(
        _ rect: CGRect
    ) -> UIBezierPath {
        let gridCount: Int = 9
        let horSpace = rect.width / CGFloat(gridCount)
        let verSpace = rect.height / CGFloat(gridCount)
        let path = UIBezierPath()
        for index in 1..<gridCount {
            if CGFloat(index).truncatingRemainder(dividingBy: 3) == 0 {
                continue
            }
            var px = rect.minX
            var py = rect.minY + verSpace * CGFloat(index)
            path.move(to: CGPoint(x: px, y: py))
            path.addLine(to: CGPoint(x: px + rect.width, y: py))
            
            px = rect.minX + horSpace * CGFloat(index)
            py = rect.minY
            path.move(to: CGPoint(x: px, y: py))
            path.addLine(to: CGPoint(x: px, y: py + rect.height))
        }
        return path
    }
    
}
