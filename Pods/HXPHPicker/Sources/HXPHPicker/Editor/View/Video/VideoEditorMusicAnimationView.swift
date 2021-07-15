//
//  VideoEditorMusicAnimationView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/6/30.
//

import UIKit

class VideoEditorMusicAnimationView: UIView {
    var animationLayers: [CAShapeLayer] = []
    var isAnimatoning: Bool = false
    init() {
        super.init(frame: .zero)
        for _ in 0..<12 {
            let shapeLayer = CAShapeLayer()
            shapeLayer.fillColor = UIColor.clear.cgColor
            shapeLayer.strokeColor = "#333333".color.cgColor
            shapeLayer.lineWidth = 1
            layer.addSublayer(shapeLayer)
            animationLayers.append(shapeLayer)
        }
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        for shapeLayer in animationLayers {
            shapeLayer.frame = bounds
        }
        updatePath()
    }
    func updatePath() {
        let pillarWidth: CGFloat = 1
        let pillarHeighs: [CGFloat] = [4, 8, 12, 8, 6, 4, 7, 12, 8, 10, 6, 4]
        for (index, shapeLayer) in animationLayers.enumerated() {
            let pillarHeigh = pillarHeighs[index]
            let pillarX: CGFloat = (pillarWidth + 2) * CGFloat(index)
            let startY: CGFloat = (height - pillarHeigh) * 0.5
            let startPoint = CGPoint(x: pillarX, y: startY)
            let endPoint = CGPoint(x: pillarX, y: startY + pillarHeigh)
            let path = UIBezierPath()
            path.move(to: startPoint)
            path.addLine(to: endPoint)
            shapeLayer.path = path.cgPath
        }
        if isAnimatoning {
            startAnimation()
        }
    }
    func startAnimation() {
        isAnimatoning = true
        for shapeLayer in animationLayers {
            shapeLayer.removeAllAnimations()
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
            shapeLayer.add(animation, forKey: nil)
        }
    }
    func stopAnimation() {
        isAnimatoning = false
        for shapeLayer in animationLayers {
            shapeLayer.removeAllAnimations()
        }
    }
}
