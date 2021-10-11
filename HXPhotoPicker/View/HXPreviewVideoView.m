//
//  HXPreviewVideoView.m
//  HXPhotoPickerExample
//
//  Created by Silence on 2019/11/15.
//  Copyright © 2019 Silence. All rights reserved.
//

#import "HXPreviewVideoView.h"
#import <AVKit/AVKit.h>
#import "HXPhotoModel.h"
#import "HXPhotoDefine.h"
#import "UIView+HXExtension.h"
#import "UIImage+HXExtension.h"
#import "NSString+HXExtension.h"
#import "HXPhotoTools.h"
#import "UIButton+HXExtension.h"
#import "HXPhotoBottomSelectView.h"

@interface HXPreviewVideoView ()
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (assign, nonatomic) PHImageRequestID requestID;
@property (strong ,nonatomic) id playbackTimeObserver;
@property (assign, nonatomic) BOOL canRemovePlayerObservers;
@property (assign, nonatomic) NSTimeInterval videoTotalDuration;
@property (assign, nonatomic) NSTimeInterval videoCurrentTime;
@property (assign, nonatomic) BOOL videoManualPause;
@property (strong, nonatomic) HXHUD *loadingView;
@property (strong, nonatomic) HXHUD *loadFailedView;
@property (assign, nonatomic) BOOL videoLoadFailed;

@property (strong, nonatomic) UIButton *playBtn;
@property (assign, nonatomic) BOOL isDismiss;

@property (strong, nonatomic) NSURLSessionDownloadTask *videoDownloadTask;
@end

@implementation HXPreviewVideoView

- (void)awakeFromNib {
    [super awakeFromNib];

    [self setup];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}
- (void)setup {
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.playerLayer.player = self.player;
    self.videoManualPause = NO;
    self.layer.masksToBounds = YES;
    [self addSubview:self.playBtn];
    
    
    [self.playerLayer addObserver:self forKeyPath:@"readyForDisplay" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterPlayGround) name:UIApplicationDidBecomeActiveNotification object:nil];
    
#if HasAFNetworking
    HXWeakSelf
    [HXPhotoCommon photoCommon].reachabilityStatusChangeBlock = ^(AFNetworkReachabilityStatus netStatus) {
        if (weakSelf.videoLoadFailed) {
            if (netStatus == AFNetworkReachabilityStatusReachableViaWiFi ||
                netStatus == AFNetworkReachabilityStatusReachableViaWWAN) {
                [weakSelf cancelPlayer];
                [weakSelf setModel:weakSelf.model];
            }
        }
    };
#endif
}

- (void)setModel:(HXPhotoModel *)model {
    _model = model;
    if (self.player.currentItem != nil && !self.videoLoadFailed) return;

    self.playBtn.hidden = YES;
    self.canRemovePlayerObservers = NO;
    HXWeakSelf
    if (model.cameraVideoType == HXPhotoModelMediaTypeCameraVideoTypeNetWork) {
        NSString *videoFilePath = [HXPhotoTools getVideoURLFilePath:model.videoURL];
        NSURL *videoFileURL = [NSURL fileURLWithPath:videoFilePath];
        if ([HXPhotoTools fileExistsAtVideoURL:model.videoURL]) {
            [self requestAVAssetComplete:[AVAsset assetWithURL:videoFileURL]];
            return;
        }
        [self showLoading];
        if ([HXPhotoCommon photoCommon].downloadNetworkVideo) {
            self.videoDownloadTask = [[HXPhotoCommon photoCommon] downloadVideoWithURL:model.videoURL progress:^(float progress, long long downloadLength, long long totleLength, NSURL * _Nullable videoURL) {
                if (![videoURL.absoluteString isEqualToString:weakSelf.model.videoURL.absoluteString]) {
                    return;
                }
            } downloadSuccess:^(NSURL * _Nullable filePath, NSURL * _Nullable videoURL) {
                if (![videoURL.absoluteString isEqualToString:weakSelf.model.videoURL.absoluteString]) {
                    return;
                }
                [weakSelf requestAVAssetComplete:[AVAsset assetWithURL:videoFileURL]];
            } downloadFailure:^(NSError * _Nullable error, NSURL * _Nullable videoURL) {
                if (![videoURL.absoluteString isEqualToString:weakSelf.model.videoURL.absoluteString]) {
                    return;
                }
                weakSelf.videoLoadFailed = YES;
                [weakSelf hideLoading];
                if (error.code != NSURLErrorCancelled) {
                    [weakSelf showLoadFailedView];
                }
            }];
            return;
        }
    }
    [UIView cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(showLoading) withObject:nil afterDelay:0.2f];
    self.requestID = [self.model requestAVAssetStartRequestICloud:^(PHImageRequestID iCloudRequestId, HXPhotoModel *model) {
        if (weakSelf.model != model) return;
        weakSelf.requestID = iCloudRequestId;
    } progressHandler:^(double progress, HXPhotoModel *model) {
        if (weakSelf.model != model) return;
    } success:^(AVAsset *avAsset, AVAudioMix *audioMix, HXPhotoModel *model, NSDictionary *info) {
        if (weakSelf.model != model) return;
        [UIView cancelPreviousPerformRequestsWithTarget:weakSelf];
        [weakSelf requestAVAssetComplete:avAsset];
    } failed:^(NSDictionary *info, HXPhotoModel *model) {
        if (weakSelf.model != model) return;
        [UIView cancelPreviousPerformRequestsWithTarget:weakSelf];
        weakSelf.videoLoadFailed = YES;
        [weakSelf hideLoading];
        if (![[info objectForKey:PHImageCancelledKey] boolValue]) {
            [weakSelf showLoadFailedView];
        }
    }];
}
- (void)requestAVAssetComplete:(AVAsset *)avAsset {
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    [[AVAudioSession sharedInstance] setCategory: [HXPhotoCommon photoCommon].audioSessionCategory error: nil];
    self.avAsset = avAsset;
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:avAsset];
    [self.player replaceCurrentItemWithPlayerItem:playerItem];
    self.playerLayer.player = self.player;
    [self addPlayerObservers];
    if (self.downloadICloudAssetComplete) {
        self.downloadICloudAssetComplete();
    }
}
- (void)cancelPlayer {
    if (!self.stopCancel && self.videoDownloadTask) {
        [self.videoDownloadTask cancel];
        self.videoDownloadTask = nil;
    }
    if (self.requestID) {
        [[PHImageManager defaultManager] cancelImageRequest:self.requestID];
        self.requestID = -1;
    }
    if (self.player.currentItem != nil && !self.stopCancel) {
        self.playBtnDidPlay = NO;
        self.videoLoadFailed = NO;
        self.playBtn.hidden = NO;
        [self hideLoading];
        [self hideLoadFailedView];
        if (self.changePlayBtnState) {
            self.changePlayBtnState(NO);
        }
        self.videoManualPause = NO;
        [self.player pause];
        self.isPlayer = NO;
        [self.player seekToTime:kCMTimeZero];
        [self.player cancelPendingPrerolls];
        [self.player.currentItem cancelPendingSeeks];
        [self.player.currentItem.asset cancelLoading];
        [self removePlayerObservers];
        self.canRemovePlayerObservers = NO;
        [self.player replaceCurrentItemWithPlayerItem:nil];
        self.playerLayer.player = nil;
        [self setVideoCurrentTime:0 animation:NO];
    }
    self.stopCancel = NO;
}
- (void)pausePlayerAndShowNaviBar {
    [self.player.currentItem seekToTime:CMTimeMake(0, 1)];
    if ([HXPhotoCommon photoCommon].videoAutoPlayType == HXVideoAutoPlayTypeOnce) {
        self.isPlayer = NO;
        self.playBtn.hidden = NO;
        return;
    }
    [self.player play];
    self.isPlayer = YES;
}
- (void)addPlayerObservers {
    self.canRemovePlayerObservers = YES;
    // 播放状态
    [self.player.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    // 监听loadedTimeRanges属性
    [self.player.currentItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    [self.player.currentItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    [self.player.currentItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pausePlayerAndShowNaviBar) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
}
- (void)removePlayerObservers {
    if (!self.canRemovePlayerObservers) {
        return;
    }
    if (self.playbackTimeObserver) {
        [self.player removeTimeObserver:self.playbackTimeObserver];
        self.playbackTimeObserver = nil;
    }
    [self.player.currentItem removeObserver:self forKeyPath:@"status"];
    [self.player.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [self.player.currentItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [self.player.currentItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([object isKindOfClass:[AVPlayerItem class]]) {
        if (object != self.player.currentItem) {
            return;
        }
        if ([keyPath isEqualToString:@"status"]) {
            switch (self.player.currentItem.status) {
                case AVPlayerItemStatusReadyToPlay: { // 可以播放了
                    [self hideLoadFailedView];
                    self.videoTotalDuration = CMTimeGetSeconds(self.player.currentItem.duration);
                    if (self.model.videoDuration <= 0) {
                        self.model.videoDuration = self.videoTotalDuration;
                    }
                    if (self.gotVideoDuration) {
                        self.gotVideoDuration(self.videoTotalDuration);
                    }
                    if (!self.playbackTimeObserver) {
                        // 播放进度
                        HXWeakSelf
                        self.playbackTimeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 10) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
                            if (!weakSelf.player) {
                                return;
                            }
                            //当前播放的时间
                            NSTimeInterval currentTime = CMTimeGetSeconds(time);
                            weakSelf.model.videoCurrentTime = currentTime;
                            [weakSelf setVideoCurrentTime:currentTime animation:YES];
                        }];
                    }
                } break;
                case AVPlayerItemStatusFailed: { // 初始化失败
                    self.videoLoadFailed = YES;
                    [self hideLoading];
                    [self showLoadFailedView];
                } break;
                default: {
                  // 未知状态
                } break;
            }
        }else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
            NSTimeInterval timeInterval = [self availableDuration];// 计算缓冲进度
            CMTime duration = self.player.currentItem.duration;
            CGFloat totalDuration = CMTimeGetSeconds(duration);
            if (self.gotVideoBufferEmptyValue) {
                self.gotVideoBufferEmptyValue(timeInterval / totalDuration);
            }
        }else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
            //监听播放器在缓冲数据的状态
        }else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
            if (!self.player.currentItem.playbackLikelyToKeepUp) {
                // 缓冲中
                [self showLoading];
            }else {
                // 缓冲完成
                [self hideLoading];
            }
        }
    }
    if ([object isKindOfClass:[AVPlayerLayer class]] && [keyPath isEqualToString:@"readyForDisplay"]) {
        if (object != self.playerLayer) {
            return;
        }
        if (self.playerLayer.readyForDisplay) {
            if (self.player) {
                if ([HXPhotoCommon photoCommon].videoAutoPlayType == HXVideoAutoPlayTypeWiFi) {
#if HasAFNetworking
                    if ([HXPhotoCommon photoCommon].netStatus == AFNetworkReachabilityStatusReachableViaWiFi) {
                        [self videoDidPlay];
                        self.playBtnDidPlay = YES;
                    }else {
                        self.playBtn.hidden = NO;
                    }
#else
                    if (!self.isDismiss) {
                        self.playBtn.hidden = NO;
                    }
#endif
                }else if ([HXPhotoCommon photoCommon].videoAutoPlayType == HXVideoAutoPlayTypeAll ||
                          [HXPhotoCommon photoCommon].videoAutoPlayType == HXVideoAutoPlayTypeOnce) {
                    [self videoDidPlay];
                    self.playBtnDidPlay = YES;
                }else {
                    if (!self.isDismiss) {
                        self.playBtn.hidden = NO;
                    }
                }
                if (self.shouldPlayVideo) {
                    self.shouldPlayVideo();
                }
                self.playerLayer.hidden = NO;
            }
        }
    }
}
- (void)videoDidPlay {
    [self.player play];
    self.isPlayer = YES;
    self.videoManualPause = YES;
    if (self.changePlayBtnState) {
        self.changePlayBtnState(YES);
    }
}
- (void)setVideoCurrentTime:(NSTimeInterval)videoCurrentTime animation:(BOOL)isAnimatin {
    _videoCurrentTime = videoCurrentTime;
    if (self.changeValue) {
        CGFloat value = 0;
        if (self.videoTotalDuration > 0) {
            value = videoCurrentTime / self.videoTotalDuration;
        }
        self.changeValue(value, isAnimatin);
    }
    if (self.gotVideoCurrentTime) {
        self.gotVideoCurrentTime(videoCurrentTime);
    }
}
- (void)appDidEnterBackground {
    if (!self.player.currentItem) {
        return;
    }
    [self.player pause];
    self.isPlayer = NO;
}
- (void)appDidEnterPlayGround {
    if (!self.player.currentItem) {
        return;
    }
    if (self.videoManualPause && self.playBtnDidPlay) {
        [self.player play];
        self.isPlayer = YES;
    }
}
- (void)setPlayBtnHidden:(BOOL)playBtnHidden {
    _playBtnHidden = playBtnHidden;
    self.playBtn.hidden = playBtnHidden;
}
- (void)didPlayBtnClickWithSelected:(BOOL)isSelected {
    self.videoManualPause = isSelected;
    self.playBtnDidPlay = YES;
    self.isPlayer = isSelected;
    if (isSelected) {
        [self.player play];
    }else {
        [self.player pause];
    }
}
- (void)changePlayerTimeWithValue:(CGFloat)value type:(HXPreviewVideoSliderType)type {
    if (!self.player.currentItem) {
        return;
    }
    CGFloat seconds = self.videoTotalDuration * value;
    seconds = MAX(0, seconds);
    seconds = MIN(seconds, self.videoTotalDuration);
    CMTime time = CMTimeMakeWithSeconds(seconds , self.player.currentTime.timescale);
    HXWeakSelf
    [self.player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        if (finished) {
            [weakSelf setVideoCurrentTime:seconds animation:NO];
            if (type == HXPreviewVideoSliderTypeTouchUpInSide) {
                [weakSelf videoDidPlay];
            }
        }
    }];
    if (type == HXPreviewVideoSliderTypeTouchDown) {
        [self.player pause];
        self.isPlayer = NO;
        if (self.changePlayBtnState) {
            self.changePlayBtnState(NO);
        }
        self.videoManualPause = NO;
    }
}
- (NSTimeInterval)availableDuration {
    if (!self.player.currentItem) {
        return 0;
    }
    NSArray *loadedTimeRanges = [self.player.currentItem loadedTimeRanges];
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    float startSeconds = CMTimeGetSeconds(timeRange.start);
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result = startSeconds + durationSeconds;// 计算缓冲总进度
    return result;
}
- (void)showOtherView {
    self.isDismiss = NO;
    self.changeSliderHidden(NO);
    [UIView animateWithDuration:0.2 animations:^{
        self.loadFailedView.alpha = 1;
        self.loadingView.alpha = 1;
        self.playBtn.alpha = 1;
    }];
}
- (void)hideOtherView:(BOOL)animatoin {
    self.isDismiss = YES;
    self.changeSliderHidden(YES);
    if (!animatoin) {
        self.loadingView.hidden = YES;
        self.loadFailedView.hidden = YES;
        self.playBtn.hidden = YES;
        return;
    }
    [UIView animateWithDuration:0.2 animations:^{
        self.loadFailedView.alpha = 0;
        self.loadingView.alpha = 0;
        self.playBtn.alpha = 0;
    }];
}
- (UIButton *)playBtn {
    if (!_playBtn) {
        _playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playBtn setImage:[UIImage hx_imageNamed:@"hx_multimedia_videocard_play"] forState:UIControlStateNormal];
        [_playBtn addTarget:self action:@selector(didPlayBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        _playBtn.hx_size = _playBtn.currentImage.size;
    }
    return _playBtn;
}
- (void)didPlayBtnClick:(UIButton *)button {
    [self videoDidPlay];
    self.playBtnDidPlay = YES;
    button.hidden = YES;
    if (self.playBtnDidClick) {
        self.playBtnDidClick(YES);
    }
}
- (void)setPlayBtnDidPlay:(BOOL)playBtnDidPlay {
    _playBtnDidPlay = playBtnDidPlay;
    if (playBtnDidPlay && !self.playBtn.hidden) {
        self.playBtn.hidden = YES;
    }
}
+ (Class)layerClass {
    return AVPlayerLayer.class;
}
- (AVPlayerLayer *)playerLayer {
    return (AVPlayerLayer *)self.layer;
}
- (AVPlayer *)player {
    if (!_player) {
        _player = [[AVPlayer alloc] init];
    }
    return _player;
}
- (HXHUD *)loadingView {
    if (!_loadingView) {
        _loadingView = [[HXHUD alloc] initWithFrame:CGRectMake(0, 0, 95, 95) imageName:nil text:nil];
        [_loadingView showloading];
    }
    return _loadingView;
}
- (void)showLoading {
    [self addSubview:self.loadingView];
}
- (void)hideLoading {
    [self.loadingView removeFromSuperview];
}
- (HXHUD *)loadFailedView {
    if (!_loadFailedView) {
        NSString *text = @"视频加载失败!";
        CGFloat hudW = [UILabel hx_getTextWidthWithText:text height:15 fontSize:14];
        if (hudW > self.hx_w - 60) {
            hudW = self.hx_w - 60;
        }
        if (hudW < 100) {
            hudW = 100;
        }
        CGFloat hudH = [UILabel hx_getTextHeightWithText:text width:hudW fontSize:14];
        _loadFailedView = [[HXHUD alloc] initWithFrame:CGRectMake(0, 0, hudW + 20, 110 + hudH - 15) imageName:@"hx_alert_failed" text:text];
    }
    return _loadFailedView;
}
- (void)showLoadFailedView {
    [self addSubview:self.loadFailedView];
}
- (void)hideLoadFailedView {
    [self.loadFailedView removeFromSuperview];
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.playerLayer.frame = self.bounds;
    
    self.loadingView.hx_centerX = self.hx_w / 2;
    self.loadingView.hx_centerY = self.hx_h / 2;
    
    self.loadFailedView.hx_centerX = self.hx_w / 2;
    self.loadFailedView.hx_centerY = self.hx_h / 2;
    
    self.playBtn.hx_centerX = self.hx_w / 2;
    self.playBtn.hx_centerY = self.hx_h / 2;
}
- (void)dealloc {
    
    [self.playerLayer removeObserver:self forKeyPath:@"readyForDisplay"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [self removePlayerObservers];
    if (HXShowLog) NSSLog(@"dealloc");
}
@end


@interface HXPreviewVideoSliderView ()
@property (strong, nonatomic) HXSlider *sliderView;
@property (strong, nonatomic) UIProgressView *progressView;
@property (strong, nonatomic) UIButton *playBtn;
@property (strong, nonatomic) UILabel *currentTimeLb;
@property (strong, nonatomic) UILabel *totalTimeLb;
@property (strong, nonatomic) UIVisualEffectView *effectView;
@property (strong, nonatomic) UIPanGestureRecognizer *panGesture;
@end

@implementation HXPreviewVideoSliderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.masksToBounds = YES;
        self.layer.cornerRadius = 5.f;
        self.panGesture = [[UIPanGestureRecognizer alloc] init];
        [self addGestureRecognizer:self.panGesture];
        [self addSubview:self.effectView];
        [self addSubview:self.progressView];
        [self addSubview:self.sliderView];
        [self addSubview:self.playBtn];
        [self addSubview:self.currentTimeLb];
        [self addSubview:self.totalTimeLb];
    }
    return self;
}
- (void)show {
    if (self.hidden) {
        self.hidden = NO;
        [UIView animateWithDuration:0.25 animations:^{
            self.alpha = 1;
        }];
    }
}
- (void)hide {
    if (!self.hidden) {
        [UIView animateWithDuration:0.25 animations:^{
            self.alpha = 0;
        } completion:^(BOOL finished) {
            self.hidden = YES;
        }];
    }
}
- (void)setCurrentValue:(CGFloat)currentValue animation:(BOOL)isAnimation {
    _currentValue = currentValue;
    [self.sliderView setCurrentValue:currentValue animation:isAnimation];
}
- (void)setCurrentValue:(CGFloat)currentValue {
    _currentValue = currentValue;
    [self.sliderView setCurrentValue:currentValue animation:NO];
}
- (void)setProgressValue:(CGFloat)progressValue {
    _progressValue = progressValue;
    self.progressView.progress = progressValue;
}
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    if([view isKindOfClass:[HXSlider class]]){
        self.panGesture.enabled = NO;
    }else {
        self.panGesture.enabled = YES;
    }
    return view;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.playBtn.hx_x = 5;
    self.playBtn.hx_size = CGSizeMake(30, 30.f);
    self.playBtn.hx_centerY = self.hx_h / 2.f;
    
    self.currentTimeLb.hx_size = CGSizeMake(60, 30.f);
    self.currentTimeLb.hx_x = CGRectGetMaxX(self.playBtn.frame);
    self.currentTimeLb.hx_centerY = self.hx_h / 2.f;
    
    self.totalTimeLb.hx_size = CGSizeMake(60, 30.f);
    self.totalTimeLb.hx_x = self.hx_w - self.totalTimeLb.hx_w - 10;
    self.totalTimeLb.hx_centerY = self.hx_h / 2.f;
    
    CGFloat progressX = CGRectGetMaxX(self.currentTimeLb.frame) + 5;
    CGFloat progressW = self.hx_w - progressX - 10 - (self.hx_w - self.totalTimeLb.hx_x);
    
    self.progressView.frame = CGRectMake(progressX, 0, progressW, 2);
    self.progressView.hx_centerY = self.hx_h / 2.f;
    
    self.sliderView.frame = CGRectMake(progressX, 0, progressW, 30);
    self.sliderView.hx_centerY = self.hx_h / 2.f;

    self.effectView.frame = self.bounds;
}

- (HXSlider *)sliderView {
    if (!_sliderView) {
        _sliderView = [[HXSlider alloc] init];
        HXWeakSelf
        _sliderView.sliderChanged = ^(CGFloat value) {
            if (weakSelf.sliderChangedValueBlock) {
                weakSelf.sliderChangedValueBlock(value, HXPreviewVideoSliderTypeChanged);
            }
        };
        _sliderView.sliderTouchDown = ^(CGFloat value) {
            if (weakSelf.sliderChangedValueBlock) {
                weakSelf.sliderChangedValueBlock(value, HXPreviewVideoSliderTypeTouchDown);
            }
        };
        _sliderView.sliderTouchUpInSide = ^(CGFloat value) {
            if (weakSelf.sliderChangedValueBlock) {
                weakSelf.sliderChangedValueBlock(value, HXPreviewVideoSliderTypeTouchUpInSide);
            }
        };
    }
    return _sliderView;
}
- (UIProgressView *)progressView {
    if (!_progressView) {
        _progressView = [[UIProgressView alloc] init];
        _progressView.trackTintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3f];
        _progressView.progressTintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.6f];
    }
    return _progressView;
}
- (UIButton *)playBtn {
    if (!_playBtn) {
        _playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playBtn setImage:[UIImage hx_imageNamed:@"hx_video_play"] forState:UIControlStateNormal];
        [_playBtn setImage:[UIImage hx_imageNamed:@"hx_video_ pause"] forState:UIControlStateSelected];
        [_playBtn addTarget:self action:@selector(didPlayBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        [_playBtn hx_setEnlargeEdgeWithTop:20 right:20 bottom:20 left:20];
    }
    return _playBtn;
}
- (void)didPlayBtnClick:(UIButton *)button {
    button.selected = !button.isSelected;
    if (self.didPlayBtnBlock) {
        self.didPlayBtnBlock(button.selected);
    }
}
- (void)setPlayBtnSelected:(BOOL)playBtnSelected {
    self.playBtn.selected = playBtnSelected;
}
- (BOOL)playBtnSelected {
    return self.playBtn.selected;
}
- (UILabel *)currentTimeLb {
    if (!_currentTimeLb) {
        _currentTimeLb = [[UILabel alloc] init];
        _currentTimeLb.text = @"00:00";
        _currentTimeLb.textColor = [UIColor whiteColor];
        _currentTimeLb.font = [UIFont systemFontOfSize:13];
        _currentTimeLb.textAlignment = NSTextAlignmentCenter;
    }
    return _currentTimeLb;
}
- (void)setCurrentTime:(NSString *)currentTime {
    _currentTime = currentTime;
    self.currentTimeLb.text = currentTime;
}
- (UILabel *)totalTimeLb {
    if (!_totalTimeLb) {
        _totalTimeLb = [[UILabel alloc] init];
        _totalTimeLb.text = @"--:--";
        _totalTimeLb.textColor = [UIColor whiteColor];
        _totalTimeLb.font = [UIFont systemFontOfSize:13];
        _totalTimeLb.textAlignment = NSTextAlignmentCenter;
    }
    return _totalTimeLb;
}
- (void)setTotalTime:(NSString *)totalTime {
    _totalTime = totalTime;
    self.totalTimeLb.text = totalTime;
}
- (UIVisualEffectView *)effectView {
    if (!_effectView) {
        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        _effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
    }
    return _effectView;
}
@end

@interface HXSlider ()<UIGestureRecognizerDelegate>
@property (strong, nonatomic) UIImageView *thumbView;
@property (strong, nonatomic) UIView *lineView;
@property (assign, nonatomic) CGRect thumbViewFrame;
@property (strong, nonatomic) HXPanGestureRecognizer *panGesture;
@end

@implementation HXSlider
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.currentValue = 0;
        [self addSubview:self.lineView];
        [self addSubview:self.thumbView];
        self.panGesture = [[HXPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognizerClick:)];
        self.panGesture.delegate = self;
        [self addGestureRecognizer:self.panGesture];
    }
    return self;
}
- (void)panGestureRecognizerClick:(HXPanGestureRecognizer *)gestRecog {
    switch (gestRecog.state) {
        case UIGestureRecognizerStateBegan: {
            CGPoint point = [gestRecog locationInView:self];
            if (point.x < self.thumbView.hx_x - 20 ||
                point.x > CGRectGetMaxX(self.thumbView.frame) + 20) {
                gestRecog.enabled = NO;
                gestRecog.enabled = YES;
                return;
            }
            if (point.y < self.thumbView.hx_y - 20 ||
                point.y > CGRectGetMaxY(self.thumbView.frame) + 20) {
                gestRecog.enabled = NO;
                gestRecog.enabled = YES;
                return;
            }
            if (self.sliderTouchDown) {
                self.sliderTouchDown(self.currentValue);
            }
            if (CGRectEqualToRect(self.thumbViewFrame, CGRectZero)) {
                self.thumbViewFrame = self.thumbView.frame;
            }
        } break;
        case UIGestureRecognizerStateChanged: {
            CGPoint specifiedPoint = [gestRecog translationInView:self];
            CGRect rect = self.thumbViewFrame;
            rect.origin.x += specifiedPoint.x;
            if (rect.origin.x < 0) {
                rect.origin.x = 0;
            }
            if (rect.origin.x > self.hx_w - self.thumbView.hx_w) {
                rect.origin.x = self.hx_w - self.thumbView.hx_w;
            }
            self.thumbView.frame = rect;
            CGFloat lineW = CGRectGetMaxX(self.thumbView.frame);
            if (lineW < 0) {
                lineW = 0;
            }
            if (lineW > self.hx_w) {
                lineW = self.hx_w;
            }
            self.lineView.hx_w = lineW;
            _currentValue = self.thumbView.hx_x / (self.hx_w - self.thumbView.hx_w);
            if (self.sliderChanged) {
                self.sliderChanged(self.currentValue);
            }
        } break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed: {
            if (self.sliderTouchUpInSide) {
                self.sliderTouchUpInSide(self.currentValue);
            }
            self.thumbViewFrame = CGRectZero;
        } break;
        default:
            break;
    }
}
- (void)setCurrentValue:(CGFloat)currentValue animation:(BOOL)isAnimation {
    if (_currentValue == 1 && currentValue == 0) {
        isAnimation = NO;
    }
    if (self.panGesture.state == UIGestureRecognizerStateChanged ||
        self.panGesture.state == UIGestureRecognizerStateBegan ||
        self.panGesture.state == UIGestureRecognizerStateEnded) {
        return;
    }
    if (currentValue < 0) {
        currentValue = 0;
    }
    if (currentValue > 1) {
        currentValue = 1;
    }
    if (isAnimation) {
        [UIView animateWithDuration:0.1f delay:0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveLinear | UIViewAnimationOptionOverrideInheritedDuration | UIViewAnimationOptionOverrideInheritedCurve animations:^{
            self.currentValue = currentValue;
        } completion:nil];
    }else {
        self.currentValue = currentValue;
    }
}
- (void)setCurrentValue:(CGFloat)currentValue {
    _currentValue = currentValue;
    if (currentValue < 0) {
        currentValue = 0;
    }
    if (currentValue > 1) {
        currentValue = 1;
    }
    CGFloat thumbX = (self.hx_w - self.thumbView.hx_w) * currentValue;
    if (thumbX > self.hx_w - self.thumbView.hx_w) {
        thumbX = self.hx_w - self.thumbView.hx_w;
    }
    if (thumbX < 0) {
        thumbX = 0;
    }
    self.lineView.hx_w = thumbX + self.thumbView.hx_w;
    self.thumbView.hx_x = thumbX;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.lineView.hx_centerY = self.hx_h / 2.f;
    self.thumbView.hx_centerY = self.hx_h / 2.f;
}
- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.thumbView.hx_size.width, 2)];
        _lineView.backgroundColor = [UIColor whiteColor];
    }
    return _lineView;
}
- (UIImageView *)thumbView {
    if (!_thumbView) {
        _thumbView = [[UIImageView alloc] initWithImage:[UIImage hx_imageNamed:@"hx_video_progress"]];
        _thumbView.hx_size = _thumbView.image.size;
    }
    return _thumbView;
}
@end

@implementation HXPanGestureRecognizer
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    self.state = UIGestureRecognizerStateBegan;
    if ([self.delegate isKindOfClass:[HXPhotoBottomSelectView class]]) {
        [(HXPhotoBottomSelectView *)self.delegate panGestureReconClick:self];
    }
}
@end

