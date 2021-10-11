//
//  GIFImageView.swift
//  HXPHPickerExample
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

class GIFImage {
    /// 内部读取图片帧队列
    fileprivate lazy var readFrameQueue: DispatchQueue = DispatchQueue(
        label: "hxpickerimage.gif.readFrameQueue",
        qos: .background
    )
    /// 图片资源数据
    fileprivate var cgImageSource: CGImageSource?
    /// 总动画时长
    var totalDuration: TimeInterval = 0.0
    /// 每一帧对应的动画时长
    var frameDurations: [Int: TimeInterval] = [:]
    /// 每一帧对应的图片
    var frameImages: [Int: UIImage] = [:]
    /// 总图片数
    var frameTotalCount: Int = 0
    /// 兼容之前的 UIImage 使用
    var image: UIImage?

    /// 全局配置
    struct GlobalSetting {
        /// 配置预加载帧的数量
        static var prefetchNumber: Int = 10
        static var minFrameDuration: TimeInterval = 0.01
    }

    /// 兼容 UIImage data 调用
    convenience init?(data: Data) {
        self.init(data: data, scale: 1.0)
    }

    /// 根据二进制数据初始化【核心初始化方法】
    init?(data: Data, scale: CGFloat) {
        guard let cgImageSource = CGImageSourceCreateWithData(data as CFData, nil) else { return }
        self.cgImageSource = cgImageSource
        initGIFSource(cgImageSource: cgImageSource)
    }

    /// 获取图片数据源的第 index 帧图片的动画时间
    fileprivate class func getCGImageSourceGifFrameDelay(imageSource: CGImageSource, index: Int) -> TimeInterval {
        var delay = 0.0
        guard let imgProperties: NSDictionary = CGImageSourceCopyPropertiesAtIndex(
                imageSource,
                index, nil
        ) else { return delay }
        // 获取该帧图片的属性字典
        if let property = imgProperties[kCGImagePropertyGIFDictionary as String] as? NSDictionary {
            // 获取该帧图片的动画时长
            if let unclampedDelayTime = property[kCGImagePropertyGIFUnclampedDelayTime as String] as? NSNumber {
                delay = unclampedDelayTime.doubleValue
                if delay <= 0, let delayTime = property[kCGImagePropertyGIFDelayTime as String] as? NSNumber {
                    delay = delayTime.doubleValue
                }
            }
        }
        return delay
    }

    /// 根据图片数据源初始化，设置动画总时长、总帧数等属性
    fileprivate func initGIFSource(cgImageSource: CGImageSource) {
        let numOfFrames = CGImageSourceGetCount(cgImageSource)
        frameTotalCount = numOfFrames
        for index in 0..<numOfFrames {
            // 获取每一帧的动画时长
            let frameDuration = GIFImage.getCGImageSourceGifFrameDelay(imageSource: cgImageSource, index: index)
            self.frameDurations[index] = max(GlobalSetting.minFrameDuration, frameDuration)
            self.totalDuration += frameDuration
            // 一开始初始化预加载一定数量的图片，而不是全部图片
            if index < GlobalSetting.prefetchNumber {
                if let cgimage = CGImageSourceCreateImageAtIndex(cgImageSource, index, nil) {
                    let image: UIImage = UIImage(cgImage: cgimage)
                    if index == 0 {
                        self.image = image
                    }
                    self.frameImages[index] = image
                }
            }
        }
    }

    /// 获取某一帧图片
    func getFrame(index: Int) -> UIImage? {
        guard index < frameTotalCount else { return nil }
        // 取当前帧图片
        let currentImage = self.frameImages[index] ?? self.image
        // 如果总帧数大于预加载数，需要加载后面未加载的帧图片
        if frameTotalCount > GlobalSetting.prefetchNumber {
            // 清除当前帧图片缓存数据，空出内存
            if index != 0 {
                self.frameImages[index] = nil
            }
            // 加载后面帧图片到内存
            for i in 1...GlobalSetting.prefetchNumber {
                let idx = (i + index) % frameTotalCount
                if self.frameImages[idx] == nil {
                    // 默认加载第一张帧图片为占位，防止多次加载
                    self.frameImages[idx] = self.frameImages[0]
                    self.readFrameQueue.async { [weak self] in
                        guard let strongSelf = self, let cgImageSource = strongSelf.cgImageSource else { return }
                        guard let cgImage = CGImageSourceCreateImageAtIndex(cgImageSource, idx, nil) else { return }
                        strongSelf.frameImages[idx] = UIImage(cgImage: cgImage)
                    }
                }
            }
        }
        return currentImage
    }
}
class GIFImageView: UIImageView {
    /// 累加器，用于计算一个定时循环中的可用动画时间
    fileprivate var accumulator: TimeInterval = 0.0
    /// 当前正在显示的图片帧索引
    fileprivate var currentFrameIndex: Int = 0
    /// 当前正在显示的图片
    fileprivate var currentFrame: UIImage?
    /// 动画图片存储属性
    fileprivate var animatedImage: GIFImage?
    /// 定时器
    var displayLink: CADisplayLink?

    /// 重载初始化，初始化定时器
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupDisplayLink()
    }
    init() {
        super.init(frame: CGRect.zero)
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    override init(image: UIImage?) {
        super.init(image: image)
    }

    /// 设置 GIF 图片
    var gifImage: GIFImage? {
        get {
            return self.animatedImage
        }
        set {
            if animatedImage === newValue {
                return
            }
            self.stopAnimating()
            self.currentFrameIndex = 0
            self.accumulator = 0.0
            if let newAnimatedImage = newValue {
                self.animatedImage = newAnimatedImage
                if let currentImage = newAnimatedImage.getFrame(index: 0) {
                    super.image = currentImage
                    self.currentFrame = currentImage
                }
                self.startAnimating()
            } else {
                self.animatedImage = nil
            }
            self.layer.setNeedsDisplay()
        }

    }

    /// 当显示 GIF 时，不处理高亮状态
    override var isHighlighted: Bool {
        get {
            return super.isHighlighted
        }
        set {
            if self.animatedImage == nil {
                super.isHighlighted = newValue
            }
        }
    }

    /// 获取是否正在动画
    override var isAnimating: Bool {
        if self.animatedImage != nil && self.displayLink != nil {
            return !self.displayLink!.isPaused
        } else {
            return super.isAnimating
        }
    }

    /// 开启定时器
    override func startAnimating() {
        if self.animatedImage != nil && self.displayLink != nil {
            self.displayLink!.isPaused = false
        } else {
            super.startAnimating()
        }
    }

    /// 暂停定时器
    override func stopAnimating() {
        if self.animatedImage != nil && self.displayLink != nil {
            self.displayLink!.isPaused = true
        } else {
            super.stopAnimating()
        }
    }

    /// 当前显示内容为 GIF 当前帧图片
    override func display(_ layer: CALayer) {
        super.display(layer)
        if self.animatedImage != nil {
            if let frame = self.currentFrame {
                layer.contents = frame.cgImage
            }
        }
    }

    /// 初始化定时器
    func setupDisplayLink() {
        displayLink?.invalidate()
        displayLink = CADisplayLink(target: self, selector: #selector(GIFImageView.changeKeyFrame))
        self.displayLink!.add(to: RunLoop.main, forMode: RunLoop.Mode.common)
        self.displayLink!.isPaused = true
    }

    /// 动态改变图片动画帧
    @objc fileprivate func changeKeyFrame() {
        if superview == nil {
            displayLink?.invalidate()
            gifImage = nil
            return
        }else if let view = superview,
                 let photoClass = NSClassFromString("PhotoPreviewContentView"),
                 view.isKind(of: photoClass) {
            displayLink?.invalidate()
            gifImage = nil
            return
        }
        if let animatedImage = self.animatedImage {
            guard self.currentFrameIndex < animatedImage.frameTotalCount else { return }
            self.accumulator += min(1.0, displayLink!.duration)
            var frameDuration = animatedImage.frameDurations[self.currentFrameIndex] ?? displayLink!.duration
            while self.accumulator >= frameDuration {
                self.accumulator -= frameDuration
                self.currentFrameIndex += 1
                if self.currentFrameIndex >= animatedImage.frameTotalCount {
                    self.currentFrameIndex = 0
                }
                if let currentImage = animatedImage.getFrame(index: self.currentFrameIndex) {
                    self.currentFrame = currentImage
                }
                self.layer.setNeedsDisplay()
                if let newFrameDuration = animatedImage.frameDurations[self.currentFrameIndex] {
                    frameDuration = min(displayLink!.duration, newFrameDuration)
                }
            }
        } else {
            self.stopAnimating()
        }
    }
}
