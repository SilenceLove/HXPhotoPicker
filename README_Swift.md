
`HXPhotoPicker` Swift 版本

## <a id="功能"></a> 功能

- [x] UI 外观支持浅色/深色/自动/自定义 (iOS 13.0+)
- [x] 支持多选/混合内容选择
- [x] 支持的媒体类型:
    - [x] Photo
    - [x] GIF
    - [x] Live Photo
    - [x] Video
- [x] 支持本地资源
- [x] 在线下载iCloud上的资源
- [x] 两种相册展现方式（列表、弹窗）

## <a id="要求"></a> 要求

- iOS 9.0+
- Xcode 12.0+
- Swift 5.3+

## 使用方法

### 准备工作

按需在你的 Info.plist 中添加以下键值:

| Key | 模块 | 备注 |
| ----- | ----  | ---- |
| NSPhotoLibraryUsageDescription | Picker | 允许访问相册 |
| NSPhotoLibraryAddUsageDescription | Picker | 允许保存图片至相册 |
| PHPhotoLibraryPreventAutomaticLimitedAccessAlert | Picker | 设置为 `YES` iOS 14+ 以禁用自动弹出添加更多照片的弹框(Picker 已适配 Limited 功能，可由用户主动触发，提升用户体验)|
| NSCameraUsageDescription | Capture | 允许使用相机 |
| NSMicrophoneUsageDescription | Capture | 允许使用麦克风 |

### 快速上手
```swift
class ViewController: UIViewController {

    func presentPickerController() {
        // 自带的与微信一致的配置
        let config = HXPHTools.getWXConfig()
        let pickerController = HXPHPickerController.init(picker: config)
        pickerController.pickerControllerDelegate = self
        // 当前被选择的资源对应的 HXPHAsset 对象数组
        pickerController.selectedAssetArray = selectedAssets 
        // 是否选中原图
        pickerController.isOriginal = isOriginal
        present(pickerController, animated: true, completion: nil)
    }
}

extension ViewController: HXPHPickerControllerDelegate {
    
    /// 选择完成之后调用，单选模式下不会触发此回调
    /// - Parameters:
    ///   - pickerController: 对应的 HXPHPickerController
    ///   - selectedAssetArray: 选择的资源对应的 HXPHAsset 数据
    ///   - isOriginal: 是否选中的原图
    func pickerController(_ pickerController: HXPHPickerController, didFinishWith selectedAssetArray: [HXPHAsset], _ isOriginal: Bool) {
        self.selectedAssets = selectedAssetArray
        self.isOriginal = isOriginal
    }
    
    
    /// 单选完成之后调用
    /// - Parameters:
    ///   - pickerController: 对应的 HXPHPickerController
    ///   - photoAsset: 对应的 HXPHAsset 数据
    ///   - isOriginal: 是否选中的原图
    func pickerController(_ pickerController: HXPHPickerController, singleFinishWith photoAsset:HXPHAsset, _ isOriginal: Bool) {
        self.selectedAssets = [photoAsset]
        self.isOriginal = isOriginal
    }
    
    /// 点击取消时调用
    /// - Parameter pickerController: 对应的 HXPHPickerController
    func pickerController(didCancel pickerController: HXPHPickerController) {
        
    }
    
    /// dismiss后调用
    /// - Parameters:
    ///   - pickerController: 对应的 HXPHPickerController
    ///   - localCameraAssetArray: 相机拍摄存在本地的 HXPHAsset 数据
    ///     可以在下次进入选择时赋值给localCameraAssetArray，列表则会显示
    func pickerController(_ pickerController: HXPHPickerController, didDismissWith localCameraAssetArray: [HXPHAsset]) {
        
    }
}
```
