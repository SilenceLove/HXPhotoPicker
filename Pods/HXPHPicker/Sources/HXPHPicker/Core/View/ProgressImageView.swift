//
//  ProgressImageView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/3/12.
//

import UIKit

final class ProgressImageView: UIView {
    
    lazy var circleLayer: CAShapeLayer = {
        let circleLayer = CAShapeLayer.init()
        circleLayer.contentsScale = UIScreen.main.scale
        return circleLayer
    }()
    
    lazy var lineLayer: CAShapeLayer = {
        let lineLayer = CAShapeLayer.init()
        lineLayer.contentsScale = UIScreen.main.scale
        return lineLayer
    }()
    
    lazy var pointLayer: CAShapeLayer = {
        let pointLayer = CAShapeLayer.init()
        pointLayer.contentsScale = UIScreen.main.scale
        return pointLayer
    }()
    
    lazy var tickLayer: CAShapeLayer = {
        let tickLayer = CAShapeLayer.init()
        tickLayer.contentsScale = UIScreen.main.scale
        return tickLayer
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(circleLayer)
        layer.addSublayer(lineLayer)
        layer.addSublayer(pointLayer)
        drawCircle()
        drawExclamationPoint()
    }
    init(tickFrame: CGRect) {
        super.init(frame: tickFrame)
        layer.addSublayer(tickLayer)
        drawTickLayer()
    }
    func startAnimation() {
    }
    private func drawCircle() {
        let circlePath = UIBezierPath.init()
        circlePath.addArc(
            withCenter: CGPoint(
                x: width * 0.5,
                y: height * 0.5
            ),
            radius: width * 0.5,
            startAngle: 0,
            endAngle: 2 * .pi,
            clockwise: true
        )
        circleLayer.path = circlePath.cgPath
        circleLayer.lineWidth = 1.5
        circleLayer.strokeColor = UIColor.white.cgColor
        circleLayer.fillColor = UIColor.clear.cgColor
        
//        let circleAimation = CABasicAnimation.init(keyPath: "strokeEnd")
//        circleAimation.fromValue = 0
//        circleAimation.toValue = 1
//        circleAimation.duration = 0.5
//        circleLayer.add(circleAimation, forKey: "")
    }
    
    private func drawExclamationPoint() {
        let linePath = UIBezierPath.init()
        linePath.move(to: CGPoint(x: width * 0.5, y: 15))
        linePath.addLine(to: CGPoint(x: width * 0.5, y: height - 22))
        lineLayer.path = linePath.cgPath
        lineLayer.lineWidth = 2
        lineLayer.strokeColor = UIColor.white.cgColor
        lineLayer.fillColor = UIColor.white.cgColor
        
//        let lineAimation = CABasicAnimation.init(keyPath: "strokeEnd")
//        lineAimation.fromValue = 0
//        lineAimation.toValue = 1
//        lineAimation.duration = 0.3
//        lineLayer.add(lineAimation, forKey: "")
        
        let pointPath = UIBezierPath.init()
        pointPath.addArc(
            withCenter: CGPoint(
                x: width * 0.5,
                y: height - 15
            ),
            radius: 1,
            startAngle: 0,
            endAngle: 2 * .pi,
            clockwise: true
        )
        pointLayer.path = pointPath.cgPath
        pointLayer.lineWidth = 1
        pointLayer.strokeColor = UIColor.white.cgColor
        pointLayer.fillColor = UIColor.white.cgColor
        
//        let pointAimation = CAKeyframeAnimation.init(keyPath: "transform.scale")
//        pointAimation.values = [0, 1.2, 0.8, 1.1, 0.9 , 1]
//        pointAimation.duration = 0.5
//        pointLayer.add(pointAimation, forKey: "")
    }
    private func drawTickLayer() {
        let tickPath = UIBezierPath.init()
        tickPath.move(to: CGPoint(x: scale(8), y: height * 0.5 + scale(1)))
        tickPath.addLine(to: CGPoint(x: width * 0.5 - scale(2), y: height - scale(8)))
        tickPath.addLine(to: CGPoint(x: width - scale(7), y: scale(9)))
        tickLayer.path = tickPath.cgPath
        tickLayer.lineWidth = 2
        tickLayer.lineJoin = .round
        tickLayer.strokeColor = UIColor.white.cgColor
        tickLayer.fillColor = UIColor.clear.cgColor
    }
    
    private func scale(_ numerator: CGFloat) -> CGFloat {
        return numerator / 30 * height
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
