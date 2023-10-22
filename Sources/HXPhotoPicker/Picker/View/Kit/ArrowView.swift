//
//  ArrowView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/8/30.
//

import UIKit

class ArrowView: UIView {
    private let config: ArrowViewConfiguration
    private var backgroundLayer: CAShapeLayer!
    private var arrowLayer: CAShapeLayer!
    
    var isHighlighted: Bool = false {
        didSet {
            configColor()
        }
    }
    
    init(frame: CGRect, config: ArrowViewConfiguration) {
        self.config = config
        super.init(frame: frame)
        initViews()
        drawContent()
        configColor()
    }
    
    private func initViews() {
        arrowLayer = CAShapeLayer()
        arrowLayer.contentsScale = UIScreen._scale
        backgroundLayer = CAShapeLayer()
        backgroundLayer.contentsScale = UIScreen._scale
    }
    
    private func drawContent() {
        let circlePath = UIBezierPath(
            arcCenter: CGPoint(
                x: width * 0.5,
                y: height * 0.5
            ),
            radius: width * 0.5,
            startAngle: 0,
            endAngle: 2 * .pi,
            clockwise: true
        )
        backgroundLayer.path = circlePath.cgPath
        layer.addSublayer(backgroundLayer)
        
        let arrowPath = UIBezierPath()
        arrowPath.move(to: CGPoint(x: 5, y: 8))
        arrowPath.addLine(to: CGPoint(x: width / 2, y: height - 7))
        arrowPath.addLine(to: CGPoint(x: width - 5, y: 8))
        arrowLayer.path = arrowPath.cgPath
        arrowLayer.lineWidth = 1.5
        arrowLayer.fillColor = UIColor.clear.cgColor
        layer.addSublayer(arrowLayer)
    }
    
    private func configColor() {
        let bgColor = PhotoManager.isDark ? config.backgroudDarkColor : config.backgroundColor
        let arrowColor = PhotoManager.isDark ? config.arrowDarkColor : config.arrowColor
        backgroundLayer.fillColor = isHighlighted ?
        bgColor.withAlphaComponent(0.4).cgColor :
        bgColor.cgColor
        arrowLayer.strokeColor = PhotoManager.isDark ?
        arrowColor.withAlphaComponent(0.4).cgColor :
        arrowColor.cgColor
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundLayer.frame = bounds
        arrowLayer.frame = bounds
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                configColor()
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
