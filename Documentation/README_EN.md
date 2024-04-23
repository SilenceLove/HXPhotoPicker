<h4 align="right"><strong><a href="https://github.com/SilenceLove/HXPhotoPicker#readme">中文</a></strong> | English</h4>
            
<p align="center">
    <a><img src="https://github.com/SilenceLove/PictureMaterial/blob/main/HXPhotoPicker/README/sample_graph.png?raw=true"  width = "384" height = "292.65" ></a>
    
<p align="center">
    <a href="https://github.com/SilenceLove/HXPhotoPicker"><img src="https://travis-ci.org/SilenceLove/HXPhotoPicker.svg?branch=master"></a>
    <a href="https://github.com/SilenceLove/HXPhotoPicker"><img src="https://badgen.net/badge/icon/iOS%2012.0%2B?color=cyan&icon=apple&label"></a>
    <a href="https://github.com/SilenceLove/HXPhotoPicker"><img src="http://img.shields.io/cocoapods/v/HXPhotoPicker.svg?logo=cocoapods&logoColor=ffffff"></a>
    <a href="https://developer.apple.com/Swift"><img src="http://img.shields.io/badge/language-Swift-orange.svg?logo=common-workflow-language"></a>
    <a href="http://mit-license.org"><img src="http://img.shields.io/badge/license-MIT-333333.svg?logo=letterboxd&logoColor=ffffff"></a>
    <div align="center"><a href="https://www.buymeacoffee.com/fengye" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="height: 60px !important;width: 217px !important;" ></a></div>
    <div align="center">photo/video selector-supports LivePhoto, GIF selection, iCloud resource online download, photo/video editing</div>
</p> 

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
    - [x] Mac Catalyst
- [x] Internationalization support
    - [x] 🇨🇳 Chinese, Simplified (zh-Hans)
    - [x] 🇬🇧 English (en)
    - [x] 🇨🇳 Chinese, traditional (zh-Hant)
    - [x] 🇯🇵 Japanese (ja)
    - [x] 🇰🇷 Korean (ko)
    - [x] 🇹🇭 Thai (th)
    - [x] 🇮🇳 Indonesian (id)
    - [x] 🇻🇳 Vietnamese (vi)
    - [x] 🇷🇺 russian (ru)
    - [x] 🇩🇪 german (de)
    - [x] 🇫🇷 french (fr)
    - [x] 🇸🇦 arabic (ar)
    - [x] ✍️ Custom language (custom)
    - [ ] 🤝 More support... (Pull requests welcome)
    
## <a id="Requirements"></a> Requirements

- iOS 12.0+
- Xcode 12.5+
- Swift 5.4+

## Installation

### [Swift Package Manager](https://swift.org/package-manager/)

⚠️ Needs Xcode 12.0+ to support resources and localization files

```swift
dependencies: [
    .package(url: "https://github.com/SilenceLove/HXPhotoPicker.git", .upToNextMajor(from: "4.2.0"))
]
```

### [CocoaPods](https://guides.cocoapods.org/using/using-cocoapods.html)

Add this to Podfile, and then update dependency:

```swift

iOS 12.0+
pod 'HXPhotoPicker'

/// No Kingfisher
pod `HXPhotoPicker/Lite`

/// Only Picker
pod `HXPhotoPicker/Picker`
pod `HXPhotoPicker/Picker/Lite`

/// Only Editor
pod `HXPhotoPicker/Editor`
pod `HXPhotoPicker/Editor/Lite`

/// Only Camera
pod `HXPhotoPicker/Camera`
/// Does not include location functionality
pod `HXPhotoPicker/Camera/Lite`

iOS 10.0+
pod 'HXPhotoPicker-Lite'
pod 'HXPhotoPicker-Lite/Picker'
pod 'HXPhotoPicker-Lite/Editor'
pod 'HXPhotoPicker-Lite/Camera'
```

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
import HXPhotoPicker

class ViewController: UIViewController {

    func presentPickerController() {
        let config = PickerConfiguration()
                
        // Method 1：async/await
        let images: [UIImage] = try await Photo.picker(config)
        let urls: [URL] = try await Photo.picker(config)
        let urlResult: [AssetURLResult] = try await Photo.picker(config)
        let assetResult: [AssetResult] = try await Photo.picker(config)
        
        let pickerResult = try await Photo.picker(config)
        let images: [UIImage] = try await pickerResult.objects()
        let urls: [URL] = try await pickerResult.objects()
        let urlResults: [AssetURLResult] = try await pickerResult.objects()
        let assetResults: [AssetResult] = try await pickerResult.objects()
        
        // Method 2：
        let pickerController = PhotoPickerController(picker: config)
        pickerController.pickerDelegate = self
        // The array of PhotoAsset objects corresponding to the currently selected asset
        pickerController.selectedAssetArray = selectedAssets 
        // Whether to select the original image
        pickerController.isOriginal = isOriginal
        present(pickerController, animated: true, completion: nil)
        
        // Method 3：
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
    
    /// Called when cancel is clicked
    /// - Parameter pickerController: Corresponding PhotoPickerController
    func pickerController(didCancel pickerController: PhotoPickerController) {
        
    }
}
```

### Get Content

#### Get UIImage

```swift
/// If it is a video, get the cover of the video

// async/await
// compression: if not passed, no compression 
let image: UIImage = try await photoAsset.object(compression)

/// Get the `UIImage` of the specified `Size`
/// targetSize: specify imageSize
/// targetMode: crop mode
let image = try await photoAsset.image(targetSize: .init(width: 200, height: 200), targetMode: .fill)

// compressionQuality: Compress parameters, if not passed, no compression 
photoAsset.getImage(compressionQuality: compressionQuality) { image in
    print(image)
}
```

#### Get URL

```swift
// async/await 
// compression: if not passed, no compression
let url: URL = try await photoAsset.object(compression)
let urlResult: AssetURLResult = try await photoAsset.object(compression)
let assetResult: AssetResult = try await photoAsset.object(compression)

/// compression: Compress parameters, if not passed, no compression
photoAsset.getURL(compression: compression) { result in
    switch result {
    case .success(let urlResult): 
        
        switch urlResult.mediaType {
        case .photo:
        
        case .video:
        
        }
        
        switch urlResult.urlType {
        case .local:
        
        case .network:
        
        }
        
        print(urlResult.url)
        
        // Image and video urls contained in LivePhoto
        print(urlResult.livePhoto) 
        
    case .failure(let error):
        print(error)
    }
}
```

#### Get Other

```swift
/// Get thumbnail
let thumImage = try await photoAsset.requesthumbnailImage()

/// Get preview
let previewImage = try await photoAsset.requestPreviewImage()

/// Get AVAsset
let avAsset = try await photoAsset.requestAVAsset()

/// Get AVPlayerItem
let playerItem = try await photoAsset.requestPlayerItem()

/// Get PHLivePhoto
let livePhoto = try await photoAsset.requestLivePhoto()
```

## Release Notes

<details open id="Latest updates">
  <summary><strong>Latest updates</strong></summary>
  
| Version | Release Date | Xcode | Swift | iOS |
| ---- | ----  | ---- | ---- | ---- |
| [v4.2.0](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE.md#420) | 2024-04-23 | 15.0.0 | 5.9.0 | 12.0+ |

</details>

<details open id="History record">
  <summary><strong>History record</strong></summary>
  
| Version | Release Date | Xcode | Swift | iOS |
| ---- | ----  | ---- | ---- | ---- |
| [v4.1.9](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE.md#419) | 2024-04-09 | 15.0.0 | 5.9.0 | 12.0+ |
| [v4.1.8](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE.md#418) | 2024-03-24 | 15.0.0 | 5.9.0 | 12.0+ |
| [v4.1.7](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE.md#417) | 2024-03-09 | 15.0.0 | 5.9.0 | 12.0+ |
| [v4.1.6](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE.md#416) | 2024-02-16 | 15.0.0 | 5.9.0 | 12.0+ |
| [v4.1.5](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE.md#415) | 2024-01-10 | 15.0.0 | 5.9.0 | 12.0+ |
| [v4.1.4](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE.md#414) | 2023-12-24 | 15.0.0 | 5.9.0 | 12.0+ |
| [v4.1.3](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE.md#413) | 2023-12-16 | 15.0.0 | 5.9.0 | 12.0+ |
| [v4.1.2](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE.md#412) | 2023-12-02 | 15.0.0 | 5.9.0 | 12.0+ |
| [v4.1.1](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE.md#411) | 2023-11-14 | 15.0.0 | 5.9.0 | 12.0+ |
| [v4.1.0](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE.md#410) | 2023-11-07 | 15.0.0 | 5.9.0 | 12.0+ |
| [v4.0.9](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE.md#409) | 2023-10-22 | 15.0.0 | 5.9.0 | 12.0+ |
| [v4.0.8](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE.md#408) | 2023-10-13 | 15.0.0 | 5.9.0 | 12.0+ |
| [v4.0.7](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE.md#407) | 2023-09-23 | 14.3.0 | 5.7.0 | 12.0+ |
| [v4.0.6](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE.md#406) | 2023-09-09 | 14.3.0 | 5.7.0 | 12.0+ |
| [v4.0.5](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE.md#405) | 2023-08-12 | 14.3.0 | 5.7.0 | 12.0+ |
| [v4.0.4](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE.md#404) | 2023-07-30 | 14.3.0 | 5.7.0 | 12.0+ |
| [v4.0.3](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE.md#403) | 2023-07-06 | 14.3.0 | 5.7.0 | 12.0+ |
| [v4.0.2](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE.md#402) | 2023-06-24 | 14.3.0 | 5.7.0 | 12.0+ | 
| [v4.0.1](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE.md#401) | 2023-06-17 | 14.3.0 | 5.7.0 | 12.0+ | 
| [v4.0.0](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/RELEASE_NOTE.md#400) | 2023-06-15 | 14.3.0 | 5.7.0 | 12.0+ | 

</details>

## Demonstration effect

| Choose a photo | Picture editing | Video editing |  
| ---- | ----  | ---- |
| [![IMAGE ALT TEXT](https://github.com/SilenceLove/PictureMaterial/blob/main/HXPhotoPicker/README/Videos/photo_list_picker_cover.png?raw=true)](http://oss-cn-hangzhou.aliyuncs.com/tsnrhapp/shop/videos/83862ab94facfd8979eb6148094908b2.mp4) | [![IMAGE ALT TEXT](https://github.com/SilenceLove/PictureMaterial/blob/main/HXPhotoPicker/README/Videos/photo_editor_cover.png?raw=true)](http://oss-cn-hangzhou.aliyuncs.com/tsnrhapp/shop/videos/3c81199474e33006e2cebd5f6241ead5.mp4) | [![IMAGE ALT TEXT](https://github.com/SilenceLove/PictureMaterial/blob/main/HXPhotoPicker/README/Videos/video_editor_cover.png?raw=true)](http://oss-cn-hangzhou.aliyuncs.com/tsnrhapp/shop/videos/8c1cf86f32329e6464d327781f15041a.mp4) | 

## Views display

| <img src="https://github.com/SilenceLove/PictureMaterial/blob/main/HXPhotoPicker/README/Photos/sample_graph_photo_picker_list.png?raw=true"> | <img src="https://github.com/SilenceLove/PictureMaterial/blob/main/HXPhotoPicker/README/Photos/sample_graph_photo_preview.png?raw=true"> | <img src="https://github.com/SilenceLove/PictureMaterial/blob/main/HXPhotoPicker/README/Photos/sample_graph_photo_editor_filter.png?raw=true"> | 
| ---- | ----  | ---- |
| <img src="https://github.com/SilenceLove/PictureMaterial/blob/main/HXPhotoPicker/README/Photos/sample_graph_video_editor_time.png?raw=true"> | <img src="https://github.com/SilenceLove/PictureMaterial/blob/main/HXPhotoPicker/README/Photos/sample_graph_video_editor_edit.png?raw=true"> | <img src="https://github.com/SilenceLove/PictureMaterial/blob/main/HXPhotoPicker/README/Photos/sample_graph_video_editor_crop_size.png?raw=true"> |

| <img src="https://github.com/SilenceLove/PictureMaterial/blob/main/HXPhotoPicker/README/Photos/sample_graph_photo_editor_crop_size_horizontal_screen.png?raw=true"> | <img src="https://github.com/SilenceLove/PictureMaterial/blob/main/HXPhotoPicker/README/Photos/sample_graph_video_editor_crop_size_horizontal_screen.png?raw=true"> |
| ---- | ----  |

## License

HXPhotoPicker is released under the MIT license. See LICENSE for details.

## Support❤️
* [**★ Star**](#) this repo.
* Support with 

| <img src="https://github.com/SilenceLove/PictureMaterial/blob/main/HXPhotoPicker/Support/bmc_qr.png?raw=true" width = "135" height = "135" /> | <img src="https://github.com/SilenceLove/PictureMaterial/blob/main/HXPhotoPicker/Support/ap.jpeg?raw=true" width = "100" height = "135.75" />   | <img src="https://github.com/SilenceLove/PictureMaterial/blob/main/HXPhotoPicker/Support/wp.jpeg?raw=true" width = "100" height = "135.75" /> |
| ------ | ------ | ------ | 


## Stargazers over time

[![Stargazers over time](https://starchart.cc/SilenceLove/HXPhotoPicker.svg)](https://starchart.cc/SilenceLove/HXPhotoPicker)

[🔝](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Documentation/README_EN.md#-features)



