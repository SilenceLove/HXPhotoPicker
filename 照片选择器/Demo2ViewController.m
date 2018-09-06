//
//  Demo2ViewController.m
//  照片选择器
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

@property (strong, nonatomic) UIButton *bottomView;

@property (assign, nonatomic) BOOL needDeleteItem;

@property (assign, nonatomic) BOOL showHud;

@end

@implementation Demo2ViewController
- (UIButton *)bottomView {
    if (!_bottomView) {
        _bottomView = [UIButton buttonWithType:UIButtonTypeCustom];
        [_bottomView setTitle:@"删除" forState:UIControlStateNormal];
        [_bottomView setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_bottomView setBackgroundColor:[UIColor redColor]];
        _bottomView.frame = CGRectMake(0, self.view.hx_h - 50, self.view.hx_w, 50);
        _bottomView.alpha = 0;
    }
    return _bottomView;
}
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
        _manager.configuration.photoMaxNum = 9;
        _manager.configuration.videoMaxNum = 1;
        _manager.configuration.maxNum = 9;
        _manager.configuration.videoMaxDuration = 500.f;
        _manager.configuration.saveSystemAblum = YES;
//        _manager.configuration.reverseDate = YES;
        _manager.configuration.showDateSectionHeader = NO;
        _manager.configuration.selectTogether = NO;
//        _manager.configuration.rowCount = 3;
//        _manager.configuration.movableCropBox = YES;
//        _manager.configuration.movableCropBoxEditSize = YES;
//        _manager.configuration.movableCropBoxCustomRatio = CGPointMake(1, 1);
        _manager.configuration.requestImageAfterFinishingSelection = YES;
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
    photoView.previewShowDeleteButton = YES;
//    photoView.hideDeleteButton = YES;
    photoView.showAddCell = YES;
    [photoView.collectionView reloadData];
    photoView.backgroundColor = [UIColor whiteColor];
    [scrollView addSubview:photoView];
    self.photoView = photoView;
    
//    [self.view showLoadingHUDText:nil];
//    HXWeakSelf
//    [HXPhotoTools getSelectedModelArrayWithManager:self.manager complete:^(NSArray<HXPhotoModel *> *modelArray) {
//        [weakSelf.manager addModelArray:modelArray];
//        [weakSelf.photoView refreshView];
//        [weakSelf.view handleLoading];
//    }];

//    UIBarButtonItem *saveItem = [[UIBarButtonItem alloc] initWithTitle:@"草稿" style:UIBarButtonItemStylePlain target:self action:@selector(savaClick)];
    UIBarButtonItem *cameraItem = [[UIBarButtonItem alloc] initWithTitle:@"相册/相机" style:UIBarButtonItemStylePlain target:self action:@selector(didNavBtnClick)];
    
    self.navigationItem.rightBarButtonItems = @[cameraItem];
    
    [self.view addSubview:self.bottomView];
}
- (void)dealloc {
    NSSLog(@"dealloc");
}
- (void)savaClick {
//    [self.view showLoadingHUDText:@"保存中"];
//    HXWeakSelf
//    [HXPhotoTools saveSelectModelArrayWithManager:self.manager success:^{
//        [weakSelf.view handleLoading];
//    } failed:^{
//        [weakSelf.view showImageHUDText:@"保存草稿失败啦!"];
//    }];
    
    
//    NSMutableArray *gifModel = [NSMutableArray array];
//    for (HXPhotoModel *model in self.manager.afterSelectedArray) {
//        if (model.type == HXPhotoModelMediaTypePhotoGif && !model.gifImageData) {
//            [gifModel addObject:model];
//        }
//    }
//    if (gifModel.count) {
//        HXWeakSelf
//        [self.toolManager gifModelAssignmentData:gifModel success:^{
//            BOOL success = [HXPhotoTools saveSelectModelArray:weakSelf.manager.afterSelectedArray fileName:@"ModelArray"];
//            if (!success) {
//                [weakSelf.view showImageHUDText:@"保存草稿失败啦!"];
//            }else {
//                [weakSelf.view handleLoading];
//            }
//        } failed:^{
//            [weakSelf.view showImageHUDText:@"保存草稿失败啦!"];
//        }];
//    }else {
//        BOOL success = [HXPhotoTools saveSelectModelArray:self.manager.afterSelectedArray fileName:@"ModelArray"];
//        if (!success) {
//            [self.view showImageHUDText:@"保存草稿失败啦!"];
//        }else {
//            [self.view handleLoading];
//        }
//    }
}
- (void)didNavBtnClick {
//    [HXPhotoTools deleteLocalSelectModelArrayWithManager:self.manager];
    
    if (self.manager.configuration.specialModeNeedHideVideoSelectBtn && !self.manager.configuration.selectTogether && self.manager.configuration.videoMaxNum == 1) {
        if (self.manager.afterSelectedVideoArray.count) {
            [self.view showImageHUDText:@"请先删除视频"];
            return;
        }
    }
    [self.photoView goPhotoViewController];
}

- (void)photoView:(HXPhotoView *)photoView changeComplete:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photos videos:(NSArray<HXPhotoModel *> *)videos original:(BOOL)isOriginal {
//    NSSLog(@"所有:%ld - 照片:%ld - 视频:%ld",allList.count,photos.count,videos.count);
//    NSSLog(@"所有:%@ - 照片:%@ - 视频:%@",allList,photos,videos); 
//    HXWeakSelf
//    [self.toolManager getSelectedImageDataList:allList success:^(NSArray<NSData *> *imageDataList) {
//        NSSLog(@"%ld",imageDataList.count);
//    } failed:^{
//
//    }];
//    if (!self.showHud) {
//        self.showHud = YES;
//        [self.toolManager writeSelectModelListToTempPathWithList:allList success:^(NSArray<NSURL *> *allURL, NSArray<NSURL *> *photoURL, NSArray<NSURL *> *videoURL) {
//            NSSLog(@"allUrl - %@\nimageUrls - %@\nvideoUrls - %@",allURL,photoURL,videoURL);
//            NSMutableArray *array = [NSMutableArray array];
//            for (NSURL *url in allURL) {
//                [array addObject:url.absoluteString];
//            }
//            [[[UIAlertView alloc] initWithTitle:nil message:[array componentsJoinedByString:@"\n\n"] delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
////            [weakSelf.view showImageHUDText:[array componentsJoinedByString:@"\n"]];
//        } failed:^{
//
//        }];
//    }
    
    // 获取图片
//    [self.toolManager getSelectedImageList:allList requestType:HXDatePhotoToolManagerRequestTypeOriginal success:^(NSArray<UIImage *> *imageList) {
//
//    } failed:^{
//
//    }];
    
//    [HXPhotoTools selectListWriteToTempPath:allList requestList:^(NSArray *imageRequestIds, NSArray *videoSessions) {
//        NSSLog(@"requestIds - image : %@ \nsessions - video : %@",imageRequestIds,videoSessions);
//    } completion:^(NSArray<NSURL *> *allUrl, NSArray<NSURL *> *imageUrls, NSArray<NSURL *> *videoUrls) {
//        NSSLog(@"allUrl - %@\nimageUrls - %@\nvideoUrls - %@",allUrl,imageUrls,videoUrls);
//    } error:^{
//        NSSLog(@"失败");
//    }];
}

- (void)photoView:(HXPhotoView *)photoView imageChangeComplete:(NSArray<UIImage *> *)imageList {
    NSSLog(@"%@",imageList);
}

- (void)photoView:(HXPhotoView *)photoView deleteNetworkPhoto:(NSString *)networkPhotoUrl {
    NSSLog(@"%@",networkPhotoUrl);
}

- (void)photoView:(HXPhotoView *)photoView updateFrame:(CGRect)frame {
    NSSLog(@"%@",NSStringFromCGRect(frame));
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, CGRectGetMaxY(frame) + kPhotoViewMargin);
    
}

- (void)photoView:(HXPhotoView *)photoView currentDeleteModel:(HXPhotoModel *)model currentIndex:(NSInteger)index {
    NSSLog(@"%@ --> index - %ld",model,index);
}

- (BOOL)photoViewShouldDeleteCurrentMoveItem:(HXPhotoView *)photoView gestureRecognizer:(UILongPressGestureRecognizer *)longPgr indexPath:(NSIndexPath *)indexPath {
    return self.needDeleteItem;
}
- (void)photoView:(HXPhotoView *)photoView gestureRecognizerBegan:(UILongPressGestureRecognizer *)longPgr indexPath:(NSIndexPath *)indexPath {
    [UIView animateWithDuration:0.25 animations:^{
        self.bottomView.alpha = 0.5;
    }];
    NSSLog(@"长按手势开始了 - %ld",indexPath.item);
}
- (void)photoView:(HXPhotoView *)photoView gestureRecognizerChange:(UILongPressGestureRecognizer *)longPgr indexPath:(NSIndexPath *)indexPath {
    CGPoint point = [longPgr locationInView:self.view];
    if (point.y >= self.bottomView.hx_y) {
        [UIView animateWithDuration:0.25 animations:^{
            self.bottomView.alpha = 1;
        }];
    }else {
        [UIView animateWithDuration:0.25 animations:^{
            self.bottomView.alpha = 0.5;
        }];
    }
    NSSLog(@"长按手势改变了 %@ - %ld",NSStringFromCGPoint(point), indexPath.item);
}
- (void)photoView:(HXPhotoView *)photoView gestureRecognizerEnded:(UILongPressGestureRecognizer *)longPgr indexPath:(NSIndexPath *)indexPath {
    CGPoint point = [longPgr locationInView:self.view];
    if (point.y >= self.bottomView.hx_y) {
        self.needDeleteItem = YES;
        [self.photoView deleteModelWithIndex:indexPath.item]; 
    }else {
        self.needDeleteItem = NO;
    }
    NSSLog(@"长按手势结束了 - %ld",indexPath.item);
    [UIView animateWithDuration:0.25 animations:^{
        self.bottomView.alpha = 0;
    }];
}


@end
