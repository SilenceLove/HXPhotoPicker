//
//  HXCameraViewController.m
//  微博照片选择
//
//  Created by 洪欣 on 17/2/13.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXCameraViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreMotion/CoreMotion.h>
#import <MediaPlayer/MediaPlayer.h>
#import "HXPhotoTools.h"
#import "UIView+HXExtension.h"
#import "UIImage+HXExtension.h"
#import "HXVideoPresentTransition.h"
@interface HXCameraViewController ()<UIGestureRecognizerDelegate,AVCaptureFileOutputRecordingDelegate,UIViewControllerTransitioningDelegate>
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

//图像预览层，实时显示捕获的图像
@property (nonatomic ,strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (weak, nonatomic) UIView *backView;
@property (assign, nonatomic) NSInteger flashlight;
@property (weak, nonatomic) UIButton *rightTwo;
@property (weak, nonatomic) UIButton *rightOne;
@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, assign) UIDeviceOrientation deviceOrientation;
/**
 *  记录开始的缩放比例
 */
@property(nonatomic,assign)CGFloat beginGestureScale;
/**
 * 最后的缩放比例
 */
@property(nonatomic,assign)CGFloat effectiveScale;
@property (weak, nonatomic) UIButton *photoBtn;
@property (weak, nonatomic) UIButton *videoBtn;
@property (strong, nonatomic) AVCaptureMovieFileOutput *videoOutPut;
@property (strong, nonatomic) UIImageView *imageView;

@property (strong, nonatomic) UIView *moveView;
@property (weak, nonatomic) UIButton *changePhotoBtn;
@property (weak, nonatomic) UIButton *changeVideoBtn;

@property (strong, nonatomic) UIButton *deleteBtn;
@property (strong, nonatomic) UIButton *nextBtn;
@property (strong, nonatomic) UIButton *albumBtn;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;

@property (weak, nonatomic) UISwipeGestureRecognizer *leftSwipe;
@property (weak, nonatomic) UISwipeGestureRecognizer *rightSwipe;

@property (strong, nonatomic) NSURL *videoURL;
@property (weak, nonatomic) UIPinchGestureRecognizer *pinch;
@property (weak, nonatomic) UITapGestureRecognizer *tap;
@property (weak, nonatomic) UIProgressView *progressView;
@property (weak, nonatomic) NSTimer *timer;
@property (assign, nonatomic) NSInteger videoTime;
@property (weak, nonatomic) UIView *maskViewO;
@property (weak, nonatomic) UIView *maskViewT;

@property (strong, nonatomic) UIImageView *focusIcon;
@property (strong, nonatomic) UISlider *zoomSlider;
@property (strong, nonatomic) NSURL *clipVideoURL;
@property (assign, nonatomic) BOOL first;
@end

@implementation HXCameraViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.transitioningDelegate = self;
        self.modalPresentationStyle = UIModalPresentationCustom;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    [self cameraDistrict];
}

- (void)dismiss
{
    [self.session stopRunning];
    [UIView animateWithDuration:0.4 animations:^{
        self.maskViewO.frame = CGRectMake(0, 0, self.backView.frame.size.width, self.backView.frame.size.height / 2);
        self.maskViewT.frame = CGRectMake(0, self.backView.frame.size.height / 2, self.backView.frame.size.width, self.backView.frame.size.height / 2);
    } completion:^(BOOL finished) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
}

- (void)cameraDistrict
{
    CGFloat width = self.view.frame.size.width;
    CGFloat height = self.view.frame.size.height;
    UINavigationBar *navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, width, 64)];
    [self.view addSubview:navBar];
    UINavigationItem *navItem = [[UINavigationItem alloc] init];
    [navBar pushNavigationItem:navItem animated:NO];
    self.beginGestureScale = 1.0f;
    self.effectiveScale = 1.0f;
    navItem.title = @"拍摄";
    UIButton *leftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [leftBtn setImage:[UIImage imageNamed:@"camera_close@2x.png"] forState:UIControlStateNormal];
    [leftBtn setImage:[UIImage imageNamed:@"camera_close_highlighted@2x.png"] forState:UIControlStateHighlighted];
    [leftBtn addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    leftBtn.frame = CGRectMake(0, 0, leftBtn.currentImage.size.width, leftBtn.currentImage.size.height);
    
    UIButton *rightOne = [UIButton buttonWithType:UIButtonTypeCustom];
    [rightOne setImage:[UIImage imageNamed:@"camera_overturn@2x.png"] forState:UIControlStateNormal];
    [rightOne setImage:[UIImage imageNamed:@"camera_overturn_highlighted@2x.png"] forState:UIControlStateHighlighted];
    [rightOne addTarget:self action:@selector(didRightOneClick) forControlEvents:UIControlEventTouchUpInside];
    rightOne.frame = CGRectMake(0, 0, rightOne.currentImage.size.width, rightOne.currentImage.size.height);
    self.rightOne = rightOne;
    
    UIButton *rightTwo = [UIButton buttonWithType:UIButtonTypeCustom];
    [rightTwo setImage:[UIImage imageNamed:@"camera_flashlight_auto_disable@2x.png"] forState:UIControlStateNormal];
    [rightTwo addTarget:self action:@selector(didRightTwoClick) forControlEvents:UIControlEventTouchUpInside];
    rightTwo.frame = CGRectMake(0, 0, rightTwo.currentImage.size.width, rightTwo.currentImage.size.height);
    self.rightTwo = rightTwo;
    
    navItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:leftBtn];
    UIBarButtonItem *rightOne_ = [[UIBarButtonItem alloc] initWithCustomView:rightOne];
    UIBarButtonItem *rightTwo_ = [[UIBarButtonItem alloc] initWithCustomView:rightTwo];
    self.flashlight = 0;
    //    AVCaptureDevicePositionBack  后置摄像头
    //    AVCaptureDevicePositionFront 前置摄像头
    self.device = [self cameraWithPosition:AVCaptureDevicePositionBack];
    
    if ([self.device hasFlash]) {
        navItem.rightBarButtonItems = @[rightOne_,rightTwo_];
    }else {
        navItem.rightBarButtonItems = @[rightOne_];
    }
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
    UIView *backView = [[UIView alloc] initWithFrame:CGRectMake(0, 64, width, width)];
    backView.layer.masksToBounds = YES;
    [self.view addSubview:backView];
    self.backView = backView;
    //预览层的生成
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    self.previewLayer.frame = backView.bounds;
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [backView.layer addSublayer:self.previewLayer];
    
    if ([_device lockForConfiguration:nil]) {
        //自动闪光灯，
        if ([_device isFlashModeSupported:AVCaptureFlashModeAuto]) {
            [_device setFlashMode:AVCaptureFlashModeAuto];
        }
        if ([_device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance]) {
            [_device setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];
        }
        [_device unlockForConfiguration];
    }
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    pinch.delegate = self;
    [self.backView addGestureRecognizer:pinch];
    self.pinch = pinch;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapClick:)];
    [self.backView addGestureRecognizer:tap];
    self.tap = tap;
    
    UIButton *photoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [photoBtn setImage:[UIImage imageNamed:@"camera_camera_background@2x.png"] forState:UIControlStateNormal];
    [photoBtn setImage:[UIImage imageNamed:@"camera_camera_background_highlighted@2x.png"] forState:UIControlStateHighlighted];
    [self.view addSubview:photoBtn];
    [photoBtn addTarget:self action:@selector(didPhotoClick) forControlEvents:UIControlEventTouchUpInside];
    photoBtn.frame = CGRectMake(0, 0, photoBtn.currentImage.size.width, photoBtn.currentImage.size.height);
    photoBtn.center = CGPointMake(width / 2, CGRectGetMaxY(backView.frame) + (height - CGRectGetMaxY(backView.frame)) / 2);
    self.photoBtn = photoBtn;
    
    UIButton *videoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [videoBtn setImage:[UIImage imageNamed:@"camera_video_background@2x.png"] forState:UIControlStateNormal];
    [self.view addSubview:videoBtn];
    videoBtn.hidden = YES;
    UILongPressGestureRecognizer *longPGR = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongClick:)];
    longPGR.minimumPressDuration = 0.1;
    [videoBtn addGestureRecognizer:longPGR];
    videoBtn.frame = CGRectMake(0, 0, videoBtn.currentImage.size.width, videoBtn.currentImage.size.height);
    videoBtn.center = CGPointMake(width / 2, CGRectGetMaxY(backView.frame) + (height - CGRectGetMaxY(backView.frame)) / 2);
    self.videoBtn = videoBtn;
    
    UISwipeGestureRecognizer *leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(leftSwipeClick:)];
    leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:leftSwipe];
    self.leftSwipe = leftSwipe;
    
    UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(rightSwipeClick:)];
    rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:rightSwipe];
    self.rightSwipe = rightSwipe;
    
    UIImageView *centerIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"camera_drop_highlighted@2x.png"]];
    centerIcon.frame = CGRectMake(0, 0, centerIcon.image.size.width, centerIcon.image.size.height);
    centerIcon.center = CGPointMake(width / 2, CGRectGetMaxY(backView.frame) + 10);
    [self.view addSubview:centerIcon];
    
    [self.view addSubview:self.moveView];
    self.moveView.center = CGPointMake(width / 2 + self.moveView.frame.size.width / 4, CGRectGetMaxY(centerIcon.frame) + 10);
    self.changePhotoBtn.selected = YES;
    
    [self.view addSubview:self.deleteBtn];
    [self.view addSubview:self.nextBtn];
    
    self.imageView = [[UIImageView alloc] init];
    self.imageView.frame = self.backView.bounds;
    self.imageView.hidden = YES;
    self.imageView.clipsToBounds = YES;
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.backView addSubview:self.imageView];
    
    self.playerLayer = [[AVPlayerLayer alloc] init];
    self.playerLayer.frame = self.backView.bounds;
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.backView.layer addSublayer:self.playerLayer];
    
    UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    progressView.frame = CGRectMake(0, width - 2.5, width, 2.5);
    progressView.trackTintColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.8];
    progressView.hidden = YES;
    progressView.progressTintColor = [UIColor orangeColor];
    [self.backView addSubview:progressView];
    self.progressView = progressView;
    
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.deviceMotionUpdateInterval = 1/15.0;
    if (self.motionManager.deviceMotionAvailable) {
        [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMDeviceMotion * _Nullable motion, NSError * _Nullable error) {
            [self performSelectorOnMainThread:@selector(handleDeviceMotion:) withObject:motion waitUntilDone:YES];
        }];
    } else {
        NSLog(@"No device motion on device");
    }
    
    if (self.type == HXCameraTypePhotoAndVideo) {
        if ([self.session canAddOutput:self.imageOutput]) {
            [self.session addOutput:self.imageOutput];
        }
    }else if (self.type == HXCameraTypePhoto) {
        if ([self.session canAddOutput:self.imageOutput]) {
            [self.session addOutput:self.imageOutput];
        }
        leftSwipe.enabled = NO;
        rightSwipe.enabled = NO;
        self.changeVideoBtn.hidden = YES;
        self.videoBtn.hidden = YES;
    }else if (self.type == HXCameraTypeVideo) {
        if ([self.session canAddOutput:self.videoOutPut]) {
            [self.session addOutput:self.videoOutPut];
        }
        [self didMoveViewClick:self.changeVideoBtn];
        leftSwipe.enabled = NO;
        rightSwipe.enabled = NO;
        self.changePhotoBtn.hidden = YES;
        self.photoBtn.hidden = YES;
    }
    
    UIView *maskViewO = [[UIImageView alloc] init];
    maskViewO.backgroundColor = [UIColor whiteColor];
    maskViewO.frame = CGRectMake(0, 0, self.backView.frame.size.width, self.backView.frame.size.height / 2);
    [self.backView addSubview:maskViewO];
    self.maskViewO = maskViewO;
    UIView *maskViewT = [[UIImageView alloc] init];
    maskViewT.backgroundColor = [UIColor whiteColor];
    maskViewT.frame = CGRectMake(0, self.backView.frame.size.height / 2, self.backView.frame.size.width, self.backView.frame.size.height / 2);
    [self.backView addSubview:maskViewT];
    self.maskViewT = maskViewT;
    
//    self.zoomSlider = [[UISlider alloc] init];
//    self.zoomSlider =
//    [self.backView addSubview:self.zoomSlider];
    
    self.focusIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"camera_ Focusing@2x.png"]];
    self.focusIcon.frame = CGRectMake(0, 0, self.focusIcon.image.size.width, self.focusIcon.image.size.height);
    self.focusIcon.hidden = YES;
    [self.backView addSubview:self.focusIcon];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (self.session) {
            [self.session startRunning];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.4 animations:^{
                maskViewO.frame = CGRectMake(0, - self.backView.frame.size.height / 2, self.backView.frame.size.width, self.backView.frame.size.height / 2);
                maskViewT.frame = CGRectMake(0, self.backView.frame.size.height, self.backView.frame.size.width, self.backView.frame.size.height / 2);
            }];
        });
    });
}

/// 重力感应回调
- (void)handleDeviceMotion:(CMDeviceMotion *)deviceMotion{
    double x = deviceMotion.gravity.x;
    double y = deviceMotion.gravity.y;
    
    CGAffineTransform videoTransform;
    
    if (fabs(y) >= fabs(x)) {
        if (y >= 0) {
            videoTransform = CGAffineTransformMakeRotation(M_PI);
            _deviceOrientation = UIDeviceOrientationPortraitUpsideDown;
            [UIView animateWithDuration:0.25 animations:^{
                self.videoBtn.transform = CGAffineTransformMakeRotation(M_PI);
            }];
        } else {
            videoTransform = CGAffineTransformMakeRotation(0);
            _deviceOrientation = UIDeviceOrientationPortrait;
            [UIView animateWithDuration:0.25 animations:^{
                self.videoBtn.transform = CGAffineTransformIdentity;
            }];
        }
    } else {
        if (x >= 0) {
            videoTransform = CGAffineTransformMakeRotation(-M_PI_2);
            _deviceOrientation = UIDeviceOrientationLandscapeRight;    // Home键左侧水平拍摄
            [UIView animateWithDuration:0.25 animations:^{
                self.videoBtn.transform = CGAffineTransformMakeRotation(-M_PI_2);
            }];
        } else {
            videoTransform = CGAffineTransformMakeRotation(M_PI_2);
            _deviceOrientation = UIDeviceOrientationLandscapeLeft;     // Home键右侧水平拍摄
            [UIView animateWithDuration:0.25 animations:^{
                self.videoBtn.transform = CGAffineTransformMakeRotation(M_PI_2);
            }];
        }
    }
}

- (void)leftSwipeClick:(UISwipeGestureRecognizer *)swipe
{
    if (swipe.direction == UISwipeGestureRecognizerDirectionLeft) {
        [self didMoveViewClick:self.changeVideoBtn];
    }
}

- (void)rightSwipeClick:(UISwipeGestureRecognizer *)swipe
{
    if (swipe.direction == UISwipeGestureRecognizerDirectionRight) {
        [self didMoveViewClick:self.changePhotoBtn];
    }
}

- (void)didPhotoClick
{
    AVCaptureConnection *conntion = [self.imageOutput connectionWithMediaType:AVMediaTypeVideo];
    if (!conntion) {
        [self.view showImageHUDText:@"照片失败"];
        return;
    }
    [self.imageOutput captureStillImageAsynchronouslyFromConnection:conntion completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if (imageDataSampleBuffer == nil) {
            return ;
        }
        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        self.imageView.image = [UIImage imageWithData:imageData];
        if (self.effectiveScale > 1) {
            self.imageView.transform = CGAffineTransformMakeScale(self.effectiveScale, self.effectiveScale);
        }
        self.imageView.hidden = NO;
        [self hideClick];
    }];
}

- (void)didLongClick:(UILongPressGestureRecognizer *)longRPG
{
    if ([longRPG state] == UIGestureRecognizerStateBegan) {
        [self.videoBtn setImage:[UIImage imageNamed:@"camera_video_background_highlighted@2x.png"] forState:UIControlStateNormal];
        [self cameraBackgroundDidClickPlay];
    }else if ([longRPG state] == UIGestureRecognizerStateEnded) {
        [self.videoBtn setImage:[UIImage imageNamed:@"camera_video_background@2x.png"] forState:UIControlStateNormal];
        [self.videoOutPut stopRecording];
        [self.timer invalidate];
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

- (NSURL *)outPutFileURL
{
    return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), [NSString stringWithFormat:@"hx%@.mov",[self videoOutFutFileName]]]];
}

- (NSString *)videoOutFutFileName
{
    NSString *fileName = @"";
    NSDate *nowDate = [NSDate date];
    NSString *dateStr = [NSString stringWithFormat:@"%ld", (long)[nowDate timeIntervalSince1970]];
    NSString *numStr = [NSString stringWithFormat:@"%d",arc4random()%10000];
    fileName = [fileName stringByAppendingString:dateStr];
    fileName = [fileName stringByAppendingString:numStr];
    return fileName;
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
    // 开始录制
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(recordingClick:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)recordingClick:(NSTimer *)timer
{
    self.videoTime++;
    [self.progressView setProgress:self.videoTime / 60.f animated:YES];
    if (self.videoTime == 60) {
        [timer invalidate];
        [self.videoBtn setImage:[UIImage imageNamed:@"camera_video_background@2x.png"] forState:UIControlStateNormal];
        [self.videoOutPut stopRecording];
    }
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    [self.timer invalidate];
    // 录制结束
    self.playerLayer.hidden = NO;
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:outputFileURL];
    AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
    self.playerLayer.player = player;
    [player play];
    self.videoURL = outputFileURL;
    [self hideClick];
}

- (void)hideClick
{
    self.videoBtn.hidden = YES;
    self.photoBtn.hidden = YES;
    self.deleteBtn.hidden = NO;
    self.nextBtn.hidden = NO;
    self.rightOne.enabled = NO;
    self.leftSwipe.enabled = NO;
    self.rightSwipe.enabled = NO;
    self.moveView.userInteractionEnabled = NO;
}

- (void)didRightOneClick
{
    [self changeCamera];
}

- (void)didRightTwoClick
{
    [self.device lockForConfiguration:nil];
    if ([self.device hasFlash]) {
        if (self.flashlight == 0) {
            self.flashlight = 1;
            [self.rightTwo setImage:[UIImage imageNamed:@"camera_flashlight_disable@2x.png"] forState:UIControlStateNormal];
            self.device.flashMode = AVCaptureFlashModeOff;
        }else if (self.flashlight == 1){
            self.flashlight = 1;
            [self.rightTwo setImage:[UIImage imageNamed:@"camera_flashlight_open_disable@2x.png"] forState:UIControlStateNormal];
            self.device.flashMode = AVCaptureFlashModeOn;
            self.flashlight = 2;
        }else {
            self.flashlight = 0;
            [self.rightTwo setImage:[UIImage imageNamed:@"camera_flashlight_auto_disable@2x.png"] forState:UIControlStateNormal];
            self.device.flashMode = AVCaptureFlashModeAuto;
        }
    } else {
        NSLog(@"设备不支持闪光灯");
    }
    [self.device unlockForConfiguration];
}

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

//缩放手势 用于调整焦距
- (void)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer{
    BOOL allTouchesAreOnThePreviewLayer = YES;
    NSUInteger numTouches = [recognizer numberOfTouches], i;
    for (i = 0; i < numTouches; ++i ) {
        CGPoint location = [recognizer locationOfTouch:i inView:self.backView];
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
        [CATransaction setAnimationDuration:.025];
        [self.previewLayer setAffineTransform:CGAffineTransformMakeScale(self.effectiveScale, self.effectiveScale)];
        [CATransaction commit];
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ( [gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] ) {
        self.beginGestureScale = self.effectiveScale;
    }
    return YES;
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
            self.rightTwo.hidden = NO;
            newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
            animation.subtype = kCATransitionFromLeft;//动画翻转方向
        }
        else {
            self.rightTwo.hidden = YES;
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
            NSLog(@"toggle carema failed, error = %@", error);
        }
    }
}

- (void)tapClick:(UITapGestureRecognizer *)tap
{
    CGPoint point = [tap locationInView:self.backView];
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

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if (self.session) {
        [self.session stopRunning];
    }
}

- (UIView *)moveView
{
    if (!_moveView) {
        _moveView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 25)];
        UIButton *changePhotoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [changePhotoBtn setTitle:@"照片" forState:UIControlStateNormal];
        [changePhotoBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [changePhotoBtn setTitleColor:[UIColor colorWithRed:253/255.0 green:142/255.0 blue:36/255.0 alpha:1] forState:UIControlStateSelected];
        [changePhotoBtn setTitleColor:[UIColor colorWithRed:253/255.0 green:142/255.0 blue:36/255.0 alpha:1] forState:UIControlStateHighlighted];
        changePhotoBtn.titleLabel.font = [UIFont systemFontOfSize:11];
        [changePhotoBtn addTarget:self action:@selector(didMoveViewClick:) forControlEvents:UIControlEventTouchUpInside];
        changePhotoBtn.frame = CGRectMake(0, 0, 50, 25);
        changePhotoBtn.tag = 0;
        [_moveView addSubview:changePhotoBtn];
        self.changePhotoBtn = changePhotoBtn;
        
        UIButton *changeVideoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [changeVideoBtn setTitle:@"视频" forState:UIControlStateNormal];
        [changeVideoBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [changeVideoBtn setTitleColor:[UIColor colorWithRed:253/255.0 green:142/255.0 blue:36/255.0 alpha:1] forState:UIControlStateSelected];
        [changeVideoBtn setTitleColor:[UIColor colorWithRed:253/255.0 green:142/255.0 blue:36/255.0 alpha:1] forState:UIControlStateHighlighted];
        changeVideoBtn.titleLabel.font = [UIFont systemFontOfSize:11];
        [changeVideoBtn addTarget:self action:@selector(didMoveViewClick:) forControlEvents:UIControlEventTouchUpInside];
        changeVideoBtn.frame = CGRectMake(50, 0, 50, 25);
        changeVideoBtn.tag = 1;
        [_moveView addSubview:changeVideoBtn];
        self.changeVideoBtn = changeVideoBtn;
    }
    return _moveView;
}

- (void)didMoveViewClick:(UIButton *)button
{
    if (button.selected) {
        return;
    }
    button.selected = !button.selected;
    if (button.tag == 0) {
        self.progressView.hidden = YES;
        self.pinch.enabled = YES;
        self.changeVideoBtn.selected = NO;
        self.videoBtn.hidden = YES;
        self.photoBtn.hidden = NO;
        [UIView animateWithDuration:0.25 animations:^{
            self.moveView.center = CGPointMake(self.moveView.center.x + self.moveView.frame.size.width / 2, self.moveView.center.y);
        } completion:^(BOOL finished) {
            
        }];
        [self.session beginConfiguration];
        [self.session removeOutput:self.videoOutPut];
        if ([self.session canAddOutput:self.imageOutput]) {
            [self.session addOutput:self.imageOutput];
        }
        [self.session commitConfiguration];
    }else {
        self.progressView.hidden = NO;
        self.pinch.enabled = NO;
        self.videoBtn.hidden = NO;
        self.photoBtn.hidden = YES;
        [UIView animateWithDuration:0.25 animations:^{
            self.moveView.center = CGPointMake(self.moveView.center.x - self.moveView.frame.size.width / 2, self.moveView.center.y);
        }];
        self.changePhotoBtn.selected = NO;
        [self.session beginConfiguration];
        [self.session removeOutput:self.imageOutput];
        if ([self.session canAddOutput:self.videoOutPut]) {
            self.effectiveScale = 1.0f;
            [self.previewLayer setAffineTransform:CGAffineTransformIdentity];
            [self.session addOutput:self.videoOutPut];
        }
        [self.session commitConfiguration];
    }
}

- (UIButton *)deleteBtn
{
    if (!_deleteBtn) {
        _deleteBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _deleteBtn.hidden = YES;
        [_deleteBtn setImage:[UIImage imageNamed:@"video_delete_dustbin@2x.png"] forState:UIControlStateNormal];
        [_deleteBtn addTarget:self action:@selector(deleteClick) forControlEvents:UIControlEventTouchUpInside];
        _deleteBtn.frame = CGRectMake(30, 0, _deleteBtn.currentImage.size.width, _deleteBtn.currentImage.size.height);
        _deleteBtn.center = CGPointMake(_deleteBtn.center.x, self.videoBtn.center.y);
    }
    return _deleteBtn;
}

- (void)deleteClick
{
    self.nextBtn.hidden = YES;
    self.deleteBtn.hidden = YES;
    self.imageView.hidden = YES;
    if (self.changePhotoBtn.selected) {
        self.videoBtn.hidden = YES;
        self.photoBtn.hidden = NO;
    }else {
        self.videoBtn.hidden = NO;
        self.photoBtn.hidden = YES;
    }
    self.progressView.progress = 0;
    self.videoTime = 0;
    [self showClick];
    [[self.playerLayer player] pause];
    self.playerLayer.hidden = YES;
}

- (void)showClick
{
    self.deleteBtn.hidden = YES;
    self.nextBtn.hidden = YES;
    self.rightOne.enabled = YES;
    self.leftSwipe.enabled = YES;
    self.rightSwipe.enabled = YES;
    self.moveView.userInteractionEnabled = YES;
}

- (UIButton *)nextBtn
{
    if (!_nextBtn) {
        _nextBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _nextBtn.hidden = YES;
        [_nextBtn setImage:[UIImage imageNamed:@"video_next_button@2x.png"] forState:UIControlStateNormal];
        [_nextBtn setImage:[UIImage imageNamed:@"video_next_button_highlighted@2x.png"] forState:UIControlStateHighlighted];
        [_nextBtn addTarget:self action:@selector(nextClick) forControlEvents:UIControlEventTouchUpInside];
        CGFloat width = self.view.frame.size.width;
        _nextBtn.frame = CGRectMake(width - 30 - _nextBtn.currentImage.size.width, 0, _nextBtn.currentImage.size.width, _nextBtn.currentImage.size.height);
        _nextBtn.center = CGPointMake(_nextBtn.center.x, self.videoBtn.center.y);
    }
    return _nextBtn;
}

- (void)nextClick
{
    HXPhotoModel *model = [[HXPhotoModel alloc] init];
    if (self.changePhotoBtn.selected) {
        model.type = HXPhotoModelMediaTypeCameraPhoto;
        if (self.imageView.image.imageOrientation != UIImageOrientationUp) {
            self.imageView.image = [self.imageView.image normalizedImage];
        }
        UIImage *image;
        if (self.effectiveScale > 1) {
            image = [self.imageView.image scaleImagetoScale:self.effectiveScale];
        }else {
            image = self.imageView.image;
        }
        image = [image clipImage:self.effectiveScale];
        model.thumbPhoto = image;
        model.imageSize = image.size;
        model.previewPhoto = image;
        
        model.cameraIdentifier = [self videoOutFutFileName];
        if ([self.delegate respondsToSelector:@selector(cameraDidNextClick:)]) {
            [self.delegate cameraDidNextClick:model];
        }
        [self dismiss];
    }else {
        [self.timer invalidate];
        self.timer = nil;
        if (self.videoTime < 3) {
            [self.view showImageHUDText:@"录制时间不能少于3秒"];
            return;
        }
        [self.playerLayer.player pause];
        __weak typeof(self) weakSelf = self;
        [self.view showLoadingHUDText:@"处理中"];
        self.view.userInteractionEnabled = NO;
        [self clipVideoCompleted:^{
            weakSelf.view.userInteractionEnabled = YES;
            model.type = HXPhotoModelMediaTypeCameraVideo;
            MPMoviePlayerController *player = [[MPMoviePlayerController alloc]initWithContentURL:weakSelf.videoURL] ;
            player.shouldAutoplay = NO;
            UIImage  *image = [player thumbnailImageAtTime:1.0 timeOption:MPMovieTimeOptionNearestKeyFrame];
            NSString *videoTime = [HXPhotoTools getNewTimeFromDurationSecond:weakSelf.videoTime];
            model.videoURL = weakSelf.clipVideoURL;
            model.videoTime = videoTime;
            model.thumbPhoto = image;
            model.imageSize = [image clipImage:self.effectiveScale].size;
            model.previewPhoto = image;
            model.cameraIdentifier = [weakSelf videoOutFutFileName];
            [weakSelf.view handleLoading];
            if ([weakSelf.delegate respondsToSelector:@selector(cameraDidNextClick:)]) {
                [weakSelf.delegate cameraDidNextClick:model];
            }
            [weakSelf dismiss];
        } failed:^{
            weakSelf.view.userInteractionEnabled = YES;
            [weakSelf.view handleLoading];
            [weakSelf.view showImageHUDText:@"处理失败,请重试!"];
        }];
        
    }
}

- (void)clipVideoCompleted:(void(^)())completed failed:(void(^)())failed
{
    AVAsset *asset = [AVAsset assetWithURL:self.videoURL];
    
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    
    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
    NSError *error = nil;
    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                        ofTrack:[[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
                         atTime:kCMTimeZero
                          error:&error];
    
    // 3.1 AVMutableVideoCompositionInstruction 视频轨道中的一个视频，可以缩放、旋转等
    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
    
    AVMutableVideoCompositionLayerInstruction *videolayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    AVAssetTrack *videoAssetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    UIImageOrientation videoAssetOrientation_  = UIImageOrientationUp;
    BOOL isVideoAssetPortrait_  = NO;
    CGAffineTransform videoTransform = videoAssetTrack.preferredTransform;
    if (videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0) {
        videoAssetOrientation_ = UIImageOrientationRight;
        isVideoAssetPortrait_ = YES;
    }
    if (videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0) {
        videoAssetOrientation_ =  UIImageOrientationLeft;
        isVideoAssetPortrait_ = YES;
    }
    if (videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0) {
        videoAssetOrientation_ =  UIImageOrientationUp;
    }
    if (videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0) {
        videoAssetOrientation_ = UIImageOrientationDown;
    }
    CGFloat videoWidth = videoAssetTrack.naturalSize.width;
    CGFloat videoHeight = videoAssetTrack.naturalSize.height;
    CGAffineTransform t1;
    CGAffineTransform t2;
    if(isVideoAssetPortrait_){
        if (videoAssetOrientation_ == UIImageOrientationRight) {
            t1 = CGAffineTransformTranslate(videoTransform, -(videoWidth / 2 - videoHeight / 2), 0);
            [videolayerInstruction setTransform:t1 atTime:kCMTimeZero];
        }else if (videoAssetOrientation_ == UIImageOrientationLeft) {
            t1 = CGAffineTransformScale(videoTransform, 1, 1);
            t2 = CGAffineTransformTranslate(t1, -(videoWidth / 2 - videoHeight - videoHeight / 4), 0);
            [videolayerInstruction setTransform:t2 atTime:kCMTimeZero];
        }
    } else {
        if (videoAssetOrientation_ == UIImageOrientationUp) {
            t1 = CGAffineTransformScale(videoTransform, 1.77778, 1.77778);
            t2 = CGAffineTransformTranslate(t1, videoHeight / 2 - videoWidth / 2, 0);
            [videolayerInstruction setTransform:t2 atTime:kCMTimeZero];
        }else {
            t1 = CGAffineTransformScale(videoTransform, 1.77778, 1.77778);
            t2 = CGAffineTransformTranslate(t1, videoHeight / 2 - videoWidth / 2, -(videoHeight / 16 * 7));
            [videolayerInstruction setTransform:t2 atTime:kCMTimeZero];
        }
    }
    [videolayerInstruction setOpacity:0.0 atTime:asset.duration];

    mainInstruction.layerInstructions = [NSArray arrayWithObjects:videolayerInstruction,nil];

    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
    
    CGSize naturalSize;
    if(isVideoAssetPortrait_){
        naturalSize = CGSizeMake(videoAssetTrack.naturalSize.height, videoAssetTrack.naturalSize.width);
    } else {
        naturalSize = videoAssetTrack.naturalSize;
    }
    
    float renderWidth, renderHeight;
    renderWidth = naturalSize.width;
    renderHeight = naturalSize.height;
    mainCompositionInst.renderSize = CGSizeMake(renderWidth, renderWidth);
    mainCompositionInst.instructions = [NSArray arrayWithObject:mainInstruction];
    mainCompositionInst.frameDuration = CMTimeMake(1, 30);
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *myPathDocs =  [documentsDirectory stringByAppendingPathComponent:
                             [NSString stringWithFormat:@"FinalVideo-%d.mov",arc4random() % 1000]];
    self.clipVideoURL = [NSURL fileURLWithPath:myPathDocs];
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition
                                                                      presetName:AVAssetExportPresetHighestQuality];
    exporter.outputURL = self.clipVideoURL;
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    exporter.shouldOptimizeForNetworkUse = YES;
    exporter.videoComposition = mainCompositionInst;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        switch (exporter.status) {
            case AVAssetExportSessionStatusUnknown:
                break;
            case AVAssetExportSessionStatusWaiting:
                break;
            case AVAssetExportSessionStatusExporting:
                break;
            case AVAssetExportSessionStatusCompleted:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completed) {
                        completed();
                    }
                });
            }
                break;
            case AVAssetExportSessionStatusFailed:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (failed) {
                        failed();
                    }
                });
            }
                break;
            case AVAssetExportSessionStatusCancelled:
                break;
            default:
                break;
        }
    }];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source{
    return [HXVideoPresentTransition transitionWithTransitionType:HXVideoPresentTransitionPresent];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed{
    return [HXVideoPresentTransition transitionWithTransitionType:HXVideoPresentTransitionDismiss];
}

@end
