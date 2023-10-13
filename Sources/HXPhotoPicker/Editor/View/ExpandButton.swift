//
//  ExpandButton.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/10/8.
//  Copyright © 2023 洪欣. All rights reserved.
//

import UIKit

class ExpandButton: UIButton {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        bounds.insetBy(dx: -15, dy: -15).contains(point)
    }
}
