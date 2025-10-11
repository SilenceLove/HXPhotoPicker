//
//  CameraFocusView.swift
//  HXPhotoPickerExample
//
//  Created by Silence on 2025/10/11.
//  Copyright © 2025 Silence. All rights reserved.
//

import UIKit

class CameraFocusView: UIView {
    private var rectLayer: CAShapeLayer!
    private var lineLayer: CAShapeLayer!
    private let color: UIColor
    init(
        size: CGSize,
        color: UIColor
    ) {
        self.color = color
        super.init(frame: CGRect(origin: .zero, size: size))
        
        rectLayer = CAShapeLayer()
        rectLayer.lineWidth = 2
        rectLayer.lineJoin = .round
        rectLayer.lineCap = .round
        rectLayer.strokeColor = color.cgColor
        rectLayer.fillColor = UIColor.clear.cgColor
        rectLayer.contentsScale = UIScreen._scale
        let rectPath = UIBezierPath(rect: bounds)
        rectLayer.path = rectPath.cgPath
        layer.addSublayer(rectLayer)
        
        lineLayer = CAShapeLayer()
        lineLayer.lineWidth = 1
        lineLayer.lineJoin = .round
        lineLayer.lineCap = .round
        lineLayer.strokeColor = color.cgColor
        lineLayer.fillColor = UIColor.clear.cgColor
        let linePath = UIBezierPath()
        let lineLength: CGFloat = 10
        linePath.move(to: CGPoint(x: width * 0.5, y: 0))
        linePath.addLine(to: CGPoint(x: width * 0.5, y: lineLength))
        
        linePath.move(to: CGPoint(x: width * 0.5, y: height - lineLength))
        linePath.addLine(to: CGPoint(x: width * 0.5, y: height))
        
        linePath.move(to: CGPoint(x: 0, y: height * 0.5))
        linePath.addLine(to: CGPoint(x: lineLength, y: height * 0.5))
        
        linePath.move(to: CGPoint(x: width - lineLength, y: height * 0.5))
        linePath.addLine(to: CGPoint(x: width, y: height * 0.5))
        
        lineLayer.path = linePath.cgPath
        layer.addSublayer(lineLayer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        rectLayer.frame = bounds
        lineLayer.frame = bounds
    }
}
