//
//  EditorBrushBlockView.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/10.
//

import UIKit

class EditorBrushBlockView: UIView {
    
    var color: UIColor? {
        didSet {
            guard let color = color else {
                borderLayer.fillColor = UIColor.clear.cgColor
                return
            }
            borderLayer.fillColor = color.cgColor
        }
    }
    
    private var borderLayer: CAShapeLayer!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        borderLayer = CAShapeLayer()
        borderLayer.strokeColor = UIColor.white.cgColor
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.lineWidth = 2
        borderLayer.shadowColor = UIColor.black.cgColor
        borderLayer.shadowRadius = 2
        borderLayer.shadowOpacity = 0.4
        borderLayer.shadowOffset = CGSize(width: 0, height: 0)
        layer.addSublayer(borderLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        borderLayer.frame = bounds
        
        let path = UIBezierPath(
            arcCenter: CGPoint(x: width * 0.5, y: height * 0.5),
            radius: width * 0.5 - 1,
            startAngle: 0,
            endAngle: CGFloat.pi * 2,
            clockwise: true
        )
        borderLayer.path = path.cgPath
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
