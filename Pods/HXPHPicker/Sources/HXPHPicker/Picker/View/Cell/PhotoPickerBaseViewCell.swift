//
//  PhotoPickerBaseViewCell.swift
//  HXPHPicker
//
//  Created by Slience on 2021/3/12.
//

import UIKit
import Photos

#if canImport(Kingfisher)
import Kingfisher
#endif

public protocol PhotoPickerViewCellDelegate: AnyObject {
    func cell(_ cell: PhotoPickerBaseViewCell, didSelectControl isSelected: Bool)
}

public extension PhotoPickerViewCellDelegate {
    func cell(_ cell: PhotoPickerBaseViewCell, didSelectControl isSelected: Bool) { }
}

open class PhotoPickerBaseViewCell: UICollectionViewCell {
    /// 代理
    public weak var delegate: PhotoPickerViewCellDelegate?
    /// 配置
    public var config: PhotoListCellConfiguration? {
        didSet { configColor() }
    }
    /// 展示图片
    public lazy var photoView: PhotoThumbnailView = {
        let photoView = PhotoThumbnailView()
        return photoView
    }()
    /// 是否可以选择
    open var canSelect = true
    
    /// 请求ID
    public var requestID: PHImageRequestID? {
        photoView.requestID
    }
    
    /// 网络图片下载状态
    public var downloadStatus: PhotoAsset.DownloadStatus {
        photoView.downloadStatus
    }
    
    /// 对应资源的 PhotoAsset 对象
    open var photoAsset: PhotoAsset! {
        didSet {
            updateSelectedState(isSelected: photoAsset.isSelected, animated: false)
            photoView.photoAsset = photoAsset
            requestThumbnailImage()
        }
    }
    /// 初始化
    open func initView() {
        contentView.addSubview(photoView)
    }
    /// 配置背景颜色
    open func configColor() {
        backgroundColor = PhotoManager.isDark ? config?.backgroundDarkColor : config?.backgroundColor
    }
    
    /// 当前选中时显示的标题数字
    open var selectedTitle: String = "0"
    
    /// 获取图片，重写此方法可以修改图片
    open func requestThumbnailImage() { 
        requestThumbnailImage(
            targetWidth: config?.targetWidth ?? 250
        )
    }
    
    /// 获取图片，重写此方法可以修改图片
    open func requestThumbnailImage(targetWidth: CGFloat) {
        photoView.requestThumbnailImage(targetWidth: targetWidth)
    }
    
    /// 更新已选状态
    /// 重写此方法时如果是自定义的选择按钮显示当前选择的下标文字，必须在此方法内更新文字内容，否则将会出现顺序显示错乱
    /// 当前选择的下标：photoAsset.selectIndex
    /// - Parameters:
    ///   - isSelected: 是否已选择
    ///   - animated: 是否需要动画效果
    open func updateSelectedState(isSelected: Bool, animated: Bool) {
        selectedTitle = isSelected ? String(photoAsset.selectIndex + 1) : "0"
    }
    /// 布局，重写此方法修改布局
    open func layoutView() {
        photoView.frame = bounds
    }
    /// 取消请求资源图片
    public func cancelRequest() {
        photoView.cancelRequest()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }
    open override func layoutSubviews() {
        super.layoutSubviews()
        layoutView()
    }
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                configColor()
            }
        }
    }
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
