//
//  HXCustomCameraController.m
//  HXPhotoPickerExample
//
//  Created by Silence on 2017/10/31.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import "HXCustomCameraController.h"
#import <CoreMotion/CoreMotion.h>
#import "HXPhotoTools.h"
#import "HXCustomPreviewView.h"

const CGFloat HXZoomRate = 1.0f;

@interface HXCustomCameraController ()<AVCaptureFileOutputRecordingDelegate>
@property (strong, nonatomic) dispatch_queue_t videoQueue;
@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (weak, nonatomic) AVCaptureDeviceInput *activeVideoInput;

@property (strong, nonatomic) AVCaptureStillImageOutput *imageOutput;
@property (strong, nonatomic) AVCaptureMovieFileOutput *movieOutput;
@property (strong, nonatomic) NSURL *outputURL;
@property (strong, nonatomic) CMMotionManager *motionManager;
@property (nonatomic, assign) UIDeviceOrientation deviceOrientation;
@property (nonatomic, assign) UIDeviceOrientation imageOrientation;
@end

@implementation HXCustomCameraController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.motionManager = [[CMMotionManager alloc] init];
        self.motionManager.deviceMotionUpdateInterval = 1/15.0;
        
    }
    return self;
}
- (void)startMontionUpdate {
    if (self.motionManager.deviceMotionAvailable) {
        HXWeakSelf
        [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMDeviceMotion * _Nullable motion, NSError * _Nullable error) {
            [weakSelf performSelectorOnMainThread:@selector(handleDeviceMotion:) withObject:motion waitUntilDone:YES];
        }];
    }
}
- (void)stopMontionUpdate {
    [self.motionManager stopDeviceMotionUpdates];
}
- (void)dealloc {
}
/// 重力感应回调
- (void)handleDeviceMotion:(CMDeviceMotion *)deviceMotion {
    double x = deviceMotion.gravity.x;
    double y = deviceMotion.gravity.y;
    
    if (fabs(y) >= fabs(x)) {
        if (y >= 0) {
            _imageOrientation = UIDeviceOrientationPortraitUpsideDown;
            _deviceOrientation = UIDeviceOrientationPortraitUpsideDown;
            if ([self.delegate respondsToSelector:@selector(handleDeviceMotion:)]) {
                [self.delegate handleDeviceMotion:UIDeviceOrientationPortraitUpsideDown];
            }
        } else {
            _imageOrientation = UIDeviceOrientationPortrait;
            _deviceOrientation = UIDeviceOrientationPortrait;
            if ([self.delegate respondsToSelector:@selector(handleDeviceMotion:)]) {
                [self.delegate handleDeviceMotion:UIDeviceOrientationPortrait];
            }
        }
    } else {
        if (x >= 0) { // Home键左侧水平拍摄
            _imageOrientation = UIDeviceOrientationLandscapeRight;
            _deviceOrientation = UIDeviceOrientationLandscapeRight;
            if ([self.delegate respondsToSelector:@selector(handleDeviceMotion:)]) {
                [self.delegate handleDeviceMotion:UIDeviceOrientationLandscapeRight];
            }
        } else {
            _imageOrientation = UIDeviceOrientationLandscapeLeft;
            _deviceOrientation = UIDeviceOrientationLandscapeLeft;     // Home键右侧水平拍摄
            if ([self.delegate respondsToSelector:@selector(handleDeviceMotion:)]) {
                [self.delegate handleDeviceMotion:UIDeviceOrientationLandscapeLeft];
            }
        }
    }
}
- (void)initSeesion {
    self.captureSession = [[AVCaptureSession alloc] init];
}

- (void)setupPreviewLayer:(AVCaptureVideoPreviewLayer *)previewLayer startSessionCompletion:(void (^)(BOOL success))completion {
    if ([self.captureSession canSetSessionPreset:self.sessionPreset]) {
        self.captureSession.sessionPreset = self.sessionPreset;
    }else {
        if ([self.captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
            self.captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
        }else if ([self.captureSession canSetSessionPreset:AVCaptureSessionPresetHigh]) {
            self.captureSession.sessionPreset = AVCaptureSessionPresetHigh;
        }else {
            self.captureSession.sessionPreset = AVCaptureSessionPreset640x480;
        }
    }
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (self.defaultFrontCamera) {
        videoDevice = [self cameraWithPosition:AVCaptureDevicePositionFront];
    }
    
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
    if (videoInput) {
        if ([self.captureSession canAddInput:videoInput]) {
            [self.captureSession addInput:videoInput];
            self.activeVideoInput = videoInput;
        }
    }else {
        if (completion) {
            completion(NO);
        }
        return;
    }
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    if (completion) {
        completion(YES);
    }
}
- (AVCaptureMovieFileOutput *)movieOutput {
    if (!_movieOutput) {
        _movieOutput = [[AVCaptureMovieFileOutput alloc] init];
        CMTime maxDuration = CMTimeMakeWithSeconds(MAX(1, self.videoMaximumDuration), 30);
        _movieOutput.maxRecordedDuration = maxDuration;
    }
    return _movieOutput;
}
- (AVCaptureStillImageOutput *)imageOutput {
    if (!_imageOutput) {
        _imageOutput = [[AVCaptureStillImageOutput alloc] init];
        _imageOutput.outputSettings = @{AVVideoCodecKey : AVVideoCodecJPEG};
        _imageOutput.highResolutionStillImageOutputEnabled = YES;
    }
    return _imageOutput;
}
- (void)initImageOutput {
    if ([self.captureSession canAddOutput:self.imageOutput]) {
        [self.captureSession addOutput:self.imageOutput];
    }
}
- (void)initMovieOutput {
    if ([self.captureSession canAddOutput:self.movieOutput]) {
        [self.captureSession addOutput:self.movieOutput];
        AVCaptureConnection *videoConnection = [self.movieOutput connectionWithMediaType:AVMediaTypeVideo];
        if ([videoConnection isVideoStabilizationSupported]) {
            videoConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
        }
    }
}
- (void)removeMovieOutput {
    [self.captureSession removeOutput:self.movieOutput];
}
- (BOOL)addAudioInput {
    NSError *error;
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
    if (audioDevice) {
        if ([self.captureSession canAddInput:audioInput]) {
            [self.captureSession addInput:audioInput];
        }
    }else {
        return NO;
    }
    if (error) {
        return NO;
    }else {
        return YES;
    }
}
- (void)startSession {
    AVCaptureSession *session = self.captureSession;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (![session isRunning]) {
            [session startRunning];
        }
    });
//    if (![self.captureSession isRunning]) {
//        dispatch_async(self.videoQueue, ^{
//            [self.captureSession startRunning];
//        });
//    }
}
- (void)stopSession {
    AVCaptureSession *session = self.captureSession;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (session.running) {
            [session stopRunning];
        }
    });
    
//    if ([self.captureSession isRunning]) {
//        dispatch_async(self.videoQueue, ^{
//            [self.captureSession stopRunning];
//        });
//    }
}
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if (device.position == position) {
            return device;
        }
    }
    return nil;
}
- (AVCaptureDevice *)activeCamera {
    return self.activeVideoInput.device;
}
- (AVCaptureDevice *)inactiveCamer {
    AVCaptureDevice *device = nil;
    if (self.cameraCount > 1) {
        if ([self activeCamera].position == AVCaptureDevicePositionBack) {
            device = [self cameraWithPosition:AVCaptureDevicePositionFront];
        }else {
            device = [self cameraWithPosition:AVCaptureDevicePositionBack];
        }
    }
    return device;
}
- (BOOL)canSwitchCameras {
    return self.cameraCount > 1;
}
- (NSUInteger)cameraCount {
    return [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count];
}
- (BOOL)switchCameras {
    if (![self canSwitchCameras]) {
        return NO;
    }
    NSError *error;
    AVCaptureDevice *videoDevice = [self inactiveCamer];
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    if (videoInput) {
        
        [self.captureSession beginConfiguration];
        [self.captureSession removeInput:self.activeVideoInput];
        if ([self.captureSession canAddInput:videoInput]) {
            [self.captureSession addInput:videoInput];
            self.activeVideoInput = videoInput;
        }else {
            [self.captureSession addInput:self.activeVideoInput];
        }
        [self.captureSession commitConfiguration];
    }else {
        if ([self.delegate respondsToSelector:@selector(deviceConfigurationFailedWithError:)]) {
            [self.delegate deviceConfigurationFailedWithError:error];
        }
        return NO;
    }
    return YES;
}
- (BOOL)cameraSupportsTapToFocus {
    return [[self activeCamera] isFocusPointOfInterestSupported];
}
- (void)focusAtPoint:(CGPoint)point {
    AVCaptureDevice *device = [self activeCamera];
    if (device.isFocusPointOfInterestSupported && [device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            if (device.smoothAutoFocusSupported) {
                device.smoothAutoFocusEnabled = YES;
            }
            device.focusPointOfInterest = point;
            device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
            [device unlockForConfiguration];
        }else {
            if ([self.delegate respondsToSelector:@selector(deviceConfigurationFailedWithError:)]) {
                [self.delegate deviceConfigurationFailedWithError:error];
            }
        }
    }
}
- (BOOL)cameraSupportsTapToExpose {
    return [[self activeCamera] isExposurePointOfInterestSupported];
}
static const NSString *HXCustomCameraAdjustingExposureContext;

- (void)exposeAtPoint:(CGPoint)point {
    AVCaptureDevice *device = [self activeCamera];
    AVCaptureExposureMode exposureMode = AVCaptureExposureModeContinuousAutoExposure;
    if (device.isExposurePointOfInterestSupported && [device isExposureModeSupported:exposureMode]) {
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            device.exposurePointOfInterest = point;
            device.exposureMode = exposureMode;
//            if ([device isExposureModeSupported:AVCaptureExposureModeLocked]) {
//                [device addObserver:self forKeyPath:@"adjustingExposure" options:NSKeyValueObservingOptionNew context:&HXCustomCameraAdjustingExposureContext];
//            }
            [device unlockForConfiguration];
        }else {
            if ([self.delegate respondsToSelector:@selector(deviceConfigurationFailedWithError:)]) {
                [self.delegate deviceConfigurationFailedWithError:error];
            }
        }
    }
}
- (void)resetFocusAndExposureModes {
    AVCaptureDevice *device = [self activeCamera];
    
    AVCaptureExposureMode exposureMode =
    AVCaptureExposureModeContinuousAutoExposure;
    
    AVCaptureFocusMode focusMode = AVCaptureFocusModeContinuousAutoFocus;
    
    BOOL canResetFocus = [device isFocusPointOfInterestSupported] &&
    [device isFocusModeSupported:focusMode];
    
    BOOL canResetExposure = [device isExposurePointOfInterestSupported] &&
    [device isExposureModeSupported:exposureMode];
    
    CGPoint centerPoint = CGPointMake(0.5f, 0.5f);
    
    NSError *error;
    if ([device lockForConfiguration:&error]) {
        if (device.smoothAutoFocusSupported) {
            device.smoothAutoFocusEnabled = YES;
        }
        
        if (canResetFocus) {
            device.focusMode = focusMode;
            device.focusPointOfInterest = centerPoint;
        }
        
        if (canResetExposure) {
            device.exposureMode = exposureMode;
            device.exposurePointOfInterest = centerPoint;
        }
        
        [device unlockForConfiguration];
        
    } else {
        if ([self.delegate respondsToSelector:@selector(deviceConfigurationFailedWithError:)]) {
            [self.delegate deviceConfigurationFailedWithError:error];
        }
    }
}
// 闪光灯
- (BOOL)cameraHasFlash {
    return [[self activeCamera] hasFlash];
}
- (AVCaptureFlashMode)flashMode {
    return [[self activeCamera] flashMode];
}
- (void)setFlashMode:(AVCaptureFlashMode)flashMode {
    AVCaptureDevice *device = [self activeCamera];
    
    if (device.flashMode != flashMode &&
        [device isFlashModeSupported:flashMode]) {
        
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            device.flashMode = flashMode;
            [device unlockForConfiguration];
        } else {
            if ([self.delegate respondsToSelector:@selector(deviceConfigurationFailedWithError:)]) {
                [self.delegate deviceConfigurationFailedWithError:error];
            }
        }
    }
}
// 手电筒
- (BOOL)cameraHasTorch {
    return [[self activeCamera] hasTorch];
}

- (AVCaptureTorchMode)torchMode {
    return [[self activeCamera] torchMode];
}

- (void)setTorchMode:(AVCaptureTorchMode)torchMode {
    
    AVCaptureDevice *device = [self activeCamera];
    
    if (device.torchMode != torchMode &&
        [device isTorchModeSupported:torchMode]) {
        
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            device.torchMode = torchMode;
            [device unlockForConfiguration];
        } else {
            if ([self.delegate respondsToSelector:@selector(deviceConfigurationFailedWithError:)]) {
                [self.delegate deviceConfigurationFailedWithError:error];
            }
        }
    }
}
- (void)captureStillImage {
    
    AVCaptureConnection *connection =
    [self.imageOutput connectionWithMediaType:AVMediaTypeVideo];
    
    if (connection.isVideoOrientationSupported) {
        connection.videoOrientation = [self currentVideoOrientation];
    }
    
    AVCaptureDevicePosition position = [[self activeCamera] position];
    if (position == AVCaptureDevicePositionUnspecified ||
        position == AVCaptureDevicePositionFront) {
        connection.videoMirrored = YES;
    }else {
        connection.videoMirrored = NO;
    }
    HXWeakSelf
    id handler = ^(CMSampleBufferRef sampleBuffer, NSError *error) {
        if (sampleBuffer != NULL) {
            
            NSData *imageData =
            [AVCaptureStillImageOutput
             jpegStillImageNSDataRepresentation:sampleBuffer];
            
            UIImage *image = [[UIImage alloc] initWithData:imageData];
            if ([weakSelf.delegate respondsToSelector:@selector(takePicturesComplete:)]) {
                [weakSelf.delegate takePicturesComplete:image];
            }
        } else {
            if ([weakSelf.delegate respondsToSelector:@selector(takePicturesFailed)]) {
                [weakSelf.delegate takePicturesFailed];
            }
        }
    };
    
    [self.imageOutput captureStillImageAsynchronouslyFromConnection:connection
                                                  completionHandler:handler];
}
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
- (BOOL)isRecording {
    return self.movieOutput.isRecording;
}
- (void)startRecording {
    if (![self isRecording]) {
        AVCaptureConnection *videoConnection =
        [self.movieOutput connectionWithMediaType:AVMediaTypeVideo];

        // 设置编码格式
        if (HX_IOS11_Later && self.videoCodecKey) {
            NSMutableDictionary* outputSettings = [NSMutableDictionary dictionary];
            outputSettings[AVVideoCodecKey] = self.videoCodecKey;
            [self.movieOutput setOutputSettings:outputSettings forConnection:videoConnection];
        }
        
        if ([videoConnection isVideoOrientationSupported]) {
            videoConnection.videoOrientation = (AVCaptureVideoOrientation)_deviceOrientation;
        }
        
        AVCaptureDevice *device = [self activeCamera];
        if (device.isSmoothAutoFocusSupported) {
            NSError *error;
            if ([device lockForConfiguration:&error]) {
                device.smoothAutoFocusEnabled = NO;
                [device unlockForConfiguration];
            }
        }
        self.outputURL = [self uniqueURL];
        [self.movieOutput startRecordingToOutputFileURL:self.outputURL
                                      recordingDelegate:self];
    }
}

- (CMTime)recordedDuration {
    return self.movieOutput.recordedDuration;
}

- (NSURL *)uniqueURL {
    return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), [NSString stringWithFormat:@"hx%@.mov",[self videoOutFutFileName]]]];
}
- (NSString *)videoOutFutFileName {
    return [NSString hx_fileName];
}
- (void)stopRecording {
    if ([self isRecording]) {
        [self.movieOutput stopRecording];
    }
}

#pragma mark - AVCaptureFileOutputRecordingDelegate
// 开始录制
- (void)captureOutput:(AVCaptureFileOutput *)output didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections {
    if ([self.delegate respondsToSelector:@selector(videoStartRecording)]) {
        [self.delegate videoStartRecording];
    }
}
// 录制完成
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
      fromConnections:(NSArray *)connections
                error:(NSError *)error {
    if ([error.userInfo[AVErrorRecordingSuccessfullyFinishedKey] boolValue]) {
        if ([self.delegate respondsToSelector:@selector(videoFinishRecording:)]) {
            [self.delegate videoFinishRecording:[self.outputURL copy]];
        }
        self.outputURL = nil;
        return;
    }
    if (error) {
        if ([self.delegate respondsToSelector:@selector(mediaCaptureFailedWithError:)]) {
            [self.delegate mediaCaptureFailedWithError:error];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(videoFinishRecording:)]) {
            [self.delegate videoFinishRecording:[self.outputURL copy]];
        }
    }
    self.outputURL = nil;
}

- (void)updateZoomingDelegate {
//    CGFloat curZoomFactor = self.activeCamera.videoZoomFactor;
//    CGFloat maxZoomFactor = [self maxZoomFactor];
//    CGFloat value = log(curZoomFactor) / log(maxZoomFactor);
//    if ([self.delegate respondsToSelector:@selector(rampedZoomToValue:)]) {
//        [self.delegate rampedZoomToValue:value];
//    }
}

- (BOOL)cameraSupportsZoom {
    return self.activeCamera.activeFormat.videoMaxZoomFactor > 1.0f;
}

- (CGFloat)maxZoomFactor {
    return MIN(self.activeCamera.activeFormat.videoMaxZoomFactor, 5.0f);
}

- (CGFloat)currentZoomFacto {
    return self.activeCamera.videoZoomFactor;
}
- (void)setZoomValue:(CGFloat)zoomValue {
    if (zoomValue > self.maxZoomFactor) {
        zoomValue = self.maxZoomFactor;
    }
    if (!self.activeCamera.isRampingVideoZoom) {
        
        NSError *error;
        if ([self.activeCamera lockForConfiguration:&error]) {
            
            // Provide linear feel to zoom slider
//            CGFloat zoomFactor = pow([self maxZoomFactor], zoomValue);
            self.activeCamera.videoZoomFactor = zoomValue;
            
            [self.activeCamera unlockForConfiguration];
            
        } else {
            if ([self.delegate respondsToSelector:@selector(deviceConfigurationFailedWithError:)]) {
                [self.delegate deviceConfigurationFailedWithError:error];
            }
        }
    }
}

- (void)rampZoomToValue:(CGFloat)zoomValue {
//    CGFloat zoomFactor = pow([self maxZoomFactor], zoomValue);
    NSError *error;
    if ([self.activeCamera lockForConfiguration:&error]) {
        [self.activeCamera rampToVideoZoomFactor:zoomValue
                                        withRate:HXZoomRate];
        [self.activeCamera unlockForConfiguration];
    } else {
        if ([self.delegate respondsToSelector:@selector(deviceConfigurationFailedWithError:)]) {
            [self.delegate deviceConfigurationFailedWithError:error];
        }
    }
}

- (void)cancelZoom {
    NSError *error;
    if ([self.activeCamera lockForConfiguration:&error]) {
        [self.activeCamera cancelVideoZoomRamp];
        [self.activeCamera unlockForConfiguration];
    } else {
        if ([self.delegate respondsToSelector:@selector(deviceConfigurationFailedWithError:)]) {
            [self.delegate deviceConfigurationFailedWithError:error];
        }
    }
}

@end
