//
//  PhotoPickerSwitchLayout.swift
//  HXPHPicker
//
//  Created by Slience on 2021/9/22.
//

import UIKit

class PhotoPickerSwitchLayout: UICollectionViewFlowLayout {
    var changing: Bool = false
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        if changing {
            return CGPoint(x: -collectionView!.contentInset.left, y: -collectionView!.contentInset.top)
        }
        return super.targetContentOffset(forProposedContentOffset: proposedContentOffset)
    }
}
