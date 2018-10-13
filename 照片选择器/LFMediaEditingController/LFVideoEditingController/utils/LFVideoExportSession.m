//
//  LFVideoExportSession.m
//  LFMediaEditingController
//
//  Created by LamTsanFeng on 2017/7/26.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFVideoExportSession.h"
#import "UIView+LFMECommon.h"
#import "UIImage+LFMECommon.h"

@interface LFVideoExportSession ()

@property (nonatomic, strong) AVAsset *asset;
@property (nonatomic, strong) AVAssetExportSession *exportSession;
@property (nonatomic, strong) AVMutableComposition *composition;
@property (nonatomic, strong) AVMutableVideoComposition *videoComposition;
@property (nonatomic, strong) AVMutableAudioMix *audioMix;

@end

@implementation LFVideoExportSession

- (id)initWithAsset:(AVAsset *)asset
{
    self = [super init];
    if (self) {
        _isOrignalSound = YES;
        _asset = asset;
        _timeRange = CMTimeRangeMake(kCMTimeZero, self.asset.duration);
    }
    return self;
}

- (id)initWithURL:(NSURL *)url
{
    AVAsset *asset = [AVAsset assetWithURL:url];
    return [self initWithAsset:asset];
}

- (void)dealloc
{
    [self.exportSession cancelExport];
    self.exportSession = nil;
    self.composition = nil;
    self.videoComposition = nil;
}

- (CGSize)videoSize:(AVAsset *)asset
{
    CGSize size = CGSizeZero;
    AVAssetTrack *assetVideoTrack = nil;
    if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
        assetVideoTrack = [asset tracksWithMediaType:AVMediaTypeVideo][0];
        size = assetVideoTrack.naturalSize;
    }
    
    return size;
}

- (void)exportAsynchronouslyWithCompletionHandler:(void (^)(NSError *error))handler
{
    [self.exportSession cancelExport];
    self.exportSession = nil;
    self.composition = nil;
    self.videoComposition = nil;
    
    NSError *error = nil;
    NSFileManager *fm = [NSFileManager new];
    NSURL *trimURL = self.outputURL;
    /** 删除原来剪辑的视频 */
    BOOL exist = [fm fileExistsAtPath:trimURL.path];
    if (exist) {
        if (![fm removeItemAtURL:trimURL error:&error]) {
            NSLog(@"removeTrimPath error: %@ \n",[error localizedDescription]);
        }
    }
    
    AVAssetTrack *assetVideoTrack = nil;
    AVAssetTrack *assetAudioTrack = nil;
    // Check if the asset contains video and audio tracks
    if ([[self.asset tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
        assetVideoTrack = [self.asset tracksWithMediaType:AVMediaTypeVideo][0];
    }
    if ([[self.asset tracksWithMediaType:AVMediaTypeAudio] count] != 0) {
        assetAudioTrack = [self.asset tracksWithMediaType:AVMediaTypeAudio][0];
    }
    
    CMTime insertionPoint = kCMTimeZero;
    
    // Step 1
    // Create a composition with the given asset and insert audio and video tracks into it from the asset
    // Check if a composition already exists, else create a composition using the input asset
    
    self.composition = [[AVMutableComposition alloc] init];
    
    // Insert the video and audio tracks from AVAsset
    if (assetVideoTrack != nil) {
        // 视频通道  工程文件中的轨道，有音频轨、视频轨等，里面可以插入各种对应的素材
        AVMutableCompositionTrack *compositionVideoTrack = [self.composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        // 视频方向
        [compositionVideoTrack setPreferredTransform:assetVideoTrack.preferredTransform];
        // 把视频轨道数据加入到可变轨道中 这部分可以做视频裁剪TimeRange
        [compositionVideoTrack insertTimeRange:self.timeRange ofTrack:assetVideoTrack atTime:insertionPoint error:&error];
    }
    if (assetAudioTrack != nil && self.isOrignalSound) {
        AVMutableCompositionTrack *compositionAudioTrack = [self.composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        compositionAudioTrack.preferredTransform = assetAudioTrack.preferredTransform;
        [compositionAudioTrack insertTimeRange:self.timeRange ofTrack:assetAudioTrack atTime:insertionPoint error:&error];
    }
    
    /** 创建额外音轨特效 */
    NSMutableArray<AVAudioMixInputParameters *> *inputParameters;
    if (self.audioUrls.count) {
        inputParameters = [@[] mutableCopy];
    }
    
    /** 添加其他音频 */
    for (NSURL *audioUrl in self.audioUrls) {
        /** 声音采集 */
        AVURLAsset *audioAsset =[[AVURLAsset alloc]initWithURL:audioUrl options:nil];
        AVAssetTrack *additional_assetAudioTrack = nil;
        /** 检查是否有效音轨 */
        if ([[audioAsset tracksWithMediaType:AVMediaTypeAudio] count] != 0) {
            additional_assetAudioTrack = [audioAsset tracksWithMediaType:AVMediaTypeAudio][0];
        }
        if (additional_assetAudioTrack) {
            AVMutableCompositionTrack *additional_compositionAudioTrack = [self.composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            additional_compositionAudioTrack.preferredTransform = additional_assetAudioTrack.preferredTransform;
            [additional_compositionAudioTrack insertTimeRange:self.timeRange ofTrack:additional_assetAudioTrack atTime:insertionPoint error:&error];
            
            AVMutableAudioMixInputParameters *mixParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:additional_compositionAudioTrack];
            [mixParameters setVolumeRampFromStartVolume:1 toEndVolume:0 timeRange:CMTimeRangeMake(kCMTimeZero, self.timeRange.duration)];
            [inputParameters addObject:mixParameters];
        }
    }
    if (inputParameters.count) {
        self.audioMix = [AVMutableAudioMix audioMix];
        self.audioMix.inputParameters = inputParameters;
    }
    
    UIImageOrientation orientation = [self orientationFromAVAssetTrack:assetVideoTrack];
    
    if (orientation != UIImageOrientationUp || self.overlayView) {
        self.videoComposition = [AVMutableVideoComposition videoComposition];
        self.videoComposition.frameDuration = CMTimeMake(1, 30); // 30 fps
    }
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGSize renderSize = assetVideoTrack.naturalSize;
    
    switch (orientation) {
        case UIImageOrientationLeft:
            //顺时针旋转270°
            //            NSLog(@"视频旋转270度，home按键在右");
            transform = CGAffineTransformTranslate(transform, 0.0, assetVideoTrack.naturalSize.width);
            transform = CGAffineTransformRotate(transform,M_PI_2*3.0);
            renderSize = CGSizeMake(assetVideoTrack.naturalSize.height,assetVideoTrack.naturalSize.width);
            break;
        case UIImageOrientationRight:
            //顺时针旋转90°
            //            NSLog(@"视频旋转90度,home按键在左");
            transform = CGAffineTransformTranslate(transform, assetVideoTrack.naturalSize.height, 0.0);
            transform = CGAffineTransformRotate(transform,M_PI_2);
            renderSize = CGSizeMake(assetVideoTrack.naturalSize.height,assetVideoTrack.naturalSize.width);
            break;
        case UIImageOrientationDown:
            //顺时针旋转180°
            //            NSLog(@"视频旋转180度，home按键在上");
            transform = CGAffineTransformTranslate(transform, assetVideoTrack.naturalSize.width, assetVideoTrack.naturalSize.height);
            transform = CGAffineTransformRotate(transform,M_PI);
            renderSize = CGSizeMake(assetVideoTrack.naturalSize.width,assetVideoTrack.naturalSize.height);
            break;
        default:
            break;
    }
    
    if (self.videoComposition) {
        
        self.videoComposition.renderSize = renderSize;
        
        AVAssetTrack *videoTrack = [self.composition tracksWithMediaType:AVMediaTypeVideo][0];
        
        AVMutableVideoCompositionInstruction *roateInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        roateInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, self.composition.duration);
        AVMutableVideoCompositionLayerInstruction *roateLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
        
        [roateLayerInstruction setTransform:transform atTime:kCMTimeZero];
        
        roateInstruction.layerInstructions = @[roateLayerInstruction];
        //将视频方向旋转加入到视频处理中
        self.videoComposition.instructions = @[roateInstruction];
    }
    
    /** 水印 */
    if(self.overlayView) {
        CALayer *animatedLayer = [self buildAnimatedTitleLayerForSize:renderSize];
        CALayer *parentLayer = [CALayer layer];
        CALayer *videoLayer = [CALayer layer];
        parentLayer.frame = CGRectMake(0, 0, self.videoComposition.renderSize.width, self.videoComposition.renderSize.height);
        videoLayer.frame = CGRectMake(0, 0, self.videoComposition.renderSize.width, self.videoComposition.renderSize.height);
        [parentLayer addSublayer:videoLayer];
        [parentLayer addSublayer:animatedLayer];
        
        self.videoComposition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    }
    
    self.exportSession = [[AVAssetExportSession alloc] initWithAsset:self.composition presetName:AVAssetExportPresetHighestQuality];
    // Implementation continues.
    /** 创建混合视频时开始剪辑 */
    //    self.exportSession.timeRange = self.timeRange;
    self.exportSession.videoComposition = self.videoComposition;
    self.exportSession.outputURL = trimURL;
    self.exportSession.outputFileType = AVFileTypeQuickTimeMovie;
    self.exportSession.audioMix = self.audioMix;
    
    if (self.asset.duration.timescale == 0 || self.exportSession == nil) {
        /** 这个情况AVAssetExportSession会卡死 */
        NSError *failError = [NSError errorWithDomain:@"LFVideoExportSessionError" code:(-100) userInfo:@{NSLocalizedDescriptionKey:@"exportSession init fail"}];
        if (handler) handler(failError);
        return;
    }
    
    [self.exportSession exportAsynchronouslyWithCompletionHandler:^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            switch ([self.exportSession status]) {
                case AVAssetExportSessionStatusFailed:
                    NSLog(@"Export failed: %@", [[self.exportSession error] localizedDescription]);
                    break;
                case AVAssetExportSessionStatusCancelled:
                    NSLog(@"Export canceled");
                    break;
                case AVAssetExportSessionStatusCompleted:
                    NSLog(@"Export completed");
                    break;
                default:
                    break;
            }
            if ([self.exportSession status] == AVAssetExportSessionStatusCompleted && [fm fileExistsAtPath:trimURL.path]) {
                if (handler) handler(nil);
            } else {
                if (handler) handler(self.exportSession.error);
            }
        });
    }];
}

- (void)cancelExport
{
    [self.exportSession cancelExport];
}


- (CALayer *)buildAnimatedTitleLayerForSize:(CGSize)size
{
    UIView *overlayView = self.overlayView;
    UIImage *image = [overlayView LFME_captureImage];
    image = [image LFME_scaleToSize:size];
    // 1 - The usual overlay
    CALayer *overlayLayer = [CALayer layer];
    overlayLayer.contentsScale = [UIScreen mainScreen].scale;
    overlayLayer.contents = (__bridge id _Nullable)(image.CGImage);
    overlayLayer.frame = CGRectMake(0, 0, size.width, size.height);
    [overlayLayer setMasksToBounds:YES];
    
    return overlayLayer;
}

- (UIImageOrientation)orientationFromAVAssetTrack:(AVAssetTrack *)videoTrack
{
    UIImageOrientation orientation = UIImageOrientationUp;
    
    CGAffineTransform t = videoTrack.preferredTransform;
    if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0){
        // Portrait
        //        degress = 90;
        orientation = UIImageOrientationRight;
    }else if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0){
        // PortraitUpsideDown
        //        degress = 270;
        orientation = UIImageOrientationLeft;
    }else if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0){
        // LandscapeRight
        //        degress = 0;
        orientation = UIImageOrientationUp;
    }else if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0){
        // LandscapeLeft
        //        degress = 180;
        orientation = UIImageOrientationDown;
    }
    
    return orientation;
}

@end

