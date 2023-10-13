//
//  Core+UITableView.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/10/9.
//  Copyright © 2023 洪欣. All rights reserved.
//

import UIKit

extension UITableView {
    
    func dequeueReusableCell<T: UITableViewCell>() -> T {
        dequeueReusableCell(withIdentifier: T.className) as! T
    }
    
    func register(_ cellClass: UITableViewCell.Type) {
        register(cellClass, forCellReuseIdentifier: cellClass.className)
    }
    
}
