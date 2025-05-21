<h4 align="right">中文 | <strong><a href="https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/README_EN.md">English</a></strong></h4>
      
<p align="center">
    <a><img src="https://github.com/SilenceLove/PictureMaterial/blob/main/HXPhotoPicker/README/sample_graph.png?raw=true"  width = "384" height = "292.65" ></a>
</p>
<p align="center">
    <a href="https://github.com/SilenceLove/HXPhotoPicker"><img src="https://travis-ci.org/SilenceLove/HXPhotoPicker.svg?branch=master"></a>
    <a href="https://github.com/SilenceLove/HXPhotoPicker"><img src="https://badgen.net/badge/icon/iOS%2010.0%2B?color=cyan&icon=apple&label"></a>
    <a href="https://github.com/SilenceLove/HXPhotoPicker"><img src="http://img.shields.io/cocoapods/v/HXPhotoPicker.svg?logo=cocoapods&logoColor=ffffff"></a>
    <a href="https://developer.apple.com/Swift"><img src="http://img.shields.io/badge/language-Swift-orange.svg?logo=common-workflow-language"></a>
    <a href="http://mit-license.org"><img src="http://img.shields.io/badge/license-MIT-333333.svg?logo=letterboxd&logoColor=ffffff"></a>
    <div align="center">一款图片/视频选择器-支持LivePhoto、GIF选择、iCloud/网络资源在线下载、图片/视频编辑</div>
</p>

## 目录
* [功能](#功能)
* [要求](#要求)
* [安装](#安装)
* [示例](#示例)
    * [快速使用](#示例)
    * [如何支持GIF/网络图片](#如何支持GIF/网络图片)
    * [如何获取](#如何获取)
* [更新记录](#更新记录)
* [演示效果](#演示效果)
* [界面展示](#界面展示)
* [支持❤️](#支持❤️) 

## <a id="功能"></a> 功能

- [x] UI 外观支持浅色/深色/自动/自定义
- [x] 支持多选/混合内容选择
- [x] 支持的媒体类型：
    - [x] Photo
    - [x] GIF
    - [x] Live Photo
    - [x] Video
- [x] 支持的本地资源类型：
    - [x] Photo
    - [x] Video
    - [x] GIF
    - [x] Live Photo
- [x] 支持的网络资源类型：
    - [x] Photo
    - [x] Video
- [x] 支持下载iCloud上的资源
- [x] 支持手势返回
- [x] 支持滑动选择
- [x] 编辑图片（支持动图、网络资源）
    - [x] 涂鸦
    - [x] 贴纸
    - [x] 文字
    - [x] 裁剪
    - [x] 旋转任意角度
    - [x] 自定义蒙版
    - [x] 马赛克
    - [x] 画面调整
    - [x] 滤镜
- [x] 编辑视频（支持网络资源）
    - [x] 涂鸦
    - [x] 贴纸（支持GIF）
    - [x] 文字
    - [x] 配乐（支持歌词字幕）
    - [x] 裁剪时长
    - [x] 裁剪尺寸
    - [x] 旋转任意角度
    - [x] 自定义蒙版
    - [x] 画面调整
    - [x] 滤镜
- [x] 相册展现方式
    - [x] 单独列表
    - [x] 弹窗
- [x] 多平台支持
    - [x] iOS
    - [x] iPadOS
    - [x] Mac Catalyst
- [x] 国际化支持
    - [x] 🇨🇳 简体中文 (zh-Hans)
    - [x] 🇨🇳 繁体中文 (zh-Hant)
    - [x] 🇬🇧 英文 (en)
    - [x] 🇯🇵 日语 (ja)
    - [x] 🇰🇷 韩语 (ko)
    - [x] 🇹🇭 泰语 (th)
    - [x] 🇮🇳 印尼语 (id)
    - [x] 🇻🇳 越南语 (vi)
    - [x] 🇷🇺 俄罗斯 (ru)
    - [x] 🇩🇪 德国 (de)
    - [x] 🇫🇷 法国 (fr)
    - [x] 🇸🇦 阿拉伯 (ar)
    - [x] ✍️ 自定义语言 (custom)
    - [ ] 🤝 更多支持... (欢迎PR)

## <a id="要求"></a> 要求

- iOS 10.0+
- Xcode 12.5+
- Swift 5.4+

## <a id="安装"></a> 安装

### [Swift Package Manager](https://swift.org/package-manager/)

⚠️ 需要 Xcode 13.0 及以上版本来支持资源文件/本地化文件的添加。

```swift
dependencies: [
    .package(url: "https://github.com/SilenceLove/HXPhotoPicker.git", .upToNextMajor(from: "5.0.2"))
]
```

### [CocoaPods](https://guides.cocoapods.org/using/using-cocoapods.html)

将下面内容添加到 `Podfile`，并执行依赖更新。

```swift

/// iOS 10.0+ 默认不支持GIF和网络图片
pod 'HXPhotoPicker'

/// 使用`SwiftyGif`加载GIF图片
pod 'HXPhotoPicker/SwiftyGif'

/// 使用`SDWebImage`加载GIF/网络图片
pod 'HXPhotoPicker/SDWebImage'

/// 使用`Kingfisher v6.0.0`加载GIF/网络图片
pod 'HXPhotoPicker/Kingfisher'

/// 相机不包含定位功能
pod `HXPhotoPicker/NoLocation`

/// 只有选择器
pod `HXPhotoPicker/Picker`

/// 只有编辑器
pod `HXPhotoPicker/Editor`

/// 只有相机
pod `HXPhotoPicker/Camera`
/// 不包含定位功能
pod `HXPhotoPicker/Camera/Lite`

v4.0以下的ObjC版本
pod 'HXPhotoPickerObjC'
```

### 准备工作

按需在你的 Info.plist 中添加以下键值:

| Key | 模块 | 备注 |
| ----- | ----  | ---- |
| NSPhotoLibraryUsageDescription | Picker | 允许访问相册 |
| NSPhotoLibraryAddUsageDescription | Picker | 允许保存图片至相册 |
| PHPhotoLibraryPreventAutomaticLimitedAccessAlert | Picker | 设置为 `YES` iOS 14+ 以禁用自动弹出添加更多照片的弹框(Picker 已适配 Limited 功能，可由用户主动触发，提升用户体验) |
| NSCameraUsageDescription | Camera | 允许使用相机 |
| NSMicrophoneUsageDescription | Camera | 允许使用麦克风 |

### <a id="示例"></a> 快速上手
```swift
import HXPhotoPicker

class ViewController: UIViewController {

    func presentPickerController() {
        // 设置与微信主题一致的配置
        let config = PickerConfiguration.default
        
        // 方法一：async/await
        // 使用`Photo`
        let images: [UIImage] = try await Photo.picker(config)
        let urls: [URL] = try await Photo.picker(config)
        let urlResult: [AssetURLResult] = try await Photo.picker(config)
        let assetResult: [AssetResult] = try await Photo.picker(config)
        // 使用`PhotoPickerController`
        let images: [UIImage] = try await PhotoPickerController.picker(config)
        let urls: [URL] = try await PhotoPickerController.picker(config)
        let urlResult: [AssetURLResult] = try await PhotoPickerController.picker(config)
        let assetResult: [AssetResult] = try await PhotoPickerController.picker(config)
        
        let pickerResult = try await Photo.picker(config)
        let images: [UIImage] = try await pickerResult.objects()
        let urls: [URL] = try await pickerResult.objects()
        let urlResults: [AssetURLResult] = try await pickerResult.objects()
        let assetResults: [AssetResult] = try await pickerResult.objects()
        
        // 方法二：
        let pickerController = PhotoPickerController(picker: config)
        pickerController.pickerDelegate = self
        // 当前被选择的资源对应的 PhotoAsset 对象数组
        pickerController.selectedAssetArray = selectedAssets 
        // 是否选中原图
        pickerController.isOriginal = isOriginal
        present(pickerController, animated: true, completion: nil)
        
        // 方法三：
        Photo.picker(
            config
        ) { result, pickerController in
            // 选择完成的回调
            // result 选择结果
            //  .photoAssets 当前选择的数据
            //  .isOriginal 是否选中了原图
            // photoPickerController 对应的照片选择控制器
        } cancel: { pickerController in
            // 取消的回调
            // photoPickerController 对应的照片选择控制器 
        }
    }
}

extension ViewController: PhotoPickerControllerDelegate {
    
    /// 选择完成之后调用
    /// - Parameters:
    ///   - pickerController: 对应的 PhotoPickerController
    ///   - result: 选择的结果
    ///     result.photoAssets  选择的资源数组
    ///     result.isOriginal   是否选中原图
    func pickerController(
        _ pickerController: PhotoPickerController, 
        didFinishSelection result: PickerResult
    ) {
        // async/await
        let images: [UIImage] = try await result.objects()
        let urls: [URL] = try await result.objects()
        let urlResults: [AssetURLResult] = try await result.objects()
        let assetResults: [AssetResult] = try await result.objects()
        
        result.getImage { (image, photoAsset, index) in
            if let image = image {
                print("success", image)
            }else {
                print("failed")
            }
        } completionHandler: { (images) in
            print(images)
        }
    }
    
    /// 点击取消时调用
    /// - Parameter pickerController: 对应的 PhotoPickerController
    func pickerController(didCancel pickerController: PhotoPickerController) {
        
    }
}
```

### <a id="如何支持GIF/网络图片"></a> 如何支持GIF/网络图片 [HXImageViewProtocol](https://github.com/SilenceLove/HXPhotoPicker/tree/master/Sources/HXPhotoPicker/Core/Config/HXImageViewProtocol.swift)

<details>
  <summary><strong><a href="https://github.com/SilenceLove/HXPhotoPicker/tree/master/Sources/ImageView/GIFImageView.swift">SwiftyGif</a> </strong></summary>
  
```swift
PickerConfiguration.imageViewProtocol = GIFImageView.self

public class GIFImageView: UIImageView, HXImageViewProtocol {
    public func setImageData(_ imageData: Data?) {
        guard let imageData else {
            clear()
            SwiftyGifManager.defaultManager.deleteImageView(self)
            image = nil
            return
        }
        if let image = try? UIImage(gifData: imageData) {
            setGifImage(image)
        }else {
            image = .init(data: imageData)
        }
    }
    
    public func _startAnimating() {
        startAnimatingGif()
    }
    
    public func _stopAnimating() {
        stopAnimatingGif()
    }
}
```

</details>

<details>
  <summary><strong><a href="https://github.com/SilenceLove/HXPhotoPicker/tree/master/Sources/ImageView/SDImageView.swift">SDWebImage</a></strong></summary>
  
```swift
PickerConfiguration.imageViewProtocol = SDImageView.self

public class SDImageView: SDAnimatedImageView, HXImageViewProtocol {
    public func setImageData(_ imageData: Data?) {
        guard let imageData else { return }
        let image = SDAnimatedImage(data: imageData)
        self.image = image
    }
    
    @discardableResult
    public func setImage(with resource: ImageDownloadResource, placeholder: UIImage?, options: ImageDownloadOptionsInfo?, progressHandler: ((CGFloat) -> Void)?, completionHandler: ((Result<UIImage, ImageDownloadError>) -> Void)?) -> ImageDownloadTask? {
        var sdOptions: SDWebImageOptions = []
        var context: [SDWebImageContextOption: Any] = [:]
        if let options {
            for option in options {
                switch option {
                case .imageProcessor(let size):
                    let imageProcessor = SDImageResizingTransformer(size: size, scaleMode: .aspectFill)
                    context[.imageTransformer] = imageProcessor
                case .onlyLoadFirstFrame:
                    sdOptions.insert(.decodeFirstFrameOnly)
                case .memoryCacheExpirationExpired:
                    sdOptions.insert(.refreshCached)
                case .cacheOriginalImage, .fade, .scaleFactor:
                    break
                }
            }
        }
        sd_setImage(with: resource.downloadURL, placeholderImage: placeholder, options: sdOptions, context: context) { receivedSize, totalSize, _ in
            let progress = CGFloat(receivedSize) / CGFloat(totalSize)
            DispatchQueue.main.async {
                progressHandler?(progress)
            }
        } completed: { image, error, cacheType, sourceURL in
            if let image {
                completionHandler?(.success(image))
            }else {
                if let error = error as? NSError, error.code == NSURLErrorCancelled {
                    completionHandler?(.failure(.cancel))
                    return
                }
                completionHandler?(.failure(.error(error)))
            }
        }
        let downloadTask = ImageDownloadTask { [weak self] in
            self?.sd_cancelCurrentImageLoad()
        }
        return downloadTask
    }
    
    @discardableResult
    public func setVideoCover(with url: URL, placeholder: UIImage?, completionHandler: ((Result<UIImage, ImageDownloadError>) -> Void)?) -> ImageDownloadTask? {
        let cacheKey = url.absoluteString
        if SDImageView.isCached(forKey: cacheKey) {
            SDImageCache.shared.queryImage(forKey: cacheKey, options: [], context: nil) { (image, data, _) in
                if let image {
                    completionHandler?(.success(image))
                }else {
                    completionHandler?(.failure(.error(nil)))
                }
            }
            return nil
        }
        var imageGenerator: AVAssetImageGenerator?
        let avAsset = PhotoTools.getVideoThumbnailImage(url: url, atTime: 0.1) {
            imageGenerator = $0
        } completion: { _, image, _ in
            guard let image else {
                completionHandler?(.failure(.error(nil)))
                return
            }
            SDImageCache.shared.store(image, imageData: nil, forKey: cacheKey, cacheType: .all) {
                DispatchQueue.main.async {
                    completionHandler?(.success(image))
                }
            }
        }
        let task = ImageDownloadTask {
            avAsset.cancelLoading()
            imageGenerator?.cancelAllCGImageGeneration()
        }
        return task
    }
    
    @discardableResult
    public static func download(with resource: ImageDownloadResource, options: ImageDownloadOptionsInfo?, progressHandler: ((CGFloat) -> Void)?, completionHandler: ((Result<ImageDownloadResult, ImageDownloadError>) -> Void)?) -> ImageDownloadTask? {
        var sdOptions: SDWebImageDownloaderOptions = []
        var context: [SDWebImageContextOption: Any] = [:]
        if let options {
            for option in options {
                switch option {
                case .imageProcessor(let size):
                    let imageProcessor = SDImageResizingTransformer(size: size, scaleMode: .aspectFill)
                    context[.imageTransformer] = imageProcessor
                case .onlyLoadFirstFrame:
                    sdOptions.insert(.decodeFirstFrameOnly)
                default:
                    break
                }
            }
        }
        let key = resource.cacheKey
        if SDImageView.isCached(forKey: key) {
            SDImageCache.shared.queryImage(forKey: key, options: [], context: nil) { (image, data, _) in
                if let data = data  {
                    completionHandler?(.success(.init(imageData: data)))
                } else if let image = image as? SDAnimatedImage, let data = image.animatedImageData {
                    completionHandler?(.success(.init(imageData: data)))
                } else if let image {
                    completionHandler?(.success(.init(image: image)))
                } else {
                    completionHandler?(.failure(.error(nil)))
                }
            }
            return nil
        }
        let operation = SDWebImageDownloader.shared.downloadImage(
            with: resource.downloadURL,
            options: sdOptions,
            context: context,
            progress: { receivedSize, totalSize, _ in
                let progress = CGFloat(receivedSize) / CGFloat(totalSize)
                DispatchQueue.main.async {
                    progressHandler?(progress)
                }
            },
            completed: { image, data, error, finished in
                guard let data = data, finished, error == nil else {
                    completionHandler?(.failure(.error(error)))
                    return
                }
                DispatchQueue.global().async {
                    let format = NSData.sd_imageFormat(forImageData: data)
                    if format == SDImageFormat.GIF, let gifImage = SDAnimatedImage(data: data) {
                        SDImageCache.shared.store(gifImage, imageData: data, forKey: key, options: [], context: nil, cacheType: .all) {
                            DispatchQueue.main.async {
                                completionHandler?(.success(.init(imageData: data)))
                            }
                        }
                        return
                    }
                    if let image = image {
                        SDImageCache.shared.store(image, imageData: data, forKey: key, options: [], context: nil, cacheType: .all) {
                            DispatchQueue.main.async {
                                completionHandler?(.success(.init(image: image)))
                            }
                        }
                    }
                }
            }
        )
        let downloadTask = ImageDownloadTask {
            operation?.cancel()
        }
        return downloadTask
    }
    
    public func _startAnimating() {
        startAnimating()
    }
    
    public func _stopAnimating() {
        stopAnimating()
    }
    
    public static func getCacheKey(forURL url: URL) -> String {
        SDWebImageManager.shared.cacheKey(for: url) ?? ""
    }
    
    public static func getCachePath(forKey key: String) -> String {
        SDImageCache.shared.cachePath(forKey: key) ?? ""
    }
    
    public static func isCached(forKey key: String) -> Bool {
        FileManager.default.fileExists(atPath: getCachePath(forKey: key))
    }
    
    public static func getInMemoryCacheImage(forKey key: String) -> UIImage? {
        SDImageCache.shared.imageFromMemoryCache(forKey: key)
    }
    
    public static func getCacheImage(forKey key: String, completionHandler: ((UIImage?) -> Void)?) {
        SDImageCache.shared.queryImage(forKey: key, context: nil, cacheType: .all) { image, data, _ in
            if let data, let image = SDAnimatedImage(data: data) {
                completionHandler?(image)
            }else if let image {
                completionHandler?(image)
            }else {
                completionHandler?(nil)
            }
        }
    }
}
```

</details>

<details>
  <summary><strong><a href="https://github.com/SilenceLove/HXPhotoPicker/tree/master/Sources/ImageView/KFImageView.swift">Kingfisher(v6.0.0)</a></strong></summary>
  
```swift
PickerConfiguration.imageViewProtocol = KFImageView.self

public class KFImageView: AnimatedImageView, HXImageViewProtocol {
    public func setImageData(_ imageData: Data?) {
        guard let imageData else { return }
        let image: KFCrossPlatformImage? = DefaultImageProcessor.default.process(item: .data(imageData), options: .init([]))
        self.image = image
    }
    
    @discardableResult
    public func setImage(with resource: ImageDownloadResource, placeholder: UIImage?, options: ImageDownloadOptionsInfo?, progressHandler: ((CGFloat) -> Void)?, completionHandler: ((Result<UIImage, ImageDownloadError>) -> Void)?) -> ImageDownloadTask? {
        var kfOptions: KingfisherOptionsInfo = []
        if let options {
            for option in options {
                switch option {
                case .fade(let duration):
                    kfOptions += [.transition(.fade(duration))]
                case .imageProcessor(let size):
                    let imageProcessor = DownsamplingImageProcessor(size: size)
                    kfOptions += [.processor(imageProcessor)]
                case .onlyLoadFirstFrame:
                    kfOptions += [.onlyLoadFirstFrame]
                case .cacheOriginalImage:
                    kfOptions += [.cacheOriginalImage]
                case .memoryCacheExpirationExpired:
                    kfOptions += [.memoryCacheExpiration(.expired)]
                case .scaleFactor(let scale):
                    kfOptions += [.scaleFactor(scale)]
                }
            }
        }
        let imageResource = Kingfisher.ImageResource(downloadURL: resource.downloadURL, cacheKey: resource.cacheKey)
        if let indicatorColor = resource.indicatorColor {
            kf.indicatorType = .activity
            (kf.indicator?.view as? UIActivityIndicatorView)?.color = indicatorColor
        }
        let task = kf.setImage(with: imageResource, placeholder: placeholder, options: kfOptions) { receivedSize, totalSize in
            progressHandler?(CGFloat(receivedSize) / CGFloat(totalSize))
        } completionHandler: {
            switch $0 {
            case .success(let result):
                completionHandler?(.success(result.image))
            case .failure(let error):
                completionHandler?(.failure(error.isTaskCancelled ? .cancel : .error(error)))
            }
        }
        let downloadTask = ImageDownloadTask {
            task?.cancel()
        }
        return downloadTask
    }
    
    public func setVideoCover(with url: URL, placeholder: UIImage?, completionHandler: ((Result<UIImage, ImageDownloadError>) -> Void)?) -> ImageDownloadTask? {
        let provider = AVAssetImageDataProvider(assetURL: url, seconds: 0.1)
        provider.assetImageGenerator.appliesPreferredTrackTransform = true
        let task = KF.dataProvider(provider)
            .placeholder(placeholder)
            .onSuccess { result in
                completionHandler?(.success(result.image))
            }
            .onFailure { error in
                completionHandler?(.failure(error.isTaskCancelled ? .cancel : .error(error)))
            }
            .set(to: self)
        let downloadTask = ImageDownloadTask {
            task?.cancel()
        }
        return downloadTask
    }
    
    @discardableResult
    public static func download(with resource: ImageDownloadResource, options: ImageDownloadOptionsInfo?, progressHandler: ((CGFloat) -> Void)?, completionHandler: ((Result<ImageDownloadResult, ImageDownloadError>) -> Void)?) -> ImageDownloadTask? {
        let key = resource.cacheKey
        var kfOptions: KingfisherOptionsInfo = []
        if let options {
            for option in options {
                switch option {
                case .fade(let duration):
                    kfOptions += [.transition(.fade(duration))]
                case .imageProcessor(let size):
                    let imageProcessor = DownsamplingImageProcessor(size: size)
                    kfOptions += [.processor(imageProcessor)]
                case .onlyLoadFirstFrame:
                    kfOptions += [.onlyLoadFirstFrame]
                case .cacheOriginalImage:
                    kfOptions += [.cacheOriginalImage]
                case .memoryCacheExpirationExpired:
                    kfOptions += [.memoryCacheExpiration(.expired)]
                case .scaleFactor(let scale):
                    kfOptions += [.scaleFactor(scale)]
                }
            }
        }
        if ImageCache.default.isCached(forKey: key) {
            ImageCache.default.retrieveImage(
                forKey: key,
                options: kfOptions
            ) { (result) in
                switch result {
                case .success(let value):
                    if let data = value.image?.kf.gifRepresentation() {
                        completionHandler?(.success(.init(imageData: data)))
                    }else if let image = value.image {
                        completionHandler?(.success(.init(image: image)))
                    }else {
                        completionHandler?(.failure(.error(nil)))
                    }
                case .failure(let error):
                    completionHandler?(.failure(.error(error)))
                }
            }
            return nil
        }
        let task =  ImageDownloader.default.downloadImage(with: resource.downloadURL, options: kfOptions) { receivedSize, totalSize in
            let progress = CGFloat(receivedSize) / CGFloat(totalSize)
            progressHandler?(progress)
        } completionHandler: {
            switch $0 {
            case .success(let value):
                DispatchQueue.global().async {
                    if let gifImage = DefaultImageProcessor.default.process(
                        item: .data(value.originalData),
                        options: .init([])
                    ) {
                        ImageCache.default.store(
                            gifImage,
                            original: value.originalData,
                            forKey: key
                        )
                        DispatchQueue.main.async {
                            completionHandler?(.success(.init( imageData: value.originalData)))
                        }
                        return
                    }
                    ImageCache.default.store(
                        value.image,
                        original: value.originalData,
                        forKey: key
                    )
                    DispatchQueue.main.async {
                        completionHandler?(.success(.init(image: value.image)))
                    }
                }
            case .failure(let error):
                completionHandler?(.failure(.error(error)))
            }
        }
        let downloadTask = ImageDownloadTask {
            task?.cancel()
        }
        return downloadTask
    }
    
    public func _startAnimating() {
        startAnimating()
    }
    
    public func _stopAnimating() {
        stopAnimating()
    }
    
    public static func getCacheKey(forURL url: URL) -> String {
        url.cacheKey
    }
    
    public static func getCachePath(forKey key: String) -> String {
        ImageCache.default.cachePath(forKey: key)
    }
    
    public static func isCached(forKey key: String) -> Bool {
        ImageCache.default.isCached(forKey: key)
    }
    
    public static func getInMemoryCacheImage(forKey key: String) -> UIImage? {
        ImageCache.default.retrieveImageInMemoryCache(forKey: key)
    }
    
    public static func getCacheImage(forKey key: String, completionHandler: ((UIImage?) -> Void)?) {
        ImageCache.default.retrieveImage(forKey: key, options: []) {
            switch $0 {
            case .success(let result):
                completionHandler?(result.image)
            case .failure:
                completionHandler?(nil)
            }
        }
    }
}
```

</details>


### <a id="如何获取"></a> 如何获取

#### 获取 UIImage

```swift
/// 如果为视频的话获取则是视频封面
// async/await
// compression: 压缩参数，不传则不压缩 
let image: UIImage = try await photoAsset.object(compression)

/// 获取指定`Size`的`UIImage`
/// targetSize: 指定imageSize
/// targetMode: 裁剪模式
let image = try await photoAsset.image(targetSize: .init(width: 200, height: 200), targetMode: .fill)

// compressionQuality: 压缩参数，不传则不压缩 
photoAsset.getImage(compressionQuality: compressionQuality) { image in
    print(image)
}
```

#### 获取 URL

```swift
// async/await 
// compression: 压缩参数，不传则不压缩 
let url: URL = try await photoAsset.object(compression)
let urlResult: AssetURLResult = try await photoAsset.object(compression)

// compression: 压缩参数，不传则不压缩
photoAsset.getURL(compression: compression) { result in
    switch result {
    case .success(let urlResult):
        // 媒体类型
        switch urlResult.mediaType {
        case .photo:
            // 图片
        case .video:
            // 视频
        }
        
        // url类型
        switch urlResult.urlType {
        case .local:
            // 本地URL
        case .network:
            // 网络URL
        }
        
        // 获取的地址
        print(urlResult.url)
        
        // LivePhoto 里面包含的 图片和视频 url
        print(urlResult.livePhoto) 
        
    case .failure(let error):
        print(error)
    }
}
```

#### 获取其他

```swift
/// 获取缩略图
let thumImage = try await photoAsset.requesThumbnailImage()

/// 获取预览图
let previewImage = try await photoAsset.requestPreviewImage()

/// 获取 AVAsset
let avAsset = try await photoAsset.requestAVAsset()

/// 获取 AVPlayerItem
let playerItem = try await photoAsset.requestPlayerItem()

/// 获取 PHLivePhoto
let livePhoto = try await photoAsset.requestLivePhoto()
```

## <a id="更新记录"></a> 更新日志

<details open id="最近更新">
  <summary><strong>最近更新</strong></summary>
  
| 版本 | 发布时间 | Xcode | Swift | iOS |
| ---- | ----  | ---- | ---- | ---- |
| [v5.0.2](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE_CN.md#502) | 2025-05-21 | 16.2.0 | 6.0.0 | 10.0+ | 

</details>

<details id="历史记录">
  <summary><strong>历史记录</strong></summary>
  
| 版本 | 发布时间 | Xcode | Swift | iOS |
| ---- | ----  | ---- | ---- | ---- |
| [v5.0.1](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE_CN.md#501) | 2025-03-31 | 16.0.0 | 6.0.0 | 10.0+ | 
| [v5.0.0](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE_CN.md#500) | 2025-03-03 | 16.0.0 | 6.0.0 | 10.0+ | 
| [v4.2.5](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE_CN.md#425) | 2025-02-12 | 16.0.0 | 6.0.0 | 13.0+ | 
| [v4.2.4](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE_CN.md#424) | 2024-12-14 | 16.0.0 | 6.0.0 | 13.0+ | 
| [v4.2.3](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE_CN.md#423) | 2024-08-05 | 16.0.0 | 6.0.0 | 12.0+ | 
| [v4.2.2](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE_CN.md#422) | 2024-07-08 | 15.0.0 | 5.9.0 | 12.0+ | 
| [v4.2.1](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE_CN.md#421) | 2024-05-18 | 15.0.0 | 5.9.0 | 12.0+ | 
| [v4.2.0](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE_CN.md#420) | 2024-04-23 | 15.0.0 | 5.9.0 | 12.0+ | 
| [v4.1.9](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE_CN.md#419) | 2024-04-09 | 15.0.0 | 5.9.0 | 12.0+ | 
| [v4.1.8](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE_CN.md#418) | 2024-03-24 | 15.0.0 | 5.9.0 | 12.0+ | 
| [v4.1.7](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE_CN.md#417) | 2024-03-09 | 15.0.0 | 5.9.0 | 12.0+ | 
| [v4.1.6](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE_CN.md#416) | 2024-02-16 | 15.0.0 | 5.9.0 | 12.0+ | 
| [v4.1.5](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE_CN.md#415) | 2024-01-10 | 15.0.0 | 5.9.0 | 12.0+ | 
| [v4.1.4](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE_CN.md#414) | 2023-12-24 | 15.0.0 | 5.9.0 | 12.0+ | 
| [v4.1.3](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE_CN.md#413) | 2023-12-16 | 15.0.0 | 5.9.0 | 12.0+ | 
| [v4.1.2](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE_CN.md#412) | 2023-12-02 | 15.0.0 | 5.9.0 | 12.0+ | 
| [v4.1.1](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE_CN.md#411) | 2023-11-14 | 15.0.0 | 5.9.0 | 12.0+ | 
| [v4.1.0](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE_CN.md#410) | 2023-11-07 | 15.0.0 | 5.9.0 | 12.0+ | 
| [v4.0.9](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE_CN.md#409) | 2023-10-22 | 15.0.0 | 5.9.0 | 12.0+ |
| [v4.0.8](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE_CN.md#408) | 2023-10-13 | 15.0.0 | 5.9.0 | 12.0+ |
| [v4.0.7](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE_CN.md#407) | 2023-09-23 | 14.3.0 | 5.7.0 | 12.0+ |
| [v4.0.6](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE_CN.md#406) | 2023-09-09 | 14.3.0 | 5.7.0 | 12.0+ |
| [v4.0.5](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE_CN.md#405) | 2023-08-12 | 14.3.0 | 5.7.0 | 12.0+ |
| [v4.0.4](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE_CN.md#404) | 2023-07-30 | 14.3.0 | 5.7.0 | 12.0+ |
| [v4.0.3](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE_CN.md#403) | 2023-07-06 | 14.3.0 | 5.7.0 | 12.0+ |
| [v4.0.2](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE_CN.md#402) | 2023-06-24 | 14.3.0 | 5.7.0 | 12.0+ |
| [v4.0.1](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE_CN.md#401) | 2023-06-17 | 14.3.0 | 5.7.0 | 12.0+ |
| [v4.0.0](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE_CN.md#400) | 2023-06-15 | 14.3.0 | 5.7.0 | 12.0+ |
| [v3.0.0](https://github.com/SilenceLove/HXPhotoPickerObjC#-%E6%9B%B4%E6%96%B0%E8%AE%B0%E5%BD%95---update-history) | 2022-09-18 | 14.0.0 | ----- | 8.0+ | 

</details>

## <a id="演示效果"></a> 演示效果

| 选择照片 | 图片编辑 | 视频编辑 | 
| ---- | ----  | ---- |
| [![IMAGE ALT TEXT](https://github.com/SilenceLove/PictureMaterial/blob/main/HXPhotoPicker/README/Videos/photo_list_picker_cover.png?raw=true)](http://oss-cn-hangzhou.aliyuncs.com/tsnrhapp/shop/videos/83862ab94facfd8979eb6148094908b2.mp4) | [![IMAGE ALT TEXT](https://github.com/SilenceLove/PictureMaterial/blob/main/HXPhotoPicker/README/Videos/photo_editor_cover.png?raw=true)](http://oss-cn-hangzhou.aliyuncs.com/tsnrhapp/shop/videos/3c81199474e33006e2cebd5f6241ead5.mp4) | [![IMAGE ALT TEXT](https://github.com/SilenceLove/PictureMaterial/blob/main/HXPhotoPicker/README/Videos/video_editor_cover.png?raw=true)](http://oss-cn-hangzhou.aliyuncs.com/tsnrhapp/shop/videos/8c1cf86f32329e6464d327781f15041a.mp4) | 

## <a id="界面展示"></a> 界面展示

| <img src="https://github.com/SilenceLove/PictureMaterial/blob/main/HXPhotoPicker/README/Photos/sample_graph_photo_picker_list.png?raw=true"> | <img src="https://github.com/SilenceLove/PictureMaterial/blob/main/HXPhotoPicker/README/Photos/sample_graph_photo_preview.png?raw=true"> | <img src="https://github.com/SilenceLove/PictureMaterial/blob/main/HXPhotoPicker/README/Photos/sample_graph_photo_editor_filter.png?raw=true"> | 
| ---- | ----  | ---- |
| <img src="https://github.com/SilenceLove/PictureMaterial/blob/main/HXPhotoPicker/README/Photos/sample_graph_video_editor_time.png?raw=true"> | <img src="https://github.com/SilenceLove/PictureMaterial/blob/main/HXPhotoPicker/README/Photos/sample_graph_video_editor_edit.png?raw=true"> | <img src="https://github.com/SilenceLove/PictureMaterial/blob/main/HXPhotoPicker/README/Photos/sample_graph_video_editor_crop_size.png?raw=true"> |

| <img src="https://github.com/SilenceLove/PictureMaterial/blob/main/HXPhotoPicker/README/Photos/sample_graph_photo_editor_crop_size_horizontal_screen.png?raw=true"> | <img src="https://github.com/SilenceLove/PictureMaterial/blob/main/HXPhotoPicker/README/Photos/sample_graph_video_editor_crop_size_horizontal_screen.png?raw=true"> |
| ---- | ----  |

## 版权协议 
HXPhotoPicker 基于 MIT 协议进行分发和使用，更多信息参见[协议文件](./LICENSE)。 

## <a id="支持❤️"></a> 支持❤️
* [**★ Star**](#)
* 支持作者☕️ 
    
<div align="left"><a href="https://www.buymeacoffee.com/fengye" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="height: 60px !important;width: 217px !important;" ></a></div> 

| <img src="https://github.com/SilenceLove/PictureMaterial/blob/main/HXPhotoPicker/Support/bmc_qr.png?raw=true" width = "135" height = "135" /> | <img src="https://github.com/SilenceLove/PictureMaterial/blob/main/HXPhotoPicker/Support/ap.jpeg?raw=true" width = "100" height = "135.75" />   | <img src="https://github.com/SilenceLove/PictureMaterial/blob/main/HXPhotoPicker/Support/wp.jpeg?raw=true" width = "100" height = "135.75" /> |
| ------ | ------ | ------ | 

[![Stargazers over time](https://starchart.cc/SilenceLove/HXPhotoPicker.svg)](https://starchart.cc/SilenceLove/HXPhotoPicker)


[🔝回到顶部](#readme)
