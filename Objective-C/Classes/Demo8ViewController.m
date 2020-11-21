//
//  Demo8ViewController.m
//  HXPhotoPickerExample
//
//  Created by 洪欣 on 2017/9/14.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "Demo8ViewController.h" 
#import "HXPhotoView.h"
#import "HXPreviewVideoView.h"
#import "HXPhotoEdit.h"
static const CGFloat kPhotoViewMargin = 12.0;
@interface Demo8ViewController ()<HXPhotoViewDelegate>
@property (strong, nonatomic) HXPhotoManager *manager;
@property (strong, nonatomic) HXPhotoView *photoView;
@property (strong, nonatomic) UIScrollView *scrollView;

@property (copy, nonatomic) NSArray *selectList;
@property (copy, nonatomic) NSArray *imageRequestIds;
@property (copy, nonatomic) NSArray *videoSessions;

@property (assign, nonatomic) BOOL original;

@end

@implementation Demo8ViewController

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        [self preferredStatusBarUpdateAnimation];
        [self changeStatus];
    }
#endif
}
- (UIStatusBarStyle)preferredStatusBarStyle {
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        if (UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            return UIStatusBarStyleLightContent;
        }
    }
#endif
    return UIStatusBarStyleDefault;
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self changeStatus];
}
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
- (void)changeStatus {
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        if (UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
            return;
        }
    }
#endif
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}
#pragma clang diagnostic pop
- (HXPhotoManager *)manager {
    if (!_manager) {
        _manager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhotoAndVideo];
//        _manager.configuration.requestImageAfterFinishingSelection = YES;
        _manager.configuration.openCamera = YES;
        _manager.configuration.photoMaxNum = 9;
        _manager.configuration.videoMaxNum = 9;
        _manager.configuration.maxNum = 18;
        _manager.configuration.lookLivePhoto = YES;
        _manager.configuration.selectTogether = YES;
    }
    return _manager;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    // Fallback on earlier versions
    self.view.backgroundColor = [UIColor whiteColor];
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        self.view.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return UIColor.blackColor;
            }
            return UIColor.whiteColor;
        }];
    }
#endif
    //    self.navigationController.navigationBar.translucent = NO;
    self.automaticallyAdjustsScrollViewInsets = YES;
    
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    scrollView.alwaysBounceVertical = YES;
    [self.view addSubview:scrollView];
    self.scrollView = scrollView;
    
    CGFloat width = scrollView.frame.size.width;
    HXPhotoView *photoView = [[HXPhotoView alloc] initWithFrame:CGRectMake(kPhotoViewMargin, kPhotoViewMargin, width - kPhotoViewMargin * 2, 0) manager:self.manager];
    photoView.delegate = self; 
    [photoView refreshView];
    [scrollView addSubview:photoView];
    self.photoView = photoView;
    
    UIBarButtonItem *item1 = [[UIBarButtonItem alloc] initWithTitle:@"获取(具体看代码)" style:UIBarButtonItemStylePlain target:self action:@selector(didNavOneBtnClick)];
//    UIBarButtonItem *item2 = [[UIBarButtonItem alloc] initWithTitle:@"保存livePhoto" style:UIBarButtonItemStylePlain target:self action:@selector(didNavTwoBtnClick)];
    self.navigationItem.rightBarButtonItems = @[item1];
}

- (void)didNavOneBtnClick {
    // 如果将_manager.configuration.requestImageAfterFinishingSelection 设为YES，
    // 那么在选择完成的时候就会获取图片和视频地址
    // 如果选中了原图那么获取图片时就是原图
    // 获取视频时如果设置 exportVideoURLForHighestQuality 为YES，则会去获取高等质量的视频。其他情况为中等质量的视频
    // 个人建议不在选择完成的时候去获取，因为每次选择完都会去获取。获取过程中可能会耗时过长
    // 可以在要上传的时候再去获取
    for (HXPhotoModel *model in self.selectList) {
        // 数组里装的是所有类型的资源，需要判断
        // 先判断资源类型
        if (model.subType == HXPhotoModelMediaSubTypePhoto) {
            // 当前为图片
            if (model.photoEdit) {
                // 如果有编辑数据，则说明这张图篇被编辑过了
                // 需要这样才能获取到编辑之后的图片
//                model.photoEdit.editPreviewImage;
                return;
            }
            // 再判断具体类型
            if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
                // 到这里就说明这张图片不是手机相册里的图片，可能是本地的也可能是网络图片
                // 关于相机拍照的的问题，当系统 < ios9.0的时候拍的照片虽然保存到了相册但是在列表里存的是本地的，没有PHAsset
                // 当系统 >= ios9.0 的时候拍的照片就不是本地照片了，而是手机相册里带有PHAsset对象的照片
                // 这里的 model.asset PHAsset是空的
                // 判断具体类型
                if (model.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeLocal) {
                    // 本地图片
                
                }else if (model.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeLocalGif) {
                    // 本地gif图片
                    
                }else if (model.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeNetWork) {
                    // 网络图片
                
                }else if (model.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeNetWorkGif) {
                    // 网络gif图片
                    
                }else if (model.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeLocalLivePhoto) {
                    // 本地livePhoto
                    
                }else if (model.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeNetWorkLivePhoto) {
                    // 网络livePhoto
                    
                }
                // 上传图片的话可以不用判断具体类型，按下面操作取出图片
                if (model.networkPhotoUrl) {
                    // 如果网络图片地址有值就说明是网络图片，可直接拿此地址直接使用。避免重复上传
                    // 这里需要注意一下，先要判断是否为图片。因为如果是网络视频的话此属性代表视频封面地址
                    
                }else {
                    // 网络图片地址为空了，那就肯定是本地图片了
                    // 直接取 model.previewPhoto 或者 model.thumbPhoto，这两个是同一个image
                    
                }
            }else {
                // 到这里就是手机相册里的图片了 model.asset PHAsset对象是有值的
                // 如果需要上传 Gif 或者 LivePhoto 需要具体判断
                if (model.type == HXPhotoModelMediaTypePhoto) {
                    // 普通的照片，如果不可以查看和livePhoto的时候，这就也可能是GIF或者LivePhoto了，
                    // 如果你的项目不支持动图那就不要取NSData或URL，因为如果本质是动图的话还是会变成动图传上去
                    // 这样判断是不是GIF model.photoFormat == HXPhotoModelFormatGIF
                    
                    // 如果 requestImageAfterFinishingSelection = YES 的话，直接取 model.previewPhoto 或者 model.thumbPhoto 在选择完成时候已经获取并且赋值了
                    // 获取image
                    // size 就是获取图片的质量大小，原图的话就是 PHImageManagerMaximumSize，其他质量可设置size来获取
                    CGSize size;
                    if (self.original) {
                        size = PHImageManagerMaximumSize;
                    }else {
                        size = CGSizeMake(model.imageSize.width * 0.5, model.imageSize.height * 0.5);
                    }
                    [model requestPreviewImageWithSize:size startRequestICloud:^(PHImageRequestID iCloudRequestId, HXPhotoModel * _Nullable model) {
                        // 如果图片是在iCloud上的话会先走这个方法再去下载
                    } progressHandler:^(double progress, HXPhotoModel * _Nullable model) {
                        // iCloud的下载进度
                    } success:^(UIImage * _Nullable image, HXPhotoModel * _Nullable model, NSDictionary * _Nullable info) {
                        // image
                    } failed:^(NSDictionary * _Nullable info, HXPhotoModel * _Nullable model) {
                        // 获取失败
                    }];
                }else if (model.type == HXPhotoModelMediaTypePhotoGif) {
                    // 动图，如果 requestImageAfterFinishingSelection = YES 的话，直接取 model.imageURL。因为在选择完成的时候已经获取了不用再去获取
//                    model.imageURL;
                    // 上传动图时，不要直接拿image上传哦。可以获取url或者data上传
                    // 获取url
                    [model requestImageURLStartRequestICloud:nil progressHandler:nil success:^(NSURL * _Nullable imageURL, HXPhotoModel * _Nullable model, NSDictionary * _Nullable info) {
                        // 下载完成，imageURL 本地地址
                    } failed:nil];
                    
                    // 获取data
                    [model requestImageDataStartRequestICloud:nil progressHandler:nil success:^(NSData * _Nullable imageData, UIImageOrientation orientation, HXPhotoModel * _Nullable model, NSDictionary * _Nullable info) {
                        // imageData
                    } failed:nil];
                }else if (model.type == HXPhotoModelMediaTypeLivePhoto) {
                    // LivePhoto，requestImageAfterFinishingSelection = YES 时没有处理livephoto，需要自己处理
                    // 如果需要上传livephoto的话，需要上传livephoto里的图片和视频
                    // 展示的时候需要根据图片和视频生成livephoto
                    [model requestLivePhotoAssetsWithSuccess:^(NSURL * _Nullable imageURL, NSURL * _Nullable videoURL, BOOL isNetwork, HXPhotoModel * _Nullable model) {
                        // imageURL - LivePhoto里的照片封面地址
                        // videoURL - LivePhoto里的视频地址
                        
                    } failed:^(NSDictionary * _Nullable info, HXPhotoModel * _Nullable model) {
                        // 获取失败
                    }];
                }
                // 也可以不用上面的判断和方法获取，自己根据 model.asset 这个PHAsset对象来获取想要的东西
//                PHAsset *asset = model.asset;
                // 自由发挥
            }
            
        }else if (model.subType == HXPhotoModelMediaSubTypeVideo) {
            // 当前为视频
            if (model.type == HXPhotoModelMediaTypeVideo) {
                // 为手机相册里的视频
                // requestImageAfterFinishingSelection = YES 时，直接去 model.videoURL，在选择完成时已经获取了
//                model.videoURL;
                // 获取视频时可以获取 AVAsset，也可以获取 AVAssetExportSession，获取之后再导出视频
                // 获取 AVAsset
                [model requestAVAssetStartRequestICloud:nil progressHandler:nil success:^(AVAsset * _Nullable avAsset, AVAudioMix * _Nullable audioMix, HXPhotoModel * _Nullable model, NSDictionary * _Nullable info) {
                    // avAsset
                    // 自己根据avAsset去导出视频
                } failed:nil];
                
                // 获取 AVAssetExportSession
                [model requestAVAssetExportSessionStartRequestICloud:nil progressHandler:nil success:^(AVAssetExportSession * _Nullable assetExportSession, HXPhotoModel * _Nullable model, NSDictionary * _Nullable info) {
                    
                } failed:nil];
                
                // HXPhotoModel也提供直接导出视频地址的方法
                // presetName 导出视频的质量，自己根据需求设置
                [model exportVideoWithPresetName:AVAssetExportPresetMediumQuality startRequestICloud:nil iCloudProgressHandler:nil exportProgressHandler:^(float progress, HXPhotoModel * _Nullable model) {
                    // 导出视频时的进度，在iCloud下载完成之后
                } success:^(NSURL * _Nullable videoURL, HXPhotoModel * _Nullable model) {
                    // 导出完成, videoURL
                    
                } failed:nil];
                
                // 也可以不用上面的方法获取，自己根据 model.asset 这个PHAsset对象来获取想要的东西
//                PHAsset *asset = model.asset;
                // 自由发挥
            }else {
                // 本地视频或者网络视频
                if (model.cameraVideoType == HXPhotoModelMediaTypeCameraVideoTypeLocal) {
                    // 本地视频
                    // model.videoURL 视频的本地地址
                }else if (model.cameraVideoType == HXPhotoModelMediaTypeCameraVideoTypeNetWork) {
                    // 网络视频
                    // model.videoURL 视频的网络地址
                    // model.networkPhotoUrl 视频封面网络地址
                }
            }
        }
    }
}

- (void)didNavTwoBtnClick {
    
}

- (void)photoView:(HXPhotoView *)photoView changeComplete:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photos videos:(NSArray<HXPhotoModel *> *)videos original:(BOOL)isOriginal {
    self.original = isOriginal;
    self.selectList = allList;
    NSSLog(@"%@",allList);
}

- (void)photoView:(HXPhotoView *)photoView updateFrame:(CGRect)frame {
    NSSLog(@"%@",NSStringFromCGRect(frame));
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, CGRectGetMaxY(frame) + kPhotoViewMargin);
    
}

@end
