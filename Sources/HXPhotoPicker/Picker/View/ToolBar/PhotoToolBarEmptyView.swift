//
//  PhotoToolBarEmptyView.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/10/16.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit

class PhotoToolBarEmptyView: UIView, PhotoToolBar {
    public weak var toolbarDelegate: PhotoToolBarDelegate?
    public var toolbarHeight: CGFloat { 0 }
    public var viewHeight: CGFloat  { 0 }
    public required init(_ config: PickerConfiguration, type: PhotoToolBarType) {
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
