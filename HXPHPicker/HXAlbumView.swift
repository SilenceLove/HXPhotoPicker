//
//  HXAlbumView.swift
//  HXPHPickerExample
//
//  Created by 洪欣 on 2020/11/17.
//  Copyright © 2020 洪欣. All rights reserved.
//

import UIKit

protocol HXAlbumViewDelegate: NSObjectProtocol {
    
}

class HXAlbumView: UIView, UITableViewDataSource, UITableViewDelegate {
    
    weak var delegate: HXAlbumViewDelegate?
    
    lazy var tableView : UITableView = {
        let tableView = UITableView.init(frame: CGRect.init(), style: UITableView.Style.plain)
        tableView.backgroundColor = config!.backgroundColor
        tableView.dataSource = self;
        tableView.delegate = self;
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        tableView.register(HXAlbumViewCell.self, forCellReuseIdentifier: "cellId")
        return tableView
    }()
    var config: HXPHAlbumListConfiguration?
    var assetCollectionsArray: [HXPHAssetCollection] = []
    
    init(config: HXPHAlbumListConfiguration) {
        super.init(frame: CGRect.zero)
        self.config = config
        backgroundColor = config.backgroundColor
        addSubview(tableView)
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return assetCollectionsArray.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellId") as! HXAlbumViewCell
        let assetCollection = assetCollectionsArray[indexPath.row]
        cell.assetCollection = assetCollection
        cell.config = config
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return config!.cellHeight
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let assetCollection = assetCollectionsArray[indexPath.row]
        
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let myCell: HXAlbumViewCell = cell as! HXAlbumViewCell
        myCell.cancelRequest()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        tableView.frame = bounds
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
