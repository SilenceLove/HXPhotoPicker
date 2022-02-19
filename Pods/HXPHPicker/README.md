<img src="http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/chartle/hxphpickerpreview.png">

<p align="left">
<a href="https://github.com/SilenceLove/HXPHPicker"><img src="https://badgen.net/badge/icon/iOS%2012.0%2B?color=cyan&icon=apple&label"></a>
<a href="https://github.com/SilenceLove/HXPHPicker"><img src="http://img.shields.io/cocoapods/v/HXPHPicker.svg?logo=cocoapods&logoColor=ffffff"></a>
<a href="https://developer.apple.com/Swift"><img src="http://img.shields.io/badge/language-Swift-orange.svg?logo=common-workflow-language"></a>
<a href="http://mit-license.org"><img src="http://img.shields.io/badge/license-MIT-333333.svg?logo=letterboxd&logoColor=ffffff"></a>
</p>

`HXPHPicker` is a photo/video selector-supports LivePhoto, GIF selection, iCloud resource online download, photo/video editing

> [中文说明](https://github.com/SilenceLove/HXPHPicker/blob/main/Documentation/README_CN.md)

## <a id="Features"></a> Features

- [x] UI Appearance supports light/dark/auto/custom
- [x] Support multiple selection/mixed content selection
- [x] Supported media types：
    - [x] Photo
    - [x] GIF
    - [x] Live Photo
    - [x] Video
- [x] Supported local media types：
    - [x] Photo
    - [x] Video
    - [x] GIF
    - [x] Live Photo
- [x] Supported network media types：
    - [x] Photo
    - [x] Video
- [x] Support downloading assets on iCloud
- [x] Support gesture back
- [x] Support sliding selection
- [x] Edit pictures (support animated pictures, network pictures)
    - [x] Graffiti
    - [x] Sticker
    - [x] Text
    - [x] Crop
    - [x] Mosaic
    - [x] Filter
- [x] Edit video (support network video)
    - [x] Graffiti
    - [x] Stickers (support GIF)
    - [x] Text
    - [x] Soundtrack (support lyrics and subtitles)
    - [x] Crop duration
    - [x] Crop Size
    - [x] Filter
- [x] Album display mode
    - [x] Separate list
    - [x] Pop-ups
- [x] Multi-platform support
    - [x] iOS
    - [x] iPadOS
- [x] Internationalization support
    - [x] English (en)
    - [x] Chinese, Simplified (zh-Hans)
    - [x] Chinese, traditional (zh-Hant)
    - [x] Japanese (ja)
    - [x] Korean (ko)
    - [x] Thai (th)
    - [x] Indonesian (id)
    - [x] Vietnamese (vi)
    - [x] Custom language (custom)
    - [ ] More support... (Pull requests welcome)

## <a id="Requirements"></a> Requirements

- iOS 12.0+
- Xcode 12.5+
- Swift 5.4+

## Installation

### [Swift Package Manager](https://swift.org/package-manager/)

⚠️ Needs Xcode 12.0+ to support resources and localization files

```swift
dependencies: [
    .package(url: "https://github.com/SilenceLove/HXPHPicker.git", .upToNextMajor(from: "1.3.7"))
]
```

### [CocoaPods](https://guides.cocoapods.org/using/using-cocoapods.html)

Add this to Podfile, and then update dependency:

```swift
pod 'HXPHPicker'
```

### [Carthage](https://github.com/Carthage/Carthage)

Add the following content to `Cartfile` and perform dependency update.

```swift
github "SilenceLove/HXPHPicker"
```

## Usage

> [Wiki](https://github.com/SilenceLove/HXPHPicker/wiki)

### Prepare

Add these keys to your Info.plist when needed:

| Key | Module | Info |
| ----- | ----  | ---- |
| NSPhotoLibraryUsageDescription | Picker | Allow access to album |
| NSPhotoLibraryAddUsageDescription | Picker | Allow to save pictures to album |
| PHPhotoLibraryPreventAutomaticLimitedAccessAlert | Picker | Set YES to prevent automatic limited access alert in iOS 14+ (Picker has been adapted with Limited features that can be triggered by the user to enhance the user experience) |
| NSCameraUsageDescription | Camera | Allow camera |
| NSMicrophoneUsageDescription | Camera | Allow microphone |

### Quick Start
```swift
import HXPHPicker

class ViewController: UIViewController {

    func presentPickerController() {
        // Set the configuration consistent with the WeChat theme
        let config = PhotoTools.getWXPickerConfig()
        
        // Method 1：
        let pickerController = PhotoPickerController(picker: config)
        pickerController.pickerDelegate = self
        // The array of PhotoAsset objects corresponding to the currently selected asset
        pickerController.selectedAssetArray = selectedAssets 
        // Whether to select the original image
        pickerController.isOriginal = isOriginal
        present(pickerController, animated: true, completion: nil)
        
        // Method 2：
        Photo.picker(
            config
        ) { result, pickerController in
            // Select completion callback
            // result Select result
            //  .photoAssets Currently selected data
            //  .isOriginal Whether the original image is selected
            // photoPickerController Corresponding photo selection controller
        } cancel: { pickerController in
            // Cancelled callback
            // photoPickerController Corresponding photo selection controller
        }
    }
}

extension ViewController: PhotoPickerControllerDelegate {
    
    /// Called after the selection is complete
    /// - Parameters:
    ///   - pickerController: corresponding PhotoPickerController
    ///   - result: Selected result
    ///     result.photoAssets  Selected asset array
    ///     result.isOriginal   Whether to select the original image
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
    
    /// Called when cancel is clicked
    /// - Parameter pickerController: Corresponding PhotoPickerController
    func pickerController(didCancel pickerController: PhotoPickerController) {
        
    }
}
```

## Release Notes

| Version | Release Date | Xcode | Swift | iOS |
| ---- | ----  | ---- | ---- | ---- |
| [v1.3.7](https://github.com/SilenceLove/HXPHPicker/blob/main/Documentation/RELEASE_NOTE.md#137) | 2022-02-19 | 13.1.0 | 5.4.2 | 12.0+ |
| [v1.3.5](https://github.com/SilenceLove/HXPHPicker/blob/main/Documentation/RELEASE_NOTE.md#135) | 2022-02-09 | 13.1.0 | 5.4.2 | 12.0+ |
| [v1.3.4](https://github.com/SilenceLove/HXPHPicker/blob/main/Documentation/RELEASE_NOTE.md#134) | 2022-01-26 | 13.1.0 | 5.4.2 | 12.0+ |
| [v1.3.3](https://github.com/SilenceLove/HXPHPicker/blob/main/Documentation/RELEASE_NOTE.md#133) | 2022-01-19 | 13.1.0 | 5.4.2 | 12.0+ |
| [v1.3.2](https://github.com/SilenceLove/HXPHPicker/blob/main/Documentation/RELEASE_NOTE.md#132) | 2022-01-14 | 13.1.0 | 5.4.2 | 12.0+ |
| [v1.3.1](https://github.com/SilenceLove/HXPHPicker/blob/main/Documentation/RELEASE_NOTE.md#131) | 2022-01-05 | 13.1.0 | 5.4.2 | 12.0+ |
| [v1.3.0](https://github.com/SilenceLove/HXPHPicker/blob/main/Documentation/RELEASE_NOTE.md#130) | 2021-12-16 | 13.1.0 | 5.4.2 | 12.0+ |
| [v1.2.9](https://github.com/SilenceLove/HXPHPicker/blob/main/Documentation/RELEASE_NOTE.md#129) | 2021-12-02 | 13.1.0 | 5.4.2 | 12.0+ |
| [v1.2.8](https://github.com/SilenceLove/HXPHPicker/blob/main/Documentation/RELEASE_NOTE.md#128) | 2021-11-26 | 12.5.1 | 5.4.2 | 12.0+ |

## License

HXPHPicker is released under the MIT license. See LICENSE for details.


[🔝](#readme)
