//
//  EditorBrushSizeView.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/10.
//

import UIKit

class EditorBrushSizeView: UIView {
    
    private var sizeLayer: CAShapeLayer!
    private var blockView: UIView!
    
    var value: CGFloat = 0 {
        didSet {
            blockView.center = .init(x: 12.5, y: 5 + 195 * (1 - value))
        }
    }
    var blockDidChanged: (((CGFloat)) -> Void)?
    var blockBeganChanged: (((CGFloat)) -> Void)?
    var blockEndedChanged: (((CGFloat)) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initViews()
        layer.addSublayer(sizeLayer)
        addSubview(blockView)
        drawSizeLayer()
    }
    
    private func initViews() {
        sizeLayer = CAShapeLayer()
        sizeLayer.contentsScale = UIScreen._scale
        sizeLayer.shadowColor = UIColor.black.cgColor
        sizeLayer.shadowOpacity = 0.4
        sizeLayer.shadowOffset = CGSize(width: 0, height: 0)
        sizeLayer.fillColor = UIColor.white.cgColor
        
        blockView = UIView(frame: .init(x: 0, y: 0, width: 20, height: 20))
        blockView.layer.cornerRadius = 10
        blockView.backgroundColor = .white
        blockView.layer.shadowOffset = CGSize(width: 0, height: 0)
        blockView.layer.shadowColor = UIColor.black.cgColor
        blockView.layer.shadowOpacity = 0.5
        blockView.addGestureRecognizer(UIPanGestureRecognizer(
            target: self,
            action: #selector(blockViewPanGestureRecognizerClick(_:))
        ))
        blockView.center = .init(x: 12.5, y: 5)
    }
    
    private func drawSizeLayer() {
        let path = UIBezierPath()
        path.move(to: .init(x: 5, y: 7))
        path.addCurve(to: .init(x: 7, y: 5), controlPoint1: .init(x: 5, y: 7), controlPoint2: .init(x: 5, y: 5))
        path.addLine(to: .init(x: 18, y: 5))
        path.addCurve(to: .init(x: 20, y: 7), controlPoint1: .init(x: 18, y: 5), controlPoint2: .init(x: 20, y: 5))
        path.addLine(to: .init(x: 13.5, y: 200))
        path.addCurve(
            to: .init(x: 11.5, y: 200),
            controlPoint1: .init(x: 13.5, y: 200),
            controlPoint2: .init(x: 12.5, y: 202)
        )
        path.addLine(to: .init(x: 5, y: 7))
        sizeLayer.path = path.cgPath
    }
    
    var currentBlockCenter: CGPoint = .zero
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let rect = CGRect(
            x: blockView.x - 5,
            y: blockView.y - 5,
            width: blockView.width + 10,
            height: blockView.height + 10
        )
        if rect.contains(point) {
            return true
        }
        return super.point(inside: point, with: event)
    }
    
    @objc
    func blockViewPanGestureRecognizerClick(_ pan: UIPanGestureRecognizer) {
        let point = pan.translation(in: self)
        switch pan.state {
        case .began:
            currentBlockCenter = blockView.center
            blockBeganChanged?(1 - value)
        case .changed:
            let blockCenterY = currentBlockCenter.y + point.y
            var value = (blockCenterY - 5.0) / 195.0
            if value < 0 {
                value = 0
            }else if value > 1 {
                value = 1
            }
            self.value = 1 - value
            blockDidChanged?(1 - value)
        case .ended, .failed, .cancelled:
            blockEndedChanged?(1 - value)
        default:
            break
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        sizeLayer.frame = bounds
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
