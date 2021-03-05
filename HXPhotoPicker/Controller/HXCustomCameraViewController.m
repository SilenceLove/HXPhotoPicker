//
//  HXCustomCameraViewController.m
//  HXPhotoPickerExample
//
//  Created by Silence on 2017/9/30.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import "HXCustomCameraViewController.h"
#import "HXCustomCameraController.h"
#import "HXCustomPreviewView.h"
#import "HXPhotoTools.h"
#import "HXPhotoManager.h"
#import <MediaPlayer/MediaPlayer.h>
#import "UIImage+HXExtension.h"
#import "HXPhotoCustomNavigationBar.h"
#import "UIViewController+HXExtension.h"
#import "HXCameraBottomView.h"
#import "HX_PhotoEditViewController.h"
#import "HXCustomNavigationController.h"
#import <CoreLocation/CoreLocation.h>

@interface HXCustomCameraViewController ()
<HXCustomPreviewViewDelegate ,
HXCustomCameraControllerDelegate ,
CLLocationManagerDelegate
>
@property (strong, nonatomic) HXCustomCameraController *cameraController;
@property (strong, nonatomic) HXCustomPreviewView *previewView;
@property (strong, nonatomic) UIImageView *previewImageView;
@property (strong, nonatomic) CAGradientLayer *topMaskLayer;
@property (strong, nonatomic) UIView *topView;
@property (strong, nonatomic) UIButton *cancelBtn;
@property (strong, nonatomic) UIButton *changeCameraBtn;
@property (strong, nonatomic) HXCameraBottomView *bottomView;
@property (strong, nonatomic) NSTimer *timer;
@property (assign, nonatomic) NSUInteger time;
@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) HXCustomCameraPlayVideoView *playVideoView;
@property (strong, nonatomic) UIButton *doneBtn;
@property (strong, nonatomic) UIButton *videoCropBtn;
@property (assign, nonatomic) BOOL addAudioInputComplete;
@property (strong, nonatomic) NSURL *videoURL;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *location;
@property (strong, nonatomic) UIVisualEffectView *effectView;
@property (strong, nonatomic) UINavigationBar *customNavigationBar;
@property (strong, nonatomic) UINavigationItem *navItem;

@property (assign, nonatomic) CGFloat currentZoomFacto;
@property (strong, nonatomic) UIView *bottomToolsView;
@property (strong, nonatomic) CAGradientLayer *bottomMaskLayer;
@end

@implementation HXCustomCameraViewController
- (UIImage *)jumpImage {
    if (self.videoURL) {
        return [UIImage hx_thumbnailImageForVideo:self.videoURL atTime:0.1];
    }
    return self.imageView.image;
}
- (CGRect)jumpRect {
    if (self.videoURL) {
        CGFloat width = self.playVideoView.playerLayer.videoRect.size.width;
        CGFloat height = self.playVideoView.playerLayer.videoRect.size.height;
        return CGRectMake(0, (self.view.hx_h - height) / 2, width, height);
    }
    return self.imageView.frame;
}
- (void)showPlayerView{
    self.playVideoView.hidden = NO;
    self.previewView.hidden = NO;
}
- (void)hidePlayerView {
    self.playVideoView.hidden = YES;
    self.previewView.hidden = YES;
}

- (void)hiddenTopBottomView {
    self.customNavigationBar.alpha = 0;
    self.topView.alpha = 0;
    self.videoCropBtn.alpha = 0;
    self.doneBtn.alpha = 0;
}
- (void)showTopBottomView {
    [UIView animateWithDuration:0.2 animations:^{
        self.customNavigationBar.alpha = 1;
        self.topView.alpha = 1;
        self.videoCropBtn.alpha = 1;
        self.doneBtn.alpha = 1;
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.edgesForExtendedLayout = UIRectEdgeAll;
//    if (self.manager.configuration.saveSystemAblum && !self.manager.albums &&
//        !self.manager.onlyCamera) {
//        dispatch_async(self.manager.loadAssetQueue, ^{
//            [self.manager getAllAlbumModelFilter:NO select:nil completion:nil];
//        });
//    }
    self.view.backgroundColor = [UIColor blackColor];
    if (self.manager.configuration.cameraCanLocation && HX_ALLOW_LOCATION) {
        if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusDenied) {
            [self.locationManager startUpdatingLocation];
        }
    }
    if (self.manager.configuration.videoMaximumDuration > self.manager.configuration.videoMaximumSelectDuration) {
        self.manager.configuration.videoMaximumDuration = self.manager.configuration.videoMaximumSelectDuration;
    }else if (self.manager.configuration.videoMaximumDuration < 3.f) {
        self.manager.configuration.videoMaximumDuration = 4.f;
    }
    self.previewView.themeColor = self.manager.configuration.cameraFocusBoxColor;
    [self.view addSubview:self.previewView];
    self.cameraController = [[HXCustomCameraController alloc] init];
    self.cameraController.defaultFrontCamera = self.manager.configuration.defaultFrontCamera;
    self.cameraController.sessionPreset = self.manager.configuration.sessionPreset;
    self.cameraController.videoCodecKey = self.manager.configuration.videoCodecKey;
    self.cameraController.delegate = self;
    NSData *imageData = [NSData dataWithContentsOfURL:[HXPhotoCommon photoCommon].cameraImageURL];
    if (imageData) {
        UIImage *image = [UIImage imageWithData:imageData scale:1];
        if (image) {
            self.previewImageView.image = image;
            [self.previewView addSubview:self.previewImageView];
            [self.previewView addSubview:self.effectView];
        }
    }
    
    self.bottomView.userInteractionEnabled = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.cameraController initSeesion];
        self.previewView.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.cameraController.captureSession];
        HXWeakSelf
        [self.cameraController.captureSession beginConfiguration];
        [self.cameraController setupPreviewLayer:self.previewView.previewLayer startSessionCompletion:^(BOOL success) {
            if (success) {
                [weakSelf addOutputs];
                [weakSelf.cameraController.captureSession commitConfiguration];
                [weakSelf.cameraController.captureSession startRunning];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.previewView setupPreviewLayer];
                    weakSelf.previewView.delegate = weakSelf;
                    [weakSelf setupCamera];
                });

            }
        }];
    });
    
    [self.view addSubview:self.bottomView];
    [self.view addSubview:self.topView];
    [self.view addSubview:self.bottomToolsView];
    
    [self changeSubviewFrame];
    
    [self.view addSubview:self.customNavigationBar];
    
    if (self.manager.configuration.navigationBar) {
        self.manager.configuration.navigationBar(self.customNavigationBar, self);
    }
    self.customNavigationBar.translucent = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationBecomeActive) name:UIApplicationWillEnterForegroundNotification object:nil];

}
- (void)applicationBecomeActive {
    if (self.addAudioInputComplete) {
        [self.cameraController initMovieOutput];
    }
}
- (void)setupImageOutput {
    [self.cameraController initImageOutput];
    self.cameraController.flashMode = AVCaptureFlashModeAuto;
}
- (void)setupMovieOutput {
    [self.cameraController addAudioInput];
    self.addAudioInputComplete = YES;
    [self.cameraController initMovieOutput];
    self.cameraController.torchMode = 0;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self requestAccessForAudio];
        [self.view insertSubview:self.playVideoView belowSubview:self.bottomView];
    });
}
- (void)setupImageAndMovieOutput {
    [self setupImageOutput];
    [self setupMovieOutput];
}
- (void)addOutputs {
    switch (self.manager.configuration.customCameraType) {
        case HXPhotoCustomCameraTypeUnused: {
            if (self.manager.type == HXPhotoManagerSelectedTypePhoto) {
                [self setupImageOutput];
//                [self.cameraController addDataOutput];
            }else if (self.manager.type == HXPhotoManagerSelectedTypeVideo) {
                [self setupMovieOutput];
            }else {
                if (!self.manager.configuration.selectTogether && self.isOutside) {
                    if (self.manager.afterSelectedPhotoArray.count > 0) {
                        [self setupImageOutput];
//                        [self.cameraController addDataOutput];
                    }else if (self.manager.afterSelectedVideoArray.count > 0) {
                        [self setupMovieOutput];
                    }else {
                        [self setupImageAndMovieOutput];
                    }
                }else {
                    [self setupImageAndMovieOutput];
                }
            }
        } break;
        case HXPhotoCustomCameraTypePhoto: {
            [self setupImageOutput];
//            [self.cameraController addDataOutput];
        } break;
        case HXPhotoCustomCameraTypeVideo: {
            [self setupMovieOutput];
        } break;
        case HXPhotoCustomCameraTypePhotoAndVideo: {
            [self setupImageAndMovieOutput];
        } break;
        default:
            break;
    }
}
- (void)setupCamera {
    self.bottomView.userInteractionEnabled = YES;
    if (_previewImageView) {
        [UIView animateWithDuration:0.25 animations:^{
            self.previewImageView.alpha = 0;
            if (HX_IOS9Later) {
                [self.effectView setEffect:nil];
            }else {
                self.effectView.alpha = 0;
            }
        } completion:^(BOOL finished) {
            [self.effectView removeFromSuperview];
            [self.previewImageView removeFromSuperview];
            [self.previewView firstFocusing];
        }];
    }else {
        [self.previewView firstFocusing];
    }
    
    self.previewView.tapToFocusEnabled = self.cameraController.cameraSupportsTapToFocus;
    self.previewView.tapToExposeEnabled = self.cameraController.cameraSupportsTapToExpose;
    
    UIBarButtonItem *rightBtn1 = [[UIBarButtonItem alloc] initWithCustomView:self.changeCameraBtn];
    if ([self.cameraController canSwitchCameras] && [self.cameraController cameraHasFlash]) {
        self.navItem.rightBarButtonItems = @[rightBtn1];
    }
    
    self.previewView.maxScale = [self.cameraController maxZoomFactor];
    [self resetCameraZoom];
    self.cameraController.flashMode = AVCaptureFlashModeAuto;
    [self setupFlashAndTorchBtn];
    self.previewView.tapToExposeEnabled = self.cameraController.cameraSupportsTapToExpose;
    self.previewView.tapToFocusEnabled = self.cameraController.cameraSupportsTapToFocus;
}
- (void)requestAccessForAudio {
    HXWeakSelf
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (granted) {
                if (!weakSelf.addAudioInputComplete) {
                    [weakSelf.cameraController addAudioInput];
                    weakSelf.addAudioInputComplete = YES;
                }
            }else {
                hx_showAlert(weakSelf, [NSBundle hx_localizedStringForKey:@"无法使用麦克风"], [NSBundle hx_localizedStringForKey:@"请在设置-隐私-相机中允许访问麦克风"], [NSBundle hx_localizedStringForKey:@"取消"], [NSBundle hx_localizedStringForKey:@"设置"], ^{
                    [weakSelf.view hx_showImageHUDText:[NSBundle hx_localizedStringForKey:@"麦克风添加失败，录制视频会没有声音哦!"]];
                }, ^{
                    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                    if (@available(iOS 10.0, *)) {
                        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
                    }else {
                        [[UIApplication sharedApplication] openURL:url];
                    }
                }); 
            }
        });
    }];
}
- (void)setupFlashAndTorchBtn {
    self.previewView.pinchToZoomEnabled = [self.cameraController cameraSupportsZoom];
}
- (void)changeSubviewFrame {
    self.customNavigationBar.frame = CGRectMake(0, self.previewView.hx_y, self.view.hx_w, hxNavigationBarHeight);
    if (!HX_IS_IPhoneX_All && HX_IOS11_Later) {
        self.customNavigationBar.hx_y = self.previewView.hx_y + 10;
        self.topView.frame = self.customNavigationBar.frame;
        self.topView.hx_y = -10;
    }else if (HX_IS_IPhoneX_All) {
        self.customNavigationBar.hx_y = self.previewView.hx_y - 40;
        self.topView.frame = self.customNavigationBar.frame;
    }
    self.topMaskLayer.frame = self.topView.bounds;
    if (HX_IS_IPhoneX_All) {
        self.bottomView.frame = CGRectMake(0, self.view.hx_h - 100 - self.previewView.hx_y, self.view.hx_w, 130);
    }else {
        self.bottomView.frame = CGRectMake(0, self.view.hx_h - 130 - self.previewView.hx_y, self.view.hx_w, 130);
    }
}
- (BOOL)prefersStatusBarHidden {
    return YES;
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
    [self.customNavigationBar setBackgroundColor:[UIColor clearColor]];
    [self.customNavigationBar setShadowImage:[[UIImage alloc] init]];
    [self.customNavigationBar setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
    [self.customNavigationBar setTintColor:[UIColor whiteColor]];
    [self.customNavigationBar setBarTintColor:nil];
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
#pragma clang diagnostic pop
    AVCaptureConnection *previewLayerConnection = [(AVCaptureVideoPreviewLayer *)self.previewView.previewLayer connection];
    if ([previewLayerConnection isVideoOrientationSupported])
        [previewLayerConnection setVideoOrientation:(AVCaptureVideoOrientation)[[UIApplication sharedApplication] statusBarOrientation]];
    
    [self preferredStatusBarUpdateAnimation];
    if (self.manager.viewWillAppear) {
        self.manager.viewWillAppear(self);
    }
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
#pragma clang diagnostic pop
    [self.cameraController stopMontionUpdate];
    [self preferredStatusBarUpdateAnimation];
    if (self.manager.viewWillDisappear) {
        self.manager.viewWillDisappear(self);
    }
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
    [self.cameraController startMontionUpdate];
    if (self.manager.viewDidAppear) {
        self.manager.viewDidAppear(self);
    }
}
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self stopTimer];
    [self.cameraController stopSession];
    if (self.manager.viewDidDisappear) {
        self.manager.viewDidDisappear(self);
    }
} 
- (void)dealloc {
    if (HX_ALLOW_LOCATION && _locationManager) {
        [self.locationManager stopUpdatingLocation];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    if (HXShowLog) NSSLog(@"dealloc");
}
- (void)cancelClick:(UIButton *)button {
    if (button.selected) {
        self.videoURL = nil;
        [self setupFlashAndTorchBtn];
        self.bottomView.inTranscribe = NO;
        self.bottomView.inTakePictures = NO;
        [self.imageView removeFromSuperview];
        [self hideBottomToolsView];
        [self.playVideoView stopPlay];
        self.playVideoView.hidden = YES;
        self.playVideoView.playerLayer.hidden = YES;
        self.changeCameraBtn.hidden = NO;
        self.cancelBtn.selected = NO;
        self.cancelBtn.hx_w = 50;
        self.bottomView.hidden = NO;
        self.previewView.tapToFocusEnabled = YES;
    }
}
- (void)didDoneBtnClick {
    HXPhotoModel *cameraModel;
    if (!self.videoURL) {
        cameraModel = [HXPhotoModel photoModelWithImage:self.imageView.image];
    }else {
        if (self.time < self.manager.configuration.videoMinimumDuration) {
            [self.view hx_showImageHUDText:[NSString stringWithFormat:[NSBundle hx_localizedStringForKey:@"录制时间少于%0.f秒"], self.manager.configuration.videoMinimumDuration]];
            return;
        }
        [self.playVideoView stopPlay];
        cameraModel = [HXPhotoModel photoModelWithVideoURL:self.videoURL videoTime:self.time];
    }
    cameraModel.creationDate = [NSDate date];
    cameraModel.location = self.location;
    HXWeakSelf
    if (!self.manager.configuration.saveSystemAblum) {
        if (cameraModel.subType == HXPhotoModelMediaSubTypePhoto) {
            if (self.manager.configuration.cameraPhotoJumpEdit && !self.manager.configuration.useWxPhotoEdit) {
                [self hx_presentPhotoEditViewControllerWithManager:self.manager photoModel:cameraModel delegate:nil done:^(HXPhotoModel *beforeModel, HXPhotoModel *afterModel, HXPhotoEditViewController *viewController) {
                    [weakSelf doneCompleteWithModel:afterModel];
                } cancel:^(HXPhotoEditViewController *viewController) {
                    [weakSelf cancelClick:weakSelf.cancelBtn];
                }];
            }else {
                [self doneCompleteWithModel:cameraModel];
            }
        }else if (cameraModel.subType == HXPhotoModelMediaSubTypeVideo) {
            [self doneCompleteWithModel:cameraModel];
        }
    }else {
        if (self.manager.configuration.editAssetSaveSystemAblum) {
            if (cameraModel.subType == HXPhotoModelMediaSubTypePhoto) {
                if (self.manager.configuration.cameraPhotoJumpEdit && !self.manager.configuration.useWxPhotoEdit) {
                    [self hx_presentPhotoEditViewControllerWithManager:self.manager photoModel:cameraModel delegate:nil done:^(HXPhotoModel *beforeModel, HXPhotoModel *afterModel, HXPhotoEditViewController *viewController) {
                        [weakSelf doneCompleteWithModel:afterModel];
                    } cancel:^(HXPhotoEditViewController *viewController) {
                        [weakSelf cancelClick:weakSelf.cancelBtn];
                    }];
                }else {
                    [self doneCompleteWithModel:cameraModel];
                }
            }else if (cameraModel.subType == HXPhotoModelMediaSubTypeVideo) {
                [self doneCompleteWithModel:cameraModel];
            }
        }else {
            [self.view hx_immediatelyShowLoadingHudWithText:nil];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                id location = self.location;
                if (!self.videoURL) {
                    [HXPhotoTools savePhotoToCustomAlbumWithName:self.manager.configuration.customAlbumName photo:self.imageView.image location:location complete:^(HXPhotoModel *model, BOOL success) {
                        if (success) {
                            if (weakSelf.manager.configuration.cameraPhotoJumpEdit) {
                                [weakSelf hx_presentPhotoEditViewControllerWithManager:weakSelf.manager photoModel:cameraModel delegate:nil done:^(HXPhotoModel *beforeModel, HXPhotoModel *afterModel, HXPhotoEditViewController *viewController) {
                                    [weakSelf doneCompleteWithModel:afterModel];
                                } cancel:^(HXPhotoEditViewController *viewController) {
                                    [weakSelf cancelClick:weakSelf.cancelBtn];
                                }];
                            }else {
                                [weakSelf doneCompleteWithModel:model];
                            }
                            [weakSelf.view hx_handleLoading:NO];
                        }else {
                            [weakSelf.view hx_showImageHUDText:@"保存失败!"];
                        }
                    }];
                }else {
                    [HXPhotoTools saveVideoToCustomAlbumWithName:self.manager.configuration.customAlbumName videoURL:self.videoURL location:location complete:^(HXPhotoModel *model, BOOL success) {
                        [weakSelf.view hx_handleLoading:NO];
                        if (success) {
                            model.videoURL = weakSelf.videoURL;
                            [weakSelf doneCompleteWithModel:model];
                        }else {
                            [weakSelf.view hx_showImageHUDText:@"保存失败!"];
                        }
                    }];
                }
            });
        }
    }
}
- (void)doneCompleteWithModel:(HXPhotoModel *)model {
    [[HXPhotoCommon photoCommon] saveCamerImage];
    [self stopTimer];
    [self.cameraController stopMontionUpdate];
    [self.cameraController stopSession];
    self.cameraController.flashMode = 0;
    self.cameraController.torchMode = 0;
    if ([self.delegate respondsToSelector:@selector(customCameraViewController:didDone:)]) {
        [self.delegate customCameraViewController:self didDone:model];
    }
    if (self.doneBlock) {
        self.doneBlock(model, self);
    }
    BOOL cameraFinishDismissAnimated = self.manager.cameraFinishDismissAnimated;
    if (self.manager.configuration.cameraPhotoJumpEdit) {
        [self.presentingViewController dismissViewControllerAnimated:cameraFinishDismissAnimated completion:^{
            if ([self.delegate respondsToSelector:@selector(customCameraViewControllerFinishDismissCompletion:)]) {
                [self.delegate customCameraViewControllerFinishDismissCompletion:self];
            }
        }];
    }else {
        [self dismissViewControllerAnimated:cameraFinishDismissAnimated completion:^{
            if ([self.delegate respondsToSelector:@selector(customCameraViewControllerFinishDismissCompletion:)]) {
                [self.delegate customCameraViewControllerFinishDismissCompletion:self];
            }
        }];
    }
}
- (void)resetCameraZoom {
    self.previewView.maxScale = [self.cameraController maxZoomFactor];
    if ([self.cameraController cameraSupportsZoom]) {
        self.previewView.effectiveScale = 1.0f;
        self.previewView.beginGestureScale = 1.0f;
        [self.cameraController rampZoomToValue:1.0f];
        [self.cameraController cancelZoom];
    }
}
- (void)didchangeCameraClick {
    if ([self.cameraController switchCameras]) {
        [self resetCameraZoom];
        [self setupFlashAndTorchBtn];
        self.previewView.tapToExposeEnabled = self.cameraController.cameraSupportsTapToExpose;
        self.previewView.tapToFocusEnabled = self.cameraController.cameraSupportsTapToFocus;
        [self.cameraController resetFocusAndExposureModes];
    }
}
- (void)handleDeviceMotion:(UIDeviceOrientation)deviceOrientation {
    if (deviceOrientation == UIDeviceOrientationLandscapeLeft) {
        [UIView animateWithDuration:0.2 animations:^{
            self.changeCameraBtn.transform = CGAffineTransformMakeRotation(M_PI / 2);
        }];
    }else if (deviceOrientation == UIDeviceOrientationLandscapeRight) {
        [UIView animateWithDuration:0.2 animations:^{
            self.changeCameraBtn.transform = CGAffineTransformMakeRotation(-M_PI / 2);
        }];
    }else {
        [UIView animateWithDuration:0.2 animations:^{
            self.changeCameraBtn.transform = CGAffineTransformIdentity;
        }];
    }
}
- (void)takePicturesComplete:(UIImage *)image {
    [self needHideViews];
    self.imageView.image = image;
    [HXPhotoCommon photoCommon].cameraImage = [image hx_normalizedImage];
    [self.view insertSubview:self.imageView belowSubview:self.bottomView];
//    [self.cameraController stopSession];
    if (self.manager.configuration.useWxPhotoEdit &&
        self.manager.configuration.cameraPhotoJumpEdit) {
        self.topView.hidden = YES;
        HXWeakSelf
        HXPhotoModel *model = [HXPhotoModel photoModelWithImage:image];
        model.creationDate = [NSDate date];
        HX_PhotoEditViewController *vc = [[HX_PhotoEditViewController alloc] initWithConfiguration:self.manager.configuration.photoEditConfigur];
        vc.saveAlbum = self.manager.configuration.saveSystemAblum;
        vc.photoModel = model;
        vc.albumName = self.manager.configuration.customAlbumName;
        vc.location = self.location;
        vc.finishBlock = ^(HXPhotoEdit * _Nullable photoEdit, HXPhotoModel * _Nonnull photoModel, HX_PhotoEditViewController * _Nonnull viewController) {
            if (photoModel.photoEdit) {
                photoModel = [HXPhotoModel photoModelWithImage:photoModel.photoEdit.editPreviewImage];
            }
            [weakSelf doneCompleteWithModel:photoModel];
        };
        vc.cancelBlock = ^(HX_PhotoEditViewController * _Nonnull viewController) {
            weakSelf.topView.hidden = NO;
            [weakSelf.cameraController startSession];
            [weakSelf cancelClick:weakSelf.cancelBtn];
        };
        vc.supportRotation = NO;
        vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
        vc.modalPresentationCapturesStatusBarAppearance = YES;
        [self presentViewController:vc animated:YES completion:nil];
    }else {
        self.videoCropBtn.hidden = YES;
        [self showBottomToolsView];
        self.cancelBtn.hidden = NO;
    }
}
- (void)takePicturesFailed {
    self.cancelBtn.hidden = NO;
    self.changeCameraBtn.hidden = NO;
    self.cancelBtn.selected = NO;
    self.cancelBtn.hx_w = 50;
    self.bottomView.hidden = NO;
    self.previewView.tapToFocusEnabled = YES;
    self.previewView.pinchToZoomEnabled = [self.cameraController cameraSupportsZoom];
    [self.view hx_showImageHUDText:[NSBundle hx_localizedStringForKey:@"拍摄失败"]];
}
- (void)startTimer {
    self.time = 0;
    [self.timer invalidate];
    self.timer = [NSTimer timerWithTimeInterval:0.2f
                                         target:self
                                       selector:@selector(updateTimeDisplay)
                                       userInfo:nil
                                        repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)updateTimeDisplay {
    CMTime duration = self.cameraController.recordedDuration;
    NSTimeInterval time = CMTimeGetSeconds(duration);
    self.time = (NSInteger)time;
    if (time + 0.4f >= self.manager.configuration.videoMaximumDuration) {
        [self.bottomView videoRecordEnd];
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
    self.cancelBtn.hx_w = [self.cancelBtn.titleLabel hx_getTextWidth] + 10;
    self.changeCameraBtn.hidden = YES;
}
- (void)videoFinishRecording:(NSURL *)videoURL {
    [self.bottomView stopRecord];
    if (self.time < self.manager.configuration.videoMinimumDuration) {
        self.bottomView.hidden = NO;
        self.cancelBtn.selected = NO;
        self.cancelBtn.hx_w = 50;
        self.changeCameraBtn.hidden = NO;
        [self.view hx_showImageHUDText:[NSString stringWithFormat:[NSBundle hx_localizedStringForKey:@"%.0f秒内的视频无效哦~"], self.manager.configuration.videoMinimumDuration]];
    }else {
        [HXPhotoCommon photoCommon].cameraImage = [[UIImage hx_thumbnailImageForVideo:videoURL atTime:0.1f] hx_normalizedImage];
//        [self.cameraController stopSession];
        self.previewView.tapToFocusEnabled = NO;
        self.previewView.pinchToZoomEnabled = NO;
        self.bottomView.hidden = YES;
        self.videoURL = [videoURL copy];
        self.playVideoView.hidden = NO;
        self.playVideoView.playerLayer.hidden = NO;
        self.playVideoView.videoURL = self.videoURL;
        [self showBottomToolsView];
        
        self.previewView.effectiveScale = 1.0f;
        self.previewView.beginGestureScale = 1.0f;
        [self.cameraController setZoomValue:1.0f];
        self.currentZoomFacto = self.cameraController.currentZoomFacto;
    }
    self.cancelBtn.hidden = NO;
}
- (void)mediaCaptureFailedWithError:(NSError *)error {
    self.time = 0;
    [self stopTimer];
    [self.bottomView stopRecord];
    [self.view hx_showImageHUDText:[NSBundle hx_localizedStringForKey:@"录制视频失败!"]];
    self.bottomView.hidden = NO;
    self.cancelBtn.selected = NO;
    self.cancelBtn.hx_w = 50;
    self.changeCameraBtn.hidden = NO;
    self.cancelBtn.hidden = NO;
}
- (void)bottomDidTakePictures {
    [self.cameraController captureStillImage];
    self.previewView.tapToFocusEnabled = NO;
    self.previewView.pinchToZoomEnabled = NO;
}
- (void)bottomDidTranscribe {
    if ([self.cameraController isRecording]) {
        [self.cameraController stopRecording];
        [self stopTimer];
    }else {
        if ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio] != AVAuthorizationStatusAuthorized) {
            [self.view hx_showImageHUDText:[NSBundle hx_localizedStringForKey:@"麦克风添加失败，录制视频会没有声音哦!"]];
        }
        [self videoNeedHideViews];
        [self playViewAnimateCompletion];
    }
}
- (void)needHideViews {
    self.cancelBtn.selected = YES;
    self.cancelBtn.hx_w = [self.cancelBtn.titleLabel hx_getTextWidth] + 10;
    self.changeCameraBtn.hidden = YES;
    self.bottomView.hidden = YES;
    self.cancelBtn.hidden = YES;
}
- (void)playViewAnimateCompletion {
    if (self.bottomView.inTranscribe) {
        dispatch_async(dispatch_queue_create("com.hxdatephotopicker.kamera", NULL), ^{
            [self.cameraController startRecording];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self startTimer];
            });
        });
    }
}
- (void)tappedToFocusAtPoint:(CGPoint)point {
    [self.cameraController focusAtPoint:point];
    [self.cameraController exposeAtPoint:point];
}
- (void)pinchGestureScale:(CGFloat)scale {
    [self.cameraController setZoomValue:scale];
}
- (UINavigationBar *)customNavigationBar {
    if (!_customNavigationBar) {
        _customNavigationBar = [[UINavigationBar alloc] init];
        _customNavigationBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [_customNavigationBar pushNavigationItem:self.navItem animated:NO];
    }
    return _customNavigationBar;
}
- (UINavigationItem *)navItem {
    if (!_navItem) {
        _navItem = [[UINavigationItem alloc] init];
        _navItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.cancelBtn];
    }
    return _navItem;
}
- (HXCustomPreviewView *)previewView {
    if (!_previewView) {
        _previewView = [[HXCustomPreviewView alloc] init];
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            _previewView.frame = self.view.bounds;
        }else {
            _previewView.hx_size = CGSizeMake(self.view.hx_w, self.view.hx_w / 9 * 16);
            _previewView.center = CGPointMake(self.view.hx_w / 2, self.view.hx_h / 2);
        }
    }
    return _previewView;
}
- (UIImageView *)previewImageView {
    if (!_previewImageView) {
        _previewImageView = [[UIImageView alloc] init];
        _previewImageView.frame = self.previewView.bounds;
        _previewImageView.contentMode = UIViewContentModeScaleAspectFill;
        _previewImageView.clipsToBounds = YES;
    }
    return _previewImageView;
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
        [_changeCameraBtn setImage:[UIImage hx_imageNamed:@"hx_camera_overturn"] forState:UIControlStateNormal];
        [_changeCameraBtn addTarget:self action:@selector(didchangeCameraClick) forControlEvents:UIControlEventTouchUpInside];
        _changeCameraBtn.hx_size = CGSizeMake(50, 50);
        _changeCameraBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        CGSize size = _changeCameraBtn.currentImage.size;
        _changeCameraBtn.layer.anchorPoint = CGPointMake(((50 - size.width) + size.width / 2) / 50, 0.5);
    }
    return _changeCameraBtn;
}
- (HXCameraBottomView *)bottomView {
    if (!_bottomView) {
        _bottomView = [HXCameraBottomView initView];
        _bottomView.isOutside = self.isOutside;
        _bottomView.manager = self.manager;
        HXWeakSelf
        _bottomView.takePictures = ^{
            weakSelf.imageView.image = nil;
            [weakSelf bottomDidTakePictures];
        };
        _bottomView.startTranscribe = ^{
            weakSelf.currentZoomFacto = weakSelf.cameraController.currentZoomFacto;
            [weakSelf bottomDidTranscribe];
        };
        _bottomView.changedTranscribe = ^(CGFloat margin) {
            CGFloat scale = margin / 50.f;
            scale += weakSelf.currentZoomFacto;
            weakSelf.previewView.effectiveScale = scale;
            weakSelf.previewView.beginGestureScale = scale;
            [weakSelf.cameraController setZoomValue:scale];
        };
        _bottomView.endTranscribe = ^(BOOL isAnimation) {
            if (![weakSelf.cameraController isRecording]) {
                [weakSelf stopTimer];
                weakSelf.cancelBtn.selected = NO;
                weakSelf.cancelBtn.hx_w = 50;
                weakSelf.changeCameraBtn.hidden = NO;
            }else {
                weakSelf.bottomView.hidden = YES;
                [weakSelf bottomDidTranscribe];
            }
        };;
        _bottomView.backClick = ^{
            [[HXPhotoCommon photoCommon] saveCamerImage];
            [weakSelf stopTimer];
            [weakSelf.cameraController stopMontionUpdate];
            [weakSelf.cameraController stopSession];
            if ([weakSelf.delegate respondsToSelector:@selector(customCameraViewControllerDidCancel:)]) {
                [weakSelf.delegate customCameraViewControllerDidCancel:weakSelf];
            }
            if (weakSelf.cancelBlock) {
                weakSelf.cancelBlock(weakSelf);
            }
            BOOL cameraCancelDismissAnimated = weakSelf.manager.cameraCancelDismissAnimated;
            [weakSelf dismissViewControllerAnimated:cameraCancelDismissAnimated completion:^{
                if ([weakSelf.delegate respondsToSelector:@selector(customCameraViewControllerCancelDismissCompletion:)]) {
                    [weakSelf.delegate customCameraViewControllerCancelDismissCompletion:weakSelf];
                }
            }];
        };
    }
    return _bottomView;
}
- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:self.previewView.frame];
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

- (CAGradientLayer *)bottomMaskLayer {
    if (!_bottomMaskLayer) {
        _bottomMaskLayer = [CAGradientLayer layer];
        _bottomMaskLayer.colors = @[
                                    (id)[[UIColor blackColor] colorWithAlphaComponent:0].CGColor,
                                    (id)[[UIColor blackColor] colorWithAlphaComponent:0.4].CGColor
                                    ];
        _bottomMaskLayer.startPoint = CGPointMake(0, 0);
        _bottomMaskLayer.endPoint = CGPointMake(0, 1);
        _bottomMaskLayer.locations = @[@(0),@(1.f)];
        _bottomMaskLayer.borderWidth  = 0.0;
    }
    return _bottomMaskLayer;
}
- (UIView *)bottomToolsView {
    if (!_bottomToolsView) {
        _bottomToolsView = [[UIView alloc] initWithFrame:CGRectMake(0, HX_ScreenHeight, HX_ScreenWidth, 50.f)];
        self.bottomMaskLayer.frame = _bottomToolsView.bounds;
        [_bottomToolsView.layer insertSublayer:self.bottomMaskLayer atIndex:0];
        _bottomToolsView.hidden = YES;
        _bottomToolsView.alpha = 0;
        [_bottomToolsView addSubview:self.doneBtn];
        [_bottomToolsView addSubview:self.videoCropBtn];
    }
    return _bottomToolsView;
}
- (void)showBottomToolsView {
    self.bottomToolsView.hidden = NO;
    [UIView animateWithDuration:0.2 animations:^{
        self.bottomToolsView.alpha = 1;
        self.bottomToolsView.hx_y = HX_ScreenHeight - 50.f -  hxBottomMargin;
    }];
}
- (void)hideBottomToolsView {
    self.bottomToolsView.hidden = YES;
    self.bottomToolsView.alpha = 0;
    self.bottomToolsView.hx_y = HX_ScreenHeight;
    self.videoCropBtn.hidden = NO;
}
- (UIButton *)doneBtn {
    if (!_doneBtn) {
        _doneBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_doneBtn setTitle:[NSBundle hx_localizedStringForKey:@"完成"] forState:UIControlStateNormal];
        _doneBtn.hx_h = 30;
        _doneBtn.hx_w = 60;
        _doneBtn.hx_x = self.view.hx_w - 15 - _doneBtn.hx_w;
        _doneBtn.hx_centerY = 50.f / 2;
        [_doneBtn setBackgroundColor:self.manager.configuration.cameraFocusBoxColor];
        [_doneBtn addTarget:self action:@selector(didDoneBtnClick) forControlEvents:UIControlEventTouchUpInside];
        _doneBtn.titleLabel.font = [UIFont hx_mediumPingFangOfSize:15];
        [_doneBtn hx_radiusWithRadius:3 corner:UIRectCornerAllCorners];
    }
    return _doneBtn;
}
- (UIButton *)videoCropBtn {
    if (!_videoCropBtn) {
        _videoCropBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [_videoCropBtn setImage:[UIImage hx_imageNamed:@"hx_camera_video_crop"] forState:UIControlStateNormal];
        [_videoCropBtn addTarget:self action:@selector(didVideoCropBtnClick) forControlEvents:UIControlEventTouchUpInside];
        _videoCropBtn.tintColor = [UIColor whiteColor];
        _videoCropBtn.hx_h = 50.f;
        _videoCropBtn.hx_w = 40.f;
        _videoCropBtn.hx_centerY = self.doneBtn.hx_centerY;
        _videoCropBtn.hx_x = 15;
    }
    return _videoCropBtn;
}
- (void)didVideoCropBtnClick {
    [self.playVideoView.playerLayer.player pause];
    [self.playVideoView.playerLayer.player.currentItem seekToTime:CMTimeMake(0, 1)];
    HXWeakSelf
    [self hx_presentVideoEditViewControllerWithManager:self.manager videoURL:self.videoURL done:^(HXPhotoModel *beforeModel, HXPhotoModel *afterModel, HXVideoEditViewController *viewController) {
        [weakSelf doneCompleteWithModel:afterModel];
        BOOL cameraFinishDismissAnimated = weakSelf.manager.cameraFinishDismissAnimated;
        [weakSelf.presentingViewController dismissViewControllerAnimated:cameraFinishDismissAnimated completion:^{
            if ([weakSelf.delegate respondsToSelector:@selector(customCameraViewControllerFinishDismissCompletion:)]) {
                [weakSelf.delegate customCameraViewControllerFinishDismissCompletion:weakSelf];
            }
        }];
    } cancel:^(HXVideoEditViewController *viewController) {
        [weakSelf.playVideoView.playerLayer.player play];
    }];
}
- (UIVisualEffectView *)effectView {
    if (!_effectView) {
        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        _effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
        _effectView.frame = self.previewView.bounds;
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pausePlayerNotifacation) name:AVPlayerItemDidPlayToEndTimeNotification object:player.currentItem];
}

- (void)pausePlayerNotifacation {
    [self.playerLayer.player.currentItem seekToTime:CMTimeMake(0, 1)];
    [self.playerLayer.player play];
}
- (void)stopPlay {
    [self.playerLayer.player pause];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
}
@end
