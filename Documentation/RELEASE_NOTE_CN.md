# 更新日志

## 4.0.3

### 新增

- Picker
  - `PhotoManager.shared.isConverHEICToPNG = true`内部自动将HEIC格式转换成PNG格式
  - `config.isSelectedOriginal`控制是否选中原图按钮
  - `config.isDeselectVideoRemoveEdited`取消选择视频时，是否清空已编辑的内容
  - 添加网络资源时，图片支持配置`Kingfisher.ImageDownloader`:`PhotoManager.shared.imageDownloader`、视频使用`AVURLAsset`可设置`options`

### 优化

- Picker
  - `async/await`获取时内部逻辑优化
  - 滑动选择效果优化
- Editor
  - 角度尺连续滑动逻辑优化

## 4.0.2

### 新增

- Picker
  - 照片列表添加筛选功能，`config.photoList.isShowFilterItem`控制是否显示筛选按钮
  - 预览界面底部已选视图支持拖拽更换位置

### 优化

- Picker
  - 当照片格式为`HEIC`时，获取原图地址的后缀也保持一致

### 修复

- Picker
  - 当照片列表为空时的提示语没有换行
- Editor
  - 左右90°旋转完成回调未触发
  - 拖动角度刻度滚动未停止时点击还原时可能无效

## 4.0.1

### 修复

- Picker
  - 设置`disableFinishButtonWhenNotSelected`为`true`并且视频最大数为1时，预览界面无法选择视频
  - 预览界面选择超过最大时长的视频时跳转编辑器时未设置最大时长导致一直循环编辑逻辑
- Editor
  - 编辑系统原相机录制的视频时未修正视频方向

## 4.0.0

- 纯Swift编写
- 修复了一些问题
- 编辑器优化重构

## 3.0

- [Object-C版本](https://github.com/SilenceLove/HXPhotoPickerObjC)
