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
            if animated {
                UIView.transition(
                    with: self,
                    duration: duration,
                    options: [.transitionCrossDissolve, .curveEaseInOut, .allowUserInteraction]
                ) {
                    self.image = image
                }
            }else {
                self.image = image
            }
        }
    }
}
