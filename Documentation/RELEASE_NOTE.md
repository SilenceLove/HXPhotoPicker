# Release Notes

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
