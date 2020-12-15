//
//  ViewController.swift
//  HXPhotoPickerSwift
//
//  Created by 洪欣 on 2020/11/12.
//  Copyright © 2020 洪欣. All rights reserved.
//

import UIKit
import Photos

class ViewController: UIViewController , UITableViewDataSource, UITableViewDelegate, HXPHPickerControllerDelegate {
    
    var tableView : UITableView?
    
    var selectedAssets: [HXPHAsset] = []
    var isOriginal: Bool = false
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        title = "swift"
        view.backgroundColor = UIColor.white
        
        tableView = UITableView.init(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height), style: UITableView.Style.plain)
        tableView?.dataSource = self
        tableView?.delegate = self
        
        tableView?.register(UITableViewCell.classForCoder(), forCellReuseIdentifier: "cellId")
        
        view.addSubview(tableView!)
        
//        UINavigationBar.appearance().isTranslucent = false
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellId")
        cell?.textLabel?.text = "\( indexPath.row)"
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let pickerController = HXPHPickerController.init(config: HXPHTools.getWXConfig())
//        let pickerController = HXPHPickerController.init(config: HXPHConfiguration.init())
        pickerController.pickerContollerDelegate = self
        pickerController.selectedAssetArray = selectedAssets
//        pickerController.localAssetArray = [HXPHAsset.init(image: UIImage.init(named: "wx_head_icon"))]
        pickerController.isOriginal = isOriginal
//        pickerController.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        present(pickerController, animated: true, completion: nil)
    }
    func pickerContollerDidFinish(_ pickerController: HXPHPickerController, with selectedAssetArray: [HXPHAsset], with isOriginal: Bool) {
        self.selectedAssets = selectedAssetArray
        self.isOriginal = isOriginal
    }
    
}

