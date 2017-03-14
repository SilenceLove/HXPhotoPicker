# HXWeiboPhotoPicker - 仿微博照片选择器
[![Platform](http://img.shields.io/badge/platform-ios-blue.svg?style=flat
             )](https://developer.apple.com/iphone/index.action)
[![Language](http://img.shields.io/badge/language-ObjC-brightgreen.svg?style=flat)](https://developer.apple.com/Objective-C)
[![License](http://img.shields.io/badge/license-MIT-lightgrey.svg?style=flat)](http://mit-license.org)

<img src="http://wx1.sinaimg.cn/mw690/ade10dedgy1fdgf4qs610j20ku112n31.jpg" width="270" height="480"> 

## 一.  特性 - Features

- [x] 查看/选择GIF图片
- [x] 照片、视频可同时多选/原图
- [x] 3DTouch预览照片
- [x] 长按拖动改变顺序
- [x] 自定义相机拍照/录制视频
- [x] 自定义转场动画
- [x] 查看/选择LivePhoto IOS9以上才有用

## 二.  安装 - Installation

- 手动导入：将项目中的“HXWeiboPhotoPicker”文件夹拖入项目中
- 只使用照片选择功能 导入头文件 "HXPhotoViewController.h"
- 选完照片/视频后自动布局功能 导入头文件 "HXPhotoView.h"

## 三.  要求 - Requirements

- iOS8及以上系统可使用. ARC环境. - iOS 8 or later. Requires ARC
- 在Xcode8环境下将项目运行在iOS10的设备/模拟器中，访问相册和相机需要配置两个info.plist文件。                                              Privacy - Photo Library Usage Description 和 Privacy - Camera Usage Description。
- 相机拍照功能请使用真机调试

## 四.  例子 - Examples

- HXPhotoManager 照片管理类相关属性介绍
```
是否把相机功能放在外面 默认 NO   使用 HXPhotoView 时有用
outerCamera;

是否打开相机功能
openCamera;

是否开启查看GIF图片功能 - 默认开启
lookGifPhoto;

是否开启查看LivePhoto功能呢 - 默认开启
lookLivePhoto;

是否一开始就进入相机界面
goCamera;

最大选择数 默认10 - 必填
maxNum;

图片最大选择数 默认9 - 必填
photoMaxNum;

视频最大选择数  默认1 - 必填
videoMaxNum;

图片和视频是否能够同时选择 默认支持
selectTogether;

相册列表每行多少个照片 默认4个
rowCount;
```

- Demo1
```objc
// 懒加载 照片管理类
- (HXPhotoManager *)manager
{
    if (!_manager) {
        _manager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhotoAndVideo];
    }
    return _manager;
}

// 照片选择控制器
HXPhotoViewController *vc = [[HXPhotoViewController alloc] init];
vc.delegate = self;
vc.manager = self.manager; 
[self presentViewController:[[UINavigationController alloc] initWithRootViewController:vc] animated:YES completion:nil];

// 通过 HXPhotoViewControllerDelegate 代理返回选择的图片以及视频
- (void)photoViewControllerDidNext:(NSArray *)allList Photos:(NSArray *)photos Videos:(NSArray *)videos Original:(BOOL)original

// 点击取消
- (void)photoViewControllerDidCancel

```
- Demo2
```objc
// 懒加载 照片管理类
- (HXPhotoManager *)manager
{
    if (!_manager) {
        _manager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhotoAndVideo];
    }
    return _manager;
}

self.navigationController.navigationBar.translucent = NO;
self.automaticallyAdjustsScrollViewInsets = YES;

HXPhotoView *photoView = [[HXPhotoView alloc] initWithFrame:CGRectMake((414 - 375) / 2, 100, 375, 400) WithManager:self.manager];
photoView.delegate = self;
photoView.backgroundColor = [UIColor whiteColor];
[self.view addSubview:photoView];

// 通过 HXPhotoViewDelegate 代理返回 选择、移动顺序、删除之后的图片以及视频
- (void)photoViewChangeComplete:(NSArray *)allList Photos:(NSArray *)photos Videos:(NSArray *)videos Original:(BOOL)isOriginal

// 当 HXPhotoView 更新frame改变大小时
- (void)photoViewUpdateFrame:(CGRect)frame WithView:(UIView *)view

```
- 关于通过 HXPhotoModel 获取照片/视频信息的使用介绍 具体代码还是请下载Demo
```
// 获取照片资源
[photos enumerateObjectsUsingBlock:^(HXPhotoModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
    // 小图  - 这个字段会一直有值
    model.thumbPhoto;

    // 大图  - 这个字段有可能没有值, 只有当查看过大图之后才会有值 - 如果是通过相机拍照的这个字段一直有值跟 thumbPhoto 是一样的
    model.previewPhoto;

    // imageData  - 这个字段有可能没有值, 只有当查看过gif图片之后才会有值 - 通过相机拍照的这个字段没有值
    model.imageData;

    // livePhoto  - 这个字段只有当查看过livePhoto之后才会有值
    model.livePhoto;

    // isCloseLivePhoto 判断当前图片是否关闭了 livePhoto 功能 YES-关闭 NO-开启
    model.isCloseLivePhoto;

    // 获取imageData - 通过相册获取时有用
    [HXPhotoTools FetchPhotoDataForPHAsset:model.asset completion:^(NSData *imageData, NSDictionary *info) {
        NSLog(@"%@",imageData);
    }];

    // 获取image - PHImageManagerMaximumSize 是原图尺寸 - 通过相册获取时有用
    CGSize size = PHImageManagerMaximumSize; // 通过传入 size 的大小来控制图片的质量
    [HXPhotoTools FetchPhotoForPHAsset:model.asset Size:size resizeMode:PHImageRequestOptionsResizeModeFast completion:^(UIImage *image, NSDictionary *info) {
        NSLog(@"%@",image);
    }];

    // 如果是通过相机拍摄的照片只有 thumbPhoto、previewPhoto和imageSize 这三个字段有用可以通过 type 这个字段判断是不是通过相机拍摄的
    if (model.type == HXPhotoModelMediaTypeCameraPhoto);
}];

// 如果是相册选取的视频 要获取视频URL 必须先将视频压缩写入文件,得到的文件路径就是视频的URL 如果是通过相机录制的视频那么 videoURL 这个字段就是视频的URL 可以看需求看要不要压缩
[videos enumerateObjectsUsingBlock:^(HXPhotoModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
    // 视频封面
    model.thumbPhoto;

    // previewPhoto 这个也是视频封面 如果是在相册选择的视频 这个字段有可能没有值,只有当用户通过3DTouch 预览过之后才会有值 而且比 thumbPhoto 清晰  如果视频是通过相机拍摄的视频 那么 previewPhoto 这个字段跟 thumbPhoto 是同一张图片也是比较清晰的
    model.previewPhoto;

    // 如果是通过相机录制的视频 需要通过 model.VideoURL 这个字段来压缩写入文件
    if (model.type == HXPhotoModelMediaTypeCameraVideo) {
        [self compressedVideoWithURL:model.videoURL success:^(NSString *fileName) {
            NSLog(@"%@",fileName); // 视频路径也是视频URL;
        } failure:^{
            // 压缩写入失败
        }];
    }else { // 如果是在相册里面选择的视频就需要用过 model.avAsset 这个字段来压缩写入文件
        [self compressedVideoWithURL:model.avAsset success:^(NSString *fileName) {
            NSLog(@"%@",fileName); // 视频路径也是视频URL;
        } failure:^{
            // 压缩写入失败
        }];
    }
}];

// 判断照片、视频 或 是否是通过相机拍摄的
[allList enumerateObjectsUsingBlock:^(HXPhotoModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
    if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
        // 通过相机录制的视频
    }else if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
        // 通过相机拍摄的照片
    }else if (model.type == HXPhotoModelMediaTypePhoto) {
        // 相册里的照片
    }else if (model.type == HXPhotoModelMediaTypePhotoGif) {
        // 相册里的GIF图
    }else if (model.type == HXPhotoModelMediaTypeLivePhoto) {
        // 相册里的livePhoto
    }
}];
```
## 五.  更新历史 - Update History

- 2017-03-07  修复通过相机拍照时照片旋转90°的问题
- 2017-03-08  修复拍照之后,在浏览大图时选中图片,列表界面Cell没有选中的问题
- 2017-03-09  添加查看 LivePhoto 功能、是否查看GIF图和LivePhoto的控制开关,修复Cell重复注册3DTouch功能导致内存一直增加问题
- 2017-03-10  添加控制是否开启相机功能的开关 以及 控制相机功能是否内/外置开关.
- 2017-03-11  通过相机拍照和录制视频之后的长照片、长视频裁剪成正方形以及修复一些小问题
- 2017-03-13  修复自定义相机bug、优化相机照片访问权限问题

## 六.  更多 - More

- 如果您发现了bug请尽可能详细地描述系统版本、手机型号和复现步骤等信息 提一个issue.

- 如果您有什么好的建议也可以提issue,大家一起讨论一起学习进步...

- 具体代码请下载项目  如果觉得喜欢的能给一颗小星星么!  ✨✨✨
 
- QQ : 294005139<a target="_blank" href="http://wpa.qq.com/msgrd?v=3&uin=294005139&site=qq&menu=yes"><img border="0" src="http://wpa.qq.com/pa?p=2:294005139:52" alt="点击这里给我发消息" title="点击这里给我发消息"/></a>
  
- [有兴趣可以加下刚刚创建的QQ群:531895229](//shang.qq.com/wpa/qunwpa?idkey=ebd8d6809c83b4d6b4a18b688621cb73ded0cce092b4d1f734e071a58dd37c26) 
