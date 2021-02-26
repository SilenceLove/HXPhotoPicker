//
//  HXVideoEditViewController.m
//  HXPhotoPickerExample
//
//  Created by Silence on 2017/12/31.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import "HXVideoEditViewController.h"
#import "HXPhotoEditTransition.h"

#define hxValidRectX 30
#define hxImageWidth 8
#define hxVideoY ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeLeft || [[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeRight) ? 10 : hxTopMargin + 10
#define hxCollectionViewY 25

@interface HXVideoEditViewController ()
<
HXVideoEditBottomViewDelegate
>
@property (strong, nonatomic) HXVideoEditBottomView *bottomView;
@property (assign, nonatomic) BOOL orientationDidChange;
@property (assign, nonatomic) PHImageRequestID requestId;
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) NSTimer *indicatorLineTimer;
@property (assign, nonatomic) CGFloat itemHeight;
@property (assign, nonatomic) CGFloat itemWidth;
@property (assign, nonatomic) CGFloat validRectX;
@property (strong, nonatomic) HXPhotoModel *afterModel;
@property (strong, nonatomic) UITapGestureRecognizer *cancelTap;
@property (strong, nonatomic) NSURLSessionDownloadTask *downloadTask;
@end

@implementation HXVideoEditViewController
- (void)dealloc {
    if (HXShowLog) NSSLog(@"dealloc");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
#pragma clang diagnostic pop
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopTimer];
    if (self.downloadTask) {
        [self.downloadTask cancel];
    }
    [[PHImageManager defaultManager] cancelImageRequest:self.requestId];
    [self.navigationController setNavigationBarHidden:NO];
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.orientationDidChange) {
        self.orientationDidChange = NO;
        [self changeSubviewFrame];
        self.bottomView.avAsset = self.avAsset;
        [self updateBottomVideoTimeLbs];
        [self startTimer];
    }
}
- (BOOL)prefersStatusBarHidden {
    return YES;
}
- (instancetype)init {
    self = [super init];
    if (self) {
        self.transitioningDelegate = self;
        self.modalPresentationStyle = UIModalPresentationCustom;
    }
    return self;
}
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    return [HXPhotoEditTransition transitionWithType:HXPhotoEditTransitionTypePresent model:self.model];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    return [HXPhotoEditTransition transitionWithType:HXPhotoEditTransitionTypeDismiss model:self.isCancel ? self.model : self.afterModel];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.itemHeight = 60;
    CGFloat cellHeight = self.itemHeight - 4;
    self.itemWidth = cellHeight / 16 * 9;
    CGFloat imgWidth = self.model.imageSize.width;
    CGFloat imgHeight = self.model.imageSize.height;
    imgWidth = cellHeight / imgHeight * imgWidth;
    if (imgWidth > self.itemWidth) {
        CGFloat w = cellHeight / imgHeight * self.model.imageSize.width;
        if (w > cellHeight / 9 * 16) {
            w = cellHeight / 9 * 16;
        }
        self.itemWidth = w;
    }
    self.validRectX = 30;
    self.bottomView.itemWidth = self.itemWidth;
    self.bottomView.itemHeight = self.itemHeight;
    self.bottomView.validRectX = self.validRectX;
    
    [self setupUI];
    [self changeSubviewFrame];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationWillChanged:) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)completeTransition {
    self.transitionCompletion = YES;
    if (self.requestComplete) {
        [self setupVideo];
    }else {
        [self.view hx_showLoadingHUDText:[NSBundle hx_localizedStringForKey:@"加载中"]];
    }
}
- (void)showBottomView {
    if (self.requestComplete) {
        self.bottomView.alpha = 1;
    }
}
- (CGRect)getVideoRect {
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGFloat bottomMargin = hxBottomMargin;
    if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
        bottomMargin = 0;
    }
    CGFloat bottomH = hxCollectionViewY + self.itemHeight + 5 + 50;
    CGFloat videoH = self.view.hx_h - bottomH - (hxVideoY) - bottomMargin;
    CGFloat videoW = self.view.hx_w - hxValidRectX * 2;
    CGFloat width = videoW;
    CGFloat height = videoH;
    CGFloat imgWidth = self.model.imageSize.width;
    CGFloat imgHeight = self.model.imageSize.height;
    CGFloat w;
    CGFloat h;
    imgHeight = width / imgWidth * imgHeight;
    if (imgHeight > height) {
        w = height / self.model.imageSize.height * imgWidth;
        h = height;
    }else {
        w = width;
        h = imgHeight;
    }
    
    return CGRectMake(hxValidRectX + (videoW - w) / 2, hxVideoY + (videoH - h) / 2, w, h);
}
- (void)changeSubviewFrame {
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGFloat itemH = self.itemHeight;
    CGFloat bottomMargin = hxBottomMargin;
    CGFloat bottomX = 0;
    CGFloat bottomH = hxCollectionViewY + itemH + 5 + 50;
    if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
        bottomX = hxBottomMargin;
        bottomMargin = 0;
    }
    self.bottomView.editView.validRect = CGRectZero;
    self.bottomView.frame = CGRectMake(bottomX, self.view.hx_h - bottomH - bottomMargin, self.view.hx_w - bottomX * 2, bottomH + bottomMargin);
    self.videoView.frame = [self getVideoRect];
    self.playerLayer.frame = self.videoView.bounds;
}
- (void)setupUI {
    self.view.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.videoView];
    [self.view addSubview:self.bottomView];
    
    [self getVideo];
}
- (void)getVideo {
    self.bottomView.userInteractionEnabled = NO;
    self.bottomView.alpha = 0;
    self.bottomView.model = self.model;
    if (self.avAsset && self.transitionCompletion) {
        [self setupVideo];
    }else {
        self.cancelTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showCancelAlert)];
        [self.view addGestureRecognizer:self.cancelTap];
        if (!self.isInside) {
            [self.view hx_showLoadingHUDText:[NSBundle hx_localizedStringForKey:@"加载中"]];
        }
        HXWeakSelf
        if (self.model.cameraVideoType == HXPhotoModelMediaTypeCameraVideoTypeNetWork) {
            self.downloadTask = [[HXPhotoCommon photoCommon] downloadVideoWithURL:self.model.videoURL progress:nil downloadSuccess:^(NSURL * _Nullable filePath, NSURL * _Nullable videoURL) {
                [weakSelf.view removeGestureRecognizer:weakSelf.cancelTap];
                [weakSelf.view hx_handleLoading];
                weakSelf.avAsset = [AVAsset assetWithURL:filePath];
                weakSelf.requestComplete = YES;
                if (!weakSelf.isInside) {
                    [weakSelf setupVideo];
                }else {
                    if (weakSelf.transitionCompletion) {
                        [weakSelf setupVideo];
                    }
                }
            } downloadFailure:^(NSError * _Nullable error, NSURL * _Nullable videoURL) {
                [weakSelf.view hx_handleLoading];
                [weakSelf showErrorAlert];
            }];
            return;
        }
        self.requestId = [self.model requestAVAssetStartRequestICloud:^(PHImageRequestID iCloudRequestId, HXPhotoModel *model) {
            weakSelf.requestId = iCloudRequestId;
        } progressHandler:nil success:^(AVAsset *avAsset, AVAudioMix *audioMix, HXPhotoModel *model, NSDictionary *info) {
            [weakSelf.view removeGestureRecognizer:weakSelf.cancelTap];
            [weakSelf.view hx_handleLoading];
            weakSelf.avAsset = avAsset;
            weakSelf.requestComplete = YES;
            if (!weakSelf.isInside) {
                [weakSelf setupVideo];
            }else {
                if (weakSelf.transitionCompletion) {
                    [weakSelf setupVideo];
                }
            }
        } failed:^(NSDictionary *info, HXPhotoModel *model) {
            [weakSelf.view hx_handleLoading];
            [weakSelf showErrorAlert];
        }];
    }
}
- (void)showErrorAlert {
    HXWeakSelf
    hx_showAlert(weakSelf, [NSBundle hx_localizedStringForKey:@"获取视频失败!"], nil, [NSBundle hx_localizedStringForKey:@"返回"], [NSBundle hx_localizedStringForKey:@"获取"], ^{
        [weakSelf videoEditBottomViewDidCancelClick:nil];
    }, ^{
        [weakSelf getVideo];
    });
}
- (void)showCancelAlert {
    if (self.transitionCompletion && !self.requestComplete) {
        HXWeakSelf
        hx_showAlert(self, [NSBundle hx_localizedStringForKey:@"是否取消吗?"], nil, [NSBundle hx_localizedStringForKey:@"取消"], [NSBundle hx_localizedStringForKey:@"继续"], ^{
            [weakSelf videoEditBottomViewDidCancelClick:nil];
        }, nil);
    }
}
- (void)setupVideo {
    self.player = [AVPlayer playerWithPlayerItem:[AVPlayerItem playerItemWithAsset:self.avAsset]];
    self.playerLayer.player = self.player;
    self.bottomView.avAsset = self.avAsset;
    
    [self updateBottomVideoTimeLbs];
    if (!self.isInside || self.transitionCompletion) {
        [UIView animateWithDuration:0.25 animations:^{
            self.bottomView.alpha = 1;
        } completion:^(BOOL finished) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.bgImageView removeFromSuperview];
                [self.player play];
                self.bottomView.playBtn.selected = YES;
                [self startTimer];
            });
        }];
    }
    self.bottomView.userInteractionEnabled = YES;
}
- (void)updateBottomVideoTimeLbs {
    NSInteger startSecond = [self getStartSecond];
    NSInteger videoRect = [self getValidRectVideoTime];
    NSInteger endSecond = startSecond + videoRect;
    
    if (startSecond > [self getVideoTime]) {
        startSecond = roundf([self getVideoTime]);
    }
    if (endSecond > [self getVideoTime]) {
        endSecond = roundf([self getVideoTime]);
    }
    self.bottomView.startTimeLb.text = [HXPhotoTools transformVideoTimeToString:startSecond];
    self.bottomView.endTimeLb.text = [HXPhotoTools transformVideoTimeToString:endSecond];
    self.bottomView.totalTimeLb.text = [HXPhotoTools transformVideoTimeToString:videoRect];
    [self.bottomView updateTimeLbsFrame];
}
- (void)deviceOrientationChanged:(NSNotification *)notify {
    self.orientationDidChange = YES;
}
- (void)deviceOrientationWillChanged:(NSNotification *)notify {
    [self stopTimer];
}

- (void)appResignActive {
    [self stopTimer];
}

- (void)appBecomeActive {
    [self startTimer];
}
- (void)startTimer {
    [self stopTimer];
    if (!self.avAsset || self.bottomView.interval == -1) {
        return;
    }
    NSTimeInterval duration = [self getValidRectVideoTime];
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:duration target:self selector:@selector(playPartVideo:) userInfo:nil repeats:YES];
    [self.timer fire];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    
    [self.bottomView startLineAnimationWithDuration:duration];
}
- (void)stopTimer {
    
    [self.indicatorLineTimer invalidate];
    self.indicatorLineTimer = nil;
    
    [self.timer invalidate];
    self.timer = nil;
    [self.bottomView removeLineView];
    [self.playerLayer.player pause];
    self.bottomView.playBtn.selected = NO;
}
- (void)playPartVideo:(NSTimer *)timer {
    self.bottomView.playBtn.selected = YES;
    [self.playerLayer.player seekToTime:[self getStartTime] toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    [self.playerLayer.player play];
}
- (NSTimeInterval)getStartSecond {
    CGFloat offsetX = self.bottomView.collectionView.contentOffset.x;
    CGFloat contentW = self.bottomView.contentWidth;
    CGFloat rectX = self.bottomView.editView.validRect.origin.x - 30 - hxImageWidth;
    
    NSTimeInterval second = (offsetX + rectX) / contentW * roundf([self getVideoTime]);
    if (second < 0) {
        second = 0;
    }
    return roundf(second);
}
- (CMTime)getStartTime {
    NSTimeInterval second = [self getStartSecond];
    if (second > [self getVideoTime]) {
        second = roundf([self getVideoTime]);
    }
    return CMTimeMakeWithSeconds(second, self.playerLayer.player.currentTime.timescale);
}
- (NSTimeInterval)getValidRectVideoTime {
    CGFloat rectW = self.bottomView.editView.validRect.size.width;
    CGFloat contentW = self.bottomView.contentWidth;
    NSTimeInterval second = rectW / contentW * roundf([self getVideoTime]);
    return roundf(second);
}
- (CMTimeRange)getTimeRange {
    NSTimeInterval startSecond = [self getStartSecond];
    CMTime start = CMTimeMakeWithSeconds(startSecond, self.playerLayer.player.currentTime.timescale);
    NSTimeInterval second = [self getValidRectVideoTime];
    CMTime duration = CMTimeMakeWithSeconds(second, self.playerLayer.player.currentTime.timescale);
    return CMTimeRangeMake(start, duration);
}
- (NSTimeInterval)getVideoTime {
    if (self.model.asset) {
        return self.model.asset.duration;
    }else {
        return CMTimeGetSeconds(self.avAsset.duration);
    }
}
#pragma mark - < HXVideoEditBottomViewDelegate >
- (void)videoEditBottomViewDidCancelClick:(HXVideoEditBottomView *)bottomView {
    [self.bottomView.collectionView setContentOffset:self.bottomView.collectionView.contentOffset animated:NO];
    self.isCancel = YES;
    if ([self.delegate respondsToSelector:@selector(videoEditViewControllerDidCancelClick:)]) {
        [self.delegate videoEditViewControllerDidCancelClick:self];
    }
    if (self.cancelBlock) {
        self.cancelBlock(self);
    }
    [self dismissViewControllerCompletion:nil];
}
- (void)videoEditBottomViewDidDoneClick:(HXVideoEditBottomView *)bottomView {
    self.isCancel = NO;
    [self.bottomView.collectionView setContentOffset:self.bottomView.collectionView.contentOffset animated:NO];
    [self.view hx_showLoadingHUDText:[NSBundle hx_localizedStringForKey:@"处理中"]];
    self.bottomView.userInteractionEnabled = NO;
    HXWeakSelf
    [HXPhotoTools exportEditVideoForAVAsset:self.avAsset timeRange:[self getTimeRange] presetName:self.manager.configuration.editVideoExportPresetName success:^(NSURL *videoURL) {
        if (weakSelf.manager.configuration.editAssetSaveSystemAblum) {
            [HXPhotoTools saveVideoToCustomAlbumWithName:weakSelf.manager.configuration.customAlbumName videoURL:videoURL location:weakSelf.model.location complete:^(HXPhotoModel * _Nullable model, BOOL success) {
                weakSelf.bottomView.userInteractionEnabled = YES;
                [weakSelf.view hx_handleLoading];
                if (model) {
                    weakSelf.afterModel = model;
                    [weakSelf editVideoCompletion];
                }else {
                    [weakSelf.view hx_showImageHUDText:[NSBundle hx_localizedStringForKey:@"处理失败，请重试"]];
                }
            }];
        }else {
            weakSelf.bottomView.userInteractionEnabled = YES;
            HXPhotoModel *photoModel = [HXPhotoModel photoModelWithVideoURL:videoURL];
            weakSelf.afterModel = photoModel;
            [weakSelf editVideoCompletion];
        }
    } failed:^(NSError *error) {
        weakSelf.bottomView.userInteractionEnabled = YES;
        [weakSelf.view hx_handleLoading];
        [weakSelf.view hx_showImageHUDText:[NSBundle hx_localizedStringForKey:@"处理失败，请重试"]];
    }];
}
- (void)editVideoCompletion {
    if (!self.outside) {
        if ([self.delegate respondsToSelector:@selector(videoEditViewControllerDidDoneClick:beforeModel:afterModel:)]) {
            [self.delegate videoEditViewControllerDidDoneClick:self beforeModel:self.model afterModel:self.afterModel];
        }
        if (self.doneBlock) {
            self.doneBlock(self.model, self.afterModel, self);
        }
        [self dismissViewControllerCompletion:nil];
    }else {
        [self dismissViewControllerCompletion:^{
            if ([self.delegate respondsToSelector:@selector(videoEditViewControllerDidDoneClick:beforeModel:afterModel:)]) {
                [self.delegate videoEditViewControllerDidDoneClick:self beforeModel:self.model afterModel:self.afterModel];
            }
            if (self.doneBlock) {
                self.doneBlock(self.model, self.afterModel, self);
            }
        }];
    }
}
- (void)dismissViewControllerCompletion:(void (^)(void))completion {
    [self stopTimer];
    if (self.afterModel) {
        [self.playerLayer.player seekToTime:[self getStartTime] toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    }else {
        [self.playerLayer.player seekToTime:CMTimeMakeWithSeconds(0, self.playerLayer.player.currentTime.timescale) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    }
    if (self.navigationController.viewControllers.count > 1) {
        [self.navigationController popViewControllerAnimated:NO];
    }else {
        if (self.isCancel) {
            [self dismissViewControllerAnimated:YES completion:completion];
        }else {
            [self dismissViewControllerAnimated:!self.outside completion:completion];
        }
    }
}
- (void)videoEditBottomViewValidRectChanged:(HXVideoEditBottomView *)bottomView {
    [self stopTimer];
    [self.playerLayer.player seekToTime:[self getStartTime] toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    [self updateBottomVideoTimeLbs];
}
- (void)videoEditBottomViewValidRectEndChanged:(HXVideoEditBottomView *)bottomView {
    [self startTimer];
    [self updateBottomVideoTimeLbs];
}
- (void)videoEditBottomViewIndicatorLinePanGestureBegan:(HXVideoEditBottomView *)bottomView frame:(CGRect)frame second:(CGFloat)second {
    [self.indicatorLineTimer invalidate];
    self.indicatorLineTimer = nil;
    [self.timer invalidate];
    self.timer = nil;
    [self.playerLayer.player pause];
    self.bottomView.playBtn.selected = NO;
    
    [self.bottomView.indicatorLine.layer removeAllAnimations];
    bottomView.indicatorLine.frame = frame;
    
    [self.playerLayer.player seekToTime:CMTimeMakeWithSeconds(second, self.playerLayer.player.currentTime.timescale) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}
- (void)videoEditBottomViewIndicatorLinePanGestureChanged:(HXVideoEditBottomView *)bottomView second:(CGFloat)second {
    [self.playerLayer.player seekToTime:CMTimeMakeWithSeconds(second, self.playerLayer.player.currentTime.timescale) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}
- (void)videoEditBottomViewIndicatorLinePanGestureEnd:(HXVideoEditBottomView *)bottomView frame:(CGRect)frame second:(CGFloat)second {
    CGFloat validX = self.bottomView.editView.validRect.origin.x;
    CGFloat centerX = (frame.origin.x + frame.size.width) - validX;
    CGFloat rectW = self.bottomView.editView.validRect.size.width - centerX;
    CGFloat contentW = self.bottomView.contentWidth;
    NSTimeInterval duration = rectW / contentW * [self getVideoTime];
    
    self.indicatorLineTimer = [NSTimer scheduledTimerWithTimeInterval:duration target:self selector:@selector(indicatorLinePlayPartVideo:) userInfo:nil repeats:NO];
    [self.playerLayer.player seekToTime:CMTimeMakeWithSeconds(second, self.playerLayer.player.currentTime.timescale) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    [self.playerLayer.player play];
    self.bottomView.playBtn.selected = YES;
    [self.bottomView panGestureStarAnimationWithDuration:duration];
}
- (void)indicatorLinePlayPartVideo:(NSTimer *)timer {
    [self startTimer];
}
#pragma mark - < 懒加载 >
- (HXVideoEditBottomView *)bottomView {
    if (!_bottomView) {
        _bottomView = [[HXVideoEditBottomView alloc] initWithManager:self.manager];
        _bottomView.delegate = self;
        
        HXWeakSelf
        _bottomView.scrollViewDidScroll = ^{
            if (!weakSelf.playerLayer.player) {
                return;
            }
            [weakSelf stopTimer];
            [weakSelf.playerLayer.player seekToTime:[weakSelf getStartTime] toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
            [weakSelf updateBottomVideoTimeLbs];
        };
        _bottomView.startTimer = ^{
            if (weakSelf.isCancel) {
                return;
            }
            [weakSelf startTimer];
            [weakSelf updateBottomVideoTimeLbs];
        };
    }
    return _bottomView;
}
- (AVPlayerLayer *)playerLayer {
    if (!_playerLayer) {
        _playerLayer = [[AVPlayerLayer alloc] init];
        _playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    return _playerLayer;
}
- (UIView *)videoView {
    if (!_videoView) {
        _videoView = [[UIView alloc] init];
        [_videoView.layer addSublayer:self.playerLayer];
    }
    return _videoView;
}
@end

@interface HXVideoEditBottomView ()
<
UICollectionViewDataSource,
UICollectionViewDelegate,
UICollectionViewDelegateFlowLayout,
HXEditFrameViewDelegate
>
@property (strong, nonatomic) UIButton *cancelBtn;
@property (strong, nonatomic) UIButton *doneBtn;
@property (strong, nonatomic) UICollectionViewFlowLayout *flowLayout;
@property (strong, nonatomic) HXPhotoManager *manager;
@property (strong, nonatomic) AVAssetImageGenerator *generator;
@property (strong, nonatomic) NSOperationQueue *operationQueue;
@property (strong, nonatomic) NSMutableDictionary *operationDict;
@property (assign, nonatomic) NSInteger dataCount;
@property (assign, nonatomic) NSInteger videoSecond;
@property (assign, nonatomic) CGRect currentIndicatorLineFrame; 
@end

@implementation HXVideoEditBottomView
- (void)dealloc {
    if (HXShowLog) NSSLog(@"dealloc");
    [self.operationQueue cancelAllOperations];
}
- (instancetype)initWithManager:(HXPhotoManager *)manager {
    self = [super init];
    if (self) {
        self.manager = manager;
        [self setup];
    }
    return self;
}
- (void)setup {
    self.interval = -1;
    [self addSubview:self.cancelBtn];
    [self addSubview:self.playBtn];
    [self addSubview:self.doneBtn];
    [self addSubview:self.collectionView];
    [self addSubview:self.editView];
    
    [self addSubview:self.startTimeLb];
    [self addSubview:self.endTimeLb];
    [self addSubview:self.totalTimeLb];
}
- (void)didCancelBtnClick {
    if ([self.delegate respondsToSelector:@selector(videoEditBottomViewDidCancelClick:)]) {
        [self.delegate videoEditBottomViewDidCancelClick:self];
    }
}
- (void)didplayBtnClick:(UIButton *)button {
    CGRect indicatorLineFrame = [[self.indicatorLine.layer presentationLayer] frame];
    CGFloat offsetX = self.collectionView.contentOffset.x;
    CGFloat centerX = CGRectGetMaxX(indicatorLineFrame) + CGRectGetWidth(indicatorLineFrame) - hxValidRectX - hxImageWidth;
    CGFloat currentSecond = (offsetX + centerX) / self.contentWidth * CMTimeGetSeconds(self.avAsset.duration);
    if (currentSecond < 0) {
        currentSecond = 0;
    }
    if (button.selected) {
        self.currentIndicatorLineFrame = indicatorLineFrame;
        if ([self.delegate respondsToSelector:@selector(videoEditBottomViewIndicatorLinePanGestureBegan:frame:second:)]) {
            [self.delegate videoEditBottomViewIndicatorLinePanGestureBegan:self frame:self.currentIndicatorLineFrame second:currentSecond];
        }
    }else {
        if ([self.delegate respondsToSelector:@selector(videoEditBottomViewIndicatorLinePanGestureEnd:frame: second:)]) {
            [self.delegate videoEditBottomViewIndicatorLinePanGestureEnd:self frame:self.indicatorLine.frame second:currentSecond];
        }
    }
}
- (void)didDoneBtnClick {
    if ([self.delegate respondsToSelector:@selector(videoEditBottomViewDidDoneClick:)]) {
        [self.delegate videoEditBottomViewDidDoneClick:self];
    }
}
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    CGRect rect = [[self.indicatorLine.layer presentationLayer] frame];
    rect.origin.x -= 5;
    rect.size.width += 10;
    if (CGRectContainsPoint(rect, point)) {
        return self.indicatorLine;
    }
    return [super hitTest:point withEvent:event];
}
- (void)removeLineView {
    [self.indicatorLine.layer removeAllAnimations];
    [self.indicatorLine removeFromSuperview];
}
- (void)panGestureStarAnimationWithDuration:(NSTimeInterval)duration {
    [UIView animateWithDuration:duration delay:.0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveLinear | UIViewAnimationOptionOverrideInheritedDuration | UIViewAnimationOptionOverrideInheritedCurve animations:^{
        self.indicatorLine.hx_x = CGRectGetMaxX(self.editView.validRect) - 1.5;
    } completion:nil];
}
- (void)startLineAnimationWithDuration:(NSTimeInterval)duration {
    self.indicatorLine.frame = CGRectMake(self.editView.validRect.origin.x, self.collectionView.hx_y + 2, 2, self.itemHeight - 4);
    [self addSubview:self.indicatorLine];
    [UIView animateWithDuration:duration delay:.0 options:UIViewAnimationOptionRepeat|UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveLinear | UIViewAnimationOptionOverrideInheritedDuration | UIViewAnimationOptionOverrideInheritedCurve animations:^{
        self.indicatorLine.hx_x = CGRectGetMaxX(self.editView.validRect) - 1.5;
    } completion:nil];
}
- (void)panGestureAction:(UIPanGestureRecognizer *)panGesture {
    CGPoint point = [panGesture translationInView:self];
    CGRect rct = self.editView.validRect;
    CGFloat minX = rct.origin.x;
    CGFloat maxX = CGRectGetMaxX(rct) - 1.5;
    
    CGFloat offsetX = self.collectionView.contentOffset.x;
    CGFloat centerX = self.indicatorLine.hx_centerX - hxValidRectX - hxImageWidth;
    CGFloat currentSecond = (offsetX + centerX) / self.contentWidth * CMTimeGetSeconds(self.avAsset.duration);
    if (currentSecond < 0) {
        currentSecond = 0;
    }
    switch (panGesture.state) {
        case UIGestureRecognizerStateBegan: {
            CGRect indicatorLineFrame = [[self.indicatorLine.layer presentationLayer] frame];
            centerX = CGRectGetMaxX(indicatorLineFrame) + CGRectGetWidth(indicatorLineFrame) - hxValidRectX - hxImageWidth;
            currentSecond = (offsetX + centerX) / self.contentWidth * CMTimeGetSeconds(self.avAsset.duration);
            if (currentSecond < 0) {
                currentSecond = 0;
            }
            self.currentIndicatorLineFrame = indicatorLineFrame;
            if ([self.delegate respondsToSelector:@selector(videoEditBottomViewIndicatorLinePanGestureBegan:frame:second:)]) {
                [self.delegate videoEditBottomViewIndicatorLinePanGestureBegan:self frame:self.currentIndicatorLineFrame second:currentSecond];
            }
        } break;
        case UIGestureRecognizerStateChanged: {
            CGRect lineRect = self.currentIndicatorLineFrame;
            lineRect.origin.x += point.x;
            if (lineRect.origin.x < minX) {
                lineRect.origin.x = minX;
            }else if (lineRect.origin.x > maxX) {
                lineRect.origin.x = maxX;
            }
            self.indicatorLine.frame = lineRect;
            
            if ([self.delegate respondsToSelector:@selector(videoEditBottomViewIndicatorLinePanGestureChanged:second:)]) {
                [self.delegate videoEditBottomViewIndicatorLinePanGestureChanged:self second:currentSecond];
            }
        } break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            if ([self.delegate respondsToSelector:@selector(videoEditBottomViewIndicatorLinePanGestureEnd:frame: second:)]) {
                [self.delegate videoEditBottomViewIndicatorLinePanGestureEnd:self frame:self.indicatorLine.frame second:currentSecond];
            }
        }
        default:
            break;
    }
}
- (void)setValidRectX:(CGFloat)validRectX {
    _validRectX = validRectX;
    self.editView.itemWidth = self.itemWidth;
    self.editView.itemHeight = self.itemHeight;
    self.editView.validRectX = validRectX;
}
- (void)setAvAsset:(AVAsset *)avAsset {
    _avAsset = avAsset;
    
    self.interval = 1;
    CGFloat second = roundf(CMTimeGetSeconds(self.avAsset.duration));
    if (second <= 0) second = 1;
    self.editView.videoTime = second;
    self.videoSecond = second;
    CGFloat maxWidth = self.hx_w - hxValidRectX * 2 - hxImageWidth * 2;
    // 一个item代表多少秒
    CGFloat singleItemSecond;
    NSInteger maxVideoTime = self.manager.configuration.maxVideoClippingTime;
    if (self.manager.configuration.maxVideoClippingTime > self.manager.configuration.videoMaximumSelectDuration) {
        maxVideoTime = self.manager.configuration.videoMaximumSelectDuration;
    }
    if (second <= maxVideoTime) {
        CGFloat itemCount = maxWidth / self.itemWidth;
        singleItemSecond = second / itemCount;
        self.contentWidth = maxWidth;
        self.dataCount = ceilf(itemCount);
        self.interval = singleItemSecond;
    }else if (second > maxVideoTime) {
        CGFloat singleSecondWidth = maxWidth / (CGFloat)maxVideoTime;
        singleItemSecond = self.itemWidth / singleSecondWidth;
        self.contentWidth = singleSecondWidth * second;
        self.dataCount = ceilf(self.contentWidth / self.itemWidth);
        self.interval = singleItemSecond;
    }
    self.editView.contentWidth = self.contentWidth;
    [self.collectionView reloadData];
    [self layoutSubviews];
}
- (CMTime)getTimeWithIndex:(CGFloat)index {
    CGFloat second = index;
    CMTime time;
    time = CMTimeMakeWithSeconds(second * self.interval, self.avAsset.duration.timescale + 100);
    return time;
}
- (NSBlockOperation *)getVideoFrameWithIndex:(NSInteger)index {
    HXWeakSelf
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        NSInteger item = index;
        CMTime time = [weakSelf getTimeWithIndex:(CGFloat)index];
        NSError *error;
        CGImageRef cgImg = [weakSelf.generator copyCGImageAtTime:time actualTime:NULL error:&error];
        if (!error && cgImg) {
            UIImage *image = [UIImage imageWithCGImage:cgImg];
            CGImageRelease(cgImg);
            [weakSelf getVideoFrameWithImage:image item:item];
        }else {
            CMTime tempTime;
            if (item >= 0 && item < weakSelf.dataCount - 2) {
                tempTime = [weakSelf getTimeWithIndex:item + 1];
            }else {
                tempTime = [weakSelf getTimeWithIndex:item - 1];
            }
            error = nil;
            cgImg = [weakSelf.generator copyCGImageAtTime:tempTime actualTime:NULL error:&error];
            if (!error && cgImg) {
                UIImage *image = [UIImage imageWithCGImage:cgImg];
                CGImageRelease(cgImg);
                [weakSelf getVideoFrameWithImage:image item:item];
            }
        }
    }];
    return operation;
}
- (void)getVideoFrameWithImage:(UIImage *)image item:(NSInteger)item {
    dispatch_async(dispatch_get_main_queue(), ^{
        HXVideoEditBottomViewCell *tempCell = (HXVideoEditBottomViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:item inSection:0]];
        if (tempCell) {
            CATransition *transition = [CATransition animation];
            transition.duration = 0.1f;
            transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            transition.type = kCATransitionFade;
            tempCell.imageView.image = image;
            [tempCell.layer addAnimation:transition forKey:nil];
        }
    });
}
#pragma mark - < UICollectionViewDataSource >
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataCount;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    HXVideoEditBottomViewCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CellId" forIndexPath:indexPath];
    return cell;
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item < self.dataCount - 1) {
        return CGSizeMake(self.itemWidth, self.itemHeight - 4);
    }
    CGFloat itemW = self.contentWidth - indexPath.item * self.itemWidth;
    return CGSizeMake(itemW, self.itemHeight - 4);
}
- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    [self getVideoFrameWithIndexPath:indexPath];
}
- (void)getVideoFrameWithIndexPath:(NSIndexPath *)indexPath {
    if (![self.operationDict objectForKey:@(indexPath.item).stringValue]) {
        NSBlockOperation *operation = [self getVideoFrameWithIndex:indexPath.item];
        [self.operationQueue addOperation:operation];
        [self.operationDict setObject:operation forKey:@(indexPath.item).stringValue];
    }
}
- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.operationDict[@(indexPath.item).stringValue]) {
        NSBlockOperation *operation = self.operationDict[@(indexPath.item).stringValue];
        [operation cancel];
        [self.operationDict removeObjectForKey:@(indexPath.item).stringValue];
    }
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.scrollViewDidScroll) {
        self.scrollViewDidScroll();
    }
}
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        if (self.startTimer) {
            self.startTimer();
        }
    }
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (self.startTimer) {
        self.startTimer();
    }
}
#pragma mark - < HXEditFrameViewDelegate >
- (void)editViewValidRectChanged {
    if ([self.delegate respondsToSelector:@selector(videoEditBottomViewValidRectChanged:)]) {
        [self.delegate videoEditBottomViewValidRectChanged:self];
    }
}
- (void)editViewValidRectEndChanged {
    if ([self.delegate respondsToSelector:@selector(videoEditBottomViewValidRectEndChanged:)]) {
        [self.delegate videoEditBottomViewValidRectEndChanged:self];
    }
}
- (void)layoutSubviews {
    CGFloat collectionViewW = self.hx_w;
    self.collectionView.frame = CGRectMake(0, hxCollectionViewY, collectionViewW, self.itemHeight);
    self.editView.frame = self.collectionView.frame;
    
    if (CGRectEqualToRect(self.editView.validRect, CGRectZero)) {
        self.editView.validRect = CGRectMake(hxValidRectX + hxImageWidth, 0, collectionViewW - hxValidRectX * 2 - hxImageWidth * 2, self.itemHeight);
    }
    
    self.cancelBtn.frame = CGRectMake(20, CGRectGetMaxY(self.collectionView.frame) + 15, 0 + 20, 40);
    self.cancelBtn.hx_w = [self.cancelBtn.titleLabel hx_getTextWidth];
    
    self.playBtn.hx_size = CGSizeMake(40, 40);
    
    self.playBtn.hx_centerX = self.hx_w / 2;
    self.playBtn.hx_centerY = self.cancelBtn.hx_centerY;
    
    self.doneBtn.hx_h = 40;
    self.doneBtn.hx_w = [self.doneBtn.titleLabel hx_getTextWidth];
    self.doneBtn.hx_x = self.hx_w - 20 - self.doneBtn.hx_w;
    self.doneBtn.hx_centerY = self.cancelBtn.hx_centerY;
    
}
- (void)updateTimeLbsFrame {
    self.startTimeLb.hx_h = 14;
    self.startTimeLb.hx_w = [self.startTimeLb hx_getTextWidth];
    self.startTimeLb.hx_x = hxValidRectX + hxImageWidth;
    self.startTimeLb.hx_y = self.collectionView.hx_y - 16;
    
    self.endTimeLb.hx_h = 14;
    self.endTimeLb.hx_w = [self.endTimeLb hx_getTextWidth];
    self.endTimeLb.hx_x = self.hx_w - hxValidRectX - hxImageWidth - self.endTimeLb.hx_w;
    self.endTimeLb.hx_y = self.collectionView.hx_y - 16;
    
    self.totalTimeLb.hx_h = 14;
    self.totalTimeLb.hx_w = [self.totalTimeLb hx_getTextWidth];
    self.totalTimeLb.hx_y = CGRectGetMaxY(self.collectionView.frame) + 3;
    self.totalTimeLb.hx_centerX = self.collectionView.hx_centerX;
}
#pragma mark - < 懒加载 >
- (UIButton *)cancelBtn {
    if (!_cancelBtn) {
        _cancelBtn = [UIButton buttonWithType:UIButtonTypeSystem]; 
        [_cancelBtn setTitle:[NSBundle hx_localizedStringForKey:@"取消"] forState:UIControlStateNormal];
        [_cancelBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _cancelBtn.titleLabel.font = [UIFont hx_mediumSFUITextOfSize:15];
        _cancelBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [_cancelBtn addTarget:self action:@selector(didCancelBtnClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelBtn;
}
- (UIButton *)playBtn {
    if (!_playBtn) {
        _playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playBtn setImage:[UIImage hx_imageNamed:@"hx_video_play"] forState:UIControlStateNormal];
        [_playBtn setImage:[UIImage hx_imageNamed:@"hx_video_ pause"] forState:UIControlStateSelected];
        _playBtn.tintColor = [UIColor whiteColor];
        [_playBtn addTarget:self action:@selector(didplayBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playBtn;
}
- (UIButton *)doneBtn {
    if (!_doneBtn) {
        _doneBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [_doneBtn setTitle:[NSBundle hx_localizedStringForKey:@"确定"] forState:UIControlStateNormal];
        [_doneBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _doneBtn.titleLabel.font = [UIFont hx_mediumSFUITextOfSize:15];
        _doneBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [_doneBtn addTarget:self action:@selector(didDoneBtnClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _doneBtn;
}
- (UICollectionViewFlowLayout *)flowLayout {
    if (!_flowLayout) {
        _flowLayout = [[UICollectionViewFlowLayout alloc] init];
        _flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _flowLayout.minimumInteritemSpacing = 0;
        _flowLayout.minimumLineSpacing = 0;
        _flowLayout.sectionInset = UIEdgeInsetsMake(2, hxValidRectX + hxImageWidth, 2, hxValidRectX + hxImageWidth);
    }
    return _flowLayout;
}
- (UICollectionView *)collectionView {
    if (!_collectionView) {
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:self.flowLayout];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.showsHorizontalScrollIndicator = NO;
        [_collectionView registerClass:[HXVideoEditBottomViewCell class] forCellWithReuseIdentifier:@"CellId"];
#ifdef __IPHONE_11_0
        if (@available(iOS 11.0, *)) {
            _collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
#else
            if ((NO)) {
#endif
            }
    }
    return _collectionView;
}
- (HXEditFrameView *)editView {
    if (!_editView) {
        _editView = [[HXEditFrameView alloc] initWithManager:self.manager];
        _editView.delegate = self;
    }
    return _editView;
}
- (AVAssetImageGenerator *)generator {
    if (!_generator) {
        _generator = [[AVAssetImageGenerator alloc] initWithAsset:self.avAsset];
        if (self.model.endImageSize.width >= self.model.endImageSize.height / 9 * 15) {
            _generator.maximumSize = CGSizeMake(self.model.endImageSize.width, self.model.endImageSize.height);
        }else {
            _generator.maximumSize = CGSizeMake(self.model.endImageSize.width / 3, self.model.endImageSize.height / 3);
        }
        _generator.appliesPreferredTrackTransform = YES;
        _generator.requestedTimeToleranceBefore = kCMTimeZero;
        _generator.requestedTimeToleranceAfter = kCMTimeZero;
        _generator.apertureMode = AVAssetImageGeneratorApertureModeProductionAperture;
    }
    return _generator;
}
- (NSOperationQueue *)operationQueue {
    if (!_operationQueue) {
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 5;
    }
    return _operationQueue;
}
- (NSMutableDictionary *)operationDict {
    if (!_operationDict) {
        _operationDict = [NSMutableDictionary dictionary];
    }
    return _operationDict;
}
- (UIView *)indicatorLine {
    if (!_indicatorLine) {
        _indicatorLine = [[UIView alloc] initWithFrame:CGRectMake(0, 2, 2, self.itemHeight - 4)];
        _indicatorLine.backgroundColor = [UIColor whiteColor];
        _indicatorLine.layer.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.5].CGColor;
        _indicatorLine.layer.shadowOpacity = 0.5f;
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureAction:)];
        [_indicatorLine addGestureRecognizer:panGesture];
    }
    return _indicatorLine;
}
- (UILabel *)startTimeLb {
    if (!_startTimeLb) {
        _startTimeLb = [[UILabel alloc] init];
        _startTimeLb.textColor = [UIColor whiteColor];
        _startTimeLb.font = [UIFont hx_mediumSFUITextOfSize:12];
    }
    return _startTimeLb;
}
- (UILabel *)endTimeLb {
    if (!_endTimeLb) {
        _endTimeLb = [[UILabel alloc] init];
        _endTimeLb.textColor = [UIColor whiteColor];
        _endTimeLb.font = [UIFont hx_mediumSFUITextOfSize:12];
    }
    return _endTimeLb;
}
- (UILabel *)totalTimeLb {
    if (!_totalTimeLb) {
        _totalTimeLb = [[UILabel alloc] init];
        _totalTimeLb.textColor = [UIColor whiteColor];
        _totalTimeLb.font = [UIFont hx_mediumSFUITextOfSize:12];
    }
    return _totalTimeLb;
}
@end

@interface HXVideoEditBottomViewCell ()

@end

@implementation HXVideoEditBottomViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self.contentView addSubview:self.imageView];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.imageView.frame = self.bounds;
}
- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
    }
    return _imageView;
}
@end

@interface HXEditFrameView ()
@property (strong, nonatomic) UIImageView *leftImageView;
@property (strong, nonatomic) UIImageView *rightImageView;
@property (assign, nonatomic) CGFloat minWidth;
@property (strong, nonatomic) HXPhotoManager *manager;
@end

@implementation HXEditFrameView
- (instancetype)initWithManager:(HXPhotoManager *)manager {
    self = [super init];
    if (self) {
        self.manager = manager;
        [self setupUI];
    }
    return self;
}
- (void)setContentWidth:(CGFloat)contentWidth {
    _contentWidth = contentWidth;
    if ((NSInteger)roundf(self.videoTime) <= 0) {
        self.minWidth = contentWidth;
        return;
    }
    CGFloat scale = (CGFloat)self.manager.configuration.minVideoClippingTime / self.videoTime;
    self.minWidth = contentWidth * scale;
}
- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextClearRect(context, self.validRect);
    
    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextSetLineWidth(context, 4.0);
    
    CGPoint topPoints[2];
    topPoints[0] = CGPointMake(self.validRect.origin.x, 0);
    topPoints[1] = CGPointMake(self.validRect.size.width + self.validRect.origin.x, 0);
    
    CGPoint bottomPoints[2];
    bottomPoints[0] = CGPointMake(self.validRect.origin.x, self.itemHeight);
    bottomPoints[1] = CGPointMake(self.validRect.size.width + self.validRect.origin.x, self.itemHeight);
    
    CGContextAddLines(context, topPoints, 2);
    CGContextAddLines(context, bottomPoints, 2);
    
    CGContextDrawPath(context, kCGPathStroke);
}
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    CGRect left = self.leftImageView.frame;
    left.origin.x -= hxImageWidth * 2;
    left.size.width += hxImageWidth * 4;
    CGRect right = self.rightImageView.frame;
    right.origin.x -= hxImageWidth * 2;
    right.size.width += hxImageWidth * 4;
    
    if (CGRectContainsPoint(left, point)) {
        return self.leftImageView;
    }
    if (CGRectContainsPoint(right, point)) {
        return self.rightImageView;
    }
    return nil;
}
- (void)setupUI {
    self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:.5];
    [self addSubview:self.leftImageView];
    [self addSubview:self.rightImageView];
}
- (void)panGestureAction:(UIGestureRecognizer *)panGesture {
    CGPoint point = [panGesture locationInView:self];
    CGRect rct = self.validRect;
    const CGFloat W = self.hx_w;
    CGFloat minX = hxValidRectX + hxImageWidth;
    
    switch (panGesture.view.tag) {
        case 0: {
            //left
            CGFloat maxX = self.rightImageView.hx_x - self.minWidth;
            point.x = MAX(minX, MIN(point.x, maxX));
            point.y = 0;
            
            rct.size.width = CGRectGetMaxX(rct) - point.x;
            rct.origin.x = point.x;
        }
            break;
        case 1:  {
            //right
            minX = CGRectGetMaxX(self.leftImageView.frame) + self.minWidth;
            CGFloat  maxX = W - hxValidRectX - hxImageWidth;
            
            point.x = MAX(minX, MIN(point.x, maxX));
            point.y = 0;
            
            rct.size.width = (point.x - rct.origin.x);
        }
            break;
        default:
            break;
    }
    
    switch (panGesture.state) {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged:
            if (self.delegate && [self.delegate respondsToSelector:@selector(editViewValidRectChanged)]) {
                [self.delegate editViewValidRectChanged];
            }
            break;
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
            if (self.delegate && [self.delegate respondsToSelector:@selector(editViewValidRectEndChanged)]) {
                [self.delegate editViewValidRectEndChanged];
            }
            break;
            
        default:
            break;
    }
    
    
    self.validRect = rct;
}
- (void)setValidRect:(CGRect)validRect {
    _validRect = validRect;
    self.leftImageView.frame = CGRectMake(validRect.origin.x - hxImageWidth, 0, hxImageWidth, self.itemHeight);
    self.rightImageView.frame = CGRectMake(validRect.origin.x + validRect.size.width, 0, hxImageWidth, self.itemHeight);
    
    [self setNeedsDisplay];
}
- (UIImageView *)leftImageView {
    if (!_leftImageView) {
        _leftImageView = [[UIImageView alloc] initWithImage:[UIImage hx_imageNamed:@"hx_videoedit_left"]];
        _rightImageView.userInteractionEnabled = YES;
        _leftImageView.tag = 0;
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureAction:)];
        [_leftImageView addGestureRecognizer:panGesture];
    }
    return _leftImageView;
}
- (UIImageView *)rightImageView {
    if (!_rightImageView) {
        _rightImageView = [[UIImageView alloc] initWithImage:[UIImage hx_imageNamed:@"hx_videoedit_right"]];
        _rightImageView.userInteractionEnabled = YES;
        _rightImageView.tag = 1;
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureAction:)];
        [_rightImageView addGestureRecognizer:panGesture];
    }
    return _rightImageView;
}
@end
