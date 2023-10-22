//
//  ProgressImageView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/3/12.
//

import UIKit

final class ProgressImageView: UIView {
    
    private var circleLayer: CAShapeLayer!
    private var lineLayer: CAShapeLayer!
    private var pointLayer: CAShapeLayer!
    private var tickLayer: CAShapeLayer!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        circleLayer = CAShapeLayer()
        circleLayer.contentsScale = UIScreen._scale
        lineLayer = CAShapeLayer()
        lineLayer.contentsScale = UIScreen._scale
        pointLayer = CAShapeLayer()
        pointLayer.contentsScale = UIScreen._scale
        layer.addSublayer(circleLayer)
        layer.addSublayer(lineLayer)
        layer.addSublayer(pointLayer)
        drawCircle()
        drawExclamationPoint()
    }
    
    init(tickFrame: CGRect) {
        super.init(frame: tickFrame)
        tickLayer = CAShapeLayer()
        tickLayer.contentsScale = UIScreen._scale
        layer.addSublayer(tickLayer)
        drawTickLayer()
    }
    
    private func drawCircle() {
        let circlePath: UIBezierPath = .init()
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
    }
    
    private func drawExclamationPoint() {
        let linePath: UIBezierPath = .init()
        linePath.move(to: CGPoint(x: width * 0.5, y: 15))
        linePath.addLine(to: CGPoint(x: width * 0.5, y: height - 22))
        lineLayer.path = linePath.cgPath
        lineLayer.lineWidth = 2
        lineLayer.strokeColor = UIColor.white.cgColor
        lineLayer.fillColor = UIColor.white.cgColor
        
        let pointPath: UIBezierPath = .init()
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
    }
    private func drawTickLayer() {
        let tickPath: UIBezierPath = .init()
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
