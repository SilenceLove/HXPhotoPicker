# Release Notes

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
