//
//  PhotoPickerNavigationTitle.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/10/9.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit

public protocol PhotoPickerNavigationTitle: UIView {
    
    var title: String? { get set }
    
    var titleColor: UIColor? { get set }
    
    var isSelected: Bool { get set }
    
    init(config: PickerConfiguration, isSplit: Bool)
    
    func addTarget(_ target: Any?, action: Selector)
    
    func updateFrame()
}
