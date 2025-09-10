//
//  HXCollectionView.swift
//  HXPhotoPickerExample
//
//  Created by Silence on 2025/6/22.
//  Copyright © 2025 Silence. All rights reserved.
//

import UIKit

class HXCollectionView: UICollectionView {
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
#if canImport(UIKit.UIGlassEffect)
        if #available(iOS 26.0, *) {
            topEdgeEffect.isHidden = true
            leftEdgeEffect.isHidden = true
            bottomEdgeEffect.isHidden = true
            rightEdgeEffect.isHidden = true
        }
#endif
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

