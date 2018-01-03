//
//  Demo2ViewController.m
//  微博照片选择
//
//  Created by 洪欣 on 17/2/17.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "Demo2ViewController.h" 
#import "HXPhotoPicker.h"

static const CGFloat kPhotoViewMargin = 12.0;

@interface Demo2ViewController ()<HXPhotoViewDelegate,UIImagePickerControllerDelegate>

@property (strong, nonatomic) HXPhotoManager *manager;
@property (strong, nonatomic) HXPhotoView *photoView;
@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) HXDatePhotoToolManager *toolManager;

@end

@implementation Demo2ViewController

- (HXDatePhotoToolManager *)toolManager {
    if (!_toolManager) {
        _toolManager = [[HXDatePhotoToolManager alloc] init];
    }
    return _toolManager;
}

- (HXPhotoManager *)manager {
    if (!_manager) {
        _manager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhotoAndVideo];
        _manager.configuration.openCamera = YES;
        _manager.configuration.lookLivePhoto = YES;
        _manager.configuration.photoMaxNum = 4;
        _manager.configuration.videoMaxNum = 6;
        _manager.configuration.maxNum = 10;
        _manager.configuration.videoMaxDuration = 500.f;
        _manager.configuration.saveSystemAblum = NO;
//        _manager.configuration.reverseDate = YES;
        _manager.configuration.showDateSectionHeader = NO;
        _manager.configuration.selectTogether = NO;
//        _manager.configuration.rowCount = 3;
//        _manager.configuration.movableCropBox = YES;
//        _manager.configuration.movableCropBoxEditSize = YES;
//        _manager.configuration.movableCropBoxCustomRatio = CGPointMake(1, 1);
        
        __weak typeof(self) weakSelf = self;
//        _manager.configuration.replaceCameraViewController = YES;
        _manager.configuration.shouldUseCamera = ^(UIViewController *viewController, HXPhotoConfigurationCameraType cameraType, HXPhotoManager *manager) {
            
            // 这里拿使用系统相机做例子
            UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
            imagePickerController.delegate = (id)weakSelf;
            imagePickerController.allowsEditing = NO;
            NSString *requiredMediaTypeImage = ( NSString *)kUTTypeImage;
            NSString *requiredMediaTypeMovie = ( NSString *)kUTTypeMovie;
            NSArray *arrMediaTypes;
            if (cameraType == HXPhotoConfigurationCameraTypePhoto) {
                arrMediaTypes=[NSArray arrayWithObjects:requiredMediaTypeImage,nil];
            }else if (cameraType == HXPhotoConfigurationCameraTypeVideo) {
                arrMediaTypes=[NSArray arrayWithObjects:requiredMediaTypeMovie,nil];
            }else {
                arrMediaTypes=[NSArray arrayWithObjects:requiredMediaTypeImage, requiredMediaTypeMovie,nil];
            }
            [imagePickerController setMediaTypes:arrMediaTypes];
            // 设置录制视频的质量
            [imagePickerController setVideoQuality:UIImagePickerControllerQualityTypeHigh];
            //设置最长摄像时间
            [imagePickerController setVideoMaximumDuration:60.f];
            imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
            imagePickerController.navigationController.navigationBar.tintColor = [UIColor whiteColor];
            imagePickerController.modalPresentationStyle=UIModalPresentationOverCurrentContext;
            [viewController presentViewController:imagePickerController animated:YES completion:nil];
        };
    }
    return _manager;
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    HXPhotoModel *model;
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
        UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
        model = [HXPhotoModel photoModelWithImage:image];
        if (self.manager.configuration.saveSystemAblum) {
            [HXPhotoTools savePhotoToCustomAlbumWithName:self.manager.configuration.customAlbumName photo:model.thumbPhoto];
        }
    }else  if ([mediaType isEqualToString:(NSString *)kUTTypeMovie]) {
        NSURL *url = info[UIImagePickerControllerMediaURL];
        NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]
                                                         forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
        AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:url options:opts];
        float second = 0;
        second = urlAsset.duration.value/urlAsset.duration.timescale;
        model = [HXPhotoModel photoModelWithVideoURL:url videoTime:second];
        if (self.manager.configuration.saveSystemAblum) {
            [HXPhotoTools saveVideoToCustomAlbumWithName:self.manager.configuration.customAlbumName videoURL:url];
        }
    }
    if (self.manager.configuration.useCameraComplete) {
        self.manager.configuration.useCameraComplete(model);
    }
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    scrollView.alwaysBounceVertical = YES;
    [self.view addSubview:scrollView];
    self.scrollView = scrollView;
    
    CGFloat width = scrollView.frame.size.width;
    HXPhotoView *photoView = [HXPhotoView photoManager:self.manager];
    photoView.frame = CGRectMake(kPhotoViewMargin, kPhotoViewMargin, width - kPhotoViewMargin * 2, 0);
    photoView.delegate = self;
    photoView.outerCamera = YES;
    photoView.backgroundColor = [UIColor whiteColor];
    [scrollView addSubview:photoView];
    self.photoView = photoView; 

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"相册/相机" style:UIBarButtonItemStylePlain target:self action:@selector(didNavBtnClick)];
}
- (void)didNavBtnClick {
    [self.photoView goPhotoViewController];
}

- (void)photoView:(HXPhotoView *)photoView changeComplete:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photos videos:(NSArray<HXPhotoModel *> *)videos original:(BOOL)isOriginal {
    NSSLog(@"所有:%ld - 照片:%ld - 视频:%ld",allList.count,photos.count,videos.count);
    NSSLog(@"所有:%@ - 照片:%@ - 视频:%@",allList,photos,videos);
    
    [HXPhotoTools selectListWriteToTempPath:allList requestList:^(NSArray *imageRequestIds, NSArray *videoSessions) {
        NSSLog(@"requestIds - image : %@ \nsessions - video : %@",imageRequestIds,videoSessions);
    } completion:^(NSArray<NSURL *> *allUrl, NSArray<NSURL *> *imageUrls, NSArray<NSURL *> *videoUrls) {
        NSSLog(@"allUrl - %@\nimageUrls - %@\nvideoUrls - %@",allUrl,imageUrls,videoUrls);
    } error:^{
        NSSLog(@"失败");
    }];
}
- (void)photoView:(HXPhotoView *)photoView deleteNetworkPhoto:(NSString *)networkPhotoUrl {
    NSSLog(@"%@",networkPhotoUrl);
}

- (void)photoView:(HXPhotoView *)photoView updateFrame:(CGRect)frame {
    NSSLog(@"%@",NSStringFromCGRect(frame));
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, CGRectGetMaxY(frame) + kPhotoViewMargin);
    
}

//
//// 压缩视频并写入沙盒文件
//- (void)compressedVideoWithURL:(id)url success:(void(^)(NSString *fileName))success failure:(void(^)())failure
//{
//    AVURLAsset *avAsset;
//    if ([url isKindOfClass:[NSURL class]]) {
//        avAsset = [AVURLAsset assetWithURL:url];
//    }else if ([url isKindOfClass:[AVAsset class]]) {
//        avAsset = (AVURLAsset *)url;
//    }
//    
//    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
//    
//    if ([compatiblePresets containsObject:AVAssetExportPresetHighestQuality]) {
//        
//        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:AVAssetExportPresetMediumQuality];
//        
//        NSString *fileName = @""; // 这里是自己定义的文件路径
//        
//        NSDate *nowDate = [NSDate date];
//        NSString *dateStr = [NSString stringWithFormat:@"%ld", (long)[nowDate timeIntervalSince1970]];
//        
//        NSString *numStr = [NSString stringWithFormat:@"%d",arc4random()%10000];
//        fileName = [fileName stringByAppendingString:dateStr];
//        fileName = [fileName stringByAppendingString:numStr];
//        
//        // ````` 这里取的是时间加上一些随机数  保证每次写入文件的路径不一样
//        fileName = [fileName stringByAppendingString:@".mp4"]; // 视频后缀
//        NSString *fileName1 = [NSTemporaryDirectory() stringByAppendingString:fileName]; //文件名称
//        exportSession.outputURL = [NSURL fileURLWithPath:fileName1];
//        exportSession.outputFileType = AVFileTypeMPEG4;
//        exportSession.shouldOptimizeForNetworkUse = YES;
//        
//        [exportSession exportAsynchronouslyWithCompletionHandler:^{
//            
//            switch (exportSession.status) {
//                case AVAssetExportSessionStatusCancelled:
//                    break;
//                case AVAssetExportSessionStatusCompleted:
//                {
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        if (success) {
//                            success(fileName1);
//                        }
//                    });
//                }
//                    break;
//                case AVAssetExportSessionStatusExporting:
//                    break;
//                case AVAssetExportSessionStatusFailed:
//                {
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        if (failure) {
//                            failure();
//                        }
//                    });
//                }
//                    break;
//                case AVAssetExportSessionStatusUnknown:
//                    break;
//                case AVAssetExportSessionStatusWaiting:
//                    break;
//                default:
//                    break;
//            }
//        }];
//    }
//}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
