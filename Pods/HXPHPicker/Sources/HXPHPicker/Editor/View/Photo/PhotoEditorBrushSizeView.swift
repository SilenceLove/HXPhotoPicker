//
//  PhotoEditorBrushSizeView.swift
//  HXPHPicker
//
//  Created by Slience on 2022/4/14.
//

import UIKit

class PhotoEditorBrushSizeView: UIView {
    
    lazy var sizeLayer: CAShapeLayer = {
        let sizeLayer = CAShapeLayer()
        sizeLayer.contentsScale = UIScreen.main.scale
        sizeLayer.shadowColor = UIColor.black.cgColor
        sizeLayer.shadowOpacity = 0.4
        sizeLayer.shadowOffset = CGSize(width: 0, height: 0)
        sizeLayer.fillColor = UIColor.white.cgColor
        return sizeLayer
    }()
    
    lazy var blockView: UIView = {
        let view = UIView(frame: .init(x: 0, y: 0, width: 20, height: 20))
        view.layer.cornerRadius = 10
        view.backgroundColor = .white
        view.layer.shadowOffset = CGSize(width: 0, height: 0)
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.5
        view.addGestureRecognizer(UIPanGestureRecognizer.init(target: self, action: #selector(blockViewPanGestureRecognizerClick(_:))))
        view.center = .init(x: 12.5, y: 5)
        return view
    }()
    
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
        
        layer.addSublayer(sizeLayer)
        addSubview(blockView)
        drawSizeLayer()
    }
    
    func drawSizeLayer() {
        let path = UIBezierPath()
        path.move(to: .init(x: 5, y: 7))
        path.addCurve(to: .init(x: 7, y: 5), controlPoint1: .init(x: 5, y: 7), controlPoint2: .init(x: 5, y: 5))
        path.addLine(to: .init(x: 18, y: 5))
        path.addCurve(to: .init(x: 20, y: 7), controlPoint1: .init(x: 18, y: 5), controlPoint2: .init(x: 20, y: 5))
        path.addLine(to: .init(x: 13.5, y: 200))
        path.addCurve(to: .init(x: 11.5, y: 200), controlPoint1: .init(x: 13.5, y: 200), controlPoint2: .init(x: 12.5, y: 202))
        path.addLine(to: .init(x: 5, y: 7))
        sizeLayer.path = path.cgPath
    }
    
    var currentBlockCenter: CGPoint = .zero
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if CGRect(x: blockView.x - 5, y: blockView.y - 5, width: blockView.width + 10, height: blockView.height + 10).contains(point) {
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
            break
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
            break
        case .ended, .failed, .cancelled:
            blockEndedChanged?(1 - value)
            break
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
