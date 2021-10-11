//
//  Editor+UIImage.swift
//  HXPHPicker
//
//  Created by Slience on 2021/6/25.
//

import UIKit

extension UIImage {
    /// 生成马赛克图片
    func mosaicImage(level: CGFloat) -> UIImage? {
        let screenScale = level / max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        let scale = width * screenScale
        return filter(name: "CIPixellate", parameters: [kCIInputScaleKey: scale])
    }
    
    func filter(name: String, parameters: [String: Any]) -> UIImage? {
        guard let image = self.cgImage else {
            return nil
        }

        // 输入
        let input = CIImage(cgImage: image)
        // 输出
        let output = input.applyingFilter(name, parameters: parameters)

        // 渲染图片
        guard let cgimage = CIContext(options: nil).createCGImage(output, from: input.extent) else {
            return nil
        }
        return UIImage(cgImage: cgimage)
    }
}
