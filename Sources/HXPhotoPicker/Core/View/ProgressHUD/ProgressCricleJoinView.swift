//
//  ProgressCricleJoinView.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/10/29.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit

class ProgressCricleJoinView: UIView {
    
    var replicatorLayer: CAReplicatorLayer!
    var mylayer: CALayer!
    var isAnimating: Bool = false
    override init(frame: CGRect) {
        super.init(frame: frame)
        replicatorLayer = CAReplicatorLayer()
        replicatorLayer.cornerRadius = 10
        replicatorLayer.contentsScale = UIScreen._scale
        
        mylayer = CALayer()
        mylayer.contentsScale = UIScreen._scale
        mylayer.masksToBounds = true
        mylayer.backgroundColor = UIColor.white.cgColor
        replicatorLayer.addSublayer(mylayer)
        
    }
    
    func startAnimating() {
        if isAnimating {
            return
        }
        isAnimating = true
        let myWidth: CGFloat = 5
        mylayer.frame = .init(x: 0, y: 0, width: myWidth, height: myWidth)
        mylayer.cornerRadius = myWidth / 2
        mylayer.transform = CATransform3DMakeScale(0.01, 0.01, 0.01)
        
        let count = 200
        replicatorLayer.instanceCount = count
        
        let angle: CGFloat = .pi * 2 / CGFloat(count)
        replicatorLayer.instanceTransform = CATransform3DMakeRotation(angle, 0, 0, 1)
        replicatorLayer.instanceDelay = 0.6 / CGFloat(count)
        
        let animation = CABasicAnimation()
        animation.repeatCount = Float(CGFLOAT_MAX)
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        animation.keyPath = "transform.scale"
        animation.duration = 0.6
        animation.fromValue = 1
        animation.toValue = 0
        mylayer.add(animation, forKey: "ProgressHUD Cricle Join")
    }
    
    func stopAnimating() {
        if !isAnimating { return }
        replicatorLayer.removeAllAnimations()
        mylayer.removeAllAnimations()
        isAnimating = false
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if newSuperview != nil {
            layer.addSublayer(replicatorLayer)
        }else {
            replicatorLayer.removeFromSuperlayer()
            stopAnimating()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        replicatorLayer.frame = bounds
        mylayer.position = .init(x: 37, y: 20)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
