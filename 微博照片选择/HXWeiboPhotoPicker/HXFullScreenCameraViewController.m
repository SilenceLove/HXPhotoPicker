//
//  HXFullScreenCameraViewController.m
//  微博照片选择
//
//  Created by 洪欣 on 2017/5/22.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXFullScreenCameraViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreMotion/CoreMotion.h>
#import <MediaPlayer/MediaPlayer.h>
#import "HXPhotoTools.h"
#import "UIView+HXExtension.h"
#import "UIImage+HXExtension.h"
#import "HXVideoPresentTransition.h"
#import "HXFullScreenCameraPlayView.h"
#import "HXPhotoManager.h"
#import "HXPhotoEditViewController.h"
#define WIDTH [UIScreen mainScreen].bounds.size.width
#define HEIGHT [UIScreen mainScreen].bounds.size.height

@interface HXFullScreenCameraViewController ()<UIGestureRecognizerDelegate,AVCaptureFileOutputRecordingDelegate,UIViewControllerTransitioningDelegate,HXPhotoEditViewControllerDelegate>
//捕获设备，通常是前置摄像头，后置摄像头，麦克风（音频输入）
@property (nonatomic, strong) AVCaptureDevice *device;
//AVCaptureDeviceInput 代表输入设备，他使用AVCaptureDevice 来初始化
@property (nonatomic, strong) AVCaptureDeviceInput *input;
//输出图片
@property (nonatomic ,strong) AVCaptureStillImageOutput *imageOutput;
//session：由他把输入输出结合在一起，并开始启动捕获设备（摄像头）
@property (nonatomic, strong) AVCaptureSession *session;
@property (strong, nonatomic) AVCaptureDevice *audioDevice;
@property (strong, nonatomic) AVCaptureDeviceInput *audioInput;
@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, assign) UIDeviceOrientation deviceOrientation;
@property (nonatomic, assign) UIDeviceOrientation imageOrientation;
//图像预览层，实时显示捕获的图像
@property (nonatomic ,strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (strong, nonatomic) AVCaptureMovieFileOutput *videoOutPut;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (assign, nonatomic) NSInteger flashlight;
@property (assign, nonatomic) BOOL first;
@property (strong, nonatomic) UIImageView *imageView;
/**
 *  记录开始的缩放比例
 */
@property(nonatomic,assign)CGFloat beginGestureScale;
/**
 * 最后的缩放比例
 */
@property(nonatomic,assign)CGFloat effectiveScale;
@property (weak, nonatomic) UIPinchGestureRecognizer *pinch;
@property (strong, nonatomic) HXFullScreenCameraPlayView *playView;
@property (weak, nonatomic) NSTimer *timer;
@property (assign, nonatomic) NSInteger videoTime;
@property (strong, nonatomic) UILabel *timeLb;
@property (copy, nonatomic) NSString *titleStr;
@property (weak, nonatomic) UIButton *backBtn;
@property (weak, nonatomic) UIButton *changeCameraBtn;
@property (strong, nonatomic) NSURL *videoURL;
@property (strong, nonatomic) UIButton *nextBtn;
@property (strong, nonatomic) UIImageView *focusIcon;
@property (strong, nonatomic) UITapGestureRecognizer *bgViewTap;
@property (strong, nonatomic) UIButton *flashBtn;
@end

@implementation HXFullScreenCameraViewController
- (instancetype)init {
    self = [super init];
    if (self) {
        self.transitioningDelegate = self;
        self.modalPresentationStyle = UIModalPresentationCustom;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.layer.backgroundColor = [UIColor grayColor].CGColor;
    [self setupUI];
    self.title = [NSBundle hx_localizedStringForKey:@"拍摄"];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.session) {
        [self.session startRunning];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.session) {
        [self.session stopRunning];
    }
}

- (void)setupUI {
    self.flashlight = 0;
    //    AVCaptureDevicePositionBack  后置摄像头
    //    AVCaptureDevicePositionFront 前置摄像头
    self.device = [self cameraWithPosition:AVCaptureDevicePositionBack];
    
//    if ([self.device hasFlash]) {
//        navItem.rightBarButtonItems = @[rightOne_,rightTwo_];
//    }else {
//        navItem.rightBarButtonItems = @[rightOne_];
    //    }
    self.beginGestureScale = 1.0f;
    self.effectiveScale = 1.0f;
    self.input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
    self.imageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary * outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey, nil];
    [self.imageOutput setOutputSettings:outputSettings];
    self.videoOutPut = [[AVCaptureMovieFileOutput alloc] init];
    self.session = [[AVCaptureSession alloc] init];
    self.session.sessionPreset = AVCaptureSessionPreset1280x720;
    //输入输出设备结合
    self.audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    self.audioInput = [AVCaptureDeviceInput deviceInputWithDevice:self.audioDevice error:nil];
    
    if ([self.session canAddInput:self.input]) {
        [self.session addInput:self.input];
    }
    if ([self.session canAddInput:self.audioInput]) {
        [self.session addInput:self.audioInput];
        // 根据设备输出获得连接
        AVCaptureConnection *captureConnection = [self.videoOutPut connectionWithMediaType:AVMediaTypeVideo];
        // 判断是否支持光学防抖
        if ([self.device.activeFormat isVideoStabilizationModeSupported:AVCaptureVideoStabilizationModeCinematic]) {
            // 如果支持防抖就打开防抖
            captureConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeCinematic;
        }
    }
    //预览层的生成
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    self.previewLayer.frame = self.view.bounds;
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:self.previewLayer];
    
    if ([_device lockForConfiguration:nil]) {
        //自动闪光灯，
        if ([_device isFlashModeSupported:AVCaptureFlashModeOff]) {
            [_device setFlashMode:AVCaptureFlashModeOff];
        }
        if ([_device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance]) {
            [_device setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];
        }
        [_device unlockForConfiguration];
    }
    
    self.imageView = [[UIImageView alloc] init];
    self.imageView.frame = self.view.bounds;
    self.imageView.hidden = YES;
    self.imageView.clipsToBounds = YES;
    self.imageView.backgroundColor = [UIColor blackColor];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.imageView];
    
    self.playerLayer = [[AVPlayerLayer alloc] init];
    self.playerLayer.frame = self.view.bounds;
    self.playerLayer.hidden = YES;
    self.playerLayer.backgroundColor = [UIColor blackColor].CGColor;
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.view.layer addSublayer:self.playerLayer];
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    pinch.delegate = self;
    [self.view addGestureRecognizer:pinch];
    self.pinch = pinch;
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.deviceMotionUpdateInterval = 1/15.0;
    if (self.motionManager.deviceMotionAvailable) {
        __weak typeof(self) weakSelf = self;
        [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMDeviceMotion * _Nullable motion, NSError * _Nullable error) {
            [weakSelf performSelectorOnMainThread:@selector(handleDeviceMotion:) withObject:motion waitUntilDone:YES];
        }];
    } else {
        NSSLog(@"No device motion on device");
    }
    
    if (self.type == HXCameraTypePhotoAndVideo) {
        self.titleStr = [NSBundle hx_localizedStringForKey:@"点击拍照，长按录像"];
        if ([self.session canAddOutput:self.imageOutput]) {
            [self.session addOutput:self.imageOutput];
        }
        if ([self.session canAddOutput:self.videoOutPut]) {
            [self.session addOutput:self.videoOutPut];
        }
    }else if (self.type == HXCameraTypePhoto) {
        self.titleStr = [NSBundle hx_localizedStringForKey:@"点击拍照"];
        if ([self.session canAddOutput:self.imageOutput]) {
            [self.session addOutput:self.imageOutput];
        }
    }else if (self.type == HXCameraTypeVideo) {
        self.titleStr = [NSBundle hx_localizedStringForKey:@"长按录像"];
        if ([self.session canAddOutput:self.videoOutPut]) {
            [self.session addOutput:self.videoOutPut];
        }
    }
    self.focusIcon = [[UIImageView alloc] initWithImage:[HXPhotoTools hx_imageNamed:self.photoManager.UIManager.cameraFocusImageName]];
    self.focusIcon.frame = CGRectMake(0, 0, self.focusIcon.image.size.width, self.focusIcon.image.size.height);
    self.focusIcon.hidden = YES;
    [self.view addSubview:self.focusIcon];

    UITapGestureRecognizer *bgViewTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bgViewTapClick:)];
    [self.view addGestureRecognizer:bgViewTap];
    self.bgViewTap = bgViewTap;
    
    UIImageView *topMaskView = [[UIImageView alloc] initWithImage:[HXPhotoTools hx_imageNamed:@"camera_shadow_up@2x.png"]];
    topMaskView.alpha = 0.8;
    topMaskView.frame = CGRectMake(0, 0, WIDTH, topMaskView.image.size.height);
    [self.view addSubview:topMaskView];
    
    UIImageView *bottomMaskView = [[UIImageView alloc] initWithImage:[HXPhotoTools hx_imageNamed:@"camera_shadow_down@2x.png"]];
    bottomMaskView.alpha = 0.85;
    bottomMaskView.frame = CGRectMake(0, HEIGHT - bottomMaskView.image.size.height, WIDTH, bottomMaskView.image.size.height);
    [self.view addSubview:bottomMaskView];
    
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [backBtn setImage:[HXPhotoTools hx_imageNamed:@"faceu_cancel@3x.png"] forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(didBackClick) forControlEvents:UIControlEventTouchUpInside];
    backBtn.frame = CGRectMake(15, 20, backBtn.currentImage.size.width, backBtn.currentImage.size.height);
    [self.view addSubview:backBtn];
    self.backBtn = backBtn;
    
    UIButton *changeCameraBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [changeCameraBtn setImage:[HXPhotoTools hx_imageNamed:@"faceu_camera@3x.png"] forState:UIControlStateNormal];
    [changeCameraBtn addTarget:self action:@selector(didchangeCameraClick) forControlEvents:UIControlEventTouchUpInside];
    changeCameraBtn.frame = CGRectMake(WIDTH - 15 - changeCameraBtn.currentImage.size.width, 20, changeCameraBtn.currentImage.size.width, changeCameraBtn.currentImage.size.height);
    [self.view addSubview:changeCameraBtn];
    self.changeCameraBtn = changeCameraBtn;
    
    self.flashBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.flashBtn setImage:[HXPhotoTools hx_imageNamed:@"camera_flashlight@2x的副本11.png"] forState:UIControlStateNormal];
    [self.flashBtn setImage:[HXPhotoTools hx_imageNamed:@"flash_pic_nopreview@2x.png"] forState:UIControlStateSelected];
    CGFloat flashBtnW = self.flashBtn.currentImage.size.width;
    CGFloat flashBtnH = self.flashBtn.currentImage.size.height;
    self.flashBtn.frame = CGRectMake(self.changeCameraBtn.frame.origin.x - 20 - flashBtnW, 0, flashBtnW, flashBtnH);
    self.flashBtn.center = CGPointMake(self.flashBtn.center.x, self.changeCameraBtn.center.y);
    [self.flashBtn addTarget:self action:@selector(didFlashClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.flashBtn];
    
    self.playView = [[HXFullScreenCameraPlayView alloc] initWithFrame:CGRectMake(0, HEIGHT - 20 - 70, 70, 70)];
    self.playView.center = CGPointMake(WIDTH / 2, self.playView.center.y);
    [self.view addSubview:self.playView];
    UILongPressGestureRecognizer *playViewLongPrg = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(playViewLongPgrEvent:)];
    playViewLongPrg.minimumPressDuration = 0.7;
    [self.playView addGestureRecognizer:playViewLongPrg];
    
    UITapGestureRecognizer *playViewTapGr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(playViewTapGrEvent:)];
    [self.playView addGestureRecognizer:playViewTapGr];
    
    self.timeLb = [[UILabel alloc] initWithFrame:CGRectMake(0, self.playView.frame.origin.y - 30, WIDTH, 16)];
    self.timeLb.text = self.titleStr;
    self.timeLb.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.9];
    self.timeLb.textAlignment = NSTextAlignmentCenter;
    self.timeLb.font = [UIFont systemFontOfSize:14];
    [self.view addSubview:self.timeLb];
    
    self.nextBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.nextBtn setTitle:[NSBundle hx_localizedStringForKey:@"下一步"] forState:UIControlStateNormal];
    [self.nextBtn setTitleColor:self.photoManager.UIManager.fullScreenCameraNextBtnTitleColor forState:UIControlStateNormal];
    [self.nextBtn setBackgroundColor:self.photoManager.UIManager.fullScreenCameraNextBtnBgColor];
    self.nextBtn.layer.masksToBounds = YES;
    self.nextBtn.layer.cornerRadius = 2;
    self.nextBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    self.nextBtn.frame = CGRectMake(WIDTH - 10 - 60, HEIGHT - 20 - 25, 60, 25);
    [self.nextBtn addTarget:self action:@selector(didNextBtnClick) forControlEvents:UIControlEventTouchUpInside];
    self.nextBtn.hidden = YES;
    [self.view addSubview:self.nextBtn];
    
    if (self.type == HXCameraTypePhoto) {
        playViewLongPrg.enabled = NO;
    }else if (self.type == HXCameraTypeVideo) {
        playViewTapGr.enabled = NO;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (self.session) {
            [self.session startRunning];
        }
    });
}
- (void)didFlashClick:(UIButton *)button {
    [self.device lockForConfiguration:nil];
    if ([self.device hasFlash]) {
        if (self.flashlight == 1) {
            self.flashlight = 0;
            self.flashBtn.selected = NO;
            self.device.flashMode = AVCaptureFlashModeOff;
        }else if (self.flashlight == 0){
            self.flashBtn.selected = YES;
            self.device.flashMode = AVCaptureFlashModeOn;
            self.flashlight = 1;
        }
    } else {
        NSSLog(@"设备不支持闪光灯");
    }
    [self.device unlockForConfiguration];
}
/// 重力感应回调
- (void)handleDeviceMotion:(CMDeviceMotion *)deviceMotion{
    double x = deviceMotion.gravity.x;
    double y = deviceMotion.gravity.y;
    
    if (fabs(y) >= fabs(x)) {
        if (y >= 0) {
            _imageOrientation = UIDeviceOrientationPortraitUpsideDown;
            _deviceOrientation = UIDeviceOrientationPortraitUpsideDown;
        } else {
            _imageOrientation = UIDeviceOrientationPortrait;
            _deviceOrientation = UIDeviceOrientationPortrait;
        }
    } else {
        if (x >= 0) {
            _imageOrientation = UIDeviceOrientationLandscapeRight;
            _deviceOrientation = UIDeviceOrientationLandscapeRight;    // Home键左侧水平拍摄
        } else {
            _imageOrientation = UIDeviceOrientationLandscapeLeft;
            _deviceOrientation = UIDeviceOrientationLandscapeLeft;     // Home键右侧水平拍摄
        }
    }
}
// 切换前后置摄像头
- (void)didchangeCameraClick {
    [self changeCamera];
}
- (void)changeCamera{
    NSUInteger cameraCount = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count];
    if (cameraCount > 1) {
        NSError *error;
        //给摄像头的切换添加翻转动画
        CATransition *animation = [CATransition animation];
        animation.duration = .5f;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        animation.type = @"oglFlip";
        
        AVCaptureDevice *newCamera = nil;
        AVCaptureDeviceInput *newInput = nil;
        //拿到另外一个摄像头位置
        AVCaptureDevicePosition position = [[_input device] position];
        if (position == AVCaptureDevicePositionFront){
            self.flashBtn.hidden = NO;
            self.flashBtn.enabled = YES;
            newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
            animation.subtype = kCATransitionFromLeft;//动画翻转方向
        }
        else {
            self.flashBtn.hidden = YES;
            self.flashBtn.enabled = NO;
            newCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
            animation.subtype = kCATransitionFromRight;//动画翻转方向
        }
        //生成新的输入
        newInput = [AVCaptureDeviceInput deviceInputWithDevice:newCamera error:nil];
        [self.previewLayer addAnimation:animation forKey:nil];
        if (newInput != nil) {
            [self.session beginConfiguration];
            [self.session removeInput:self.input];
            if ([self.session canAddInput:newInput]) {
                [self.session addInput:newInput];
                self.input = newInput;
                
            } else {
                [self.session addInput:self.input];
            }
            [self.session commitConfiguration];
            
        } else if (error) {
            NSSLog(@"toggle carema failed, error = %@", error);
        }
    }
}
- (void)bgViewTapClick:(UITapGestureRecognizer *)tap {
    CGPoint point = [tap locationInView:self.view];
    [self focusAtPoint:point];
}
- (void)focusAtPoint:(CGPoint)point{
    CGSize size = self.view.bounds.size;
    CGPoint focusPoint = CGPointMake( point.y /size.height ,1-point.x/size.width );
    NSError *error;
    if ([self.device lockForConfiguration:&error]) {
        //对焦模式和对焦点
        if ([self.device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            [self.device setFocusPointOfInterest:focusPoint];
            [self.device setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        //曝光模式和曝光点
        if ([self.device isExposureModeSupported:AVCaptureExposureModeAutoExpose ]) {
            [self.device setExposurePointOfInterest:focusPoint];
            [self.device setExposureMode:AVCaptureExposureModeAutoExpose];
        }
        
        [self.device unlockForConfiguration];
        //设置对焦动画
        self.focusIcon.center = point;
        self.focusIcon.hidden = NO;
        [UIView animateWithDuration:0.2 animations:^{
            self.focusIcon.transform = CGAffineTransformMakeScale(1.25, 1.25);
        }completion:^(BOOL finished) {
            [UIView animateWithDuration:0.2 animations:^{
                self.focusIcon.transform = CGAffineTransformIdentity;
            } completion:^(BOOL finished) {
                self.focusIcon.hidden = YES;
            }];
        }];
        
    }
}
//缩放手势 用于调整焦距
- (void)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer{
    BOOL allTouchesAreOnThePreviewLayer = YES;
    NSUInteger numTouches = [recognizer numberOfTouches], i;
    for (i = 0; i < numTouches; ++i ) {
        CGPoint location = [recognizer locationOfTouch:i inView:self.view];
        CGPoint convertedLocation = [self.previewLayer convertPoint:location fromLayer:self.previewLayer.superlayer];
        if (![self.previewLayer containsPoint:convertedLocation] ) {
            allTouchesAreOnThePreviewLayer = NO;
            break;
        }
    }
    if (allTouchesAreOnThePreviewLayer ) {
        self.effectiveScale = self.beginGestureScale * recognizer.scale;
        CGFloat maxScaleAndCropFactor = [[self.imageOutput connectionWithMediaType:AVMediaTypeVideo] videoMaxScaleAndCropFactor];
        if (maxScaleAndCropFactor > 5.0f) {
            maxScaleAndCropFactor = 5.0f;
        }
        if (self.effectiveScale < 1.0){
            self.effectiveScale = 1.0;
        }
        
        if (self.effectiveScale > maxScaleAndCropFactor)
            self.effectiveScale = maxScaleAndCropFactor;
        [CATransaction begin];
        [CATransaction setAnimationDuration:.015];
        [self.previewLayer setAffineTransform:CGAffineTransformMakeScale(self.effectiveScale, self.effectiveScale)];
        [CATransaction commit];
    }
}
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ( [gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] ) {
        self.beginGestureScale = self.effectiveScale;
    }
    return YES;
}
- (void)didBackClick {
    if (!self.backBtn.selected) {
        [self.session stopRunning];
        [self.timer invalidate];
        self.timer = nil;
        [self.playerLayer removeFromSuperlayer];
        self.playerLayer = nil;
        [self.motionManager stopDeviceMotionUpdates];
        [self dismissViewControllerAnimated:YES completion:nil];
    }else {
        if (self.flashBtn.enabled) {
            self.flashBtn.hidden = NO;
        }
        self.videoURL = nil;
        self.bgViewTap.enabled = YES;
        self.nextBtn.hidden = YES;
        self.imageView.hidden = YES;
        self.backBtn.selected = NO;
        [self.backBtn setTitle:@"" forState:UIControlStateNormal];
        [self.backBtn setImage:[HXPhotoTools hx_imageNamed:@"faceu_cancel@3x.png"] forState:UIControlStateNormal];
        self.backBtn.frame = CGRectMake(15, 20, self.backBtn.currentImage.size.width, self.backBtn.currentImage.size.height);
        self.timeLb.text = self.titleStr;
        self.playView.hidden = NO;
        self.timeLb.hidden = NO;
        self.changeCameraBtn.hidden = NO;
        [[self.playerLayer player] pause];
        self.playerLayer.hidden = YES;
    }
}
// 切换闪光灯状态
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for ( AVCaptureDevice *device in devices )
        if ( device.position == position ){
            if (!self.first) {
                self.first = YES;
                [device lockForConfiguration:nil];
                if ([device hasFlash]) {
                    [device setFlashMode:AVCaptureFlashModeAuto];
                }
                [device unlockForConfiguration];
            }
            return device;
        }
    return nil;
}
// 点击事件
- (void)playViewTapGrEvent:(UITapGestureRecognizer *)tap {
    AVCaptureConnection *conntion = [self.imageOutput connectionWithMediaType:AVMediaTypeVideo];
    if (!conntion) {
        [self.view showImageHUDText:[NSBundle hx_localizedStringForKey:@"拍摄失败"]];
        return;
    }
    if (conntion.isVideoOrientationSupported) {
        conntion.videoOrientation = [self currentVideoOrientation];
    }
    __weak typeof(self) weakSelf = self;
    [self.imageOutput captureStillImageAsynchronouslyFromConnection:conntion completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if (imageDataSampleBuffer == nil) {
            return ;
        }
        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        weakSelf.imageView.image = [UIImage imageWithData:imageData];
        if (weakSelf.effectiveScale > 1) {
            weakSelf.imageView.transform = CGAffineTransformMakeScale(weakSelf.effectiveScale, weakSelf.effectiveScale);
        }
        weakSelf.imageView.hidden = NO;
        [weakSelf hideClick];
    }];
}
// 调整设备取向
- (AVCaptureVideoOrientation)currentVideoOrientation {
    AVCaptureVideoOrientation orientation;
    switch (self.imageOrientation) {
        case UIDeviceOrientationPortrait:
            orientation = AVCaptureVideoOrientationPortrait;
            break;
        case UIDeviceOrientationLandscapeRight:
            orientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            orientation = AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        default:
            orientation = AVCaptureVideoOrientationLandscapeRight;
            break;
    }
    return orientation;
}
- (void)hideClick {
    self.flashBtn.hidden = YES;
    self.bgViewTap.enabled = NO;
    self.nextBtn.hidden = NO;
    self.changeCameraBtn.hidden = YES;
    self.timeLb.hidden = YES;
    self.playView.hidden = YES;
    [self.backBtn setImage:[[UIImage alloc] init] forState:UIControlStateNormal];
    [self.backBtn setTitle:[NSBundle hx_localizedStringForKey:@"重拍"] forState:UIControlStateNormal];
    self.backBtn.hx_w = [HXPhotoTools getTextWidth:self.backBtn.currentTitle height:18 fontSize:17] + 20;
    self.backBtn.selected = YES;
}
// 长按手势
- (void)playViewLongPgrEvent:(UILongPressGestureRecognizer *)longPgr {
    if (longPgr.state == UIGestureRecognizerStatePossible) {
    }
    if (longPgr.state == UIGestureRecognizerStateBegan) {
        self.changeCameraBtn.hidden = YES;
        self.flashBtn.hidden = YES;
        self.effectiveScale = 1.0f;
        [UIView animateWithDuration:0.5 animations:^{
            self.playView.transform = CGAffineTransformMakeScale(1.15, 1.15);
            [self.previewLayer setAffineTransform:CGAffineTransformMakeScale(self.effectiveScale, self.effectiveScale)];
        }];
        [self cameraBackgroundDidClickPlay];
    }
    if (longPgr.state == UIGestureRecognizerStateChanged) {
        
    }
    if (longPgr.state == UIGestureRecognizerStateCancelled ||
        longPgr.state == UIGestureRecognizerStateEnded){
        [self.timer invalidate];
        self.timer = nil;
        [self.videoOutPut stopRecording]; 
        [self.playView clean];
        if (self.videoTime < 3) {
            self.changeCameraBtn.hidden = NO;
            if (self.flashBtn.enabled) {
                self.flashBtn.hidden = NO;
            }
            [self.view showImageHUDText:[NSBundle hx_localizedStringForKey:@"录制时间少于3秒"]];
            self.timeLb.text = self.titleStr;
        }else {
            [self hideClick];
        }
        [UIView animateWithDuration:0.25 animations:^{
            self.playView.transform = CGAffineTransformIdentity;
        }];
    }
}
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections { 
    // 开始录制
    self.videoTime = 0;
    self.timeLb.text = [NSString stringWithFormat:@"0s"];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(recordingClick:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    [self.timer invalidate];
    self.timer = nil;
    if (self.videoTime >= 3) {
        // 录制结束
        self.playerLayer.hidden = NO;
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:outputFileURL];
        AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
        self.playerLayer.player = player;
        [player play];
        self.videoURL = outputFileURL;
        [self hideClick];
    }
}
- (void)recordingClick:(NSTimer *)timer {
    self.videoTime++;
    self.timeLb.text = [NSString stringWithFormat:@"%lds",self.videoTime];
    self.playView.progress = (CGFloat)self.videoTime / 60.f;
    if (self.videoTime == 60) {
        [timer invalidate];
        self.timer = nil;
    }
}
- (void)cameraBackgroundDidClickPlay {
    // 根据连接取得设备输出的数据
    AVCaptureConnection *captureConnection = [self.videoOutPut connectionWithMediaType:AVMediaTypeVideo];
    if (![self.videoOutPut isRecording]) {
        captureConnection.videoOrientation = (AVCaptureVideoOrientation)_deviceOrientation; // 视频方向和手机方向一致
        NSURL *fileURL = [self outPutFileURL];
        [self.videoOutPut startRecordingToOutputFileURL:fileURL recordingDelegate:self];
    }
}

- (NSURL *)outPutFileURL {
    return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), [NSString stringWithFormat:@"hx%@.mov",[self videoOutFutFileName]]]];
}

- (NSString *)videoOutFutFileName {
    NSString *fileName = @"";
    NSDate *nowDate = [NSDate date];
    NSString *dateStr = [NSString stringWithFormat:@"%ld", (long)[nowDate timeIntervalSince1970]];
    NSString *numStr = [NSString stringWithFormat:@"%d",arc4random()%10000];
    fileName = [fileName stringByAppendingString:dateStr];
    fileName = [fileName stringByAppendingString:numStr];
    return fileName;
}
- (void)editViewControllerDidNextClick:(HXPhotoModel *)model {
    [self.session stopRunning];
    [self.motionManager stopDeviceMotionUpdates];
    [self.timer invalidate];
    self.timer = nil;
    [self dismissViewControllerAnimated:NO completion:^{
        if ([self.delegate respondsToSelector:@selector(cameraDidNextClick:)]) {
            [self.delegate fullScreenCameraDidNextClick:model];
        }
    }];
}
- (void)didNextBtnClick {
    HXPhotoModel *model = [[HXPhotoModel alloc] init];
    if (!self.videoURL) {
        model.type = HXPhotoModelMediaTypeCameraPhoto;
        model.subType = HXPhotoModelMediaSubTypePhoto;
        if (self.imageView.image.imageOrientation != UIImageOrientationUp) {
            self.imageView.image = [self.imageView.image fullNormalizedImage];
        }
        UIImage *image;
        if (self.effectiveScale > 1) {
            image = [self.imageView.image scaleImagetoScale:self.effectiveScale];
        }else {
            image = self.imageView.image;
        }
        image = [image clipNormalizedImage:self.effectiveScale];
        model.thumbPhoto = image;
        model.imageSize = image.size;
        model.previewPhoto = image;
        model.cameraIdentifier = [self videoOutFutFileName];
        if (self.photoManager.singleSelected) {
            HXPhotoEditViewController *vc = [[HXPhotoEditViewController alloc] init];
            vc.model = model;
            vc.coverImage = model.thumbPhoto;
            vc.delegate = self;
            vc.photoManager = self.photoManager;
            [self.navigationController pushViewController:vc animated:YES];
            return;
        }
    }else {
        [self.timer invalidate];
        self.timer = nil;
        if (self.videoTime < 3) {
            [self.view showImageHUDText:[NSBundle hx_localizedStringForKey:@"录制时间少于3秒"]];
            return;
        }
        [self.playerLayer.player pause];
        model.type = HXPhotoModelMediaTypeCameraVideo;
        model.subType = HXPhotoModelMediaSubTypeVideo;
        MPMoviePlayerController *player = [[MPMoviePlayerController alloc]initWithContentURL:self.videoURL] ;
        player.shouldAutoplay = NO;
        UIImage  *image = [player thumbnailImageAtTime:1.0 timeOption:MPMovieTimeOptionNearestKeyFrame];
        NSString *videoTime = [HXPhotoTools getNewTimeFromDurationSecond:self.videoTime];
        model.videoURL = self.videoURL;
        model.videoTime = videoTime;
        model.thumbPhoto = image;
        model.imageSize = image.size;
        model.previewPhoto = image;
        model.cameraIdentifier = [self videoOutFutFileName]; 
    }
    if ([self.delegate respondsToSelector:@selector(cameraDidNextClick:)]) {
        [self.delegate fullScreenCameraDidNextClick:model];
    }
    [self.timer invalidate];
    self.timer = nil;
    [self.session stopRunning];
    [self.motionManager stopDeviceMotionUpdates];
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source{
    return [HXVideoPresentTransition transitionWithTransitionType:HXVideoPresentTransitionPresent];
}
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed{
    return [HXVideoPresentTransition transitionWithTransitionType:HXVideoPresentTransitionDismiss];
}
- (void)dealloc {
    NSSLog(@"dealloc");
}
@end
