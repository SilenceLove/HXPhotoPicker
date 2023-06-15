//
//  CGFloat+EditorView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2023/1/19.
//

import Foundation

extension CGFloat {
    var angle: CGFloat {
        self * (180 / .pi)
    }
    var radians: CGFloat {
        self / 180 * .pi
    }
}
