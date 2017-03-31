//
//  Demo2ViewController.m
//  微博照片选择
//
//  Created by 洪欣 on 17/2/17.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "Demo2ViewController.h"
#import "HXPhotoViewController.h"
#import "HXPhotoView.h"
@interface Demo2ViewController ()<HXPhotoViewDelegate>
@property (strong, nonatomic) HXPhotoManager *manager;
@end

@implementation Demo2ViewController

/**
    HXPhotoManager 照片管理类的属性介绍
 
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
        _manager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhotoAndVideo];
//        _manager.openCamera = NO;
        _manager.outerCamera = YES;
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
}

- (void)photoViewChangeComplete:(NSArray<HXPhotoModel *> *)allList Photos:(NSArray<HXPhotoModel *> *)photos Videos:(NSArray<HXPhotoModel *> *)videos Original:(BOOL)isOriginal
{
    NSLog(@"%ld - %ld - %ld",allList.count,photos.count,videos.count);
    
    /*
     关于为什么照片模型里面只有 thumbPhoto 这个才有值
     为了优化相册列表以及预览大图列表快速滑动内存暴增的问题，
     如果缓存了imageData或者原图的image,用户图片过多时这会导致内存的增大,
     而且当快速滑动遇到图片过大时可能导致滑动卡顿 / 内存警告⚠️程序被杀。
     故不缓存imageData和image 只保留 thumbPhoto 缩略图   
     这样可以保证在选择照片/快速滑动过程中,不会因为内存过大导致程序被杀 和 滑动流畅丝滑。
     所以要获取已选图片的原图可以选择HXPhotoTools提供的快速获取已选照片的全部原图 或
     快速获取已选照片的全图高清图片,获取高清图片消耗内存很小而且图片质量也很高
     当然您也可以自己根据指定方法控制传入的size来获取不同质量的图片。
     提醒：在用户没有选择原图的时候不要使用原图上传，获取image时size稍微缩小一点这样可以保证上传快内存消耗小一点。在使用快速获取原图方法时,请将这个方法写在上传方法里! 在获取原图Image的过程中会比较消耗内存.
     */
    
    // 获取数组里面图片的 HD(高清)图片  传入的数组里装的是 HXPhotoModel  -- 这个方法必须写在点击上传的位置
    [HXPhotoTools fetchHDImageForSelectedPhoto:photos completion:^(NSArray<UIImage *> *images) {
        NSLog(@"%@",images);
    }];
    /*
     如果真的觉得这个方法获取的高清图片还达不到你想要的效果,你可以按住 command 点击上面方法修改以下属性来获取你想要的图片
     
        // 这里的size 是普通图片的时候  想要更高质量的图片 可以把 1.5 换成 2 或者 3
            如果觉得内存消耗过大可以 调小一点
     
         CGSize size = CGSizeMake(model.endImageSize.width * 1.5, model.endImageSize.height * 1.5);
     
        // 这里是判断图片是否过长 因为图片如果长了 上面的size就显的有点小了获取出来的图片就变模糊了,所以这里把宽度 换成了屏幕的宽度,这个可以保证即不影响内存也不影响质量 如果觉得质量达不到你的要求,可以乘上 1.5 或者 2 . 当然你也可以不按我这样给size,自己测试怎么给都可以
         if (model.endImageSize.height > model.endImageSize.width / 9 * 20) {
            size = CGSizeMake([UIScreen mainScreen].bounds.size.width, model.endImageSize.height);
         }
     */
    
    
    // 获取数组里面图片原图的 imageData 资源 传入的数组里装的是 HXPhotoModel  -- 这个方法必须写在点击上传的位置
    [HXPhotoTools fetchImageDataForSelectedPhoto:photos completion:^(NSArray<NSData *> *imageDatas) {
        NSLog(@"%ld",imageDatas.count);
    }];
    
    //  获取数组里面图片的原图 传入的数组里装的是 HXPhotoModel  -- 这个方法必须写在点击上传的地方获取 此方法会增大内存. 获取原图图片之后请将选中数组中模型里面的数据全部清空
//    [HXPhotoTools fetchOriginalForSelectedPhoto:photos completion:^(NSArray<UIImage *> *images) {
//        NSLog(@"%@",images);
//    }];
     
    /*
     
    // 获取图片资源
    [photos enumerateObjectsUsingBlock:^(HXPhotoModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
        // 小图  - 这个字段会一直有值
        model.thumbPhoto;
        
        // 大图  - 这个字段没有值,  如果是通过相机拍照的这个字段一直有值跟 thumbPhoto 是一样的
        model.previewPhoto;
        
        // imageData  - 这个字段没有值 请根据指定方法获取
        model.imageData;
        
        // livePhoto  - 这个字段只有当查看过livePhoto之后才会有值
        model.livePhoto;
        
        // isCloseLivePhoto 判断当前图片是否关闭了 livePhoto 功能 YES-关闭 NO-开启
        model.isCloseLivePhoto;
        
        // 获取imageData - 通过相册获取时有用 / 通过相机拍摄的无效
        [HXPhotoTools FetchPhotoDataForPHAsset:model.asset completion:^(NSData *imageData, NSDictionary *info) {
            NSLog(@"%@",imageData);
        }];
        
        // 获取image - PHImageManagerMaximumSize 是原图尺寸 - 通过相册获取时有用 / 通过相机拍摄的无效
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
     
     */
}

- (void)photoViewUpdateFrame:(CGRect)frame WithView:(UIView *)view
{
    NSLog(@"%@",NSStringFromCGRect(frame));
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
