//
//  HXCustomCameraViewController.m
//  照片选择器
//
//  Created by 洪欣 on 2017/9/30.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXCustomCameraViewController.h"
#import "HXCustomCameraController.h"
#import "HXCustomPreviewView.h"
#import "HXPhotoTools.h"
#import "HXFullScreenCameraPlayView.h"
#import "HXPhotoManager.h"
#import <MediaPlayer/MediaPlayer.h>
#import "UIImage+HXExtension.h"
#import <CoreLocation/CoreLocation.h>

@interface HXCustomCameraViewController ()<HXCustomPreviewViewDelegate,HXCustomCameraBottomViewDelegate,HXCustomCameraControllerDelegate, CLLocationManagerDelegate>
@property (strong, nonatomic) HXCustomCameraController *cameraController;
@property (strong, nonatomic) HXCustomPreviewView *previewView;
@property (strong, nonatomic) CAGradientLayer *topMaskLayer;
@property (strong, nonatomic) UIView *topView;
@property (strong, nonatomic) UIButton *cancelBtn;
@property (strong, nonatomic) UIButton *changeCameraBtn;
@property (strong, nonatomic) UIButton *flashBtn;
@property (strong, nonatomic) HXCustomCameraBottomView *bottomView;
@property (strong, nonatomic) NSTimer *timer;
@property (assign, nonatomic) NSUInteger time;
@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) HXCustomCameraPlayVideoView *playVideoView;
@property (strong, nonatomic) UIButton *doneBtn;
@property (assign, nonatomic) BOOL addAudioInputComplete;
@property (strong, nonatomic) NSURL *videoURL;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *location;
@property (strong, nonatomic) UIVisualEffectView *effectView;
@end

@implementation HXCustomCameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.manager.configuration.saveSystemAblum && !self.manager.albums.count) { 
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.manager getAllPhotoAlbums:nil albums:nil isFirst:NO];
        });
    }
    self.view.backgroundColor = [UIColor grayColor];
    
    if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusDenied) {
        [self.locationManager startUpdatingLocation];
    }
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.cancelBtn];
    if (self.manager.configuration.videoMaximumDuration > self.manager.configuration.videoMaxDuration) {
        self.manager.configuration.videoMaximumDuration = self.manager.configuration.videoMaxDuration;
    }else if (self.manager.configuration.videoMaximumDuration < 3.f) {
        self.manager.configuration.videoMaximumDuration = 4.f;
    }
    
    [self.view addSubview:self.previewView];
    self.cameraController = [[HXCustomCameraController alloc] init];
    self.cameraController.delegate = self;
    if ([self.cameraController setupSession:nil]) {
        [self.previewView setSession:self.cameraController.captureSession];
        self.previewView.delegate = self;
        if (self.manager.type == HXPhotoManagerSelectedTypePhoto) {
            [self.cameraController initImageOutput];
        }else if (self.manager.type == HXPhotoManagerSelectedTypeVideo) {
            [self.view insertSubview:self.playVideoView belowSubview:self.bottomView];
            [self.cameraController addAudioInput];
            self.addAudioInputComplete = YES;
            [self.cameraController initMovieOutput];
        }else {
            if (!self.manager.configuration.selectTogether && self.isOutside) {
                if (self.manager.afterSelectedPhotoArray.count > 0) {
                    [self.cameraController initImageOutput];
                }else if (self.manager.afterSelectedVideoArray.count > 0) {
                    [self.view insertSubview:self.playVideoView belowSubview:self.bottomView];
                    [self.cameraController addAudioInput];
                    self.addAudioInputComplete = YES;
                    [self.cameraController initMovieOutput];
                }else {
                    [self.view insertSubview:self.playVideoView belowSubview:self.bottomView];
                    [self.cameraController initImageOutput];
                    [self.previewView addSwipeGesture];
                }
            }else {
                [self.view insertSubview:self.playVideoView belowSubview:self.bottomView];
                [self.cameraController initImageOutput];
                [self.previewView addSwipeGesture];
            }
        }
        if (self.manager.tempCameraView) { 
            self.manager.tempCameraView.frame = self.view.bounds;
            [self.previewView addSubview:self.manager.tempCameraView];
            [self.previewView addSubview:self.effectView];
        }
        HXWeakSelf
        self.bottomView.userInteractionEnabled = NO;
        [self.cameraController startSessionComplete:^{
            weakSelf.bottomView.userInteractionEnabled = YES;
            if (weakSelf.manager.tempCameraView) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [UIView animateWithDuration:0.3 animations:^{
                        weakSelf.manager.tempCameraView.alpha = 0;
                        weakSelf.effectView.effect = nil;
                    } completion:^(BOOL finished) {
                        [weakSelf.effectView removeFromSuperview];
                        [weakSelf.manager.tempCameraView removeFromSuperview];
                    }];
                });
            }
        }];
    }
    self.previewView.tapToFocusEnabled = self.cameraController.cameraSupportsTapToFocus;
    self.previewView.tapToExposeEnabled = self.cameraController.cameraSupportsTapToExpose;
    [self.view addSubview:self.bottomView];
    [self.view addSubview:self.topView];
    
    UIBarButtonItem *rightBtn1 = [[UIBarButtonItem alloc] initWithCustomView:self.changeCameraBtn];
    UIBarButtonItem *rightBtn2 = [[UIBarButtonItem alloc] initWithCustomView:self.flashBtn];
    if ([self.cameraController canSwitchCameras] && [self.cameraController cameraHasFlash]) {
        self.navigationItem.rightBarButtonItems = @[rightBtn1,rightBtn2];
    }else {
        if ([self.cameraController cameraHasTorch] || [self.cameraController cameraHasFlash]) {
            self.navigationItem.rightBarButtonItems = @[rightBtn2];
        }
    }
    [self changeSubviewFrame];
    self.previewView.maxScale = [self.cameraController maxZoomFactor];
    if ([self.cameraController cameraSupportsZoom]) {
        self.previewView.effectiveScale = 1.0f;
        self.previewView.beginGestureScale = 1.0f;
        [self.cameraController rampZoomToValue:1.0f];
        [self.cameraController cancelZoom];
    }
    [self setupFlashAndTorchBtn];
    self.previewView.tapToExposeEnabled = self.cameraController.cameraSupportsTapToExpose;
    self.previewView.tapToFocusEnabled = self.cameraController.cameraSupportsTapToFocus;
    
    if (self.manager.configuration.navigationBar) {
        self.manager.configuration.navigationBar(self.navigationController.navigationBar, self);
    }
}
- (void)requestAccessForAudio {
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (granted) {
                if (!self.addAudioInputComplete) {
                    [self.cameraController addAudioInput];
                    self.addAudioInputComplete = YES;
                }
            }else {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSBundle hx_localizedStringForKey:@"无法使用麦克风"] message:[NSBundle hx_localizedStringForKey:@"请在设置-隐私-相机中允许访问麦克风"] preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:[NSBundle hx_localizedStringForKey:@"取消"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [self.view showImageHUDText:[NSBundle hx_localizedStringForKey:@"麦克风添加失败,录制视频会没有声音哦!"]];
                }]];
                [alert addAction:[UIAlertAction actionWithTitle:[NSBundle hx_localizedStringForKey:@"设置"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                }]];
                [self presentViewController:alert animated:YES completion:nil];
            }
        });
    }];
}
- (void)setupFlashAndTorchBtn {
    self.previewView.pinchToZoomEnabled = [self.cameraController cameraSupportsZoom];
    BOOL hidden = NO;
    if (self.bottomView.mode == HXCustomCameraBottomViewModePhoto) {
        hidden = !self.cameraController.cameraHasFlash;
    }else {
        hidden = !self.cameraController.cameraHasTorch;
    }
    self.flashBtn.hidden = hidden;
    
    if (self.bottomView.mode == HXCustomCameraBottomViewModePhoto) {
        if (self.cameraController.flashMode == AVCaptureFlashModeOff) {
            self.flashBtn.selected = NO;
        }else {
            self.flashBtn.selected = YES;
        }
    }else {
        if (self.cameraController.torchMode == AVCaptureTorchModeOff) {
            self.flashBtn.selected = NO;
        }else {
            self.flashBtn.selected = YES;
        }
    }
}
- (void)changeSubviewFrame {
    self.topView.frame = CGRectMake(0, 0, self.view.hx_w, hxNavigationBarHeight);
    self.topMaskLayer.frame = self.topView.bounds;
    self.bottomView.frame = CGRectMake(0, self.view.hx_h - 120, self.view.hx_w, 120);
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setBackgroundColor:[UIColor clearColor]];
    [self.navigationController.navigationBar setShadowImage:[[UIImage alloc] init]];
    [self.navigationController.navigationBar setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    AVCaptureConnection *previewLayerConnection = [(AVCaptureVideoPreviewLayer *)self.previewView.layer connection]; 
    if ([previewLayerConnection isVideoOrientationSupported])
        [previewLayerConnection setVideoOrientation:(AVCaptureVideoOrientation)[[UIApplication sharedApplication] statusBarOrientation]];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    [self.cameraController stopMontionUpdate];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.cameraController startMontionUpdate];
}
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self stopTimer];
    self.manager.tempCameraView = [self.previewView snapshotViewAfterScreenUpdates:YES];
    [self.cameraController stopSession];
} 
- (void)dealloc {
    if (_locationManager) {
        [self.locationManager stopUpdatingLocation];
    }
    if (HXShowLog) NSSLog(@"dealloc");
}
- (void)cancelClick:(UIButton *)button {
    if (button.selected) {
        [self.cameraController startSession];
        [self.imageView removeFromSuperview];
        [self.doneBtn removeFromSuperview];
        [self.playVideoView stopPlay];
        self.playVideoView.hidden = YES;
        self.playVideoView.playerLayer.hidden = YES;
        self.flashBtn.hidden = NO;
        self.changeCameraBtn.hidden = NO;
        self.cancelBtn.selected = NO;
        self.bottomView.hidden = NO;
        self.previewView.tapToFocusEnabled = YES;
        self.previewView.pinchToZoomEnabled = [self.cameraController cameraSupportsZoom];
    }else {
        [self stopTimer];
        [self.cameraController stopMontionUpdate];
        [self.cameraController stopSession];
        if ([self.delegate respondsToSelector:@selector(customCameraViewControllerDidCancel:)]) {
            [self.delegate customCameraViewControllerDidCancel:self];
        }
        if (self.cancelBlock) {
            self.cancelBlock(self);
        }
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}
- (void)didDoneBtnClick {
    HXPhotoModel *model = [[HXPhotoModel alloc] init];
    model.location = self.location;
    if (!self.videoURL) {
        model.type = HXPhotoModelMediaTypeCameraPhoto;
        model.subType = HXPhotoModelMediaSubTypePhoto;
        if (self.imageView.image.imageOrientation != UIImageOrientationUp) {
            self.imageView.image = [self.imageView.image normalizedImage];
        }
        model.thumbPhoto = self.imageView.image;
        model.imageSize = self.imageView.image.size;
        model.previewPhoto = self.imageView.image;
//        model.cameraIdentifier = [self videoOutFutFileName];
    }else {
        if (self.time < 3) {
            [self.view showImageHUDText:[NSBundle hx_localizedStringForKey:@"录制时间少于3秒"]];
            return;
        }
        [self.playVideoView stopPlay];
        model.type = HXPhotoModelMediaTypeCameraVideo;
        model.subType = HXPhotoModelMediaSubTypeVideo;
        MPMoviePlayerController *player = [[MPMoviePlayerController alloc]initWithContentURL:self.videoURL] ;
        player.shouldAutoplay = NO;
        UIImage  *image = [player thumbnailImageAtTime:0.1 timeOption:MPMovieTimeOptionNearestKeyFrame];
        NSString *videoTime = [HXPhotoTools getNewTimeFromDurationSecond:self.time];
        model.videoDuration = self.time;
        model.videoURL = self.videoURL;
        model.videoTime = videoTime;
        model.thumbPhoto = image;
        model.imageSize = image.size;
        model.previewPhoto = image;
//        model.cameraIdentifier = [self videoOutFutFileName];
    }
    [self stopTimer];
    [self.cameraController stopMontionUpdate];
    [self.cameraController stopSession]; 
    if (self.manager.configuration.saveSystemAblum) {
        if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
            [HXPhotoTools savePhotoToCustomAlbumWithName:self.manager.configuration.customAlbumName photo:model.thumbPhoto];
        }else {
            [HXPhotoTools saveVideoToCustomAlbumWithName:self.manager.configuration.customAlbumName videoURL:model.videoURL];
        }
    }
    if ([self.delegate respondsToSelector:@selector(customCameraViewController:didDone:)]) {
        [self.delegate customCameraViewController:self didDone:model];
    }
    if (self.doneBlock) {
        self.doneBlock(model, self);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)didchangeCameraClick {
    if ([self.cameraController switchCameras]) {
        self.previewView.maxScale = [self.cameraController maxZoomFactor];
        if ([self.cameraController cameraSupportsZoom]) {
            self.previewView.effectiveScale = 1.0f;
            self.previewView.beginGestureScale = 1.0f;
            [self.cameraController rampZoomToValue:1.0f];
            [self.cameraController cancelZoom];
        }
        [self setupFlashAndTorchBtn];
        self.previewView.tapToExposeEnabled = self.cameraController.cameraSupportsTapToExpose;
        self.previewView.tapToFocusEnabled = self.cameraController.cameraSupportsTapToFocus;
        [self.cameraController resetFocusAndExposureModes];
    }
}
- (void)didFlashClick:(UIButton *)button {
    if (self.bottomView.mode == HXCustomCameraBottomViewModePhoto) {
        if (button.selected) {
            self.cameraController.flashMode = 0;
        }else {
            self.cameraController.flashMode = 1;
        }
    }else {
        if (button.selected) {
            self.cameraController.torchMode = 0;
        }else {
            self.cameraController.torchMode = 1;
        }
    }
    button.selected = !button.selected;
}
- (void)takePicturesComplete:(UIImage *)image {
    self.imageView.image = image;
    [self.view insertSubview:self.imageView belowSubview:self.bottomView];
    [self.view addSubview:self.doneBtn];
    [self.cameraController stopSession];
    self.cancelBtn.hidden = NO;
}
- (void)takePicturesFailed {
    self.cancelBtn.hidden = NO;
    self.flashBtn.hidden = NO;
    self.changeCameraBtn.hidden = NO;
    self.cancelBtn.selected = NO;
    self.bottomView.hidden = NO;
    self.previewView.tapToFocusEnabled = YES;
    self.previewView.pinchToZoomEnabled = [self.cameraController cameraSupportsZoom];
    [self.view showImageHUDText:[NSBundle hx_localizedStringForKey:@"拍摄失败"]];
}
- (void)startTimer {
    self.time = 0;
    [self.timer invalidate];
    self.timer = [NSTimer timerWithTimeInterval:1.0f
                                         target:self
                                       selector:@selector(updateTimeDisplay)
                                       userInfo:nil
                                        repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)updateTimeDisplay {
    CMTime duration = self.cameraController.recordedDuration;
    NSUInteger time = (NSUInteger)CMTimeGetSeconds(duration);
    self.time = time;
    [self.bottomView changeTime:time];
    if (time == self.manager.configuration.videoMaximumDuration) {
        [self.cameraController stopRecording];
        [self stopTimer];
    }
}

- (void)stopTimer {
    [self.timer invalidate];
    self.timer = nil;
}
- (void)videoStartRecording {
    [self.bottomView startRecord];
}
- (void)videoNeedHideViews {
    self.cancelBtn.hidden = YES;
    self.cancelBtn.selected = YES;
    self.flashBtn.hidden = YES;
    self.changeCameraBtn.hidden = YES;
}
- (void)videoFinishRecording:(NSURL *)videoURL {
    [self.bottomView stopRecord];
    if (self.time < 3) {
        self.bottomView.hidden = NO;
        self.cancelBtn.selected = NO;
        self.flashBtn.hidden = NO;
        self.changeCameraBtn.hidden = NO;
        [self.view showImageHUDText:[NSBundle hx_localizedStringForKey:@"3秒内的视频无效哦~"]];
    }else {
        [self.cameraController stopSession];
        self.previewView.tapToFocusEnabled = NO;
        self.previewView.pinchToZoomEnabled = NO;
        self.bottomView.hidden = YES;
        self.videoURL = [videoURL copy];
        self.playVideoView.hidden = NO;
        self.playVideoView.playerLayer.hidden = NO;
        self.playVideoView.videoURL = self.videoURL;
        [self.view addSubview:self.doneBtn];
    }
    self.cancelBtn.hidden = NO;
//    NSSLog(@"%@",videoURL);
}
- (void)mediaCaptureFailedWithError:(NSError *)error {
    self.time = 0;
    [self stopTimer];
    [self.bottomView stopRecord];
    [self.view showImageHUDText:[NSBundle hx_localizedStringForKey:@"录制视频失败!"]];
    self.bottomView.hidden = NO;
    self.cancelBtn.selected = NO;
    self.flashBtn.hidden = NO;
    self.changeCameraBtn.hidden = NO;
    self.cancelBtn.hidden = NO;
}
- (void)playViewClick {
    if (self.bottomView.mode == HXCustomCameraBottomViewModePhoto) {
        [self.cameraController captureStillImage];
        self.previewView.tapToFocusEnabled = NO;
        self.previewView.pinchToZoomEnabled = NO;
        [self needHideViews];
    }else {
        if ([self.cameraController isRecording]) {
            [self.cameraController stopRecording];
            [self stopTimer];
            return;
        }else {
            if ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio] != AVAuthorizationStatusAuthorized) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSBundle hx_localizedStringForKey:@"无法使用麦克风"] message:[NSBundle hx_localizedStringForKey:@"请在设置-隐私-相机中允许访问麦克风"] preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:[NSBundle hx_localizedStringForKey:@"继续录制"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [self.view showImageHUDText:[NSBundle hx_localizedStringForKey:@"麦克风添加失败,录制视频会没有声音哦!"]];
                    [self.bottomView beganAnimate];
                    [self videoNeedHideViews];
                }]];
                [alert addAction:[UIAlertAction actionWithTitle:[NSBundle hx_localizedStringForKey:@"设置"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                }]];
                [self presentViewController:alert animated:YES completion:nil];
            }else {
                [self.bottomView beganAnimate];
                [self videoNeedHideViews];
            }
        }
    }
}
- (void)needHideViews {
    self.cancelBtn.selected = YES;
    self.flashBtn.hidden = YES;
    self.changeCameraBtn.hidden = YES;
    self.bottomView.hidden = YES;
    self.cancelBtn.hidden = YES;
}
- (void)playViewChangeMode:(HXCustomCameraBottomViewMode)mode {
    if (mode == HXCustomCameraBottomViewModePhoto) {
        [self.cameraController addImageOutput];
    }else {
        [self requestAccessForAudio];
        [self.cameraController addMovieOutput];
    }
    [self setupFlashAndTorchBtn];
}
- (void)playViewAnimateCompletion {
    if (!self.bottomView.animating) {
        dispatch_async(dispatch_queue_create("com.hxdatephotopicker.kamera", NULL), ^{
            [self.cameraController startRecording];
            [self startTimer];
        });
    }
}
- (void)didLeftSwipeClick {
    [self.bottomView leftAnimate];
}
- (void)didRightSwipeClick {
    [self.bottomView rightAnimate];
}
- (void)tappedToFocusAtPoint:(CGPoint)point {
    [self.cameraController focusAtPoint:point];
    [self.cameraController exposeAtPoint:point];
}
- (void)pinchGestureScale:(CGFloat)scale {
    [self.cameraController setZoomValue:scale];
}
- (HXCustomPreviewView *)previewView {
    if (!_previewView) {
        _previewView = [[HXCustomPreviewView alloc] initWithFrame:self.view.bounds];
        _previewView.delegate = self;
    }
    return _previewView;
}
- (UIView *)topView {
    if (!_topView) {
        _topView = [[UIView alloc] init];
        [_topView.layer addSublayer:self.topMaskLayer];
    }
    return _topView;
}
- (CAGradientLayer *)topMaskLayer {
    if (!_topMaskLayer) {
        _topMaskLayer = [CAGradientLayer layer];
        _topMaskLayer.colors = @[
                                    (id)[[UIColor blackColor] colorWithAlphaComponent:0].CGColor,
                                    (id)[[UIColor blackColor] colorWithAlphaComponent:0.3].CGColor
                                    ];
        _topMaskLayer.startPoint = CGPointMake(0, 1);
        _topMaskLayer.endPoint = CGPointMake(0, 0);
        _topMaskLayer.locations = @[@(0.15f),@(0.9f)];
        _topMaskLayer.borderWidth  = 0.0;
    }
    return _topMaskLayer;
}
- (UIButton *)cancelBtn {
    if (!_cancelBtn) {
        _cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cancelBtn setTitle:[NSBundle hx_localizedStringForKey:@"重拍"] forState:UIControlStateSelected];
        [_cancelBtn setTitle:@"" forState:UIControlStateNormal];
        [_cancelBtn setImage:[HXPhotoTools hx_imageNamed:@"hx_faceu_cancel@3x.png"] forState:UIControlStateNormal];
        [_cancelBtn setImage:[[UIImage alloc] init] forState:UIControlStateSelected];
        [_cancelBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        [_cancelBtn addTarget:self action:@selector(cancelClick:) forControlEvents:UIControlEventTouchUpInside];
        _cancelBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        _cancelBtn.hx_size = CGSizeMake(50, 50);
    }
    return _cancelBtn;
}
- (UIButton *)changeCameraBtn {
    if (!_changeCameraBtn) {
        _changeCameraBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_changeCameraBtn setImage:[HXPhotoTools hx_imageNamed:@"hx_faceu_camera@3x.png"] forState:UIControlStateNormal];
        [_changeCameraBtn addTarget:self action:@selector(didchangeCameraClick) forControlEvents:UIControlEventTouchUpInside];
        _changeCameraBtn.hx_size = _changeCameraBtn.currentImage.size;
    }
    return _changeCameraBtn;
}
- (UIButton *)flashBtn {
    if (!_flashBtn) {
        _flashBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_flashBtn setImage:[HXPhotoTools hx_imageNamed:@"hx_camera_flashlight@2x.png"] forState:UIControlStateNormal];
        [_flashBtn setImage:[HXPhotoTools hx_imageNamed:@"hx_flash_pic_nopreview@2x.png"] forState:UIControlStateSelected];
        _flashBtn.hx_size = _flashBtn.currentImage.size;
        [_flashBtn addTarget:self action:@selector(didFlashClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _flashBtn;
}
- (HXCustomCameraBottomView *)bottomView {
    if (!_bottomView) {
        _bottomView = [[HXCustomCameraBottomView alloc] initWithFrame:CGRectZero manager:self.manager isOutside:self.isOutside];
        _bottomView.delegate = self;
    }
    return _bottomView;
}
- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        _imageView.backgroundColor = [UIColor blackColor];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _imageView;
}
- (HXCustomCameraPlayVideoView *)playVideoView {
    if (!_playVideoView) {
        _playVideoView = [[HXCustomCameraPlayVideoView alloc] initWithFrame:self.view.bounds];
        _playVideoView.hidden = YES;
        _playVideoView.playerLayer.hidden = YES;
    }
    return _playVideoView;
}
- (UIButton *)doneBtn {
    if (!_doneBtn) {
        _doneBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_doneBtn setTitle:[NSBundle hx_localizedStringForKey:@"完成"] forState:UIControlStateNormal];
        [_doneBtn setTitleShadowColor:[[UIColor blackColor] colorWithAlphaComponent:0.4] forState:UIControlStateNormal];
        [_doneBtn.titleLabel setShadowOffset:CGSizeMake(1, 2)];
        _doneBtn.frame = CGRectMake(self.view.hx_w - 20 - 70, self.view.hx_h - 120 + 70, 70, 35);
        [_doneBtn addTarget:self action:@selector(didDoneBtnClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _doneBtn;
}
- (UIVisualEffectView *)effectView {
    if (!_effectView) {
        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        _effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
        _effectView.frame = self.view.bounds;
    }
    return _effectView;
}
- (CLLocationManager *)locationManager {
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        _locationManager.distanceFilter = kCLDistanceFilterNone;
        [_locationManager requestWhenInUseAuthorization];
    }
    return _locationManager;
}
#pragma mark - < CLLocationManagerDelegate >
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    if (locations.lastObject) {
        self.location = locations.lastObject;
    }
}
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    if(error.code == kCLErrorLocationUnknown) {
        if (HXShowLog) NSSLog(@"定位失败，无法检索位置");
    }
    else if(error.code == kCLErrorNetwork) {
        if (HXShowLog) NSSLog(@"定位失败，网络问题");
    }
    else if(error.code == kCLErrorDenied) {
        if (HXShowLog) NSSLog(@"定位失败，定位权限的问题");
        [self.locationManager stopUpdatingLocation];
        self.locationManager = nil;
    }
}
@end

@interface HXCustomCameraBottomView ()
@property (strong, nonatomic) CAGradientLayer *maskLayer;
@property (strong, nonatomic) HXFullScreenCameraPlayView *playView;
@property (strong, nonatomic) HXPhotoManager *manager;
@property (strong, nonatomic) UILabel *titleLb;
@property (strong, nonatomic) UILabel *timeLb;
@property (strong, nonatomic) UITapGestureRecognizer *tap;
@property (strong, nonatomic) UIButton *photoBtn;
@property (strong, nonatomic) UIButton *videoBtn;
@property (assign, nonatomic) BOOL isOutside;
@end

@implementation HXCustomCameraBottomView
- (instancetype)initWithFrame:(CGRect)frame manager:(HXPhotoManager *)manager isOutside:(BOOL)isOutside{
    self = [super initWithFrame:frame];
    if (self) {
        self.isOutside = isOutside;
        self.manager = manager;
        [self setupUI];
    }
    return self;
}
- (void)setupUI {
    [self.layer addSublayer:self.maskLayer];
    [self addSubview:self.playView];
    [self addSubview:self.titleLb];
    [self addSubview:self.timeLb];
    [self addSubview:self.photoBtn];
    [self addSubview:self.videoBtn];
    self.photoBtn.center = CGPointMake([UIScreen mainScreen].bounds.size.width / 2, 0);
    self.videoBtn.hx_x = CGRectGetMaxX(self.photoBtn.frame) + 10;
    self.titleLb.alpha = 0;
    if (self.manager.type == HXPhotoManagerSelectedTypePhotoAndVideo) {
        if (!self.manager.configuration.selectTogether && self.isOutside) {
            if (self.manager.afterSelectedPhotoArray.count > 0) {
                self.mode = HXCustomCameraBottomViewModePhoto;
                self.titleLb.text = [NSBundle hx_localizedStringForKey:@"点击拍照"];
                self.titleLb.alpha = 1;
                self.photoBtn.hidden = YES;
                self.videoBtn.hidden = YES;
            }else if (self.manager.afterSelectedVideoArray.count > 0) {
                self.mode = HXCustomCameraBottomViewModeVideo;
                self.titleLb.text = [NSBundle hx_localizedStringForKey:@"点击录制"];
                self.titleLb.alpha = 1;
                self.photoBtn.hidden = YES;
                self.videoBtn.hidden = YES;
            }else {
                self.mode = HXCustomCameraBottomViewModePhoto;
                self.titleLb.text = [NSBundle hx_localizedStringForKey:@"点击拍照"];
                self.photoBtn.hidden = NO;
                self.videoBtn.hidden = NO;
                self.photoBtn.enabled = NO;
                self.videoBtn.enabled = YES;
            }
        }else {
            self.mode = HXCustomCameraBottomViewModePhoto;
            self.titleLb.text = [NSBundle hx_localizedStringForKey:@"点击拍照"];
            self.photoBtn.hidden = NO;
            self.videoBtn.hidden = NO;
            self.photoBtn.enabled = NO;
            self.videoBtn.enabled = YES;
        }
    }else if (self.manager.type == HXPhotoManagerSelectedTypePhoto) {
        self.mode = HXCustomCameraBottomViewModePhoto;
        self.titleLb.text = [NSBundle hx_localizedStringForKey:@"点击拍照"];
        self.titleLb.alpha = 1;
        self.photoBtn.hidden = YES;
        self.videoBtn.hidden = YES;
    }else {
        self.mode = HXCustomCameraBottomViewModeVideo;
        self.titleLb.text = [NSBundle hx_localizedStringForKey:@"点击录制"];
        self.titleLb.alpha = 1;
        self.photoBtn.hidden = YES;
        self.videoBtn.hidden = YES;
    }
}
- (void)takePictures {
    if ([self.delegate respondsToSelector:@selector(playViewClick)]) {
        [self.delegate playViewClick];
    }
}
- (void)changeTime:(NSInteger)time {
    if (time < 3) {
        self.timeLb.text = [NSBundle hx_localizedStringForKey:@"3秒内的视频无效哦~"];
    }else {
        self.timeLb.text = [NSString stringWithFormat:@"%lds",time];
    }
    self.playView.progress = (CGFloat)time / self.manager.configuration.videoMaximumDuration;
}
- (void)beganAnimate {
    self.userInteractionEnabled = NO;
    self.titleLb.alpha = 0;
    self.photoBtn.hidden = YES;
    self.videoBtn.hidden = YES;
    self.animating = YES;
    self.tap.enabled = NO;
    [UIView animateWithDuration:0.2 animations:^{
        self.playView.transform = CGAffineTransformMakeScale(1.2, 1.2);
    } completion:^(BOOL finished) {
        self.animating = NO;
        if ([self.delegate respondsToSelector:@selector(playViewAnimateCompletion)]) {
            [self.delegate playViewAnimateCompletion];
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.tap.enabled = YES;
            self.userInteractionEnabled = YES;
        });
    }];
}
- (void)startRecord {
    self.timeLb.hidden = NO;
    self.timeLb.text = [NSBundle hx_localizedStringForKey:@"3秒内的视频无效哦~"];
}
- (void)stopRecord {
    if (self.manager.type == HXPhotoManagerSelectedTypePhotoAndVideo && self.isOutside) {
        if (!self.manager.configuration.selectTogether) {
            if (self.manager.afterSelectedPhotoArray.count > 0) {
                self.titleLb.alpha = 1;
            }else if (self.manager.afterSelectedVideoArray.count > 0) {
                self.titleLb.alpha = 1;
            }else {
                self.photoBtn.hidden = NO;
                self.videoBtn.hidden = NO;
            }
        }else {
            self.photoBtn.hidden = NO;
            self.videoBtn.hidden = NO;
        }
    }else {
        if (self.manager.type == HXPhotoManagerSelectedTypePhotoAndVideo) {
            self.photoBtn.hidden = NO;
            self.videoBtn.hidden = NO;
        }else {
            self.titleLb.alpha = 1;
        }
    }
    self.timeLb.hidden = YES;
    [self.playView clean];
    self.playView.transform = CGAffineTransformIdentity;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.maskLayer.frame = CGRectMake(0, -40, self.hx_w, self.hx_h + 40);
    self.playView.center = CGPointMake(self.hx_w / 2, self.hx_h / 2 + 10);
    self.timeLb.frame = CGRectMake(12, self.playView.hx_y - 26, self.hx_w - 24, 15);
    self.titleLb.frame = CGRectMake(12, self.playView.hx_y - 20 - 30, self.hx_w - 24, 15);
    if (self.manager.type == HXPhotoManagerSelectedTypeVideo || self.manager.type == HXPhotoManagerSelectedTypePhoto) {
        self.titleLb.hx_y = self.playView.hx_y - 30;
    }else if (self.manager.type == HXPhotoManagerSelectedTypePhotoAndVideo) {
        if (!self.manager.configuration.selectTogether && self.isOutside) {
            if (self.manager.afterSelectedPhotoArray.count > 0) {
                self.titleLb.hx_y = self.playView.hx_y - 30;
            }else if (self.manager.afterSelectedVideoArray.count > 0) {
                self.titleLb.hx_y = self.playView.hx_y - 30;
            }
        }
    }
    self.photoBtn.hx_y = self.playView.hx_y - 30;
    self.videoBtn.hx_y = self.photoBtn.hx_y;
}
- (void)leftAnimate {
    if (self.videoBtn.center.x == self.hx_w / 2) {
        return;
    }
    self.mode = HXCustomCameraBottomViewModeVideo;
    self.titleLb.text = [NSBundle hx_localizedStringForKey:@"点击录制"];
    self.titleLb.alpha = 0;
    self.videoBtn.enabled = NO;
    self.photoBtn.enabled = YES;
    if ([self.delegate respondsToSelector:@selector(playViewChangeMode:)]) {
        [self.delegate playViewChangeMode:self.mode];
    }
    [UIView animateWithDuration:0.2 animations:^{
        self.videoBtn.center = CGPointMake(self.hx_w / 2, 0);
        self.videoBtn.hx_y = self.playView.hx_y - 30;
        self.photoBtn.hx_x -= 15 + 40;
        self.titleLb.alpha = 1;
    } completion:^(BOOL finished) {
        [self hideTitleLb];
    }];
}
- (void)rightAnimate {
    if (self.photoBtn.center.x == self.hx_w / 2) {
        return;
    }
    self.mode = HXCustomCameraBottomViewModePhoto;
    self.titleLb.text = [NSBundle hx_localizedStringForKey:@"点击拍照"];
    self.titleLb.alpha = 0;
    self.photoBtn.enabled = NO;
    self.videoBtn.enabled = YES;
    if ([self.delegate respondsToSelector:@selector(playViewChangeMode:)]) {
        [self.delegate playViewChangeMode:self.mode];
    }
    [UIView animateWithDuration:0.2 animations:^{
        self.photoBtn.center = CGPointMake(self.hx_w / 2, 0);
        self.photoBtn.hx_y = self.playView.hx_y - 30;
        self.videoBtn.hx_x += 15 + 40;
        self.titleLb.alpha = 1;
    } completion:^(BOOL finished) {
        [self hideTitleLb];
    }];
}
- (void)hideTitleLb {
    [UIView animateWithDuration:1.0f animations:^{
        self.titleLb.alpha = 0;
    }];
}
- (UILabel *)titleLb {
    if (!_titleLb) {
        _titleLb = [[UILabel alloc] init];
        _titleLb.textAlignment = NSTextAlignmentCenter;
        _titleLb.textColor = [UIColor whiteColor];
        _titleLb.font = [UIFont hx_pingFangFontOfSize:14];
    }
    return _titleLb;
}
- (UILabel *)timeLb {
    if (!_timeLb) {
        _timeLb = [[UILabel alloc] init];
        _timeLb.textAlignment = NSTextAlignmentCenter;
        _timeLb.textColor = [UIColor whiteColor];
        _timeLb.font = [UIFont hx_pingFangFontOfSize:14];
        _timeLb.hidden = YES;
    }
    return _timeLb;
}
- (CAGradientLayer *)maskLayer {
    if (!_maskLayer) {
        _maskLayer = [CAGradientLayer layer];
        _maskLayer.colors = @[
                                    (id)[[UIColor blackColor] colorWithAlphaComponent:0].CGColor,
                                    (id)[[UIColor blackColor] colorWithAlphaComponent:0.4].CGColor
                                    ];
        _maskLayer.startPoint = CGPointMake(0, 0);
        _maskLayer.endPoint = CGPointMake(0, 1);
        _maskLayer.locations = @[@(0),@(1.f)];
        _maskLayer.borderWidth  = 0.0;
    }
    return _maskLayer;
}
- (HXFullScreenCameraPlayView *)playView {
    if (!_playView) {
        _playView = [[HXFullScreenCameraPlayView alloc] initWithFrame:CGRectMake(0, 0, 70, 70) color:self.manager.configuration.themeColor];
        self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(takePictures)];
        [_playView addGestureRecognizer:self.tap];
    }
    return _playView;
}
- (UIButton *)photoBtn {
    if (!_photoBtn) {
        _photoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_photoBtn setTitle:[NSBundle hx_localizedStringForKey:@"照片"] forState:UIControlStateNormal];
        [_photoBtn setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:0.5] forState:UIControlStateNormal];
        [_photoBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
        _photoBtn.titleLabel.font = [UIFont hx_pingFangFontOfSize:14];
        _photoBtn.hx_size = CGSizeMake(40, 20);
        [_photoBtn addTarget:self action:@selector(rightAnimate) forControlEvents:UIControlEventTouchUpInside];
    }
    return _photoBtn;
}
- (UIButton *)videoBtn {
    if (!_videoBtn) {
        _videoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_videoBtn setTitle:[NSBundle hx_localizedStringForKey:@"视频"] forState:UIControlStateNormal];
        [_videoBtn setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:0.5] forState:UIControlStateNormal];
        [_videoBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
        _videoBtn.titleLabel.font = [UIFont hx_pingFangFontOfSize:14];
        _videoBtn.hx_size = CGSizeMake(40, 20);
        [_videoBtn addTarget:self action:@selector(leftAnimate) forControlEvents:UIControlEventTouchUpInside];
    }
    return _videoBtn;
}
@end

@interface HXCustomCameraPlayVideoView ()
@end

@implementation HXCustomCameraPlayVideoView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}
- (void)setupUI {
    self.playerLayer = [[AVPlayerLayer alloc] init];
    self.playerLayer.frame = self.bounds;
    self.playerLayer.backgroundColor = [UIColor blackColor].CGColor;
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.layer addSublayer:self.playerLayer];
}
- (void)setVideoURL:(NSURL *)videoURL {
    _videoURL = videoURL;
    AVPlayer *player = [AVPlayer playerWithURL:videoURL];
    [player play];
    self.playerLayer.player = player;
}
- (void)stopPlay {
    [self.playerLayer.player pause];
}
@end
