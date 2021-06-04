//
//  Core+UIImageView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/9.
//

import UIKit

extension UIImageView {
    
    func setImage(_ image: UIImage?, animated: Bool) {
        if let image = image {
            self.image = image
            if animated {
                let transition = CATransition()
                transition.type = .fade
                transition.duration = 0.2
                transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                layer.add(transition, forKey: nil)
            }
        }
    }
}
