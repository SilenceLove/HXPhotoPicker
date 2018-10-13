
[![Platform](http://img.shields.io/badge/platform-ios-blue.svg?style=flat
             )](https://developer.apple.com/iphone/index.action)
[![Pod Version](http://img.shields.io/cocoapods/v/HXPhotoPicker.svg?style=flat)](http://cocoadocs.org/docsets/HXPhotoPicker/)
[![Language](http://img.shields.io/badge/language-ObjC-brightgreen.svg?style=flat)](https://developer.apple.com/Objective-C)
[![License](http://img.shields.io/badge/license-MIT-lightgrey.svg?style=flat)](http://mit-license.org)

<img src="https://user-images.githubusercontent.com/18083149/33309568-764a198c-d459-11e7-958f-8602445d740a.gif" width="270" height="480"> <img src="http://thyrsi.com/t6/386/1539442503x-1404755516.gif" width="270" height="480"> <img src="http://thyrsi.com/t6/386/1539442552x-1404755516.gif" width="270" height="480">
<img src="https://user-images.githubusercontent.com/18083149/32778022-585f3628-c973-11e7-8139-9d19c26f1515.gif" width="270" height="480"> <img src="https://user-images.githubusercontent.com/18083149/32778166-d2397300-c973-11e7-9135-8ba11b24636e.gif" width="270" height="480"> <img src="https://user-images.githubusercontent.com/18083149/33060991-55f9abf4-ced5-11e7-8b97-609813c0e937.gif" width="270" height="480">

## 目录
* [项目特性](#特性)
* [安装方式](#安装)
* [使用要求](#要求)
* [更新记录](#更新历史)
* [应用示例](#例子)
	* [单独使用HXPhotoViewController](#Demo1)
	* [使用HXPhotoView选照片后自动布局](#Demo2)
	* [传入网络图片地址](#Demo3)
	* [单选模式支持裁剪](#Demo4)
	* [同个界面多个选择器](#Demo5)
	* [上个界面拍摄/选择照片完跳转界面并展示](#Demo6)
	* [传入本地图片](#Demo7)
	* [将模型写入临时目录、获取图片/视频](#Demo8)
	* [cell上使用photoView](#Demo9)
       * [更多请下载工程查看](#) 
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
- [x] 支持自定义裁剪图片
- [x] 支持传入本地图片
- [x] 支持在线下载iCloud上的资源

## <a id="安装"></a> 二.  安装 - Installation

- Cocoapods：```pod 'HXPhotoPicker', '~> 2.2.3'```搜索不到库或最新版请执行```pod repo update``` ```rm ~/Library/Caches/CocoaPods/search_index.json```
- 手动导入：将项目中的“HXPhotoPicker”文件夹拖入项目中
- 网络图片加载使用的是```SDWebImage v4.4.1``` || ```YYWebImage v1.0.5```
- 如果想要加载网络gif图片请使用```YYWebImage```
- 使用前导入头文件 "HXPhotoPicker.h"

## <a id="要求"></a> 三.  要求 - Requirements

- iOS8及以上系统可使用. ARC环境. - iOS 8 or later. Requires ARC
- 在Xcode8环境下将项目运行在iOS11的设备/模拟器中，访问相册和相机需要配置四个info.plist文件
- Privacy - Photo Library Usage Description 和 Privacy - Camera Usage Description 以及 Privacy - Microphone Usage Description
- Privacy - Location When In Use Usage Description 使用相机拍照时会获取位置信息
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
- v2.0.5　-　修复相机拍照后显示错误，删除错误版本
- v2.0.6　-　修复ios8适配问题
- v2.0.7　-　支持传入本地图片、添加了一些属性和方法、优化了一些细节
- v2.0.8　-　修改一些细节问题、删除无效文件
- v2.0.9　-　添加一键将已选模型数组写入temp目录方法和新属性、demo示例
- v2.1.0　-　适配ios11以及iphone X / 3DTouch预览时播放gif、视频 / 优化区分iCloud照片、修改写入文件方法
- v2.1.1　-　添加新相册风格(性能更好,支持横屏)、完善细节功能
- 2017-11-06　　完善手势返回效果、修改小问题
- 2017-11-14　　添加自定义裁剪功能
- v2.1.2　-　添加显示照片地理位置信息、优化细节
- 2017-11-21　　支持在线下载iCloud上的照片和视频
- v2.1.4　-　支持更换相机界面、添加属性控制裁剪
- v2.1.5　-　添加cell上使用示例，支持添加网络图片、优化显示效果
- v2.1.7　-　完善支持英文、优化一些功能 
- v2.1.8　-　添加支持繁体字、韩文、日文，以及一些功能优化
- v2.1.9　-　Demo2添加长按拖动删除功能（类似微信）
- v2.2.0　-　添加xib使用示例（Demo11）、混合添加本地图片/网络图片/本地视频示例（Demo12）
- v2.2.1　-　修改了一些问题、优化了一些效果，使用HXPhotoView预览大图时支持手势返回
- v2.2.2　-　适配iphone XS - XSMax - XR、支持加载网络动图（需要YYWebImage）。支持YYWebImage（SD和YY同时存在时优先使用YY）
- v2.2.3　-　Demo9 添加cell上使用网络图片、3DTouch预览，Demo13 导入其他第三方图片/视频编辑库，优化显示效果，添加相册列表弹窗方式

## <a id="例子"></a> 五.  应用示例 - Examples
### <a id="Demo1"></a> Demo1
```objc
// 懒加载 照片管理类
- (HXPhotoManager *)manager {
    if (!_manager) {
        _manager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhotoAndVideo];
    }
    return _manager;
}

// 一个方法调用
__weak typeof(self) weakSelf = self;
[self hx_presentAlbumListViewControllerWithManager:self.manager done:^(NSArray<HXPhotoModel *> *allList, NSArray<HXPhotoModel *> *photoList, NSArray<HXPhotoModel *> *videoList, BOOL original, HXAlbumListViewController *viewController) {
    weakSelf.total.text = [NSString stringWithFormat:@"总数量：%ld   ( 照片：%ld   视频：%ld )",allList.count, photoList.count, videoList.count];
    weakSelf.original.text = original ? @"YES" : @"NO";
    NSSLog(@"all - %@",allList);
    NSSLog(@"photo - %@",photoList);
    NSSLog(@"video - %@",videoList);
} cancel:^(HXAlbumListViewController *viewController) {
    NSSLog(@"取消了");
}];

// 照片选择控制器
HXAlbumListViewController *vc = [[HXAlbumListViewController alloc] init];
vc.delegate = self;
vc.manager = self.manager; 
[self presentViewController:[[HXCustomNavigationController alloc] initWithRootViewController:vc] animated:YES completion:nil];

// 通过 HXPhotoViewControllerDelegate 代理返回选择的图片以及视频
- (void)albumListViewController:(HXAlbumListViewController *)albumListViewController didDoneAllList:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photoList videos:(NSArray<HXPhotoModel *> *)videoList original:(BOOL)original

// 点击取消
- (void)albumListViewControllerDidCancel:(HXAlbumListViewController *)albumListViewController

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
```
### <a id="Demo3"></a> Demo3
```
- (HXPhotoManager *)manager { // 懒加载管理类
    if (!_manager) { // 设置一些配置信息
        _manager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhoto];
        //        _manager.openCamera = NO;
        _manager.showDeleteNetworkPhotoAlert = NO;
        _manager.saveSystemAblum = YES;
        _manager.photoMaxNum = 6;
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
NSMutableArray *array = [NSMutableArray arrayWithObjects:@"http://oss-cn-hangzhou.aliyuncs.com/tsnrhapp/shop/photos/857980fd0acd3caf9e258e42788e38f5_0.gif",@"http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/0034821a-6815-4d64-b0f2-09103d62630d.jpg",@"http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/0be5118d-f550-403e-8e5c-6d0badb53648.jpg",@"http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/1466408576222.jpg", nil];
[self.manager addNetworkingImageToAlbum:array selected:YES];
// 设置完网络图片地址数组后重新刷新视图
[self.photoView refreshView];
```
### <a id="Demo4"></a> Demo4
```
- (HXPhotoManager *)manager {
    if (!_manager) {
        _manager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhoto];
        _manager.openCamera = YES;
        // 在这里设置为单选模式
        _manager.singleSelected = YES;
        // 单选模式下选择图片时是否直接跳转到编辑界面
        _manager.configuration.singleJumpEdit = YES;
        // 是否可移动的裁剪框
        _manager.configuration.movableCropBox = YES;
        // 可移动的裁剪框是否可以编辑大小
        _manager.configuration.movableCropBoxEditSize = YES;
    }
    return _manager;
}
__weak typeof(self) weakSelf = self;
[self hx_presentAlbumListViewControllerWithManager:self.manager done:^(NSArray<HXPhotoModel *> *allList, NSArray<HXPhotoModel *> *photoList, NSArray<HXPhotoModel *> *videoList, BOOL original, HXAlbumListViewController *viewController) {
    if (photoList.count > 0) {
//            HXPhotoModel *model = photoList.firstObject;
//            weakSelf.imageView.image = model.previewPhoto;
        [weakSelf.view showLoadingHUDText:@"获取图片中"];
        [weakSelf.toolManager getSelectedImageList:photoList requestType:0 success:^(NSArray<UIImage *> *imageList) {
            [weakSelf.view handleLoading];
            weakSelf.imageView.image = imageList.firstObject;
        } failed:^{
            [weakSelf.view handleLoading];
            [weakSelf.view showImageHUDText:@"获取失败"];
        }];
        NSSLog(@"%ld张图片",photoList.count);
    }else if (videoList.count > 0) {
        [weakSelf.toolManager getSelectedImageList:allList success:^(NSArray<UIImage *> *imageList) {
            weakSelf.imageView.image = imageList.firstObject;
        } failed:^{

        }];

        // 通个这个方法将视频压缩写入临时目录获取视频URL  或者 通过这个获取视频在手机里的原路径 model.fileURL  可自己压缩
        [weakSelf.view showLoadingHUDText:@"视频写入中"];
        [weakSelf.toolManager writeSelectModelListToTempPathWithList:videoList success:^(NSArray<NSURL *> *allURL, NSArray<NSURL *> *photoURL, NSArray<NSURL *> *videoURL) {
            NSSLog(@"%@",videoURL);
            [weakSelf.view handleLoading];
        } failed:^{
            [weakSelf.view handleLoading];
            [weakSelf.view showImageHUDText:@"写入失败"];
            NSSLog(@"写入失败");
        }];
        NSSLog(@"%ld个视频",videoList.count);
    }
} cancel:^(HXAlbumListViewController *viewController) {
    NSSLog(@"取消了");
}];
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
[self.manager addLocalImage:images selected:YES];
[photoView refreshView];
[scrollView addSubview:photoView];
self.photoView = photoView;
```
### <a id="Demo8"></a> Demo8
```
- (HXDatePhotoToolManager *)toolManager {
    if (!_toolManager) {
        _toolManager = [[HXDatePhotoToolManager alloc] init];
    }
    return _toolManager;
}
[self.view showLoadingHUDText:@"写入中"];
__weak typeof(self) weakSelf = self;
HXDatePhotoToolManagerRequestType requestType;
if (self.original) {
    requestType = HXDatePhotoToolManagerRequestTypeOriginal;
}else {
    requestType = HXDatePhotoToolManagerRequestTypeHD;
}
[self.toolManager writeSelectModelListToTempPathWithList:self.selectList requestType:requestType success:^(NSArray<NSURL *> *allURL, NSArray<NSURL *> *photoURL, NSArray<NSURL *> *videoURL) {
    NSSLog(@"\nall : %@ \nimage : %@ \nvideo : %@",allURL,photoURL,videoURL);
    NSURL *url = photoURL.firstObject;
    if (url) {
        UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:url]];
        NSSLog(@"%@",image);
    }
            [weakSelf.view handleLoading];
} failed:^{
    [weakSelf.view handleLoading];
    [weakSelf.view showImageHUDText:@"写入失败"];
    NSSLog(@"写入失败");
}];
```
### <a id="Demo9"></a> Demo9
```
具体代码请下载工程查看demo9
```

## <a id="更多"></a> 六.  更多 - More

- 如果您发现了bug请尽可能详细地描述系统版本、手机型号和复现步骤等信息 提一个issue.

- 如果您有什么好的建议也可以提issue,大家一起讨论一起学习进步...

- 具体代码请下载项目  如果觉得喜欢的能给一颗小星星么!  ✨✨✨

- [有兴趣可以加下创建的QQ群:531895229(有问题请先看Demo，因为工作很忙所以可能问问题没人回答!!)](//shang.qq.com/wpa/qunwpa?idkey=ebd8d6809c83b4d6b4a18b688621cb73ded0cce092b4d1f734e071a58dd37c26) <a target="_blank" href="http://wpa.qq.com/msgrd?v=3&uin=294005139&site=qq&menu=yes"><img border="0" src="http://wpa.qq.com/pa?p=2:294005139:52" alt="点击这里给我发消息" title="点击这里给我发消息"/></a>
