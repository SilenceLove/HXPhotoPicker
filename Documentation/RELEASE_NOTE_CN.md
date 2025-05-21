# 更新日志
    
## 5.0.2

### 修复

- [[797]](https://github.com/SilenceLove/HXPhotoPicker/issues/797)
- [[792]](https://github.com/SilenceLove/HXPhotoPicker/issues/792)

## 5.0.1

### 新增

- 西班牙、葡萄牙语言

### 修复

- [[787]](https://github.com/SilenceLove/HXPhotoPicker/issues/787) 
- [[784]](https://github.com/SilenceLove/HXPhotoPicker/issues/784)  
- [[782]](https://github.com/SilenceLove/HXPhotoPicker/issues/782) 
- [[777]](https://github.com/SilenceLove/HXPhotoPicker/issues/777)
- [[776]](https://github.com/SilenceLove/HXPhotoPicker/issues/776)
- [[775]](https://github.com/SilenceLove/HXPhotoPicker/issues/775)

## 5.0.0

- 最低系统版本修改为`iOS 10`
- 默认不支持GIF图片、网络图片加载支持自定义[HXImageViewProtocol](https://github.com/SilenceLove/HXPhotoPicker/blob/master/Sources/HXPhotoPicker/Core/Config/HXImageViewProtocol.swift)
  - [GIF](https://github.com/SilenceLove/HXPhotoPicker/tree/master/Sources/ImageView/GIFImageView.swift)
  - [Kingfisher](https://github.com/SilenceLove/HXPhotoPicker/tree/master/Sources/ImageView/KFImageView.swift)
  - [SDWebImage](https://github.com/SilenceLove/HXPhotoPicker/tree/master/Sources/ImageView/SDImageView.swift)
- 优化RLT布局
  
## 4.2.5

### 修复

- [[766]](https://github.com/SilenceLove/HXPhotoPicker/issues/766)
- [[754]](https://github.com/SilenceLove/HXPhotoPicker/issues/754)
- [[751]](https://github.com/SilenceLove/HXPhotoPicker/issues/751)

## 4.2.4

### 新增

- 最低系统版本升级为`iOS 13`
- `Kingfisher`升级为`8.0`

## 4.2.3.2

### 修复

- [[727]](https://github.com/SilenceLove/HXPhotoPicker/issues/727)
- [[730]](https://github.com/SilenceLove/HXPhotoPicker/issues/730)
- [[731]](https://github.com/SilenceLove/HXPhotoPicker/issues/731)
- [[732]](https://github.com/SilenceLove/HXPhotoPicker/issues/732)

## 4.2.3.1

### 修复

- picker
  - 权限受限时系统相册更新后未同步

## 4.2.3

### 新增

- Camera
  - 相机界面支持自定义`CameraViewControllerProtocol`

### 修复

- picker
  - 系统相册删除照片后可能未同步

- Editor
  - 旋转、镜像时可能无效

## 4.2.2

### 修复

- [[705]](https://github.com/SilenceLove/HXPhotoPicker/issues/705)

## 4.2.1

### 修复

- [[691]](https://github.com/SilenceLove/HXPhotoPicker/issues/691)
- [[690]](https://github.com/SilenceLove/HXPhotoPicker/issues/690)
- [[686]](https://github.com/SilenceLove/HXPhotoPicker/issues/686)
- [[681]](https://github.com/SilenceLove/HXPhotoPicker/issues/681)

## 4.2.0

### 新增

- 隐私 api 添加 .xcprivacy 文件

### 修复

- [[663]](https://github.com/SilenceLove/HXPhotoPicker/issues/663)
- [[660]](https://github.com/SilenceLove/HXPhotoPicker/issues/660)
- [[659]](https://github.com/SilenceLove/HXPhotoPicker/issues/659)

## 4.1.9

### 修复

- [[654]](https://github.com/SilenceLove/HXPhotoPicker/issues/654)
- [[653]](https://github.com/SilenceLove/HXPhotoPicker/issues/653)
- [[649]](https://github.com/SilenceLove/HXPhotoPicker/issues/649)
- [[647]](https://github.com/SilenceLove/HXPhotoPicker/issues/647)
- [[646]](https://github.com/SilenceLove/HXPhotoPicker/issues/646)
- [[644]](https://github.com/SilenceLove/HXPhotoPicker/issues/644)

## 4.1.8

### 修复

- [[642]](https://github.com/SilenceLove/HXPhotoPicker/issues/642)
- [[641]](https://github.com/SilenceLove/HXPhotoPicker/issues/641)
- [[640]](https://github.com/SilenceLove/HXPhotoPicker/issues/640)
- [[635]](https://github.com/SilenceLove/HXPhotoPicker/issues/635)
- [[634]](https://github.com/SilenceLove/HXPhotoPicker/issues/634)
- [[633]](https://github.com/SilenceLove/HXPhotoPicker/issues/633)

## 4.1.7

### 修复

- [[632]](https://github.com/SilenceLove/HXPhotoPicker/issues/632)
- [[598]](https://github.com/SilenceLove/HXPhotoPicker/issues/598)

## 4.1.6

### 新增

- 所有图标可自定义`HX.ImageResource`
- 所有文本内容可自定义`HX.TextManager`

- Picker
  - 一键设置主题色`config.themeColor = .systemBlue`[[620]](https://github.com/SilenceLove/HXPhotoPicker/issues/620)
  - `PhotoAsset`新增可指定`UIImage`的`size`[[624]](https://github.com/SilenceLove/HXPhotoPicker/issues/624)
  ```
    /// targetSize: 指定imageSize
    /// targetMode: 裁剪模式
    let image = try await photoAsset.image(targetSize: .init(width: 200, height: 200), targetMode: .fill)
  ```
  - `PhotoAsset`新增获取用于展示的内容
  ```
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

- Camera
  - 相机画面大小可以自定义`config.aspectRatio = ._9x16`
  
### 修复

- Editor
  - 使用圆形裁剪框并且旋转裁剪后，再次进入编辑界面内容偏移的问题
  
### 优化

- Picker
  - 快速滑动显示效果

## 4.1.5

### 修复

- [[618]](https://github.com/SilenceLove/HXPhotoPicker/issues/618)
- [[616]](https://github.com/SilenceLove/HXPhotoPicker/issues/616)
- [[614]](https://github.com/SilenceLove/HXPhotoPicker/issues/614)

## 4.1.4

### 修复

- [[613]](https://github.com/SilenceLove/HXPhotoPicker/issues/613)
- [[612]](https://github.com/SilenceLove/HXPhotoPicker/issues/612)
- [[610]](https://github.com/SilenceLove/HXPhotoPicker/issues/610)
- [[591]](https://github.com/SilenceLove/HXPhotoPicker/issues/591)

## 4.1.3

### 修复

- Picker
  - 预览界面底部列表可能错乱的问题
- [[605]](https://github.com/SilenceLove/HXPhotoPicker/issues/605)
- [[599]](https://github.com/SilenceLove/HXPhotoPicker/issues/599)

## 4.1.2

### 新增

- Picker
  - 照片列表的`PhotoToolbar`支持显示已选择的列表视图
  - 预览界面的`PhotoToolbar`新增预览数据的列表视图

### 修复

- Picker
  - 选中原图时，快速选择/取消选择照片可能会导致崩溃的问题
  - 当相册权限限制部分照片时，选择照片之后切换相册导致`PhotoToolbar`显示的数量出错的问题
  - 相册列表可能会空白的问题
  - 当gif显示为静态图时获取地址后缀名错误的问题
  - 最大选择数的判断逻辑修改
  
### 优化

- Picker
  - `PhotoToolbar`横屏时安全区域距离对齐
  - 预览界面加载图片的逻辑优化，初始加载时图片更加清晰

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
