//
//  Core+DispatchQueue.swift
//  HXPHPicker
//
//  Created by Slience on 2021/5/14.
//

import Foundation

extension DispatchQueue {
    // 注意此方法为 static
    private static var token: DispatchSpecificKey<()> = {
        // 初始化一个 key
        let key = DispatchSpecificKey<()>()
        // 在主队列上关联一个空元组
        DispatchQueue.main.setSpecific(key: key, value: ())
        return key
    }()
    
    // 通过队列上是否有绑定 token 对应的值来判断是否为主队列
    static var isMain: Bool {
        return DispatchQueue.getSpecific(key: token) != nil
    }
}
