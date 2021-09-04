<img src="http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/chartle/hxphpickerpreview.png">

<p align="left">
<a href="https://github.com/SilenceLove/HXPHPicker"><img src="https://badgen.net/badge/icon/iOS%2010.0%2B?color=cyan&icon=apple&label"></a>
<a href="https://github.com/SilenceLove/HXPHPicker"><img src="http://img.shields.io/cocoapods/v/HXPHPicker.svg?logo=cocoapods&logoColor=ffffff"></a>
<a href="https://developer.apple.com/Swift"><img src="http://img.shields.io/badge/language-Swift-orange.svg?logo=common-workflow-language"></a>
<a href="http://mit-license.org"><img src="http://img.shields.io/badge/license-MIT-333333.svg?logo=letterboxd&logoColor=ffffff"></a>
</p>

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
    - [ ] Live Photo
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
    - [x] 马赛克
    - [x] 滤镜
- [x] 编辑视频（支持网络资源）
    - [x] 贴纸（支持GIF）
    - [x] 文字
    - [x] 配乐（支持歌词字幕）
    - [x] 裁剪
- [x] 相册展现方式
    - [x] 单独列表
    - [x] 弹窗
- [x] 多平台支持
    - [x] iOS
    - [x] iPadOS
- [x] 国际化支持
    - [x] 英文 (en)
    - [x] 简体中文 (zh-Hans)
    - [x] 繁体中文 (zh-Hant)
    - [x] 日语 (ja)
    - [x] 韩语 (ko)
    - [x] 泰语 (th)
    - [x] 印尼语 (id)
    - [x] 自定义语言 (custom)
    - [ ] 更多支持... (欢迎PR)

## <a id="要求"></a> 要求

- iOS 10.0+
- Xcode 12.5+
- Swift 5.4+

## 安装

### [Swift Package Manager](https://swift.org/package-manager/)

⚠️ 需要 Xcode 12.0 及以上版本来支持资源文件/本地化文件的添加。

```swift
dependencies: [
    .package(url: "https://github.com/SilenceLove/HXPHPicker.git", .upToNextMajor(from: "1.2.1"))
]
```

### [CocoaPods](https://guides.cocoapods.org/using/using-cocoapods.html)

将下面内容添加到 `Podfile`，并执行依赖更新。

```swift
pod 'HXPHPicker'
```

### [Carthage](https://github.com/Carthage/Carthage)

将下面内容添加到 `Cartfile`，并执行依赖更新。

```swift
github "SilenceLove/HXPHPicker"
```

## 使用方法

> 我们在 [Wiki](https://github.com/SilenceLove/HXPHPicker/wiki) 中提供了更详细的使用说明。

### 准备工作

按需在你的 Info.plist 中添加以下键值:

| Key | 模块 | 备注 |
| ----- | ----  | ---- |
| NSPhotoLibraryUsageDescription | Picker | 允许访问相册 |
| NSPhotoLibraryAddUsageDescription | Picker | 允许保存图片至相册 |
| PHPhotoLibraryPreventAutomaticLimitedAccessAlert | Picker | 设置为 `YES` iOS 14+ 以禁用自动弹出添加更多照片的弹框(Picker 已适配 Limited 功能，可由用户主动触发，提升用户体验)|
| NSCameraUsageDescription | Camera | 允许使用相机 |
| NSMicrophoneUsageDescription | Camera | 允许使用麦克风 |

### 快速上手
```swift
import HXPHPicker

class ViewController: UIViewController {

    func presentPickerController() {
        // 设置与微信主题一致的配置
        let config = PhotoTools.getWXPickerConfig()
        let pickerController = PhotoPickerController.init(picker: config)
        pickerController.pickerDelegate = self
        // 当前被选择的资源对应的 PhotoAsset 对象数组
        pickerController.selectedAssetArray = selectedAssets 
        // 是否选中原图
        pickerController.isOriginal = isOriginal
        present(pickerController, animated: true, completion: nil)
    }
}

extension ViewController: PhotoPickerControllerDelegate {
    
    /// 选择完成之后调用
    /// - Parameters:
    ///   - pickerController: 对应的 PhotoPickerController
    ///   - result: 选择的结果
    ///     result.photoAssets  选择的资源数组
    ///     result.isOriginal   是否选中原图
    func pickerController(_ pickerController: PhotoPickerController, 
                            didFinishSelection result: PickerResult) {
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

## 更新日志

| 版本 | 发布时间 | Xcode | Swift | iOS |
| ---- | ----  | ---- | ---- | ---- |
| [v1.2.1](https://github.com/SilenceLove/HXPHPicker/blob/main/Documentation/RELEASE_NOTE.md#121) | 2021-09-04 | 12.5.1 | 5.4.2 | 10.0+ |
| [v1.1.9](https://github.com/SilenceLove/HXPHPicker/blob/main/Documentation/RELEASE_NOTE.md#119) | 2021-08-16 | 12.5.1 | 5.4.2 | 10.0+ |
| [v1.1.7](https://github.com/SilenceLove/HXPHPicker/blob/main/Documentation/RELEASE_NOTE.md#117) | 2021-08-06 | 12.5.1 | 5.4.2 | 10.0+ |
| [v1.1.6](https://github.com/SilenceLove/HXPHPicker/blob/main/Documentation/RELEASE_NOTE.md#116) | 2021-08-02 | 12.5.1 | 5.4.2 | 10.0+ |
| [v1.1.5](https://github.com/SilenceLove/HXPHPicker/blob/main/Documentation/RELEASE_NOTE.md#115) | 2021-07-28 | 12.5.1 | 5.4.2 | 10.0+ |

## 版权协议

HXPHPicker 基于 MIT 协议进行分发和使用，更多信息参见[协议文件](./LICENSE)。
