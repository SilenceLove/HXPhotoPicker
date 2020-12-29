//
//  HXPreviewLivePhotoView.m
//  HXPhotoPickerExample
//
//  Created by Silence on 2019/11/15.
//  Copyright © 2019 Silence. All rights reserved.
//

#import "HXPreviewLivePhotoView.h"
#import "HXPhotoModel.h"
#import "UIView+HXExtension.h"
#import <PhotosUI/PhotosUI.h>
#import "HXPhotoDefine.h"
#import "HXCircleProgressView.h"
#import "HXPhotoTools.h"

#if __has_include(<SDWebImage/UIImageView+WebCache.h>)
#import <SDWebImage/SDImageCache.h>
#elif __has_include("SDImageCache.h")
#import "SDImageCache.h"
#endif

#if __has_include(<SDWebImage/UIImageView+WebCache.h>)
#import <SDWebImage/SDWebImageManager.h>
#elif __has_include("SDWebImageManager.h")
#import "SDWebImageManager.h"
#endif

#if __has_include(<YYWebImage/YYWebImage.h>)
#import <YYWebImage/YYWebImage.h>
#elif __has_include("YYWebImage.h")
#import "YYWebImage.h"
#elif __has_include(<YYKit/YYKit.h>)
#import <YYKit/YYKit.h>
#elif __has_include("YYKit.h")
#import "YYKit.h"
#endif

@interface HXPreviewLivePhotoView ()<PHLivePhotoViewDelegate, NSURLConnectionDataDelegate>
@property (strong, nonatomic) PHLivePhotoView *livePhotoView;
@property (assign, nonatomic) BOOL livePhotoAnimating;
@property (assign, nonatomic) PHImageRequestID requestID;
@property (strong, nonatomic) HXCircleProgressView *progressView;
@property (strong, nonatomic) HXHUD *loadingView;
@property (strong, nonatomic) AVAssetWriter *writer;
@property (strong, nonatomic) AVAssetReader *videoReader;
@property (strong, nonatomic) AVAssetReader *audioReader;
@property (strong, nonatomic) NSURLSessionDownloadTask *videoTask;
@property (strong, nonatomic) id imageOperation;

@property (assign, nonatomic) long long totalLength;
@property (assign, nonatomic) long long imageCurrentLength;
@property (assign, nonatomic) long long videoCurrentLength;

@property (assign, nonatomic) BOOL cacheImage;
@property (assign, nonatomic) BOOL cacheVideo;
@end

@implementation HXPreviewLivePhotoView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.progressView];
        [self addSubview:self.livePhotoView];
    }
    return self;
}

- (void)setModel:(HXPhotoModel *)model {
    _model = model;
    if (self.requestID) {
        [[PHImageManager defaultManager] cancelImageRequest:self.requestID];
        [PHLivePhoto cancelLivePhotoRequestWithRequestID:self.requestID];
        self.requestID = -1;
    }
    if (_livePhotoView.livePhoto) {
//        [self.livePhotoView stopPlayback];
//        [self.livePhotoView startPlaybackWithStyle:PHLivePhotoViewPlaybackStyleFull];
        return;
    }
    if (self.model.iCloudRequestID) {
        [[PHImageManager defaultManager] cancelImageRequest:self.model.iCloudRequestID];
        self.model.iCloudRequestID = -1;
    }
    HXWeakSelf
    if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
        if (model.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeLocalLivePhoto) {
            BOOL hasVideoURL = [HXPhotoTools fileExistsAtLivePhotoVideoURL:self.model.videoURL];
            BOOL hasImageURL = [self imageCacheLocal];
//            BOOL hasImageURL = [HXPhotoTools fileExistsAtLivePhotoImageURL:self.model.imageURL];
            if (!hasVideoURL || !hasImageURL) {
                [self showLoading];
            }
            [self requestLocalLivePhoto];
        }else if (model.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeNetWorkLivePhoto) {
            self.totalLength = 0;
            self.imageCurrentLength = 0;
            self.videoCurrentLength = 0;
            self.cacheVideo = [HXPhotoTools fileExistsAtVideoURL:model.livePhotoVideoURL];
#if HasSDWebImage
            HXWeakSelf
            [[SDWebImageManager sharedManager].imageCache queryImageForKey:[[SDWebImageManager sharedManager] cacheKeyForURL:model.networkPhotoUrl] options:SDWebImageQueryMemoryData context:nil completion:^(UIImage * _Nullable image, NSData * _Nullable data, SDImageCacheType cacheType) {
                if (image) {
                    weakSelf.cacheImage = YES;
                }
                if (!weakSelf.cacheVideo || !weakSelf.cacheImage) {
                    [weakSelf showLoading];
                }
                [weakSelf getLivePhotoAssetLength];
            }];
#elif HasYYKitOrWebImage
            HXWeakSelf
            YYWebImageManager *manager = [YYWebImageManager sharedManager];
            [manager.cache getImageForKey:[manager cacheKeyForURL:model.networkPhotoUrl]  withType:YYImageCacheTypeAll withBlock:^(UIImage * _Nullable image, YYImageCacheType type) {
                if (image) {
                    weakSelf.cacheImage = YES;
                }
                if (!weakSelf.cacheVideo || !weakSelf.cacheImage) {
                    [weakSelf showLoading];
                }
                [weakSelf getLivePhotoAssetLength];
            }];
#endif
        }
        return;
    }
    self.requestID = [self.model requestLivePhotoWithSize:self.model.endImageSize startRequestICloud:^(PHImageRequestID iCloudRequestId, HXPhotoModel *model) {
        if (weakSelf.model != model) return;
        if (weakSelf.model.isICloud) {
            weakSelf.progressView.hidden = NO;
        }
        weakSelf.requestID = iCloudRequestId;
    } progressHandler:^(double progress, HXPhotoModel *model) {
        if (weakSelf.model != model) return;
        if (weakSelf.model.isICloud) {
            weakSelf.progressView.hidden = NO;
        }
        weakSelf.progressView.progress = progress;
    } success:^(PHLivePhoto *livePhoto, HXPhotoModel *model, NSDictionary *info) {
        if (weakSelf.model != model) return;
        if (weakSelf.downloadICloudAssetComplete) {
            weakSelf.downloadICloudAssetComplete();
        }
        weakSelf.livePhotoView.livePhoto = livePhoto;
        if ([HXPhotoCommon photoCommon].livePhotoAutoPlay) {
            [weakSelf.livePhotoView startPlaybackWithStyle:PHLivePhotoViewPlaybackStyleFull];
        }
    } failed:^(NSDictionary *info, HXPhotoModel *model) {
        if (weakSelf.model != model) return;
        weakSelf.progressView.hidden = YES;
    }];
}
- (void)getLivePhotoAssetLength {
    if (self.cacheImage && self.cacheVideo) {
        [self downloadLivePhoto];
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableURLRequest *imageURLRequest = [NSMutableURLRequest requestWithURL:self.model.networkPhotoUrl];
        [imageURLRequest setHTTPMethod:@"HEAD"];
        NSHTTPURLResponse *imageResp = nil;
        NSError *imageErr = nil;
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
        [NSURLConnection sendSynchronousRequest:imageURLRequest returningResponse:&imageResp error:&imageErr];
        
        if (self.cacheImage) {
            self.imageCurrentLength = imageResp.expectedContentLength;
        }
        NSMutableURLRequest *videoURLRequest = [NSMutableURLRequest requestWithURL:self.model.livePhotoVideoURL];
        [videoURLRequest setHTTPMethod:@"HEAD"];
        
        NSHTTPURLResponse *videoResp = nil;
        NSError *videoErr = nil;
        [NSURLConnection sendSynchronousRequest:videoURLRequest returningResponse:&videoResp error:&videoErr];
#pragma clang diagnostic pop
        if (!imageErr && !videoErr) {
            self.totalLength = videoResp.expectedContentLength + imageResp.expectedContentLength;
        }
        if (self.cacheVideo) {
            self.videoCurrentLength = videoResp.expectedContentLength;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self downloadLivePhoto];
        });
    });
}
- (void)updateProgress {
    self.progressView.progress = (float)(self.imageCurrentLength + self.videoCurrentLength) / (float)self.totalLength;
}
- (void)downloadLivePhoto {
    [self hideLoading];
    if (!self.cacheImage || !self.cacheVideo) {
        [self updateProgress];
        self.progressView.hidden = NO;
    }
    __block BOOL imageDownloadCompletion = NO;
    __block BOOL videoDownloadCompletion = NO;
    HXWeakSelf
    self.imageOperation = [HXPhotoModel requestImageWithURL:self.model.networkPhotoUrl progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        weakSelf.imageCurrentLength = receivedSize;
        [weakSelf updateProgress];
    } completion:^(UIImage * _Nullable image, NSURL * _Nullable url, NSError * _Nullable error) {
        weakSelf.imageOperation = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            imageDownloadCompletion = YES;
            if (error) {
                [[UIApplication sharedApplication].keyWindow hx_showImageHUDText:@"下载失败!"];
            }
            if (image) {
#if HasSDWebImage
                NSString *cacheKey = [[SDWebImageManager sharedManager] cacheKeyForURL:url];
                NSString *cachePath = [[SDImageCache sharedImageCache] cachePathForKey:cacheKey];
                weakSelf.model.imageURL = [NSURL fileURLWithPath:cachePath];
#elif HasYYKitOrWebImage
                weakSelf.model.thumbPhoto = image;
#endif
                if (videoDownloadCompletion) {
                    BOOL hasImageURL = [weakSelf imageCacheLocal];
                    BOOL hasVideoURL = [HXPhotoTools fileExistsAtLivePhotoVideoURL:weakSelf.model.videoURL];
                    if (!hasVideoURL || !hasImageURL) {
                        [weakSelf showLoading];
                    }
                    [weakSelf requestLocalLivePhoto];
                }
            }
        });
    }];
    
    self.videoTask = [[HXPhotoCommon photoCommon] downloadVideoWithURL:self.model.livePhotoVideoURL progress:^(float progress, long long downloadLength, long long totleLength, NSURL * _Nullable videoURL) {
        weakSelf.videoCurrentLength = downloadLength;
        [weakSelf updateProgress];
    } downloadSuccess:^(NSURL * _Nullable filePath, NSURL * _Nullable videoURL) {
        weakSelf.videoTask = nil;
        videoDownloadCompletion = YES;
        weakSelf.model.videoURL = filePath;
        if (imageDownloadCompletion) {
            BOOL hasImageURL = [weakSelf imageCacheLocal];
            BOOL hasVideoURL = [HXPhotoTools fileExistsAtLivePhotoVideoURL:weakSelf.model.videoURL];
            if (!hasVideoURL || !hasImageURL) {
                [weakSelf showLoading];
            }
            [weakSelf requestLocalLivePhoto];
        }
    } downloadFailure:^(NSError * _Nullable error, NSURL * _Nullable videoURL) {
        weakSelf.videoTask = nil;
        videoDownloadCompletion = YES;
        [weakSelf hideLoading];
        [[UIApplication sharedApplication].keyWindow hx_showImageHUDText:@"下载失败!"];
    }];
}
- (BOOL)imageCacheLocal {
    NSURL *imageURL;
    if (!self.model.imageURL) {
        NSString *fileName = [self.model.videoURL.lastPathComponent.stringByDeletingPathExtension stringByAppendingString:@"_local_img"];
        fileName = HXDiskCacheFileNameForKey(fileName, NO);
        fileName = [HXPhotoPickerLivePhotoImagesPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", fileName]];
        imageURL = [NSURL fileURLWithPath:fileName];
    }else {
        imageURL = self.model.imageURL;
    }
    return [HXPhotoTools fileExistsAtLivePhotoImageURL:imageURL];
}
- (void)requestLocalLivePhoto {
    self.progressView.hidden = YES;
    HXWeakSelf
    [self.model requestLocalLivePhotoWithReqeustID:^(PHLivePhotoRequestID requestID) {
        weakSelf.requestID = requestID;
    } header:^(AVAssetWriter * _Nullable writer, AVAssetReader * _Nullable videoReader, AVAssetReader * _Nullable audioReader) {
        weakSelf.writer = writer;
        weakSelf.videoReader = videoReader;
        weakSelf.audioReader = audioReader;
    } completion:^(PHLivePhoto * _Nullable livePhoto, HXPhotoModel * _Nullable model, NSDictionary * _Nullable info) {
        weakSelf.writer = nil;
        weakSelf.videoReader = nil;
        weakSelf.audioReader = nil;
        [weakSelf hideLoading];
        if (weakSelf.model != model) return;
        if (!livePhoto) {
            return;
        }
        if (weakSelf.downloadICloudAssetComplete) {
            weakSelf.downloadICloudAssetComplete();
        }
        [weakSelf.livePhotoView stopPlayback];
        weakSelf.livePhotoView.livePhoto = livePhoto;
        if ([HXPhotoCommon photoCommon].livePhotoAutoPlay) {
            [weakSelf.livePhotoView startPlaybackWithStyle:PHLivePhotoViewPlaybackStyleFull];
        }
    }];
}
- (void)cancelLivePhoto {
    [self hideLoading];
    if (self.imageOperation) {
#if HasSDWebImage
        [(SDWebImageCombinedOperation *)self.imageOperation cancel];
#elif HasYYKitOrWebImage
        [(YYWebImageOperation *)self.imageOperation cancel];
#endif
        self.imageOperation = nil;
    }
    if (self.videoTask) {
        [self.videoTask cancel];
        self.videoTask = nil;
    }
    if (self.writer) {
        [self.writer cancelWriting];
        self.writer = nil;
    }
    if (self.videoReader) {
        [self.videoReader cancelReading];
        self.videoReader = nil;
    }
    if (self.audioReader) {
        [self.audioReader cancelReading];
        self.audioReader = nil;
    }
    if (self.requestID) {
        if (self.model.type == HXPhotoModelMediaTypeCameraPhoto &&
            (self.model.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeLocalLivePhoto ||
             self.model.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeNetWorkLivePhoto)) {
                [PHLivePhoto cancelLivePhotoRequestWithRequestID:self.requestID];
        }else {
            [[PHImageManager defaultManager] cancelImageRequest:self.requestID];
        }
        self.requestID = -1;
    }
    if (!self.stopCancel) {
        self.progressView.hidden = YES;
        self.progressView.progress = 0;
        if (_livePhotoView.livePhoto) {
            [self stopLivePhoto];
            self.livePhotoView.livePhoto = nil;
        }
    }
    self.stopCancel = NO;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    if (!CGRectEqualToRect(self.livePhotoView.frame, self.bounds)) {
        self.livePhotoView.frame = self.bounds;
    }
    self.loadingView.hx_centerX = self.hx_w / 2;
    self.loadingView.hx_centerY = self.hx_h / 2;
    self.progressView.hx_centerX = self.hx_w / 2;
    self.progressView.hx_centerY = self.hx_h / 2;
}
#pragma mark - < PHLivePhotoViewDelegate >
- (void)livePhotoView:(PHLivePhotoView *)livePhotoView willBeginPlaybackWithStyle:(PHLivePhotoViewPlaybackStyle)playbackStyle {
    self.livePhotoAnimating = YES;
}
- (void)livePhotoView:(PHLivePhotoView *)livePhotoView didEndPlaybackWithStyle:(PHLivePhotoViewPlaybackStyle)playbackStyle {
    if (livePhotoView == _livePhotoView) {
        if ([HXPhotoCommon photoCommon].livePhotoAutoPlay) {
            [livePhotoView startPlaybackWithStyle:PHLivePhotoViewPlaybackStyleFull];
        }
    }
//    [self stopLivePhoto];
}
- (void)stopLivePhoto {
    self.livePhotoAnimating = NO;
    [self.livePhotoView stopPlayback];
}

- (PHLivePhotoView *)livePhotoView {
    if (!_livePhotoView) {
        _livePhotoView = [[PHLivePhotoView alloc] init];
        _livePhotoView.clipsToBounds = YES;
        _livePhotoView.contentMode = UIViewContentModeScaleAspectFill;
        _livePhotoView.delegate = self;
    }
    return _livePhotoView;
}
- (HXCircleProgressView *)progressView {
    if (!_progressView) {
        _progressView = [[HXCircleProgressView alloc] init];
        _progressView.progress = 0;
        _progressView.hidden = YES;
    }
    return _progressView;
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
@end
