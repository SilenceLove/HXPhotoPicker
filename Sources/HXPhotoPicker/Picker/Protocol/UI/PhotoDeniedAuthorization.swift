//
//  PhotoDeniedAuthorization.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/10/10.
//  Copyright © 2023 洪欣. All rights reserved.
//

import UIKit

public protocol PhotoDeniedAuthorization: UIView {
    var pickerDelegate: PhotoControllerEvent? { get set }
    init(config: PickerConfiguration)
}
