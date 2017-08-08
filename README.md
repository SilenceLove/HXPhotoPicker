# HXWeiboPhotoPicker - 仿微博照片选择器<p>如有遇到问题请先下载最新版</p>
[![Platform](http://img.shields.io/badge/platform-ios-blue.svg?style=flat
             )](https://developer.apple.com/iphone/index.action)
[![Language](http://img.shields.io/badge/language-ObjC-brightgreen.svg?style=flat)](https://developer.apple.com/Objective-C)
[![License](http://img.shields.io/badge/license-MIT-lightgrey.svg?style=flat)](http://mit-license.org)

<img src="http://wx1.sinaimg.cn/mw690/ade10dedgy1fdgf4qs610j20ku112n31.jpg" width="270" height="480"> 

## 最新支持浏览网络图片
## 一.  特性 - Features

- [x] 查看/选择GIF图片
- [x] 照片、视频可同时多选/原图
- [x] 3DTouch预览照片
- [x] 长按拖动改变顺序
- [x] 自定义相机拍照/录制视频
- [x] 自定义转场动画
- [x] 查看/选择LivePhoto IOS9.1以上才有用
- [x] 支持浏览网络图片
- [x] 支持裁剪图片
- [x] 观察系统相册变化实时增删

## 二.  安装 - Installation

- Cocoapods：pod 'HXWeiboPhotoPicker' '~> 1.2' pod的版本为浏览网络图片之前的版本(不包含浏览网络图片) // 暂时不支持
- 手动导入：将项目中的“HXWeiboPhotoPicker”文件夹拖入项目中
- 只使用照片选择功能 导入头文件 "HXPhotoViewController.h"
- 选完照片/视频后自动布局功能 导入头文件 "HXPhotoView.h"

## 三.  要求 - Requirements

- iOS8及以上系统可使用. ARC环境. - iOS 8 or later. Requires ARC
- 在Xcode8环境下将项目运行在iOS10的设备/模拟器中，访问相册和相机需要配置三个info.plist文件。                                              Privacy - Photo Library Usage Description 和 Privacy - Camera Usage Description 以及 Privacy - Microphone Usage Description。
- 相机拍照功能请使用真机调试

## 四.  例子 - Examples

- HXPhotoManager 照片管理类相关属性介绍
```
/**
 *  拍摄的 照片/视频 是否保存到系统相册  默认NO 此功能需要配合 监听系统相册 和 缓存相册 功能 (请不要关闭)
 */
BOOL saveSystemAblum;

/**
 *  视频能选择的最大秒数  -  默认 5分钟/300秒
 */
NSTimeInterval videoMaxDuration;

/**
 *  是否缓存相册, manager会监听系统相册变化(需要此功能时请不要关闭监听系统相册功能)   默认YES
 */
BOOL cacheAlbum;

/**
 *  是否监听系统相册     默认 YES
 */
BOOL monitorSystemAlbum;

/**
 是否为单选模式 默认 NO
 */
BOOL singleSelected;

/**
 单选模式下是否需要裁剪  默认YES
 */
BOOL singleSelecteClip;

/**
 是否开启3DTouch预览功能 默认打开
 */
BOOL open3DTouchPreview;

/**
 显示全屏相机 //  默认 NO
 */
BOOL showFullScreenCamera;

/**
 删除网络图片时是否显示Alert // 默认不显示
 */
BOOL showDeleteNetworkPhotoAlert;

/**
 网络图片地址数组
 */
NSMutableArray *networkPhotoUrls;

/**
 是否把相机功能放在外面 默认 NO   使用 HXPhotoView 时有用
 */
BOOL outerCamera;

/**
 是否打开相机功能
 */
BOOL openCamera;

/**
 是否开启查看GIF图片功能 - 默认开启
 */
BOOL lookGifPhoto;

/**
 是否开启查看LivePhoto功能呢 - 默认开启
 */
BOOL lookLivePhoto;

/**
 是否一开始就进入相机界面
 */
BOOL goCamera;

/**
 最大选择数 等于 图片最大数 + 视频最大数 默认10 - 必填
 */
NSInteger maxNum;

/**
 图片最大选择数 默认9 - 必填
 */
NSInteger photoMaxNum;

/**
 视频最大选择数 // 默认1 - 必填
 */
NSInteger videoMaxNum;

/**
 图片和视频是否能够同时选择 默认支持
 */
BOOL selectTogether;

/**
 相册列表每行多少个照片 默认4个 iphone 4s / 5  默认3个
 */
NSInteger rowCount;
```

- Demo1
```objc
// 懒加载 照片管理类
- (HXPhotoManager *)manager {
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
- (HXPhotoManager *)manager {
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

// 代理返回 选择、移动顺序、删除之后的图片以及视频
- (void)photoView:(HXPhotoView *)photoView changeComplete:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photos videos:(NSArray<HXPhotoModel *> *)videos original:(BOOL)isOriginal;

// 当view更新高度时调用
- (void)photoView:(HXPhotoView *)photoView updateFrame:(CGRect)frame;

// 删除网络图片的地址
- (void)photoView:(HXPhotoView *)photoView deleteNetworkPhoto:(NSString *)networkPhotoUrl;

// 网络图片全部下载完成时调用
- (void)photoViewAllNetworkingPhotoDownloadComplete:(HXPhotoView *)photoView;
```
- 关于通过 HXPhotoModel 获取照片UIImage对象 具体代码还是请下载Demo
```
HXPhotoTools提供一个方法可以根据传入的模型数组转换成图片(UIImage)数组 

type是个枚举
HXPhotoToolsFetchHDImageType = 0, // 高清
HXPhotoToolsFetchOriginalImageTpe, // 原图

[HXPhotoTools getImageForSelectedPhoto:photos type:HXPhotoToolsFetchHDImageType completion:^(NSArray<UIImage    *> *images) {
    NSSLog(@"%@",images);
    for (UIImage *image in images) {
        if (image.images.count > 0) {
            // 到这里了说明这个image  是个gif图
        }
    }
}];
```
## 五.  更新历史 - Update History

- 2017-03-07　　修复通过相机拍照时照片旋转90°的问题
- 2017-03-08　　修复拍照之后,在浏览大图时选中图片,列表界面Cell没有选中的问题
- 2017-03-09　　添加查看 LivePhoto 功能、是否查看GIF图和LivePhoto的控制开关,修复Cell重复注册3DTouch功能导致内存一直增加问题
- 2017-03-10　　添加控制是否开启相机功能的开关 以及 控制相机功能是否内/外置开关.
- 2017-03-11　　通过相机拍照和录制视频之后的长照片、长视频裁剪成正方形以及修复一些小问题
- 2017-03-13　　修复自定义相机bug、优化相机照片访问权限问题
- 2017-03-22　　修复最大数限制问题
- 2017-03-29　　解决裁剪视频时声音丢失问题、优化了快速滑动内存问题、添加获取选中数组里面图片的原图和imageData的方法
- 2017-05-20　　添加支持传入网络图片Url数组后进行浏览查看并删除
- 2017-05-24　　修复传入网络图片之后添加按钮错误显示问题。添加全屏相机/开关控制
- 2017-06-02　　修复在预览时取消选中时的问题
- 2017-06-26　　合并一些方法、删除无用方法
- 2017-07-01　　添加单选样式、支持裁剪图片
- 2017-07-05　　解决同一界面多个选择器界面跳转问题,拍摄视频完成时遗留问题
- 2017-07-26　　优化cell性能、3DTouch预览内存消耗。添加是否需要裁剪框属性、刷新界面方法以及拍照/选择照片完之后跳界面Demo
- 2017-08-08　　添加国际化支持英文、保存拍摄的照片/视频到系统相册、实时监听系统相册变化并改变、缓存相册、针对ios10和iphone4s/5s优化列表滑动、选择视频时限制超过指定秒数不能选。以及一些小问题

## 六.  更多 - More
 
- 关于自定义化和支持横屏功能正在准备当中...

- 如果您发现了bug请尽可能详细地描述系统版本、手机型号和复现步骤等信息 提一个issue.

- 如果您有什么好的建议也可以提issue,大家一起讨论一起学习进步...

- 具体代码请下载项目  如果觉得喜欢的能给一颗小星星么!  ✨✨✨
 
- QQ : 294005139<a target="_blank" href="http://wpa.qq.com/msgrd?v=3&uin=294005139&site=qq&menu=yes"><img border="0" src="http://wpa.qq.com/pa?p=2:294005139:52" alt="点击这里给我发消息" title="点击这里给我发消息"/></a>

- 如果觉得的不行，麻烦请多包涵。(真实工作经验1年3个月-2017.08.08)

- [有兴趣可以加下创建的QQ群:531895229](//shang.qq.com/wpa/qunwpa?idkey=ebd8d6809c83b4d6b4a18b688621cb73ded0cce092b4d1f734e071a58dd37c26) 
