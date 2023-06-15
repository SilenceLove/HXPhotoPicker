//
//  String+Extension.swift
//  Example
//
//  Created by 洪欣 on 2023/5/2.
//

import Foundation


extension String {
    
    subscript(_ indexs: ClosedRange<Int>) -> String {
            let beginIndex = index(startIndex, offsetBy: indexs.lowerBound)
            let endIndex = index(startIndex, offsetBy: indexs.upperBound)
            return String(self[beginIndex...endIndex])
        }
        
    subscript(_ indexs: Range<Int>) -> String {
        let beginIndex = index(startIndex, offsetBy: indexs.lowerBound)
        let endIndex = index(startIndex, offsetBy: indexs.upperBound)
        return String(self[beginIndex..<endIndex])
    }
    
    subscript(_ indexs: PartialRangeThrough<Int>) -> String {
        let endIndex = index(startIndex, offsetBy: indexs.upperBound)
        return String(self[startIndex...endIndex])
    }
    
    subscript(_ indexs: PartialRangeFrom<Int>) -> String {
        let beginIndex = index(startIndex, offsetBy: indexs.lowerBound)
        return String(self[beginIndex..<endIndex])
    }
    
    subscript(_ indexs: PartialRangeUpTo<Int>) -> String {
        let endIndex = index(startIndex, offsetBy: indexs.upperBound)
        return String(self[startIndex..<endIndex])
    }
}
