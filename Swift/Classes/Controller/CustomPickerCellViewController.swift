//
//  CustomPickerCellViewController.swift
//  Example
//
//  Created by Slience on 2021/3/16.
//

import UIKit
import HXPHPicker

class CustomPickerCellViewController: UIViewController {
    
    let config: PickerConfiguration = PhotoTools.getWXPickerConfig(isMoment: false)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        config.photoSelectionTapAction = .quickSelect
        config.videoSelectionTapAction = .quickSelect
//        config.photoList.cell.customSingleCellClass = CustomPickerViewCell.self
        config.photoList.cell.customSelectableCellClass = CustomPickerViewCell.self
        view.backgroundColor = .white
        title = "CustomCell";
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: "打开选择器", style: .done, target: self, action: #selector(openPickerController))
    }
    
    @objc func openPickerController() {
        let pickerController = PhotoPickerController.init(config: config)
        pickerController.pickerDelegate = self
        pickerController.autoDismiss = false
        present(pickerController, animated: true, completion: nil)
    }
}
extension CustomPickerCellViewController: PhotoPickerControllerDelegate {
    func pickerController(_ pickerController: PhotoPickerController, didFinishSelection result: PickerResult) {
        pickerController.dismiss(animated: true) {
            let pickerResultVC = PickerResultViewController.init()
            pickerResultVC.config = pickerController.config
            pickerResultVC.selectedAssets = result.photoAssets
            pickerResultVC.isOriginal = result.isOriginal
            self.navigationController?.pushViewController(pickerResultVC, animated: true)
        }
    }
    func pickerController(didCancel pickerController: PhotoPickerController) {
        pickerController.dismiss(animated: true, completion: nil)
    }
}
