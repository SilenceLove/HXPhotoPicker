//
//  Editor+CIImage.swift
//  HXPHPicker
//
//  Created by Slience on 2022/1/12.
//

import UIKit

extension CIImage {
    func filter(name: String, parameters: [String: Any]) -> CIImage? {
        guard let filter = CIFilter(name: name, parameters: parameters) else {
            return nil
        }
        filter.setValue(self, forKey: kCIInputImageKey)
        guard let output = filter.outputImage?.cropped(to: self.extent) else {
            return nil
        }
        return output
    }
}
