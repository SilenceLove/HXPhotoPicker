//
//  PhotoPickerListConfig.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/10/13.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit

public protocol PhotoPickerListConfig {
    var config: PhotoListConfiguration { get set }
}

public protocol PhotoPickerListPickerConfig {
    var pickerConfig: PickerConfiguration { get set }
}
