//
//  EditorDrawTool.swift
//  HXPhotoPicker
//
//  Created by songjk on 2024/3/20.
//  Copyright © 2024 Silence. All rights reserved.
//  Catmull-Rom Spline算法实现

import Foundation

public class EditorDrawTool {
    // 计算Catmull-Rom插值点
    private static func interpolate(point p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint, t: CGFloat) -> CGPoint {
        let t2 = t * t
        let t3 = t2 * t
            
        let f1 = 2*p1.x
        let f2 = -p0.x + p2.x
        let f3 = 2*p0.x - 5*p1.x + 4*p2.x - p3.x
        let f4 = -p0.x + 3*p1.x - 3*p2.x + p3.x
        
        let x = 0.5 * (f1 + (f2 * t) + (f3 * t2) + (f4 * t3))
        
        let f1y = 2*p1.y
        let f2y = -p0.y + p2.y
        let f3y = 2*p0.y - 5*p1.y + 4*p2.y - p3.y
        let f4y = -p0.y + 3*p1.y - 3*p2.y + p3.y
        
        let y = 0.5 * (f1y + (f2y * t) + (f3y * t2) + (f4y * t3))
        
        return CGPoint(x: x, y: y)
    }

    // 根据控制点数组生成曲线点
    static func generatePoints(from controlPoints: [CGPoint], segmentsPerCurve: Int = 10) -> [CGPoint] {
        var splinePoints: [CGPoint] = []
        
        guard controlPoints.count >= 4 else {
            HXLog("需要至少4个点来生成Catmull-Rom曲线")
            return splinePoints
        }
        
        for i in 0..<controlPoints.count - 3 {
            let p0 = controlPoints[i]
            let p1 = controlPoints[i + 1]
            let p2 = controlPoints[i + 2]
            let p3 = controlPoints[i + 3]
            
            // 添加起始点
            if i == 0 {
                splinePoints.append(p1)
            }
            
            for j in 1...segmentsPerCurve {
                let t = CGFloat(j) / CGFloat(segmentsPerCurve)
                let point = interpolate(point: p0, p1: p1, p2: p2, p3: p3, t: t)
                splinePoints.append(point)
            }
            
            // 在最后一个段落中添加结束点
            if i == controlPoints.count - 4 {
                splinePoints.append(p2)
            }
        }        
        return splinePoints
    }
}


