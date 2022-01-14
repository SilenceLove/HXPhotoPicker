//
//  RowTypeRule.swift
//  Example
//
//  Created by Slience on 2021/3/16.
//

import UIKit
 
protocol HomeRowTypeRule {
    var title: String { get }
    var controller: UIViewController { get }
}

protocol ConfigRowTypeRule {
    var title: String { get }
    var detailTitle: String { get }
    
    func getFunction<T: UIViewController>(_ controller: T) -> ((IndexPath) -> Void)
}
