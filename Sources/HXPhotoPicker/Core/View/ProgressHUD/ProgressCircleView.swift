//
//  ProgressCircleView.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/9/5.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit

final class ProgressCircleView: UIView {
    
    private var circleLayer: CAShapeLayer!
    private var borderLayer: CAShapeLayer!
    private var progressLb: UILabel!
    private var lineWidth: CGFloat = 3
    
    var progress: CGFloat = 0 {
        didSet {
            let p = max(0, min(1, progress))
            let radius = width * 0.5
            let path: UIBezierPath = .init(
                arcCenter: CGPoint(x: radius, y: radius),
                radius: radius - lineWidth * 0.5 - 1,
                startAngle: CGFloat.pi * 1.5,
                endAngle: CGFloat.pi * 1.5 + CGFloat.pi * 2 * p,
                clockwise: true
            )
            circleLayer.path = path.cgPath
            progressLb.text = "\(Int(p * 100))%"
        }
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initViews()
        layer.addSublayer(borderLayer)
        layer.addSublayer(circleLayer)
        addSubview(progressLb)
    }
    
    private func initViews() {
        circleLayer = CAShapeLayer()
        circleLayer.contentsScale = UIScreen._scale
        circleLayer.lineWidth = lineWidth
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.strokeColor = UIColor.white.cgColor
        
        borderLayer = CAShapeLayer()
        borderLayer.contentsScale = UIScreen._scale
        borderLayer.lineWidth = 1
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = UIColor.white.cgColor
        let radius: CGFloat = width * 0.5
        let path: UIBezierPath = .init(
            arcCenter: CGPoint(x: radius, y: radius),
            radius: radius - 0.5,
            startAngle: 0,
            endAngle: CGFloat.pi * 2,
            clockwise: true
        )
        borderLayer.path = path.cgPath
        
        progressLb = UILabel()
        progressLb.textColor = .white
        progressLb.textAlignment = .center
        progressLb.adjustsFontSizeToFitWidth = true
        progressLb.font = .mediumPingFang(ofSize: 13)
        progressLb.text = "0%"
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        borderLayer.frame = bounds
        circleLayer.frame = bounds
        progressLb.frame = bounds
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
