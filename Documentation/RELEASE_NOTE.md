# Release Notes

## 4.2.1

### Resolved

- [[691]](https://github.com/SilenceLove/HXPhotoPicker/issues/691)
- [[690]](https://github.com/SilenceLove/HXPhotoPicker/issues/690)
- [[686]](https://github.com/SilenceLove/HXPhotoPicker/issues/686)
- [[681]](https://github.com/SilenceLove/HXPhotoPicker/issues/681)

## 4.2.0

### Add

- add .xcprivacy file for privacy api's

### Resolved

- [[663]](https://github.com/SilenceLove/HXPhotoPicker/issues/663)
- [[660]](https://github.com/SilenceLove/HXPhotoPicker/issues/660)
- [[659]](https://github.com/SilenceLove/HXPhotoPicker/issues/659)

## 4.1.9

### Resolved

- [[663]](https://github.com/SilenceLove/HXPhotoPicker/issues/663)
- [[660]](https://github.com/SilenceLove/HXPhotoPicker/issues/660)
- [[659]](https://github.com/SilenceLove/HXPhotoPicker/issues/659)
- [[654]](https://github.com/SilenceLove/HXPhotoPicker/issues/654)
- [[653]](https://github.com/SilenceLove/HXPhotoPicker/issues/653)
- [[649]](https://github.com/SilenceLove/HXPhotoPicker/issues/649)
- [[647]](https://github.com/SilenceLove/HXPhotoPicker/issues/647)
- [[646]](https://github.com/SilenceLove/HXPhotoPicker/issues/646)
- [[644]](https://github.com/SilenceLove/HXPhotoPicker/issues/644)

## 4.1.8

### Resolved

- [[642]](https://github.com/SilenceLove/HXPhotoPicker/issues/642)
- [[641]](https://github.com/SilenceLove/HXPhotoPicker/issues/641)
- [[640]](https://github.com/SilenceLove/HXPhotoPicker/issues/640)
- [[635]](https://github.com/SilenceLove/HXPhotoPicker/issues/635)
- [[634]](https://github.com/SilenceLove/HXPhotoPicker/issues/634)
- [[633]](https://github.com/SilenceLove/HXPhotoPicker/issues/633)

## 4.1.7

### Resolved

- [[632]](https://github.com/SilenceLove/HXPhotoPicker/issues/632)
- [[598]](https://github.com/SilenceLove/HXPhotoPicker/issues/598)

## 4.1.6

### Added

- All icons can be customized with `HX.ImageResource`
- All text content can be customized with `HX.TextManager`

- Picker
  - Set theme color with one click`config.themeColor = .systemBlue`[[620]](https://github.com/SilenceLove/HXPhotoPicker/issues/620)
  - `PhotoAsset` adds `size` that can specify `UIImage`(https://github.com/SilenceLove/HXPhotoPicker/issues/624)
  ```
    /// targetSize: specify imageSize
    /// targetMode: crop mode
    let image = try await photoAsset.image(targetSize: .init(width: 200, height: 200), targetMode: .fill)
  ```
  - `PhotoAsset`Added content for display
  ``` 
    let thumImage = try await photoAsset.requesThumbnailImage() 
    let previewImage = try await photoAsset.requestPreviewImage() 
    let avAsset = try await photoAsset.requestAVAsset() 
    let playerItem = try await photoAsset.requestPlayerItem() 
    let livePhoto = try await photoAsset.requestLivePhoto()
  ```

- Camera
  - Camera screen size can be customized`config.aspectRatio = ._9x16`
  
### Resolved

- Editor
  - After using the circular cropping box and rotating the crop, the content is offset when entering the editing interface again.
  
### Optimizer

- Picker
  - Quick slide display effect

## 4.1.5

### Resolved

- [[618]](https://github.com/SilenceLove/HXPhotoPicker/issues/618)
- [[616]](https://github.com/SilenceLove/HXPhotoPicker/issues/616)
- [[614]](https://github.com/SilenceLove/HXPhotoPicker/issues/614)

## 4.1.4

### Resolved

- [[613]](https://github.com/SilenceLove/HXPhotoPicker/issues/613)
- [[612]](https://github.com/SilenceLove/HXPhotoPicker/issues/612)
- [[610]](https://github.com/SilenceLove/HXPhotoPicker/issues/610)
- [[591]](https://github.com/SilenceLove/HXPhotoPicker/issues/591)

## 4.1.3

### Resolved

- Picker
  - The list at the bottom of the preview interface may be messed up
- [[605]](https://github.com/SilenceLove/HXPhotoPicker/issues/605)
- [[599]](https://github.com/SilenceLove/HXPhotoPicker/issues/599)

## 4.1.2

### Added

- Picker
  - `PhotoToolbar` of photo list supports displaying selected list view
  - `PhotoToolbar` in the preview interface adds a list view of preview data

### Resolved

- Picker
  - When the original image is selected, quickly selecting/deselecting photos may cause a crash.
  - When the album permissions restrict some photos, switching the album after selecting the photos causes the number displayed in the `PhotoToolbar` to be incorrect.
  - The album list may be blank
  - The problem of obtaining the wrong address suffix name when GIF is displayed as a static image
  - Modification of the judgment logic of the maximum number of choices
  
### Optimizer

- Picker
  - `PhotoToolbar` safe area distance alignment when horizontal screen
  - The logic of loading images in the preview interface is optimized, and the images are clearer during initial loading.

## 4.1.1

### Added

- Editor
  - Added `Highlight`, `Shadow` and `Color Temperature` effects to the picture adjustment
  
### Resolved
    
- [[593]](https://github.com/SilenceLove/HXPhotoPicker/issues/593)
- [[589]](https://github.com/SilenceLove/HXPhotoPicker/issues/589)
- and some known issues

## 4.1.0

### Added

- Editor
  - The sticker list supports customization and implements the protocol `EditorChartletListProtocol`

### Resolved

- Picker
  - Multiple quick gesture returns may cause the interface to become unresponsive.
  
- [[593]](https://github.com/SilenceLove/HXPhotoPicker/issues/593)
- [[592]](https://github.com/SilenceLove/HXPhotoPicker/issues/592)

## 4.0.9

### Added

- Picker
  - Added new album list presentation method `present(UIModalPresentationStyle)`
  - Album list UI modification, support customization, implement protocol `PhotoAlbumController`
  - The album list and photo list navigation bar buttons support customization and implement the protocol `PhotoNavigationItem`
  - `PhotoBrowser` adds new language configuration [[584]](https://github.com/SilenceLove/HXPhotoPicker/issues/584)
  - Add highlight state to button
  
### Resolved

- Picker
  - There is no response when clicking `PhotoToolbar` on low-version systems [[587]](https://github.com/SilenceLove/HXPhotoPicker/issues/587)
- Editor
    - Edit video crash [[580]](https://github.com/SilenceLove/HXPhotoPicker/issues/580)
    - Rotation may crash while painting
- and fixed some minor issues

### Optimizer

- Optimized some code

## 4.0.8

### Added

- Picker
  - Support `UISplitViewController`, used by `iPad` by default
  - The photo album list supports customization and implements the protocol `PhotoAlbumList`
  - The photo list title bar supports customization and implements the protocol `PhotoPickerTitle`
  - The photo list view supports customization and implements the protocol `PhotoPickerList`

### Resolved

- Fixed some minor issues

## 4.0.7

### Added

- Picker
  - The bottom view of the photo list and preview interface supports customization. You only need to implement the methods in the `PhotoToolBar` protocol and assign it to the `photoToolbar` of the configuration class.
- Editor
  - The drawing function `iOS 13.0` and above is replaced by `PencilKit`

## 4.0.6

### Added

- Editor
  - When the original ratio is selected, you can switch between horizontal and vertical states.

### Resolved

- Picker
  - When the album permission is not authorized, the cancellation callback is not triggered.
- Some issues on Mac Catalyst

### Optimizer

- The problem of long compilation time under Release [[564]](https://github.com/SilenceLove/HXPhotoPicker/issues/564)

## 4.0.5.1

### Resolved

- Low version Xcode compilation error [[571]](https://github.com/SilenceLove/HXPhotoPicker/issues/571)

## 4.0.5

### Added

- Picker
  - `NetworkImageAsset` adds `CacheKey` property
  - Obtaining the URL supports specifying the path

### Optimizer

- Picker
  - Gesture sliding selection is enabled by default, and the sliding selection function is optimized
- Editor
  - iPad interface layout adjustment

## 4.0.4

### Added
  
- Editor
  - `config.buttonPostion` adds configuration: the position of the cancel/finish button when the screen is vertical
- Camera
  - `config.isSaveSystemAlbum` added configuration: save to the system album after taking pictures

### Optimizer

- Picker
  - Preview interface gesture return optimization
- Editor 
  - layout optimization

### Resolved

- [[553]](https://github.com/SilenceLove/HXPhotoPicker/issues/553)
- [[558]](https://github.com/SilenceLove/HXPhotoPicker/issues/558)
- [[562]](https://github.com/SilenceLove/HXPhotoPicker/issues/562)
- [[567]](https://github.com/SilenceLove/HXPhotoPicker/issues/567)
- [[568]](https://github.com/SilenceLove/HXPhotoPicker/issues/568)

## 4.0.3

### Added

- Picker
  - `PhotoManager.shared.isConverHEICToPNG = true`Automatically convert HEIC format to PNG format internally
  - `config.isSelectedOriginal`Control whether to select the original image button
  - `config.isDeselectVideoRemoveEdited`Whether to clear the edited content when the video is deselected
  - When adding network resources, images support configuration `Kingfisher.ImageDownloader`:`PhotoManager.shared.imageDownloader`, video uses `AVURLAsset` to set `options`

### Optimizer

- Picker
  - Internal logic optimization when `async/await` gets
  - Swipe selection effect optimization
- Editor
  - Optimizing the continuous sliding logic of the angle ruler

## 4.0.2

### Added

- Picker
  - Add filtering function to the photo list, `config.photoList.isShowFilterItem` controls whether to display the filter button
  - The selected view at the bottom of the preview interface supports dragging to change the position

### Optimizer

- Picker
  - When the photo format is `HEIC`, the suffix of the original image address is also consistent

### Resolved

- Picker
  - The prompt text does not wrap when the photo list is empty
- Editor
  - Left and right 90° rotation complete callback not triggered
  - It may not work when clicking restore when dragging the angle scale scrolling does not stop
  
## 4.0.1

### Resolved

- Picker
  - When `disableFinishButtonWhenNotSelected` is set to `true` and the maximum number of videos is 1, the preview interface cannot select a video
  - When the preview interface selects a video that exceeds the maximum duration, the maximum duration is not set when jumping to the editor, resulting in a constant cycle of editing logic
- Editor
  - The video orientation was not corrected when editing the video recorded by the original camera of the system

## 4.0.0

- Fixed some issues
- Editor optimization refactoring
