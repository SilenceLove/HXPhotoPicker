import UIKit

private var refWidthKey: UInt8 = 0

extension CALayer {
    /// 参照宽度，也就是【父图层】的宽度。
    /// - 如果【父图层】是`CAScrollLayer`最好将其设置为它的`内容宽度`。
    @objc var hxPicker_refWidth: CGFloat {
        set { objc_setAssociatedObject(self, &refWidthKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { objc_getAssociatedObject(self, &refWidthKey) as? CGFloat ?? superlayer?.bounds.maxX ?? 0 }
    }
    
    var hxPicker_frame: CGRect {
        set {
            guard PhotoManager.isRTL else {
                frame = newValue
                return
            }
            let x = hxPicker_refWidth - newValue.maxX
            frame = CGRect(origin: CGPoint(x: x, y: newValue.origin.y), size: newValue.size)
        }
        get {
            guard PhotoManager.isRTL else {
                return frame
            }
            let x = hxPicker_refWidth - frame.maxX
            return CGRect(origin: CGPoint(x: x, y: frame.origin.y), size: frame.size)
        }
    }
    
    var hxPicker_position: CGPoint {
        set {
            guard PhotoManager.isRTL else {
                position = newValue
                return
            }
            let positionX = hxPicker_refWidth - newValue.x
            position = CGPoint(x: positionX, y: newValue.y)
        }
        get {
            guard PhotoManager.isRTL else {
                return position
            }
            let positionX = hxPicker_refWidth - position.x
            return CGPoint(x: positionX, y: position.y)
        }
    }
    
    var hxPicker_x: CGFloat {
        set {
            guard PhotoManager.isRTL else {
                frame.origin.x = newValue
                return
            }
            let x = hxPicker_refWidth - frame.width - newValue
            frame.origin.x = x
        }
        get {
            guard PhotoManager.isRTL else {
                return frame.origin.x
            }
            let x = hxPicker_refWidth - frame.maxX
            return x
        }
    }
    
    var hxPicker_midX: CGFloat {
        guard PhotoManager.isRTL else {
            return frame.midX
        }
        let midX = hxPicker_refWidth - frame.midX
        return midX
    }
    
    var hxPicker_maxX: CGFloat {
        guard PhotoManager.isRTL else {
            return frame.maxX
        }
        return hxPicker_refWidth - frame.origin.x
    }
    
    /// 相对【自身宽度】的转换值
    func hxPicker_valueFromSelf(_ v: CGFloat) -> CGFloat {
        PhotoManager.isRTL ? (bounds.width - v) : v
    }
    
    /// 相对【参照宽度】的转换值
    func hxPicker_valueFromRef(_ v: CGFloat) -> CGFloat {
        PhotoManager.isRTL ? (hxPicker_refWidth - v) : v
    }
}

extension CALayer {
    /// 沿着Y轴180°翻转（水平镜像）
    func hxPicker_flip() {
        guard PhotoManager.isRTL else { return }
        transform = CATransform3DMakeRotation(CGFloat.pi, 0, 1, 0)
    }
}
