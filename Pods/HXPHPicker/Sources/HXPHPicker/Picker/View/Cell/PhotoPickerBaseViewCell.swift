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
        didSet {
            photoView.targetWidth = config?.targetWidth ?? 250
            #if canImport(Kingfisher)
            photoView.kf_indicatorColor = config?.kf_indicatorColor
            #endif
            configColor()
        }
    }
    /// 展示图片
    public lazy var photoView: PhotoThumbnailView = {
        let photoView = PhotoThumbnailView()
        photoView.fadeImage = PhotoManager.shared.firstLoadAssets
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
            if isRequestDirectly {
                request()
            }
        }
    }
    
    open func request() {
        requestThumbnailImage()
        requestICloudState()
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
        photoView.requestThumbnailImage(targetWidth: targetWidth) { [weak self] in
            guard let self = self, self.photoAsset == $1 else { return }
            self.requestThumbnailCompletion($0)
        }
    }
    
    open func requestThumbnailCompletion(_ image: UIImage?) {
        
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
    
    /// 是否在iCloud上，只有获取过iCloud状态之后才确定
    open var inICloud: Bool = false
    
    /// 获取iCloud上的状态的请求id
    public var iCloudRequestID: PHImageRequestID?
    
    /// 获取是否在iCloud
    open func requestICloudState() {
        guard let config = config,
              config.showICloudMark else {
            return
        }
        cancelICloudRequest()
        if PhotoManager.shared.thumbnailLoadMode == .simplify {
            return
        }
        iCloundLoading = true
        iCloudRequestID = photoAsset.requestICloudState { [weak self] photoAsset, inICloud in
            guard let self = self,
                  self.photoAsset == photoAsset else {
                return
            }
            self.iCloudRequestID = nil
            self.requestICloudStateCompletion(inICloud)
            self.iCloundLoading = false
        }
    }
    
    /// 获取iCloud上状态完成
    open func requestICloudStateCompletion(_ inICloud: Bool) {
        self.inICloud = inICloud
        requestICloudCompletion = true
    }
    
    /// 布局，重写此方法修改布局
    open func layoutView() {
        photoView.frame = bounds
    }
    
    /// 取消请求资源图片
    public func cancelRequest() {
        photoView.cancelRequest()
        cancelICloudRequest()
    }
    
    open func cancelICloudRequest() {
        if iCloundLoading {
            iCloundLoading = false
        }
        if requestICloudCompletion {
            requestICloudCompletion = false
        }
        if inICloud {
            inICloud = false
        }
        if let id = iCloudRequestID {
            PHImageManager.default().cancelImageRequest(id)
            iCloudRequestID = nil
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
//        addLoadModeObserver()
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
    var isRequestDirectly = true
    var iCloundLoading = false
    var requestICloudCompletion = false
    deinit {
        cancelRequest()
    }
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PhotoPickerBaseViewCell {
    func reload() {
        self.photoView.reloadImage()
        if !self.requestICloudCompletion && !self.iCloundLoading {
            self.requestICloudState()
        }
    }
    func cancelReload() {
        self.photoView.cancelRequest()
        if !self.requestICloudCompletion {
            self.cancelICloudRequest()
        }
    }
}
