//
//  ViewController.swift
//  HXPhotoPickerSwift
//
//  Created by Silence on 2020/11/12.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit
import Photos

class ViewController: UIViewController , UITableViewDataSource, UITableViewDelegate {
    
    var tableView : UITableView?
    var exampleList:[HXPHExample] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        title = "Example"
        let baseExample = HXPHExample.init(title: "照片选择器", subTitle: "获取所选资源的内容", viewControllerClass: HXPHPickerBaseViewController.self)
        exampleList.append(baseExample)
        view.backgroundColor = UIColor.white
        tableView = UITableView.init(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height), style: UITableView.Style.plain)
        tableView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView?.dataSource = self
        tableView?.delegate = self
        view.addSubview(tableView!)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return exampleList.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cellId")
        if cell == nil {
            cell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "CellId")
            cell?.detailTextLabel?.numberOfLines = 0;
            cell?.detailTextLabel?.textColor = .gray
        }
        cell?.textLabel?.text = exampleList[indexPath.row].title
        cell?.detailTextLabel?.text = exampleList[indexPath.row].subTitle
        return cell!
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = exampleList[indexPath.row].viewControllerClass.init()
        navigationController?.pushViewController(vc, animated: true)
    }
}

class HXPHExample: NSObject {
    var title: String?
    var subTitle: String?
    var viewControllerClass: UIViewController.Type
    init(title: String?, subTitle: String?, viewControllerClass: UIViewController.Type) {
        self.title = title
        self.subTitle = subTitle
        self.viewControllerClass = viewControllerClass
        super.init()
    }
}

