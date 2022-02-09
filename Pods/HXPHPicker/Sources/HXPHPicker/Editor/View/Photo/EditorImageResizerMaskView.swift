//
//  EditorImageResizerMaskView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/3/20.
//

import UIKit

public class EditorImageResizerMaskView: UIView {
    
    lazy var visualEffectView: UIVisualEffectView = {
        let visualEffect = UIBlurEffect(style: maskType == .darkBlurEffect ? .dark : .light)
        let view = UIVisualEffectView(effect: visualEffect)
        view.isUserInteractionEnabled = false
        return view
    }()
    
    lazy var blackMaskView: UIView = {
        let view = UIView()
        view.isHidden = true
        view.alpha = 0
        view.isUserInteractionEnabled = false
        view.backgroundColor = .black
        return view
    }()
    
    lazy var maskLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.contentsScale = UIScreen.main.scale
        return layer
    }()
    
    lazy var frameLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.strokeColor = UIColor.white.cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.lineWidth = 1.2
        layer.shadowOffset = CGSize(width: -1, height: 1)
        layer.contentsScale = UIScreen.main.scale
        layer.shouldRasterize = true
        layer.rasterizationScale = layer.contentsScale
        layer.shadowOpacity = 0.5
        return layer
    }()
    
    lazy var dotsLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.strokeColor = UIColor.white.cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.lineWidth = 3.5
        layer.contentsScale = UIScreen.main.scale
        return layer
    }()
    
    lazy var gridlinesLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.strokeColor = UIColor.white.withAlphaComponent(0.7).cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.lineWidth = 0.5
        layer.shadowOffset = CGSize(width: -1, height: 1)
        layer.contentsScale = UIScreen.main.scale
        layer.shouldRasterize = true
        layer.rasterizationScale = layer.contentsScale
        layer.shadowOpacity = 0.5
        layer.isHidden = true
        return layer
    }()
    /// 圆形裁剪框
    var isRoundCrop: Bool = false
    var animationDuration: TimeInterval = 0.3
    let isMask: Bool
    let maskType: MaskType
    
    var isCropTime: Bool = false {
        didSet {
            backgroundColor = .black.withAlphaComponent(isCropTime ? 1 : 0.6)
            visualEffectView.isHidden = isCropTime
        }
    }
    
    init(isMask: Bool, maskType: MaskType = .blackColor) {
        self.isMask = isMask
        self.maskType = maskType
        super.init(frame: .zero)
        if isMask {
            if maskType == .blackColor {
                backgroundColor = .black.withAlphaComponent(0.6)
            }else {
                addSubview(visualEffectView)
            }
            layer.mask = maskLayer
        }else {
            layer.addSublayer(frameLayer)
            layer.addSublayer(gridlinesLayer)
            layer.addSublayer(dotsLayer)
        }
        addSubview(blackMaskView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func updateBlackMask(isShow: Bool, animated: Bool, completion: (() -> Void)? = nil) {
        if animated {
            if isShow {
                blackMaskView.isHidden = false
            }
            UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseOut) {
                self.blackMaskView.alpha = isShow ? 1 : 0
            } completion: { (_) in
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
    func updateLayers(_ rect: CGRect, _ animated: Bool) {
        if isMask {
            let maskPath = UIBezierPath.init(rect: bounds)
            if isRoundCrop {
                maskPath.append(UIBezierPath(roundedRect: rect, cornerRadius: rect.width * 0.5).reversing())
            }else {
                maskPath.append(UIBezierPath.init(rect: rect).reversing())
            }
            if animated {
                let maskAnimation = PhotoTools.getBasicAnimation(
                    "path",
                    maskLayer.path,
                    maskPath.cgPath,
                    animationDuration,
                    .easeOut
                )
                maskLayer.add(maskAnimation, forKey: nil)
            }
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            maskLayer.path = maskPath.cgPath
            CATransaction.commit()
        }else {
            var framePath: UIBezierPath
            let frameRect = CGRect(
                x: rect.minX - frameLayer.lineWidth * 0.5,
                y: rect.minY - frameLayer.lineWidth * 0.5,
                width: rect.width + frameLayer.lineWidth,
                height: rect.height + frameLayer.lineWidth
            )
            if !isRoundCrop {
                framePath = UIBezierPath.init(rect: frameRect)
            }else {
                framePath = UIBezierPath.init(roundedRect: frameRect, cornerRadius: frameRect.width * 0.5)
            }
            let gridlinePath = getGridlinePath(rect)
            let dotsPath = getDotsPath(
                CGRect(
                    x: rect.minX - frameLayer.lineWidth,
                    y: rect.minY - frameLayer.lineWidth,
                    width: rect.width + frameLayer.lineWidth * 2,
                    height: rect.height + frameLayer.lineWidth * 2
                )
            )
            if animated {
                let frameAnimation = PhotoTools.getBasicAnimation(
                    "path",
                    frameLayer.path,
                    framePath.cgPath,
                    animationDuration,
                    .easeOut
                )
                frameLayer.add(frameAnimation, forKey: nil)
                if !isRoundCrop {
                    let gridlinesAnimation = PhotoTools.getBasicAnimation(
                        "path",
                        gridlinesLayer.path,
                        gridlinePath.cgPath,
                        animationDuration,
                        .easeOut
                    )
                    gridlinesLayer.add(gridlinesAnimation, forKey: nil)
                    let dotsAnimation = PhotoTools.getBasicAnimation(
                        "path",
                        dotsLayer.path,
                        dotsPath.cgPath, animationDuration,
                        .easeOut
                    )
                    dotsLayer.add(dotsAnimation, forKey: nil)
                }
            }
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            frameLayer.path = framePath.cgPath
            if !isRoundCrop {
                gridlinesLayer.path = gridlinePath.cgPath
                dotsLayer.path = dotsPath.cgPath
            }
            CATransaction.commit()
        }
    }
    func showShadow(_ isShow: Bool) {
        frameLayer.isHidden = !isShow
    }
    
    func showGridlinesLayer(_ isShow: Bool) {
        if isRoundCrop {
            return
        }
        gridlinesLayer.isHidden = !isShow
    }
    
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
        return path
    }
    
    func getGridlinePath(
        _ rect: CGRect
    ) -> UIBezierPath {
        let gridCount: Int = 3
        let horSpace = rect.width / CGFloat(gridCount)
        let verSpace = rect.height / CGFloat(gridCount)
        
        let path = UIBezierPath.init()
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
    public override func layoutSubviews() {
        super.layoutSubviews()
        visualEffectView.frame = bounds
        blackMaskView.frame = bounds
    }
}
