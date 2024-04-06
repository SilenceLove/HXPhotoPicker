//
//  PhotoHUDProtocol.swift
//  HXPhotoPicker
//
//  Created by Silence on 2024/4/3.
//  Copyright © 2024 Silence. All rights reserved.
//

import UIKit

public protocol PhotoHUDProtocol: UIView {
    
    /// 设置提示框的文本内容
    func setText(_ text: String?)
    
    /// 设置提示框的进度
    func setProgress(_ progress: CGFloat)
    
    /// 加载框
    /// - Parameters:
    ///   - text: 文本内容
    ///   - delay: 延迟显示
    ///   - animated: 是否显示动画效果
    ///   - view: 添加到对应的视图
    @discardableResult
    static func show(with text: String?, delay: TimeInterval, animated: Bool, addedTo view: UIView?) -> PhotoHUDProtocol?
    
    /// 警告提示框
    /// - Parameters:
    ///   - text: 文本内容
    ///   - delay: 延迟消失
    ///   - animated: 是否显示动画效果
    ///   - view: 添加到对应的视图
    static func showInfo(with text: String?, delay: TimeInterval, animated: Bool, addedTo view: UIView?)
    
    /// 进度提示框
    /// - Parameters:
    ///   - text: 文本内容
    ///   - progress: 进度
    ///   - animated: 是否显示动画效果
    ///   - view: 添加到对应的视图
    /// - Returns: 对应的进度框
    static func showProgress(with text: String?, progress: CGFloat, animated: Bool, addedTo view: UIView?) -> PhotoHUDProtocol?
    
    /// 成功提示框
    /// - Parameters:
    ///   - text: 文本内容
    ///   - delay: 延迟消失
    ///   - animated: 是否显示动画效果
    ///   - view: 添加到对应的视图
    static func showSuccess(with text: String?, delay: TimeInterval, animated: Bool, addedTo view: UIView?)
    
    /// 隐藏提示框
    /// - Parameters:
    ///   - delay: 延迟消失
    ///   - animated: 是否显示动画效果
    ///   - view: 提示框所在的视图
    static func dismiss(delay: TimeInterval, animated: Bool, for view: UIView?)
}

extension ProgressHUD: PhotoHUDProtocol {
    public static func show(with text: String?, delay: TimeInterval, animated: Bool, addedTo view: UIView?) -> PhotoHUDProtocol? {
        showLoading(addedTo: view, text: text, afterDelay: delay, animated: animated)
    }
    
    public static func showInfo(with text: String?, delay: TimeInterval, animated: Bool, addedTo view: UIView?) {
        showWarning(addedTo: view, text: text, animated: animated, delayHide: delay)
    }
    
    public static func showSuccess(with text: String?, delay: TimeInterval, animated: Bool, addedTo view: UIView?) {
        showSuccess(addedTo: view, text: text, animated: animated, delayHide: delay)
    }
    
    public static func showProgress(with text: String?, progress: CGFloat, animated: Bool, addedTo view: UIView?) -> PhotoHUDProtocol? {
        showProgress(addedTo: view, progress: progress, text: text, animated: animated)
    }
    
    public static func dismiss(delay: TimeInterval, animated: Bool, for view: UIView?) {
        hide(forView: view, animated: animated, afterDelay: delay)
    }
    
    public func setText(_ text: String?) {
        self.text = text
    }
    
    public func setProgress(_ progress: CGFloat) {
        if mode != .circleProgress {
            mode = .circleProgress
        }
        self.progress = progress
    }
}
