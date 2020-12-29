//
//  HXPhoto3DTouchViewController.m
//  HXPhotoPickerExample
//
//  Created by Silence on 2017/9/25.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import "HXPhoto3DTouchViewController.h"
#import <PhotosUI/PhotosUI.h>
#import "UIImage+HXExtension.h"
#import "HXCircleProgressView.h"
#import "UIImageView+HXExtension.h"

@interface HXPhoto3DTouchViewController ()<PHLivePhotoViewDelegate>
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
#if HasSDWebImage
    self.sdImageView.hx_size = self.model.previewViewSize;
    self.sdImageView.image = self.image;
    [self.view addSubview:self.sdImageView];
    self.progressView.center = CGPointMake(self.sdImageView.hx_size.width / 2, self.sdImageView.hx_size.height / 2);
#elif HasYYKitOrWebImage
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
    if (self.requestId) {
        [[PHImageManager defaultManager] cancelImageRequest:self.requestId];
    }
    if (_livePhotoView) {
        self.livePhotoView.delegate = nil;
        [self.livePhotoView stopPlayback];
        [self.livePhotoView removeFromSuperview];
        self.livePhotoView.livePhoto = nil;
        self.livePhotoView = nil;
    }
    if (_progressView) {
        [self.progressView removeFromSuperview];
    }
    if (_loadingView) {
        [self.loadingView stopAnimating];
    }
#if HasSDWebImage
    if (_sdImageView) {
        [self.view addSubview:self.sdImageView];
    }
#elif HasYYKitOrWebImage
    if (_animatedImageView) {
        [self.view addSubview:self.animatedImageView];
    }
#else
    if (_imageView) {
        [self.view addSubview:self.imageView];
    }
#endif
    if (_player) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
        [self.player pause];
        [self.player seekToTime:kCMTimeZero];
        self.player = nil;
    }
    if (_playerLayer) {
        self.playerLayer.player = nil;
        [self.playerLayer removeFromSuperlayer];
    }
}

- (void)loadPhoto {
    HXWeakSelf
    if (self.model.type == HXPhotoModelMediaTypeCameraPhoto) {
        if (self.model.networkPhotoUrl) {
            self.progressView.hidden = self.model.downloadComplete;
            CGFloat progress = (CGFloat)self.model.receivedSize / self.model.expectedSize;
            self.progressView.progress = progress;
#if HasSDWebImage
            [self.sdImageView sd_setImageWithURL:self.model.networkPhotoUrl placeholderImage:self.model.thumbPhoto options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
                weakSelf.model.receivedSize = receivedSize;
                weakSelf.model.expectedSize = expectedSize;
                CGFloat progress = (CGFloat)receivedSize / expectedSize;
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakSelf.progressView.progress = progress;
                });
            } completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                if (error != nil) {
                    weakSelf.model.downloadError = YES;
                    weakSelf.model.downloadComplete = YES;
                    [weakSelf.progressView showError];
                }else {
                    if (image) {
                        if (weakSelf.downloadImageComplete) {
                            weakSelf.downloadImageComplete(weakSelf, weakSelf.model);
                        }
                        weakSelf.model.imageSize = image.size;
                        weakSelf.model.thumbPhoto = image;
                        weakSelf.model.previewPhoto = image;
                        weakSelf.model.downloadComplete = YES;
                        weakSelf.model.downloadError = NO;
                        weakSelf.model.imageSize = image.size;
                        weakSelf.progressView.progress = 1;
                        weakSelf.progressView.hidden = YES;
                        weakSelf.sdImageView.image = image;
                    }
                }
            }];
#elif HasYYKitOrWebImage
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
#if HasSDWebImage
            self.sdImageView.image = self.model.thumbPhoto;
#elif HasYYKitOrWebImage
            self.animatedImageView.image = self.model.thumbPhoto;
#else
            self.imageView.image = self.model.thumbPhoto;
#endif
        }
        return;
    }
    [self loadImageDataWithCompletion:^(NSData *imageData) {
        UIImage *image = [UIImage imageWithData:imageData];
#if HasSDWebImage
        weakSelf.sdImageView.image = image;
#elif HasYYKitOrWebImage
        weakSelf.animatedImageView.image = image;
#else
        weakSelf.imageView.image = image;
#endif
    }];
}
- (void)loadImageDataWithCompletion:(void (^)(NSData *imageData))completion {
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
        if (completion) {
            completion(imageData);
        }
    } failed:^(NSDictionary *info, HXPhotoModel *model) {
        //            [weakSelf.progressView showError];
    }];
}
- (void)loadGifPhoto {
    HXWeakSelf
    [self loadImageDataWithCompletion:^(NSData *imageData) {
#if HasSDWebImage
            UIImage *gifImage = [UIImage sd_imageWithGIFData:imageData];
            if (gifImage.images.count > 0) {
                weakSelf.sdImageView.image = nil;
                weakSelf.sdImageView.image = gifImage;
            }
#elif HasYYKitOrWebImage
            YYImage *gifImage = [YYImage imageWithData:imageData];
            weakSelf.animatedImageView.image = nil;
            weakSelf.animatedImageView.image = gifImage;
#else
        UIImage *gifImage = [UIImage hx_animatedGIFWithData:imageData];
        if (gifImage.images.count > 0) {
            weakSelf.imageView.image = nil;
            weakSelf.imageView.image = gifImage;
        }
#endif
    }];
}

- (void)loadLivePhoto { 
    self.livePhotoView = [[PHLivePhotoView alloc] initWithFrame:CGRectMake(0, 0, self.model.previewViewSize.width, self.model.previewViewSize.height)];
    self.livePhotoView.delegate = self;
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
        [weakSelf.livePhotoView startPlaybackWithStyle:PHLivePhotoViewPlaybackStyleFull];
#if HasSDWebImage
        [weakSelf.sdImageView removeFromSuperview];
#elif HasYYKitOrWebImage
        [weakSelf.animatedImageView removeFromSuperview];
#else
        [weakSelf.imageView removeFromSuperview];
#endif

    } failed:^(NSDictionary *info, HXPhotoModel *model) {
        
    }]; 
}
- (void)livePhotoView:(PHLivePhotoView *)livePhotoView didEndPlaybackWithStyle:(PHLivePhotoViewPlaybackStyle)playbackStyle {
    [self.livePhotoView startPlaybackWithStyle:PHLivePhotoViewPlaybackStyleFull];
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
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.playerLayer.frame = CGRectMake(0, 0, self.model.previewViewSize.width, self.model.previewViewSize.height);
    [self.view.layer insertSublayer:self.playerLayer atIndex:0];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.player play];
#if HasSDWebImage
        [self.sdImageView removeFromSuperview];
#elif HasYYKitOrWebImage
        [self.animatedImageView removeFromSuperview];
#else
        [self.imageView removeFromSuperview];
#endif
    });
}
#if HasSDWebImage
- (SDAnimatedImageView *)sdImageView {
    if (!_sdImageView) {
        _sdImageView = [[SDAnimatedImageView alloc] init];
        _sdImageView.clipsToBounds = YES;
        _sdImageView.contentMode = UIViewContentModeScaleAspectFill;
        _sdImageView.hx_x = 0;
        _sdImageView.hx_y = 0;
    }
    return _sdImageView;
}
#elif HasYYKitOrWebImage
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

