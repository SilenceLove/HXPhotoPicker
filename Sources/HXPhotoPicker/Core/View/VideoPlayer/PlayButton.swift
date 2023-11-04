//
//  PlayButton.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/9/5.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit

class PlayButton: UIControl {
    
    override var isSelected: Bool {
        didSet {
            updatePlay()
        }
    }
    
    private var playLayer: CAShapeLayer!
    
    init() {
        super.init(frame: .zero)
        playLayer = CAShapeLayer()
        playLayer.fillColor = UIColor.white.cgColor
        playLayer.strokeColor = UIColor.white.cgColor
        playLayer.lineCap = .round
        playLayer.lineJoin = .round
        playLayer.contentsScale = UIScreen._scale
        playLayer.shadowColor = UIColor.black.withAlphaComponent(0.3).cgColor
        playLayer.shadowOpacity = 0.3
        layer.addSublayer(playLayer)
    }
    
    private func updatePlay() {
        let path: UIBezierPath = .init()
        let widthMargin: CGFloat = 13
        let heightMargin: CGFloat = 18
        if isSelected {
            let leftLineStartPoint: CGPoint = .init(x: width * 0.5 - widthMargin * 0.5, y: height * 0.5 - heightMargin * 0.5)
            path.move(to: leftLineStartPoint)
            path.addLine(to: .init(x: leftLineStartPoint.x + 3, y: leftLineStartPoint.y))
            path.addLine(to: .init(x: leftLineStartPoint.x + 3, y: leftLineStartPoint.y + heightMargin))
            path.addLine(to: .init(x: leftLineStartPoint.x, y: leftLineStartPoint.y + heightMargin))
            path.close()
            
            let rightLineStartPoint: CGPoint = .init(x: width * 0.5 + widthMargin * 0.5, y: height * 0.5 - heightMargin * 0.5)
            path.move(to: rightLineStartPoint)
            path.addLine(to: .init(x: rightLineStartPoint.x - 3, y: rightLineStartPoint.y))
            path.addLine(to: .init(x: rightLineStartPoint.x - 3, y: rightLineStartPoint.y + heightMargin))
            path.addLine(to: .init(x: rightLineStartPoint.x, y: rightLineStartPoint.y + heightMargin))
            path.close()
        }else {
            let startPoint: CGPoint = .init(x: width * 0.5 + widthMargin * 0.5, y: height * 0.5)
            path.move(to: startPoint)
            path.addLine(to: .init(x: startPoint.x - widthMargin, y: startPoint.y + heightMargin * 0.5))
            path.addLine(to: .init(x: startPoint.x - widthMargin, y: startPoint.y - heightMargin * 0.5))
            path.close()
        }
        let animation: CABasicAnimation = getAnimation(playLayer.path, path.cgPath, 0.25)
        playLayer.add(animation, forKey: nil)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playLayer.path = path.cgPath
        CATransaction.commit()
    }
    
    private func getAnimation(
        _ fromValue: Any?,
        _ toValue: Any?,
        _ duration: TimeInterval
    ) -> CABasicAnimation {
        let animation: CABasicAnimation = .init(keyPath: "path")
        animation.fromValue = fromValue
        animation.toValue = toValue
        animation.duration = duration
        animation.fillMode = .backwards
        animation.timingFunction = .init(name: CAMediaTimingFunctionName.linear)
        return animation
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playLayer.frame = bounds
        updatePlay()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
