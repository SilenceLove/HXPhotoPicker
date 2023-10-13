//
//  Core+NSObject.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/10/9.
//  Copyright © 2023 洪欣. All rights reserved.
//

import Foundation

extension NSObject {
    
    static var className: String {
        String(describing: self)
    }
}
