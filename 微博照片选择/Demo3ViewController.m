//
//  Demo3ViewController.m
//  微博照片选择
//
//  Created by 洪欣 on 17/2/17.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "Demo3ViewController.h"
#import "HXPhotoViewController.h"
#import "HXPhotoView.h"

 

@interface Demo3ViewController ()<HXPhotoViewDelegate>
@property (strong, nonatomic) HXPhotoManager *manager;
@property (weak, nonatomic) HXPhotoView *photoView;
@end

@implementation Demo3ViewController

/**
 HXPhotoManager 照片管理类的属性介绍
 
 showDeleteNetworkPhotoAlert; 删除网络图片时是否显示Alert // 默认显示


 网络图片地址数组  networkPhotoUrls;
 
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
 
 */

- (HXPhotoManager *)manager
{
    if (!_manager) {
        _manager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhoto];
        //        _manager.openCamera = NO;
        _manager.outerCamera = YES;
        _manager.showDeleteNetworkPhotoAlert = NO;
        _manager.photoMaxNum = 2; // 这里需要注意 !!!  第一次传入的最大照片数 是可选最大数 减去 网络照片数量   即   photoMaxNum = maxNum - networkPhotoUrls.count  当点击删除网络照片时, photoMaxNum 内部会自动加1
        _manager.videoMaxNum = 0;  // 如果有网络图片且选择类型为HXPhotoManagerSelectedTypePhotoAndVideo 又设置了视频最大数且不为0时,
//        那么在选择照片列表最大只能选择 photoMaxNum + videoMaxNum
//        在外面collectionView上最大数是 photoMaxNum + networkPhotoUrls.count + videoMaxNum
        _manager.maxNum = 6;
        
//        _manager.networkPhotoUrls = [NSMutableArray arrayWithObjects:@"http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/003d86db-b140-4162-aafa-d38056742181.jpg",@"http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/0034821a-6815-4d64-b0f2-09103d62630d.jpg",@"http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/0be5118d-f550-403e-8e5c-6d0badb53648.jpg",@"http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/1466408576222.jpg", nil];
    }
    return _manager;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationController.navigationBar.translucent = NO;
    self.automaticallyAdjustsScrollViewInsets = YES;
    CGFloat width = self.view.frame.size.width;
    HXPhotoView *photoView = [HXPhotoView photoManager:self.manager];
    photoView.frame = CGRectMake(12, 100, width - 24, 0);
    photoView.delegate = self;
    photoView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:photoView];
    self.photoView = photoView;
    
    // 可以在懒加载中赋值 ,  也可以这样赋值
    self.manager.networkPhotoUrls = [NSMutableArray arrayWithObjects:@"http://oss-cn-hangzhou.aliyuncs.com/tsnrhapp/shop/photos/857980fd0acd3caf9e258e42788e38f5_0.gif",@"http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/0034821a-6815-4d64-b0f2-09103d62630d.jpg",@"http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/0be5118d-f550-403e-8e5c-6d0badb53648.jpg",@"http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/1466408576222.jpg", nil];
    
    photoView.manager = self.manager;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"查看" style:UIBarButtonItemStylePlain target:self action:@selector(lookClick)];
    
}

- (void)lookClick {
    if ([self.photoView networkingPhotoDownloadComplete]) {
        NSSLog(@"网络图片全部下载完成");
    }else {
        NSSLog(@"网络图片未下载完");
    }
    NSSLog(@"已下载的网络图片----->%ld",[self.photoView downloadNumberForNetworkingPhoto]);
    [self.view showImageHUDText:[NSString stringWithFormat:@"已下载的网络图片数量%ld张",[self.photoView downloadNumberForNetworkingPhoto]]];
}

- (void)photoView:(HXPhotoView *)photoView changeComplete:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photos videos:(NSArray<HXPhotoModel *> *)videos original:(BOOL)isOriginal {
    NSSLog(@"所有:%ld - 照片:%ld - 视频:%ld",allList.count,photos.count,videos.count);
    
    [HXPhotoTools getImageForSelectedPhoto:photos type:HXPhotoToolsFetchHDImageType completion:^(NSArray<UIImage *> *images) {
        NSSLog(@"%@",images);
    }];
    /*
     // 获取image - PHImageManagerMaximumSize 是原图尺寸 - 通过相册获取时有用 / 通过相机拍摄的无效
     CGSize size = PHImageManagerMaximumSize; // 通过传入 size 的大小来控制图片的质量
     [HXPhotoTools FetchPhotoForPHAsset:model.asset Size:size resizeMode:PHImageRequestOptionsResizeModeFast completion:^(UIImage *image, NSDictionary *info) {
     NSSLog(@"%@",image);
     }];
     
     // 这里的size 是普通图片的时候  想要更高质量的图片 可以把 1.5 换成 2 或者 3
     如果觉得内存消耗过大可以 调小一点
     
     CGSize size = CGSizeMake(model.endImageSize.width * 1.5, model.endImageSize.height * 1.5);
     
     // 这里是判断图片是否过长 因为图片如果长了 上面的size就显的有点小了获取出来的图片就变模糊了,所以这里把宽度 换成了屏幕的宽度,这个可以保证即不影响内存也不影响质量 如果觉得质量达不到你的要求,可以乘上 1.5 或者 2 . 当然你也可以不按我这样给size,自己测试怎么给都可以
     if (model.endImageSize.height > model.endImageSize.width / 9 * 20) {
     size = CGSizeMake([UIScreen mainScreen].bounds.size.width, model.endImageSize.height);
     }
     */
    
    /*
     // 获取图片资源
     [photos enumerateObjectsUsingBlock:^(HXPhotoModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
     // 封面小图
     model.thumbPhoto;
     
     // 预览大图 - 只有在查看大图的时候选中之后才有值
     model.previewPhoto;
     
     // imageData  - 这个字段没有值 请根据指定方法获取
     model.imageData;
     
     // isCloseLivePhoto 判断当前图片是否关闭了 livePhoto 功能 YES-关闭 NO-开启
     model.isCloseLivePhoto;
     
     // 获取imageData - 通过相册获取时有用 / 通过相机拍摄的无效
     [HXPhotoTools FetchPhotoDataForPHAsset:model.asset completion:^(NSData *imageData, NSDictionary *info) {
        NSSLog(@"%@",imageData);
     }];
     
     // 获取image - PHImageManagerMaximumSize 是原图尺寸 - 通过相册获取时有用 / 通过相机拍摄的无效
     CGSize size = PHImageManagerMaximumSize; // 通过传入 size 的大小来控制图片的质量
     [HXPhotoTools FetchPhotoForPHAsset:model.asset Size:size resizeMode:PHImageRequestOptionsResizeModeFast completion:^(UIImage *image, NSDictionary *info) {
     NSSLog(@"%@",image);
     }];
     
     // 如果是通过相机拍摄的照片只有 thumbPhoto、previewPhoto和imageSize 这三个字段有用可以通过 type 这个字段判断是不是通过相机拍摄的
     if (model.type == HXPhotoModelMediaTypeCameraPhoto);
     }];
     
     // 如果是相册选取的视频 要获取视频URL 必须先将视频压缩写入文件,得到的文件路径就是视频的URL 如果是通过相机录制的视频那么 videoURL 这个字段就是视频的URL 可以看需求看要不要压缩
     [videos enumerateObjectsUsingBlock:^(HXPhotoModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
     
     // 视频封面
     model.thumbPhoto;
     
     // 视频封面 大图 - 只有在查看大图的时候选中之后才有值
     model.previewPhoto;
     
     // 如果是通过相机录制的视频 需要通过 model.VideoURL 这个字段来压缩写入文件
        if (model.type == HXPhotoModelMediaTypeCameraVideo) {
            [self compressedVideoWithURL:model.videoURL success:^(NSString *fileName) {
                NSSLog(@"%@",fileName); // 视频路径也是视频URL;
            } failure:^{
            // 压缩写入失败
            }];
        }else { // 如果是在相册里面选择的视频就需要用过 model.avAsset 这个字段来压缩写入文件
            [self compressedVideoWithURL:model.avAsset success:^(NSString *fileName) {
                NSSLog(@"%@",fileName); // 视频路径也是视频URL;
            } failure:^{
                // 压缩写入失败
            }];
        }
     }];
     
     */
     // 判断照片、视频 或 是否是通过相机拍摄的
//     [allList enumerateObjectsUsingBlock:^(HXPhotoModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
//         if (model.type == HXPhotoModelMediaTypeCameraVideo) {
//         // 通过相机录制的视频
//         }else if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
//         // 通过相机拍摄的照片
//             if (model.networkPhotoUrl.length > 0) {
//                 NSSLog(@"网络图片");
//             }else {
//                 NSSLog(@"相机拍摄的照片");
//             }
//         }else if (model.type == HXPhotoModelMediaTypePhoto) {
//         // 相册里的照片
//         }else if (model.type == HXPhotoModelMediaTypePhotoGif) {
//         // 相册里的GIF图
//         }else if (model.type == HXPhotoModelMediaTypeLivePhoto) {
//         // 相册里的livePhoto
//         }
//     }];
    
}

- (void)photoView:(HXPhotoView *)photoView deleteNetworkPhoto:(NSString *)networkPhotoUrl {
    NSSLog(@"%@",networkPhotoUrl);
}

- (void)photoView:(HXPhotoView *)photoView updateFrame:(CGRect)frame
{
    NSSLog(@"%@",NSStringFromCGRect(frame));
}

- (void)photoViewAllNetworkingPhotoDownloadComplete:(HXPhotoView *)photoView {
    NSSLog(@"所有网络图片下载完成");
    /*
     网络图片全部下载完成之后会的调一下这个方法
     // 代理返回 选择、移动顺序、删除之后的图片以及视频
     - (void)photoView:(HXPhotoView *)photoView changeComplete:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photos videos:(NSArray<HXPhotoModel *> *)videos original:(BOOL)isOriginal;
     */
}

// 压缩视频并写入沙盒文件
- (void)compressedVideoWithURL:(id)url success:(void(^)(NSString *fileName))success failure:(void(^)())failure
{
    AVURLAsset *avAsset;
    if ([url isKindOfClass:[NSURL class]]) {
        avAsset = [AVURLAsset assetWithURL:url];
    }else if ([url isKindOfClass:[AVAsset class]]) {
        avAsset = (AVURLAsset *)url;
    }
    
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
    
    if ([compatiblePresets containsObject:AVAssetExportPresetHighestQuality]) {
        
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:AVAssetExportPresetMediumQuality];
        
        NSString *fileName = @""; // 这里是自己定义的文件路径
        
        NSDate *nowDate = [NSDate date];
        NSString *dateStr = [NSString stringWithFormat:@"%ld", (long)[nowDate timeIntervalSince1970]];
        
        NSString *numStr = [NSString stringWithFormat:@"%d",arc4random()%10000];
        fileName = [fileName stringByAppendingString:dateStr];
        fileName = [fileName stringByAppendingString:numStr];
        
        // ````` 这里取的是时间加上一些随机数  保证每次写入文件的路径不一样
        fileName = [fileName stringByAppendingString:@".mp4"]; // 视频后缀
        NSString *fileName1 = [NSTemporaryDirectory() stringByAppendingString:fileName]; //文件名称
        exportSession.outputURL = [NSURL fileURLWithPath:fileName1];
        exportSession.outputFileType = AVFileTypeMPEG4;
        exportSession.shouldOptimizeForNetworkUse = YES;
        
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            
            switch (exportSession.status) {
                case AVAssetExportSessionStatusCancelled:
                    break;
                case AVAssetExportSessionStatusCompleted:
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (success) {
                            success(fileName1);
                        }
                    });
                }
                    break;
                case AVAssetExportSessionStatusExporting:
                    break;
                case AVAssetExportSessionStatusFailed:
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (failure) {
                            failure();
                        }
                    });
                }
                    break;
                case AVAssetExportSessionStatusUnknown:
                    break;
                case AVAssetExportSessionStatusWaiting:
                    break;
                default:
                    break;
            }
        }];
    }
}

@end
