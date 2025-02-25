import UIKit

private var refWidthKey: UInt8 = 0

extension UIView {
    /// 参照宽度，也就是【父视图】的宽度。
    /// - 如果【父视图】是`UIScrollView`最好将其设置为它的`contentSize.width`。
    @objc var hxPicker_refWidth: CGFloat {
        set { objc_setAssociatedObject(self, &refWidthKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { objc_getAssociatedObject(self, &refWidthKey) as? CGFloat ?? superview?.bounds.maxX ?? 0 }
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
    
    var hxPicker_center: CGPoint {
        set {
            guard PhotoManager.isRTL else {
                center = newValue
                return
            }
            let centerX = hxPicker_refWidth - newValue.x
            center = CGPoint(x: centerX, y: newValue.y)
        }
        get {
            guard PhotoManager.isRTL else {
                return center
            }
            let centerX = hxPicker_refWidth - center.x
            return CGPoint(x: centerX, y: center.y)
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
    @objc func hxPicker_valueFromSelf(_ v: CGFloat) -> CGFloat {
        PhotoManager.isRTL ? (bounds.width - v) : v
    }
    
    /// 相对【参照宽度】的转换值
    func hxPicker_valueFromRef(_ v: CGFloat) -> CGFloat {
        PhotoManager.isRTL ? (hxPicker_refWidth - v) : v
    }
}

extension UIView {
    /// 沿着Y轴180°翻转（水平镜像）
    func hxPicker_flip() {
        guard PhotoManager.isRTL else { return }
        layer.transform = CATransform3DMakeRotation(.pi, 0, 1, 0)
    }
}
