//
//  UIView+EditorView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2023/1/19.
//

import UIKit

extension UIView {
    func color(for point: CGPoint) -> UIColor? {
        // 用来存放目标像素值
        var pixel = [UInt8](repeatElement(0, count: 4))
        // 颜色空间为 RGB，这决定了输出颜色的编码是 RGB 还是其他（比如 YUV）
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        // 设置位图颜色分布为 RGBA
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        guard let context = CGContext(
                data: &pixel,
                width: 1,
                height: 1,
                bitsPerComponent: 8,
                bytesPerRow: 4,
                space: colorSpace,
                bitmapInfo: bitmapInfo
        ) else {
            return nil
        }
        // 设置 context 原点偏移为目标位置所有坐标
        context.translateBy(x: -point.x, y: -point.y)
        // 将图像渲染到 context 中
        layer.render(in: context)
        
        return UIColor(red: CGFloat(pixel[0]) / 255.0,
                       green: CGFloat(pixel[1]) / 255.0,
                       blue: CGFloat(pixel[2]) / 255.0,
                       alpha: CGFloat(pixel[3]) / 255.0)
    }
    
    static func animate(
        animations: @escaping () -> Void,
        completion: ((Bool) -> Void)? = nil
    ) {
        animate(
            withDuration: 0.3,
            delay: 0,
            options: [.curveEaseOut, .layoutSubviews],
            animations: animations,
            completion: completion
        )
    }
}
