//
//  Core+UIImageView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/1/9.
//

import UIKit

extension UIImageView {
    
    func setImage(_ image: UIImage?, duration: CFTimeInterval = 0.2, animated: Bool = true) {
        if let image = image {
            self.image = image
            if animated {
                let transition = CATransition()
                transition.type = .fade
                transition.duration = duration
                transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                layer.add(transition, forKey: nil)
            }
        }
    }
}
