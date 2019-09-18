<img src="http://thyrsi.com/t6/669/1549792194x1822611383.png" width="800" height="130">

[![Platform](http://img.shields.io/badge/platform-ios-blue.svg?style=flat
             )](https://developer.apple.com/iphone/index.action)
[![Pod Version](http://img.shields.io/cocoapods/v/HXPhotoPicker.svg?style=flat)](http://cocoadocs.org/docsets/HXPhotoPicker/)
[![Language](http://img.shields.io/badge/language-ObjC-brightgreen.svg?style=flat)](https://developer.apple.com/Objective-C)
[![License](http://img.shields.io/badge/license-MIT-lightgrey.svg?style=flat)](http://mit-license.org)

<img src="http://thyrsi.com/t6/669/1549791821x1822611383.png" width="208" height="404"><img src="http://thyrsi.com/t6/669/1549791987x1822611383.png" width="208" height="404"><img src="http://thyrsi.com/t6/669/1549792014x1822611383.png" width="208" height="404"><img src="http://thyrsi.com/t6/669/1549792030x1822611383.png" width="208" height="404">
<img src="http://thyrsi.com/t6/669/1549792043x1822611383.png" width="208" height="404"><img src="http://thyrsi.com/t6/669/1549792055x1822611383.png" width="208" height="404"><img src="http://thyrsi.com/t6/669/1549792069x1822611383.png" width="208" height="404"><img src="http://thyrsi.com/t6/669/1549792082x1822611383.png" width="208" height="404">

## 目录
* [特性](#特性)
* [安装](#安装)
* [要求](#要求)
* [示例](#例子)
    * [获取照片和视频](#如何获取照片和视频)
    * [跳转相册选择照片](#Demo1)
    * [使用HXPhotoView选照片后自动布局](#Demo2)
    * [保存草稿](#如何保存草稿)
    * [添加网络/本地图片、视频](#如何添加网络/本地图片、视频)
    * [相关问题](#相关问题)
    * [更多请下载工程查看](#更多) 
* [更新记录](#更新历史)
* [更多](#更多)

## <a id="特性"></a> 一.  特性 - Features

- [x] 查看/选择GIF图片
- [x] 照片、视频可同时多选/原图
- [x] 3DTouch预览照片
- [x] 长按拖动改变顺序
- [x] 自定义相机拍照/录制视频
- [x] 自定义转场动画
- [x] 查看/选择LivePhoto IOS9.1以上才有用
- [x] 浏览网络图片
- [x] 自定义裁剪图片
- [x] 自定义裁剪视频时长
- [x] 传入本地图片、视频
- [x] 在线下载iCloud上的资源
- [x] 两种相册展现方式（列表、弹窗）
- [x] 支持Cell上添加
- [x] 支持草稿功能
- [x] 同一界面多个不同选择器

## <a id="安装"></a> 二.  安装 - Installation

- Cocoapods：```pod 'HXPhotoPicker', '~> 2.3.3'```搜索不到库或最新版请执行```pod repo update``` ```rm ~/Library/Caches/CocoaPods/search_index.json```
- ```v2.3.2 pod没有依赖sd和yy```  ```v2.3.3 pod依赖了yy```
- 手动导入：将项目中的“HXPhotoPicker”文件夹拖入项目中
- 网络图片加载使用的是 ```YYWebImage``` || >=```v2.3.0```  -> ```SDWebImage v5.0``` || <```v2.3.0``` ->  ```SDWebImage v4.0```
- 如果想要加载网络gif图片请使用```YYWebImage```
- 使用前导入头文件 "HXPhotoPicker.h"

## <a id="要求"></a> 三.  要求 - Requirements

- iOS8及以上系统可使用. ARC环境. - iOS 8 or later. Requires ARC
- 在Xcode8环境下将项目运行在iOS11的设备/模拟器中，访问相册和相机需要配置四个info.plist文件
- Privacy - Photo Library Usage Description 和 Privacy - Camera Usage Description 以及 Privacy - Microphone Usage Description
- Privacy - Location When In Use Usage Description 使用相机拍照时会获取位置信息
- 相机拍照功能请使用真机调试

## <a id="例子"></a> 四.  应用示例 - Examples
### <a id="如何获取照片和视频"> 如何获取照片和视频
```objc
根据选择完成后返回的 HXPhotoModel 对象获取

// 获取 image
// 如果为网络图片的话会先下载
// size 代表获取image的质量
// PHImageManagerMaximumSize 获取原图
[photoModel requestPreviewImageWithSize:PHImageManagerMaximumSize startRequestICloud:^(PHImageRequestID iCloudRequestId, HXPhotoModel *model) {
    // 如果照片在iCloud上会去下载,此回调代表开始下载iCloud上的照片
    // 如果照片在本地存在此回调则不会走
} progressHandler:^(double progress, HXPhotoModel *model) {
    // iCloud下载进度
    // 如果为网络图片,则是网络图片的下载进度
} success:^(UIImage *image, HXPhotoModel *model, NSDictionary *info) {
    // 获取成功
} failed:^(NSDictionary *info, HXPhotoModel *model) {
    // 获取失败
}];

// 获取 imageData
// 如果为网络图片的话会先下载
[photoModel requestImageDataStartRequestICloud:^(PHImageRequestID iCloudRequestId, HXPhotoModel *model) {
    // 开始下载iCloud上照片的imageData
} progressHandler:^(double progress, HXPhotoModel *model) {
    // iCloud下载进度
} success:^(NSData *imageData, UIImageOrientation orientation, HXPhotoModel *model, NSDictionary *info) {
    // 获取成功
} failed:^(NSDictionary *info, HXPhotoModel *model) {
    // 获取失败
}];

// 获取视频的 AVAsset
[photoModel requestAVAssetStartRequestICloud:^(PHImageRequestID iCloudRequestId, HXPhotoModel *model) {
    // 开始下载iCloud上的 AVAsset
} progressHandler:^(double progress, HXPhotoModel *model) {
    // iCloud下载进度
} success:^(AVAsset *avAsset, AVAudioMix *audioMix, HXPhotoModel *model, NSDictionary *info) {
    // 获取成功
} failed:^(NSDictionary *info, HXPhotoModel *model) {
    // 获取失败
}];

// 获取 LivePhoto 
// PHImageManagerMaximumSize代表原图
[photoModel requestLivePhotoWithSize:PHImageManagerMaximumSize startRequestICloud:^(PHImageRequestID iCloudRequestId, HXPhotoModel *model) {
    // 开始下载iCloud上的 LivePhoto
} progressHandler:^(double progress, HXPhotoModel *model) {
    // iCloud下载进度
} success:^(PHLivePhoto *livePhoto, HXPhotoModel *model, NSDictionary *info) {
    // 获取成功
} failed:^(NSDictionary *info, HXPhotoModel *model) {
    // 获取失败
}];

// 导出视频地址 
// presetName 视频导出的质量
[photoModel exportVideoWithPresetName:AVAssetExportPresetHighestQuality startRequestICloud:^(PHImageRequestID iCloudRequestId, HXPhotoModel *model) {
    // 开始下载iCloud上的视频
} iCloudProgressHandler:^(double progress, HXPhotoModel *model) {
    // iCloud下载进度
} exportProgressHandler:^(float progress, HXPhotoModel *model) {
    // 视频导出进度
} success:^(NSURL *videoURL, HXPhotoModel *model) {
    // 导出成功
} failed:^(NSDictionary *info, HXPhotoModel *model) {
    // 导出失败
}];

NSArray+HXExtension
/**
获取image
如果model是视频的话,获取的则是视频封面

@param original 是否原图
@param completion imageArray 获取成功的image数组, errorArray 获取失败的model数组
*/
- (void)hx_requestImageWithOriginal:(BOOL)original completion:(void (^)(NSArray<UIImage *> * _Nullable imageArray, NSArray<HXPhotoModel *> * _Nullable errorArray))completion;

/**
获取imageData

@param completion 完成回调，获取失败的不会添加到数组中
*/
- (void)hx_requestImageDataWithCompletion:(void (^)(NSArray<NSData *> * _Nullable imageDataArray))completion;

/**
获取AVAsset

@param completion 完成回调，获取失败的不会添加到数组中
*/
- (void)hx_requestAVAssetWithCompletion:(void (^)(NSArray<AVAsset *> * _Nullable assetArray))completion;

/**
获取视频地址

@param presetName AVAssetExportPresetHighestQuality / AVAssetExportPresetMediumQuality
@param completion 完成回调，获取失败的不会添加到数组中
*/
- (void)hx_requestVideoURLWithPresetName:(NSString *)presetName completion:(void (^)(NSArray<NSURL *> * _Nullable videoURLArray))completion;
```
### <a id="Demo1"></a> 跳转相册选择照片
```objc
// 懒加载 照片管理类
- (HXPhotoManager *)manager {
    if (!_manager) {
        _manager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhotoAndVideo];
    }
    return _manager;
}

// 一个方法调用
HXWeakSelf
[self hx_presentSelectPhotoControllerWithManager:self.manager didDone:^(NSArray<HXPhotoModel *> *allList, NSArray<HXPhotoModel *> *photoList, NSArray<HXPhotoModel *> *videoList, BOOL isOriginal, UIViewController *viewController, HXPhotoManager *manager) {
    weakSelf.total.text = [NSString stringWithFormat:@"总数量：%ld   ( 照片：%ld   视频：%ld )",allList.count, photoList.count, videoList.count];
    weakSelf.original.text = isOriginal ? @"YES" : @"NO";
    NSSLog(@"block - all - %@",allList);
    NSSLog(@"block - photo - %@",photoList);
    NSSLog(@"block - video - %@",videoList);
} cancel:^(UIViewController *viewController, HXPhotoManager *manager) {
    NSSLog(@"block - 取消了");
}];

// 照片选择控制器 
HXCustomNavigationController *nav = [[HXCustomNavigationController alloc] initWithManager:self.manager delegate:self];
[self presentViewController:nav animated:YES completion:nil];

// 通过 HXCustomNavigationControllerDelegate 代理返回选择的图片以及视频
/**
点击完成按钮

@param photoNavigationViewController self
@param allList 已选的所有列表(包含照片、视频)
@param photoList 已选的照片列表
@param videoList 已选的视频列表
@param original 是否原图
*/
- (void)photoNavigationViewController:(HXCustomNavigationController *)photoNavigationViewController didDoneAllList:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photoList videos:(NSArray<HXPhotoModel *> *)videoList original:(BOOL)original;

/**
点击取消

@param photoNavigationViewController self
*/
- (void)photoNavigationViewControllerDidCancel:(HXCustomNavigationController *)photoNavigationViewController;
```
### <a id="Demo2"></a> 使用HXPhotoView布局
```objc
// 懒加载 照片管理类
- (HXPhotoManager *)manager {
    if (!_manager) {
        _manager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhotoAndVideo];
    }
    return _manager;
}  
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

具体请查看HXPhotoView.h
...
```
### <a id="如何保存草稿"></a> 如何保存草稿
```objc
通过 HXPhotoManager 对象进行存储
/**
保存模型数组到本地

@param success 成功
@param failed 失败
*/
- (void)saveSelectModelArraySuccess:(void (^)(void))success failed:(void (^)(void))failed;
/**
删除本地保存的模型数组

@return success or failed
*/
- (BOOL)deleteLocalSelectModelArray;
/**
获取保存在本地的模型数组

*/
- (void)getSelectedModelArrayComplete:(void (^)(NSArray<HXPhotoModel *> *modelArray))complete;

// 保存草稿
[self.manager saveSelectModelArraySuccess:^{
    // 保存草稿成功
} failed:^{
    // 保存草稿失败
}];

// 获取草稿
[self.manager getSelectedModelArrayComplete:^(NSArray<HXPhotoModel *> *modelArray) {
    if (modelArray.count) {
        // 获取到保存的草稿给manager
        [weakSelf.manager addModelArray:modelArray];
        // 刷新HXPhotoView
        [weakSelf.photoView refreshView];
    }
}];
```
### <a id="如何添加网络/本地图片、视频"></a> 如何添加网络/本地图片、视频
```objc
通过 HXPhotoManager、HXCustomAssetModel 进行添加
/**
根据本地图片名初始化

@param imageName 本地图片名
@param selected 是否选中
@return HXCustomAssetModel
*/
+ (instancetype)assetWithLocaImageName:(NSString *)imageName selected:(BOOL)selected;

/**
根据本地UIImage初始化

@param image 本地图片
@param selected 是否选中
@return HXCustomAssetModel
*/
+ (instancetype)assetWithLocalImage:(UIImage *)image selected:(BOOL)selected;

/**
根据网络图片地址初始化

@param imageURL 网络图片地址
@param thumbURL 网络图片缩略图地址
@param selected 是否选中
@return HXCustomAssetModel
*/
+ (instancetype)assetWithNetworkImageURL:(NSURL *)imageURL networkThumbURL:(NSURL *)thumbURL selected:(BOOL)selected;

/**
根据本地视频地址初始化

@param videoURL 本地视频地址
@param selected 是否选中
@return HXCustomAssetModel
*/
+ (instancetype)assetWithLocalVideoURL:(NSURL *)videoURL selected:(BOOL)selected;

创建HXCustomAssetModel完成后，通过HXPhotoManager对象的这个方法进行添加
/**
添加自定义资源模型
如果图片/视频 选中的数量超过最大选择数时,之后选中的会变为未选中
如果设置的图片/视频不能同时选择时
图片在视频前面的话只会将图片添加到已选数组.
视频在图片前面的话只会将视频添加到已选数组.
如果 type = HXPhotoManagerSelectedTypePhoto 时 会过滤掉视频
如果 type = HXPhotoManagerSelectedTypeVideo 时 会过滤掉图片

@param assetArray 模型数组
*/
- (void)addCustomAssetModel:(NSArray<HXCustomAssetModel *> *)assetArray;

// 添加
[self.manager addCustomAssetModel:@[assetModel1, assetModel2, assetModel3, assetModel4, assetModel5, assetModel6]];
// 完成后刷新HXPhotoView
[self.photoView refreshView];  
```
### <a id="相关问题"></a> 相关问题
#### 1. pod YYWebImage与YYKit冲突
```objc
解决方案：将YYKit拆开分别导入
```
#### 2. 如何更换语言
```objc
HXPhotoConfiguration.h

设置语言类型
HXPhotoLanguageTypeSys = 0, // 跟随系统语言
HXPhotoLanguageTypeSc,      // 中文简体
HXPhotoLanguageTypeTc,      // 中文繁体
HXPhotoLanguageTypeJa,      // 日文
HXPhotoLanguageTypeKo,      // 韩文
HXPhotoLanguageTypeEn       // 英文

/**
语言类型
默认 跟随系统
*/
@property (assign, nonatomic) HXPhotoLanguageType languageType;
```
#### 3. 选择完照片后其他界面视图往下偏移
```objc
方法一：
/**
如果选择完照片返回之后，
原有界面继承UIScrollView的视图都往下偏移一个导航栏距离的话，
那么请将这个属性设置为YES，即可恢复。
*/
@Property (assign, nonatomic) BOOL restoreNavigationBar;

方法二：
在选择完照片之后加上
[UINavigationBar appearance].translucent = NO;
```
#### 4. 关于图片
```objc
根据HXPhotoModel的type属性来区分图片类型
HXPhotoModelMediaTypePhoto          = 0,    //!< 相册里的普通照片
HXPhotoModelMediaTypeLivePhoto      = 1,    //!< LivePhoto
HXPhotoModelMediaTypePhotoGif       = 2,    //!< gif图
HXPhotoModelMediaTypeCameraPhoto    = 5,    //!< 通过相机拍的临时照片、本地/网络图片
当type为HXPhotoModelMediaTypeCameraPhoto时，如果networkPhotoUrl不为空的话，那么这张图片就是网络图片
如果为本地图片时thumbPhoto/previewPhoto就是本地图片
不为本地图片时thumbPhoto/previewPhoto的值都是临时存的只用于展示
HXPhotoModel已提供方法获取image或者imageData
```
#### 5. 关于视频的URL
```objc
1.如果选择的HXPhotoModel的PHAsset有值，需要先获取AVAsset，再使用AVAssetExportSession根据AVAsset导出视频地址
2.如果PHAsset为空的话，则代表此视频是本地视频。可以直接HXPhotoModel里的VideoURL属性
HXPhotoModel已提供方法获取
```
#### 6. 关于相机拍照
```objc
当拍摄的照片/视频保存到系统相册
如果系统版本为9.0及以上时，拍照后的照片/视频保存相册后会获取保存后的PHAsset，保存的时候如果有定位信息也会把定位信息保存到相册
HXPhotoModel里PHAsset有值并且type为 HXPhotoModelMediaTypePhoto / HXPhotoModelMediaTypeVideo
以下版本的和不保存相册的都只是存在本地的临时图片/视频 
HXPhotoModel里PHAsset为空并且type为 HXPhotoModelMediaTypeCameraPhoto / HXPhotoModelMediaTypeCameraVideo
```
#### 7. 关于原图
```objc
根据代理或者block回调里的 isOriginal 来判断是否选择了原图 
方法一：
// 获取原图
// 本地图片、网络图片调用此方法会直接进入失败回调
// 本地图片获取原图 model.thumbPhoto / model.previewPhoto
// 网络图片获取原图 如果 model.thumbPhoto / model.previewPhoto 都为空的话，说明还没有下载完成或者下载失败了，重新下载即可。也可以直接用网络图片地址 model.networkPhotoUrl 下载 或者调用requestPreviewImageWithSize:progressHandler:success:failed
// 这个方法只针对有photoModel.asset不为空的情况
[photoModel requestImageURLStartRequestICloud:^(PHContentEditingInputRequestID iCloudRequestId, HXPhotoModel *model) { 
    // 如果照片在iCloud上会去下载,此回调代表开始下载iCloud上的照片
    // 如果照片在本地存在此回调则不会走
} progressHandler:^(double progress, HXPhotoModel *model) {
    // iCloud下载进度
} success:^(NSURL *imageURL, HXPhotoModel *model, NSDictionary *info) {
    // 获取成功
    // imageURL图片地址
    if ([imageURL.relativePath.pathExtension isEqualToString:@"HEIC"]) {
        // 处理一下 HEIC 格式图片
        CIImage *ciImage = [CIImage imageWithContentsOfURL:imageURL];
        CIContext *context = [CIContext context];
        NSString *key = (__bridge NSString *)kCGImageDestinationLossyCompressionQuality;
        NSData *jpgData = [context JPEGRepresentationOfImage:ciImage colorSpace:ciImage.colorSpace options:@{key : @1}];
        UIImage *image = [UIImage imageWithData:jpgData];
    }else {
        NSData *imageData = [NSData dataWithContentsOfFile:path];
        UIImage *image = [UIImage imageWithData:imageData];  
    }
} failed:^(NSDictionary *info, HXPhotoModel *model) {
    // 获取失败
}];
// 根据 size 获取高清图或者缩略图 , size只针对 PHAsset 有值的情况下有效
// 如果 size (width <= 0, height <= 0) / PHImageManagerMaximumSize 则会获取原图
// 本地图片直接返回本地图片的image
// 网络图片直接返回网络图片下载完成后的image
[photoModel requestPreviewImageWithSize:size startRequestICloud:^(PHImageRequestID iCloudRequestId, HXPhotoModel *model) {
    // 如果照片在iCloud上会去下载,此回调代表开始下载iCloud上的照片
    // 如果照片在本地存在此回调则不会走
} progressHandler:^(double progress, HXPhotoModel *model) {
    // iCloud下载进度
    // 如果为网络图片,则是网络图片的下载进度
} success:^(UIImage *image, HXPhotoModel *model, NSDictionary *info) {
    // 获取成功
} failed:^(NSDictionary *info, HXPhotoModel *model) {
    // 获取失败
}];
方法二：
// 获取 imageData 根据data来处理
// 如果为网络图片的话会先下载
[photoModel requestImageDataStartRequestICloud:^(PHImageRequestID iCloudRequestId, HXPhotoModel *model) {
    // 开始下载iCloud上照片的imageData
} progressHandler:^(double progress, HXPhotoModel *model) {
    // iCloud下载进度
} success:^(NSData *imageData, UIImageOrientation orientation, HXPhotoModel *model, NSDictionary *info) {
    // 获取成功
    if ([HXPhotoTools assetIsHEIF:model.asset]) {
        // 处理一下 HEIC 格式图片
        CIImage *ciImage = [CIImage imageWithData:imageData];
        CIContext *context = [CIContext context];
        NSData *jpgData = [context JPEGRepresentationOfImage:ciImage colorSpace:ciImage.colorSpace options:@{}];
        // jpgData 转换后的imageData
    } 
} failed:^(NSDictionary *info, HXPhotoModel *model) {
    // 获取失败
}];
```
#### 8. 单独使用HXPhotoPreviewViewController预览图片
```objc
HXCustomAssetModel *assetModel1 = [HXCustomAssetModel assetWithLocaImageName:@"1" selected:YES];
// selected 为NO 的会过滤掉
HXCustomAssetModel *assetModel2 = [HXCustomAssetModel assetWithLocaImageName:@"2" selected:NO];
HXCustomAssetModel *assetModel3 = [HXCustomAssetModel assetWithNetworkImageURL:[NSURL URLWithString:@"http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/1466408576222.jpg"] selected:YES];
// selected 为NO 的会过滤掉
HXCustomAssetModel *assetModel4 = [HXCustomAssetModel assetWithNetworkImageURL:[NSURL URLWithString:@"http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/0034821a-6815-4d64-b0f2-09103d62630d.jpg"] selected:NO];
NSURL *url = [[NSBundle mainBundle] URLForResource:@"QQ空间视频_20180301091047" withExtension:@"mp4"];
HXCustomAssetModel *assetModel5 = [HXCustomAssetModel assetWithLocalVideoURL:url selected:YES];

HXPhotoManager *photoManager = [HXPhotoManager managerWithType:HXPhotoManagerSelectedTypePhotoAndVideo];
photoManager.configuration.saveSystemAblum = YES;
photoManager.configuration.photoMaxNum = 0;
photoManager.configuration.videoMaxNum = 0;
photoManager.configuration.maxNum = 10;
photoManager.configuration.selectTogether = YES;
photoManager.configuration.photoCanEdit = NO;
photoManager.configuration.videoCanEdit = NO;
photoManager.configuration.previewRespondsToLongPress = ^(UILongPressGestureRecognizer *longPress, 
                                                          HXPhotoModel *photoModel, 
                                                          HXPhotoManager *manager, 
                                                          HXPhotoPreviewViewController *previewViewController) {
    hx_showAlert(previewViewController, @"提示", @"长按事件", @"确定", nil, nil, nil);
};
[photoManager addCustomAssetModel:@[assetModel1, assetModel2, assetModel3, assetModel4, assetModel5]];

[self hx_presentPreviewPhotoControllerWithManager:photoManager
                                     previewStyle:HXPhotoViewPreViewShowStyleDark
                                     currentIndex:0
                                     photoView:nil];


UIViewController+HXExtension.h
/// 跳转预览照片界面
/// @param manager 照片管理者
/// @param previewStyle 预览样式
/// @param currentIndex 当前预览的下标
/// @param photoView 照片展示视图 - 没有就不传
- (void)hx_presentPreviewPhotoControllerWithManager:(HXPhotoManager *)manager
                                       previewStyle:(HXPhotoViewPreViewShowStyle)previewStyle
                                       currentIndex:(NSUInteger)currentIndex
                                          photoView:(HXPhotoView * _Nullable)photoView;
```

## <a id="更新历史"></a> 五.  更新历史 - Update History
```
- v2.3.3　-　pod依赖yy
- v2.3.2　-　适配ios13
- v2.3.1　-　pod去除依赖sd和yy
- v2.3.0　-　适配SDWebImage v5.0.0 、去掉警告
- v2.2.9　-　UI显示问题的修改
- v2.2.7　-　解决使用NSArray+HXExtension里方法可能会获取空的问题，部分机型系统编辑照片时可能会出现黑屏问题
- v2.2.6　-　添加视频时长编辑功能，修复ipad、ios8的一些问题，显示效果和逻辑上的一些优化以及Demo的一些修改
- v2.2.5　-　优化一些显示效果，一些问题修复，编辑照片时添加转场动画
- 2019-1-18 修复预览大图时下载iCloud资源完成后未刷新列表cell问题。去除Date命名（有在外部使用的请去掉Date命名）
- 2019-1-12 获取原图时处理HEIC格式的照片
- 2019-1-9  选择照片逻辑修改、保存相册时添加定位信息以及一些问题修复
- 2019-1-7  优化了相册加载速度、调整一些显示效果、方法结构调整（旧版本更新会出现方法报错，请使用最新方法）、编辑完成后跳转逻辑修改、相机拍照逻辑修改（ios9以上版本，如果打开了保存相册开关会获取到刚刚拍照的PHAsset对象）
- v2.2.3　-　Demo9 添加cell上使用网络图片、3DTouch预览，Demo13 导入其他第三方图片/视频编辑库，优化显示效果，添加相册列表弹窗方式
- v2.2.2　-　适配iphone XS - XSMax - XR、支持加载网络动图（需要YYWebImage）。支持YYWebImage（SD和YY同时存在时优先使用YY）
- v2.2.1　-　修改了一些问题、优化了一些效果，使用HXPhotoView预览大图时支持手势返回
- v2.2.0　-　添加xib使用示例（Demo11）、混合添加本地图片/网络图片/本地视频示例（Demo12）
- v2.1.9　-　Demo2添加长按拖动删除功能（类似微信）
- v2.1.8　-　添加支持繁体字、韩文、日文，以及一些功能优化
- v2.1.7　-　完善支持英文、优化一些功能 
- v2.1.5　-　添加cell上使用示例，支持添加网络图片、优化显示效果
- v2.1.4　-　支持更换相机界面、添加属性控制裁剪
- 2017-11-21　　支持在线下载iCloud上的照片和视频
- v2.1.2　-　添加显示照片地理位置信息、优化细节
- 2017-11-14　　添加自定义裁剪功能
- 2017-11-06　　完善手势返回效果、修改小问题
- v2.1.1　-　添加新相册风格(性能更好,支持横屏)、完善细节功能
- v2.1.0　-　适配ios11以及iphone X / 3DTouch预览时播放gif、视频 / 优化区分iCloud照片、修改写入文件方法
- v2.0.9　-　添加一键将已选模型数组写入temp目录方法和新属性、demo示例
- v2.0.8　-　修改一些细节问题、删除无效文件
- v2.0.7　-　支持传入本地图片、添加了一些属性和方法、优化了一些细节
- v2.0.6　-　修复ios8适配问题
- v2.0.5　-　修复相机拍照后显示错误，删除错误版本
- ...
- 2017-08-12　　添加系统相机、HXPhotoTools添加转换方法
- 2017-08-10　　添加自定义属性、修复导航栏可能偏移64的问题
- 2017-08-08　　添加国际化支持英文、保存拍摄的照片/视频到系统相册、实时监听系统相册变化并改变、缓存相册、选择视频时限制超过指定秒数不能选。以及一些小问题
- 2017-07-26　　优化cell性能、3DTouch预览内存消耗。添加是否需要裁剪框属性、刷新界面方法以及拍照/选择照片完之后跳界面Demo
- 2017-07-05　　解决同一界面多个选择器界面跳转问题,拍摄视频完成时遗留问题
- 2017-07-01　　添加单选样式、支持裁剪图片
- 2017-06-26　　合并一些方法、删除无用方法
- ...
- 2017-03-07　　修复通过相机拍照时照片旋转90°的问题
- 2017-03-06　　第一次提交
```

## <a id="更多"></a> 六.  更多 - More

- 如果您发现了bug请尽可能详细地描述系统版本、手机型号和复现步骤等信息 提一个issue.

- 如果您有什么好的建议也可以提issue,大家一起讨论一起学习进步...

- 具体代码请下载项目  如果觉得喜欢的能给一颗小星星么!  ✨✨✨

- [有兴趣可以加下创建的QQ群:531895229(有问题请先看Demo，因为工作很忙所以可能问问题没人回答!!)](//shang.qq.com/wpa/qunwpa?idkey=ebd8d6809c83b4d6b4a18b688621cb73ded0cce092b4d1f734e071a58dd37c26)
