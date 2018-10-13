//
//  HXCustomCameraController.h
//  照片选择器
//
//  Created by 洪欣 on 2017/10/31.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

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
//- (void)rampedZoomToValue:(CGFloat)value;
@end

@interface HXCustomCameraController : NSObject
@property (weak, nonatomic) id<HXCustomCameraControllerDelegate> delegate;
@property (strong, nonatomic, readonly) AVCaptureSession *captureSession;

- (BOOL)setupSession:(NSError *)error;
- (void)startSessionComplete:(void (^)(void))complete;
- (void)startSession;
- (void)stopSession;

- (void)initImageOutput;
- (void)initMovieOutput;

- (void)addImageOutput;
- (void)addMovieOutput;
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

- (void)setZoomValue:(CGFloat)zoomValue;                                   
- (void)rampZoomToValue:(CGFloat)zoomValue;
- (void)cancelZoom;
@end
