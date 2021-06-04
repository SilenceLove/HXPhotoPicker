//
//  AlbumTickView.swift
//  HXPHPickerExample
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

public class AlbumTickView: UIView {
    public lazy var tickLayer: CAShapeLayer = {
        let tickLayer = CAShapeLayer.init()
        tickLayer.contentsScale = UIScreen.main.scale
        let tickPath = UIBezierPath.init()
        tickPath.move(to: CGPoint(x: scale(8), y: height * 0.5 + scale(1)))
        tickPath.addLine(to: CGPoint(x: width * 0.5 - scale(2), y: height - scale(8)))
        tickPath.addLine(to: CGPoint(x: width - scale(7), y: scale(9)))
        tickLayer.path = tickPath.cgPath
        tickLayer.lineWidth = 1.5
        tickLayer.strokeColor = UIColor.black.cgColor
        tickLayer.fillColor = UIColor.clear.cgColor
        return tickLayer
    }()
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(tickLayer)
    }
    
    private func scale(_ numerator: CGFloat) -> CGFloat {
        return numerator / 30 * height
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
