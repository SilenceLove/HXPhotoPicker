//
//  EditorStickerTextView+CollectionView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/8/25.
//

import UIKit

extension EditorStickerTextView: UICollectionViewDataSource,
                                 UICollectionViewDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        config.colors.count
    }
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "EditorStickerTextViewCellID",
            for: indexPath
        ) as! EditorStickerTextViewCell
        let colorHex = config.colors[indexPath.item]
        if isShowCustomColor, indexPath.item == config.colors.count - 1 {
            cell.customColor = customColor
        }else {
            cell.colorHex = colorHex
        }
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let colorHex = config.colors[indexPath.item]
        let color: UIColor
        if isShowCustomColor, indexPath.item == config.colors.count - 1 {
            color = customColor.color
            if #available(iOS 14.0, *) {
                if !customColor.isFirst && !customColor.isSelected {
                    customColor.isSelected = true
                }else {
                    let vc = UIColorPickerViewController()
                    vc.delegate = self
                    vc.selectedColor = customColor.color
                    viewController?.present(vc, animated: true, completion: nil)
                    customColor.isFirst = false
                    customColor.isSelected = true
                }
            }
        }else {
            color = colorHex.color
        }
        if currentSelectedIndex == indexPath.item {
            return
        }
        if currentSelectedIndex >= 0 {
            collectionView.deselectItem(at: IndexPath(item: currentSelectedIndex, section: 0), animated: true)
        }
        currentSelectedColor = color
        currentSelectedIndex = indexPath.item
        if showBackgroudColor {
            useBgColor = color
            if color.isWhite {
                changeTextColor(color: .black)
            }else {
                changeTextColor(color: .white)
            }
        }else {
            changeTextColor(color: color)
        }
    }
}

@available(iOS 14.0, *)
extension EditorStickerTextView: UIColorPickerViewControllerDelegate {
    public func colorPickerViewControllerDidSelectColor(
        _ viewController: UIColorPickerViewController
    ) {
        if #available(iOS 15.0, *) {
            return
        }
        didSelectCustomColor(viewController.selectedColor)
    }
    
    @available(iOS 15.0, *)
    public func colorPickerViewController(
        _ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool
    ) {
        didSelectCustomColor(color)
    }
    
    func didSelectCustomColor(_ color: UIColor) {
        customColor.color = color
        let cell = collectionView.cellForItem(
            at: .init(item: currentSelectedIndex, section: 0)
        ) as? EditorStickerTextViewCell
        cell?.customColor = customColor
        let color = customColor.color
        currentSelectedColor = color
        if showBackgroudColor {
            useBgColor = color
            if color.isWhite {
                changeTextColor(color: .black)
            }else {
                changeTextColor(color: .white)
            }
        }else {
            changeTextColor(color: color)
        }
    }
}
