//
//  Core+CGFloat.swift
//  HXPhotoPicker
//
//  Created by Slience on 2023/1/31.
//

import Foundation

extension CGFloat {
    
    static var max: CGFloat {
        CGFloat(MAXFLOAT)
    }
    
    var compressionQuality: CGFloat {
        if self > 30000000 {
            return 30000000 / self
        }else if self > 15000000 {
            return 10000000 / self
        }else if self > 10000000 {
            return 6000000 / self
        }else {
            return 3000000 / self
        }
    }
    
    var transitionCompressionQuality: CGFloat {
        if self > 6000000 {
            return 3000000 / self
        }else if self > 3000000 {
            return 1000000 / self
        }else if self > 1000000 {
            return 600000 / self
        }else {
            return 1000000 / self
        }
    }
}
