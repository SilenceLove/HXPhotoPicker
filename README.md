# HXWeiboPhotoPicker - 仿微博照片选择器<p>如有遇到问题请先下载最新版</p>
[![Platform](http://img.shields.io/badge/platform-ios-blue.svg?style=flat
             )](https://developer.apple.com/iphone/index.action)
[![Pod Version](http://img.shields.io/cocoapods/v/HXWeiboPhotoPicker.svg?style=flat)](http://cocoadocs.org/docsets/HXWeiboPhotoPicker/)
[![Language](http://img.shields.io/badge/language-ObjC-brightgreen.svg?style=flat)](https://developer.apple.com/Objective-C)
[![License](http://img.shields.io/badge/license-MIT-lightgrey.svg?style=flat)](http://mit-license.org)

<img src="http://wx1.sinaimg.cn/mw690/ade10dedgy1fdgf4qs610j20ku112n31.jpg" width="270" height="480"> <img src="https://user-images.githubusercontent.com/18083149/30411283-90f6cf8e-9942-11e7-8f21-6de1ca434cc5.PNG" width="270" height="480"> <img src="https://user-images.githubusercontent.com/18083149/30411216-3dc719ea-9942-11e7-8d1e-24e6d7a9b011.PNG" width="270" height="480">
<img src="https://user-images.githubusercontent.com/18083149/30411300-a67b52c6-9942-11e7-96cc-a05727d109af.png" width="854" height="336">

## 目录
* [项目特性](#特性)
* [安装方式](#安装)
* [使用要求](#要求)
* [更新记录](#更新历史)
* [属性介绍](#属性介绍)
	* [HXPhotoManager](#HXPhotoManager)
	* [HXPhotoUIManager](#HXPhotoUIManager)
	* [HXPhotoResultModel](#HXPhotoResultModel)
	* [HXPhotoTools](#HXPhotoTools)
* [应用示例](#例子)
	* [单独使用HXPhotoViewController](#Demo1)
	* [使用HXPhotoView选照片后自动布局](#Demo2)
	* [传入网络图片地址](#Demo3)
	* [单选模式支持裁剪](#Demo4)
	* [同个界面多个选择器](#Demo5)
	* [上个界面拍摄/选择照片完跳转界面并展示](#Demo6)
	* [传入本地图片](#Demo7)
* [更多](#更多)

## <a id="特性"></a> 一.  特性 - Features

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
- [x] 支持传入本地图片

## <a id="安装"></a> 二.  安装 - Installation

- Cocoapods：```pod 'HXWeiboPhotoPicker' '~> 2.0.9'```搜索不到库或最新版请执行```pod repo update```
- 手动导入：将项目中的“HXWeiboPhotoPicker”文件夹拖入项目中
- 网络图片加载使用的是```SDWebImage v4.0.0```
- 只使用照片选择功能 导入头文件 "HXPhotoViewController.h"
- 选完照片/视频后自动布局功能 导入头文件 "HXPhotoView.h"

## <a id="要求"></a> 三.  要求 - Requirements

- iOS8及以上系统可使用. ARC环境. - iOS 8 or later. Requires ARC
- 在Xcode8环境下将项目运行在iOS10的设备/模拟器中，访问相册和相机需要配置三个info.plist文件
- Privacy - Photo Library Usage Description 和 Privacy - Camera Usage Description 以及 Privacy - Microphone Usage Description
- 相机拍照功能请使用真机调试

## <a id="更新历史"></a> 四.  更新历史 - Update History
- 2017-03-06　　第一次提交
- 2017-03-07　　修复通过相机拍照时照片旋转90°的问题
- ...
- 2017-06-26　　合并一些方法、删除无用方法
- 2017-07-01　　添加单选样式、支持裁剪图片
- 2017-07-05　　解决同一界面多个选择器界面跳转问题,拍摄视频完成时遗留问题
- 2017-07-26　　优化cell性能、3DTouch预览内存消耗。添加是否需要裁剪框属性、刷新界面方法以及拍照/选择照片完之后跳界面Demo
- 2017-08-08　　添加国际化支持英文、保存拍摄的照片/视频到系统相册、实时监听系统相册变化并改变、缓存相册、选择视频时限制超过指定秒数不能选。以及一些小问题
- 2017-08-10　　添加自定义属性、修复导航栏可能偏移64的问题
- 2017-08-12　　添加系统相机、HXPhotoTools添加转换方法
- ...
- v2.0.5　修复相机拍照后显示错误，删除错误版本
- v2.0.6　修复ios8适配问题
- v2.0.7　支持传入本地图片、添加了一些属性和方法、优化了一些细节
- v2.0.8　修改一些细节问题、删除无效文件
- v2.0.9　添加一键将已选模型数组写入temp目录方法和新属性、demo示例

## <a id="属性介绍"></a> 五.  属性介绍 - Atribute Introduce
### <a id="HXPhotoManager"></a> HXPhotoManager 照片管理类相关属性介绍
```
HXPhotoManagerSelectedTypePhoto           // 只选择图片
HXPhotoManagerSelectedTypeVideo          // 只选择视频
HXPhotoManagerSelectedTypePhotoAndVideo // 图片和视频一起

HXPhotoManagerCameraTypeHalfScreen   // 半屏相机
HXPhotoManagerCameraTypeFullScreen  // 全屏相机
HXPhotoManagerCameraTypeSystem     // 系统相机
    
/**
 *  删除临时的照片/视频 - 注:相机拍摄的照片/视频且没有保存到系统相册 或 是本地图片 如果当这样的照片都没有被选中时会清空这些照片 有一张选中了就不会删..  - 默认 YES
 */
BOOL deleteTemporaryPhoto;

/**
 *  本地图片数组 <UIImage *> 装的是UIImage对象 - 已设置为选中状态
 */
NSArray *localImageList;
    
/**
 *  管理UI的类
 */
HXPhotoUIManager *UIManager;

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
 是否开启3DTouch预览功能 默认NO
 */
BOOL open3DTouchPreview;

/**
 相机界面类型 //  默认  半屏
 */
HXPhotoManagerCameraType cameraType;

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
 是否开启查看LivePhoto功能呢 - 默认NO
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

### <a id="HXPhotoUIManager"></a> HXPhotoUIManager UI相关属性
```
/**  HXPhotoView添加按钮图片  */
NSString *photoViewAddImageName;

/**  网络图片占位图  */
NSString *placeholderImageName;

/*-------------------导航栏相关属性------------------*/
/**  导航栏背景颜色  */
UIColor *navBackgroundColor;

/**  导航栏背景图片  */
NSString *navBackgroundImageName;

/**  导航栏左边按钮文字颜色  */
UIColor *navLeftBtnTitleColor;

/**  导航栏 标题/相册名 文字颜色  */
UIColor *navTitleColor;

/**  导航栏标题箭头图标  */
NSString *navTitleImageName;

/**  导航栏右边按钮普通状态背景颜色  */
UIColor *navRightBtnNormalBgColor;

/**  导航栏右边按钮普通状态文字颜色  */
UIColor *navRightBtnNormalTitleColor;

/**  导航栏右边按钮禁用状态背景颜色  */
UIColor *navRightBtnDisabledBgColor;

/**  导航栏右边按钮禁用状态文字颜色  */
UIColor *navRightBtnDisabledTitleColor;

/**  导航栏右边按钮禁用状态下的 layer.borderColor 边框线颜色 */
UIColor *navRightBtnBorderColor;

/*-------------------相册列表视图------------------*/
/**  相册列表有选择内容的提醒图标  */
NSString *albumViewSelectImageName;

/**  相册名称文字颜色  */
UIColor *albumNameTitleColor;

/**  照片数量文字颜色  */
UIColor *photosNumberTitleColor;

/**  相册列表视图背景颜色  */
UIColor *albumViewBgColor;

/**  相册列表cell选中颜色  */
UIColor *albumViewCellSelectedColor;

/*-------------------Cell------------------*/
/**  cell相机照片图片  */
NSString *cellCameraPhotoImageName;

/**  cell相机视频图片  */
NSString *cellCameraVideoImageName;

/**  选择按钮普通状态图片  */
NSString *cellSelectBtnNormalImageName;

/**  选择按钮选中状态图片  */
NSString *cellSelectBtnSelectedImageName;

/**  gif标示图标  */
NSString *cellGitIconImageName;

/*-------------------底部预览、原图按钮视图------------------*/
/**  是否开启毛玻璃效果开启了自动屏蔽背景颜色  */
BOOL blurEffect;

/**  隐藏原图按钮  */
BOOL hideOriginalBtn;

/**  底部视图背景颜色  */
UIColor *bottomViewBgColor;

/**  预览按钮普通状态文字颜色  */
UIColor *previewBtnNormalTitleColor;

/**  预览按钮禁用状态文字颜色  */
UIColor *previewBtnDisabledTitleColor;

/**  预览按钮普通状态背景图片  */
NSString *previewBtnNormalBgImageName;

/**  预览按钮禁用状态背景图片  */
NSString *previewBtnDisabledBgImageName;

/**  原图按钮普通状态文字颜色  */
UIColor *originalBtnNormalTitleColor;

/**  原图按钮禁用状态文字颜色  */
UIColor *originalBtnDisabledTitleColor;

/**  原图按钮边框线颜色  */
UIColor *originalBtnBorderColor;

/**  原图按钮背景颜色  */
UIColor *originalBtnBgColor;

/**  原图按钮普通状态图片  */
NSString *originalBtnNormalImageName;

/**  原图按钮选中状态图片  */
NSString *originalBtnSelectedImageName;

/*-------------------半屏相机界面------------------*/
/**  返回按钮X普通状态图片  */
NSString *cameraCloseNormalImageName;

/**  返回按钮X高亮状态图片  */
NSString *cameraCloseHighlightedImageName;

/**  闪光灯自动模式图片  */
NSString *flashAutoImageName;

/**  闪光灯打开模型图片  */
NSString *flashOnImageName;

/**  闪光灯关闭模式图片  */
NSString *flashOffImageName;

/**  反转相机普通状态图片  */
NSString *cameraReverseNormalImageName;

/**  反转相机高亮状态图片  */
NSString *cameraReverseHighlightedImageName;

/**  中心圆点下照片and视频普通状态文字颜色  */
UIColor *cameraPhotoVideoNormalTitleColor;

/**  中心圆点下照片and视频选中状态文字颜色  */
UIColor *cameraPhotoVideoSelectedTitleColor;

/**  拍照按钮普通状态图片  */
NSString *takePicturesBtnNormalImageName;

/**  拍照按钮高亮状态图片  */
NSString *takePicturesBtnHighlightedImageName;

/**  录制按钮普通状态图片  */
NSString *recordedBtnNormalImageName;

/**  录制按钮高亮状态图片  */
NSString *recordedBtnHighlightedImageName;

/**  删除拍摄的照片/视频图片  */
NSString *cameraDeleteBtnImageName;

/**  确定拍摄的照片/视频普通状态图片  */
NSString *cameraNextBtnNormalImageName;

/**  确定拍摄的照片/视频高亮状态图片  */
NSString *cameraNextBtnHighlightedImageName;

/**  中心圆点图片  */
NSString *cameraCenterDotImageName;

/**  相机聚焦图片  */
NSString *cameraFocusImageName;

/**  全屏相机界面下一步按钮文字颜色  */
UIColor *fullScreenCameraNextBtnTitleColor;

/**  全屏相机界面下一步按钮背景颜色  */
UIColor *fullScreenCameraNextBtnBgColor;
```

### <a id="HXPhotoResultModel"></a> HXPhotoResultModel 相关属性介绍
```
HXPhotoResultModelMediaTypePhoto  // 照片
HXPhotoResultModelMediaTypeVideo // 视频
 
/**  资源类型  */
HXPhotoResultModelMediaType type;

/**  原图URL  */
NSURL *fullSizeImageURL;

/**  原尺寸image 如果资源为视频时此字段为视频封面图片  */
UIImage *displaySizeImage;

/**  原图方向  */
int fullSizeImageOrientation;

/**  视频Asset  */
AVAsset *avAsset;

/**  视频URL  */
NSURL *videoURL;

/**  创建日期  */
NSDate *creationDate;

/**  位置信息  */
CLLocation *location;
```

### <a id="HXPhotoTools"></a> 关于HXPhotoTools获取资源信息 具体代码还是请下载Demo这里只是简单的两个
```
//    将HXPhotoModel模型数组转化成HXPhotoResultModel模型数组  - 已按选择顺序排序
//    !!!!  必须是全部类型的那个数组 就是 allList 这个数组  !!!!
[HXPhotoTools getSelectedListResultModel:allList complete:^(NSArray<HXPhotoResultModel *> *alls,  NSArray<HXPhotoResultModel *> *photos, NSArray<HXPhotoResultModel *> *videos) {
    NSSLog(@"\n全部类型:%@\n照片:%@\n视频:%@",alls,photos,videos);
}];

HXPhotoTools提供一个方法可以根据传入的模型数组转换成图片(UIImage)数组 

type是个枚举
HXPhotoToolsFetchHDImageType = 0, // 高清
HXPhotoToolsFetchOriginalImageTpe, // 原图

[HXPhotoTools getImageForSelectedPhoto:photos type:HXPhotoToolsFetchHDImageType completion:^(NSArray<UIImage *> *images) {
    NSSLog(@"%@",images);
    for (UIImage *image in images) {
        if (image.images.count > 0) {
            // 到这里了说明这个image  是个gif图
        }
    }
}];

[self.view showLoadingHUDText:@"写入中"];
__weak typeof(self) weakSelf = self;
// 将选择的模型数组写入临时目录
[HXPhotoTools selectListWriteToTempPath:self.selectList completion:^(NSArray<NSURL *> *allUrl, NSArray<NSURL *> *imageUrls, NSArray<NSURL *> *videoUrls) {
    NSSLog(@"\nall : %@ \nimage : %@ \nvideo : %@",allUrl,imageUrls,videoUrls);
    [weakSelf.view handleLoading];
} error:^{
    [weakSelf.view handleLoading];
    [weakSelf.view showImageHUDText:@"写入失败"];
    NSSLog(@"写入失败");
}];
```

## <a id="例子"></a> 六.  应用示例 - Examples
### <a id="Demo1"></a> Demo1
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
### <a id="Demo2"></a> Demo2
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

HXPhotoView *photoView = [[HXPhotoView alloc] initWithFrame:CGRectMake((414 - 375) / 2, 100, 375, 400) manager:self.manager];
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
### <a id="Demo3"></a> Demo3
```
- (HXPhotoManager *)manager { // 懒加载管理类
    if (!_manager) { // 设置一些配置信息
        _manager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhoto];
        //        _manager.openCamera = NO;
        _manager.outerCamera = YES;
        _manager.showDeleteNetworkPhotoAlert = NO;
        _manager.saveSystemAblum = YES;
        _manager.photoMaxNum = 2; // 这里需要注意 !!!  第一次传入的最大照片数 是可选最大数 减去 网络照片数量   即   photoMaxNum = maxNum - networkPhotoUrls.count  当点击删除网络照片时, photoMaxNum 内部会自动加1
        _manager.videoMaxNum = 0;  // 如果有网络图片且选择类型为HXPhotoManagerSelectedTypePhotoAndVideo 又设置了视频最大数且不为0时,
//        那么在选择照片列表最大只能选择 photoMaxNum + videoMaxNum
//        在外面collectionView上最大数是 photoMaxNum + networkPhotoUrls.count + videoMaxNum
        _manager.maxNum = 6;
        // 可以这个赋值也可以像下面那样
//       _manager.networkPhotoUrls = [NSMutableArray arrayWithObjects:@"http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/003d86db-b140-4162-aafa-d38056742181.jpg",@"http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/0034821a-6815-4d64-b0f2-09103d62630d.jpg",@"http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/0be5118d-f550-403e-8e5c-6d0badb53648.jpg",@"http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/1466408576222.jpg", nil];
    }
    return _manager;
}
CGFloat width = scrollView.frame.size.width;
HXPhotoView *photoView = [HXPhotoView photoManager:self.manager];
photoView.frame = CGRectMake(kPhotoViewMargin, kPhotoViewMargin, width - kPhotoViewMargin * 2, 0);
photoView.delegate = self;
photoView.backgroundColor = [UIColor whiteColor];
[scrollView addSubview:photoView];
self.photoView = photoView;
    
 // 可以在懒加载中赋值 ,  也可以这样赋值
self.manager.networkPhotoUrls = [NSMutableArray arrayWithObjects:@"http://oss-cn-hangzhou.aliyuncs.com/tsnrhapp/shop/photos/857980fd0acd3caf9e258e42788e38f5_0.gif",@"http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/0034821a-6815-4d64-b0f2-09103d62630d.jpg",@"http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/0be5118d-f550-403e-8e5c-6d0badb53648.jpg",@"http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/1466408576222.jpg", nil];
// 设置完网络图片地址数组后重新给manager赋值
photoView.manager = self.manager;
```
### <a id="Demo4"></a> Demo4
```
- (HXPhotoManager *)manager {
    if (!_manager) {
        _manager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhoto];
        _manager.openCamera = YES;
        // 在这里设置为单选模式
        _manager.singleSelected = YES;
        // 设置是否需要裁剪功能
        _manager.singleSelecteClip = NO;
        _manager.cameraType = HXPhotoManagerCameraTypeFullScreen;
    }
    return _manager;
}
HXPhotoViewController *vc = [[HXPhotoViewController alloc] init];
vc.manager = self.manager;
vc.delegate = self;
[self presentViewController:[[UINavigationController alloc] initWithRootViewController:vc] animated:YES completion:nil];
// 代理返回选择的结果
- (void)photoViewControllerDidNext:(NSArray<HXPhotoModel *> *)allList Photos:(NSArray<HXPhotoModel *> *)photos Videos:(NSArray<HXPhotoModel *> *)videos Original:(BOOL)original { 
    __weak typeof(self) weakSelf = self;
    // 这里使用HXPhotoTools 里面的方法获取image
    [HXPhotoTools getImageForSelectedPhoto:photos type:0 completion:^(NSArray<UIImage *> *images) {
        weakSelf.imageView.image = images.firstObject;
    }];
} 
```
### <a id="Demo5"></a> Demo5
```
// 懒加载三个管理类用来控制三个选择器
- (HXPhotoManager *)oneManager {
    if (!_oneManager) {
        _oneManager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhoto];
    }
    return _oneManager;
}
- (HXPhotoManager *)twoManager {
    if (!_twoManager) {
        _twoManager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypeVideo];
    }
    return _twoManager;
}
- (HXPhotoManager *)threeManager {
    if (!_threeManager) {
        _threeManager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhotoAndVideo];
    }
    return _threeManager;
}
// 初始化UIScrollerView以及三个HXPhotoView
self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
self.scrollView.alwaysBounceVertical = YES;
[self.view addSubview:self.scrollView];
    
self.onePhotoView = [[HXPhotoView alloc] initWithFrame:CGRectMake(kPhotoViewMargin, kPhotoViewMargin, self.view.frame.size.width - kPhotoViewMargin * 2, 0) WithManager:self.oneManager];
self.onePhotoView.delegate = self;
[self.scrollView addSubview:self.onePhotoView];
    
self.twoPhotoView = [[HXPhotoView alloc] initWithFrame:CGRectMake(kPhotoViewMargin, CGRectGetMaxY(self.onePhotoView.frame) + kPhotoViewSectionMargin, self.view.frame.size.width - kPhotoViewMargin * 2, 0) WithManager:self.twoManager];
self.twoPhotoView.delegate = self;
[self.scrollView addSubview:self.twoPhotoView];
    
self.threePhotoView = [[HXPhotoView alloc] initWithFrame:CGRectMake(kPhotoViewMargin, CGRectGetMaxY(self.twoPhotoView.frame) + kPhotoViewSectionMargin, self.view.frame.size.width - kPhotoViewMargin * 2, 0) WithManager:self.threeManager];
self.threePhotoView.delegate = self;
[self.scrollView addSubview:self.threePhotoView];

// 根据photoView来判断是哪一个选择器
- (void)photoView:(HXPhotoView *)photoView changeComplete:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photos videos:(NSArray<HXPhotoModel *> *)videos original:(BOOL)isOriginal {
    if (self.onePhotoView == photoView) {
        NSSLog(@"onePhotoView - %@",allList);
    }else if (self.twoPhotoView == photoView) {
        NSSLog(@"twoPhotoView - %@",allList);
    }else if (self.threePhotoView == photoView) {
        NSSLog(@"threePhotoView - %@",allList);
    }
}
// 返回更新后的frame,根据photoView来更新scrollView
- (void)photoView:(HXPhotoView *)photoView updateFrame:(CGRect)frame {
    if (self.onePhotoView == photoView) {
        self.twoPhotoView.frame = CGRectMake(kPhotoViewMargin, CGRectGetMaxY(self.onePhotoView.frame) + kPhotoViewSectionMargin,                 self.view.frame.size.width - kPhotoViewMargin * 2, self.twoPhotoView.frame.size.height);
        self.threePhotoView.frame = CGRectMake(kPhotoViewMargin, CGRectGetMaxY(self.twoPhotoView.frame) + kPhotoViewSectionMargin,               self.view.frame.size.width - kPhotoViewMargin * 2, self.threePhotoView.frame.size.height);
    }else if (self.twoPhotoView == photoView) {
        self.twoPhotoView.frame = CGRectMake(kPhotoViewMargin, CGRectGetMaxY(self.onePhotoView.frame) + kPhotoViewSectionMargin,                 self.view.frame.size.width - kPhotoViewMargin * 2, self.twoPhotoView.frame.size.height);
        self.threePhotoView.frame = CGRectMake(kPhotoViewMargin, CGRectGetMaxY(self.twoPhotoView.frame) + kPhotoViewSectionMargin,               self.view.frame.size.width - kPhotoViewMargin * 2, self.threePhotoView.frame.size.height);
    }else if (self.threePhotoView == photoView) {
        self.threePhotoView.frame = CGRectMake(kPhotoViewMargin, CGRectGetMaxY(self.twoPhotoView.frame) + kPhotoViewSectionMargin,               self.view.frame.size.width - kPhotoViewMargin * 2, frame.size.height);
    }
    self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width, CGRectGetMaxY(self.threePhotoView.frame) + kPhotoViewMargin);
}
```
### <a id="Demo6"></a> Demo6
```
// 先在第一个控制器里初始化管理类并设置好属性
- (HXPhotoManager *)manager {
    if (!_manager) {
        /**  注意!!! 如果是先选照片拍摄的话, 不支持将拍摄的照片或者视频保存到系统相册  **/
        _manager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhotoAndVideo];
        _manager.outerCamera = YES;
        _manager.openCamera = NO;
        _manager.saveSystemAblum = YES;
    }
    return _manager;
}
// 通过HXPhotoViewController的代理跳转界面并将当前界面的管理类传入下一个界面
- (void)photoViewControllerDidNext:(NSArray<HXPhotoModel *> *)allList Photos:(NSArray<HXPhotoModel *> *)photos Videos:(NSArray<HXPhotoModel *> *)videos Original:(BOOL)original {
    Demo6SubViewController *vc = [[Demo6SubViewController alloc] init];
    vc.manager = self.manager;
    [self.navigationController pushViewController:vc animated:YES];
}
// 这里需要注意在第二个控制释放的时候需要将已选的操作清空
- (void)dealloc { 
    [self.manager clearSelectedList];
}
```
### <a id="Demo7"></a> Demo7
```
// 加载本地图片
NSMutableArray *images = [NSMutableArray array];
for (int i = 0 ; i < 4; i++) {
    UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"%d",i]];
    [images addObject:image];
}
    
CGFloat width = scrollView.frame.size.width;
HXPhotoView *photoView = [[HXPhotoView alloc] initWithFrame:CGRectMake(kPhotoViewMargin, kPhotoViewMargin, width - kPhotoViewMargin * 2, 0) manager:self.manager];
photoView.delegate = self;
photoView.backgroundColor = [UIColor whiteColor];
// 在这里将本地图片image数组给管理类并且刷新界面
self.manager.localImageList = images;
[photoView refreshView];
[scrollView addSubview:photoView];
self.photoView = photoView;
```

## <a id="更多"></a> 六.  更多 - More

- 支持横屏功能正在准备当中...

- 如果您发现了bug请尽可能详细地描述系统版本、手机型号和复现步骤等信息 提一个issue.

- 如果您有什么好的建议也可以提issue,大家一起讨论一起学习进步...

- 具体代码请下载项目  如果觉得喜欢的能给一颗小星星么!  ✨✨✨

- [有兴趣可以加下创建的QQ群:531895229](//shang.qq.com/wpa/qunwpa?idkey=ebd8d6809c83b4d6b4a18b688621cb73ded0cce092b4d1f734e071a58dd37c26) <a target="_blank" href="http://wpa.qq.com/msgrd?v=3&uin=294005139&site=qq&menu=yes"><img border="0" src="http://wpa.qq.com/pa?p=2:294005139:52" alt="点击这里给我发消息" title="点击这里给我发消息"/></a>
