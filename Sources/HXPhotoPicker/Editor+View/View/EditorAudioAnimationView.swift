//
//  EditorAudioAnimationView.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/20.
//

import UIKit
import AVFoundation

public class EditorAudioAnimationLayer: CALayer {
    var animationLayers: [CAShapeLayer] = []
    var isAnimatoning: Bool = false
    let scale: CGFloat
    var animationBeginTime: CFTimeInterval = AVCoreAnimationBeginTimeAtZero
    
    override init(layer: Any) {
        self.scale = 1
        super.init(layer: layer)
    }
    
    public init(
        hexColor: String = "#333333",
        scale: CGFloat = 1
    ) {
        self.scale = scale
        super.init()
        contentsScale = UIScreen._scale
        for _ in 0..<12 {
            let shapeLayer = CAShapeLayer()
            shapeLayer.contentsScale = UIScreen._scale
            shapeLayer.fillColor = UIColor.clear.cgColor
            shapeLayer.strokeColor = hexColor.color.cgColor
            shapeLayer.lineWidth = 1 * scale
            shapeLayer.shadowOpacity = 0.4
            shapeLayer.shadowOffset = CGSize(width: 0, height: -1)
            shapeLayer.shouldRasterize = true
            shapeLayer.rasterizationScale = shapeLayer.contentsScale
            addSublayer(shapeLayer)
            animationLayers.append(shapeLayer)
        }
    }
    public func changeColor(hex: String) {
        for shapeLayer in animationLayers {
            shapeLayer.strokeColor = hex.color.cgColor
        }
    }
    public override func layoutSublayers() {
        super.layoutSublayers()
        for shapeLayer in animationLayers {
            shapeLayer.frame = bounds
        }
        updatePath(true)
    }
    func updatePath(_ skip: Bool = false) {
        let pillarWidth: CGFloat = 1 * scale
        let pillarHeighs: [CGFloat] = [4, 8, 12, 8, 6, 4, 7, 12, 8, 10, 6, 4]
        for (index, shapeLayer) in animationLayers.enumerated() {
            let pillarHeigh = pillarHeighs[index] * scale
            let pillarX: CGFloat = (pillarWidth + 2 * scale) * CGFloat(index)
            let startY: CGFloat = (frame.height - pillarHeigh) * 0.5
            let startPoint = CGPoint(x: pillarX, y: startY)
            let endPoint = CGPoint(x: pillarX, y: startY + pillarHeigh)
            let path = UIBezierPath()
            path.move(to: startPoint)
            path.addLine(to: endPoint)
            shapeLayer.path = path.cgPath
        }
        if isAnimatoning {
            startAnimation(skip)
        }
    }
    public func startAnimation(_ skip: Bool = false) {
        if isAnimatoning && !skip {
            return
        }
        isAnimatoning = true
        for shapeLayer in animationLayers {
            shapeLayer.removeAnimation(forKey: "scale_animation")
        }
        let values = [[1, 0.2, 0.8, 0.4, 0.6, 0.2, 1],
                      [1, 0.2, 0.9, 0.3, 0.8, 1, 0.2, 1],
                      [1, 0.2, 1, 0.6, 0.8, 0.7, 1, 0.2, 1],
                      [1, 0.2, 0.9, 0.3, 0.8, 1, 0.2, 1],
                      [0.2, 1, 0.3, 0.9, 0.2, 0.3, 1, 0.2],
                      [1, 0.2, 0.8, 0.4, 0.6, 0.2, 1],
                      [1, 0.2, 0.8, 0.4, 0.6, 0.2, 1],
                      [1, 0.2, 0.8, 0.4, 0.9, 0.3, 0.7, 1],
                      [1, 0.2, 1, 0.8, 1, 0.9, 1, 0.2, 1],
                      [0.2, 1, 0.3, 0.9, 0.2, 0.3, 1, 0.2],
                      [0.2, 1, 0.3, 0.9, 0.2, 0.3, 1, 0.2],
                      [1, 0.2, 0.3, 0.2, 0.3, 0.2, 1]]
        let durations = [1, 1.2, 1.6, 1.4, 1, 1.2, 1.3, 1.6, 1.4, 1.2, 1, 1.5]
        for (index, shapeLayer) in animationLayers.enumerated() {
            let animation = CAKeyframeAnimation(keyPath: "transform.scale.y")
            animation.values = values[index]
            animation.duration = durations[index]
            animation.repeatCount = MAXFLOAT
            animation.isRemovedOnCompletion = false
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            animation.beginTime = animationBeginTime
            shapeLayer.add(animation, forKey: "scale_animation")
        }
    }
    public func stopAnimation() {
        isAnimatoning = false
        for shapeLayer in animationLayers {
            shapeLayer.removeAnimation(forKey: "scale_animation")
        }
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public class EditorAudioAnimationView: UIView {
    private var animationLayer: EditorAudioAnimationLayer!
    private let hexColor: String
    public init(hexColor: String = "#333333") {
        self.hexColor = hexColor
        super.init(frame: .zero)
        animationLayer = EditorAudioAnimationLayer(hexColor: hexColor)
        layer.addSublayer(animationLayer)
    }
    public func changeColor(hex: String) {
        animationLayer.changeColor(hex: hex)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public override func layoutSubviews() {
        super.layoutSubviews()
        if !animationLayer.frame.equalTo(bounds) {
            animationLayer.frame = bounds
        }
    }
     
    public func startAnimation() {
        animationLayer.startAnimation()
    }
    public func stopAnimation() {
        animationLayer.stopAnimation()
    }
}
