//
//  Core+UICollectionView.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/10/9.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit

extension UICollectionView {
    func dequeueReusableCell<T: UICollectionViewCell>(for indexPath: IndexPath) -> T {
        dequeueReusableCell(withReuseIdentifier: T.className, for: indexPath) as! T
    }
    
    func dequeueReusableCell(with cellClass: UICollectionViewCell.Type, for indexPath: IndexPath) -> UICollectionViewCell {
        dequeueReusableCell(withReuseIdentifier: cellClass.className, for: indexPath)
    }
    
    func register(_ cellClass: UICollectionViewCell.Type) {
        register(cellClass, forCellWithReuseIdentifier: cellClass.className)
    }
}
