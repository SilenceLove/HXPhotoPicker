//
//  HXPhoto3DTouchViewController.m
//  照片选择器
//
//  Created by 洪欣 on 2017/9/25.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXPhoto3DTouchViewController.h"
#import <PhotosUI/PhotosUI.h>
#import "UIImage+HXExtension.h"
#import "HXCircleProgressView.h"
#import "UIImageView+HXExtension.h"

@interface HXPhoto3DTouchViewController ()
@property (strong, nonatomic) PHLivePhotoView *livePhotoView;
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (strong, nonatomic) HXCircleProgressView *progressView;
@property (strong, nonatomic) UIActivityIndicatorView *loadingView;
@property (assign, nonatomic) PHImageRequestID requestId;
@end

@implementation HXPhoto3DTouchViewController

- (NSArray<id<UIPreviewActionItem>> *)previewActionItems {
    NSArray *items = @[];
    if (self.previewActionItemsBlock) items = self.previewActionItemsBlock();
    return items;
}

- (void)viewDidLoad {
    [super viewDidLoad];
#if HasYYKitOrWebImage
    self.animatedImageView.hx_size = self.model.previewViewSize;
    self.animatedImageView.image = self.image;
    [self.view addSubview:self.animatedImageView];
    self.progressView.center = CGPointMake(self.animatedImageView.hx_size.width / 2, self.animatedImageView.hx_size.height / 2);
#else
    self.imageView.hx_size = self.model.previewViewSize;
    self.imageView.image = self.image;
    [self.view addSubview:self.imageView];
    self.progressView.center = CGPointMake(self.imageView.hx_size.width / 2, self.imageView.hx_size.height / 2);
#endif
    [self.view addSubview:self.progressView];
    [self.view addSubview:self.loadingView];
    self.loadingView.center = self.progressView.center;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    switch (self.model.type) {
        case HXPhotoModelMediaTypeVideo:
            [self loadVideo];
            break;
        case HXPhotoModelMediaTypeCameraVideo:
            [self loadVideo];
            break;
        case HXPhotoModelMediaTypePhotoGif:
            [self loadGifPhoto];
            break;
        case HXPhotoModelMediaTypeLivePhoto:
            [self loadLivePhoto];
            break;
        default:
            [self loadPhoto];
            break;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[PHImageManager defaultManager] cancelImageRequest:self.requestId];
    [self.player pause];
    [self.player seekToTime:kCMTimeZero];
    self.playerLayer.player = nil;
    self.player = nil;
    [self.playerLayer removeFromSuperlayer];
    if (_livePhotoView) {
        [self.livePhotoView stopPlayback];
        [self.livePhotoView removeFromSuperview];
        self.livePhotoView.livePhoto = nil;
        self.livePhotoView = nil;
    }
    [self.progressView removeFromSuperview];
    [self.loadingView stopAnimating];
#if HasYYKitOrWebImage
    [self.view addSubview:self.animatedImageView];
#else
    [self.view addSubview:self.imageView];
#endif
    if (self.player) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
    }
}

- (void)loadPhoto {
    HXWeakSelf
    if (self.model.type == HXPhotoModelMediaTypeCameraPhoto) {
        if (self.model.networkPhotoUrl) {
            self.progressView.hidden = self.model.downloadComplete;
            CGFloat progress = (CGFloat)self.model.receivedSize / self.model.expectedSize;
            self.progressView.progress = progress;
#if HasYYKitOrWebImage
            [self.animatedImageView hx_setImageWithModel:self.model progress:^(CGFloat progress, HXPhotoModel *model) {
                if (weakSelf.model == model) {
                    weakSelf.progressView.progress = progress;
                }
            } completed:^(UIImage *image, NSError *error, HXPhotoModel *model) {
                if (weakSelf.model == model) {
                    if (error != nil) {
                        [weakSelf.progressView showError];
                    }else {
                        if (image) {
                            if (weakSelf.downloadImageComplete) {
                                weakSelf.downloadImageComplete(weakSelf, weakSelf.model);
                            }
                            weakSelf.progressView.progress = 1;
                            weakSelf.progressView.hidden = YES;
                            weakSelf.animatedImageView.image = image;
                            
                        }
                    }
                }
            }];
#else
            [self.imageView hx_setImageWithModel:self.model progress:^(CGFloat progress, HXPhotoModel *model) {
                if (weakSelf.model == model) {
                    weakSelf.progressView.progress = progress;
                }
            } completed:^(UIImage *image, NSError *error, HXPhotoModel *model) {
                if (weakSelf.model == model) {
                    if (error != nil) {
                        [weakSelf.progressView showError];
                    }else {
                        if (image) {
                            if (weakSelf.downloadImageComplete) {
                                weakSelf.downloadImageComplete(weakSelf, weakSelf.model);
                            }
                            weakSelf.progressView.progress = 1;
                            weakSelf.progressView.hidden = YES;
                            weakSelf.imageView.image = image;
                            
                        }
                    }
                }
            }];
#endif
        }else {
#if HasYYKitOrWebImage
            self.animatedImageView.image = self.model.thumbPhoto;
#else
            self.imageView.image = self.model.thumbPhoto;
#endif
        }
        return;
    }
    
    [self.model requestPreviewImageWithSize:CGSizeMake(self.model.previewViewSize.width * 1.5, self.model.previewViewSize.height * 1.5) startRequestICloud:^(PHImageRequestID iCloudRequestId, HXPhotoModel *model) {
        weakSelf.requestId = iCloudRequestId;
        if (weakSelf.model.isICloud) {
            weakSelf.progressView.hidden = NO;
        }
    } progressHandler:^(double progress, HXPhotoModel *model) {
        if (weakSelf.model.isICloud) {
            weakSelf.progressView.hidden = NO;
        }
        weakSelf.progressView.progress = progress;
    } success:^(UIImage *image, HXPhotoModel *model, NSDictionary *info) {
        weakSelf.progressView.hidden = YES;
        CATransition *transition = [CATransition animation];
        transition.duration = 0.2f;
        transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        transition.type = kCATransitionFade;
#if HasYYKitOrWebImage
        [weakSelf.animatedImageView.layer removeAllAnimations];
        weakSelf.animatedImageView.image = image;
        [weakSelf.animatedImageView.layer addAnimation:transition forKey:nil];
#else
        [weakSelf.imageView.layer removeAllAnimations];
        weakSelf.imageView.image = image;
        [weakSelf.imageView.layer addAnimation:transition forKey:nil];
#endif
    } failed:^(NSDictionary *info, HXPhotoModel *model) {
        
    }];
}

- (void)loadGifPhoto {
    HXWeakSelf
    self.requestId = [self.model requestImageDataStartRequestICloud:^(PHImageRequestID iCloudRequestId, HXPhotoModel *model) {
        weakSelf.requestId = iCloudRequestId;
        if (weakSelf.model.isICloud) {
            weakSelf.progressView.hidden = NO;
        }
    } progressHandler:^(double progress, HXPhotoModel *model) {
        if (weakSelf.model.isICloud) {
            weakSelf.progressView.hidden = NO;
        }
        weakSelf.progressView.progress = progress;
    } success:^(NSData *imageData, UIImageOrientation orientation, HXPhotoModel *model, NSDictionary *info) {
        weakSelf.progressView.hidden = YES;
        UIImage *gifImage = [UIImage hx_animatedGIFWithData:imageData];
        if (gifImage.images.count > 0) {
#if HasYYKitOrWebImage
            weakSelf.animatedImageView.image = nil;
            weakSelf.animatedImageView.image = gifImage;
#else
            weakSelf.imageView.image = nil;
            weakSelf.imageView.image = gifImage;
#endif
        }
    } failed:^(NSDictionary *info, HXPhotoModel *model) {
        //            [weakSelf.progressView showError];
    }]; 
}

- (void)loadLivePhoto { 
    self.livePhotoView = [[PHLivePhotoView alloc] initWithFrame:CGRectMake(0, 0, self.model.previewViewSize.width, self.model.previewViewSize.height)];
    self.livePhotoView.clipsToBounds = YES;
    self.livePhotoView.hidden = YES;
    self.livePhotoView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:self.livePhotoView];
    HXWeakSelf
    self.requestId = [self.model requestLivePhotoWithSize:CGSizeMake(self.model.previewViewSize.width * 1.5, self.model.previewViewSize.height * 1.5) startRequestICloud:^(PHImageRequestID iCloudRequestId, HXPhotoModel *model) {
        weakSelf.requestId = iCloudRequestId;
        if (weakSelf.model.isICloud) {
            weakSelf.progressView.hidden = NO;
        }
    } progressHandler:^(double progress, HXPhotoModel *model) {
        if (weakSelf.model.isICloud) {
            weakSelf.progressView.hidden = NO;
        }
        weakSelf.progressView.progress = progress;
    } success:^(PHLivePhoto *livePhoto, HXPhotoModel *model, NSDictionary *info) {
        weakSelf.progressView.hidden = YES;
        weakSelf.livePhotoView.hidden = NO;
        weakSelf.livePhotoView.livePhoto = livePhoto;
        [weakSelf.livePhotoView startPlaybackWithStyle:PHLivePhotoViewPlaybackStyleHint];
#if HasYYKitOrWebImage
        [weakSelf.animatedImageView removeFromSuperview];
#else
        [weakSelf.imageView removeFromSuperview];
#endif

    } failed:^(NSDictionary *info, HXPhotoModel *model) {
        
    }]; 
}

- (void)loadVideo {
    HXWeakSelf
    self.requestId = [self.model requestAVAssetStartRequestICloud:^(PHImageRequestID iCloudRequestId, HXPhotoModel *model) {
        weakSelf.requestId = iCloudRequestId;
        [weakSelf.loadingView startAnimating];
    } progressHandler:^(double progress, HXPhotoModel *model) {
        if (weakSelf.model.isICloud) {
            weakSelf.progressView.hidden = NO;
        }
        weakSelf.progressView.progress = progress;
    } success:^(AVAsset *avAsset, AVAudioMix *audioMix, HXPhotoModel *model, NSDictionary *info) {
        weakSelf.progressView.hidden = YES;
        weakSelf.player = [AVPlayer playerWithPlayerItem:[AVPlayerItem playerItemWithAsset:avAsset]];
        [weakSelf playVideo];
        [weakSelf.loadingView stopAnimating];
        [[NSNotificationCenter defaultCenter] addObserver:weakSelf selector:@selector(pausePlayerAndShowNaviBar) name:AVPlayerItemDidPlayToEndTimeNotification object:weakSelf.player.currentItem];
    } failed:^(NSDictionary *info, HXPhotoModel *model) {
        [weakSelf.loadingView stopAnimating];
    }]; 
}
- (void)pausePlayerAndShowNaviBar {
    [self.player.currentItem seekToTime:CMTimeMake(0, 1)];
    [self.player play];
}
- (void)playVideo {
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.frame = CGRectMake(0, 0, self.model.previewViewSize.width, self.model.previewViewSize.height);
    [self.view.layer insertSublayer:self.playerLayer atIndex:0];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.player play];
#if HasYYKitOrWebImage
        [self.animatedImageView removeFromSuperview];
#else
        [self.imageView removeFromSuperview];
#endif
    });
}

- (void)dealloc {
    if (HXShowLog) NSSLog(@"%@",self);
}

#if HasYYKitOrWebImage
- (YYAnimatedImageView *)animatedImageView {
    if (!_animatedImageView) {
        _animatedImageView = [[YYAnimatedImageView alloc] init];
        _animatedImageView.clipsToBounds = YES;
        _animatedImageView.contentMode = UIViewContentModeScaleAspectFill;
        _animatedImageView.hx_x = 0;
        _animatedImageView.hx_y = 0;
    }
    return _animatedImageView;
}
#endif
- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.clipsToBounds = YES;
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.hx_x = 0;
        _imageView.hx_y = 0;
    }
    return _imageView;
}
- (HXCircleProgressView *)progressView {
    if (!_progressView) {
        _progressView = [[HXCircleProgressView alloc] init];
        _progressView.hidden = YES;
    }
    return _progressView;
}
- (UIActivityIndicatorView *)loadingView {
    if (!_loadingView) {
        _loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    }
    return _loadingView;
}
//- (PHLivePhotoView *)livePhotoView {
//    if (!_livePhotoView) {
//        _livePhotoView = [[PHLivePhotoView alloc] init];
//        _livePhotoView.clipsToBounds = YES;
//        _livePhotoView.contentMode = UIViewContentModeScaleAspectFill;
//    }
//    return _livePhotoView;
//}
@end

