# 更新日志 

## 4.1.1

### 新增

- Editor
  - 画面调整新增`高光`、`阴影`、`色温`效果
  
### 修复
    
- [[593]](https://github.com/SilenceLove/HXPhotoPicker/issues/593)
- [[589]](https://github.com/SilenceLove/HXPhotoPicker/issues/589)
- 以及一些已知问题

## 4.1.0

### 新增

- Editor
  - 贴纸列表支持自定义，实现协议`EditorChartletListProtocol`

### 修复

- Picker
  - 多次快速手势返回可能导致界面无响应的问题
  
- [[593]](https://github.com/SilenceLove/HXPhotoPicker/issues/593)
- [[592]](https://github.com/SilenceLove/HXPhotoPicker/issues/592)

## 4.0.9

### 新增

- Picker
  - 新增相册列表展现方式 `present(UIModalPresentationStyle)`
  - 相册列表UI修改，支持自定义，实现协议`PhotoAlbumController`
  - 相册列表、照片列表导航栏按钮支持自定义，实现协议`PhotoNavigationItem`
  - `PhotoBrowser`新增语言配置[[584]](https://github.com/SilenceLove/HXPhotoPicker/issues/584)
  - 按钮添加高亮状态
  
### 修复

- Picker
  - 低版本系统点击`PhotoToolbar`没反应 [[587]](https://github.com/SilenceLove/HXPhotoPicker/issues/587)
- Editor
    - 编辑视频崩溃 [[580]](https://github.com/SilenceLove/HXPhotoPicker/issues/580)
    - 绘画时旋转可能会崩溃
- 以及修复了一些小问题

### 优化

- 优化了一些代码

## 4.0.8

### 新增

- Picker
  - 支持`UISplitViewController`，`iPad`默认使用
  - 相册列表支持自定义，实现协议`PhotoAlbumList`
  - 照片列表标题栏支持自定义，实现协议`PhotoPickerTitle`
  - 照片列表视图支持自定义，实现协议`PhotoPickerList`

### 修复

- 解决了一些小问题

## 4.0.7

### 新增

- Picker
  - 照片列表、预览界面的底部视图支持自定义，只需实现`PhotoToolBar`协议里的方法然后赋值给配置类的`photoToolbar`即可
- Editor
  - 绘画功能`iOS 13.0`以上更换为`PencilKit`

## 4.0.6

### 新增

- Editor
  - 选中原始比例时，可以切换横竖状态

### 修复

- Picker
  - 相册权限未授权时，取消回调没有触发 
- Mac Catalyst 上的一些问题

### 优化

- Release下编译时间过长的问题 [[564]](https://github.com/SilenceLove/HXPhotoPicker/issues/564)

## 4.0.5.1

### 修复

- 低版本Xcode编译报错 [[571]](https://github.com/SilenceLove/HXPhotoPicker/issues/571)

## 4.0.5

### 新增

- Picker
  - `NetworkImageAsset`增加`CacheKey`属性
  - 获取URL支持指定路径

### 优化

- Picker
  - 默认开启手势滑动选择，滑动选择功能优化
- Editor
  - iPad界面布局调整

## 4.0.4

### 新增
  
- Editor
  - `config.buttonPostion`添加配置：竖屏时，取消/完成按钮的位置
- Camera
  - `config.isSaveSystemAlbum`添加配置：拍照完成后保存到系统相册

### 优化

- Picker
  - 预览界面手势返回优化
- Editor 
  - 布局优化

### 修复

- [[553]](https://github.com/SilenceLove/HXPhotoPicker/issues/553)
- [[558]](https://github.com/SilenceLove/HXPhotoPicker/issues/558)
- [[562]](https://github.com/SilenceLove/HXPhotoPicker/issues/562)
- [[567]](https://github.com/SilenceLove/HXPhotoPicker/issues/567)
- [[568]](https://github.com/SilenceLove/HXPhotoPicker/issues/568)

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
