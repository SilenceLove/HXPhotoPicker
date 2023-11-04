//
//  ProgressIndefiniteView.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/9/5.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit

class ProgressIndefiniteView: UIView {
    var circleLayer: CAShapeLayer!
    private var maskLayer: CALayer!
    private var circlePath: CGPath!
    private let lineWidth: CGFloat
    
    var isAnimating: Bool = false
    var progress: CGFloat = 0 {
        didSet {
            let path: UIBezierPath = .init(
                arcCenter: CGPoint(x: width * 0.5, y: height * 0.5),
                radius: width * 0.5 - lineWidth * 0.5,
                startAngle: -CGFloat.pi * 0.5,
                endAngle: -CGFloat.pi * 0.5 + CGFloat.pi * 2 * progress,
                clockwise: true
            )
            circleLayer.path = path.cgPath
        }
    }
    
    init(frame: CGRect, lineWidth: CGFloat = 5) {
        self.lineWidth = lineWidth
        super.init(frame: frame)
        initViews()
    }
    
    private func initViews() {
        circlePath = UIBezierPath(
            arcCenter: CGPoint(x: width * 0.5, y: height * 0.5),
            radius: width * 0.5 - lineWidth * 0.5,
            startAngle: -CGFloat.pi * 0.5,
            endAngle: -CGFloat.pi * 0.5 + CGFloat.pi * 4,
            clockwise: true
        ).cgPath
        
        circleLayer = CAShapeLayer()
        circleLayer.frame = bounds
        circleLayer.contentsScale = UIScreen._scale
        circleLayer.strokeColor = UIColor.white.cgColor
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.lineCap = .round
        circleLayer.lineJoin = .bevel
        circleLayer.lineWidth = lineWidth
        let path: UIBezierPath = .init(
            arcCenter: CGPoint(x: width * 0.5, y: height * 0.5),
            radius: width * 0.5 - lineWidth * 0.5,
            startAngle: -CGFloat.pi * 0.5,
            endAngle: -CGFloat.pi * 0.5 + CGFloat.pi * 4,
            clockwise: true
        )
        circleLayer.path = path.cgPath
        
        maskLayer = CALayer()
        maskLayer.contentsScale = UIScreen._scale
        maskLayer.frame = bounds
        let topLayer: CAGradientLayer = .init()
        topLayer.frame = CGRect(x: width * 0.5, y: 0, width: width * 0.5, height: height)
        topLayer.colors = [
            UIColor.white.withAlphaComponent(0.8).cgColor,
            UIColor.white.withAlphaComponent(0.4).cgColor
        ]
        topLayer.startPoint = CGPoint(x: 0, y: 0)
        topLayer.endPoint = CGPoint(x: 0, y: 1)
        maskLayer.addSublayer(topLayer)
        let bottomLayer: CAGradientLayer = .init()
        bottomLayer.frame = CGRect(x: 0, y: 0, width: width * 0.5, height: height)
        bottomLayer.colors = [
            UIColor.white.withAlphaComponent(0.4).cgColor,
            UIColor.white.withAlphaComponent(0).cgColor
        ]
        bottomLayer.startPoint = CGPoint(x: 0, y: 1)
        bottomLayer.endPoint = CGPoint(x: 0, y: 0)
        maskLayer.addSublayer(bottomLayer)
        
        circleLayer.mask = maskLayer
    }
    
    func startAnimating() {
        if isAnimating { return }
        isAnimating = true
        circleLayer.removeAllAnimations()
        maskLayer.removeAllAnimations()
        
        let duration: CFTimeInterval = 0.4
        let animation: CABasicAnimation = .init(keyPath: "transform.rotation")
        animation.fromValue = 0
        animation.toValue = CGFloat.pi * 2
        animation.duration = duration
        animation.repeatCount = MAXFLOAT
        animation.isRemovedOnCompletion = false
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        circleLayer.mask?.add(animation, forKey: nil)

        let animationGroup: CAAnimationGroup = .init()
        animationGroup.duration = duration
        animationGroup.repeatCount = MAXFLOAT
        animationGroup.isRemovedOnCompletion = false
        animationGroup.timingFunction = CAMediaTimingFunction(name: .linear)

        let strokeStartAnimation: CABasicAnimation = .init(keyPath: "strokeStart")
        strokeStartAnimation.fromValue = 0.015
        strokeStartAnimation.toValue = 0.515

        let strokeEndAnimation: CABasicAnimation = .init(keyPath: "strokeEnd")
        strokeEndAnimation.fromValue = 0.485
        strokeEndAnimation.toValue = 0.985

        animationGroup.animations = [strokeStartAnimation, strokeEndAnimation]
        circleLayer.add(animationGroup, forKey: nil)
    }
    
    func stopAnimating() {
        if !isAnimating { return }
        maskLayer.removeAllAnimations()
        circleLayer.removeAllAnimations()
        isAnimating = false
    }
    
    func resetMask() {
        if circleLayer.path != circlePath {
            circleLayer.path = circlePath
        }
        if circleLayer.mask == nil {
            circleLayer.mask = maskLayer
        }
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if newSuperview != nil {
            layer.addSublayer(circleLayer)
        }else {
            circleLayer.removeFromSuperlayer()
            stopAnimating()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
