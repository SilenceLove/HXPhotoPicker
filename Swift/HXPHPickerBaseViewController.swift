//
//  HXPHPickerBaseViewController.swift
//  HXPHPickerExample
//
//  Created by Silence on 2020/12/18.
//  Copyright © 2020 Silence. All rights reserved.
//


import UIKit
import Photos

class HXPHPickerBaseViewController: UIViewController , HXPHPickerControllerDelegate {
    
    var localCameraAssetArray: [HXPHAsset] = []
    var selectedAssets: [HXPHAsset] = []
    var isOriginal: Bool = false
    init() {
        super.init(nibName:"HXPHPickerBaseViewController",bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
    }
    
    @IBAction func selectButtonClick(_ sender: UIButton) {
        let pickerController = HXPHPickerController.init(config: HXPHTools.getWXConfig())
        pickerController.pickerContollerDelegate = self
        pickerController.selectedAssetArray = selectedAssets
        pickerController.localCameraAssetArray = localCameraAssetArray
        pickerController.isOriginal = isOriginal
        present(pickerController, animated: true, completion: nil)
    }
     
    func pickerContollerDidFinish(_ pickerController: HXPHPickerController, with selectedAssetArray: [HXPHAsset], with isOriginal: Bool) {
        self.selectedAssets = selectedAssetArray
        self.isOriginal = isOriginal
    }
    
    func pickerContollerDidDismiss(_ pickerController: HXPHPickerController, with localCameraAssetArray: [HXPHAsset]) {
        self.localCameraAssetArray = localCameraAssetArray
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
