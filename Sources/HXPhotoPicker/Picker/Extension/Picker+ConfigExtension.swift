//
//  Picker+ConfigExtension.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/9/28.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit

extension PickerConfiguration {
    
    var isSingleVideo: Bool {
        selectMode == .multiple &&
        !allowSelectedTogether &&
        maximumSelectedVideoCount == 1 &&
        selectOptions.isPhoto &&
        selectOptions.isVideo &&
        photoList.cell.isHiddenSingleVideoSelect
    }
    
    var isMultipleSelect: Bool {
        selectMode == .multiple
    }
}
