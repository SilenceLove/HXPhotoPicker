# HXWeiboPhotoPicker

    模仿微博照片选择器,支持多选、选原图和视频的图片选择器，同时有3Dtouch预览功能,长按拖动改变顺序.通过相机拍照录制视频  - 支持ios8.0 以上

   <img src="https://oss-cn-hangzhou.aliyuncs.com/tsnrhapp/shop/photos/d15641ec563550d1c528313ba75abf46_2.png" width="200" height="300">
   <img src="https://oss-cn-hangzhou.aliyuncs.com/tsnrhapp/shop/photos/37b5ca9ae12fb14070823e567837d9ca_0.png" width="200" height="300"> 
   <img src="https://oss-cn-hangzhou.aliyuncs.com/tsnrhapp/shop/photos/122849ae312dc181ecd312c426843c38_1.png" width="200" height="300">

## 一. 安装

    手动导入：将项目中的“HXWeiboPhotoPicker”文件夹拖入项目中
        只使用照片选择功能 导入头文件 "HXPhotoViewController.h"
        选完照片/视频后自动布局功能 导入头文件 "HXPhotoView.h"

## 二. 例子
   ### Demo1
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
   ### Demo2
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
## 三. 更多 

    具体代码看请下载项目
    发现的哪里有不好或不对的地方麻烦请联系我,大家一起讨论一起学习进步... 
    QQ : 294005139
    QQ群 : 531895229

