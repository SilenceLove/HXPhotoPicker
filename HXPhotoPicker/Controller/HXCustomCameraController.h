//
//  HXCustomCameraController.h
//  HXPhotoPickerExample
//
//  Created by Silence on 2017/10/31.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@class HXPhotoManager;
@protocol HXCustomCameraControllerDelegate <NSObject>
@optional;
- (void)deviceConfigurationFailedWithError:(NSError *)error;
- (void)mediaCaptureFailedWithError:(NSError *)error;
- (void)assetLibraryWriteFailedWithError:(NSError *)error;
- (void)videoStartRecording;
- (void)videoFinishRecording:(NSURL *)videoURL;
- (void)takePicturesComplete:(UIImage *)image;
- (void)takePicturesFailed;
- (void)handleDeviceMotion:(UIDeviceOrientation)deviceOrientation;
//- (void)rampedZoomToValue:(CGFloat)value;
@end

@interface HXCustomCameraController : NSObject
@property (weak, nonatomic) id<HXCustomCameraControllerDelegate> delegate;
@property (strong, nonatomic, readonly) AVCaptureSession *captureSession;

/// 相机界面默认前置摄像头
@property (assign, nonatomic) BOOL defaultFrontCamera;
@property (assign, nonatomic) NSTimeInterval videoMaximumDuration;
- (void)initSeesion;
- (void)setupPreviewLayer:(AVCaptureVideoPreviewLayer *)previewLayer startSessionCompletion:(void (^)(BOOL success))completion;

- (void)startSession;
- (void)stopSession;

- (void)initImageOutput;
- (void)initMovieOutput;
- (void)removeMovieOutput;

- (BOOL)addAudioInput;

- (BOOL)switchCameras;
- (BOOL)canSwitchCameras;
@property (nonatomic, readonly) NSUInteger cameraCount;
@property (nonatomic, readonly) BOOL cameraHasTorch;
@property (nonatomic, readonly) BOOL cameraHasFlash;
@property (nonatomic, readonly) BOOL cameraSupportsTapToFocus;
@property (nonatomic, readonly) BOOL cameraSupportsTapToExpose;
@property (nonatomic) AVCaptureTorchMode torchMode;
@property (nonatomic) AVCaptureFlashMode flashMode;


@property (copy, nonatomic) NSString *videoCodecKey;
@property (copy, nonatomic) NSString *sessionPreset;

- (void)focusAtPoint:(CGPoint)point;
- (void)exposeAtPoint:(CGPoint)point;
- (void)resetFocusAndExposureModes;

- (void)captureStillImage;

- (void)startRecording;
- (void)stopRecording;
- (BOOL)isRecording;
- (CMTime)recordedDuration;

- (void)startMontionUpdate;
- (void)stopMontionUpdate;

- (BOOL)cameraSupportsZoom;                                               

- (CGFloat)maxZoomFactor;
- (CGFloat)currentZoomFacto;

- (void)setZoomValue:(CGFloat)zoomValue;                                   
- (void)rampZoomToValue:(CGFloat)zoomValue;
- (void)cancelZoom;

@end
