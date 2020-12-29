//
//  HXPreviewImageView.m
//  HXPhotoPickerExample
//
//  Created by Silence on 2019/11/15.
//  Copyright © 2019 Silence. All rights reserved.
//

#import "HXPreviewImageView.h"
#import "UIImageView+HXExtension.h"
#import "UIImage+HXExtension.h"
#import "HXPhotoModel.h"
#import "HXPhotoDefine.h"
#import "HXCircleProgressView.h"
#import "UIView+HXExtension.h"

#if __has_include(<SDWebImage/UIImageView+WebCache.h>)
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/SDAnimatedImageView.h>
#import <SDWebImage/SDAnimatedImageView+WebCache.h>
#import <SDWebImage/UIImage+GIF.h>
#elif __has_include("UIImageView+WebCache.h")
#import "UIImageView+WebCache.h"
#import "UIImage+GIF.h"
#import "SDAnimatedImageView.h"
#import "SDAnimatedImageView+WebCache.h"
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
#import "HXPhotoEdit.h"

@interface HXPreviewImageView ()
#if HasYYKitOrWebImage
@property (strong, nonatomic) YYAnimatedImageView *animatedImageView;
#endif
#if HasSDWebImage
@property (strong, nonatomic) SDAnimatedImageView *sdImageView;
#endif
@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) HXCircleProgressView *progressView;
@end


@implementation HXPreviewImageView
@synthesize image = _image;
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
#if HasSDWebImage
        [self addSubview:self.sdImageView];
#elif HasYYKitOrWebImage
        [self addSubview:self.animatedImageView];
#else
        [self addSubview:self.imageView];
#endif
        [self addSubview:self.progressView];
    }
    return self;
}
- (void)setImage:(UIImage *)image {
    _image = image;
#if HasSDWebImage
    self.sdImageView.image = image;
#elif HasYYKitOrWebImage
    self.animatedImageView.image = image;
#else
    self.imageView.image = image;
#endif
}
- (UIImage *)image {
    if (self.model.photoEdit) {
        return self.model.photoEdit.editPreviewImage;
    }
    UIImage *image;
#if HasSDWebImage
            if (self.model.type == HXPhotoModelMediaTypePhotoGif) {
                if (self.sdImageView.image.images.count > 0) {
                    image = self.sdImageView.image.images.firstObject;
                }else {
                    image = self.sdImageView.image;
                }
            }else {
                image = self.sdImageView.image;
            }
#elif HasYYKitOrWebImage
            if (self.model.type == HXPhotoModelMediaTypePhotoGif) {
                if (self.animatedImageView.image.images.count > 0) {
                    image = self.animatedImageView.image.images.firstObject;
                }else {
                    image = self.animatedImageView.image;
                }
            }else {
                image = self.animatedImageView.image;
            }
#else
            if (self.model.type == HXPhotoModelMediaTypePhotoGif) {
                if (self.imageView.image.images.count > 0) {
                    image = self.imageView.image.images.firstObject;
                }else {
                    image = self.imageView.image;
                }
            }else {
                image = self.imageView.image;
            }
#endif
    return image;
}
- (void)setModel:(HXPhotoModel *)model {
    _model = model;
    if (model.photoEdit) {
        [self setImageViewWithImage:model.photoEdit.editPreviewImage isAnimation:NO];
        model.tempImage = nil;
        return;
    }
HXWeakSelf
    if (model.type == HXPhotoModelMediaTypeCameraPhoto || model.type == HXPhotoModelMediaTypeCameraVideo) {
        if (model.networkPhotoUrl) {
            self.progressView.hidden = model.downloadComplete;
            CGFloat progress = (CGFloat)model.receivedSize / model.expectedSize;
            self.progressView.progress = progress;
            if (model.downloadComplete && !model.downloadError && model.loadOriginalImage) {
                [self setImageViewWithImage:model.previewPhoto isAnimation:NO];
                if (self.downloadICloudAssetComplete) {
                    self.downloadICloudAssetComplete();
                }
                if (self.downloadNetworkImageComplete) {
                    self.downloadNetworkImageComplete();
                }
            }else {
#if HasSDWebImage
                [self.sdImageView sd_setImageWithURL:model.networkPhotoUrl placeholderImage:model.thumbPhoto options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
                    model.receivedSize = receivedSize;
                    model.expectedSize = expectedSize;
                    CGFloat progress = (CGFloat)receivedSize / expectedSize;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        weakSelf.progressView.progress = progress;
                    });
                } completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                    if (error != nil) {
                        model.downloadError = YES;
                        model.downloadComplete = YES;
                        [weakSelf.progressView showError];
                    }else {
                        if (image) {
                            model.imageSize = image.size;
                            model.thumbPhoto = image;
                            model.previewPhoto = image;
                            model.downloadComplete = YES;
                            model.downloadError = NO;
                            weakSelf.model.imageSize = image.size;
                            weakSelf.progressView.progress = 1;
                            weakSelf.progressView.hidden = YES;
                            weakSelf.sdImageView.image = image;
                            if (weakSelf.downloadICloudAssetComplete) {
                                weakSelf.downloadICloudAssetComplete();
                            }
                            if (weakSelf.downloadNetworkImageComplete) {
                                weakSelf.downloadNetworkImageComplete();
                            }
                        }
                    }
                }];
#elif HasYYKitOrWebImage
                [self.animatedImageView hx_setImageWithModel:model progress:^(CGFloat progress, HXPhotoModel *model) {
                    if (weakSelf.model == model) {
                        weakSelf.progressView.progress = progress;
                    }
                } completed:^(UIImage *image, NSError *error, HXPhotoModel *model) {
                    if (weakSelf.model == model) {
                        if (error != nil) {
                            [weakSelf.progressView showError];
                        }else {
                            if (image) {
                                weakSelf.model.imageSize = image.size;
                                weakSelf.progressView.progress = 1;
                                weakSelf.progressView.hidden = YES;
                                weakSelf.animatedImageView.image = image;
                                if (weakSelf.downloadICloudAssetComplete) { weakSelf.downloadICloudAssetComplete();
                                }
                                if (weakSelf.downloadNetworkImageComplete) {
                                    weakSelf.downloadNetworkImageComplete();
                                }
                            }
                        }
                    }
                }];
#else
                [self.imageView hx_setImageWithModel:model progress:^(CGFloat progress, HXPhotoModel *model) {
                    if (weakSelf.model == model) {
                        weakSelf.progressView.progress = progress;
                    }
                } completed:^(UIImage *image, NSError *error, HXPhotoModel *model) {
                    if (weakSelf.model == model) {
                        if (error != nil) {
                            [weakSelf.progressView showError];
                        }else {
                            if (image) {
                                weakSelf.progressView.progress = 1;
                                weakSelf.progressView.hidden = YES;
                                weakSelf.imageView.image = image;
                                if (weakSelf.downloadICloudAssetComplete) { weakSelf.downloadICloudAssetComplete();
                                }
                                if (weakSelf.downloadNetworkImageComplete) {
                                    weakSelf.downloadNetworkImageComplete();
                                }
                            }
                        }
                    }
                }];
#endif
            }
        }else {
            if (model.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeLocalGif &&
                model.imageURL) {
#if HasSDWebImage
                self.sdImageView.image = [UIImage hx_animatedGIFWithURL:model.imageURL];
#elif HasYYKitOrWebImage
                self.animatedImageView.image = [UIImage hx_animatedGIFWithURL:model.imageURL];
#else
                self.imageView.image = [UIImage hx_animatedGIFWithURL:model.imageURL];
#endif
            }else {
                [self setImageViewWithImage:model.thumbPhoto isAnimation:NO];
            }
            model.tempImage = nil;
        }
    }else {
        if (model.type == HXPhotoModelMediaTypeLivePhoto) {
            if (model.tempImage) {
                [self setImageViewWithImage:model.tempImage isAnimation:NO];
                model.tempImage = nil;
            }else {
                if (self.allowPreviewDirectLoadOriginalImage) {
                    [self requestImageData];
                }else {
                    self.requestID = [model requestThumbImageWithWidth:self.hx_w completion:^(UIImage *image, HXPhotoModel *model, NSDictionary *info) {
                        if (weakSelf.model != model) return;
                        [weakSelf setImageViewWithImage:image isAnimation:NO];
                    }];
                }
            }
        }else {
            if (model.previewPhoto) {
                [self setImageViewWithImage:model.previewPhoto isAnimation:NO];
                model.tempImage = nil;
            }else {
                if (model.tempImage) {
                    [self setImageViewWithImage:model.tempImage isAnimation:NO];
                    model.tempImage = nil;
                }else {
                    if (self.allowPreviewDirectLoadOriginalImage) {
                        [self requestImageData];
                    }else {
                        self.requestID = [model requestThumbImageWithWidth:self.hx_w completion:^(UIImage *image, HXPhotoModel *model, NSDictionary *info) {
                            if (weakSelf.model != model) return;
                            [weakSelf setImageViewWithImage:image isAnimation:NO];
                        }];
                    }
                }
            }
        }
    }
}
- (void)setImageViewWithImage:(UIImage *)image isAnimation:(BOOL)isAnimation {
    CATransition *transition;
    if (isAnimation) {
        transition = [CATransition animation];
        transition.duration = 0.2f;
        transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        transition.type = kCATransitionFade;
    }
        
#if HasSDWebImage
    if (isAnimation) [self.sdImageView.layer removeAllAnimations];
    self.sdImageView.image = image;
    if (isAnimation) [self.sdImageView.layer addAnimation:transition forKey:nil];
#elif HasYYKitOrWebImage
    if (isAnimation) [self.animatedImageView.layer removeAllAnimations];
    self.animatedImageView.image = image;
    if (isAnimation) [self.animatedImageView.layer addAnimation:transition forKey:nil];
#else
    if (isAnimation) [self.imageView.layer removeAllAnimations];
    self.imageView.image = image;
    if (isAnimation) [self.imageView.layer addAnimation:transition forKey:nil];
#endif
}
- (void)requestImageData {
    if (!self.model.asset) {
        return;
    }
    HXWeakSelf
    self.requestID = [self.model requestImageDataStartRequestICloud:^(PHImageRequestID iCloudRequestId, HXPhotoModel * _Nullable model) {
        if (weakSelf.model != model) return;
        if (weakSelf.model.isICloud) {
            weakSelf.progressView.hidden = NO;
        }
        weakSelf.requestID = iCloudRequestId;
    } progressHandler:^(double progress, HXPhotoModel * _Nullable model) {
        if (weakSelf.model != model) return;
        if (weakSelf.model.isICloud) {
            weakSelf.progressView.hidden = NO;
        }
        weakSelf.progressView.progress = progress;
    } success:^(NSData * _Nullable imageData, UIImageOrientation orientation, HXPhotoModel * _Nullable model, NSDictionary * _Nullable info) {
        if (weakSelf.model != model) return;
        @autoreleasepool {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                UIImage *image = [UIImage imageWithData:imageData];
                if (orientation != UIImageOrientationUp) {
                    image = [image hx_normalizedImage];
                }
                CGSize imageSize = image.size;
                if (imageSize.width * imageSize.height > 3 * 1000 * 1000) {
                    while (imageSize.width * imageSize.height > 3 * 1000 * 1000) {
                        imageSize.width /= 2;
                        imageSize.height /= 2;
                    }
                    image = [image hx_scaleToFillSize:imageSize];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf downloadICloudAssetComplete];
                    weakSelf.progressView.hidden = YES;
                    [weakSelf setImageViewWithImage:image isAnimation:YES];
                });
            });
        }
    } failed:^(NSDictionary * _Nullable info, HXPhotoModel * _Nullable model) {
        if (weakSelf.model != model) return;
        weakSelf.progressView.hidden = YES;
    }];
}
- (void)requestHDImage {
    if (self.model.photoEdit) {
        [self setImageViewWithImage:self.model.photoEdit.editPreviewImage isAnimation:NO];
        [self downloadICloudAssetComplete];
        return;
    }
    HXWeakSelf
    if (self.model.type == HXPhotoModelMediaTypeCameraPhoto) {
        if (self.model.networkPhotoUrl) {
            if (!self.model.downloadComplete) {
                self.progressView.hidden = NO;
                self.progressView.progress = (CGFloat)self.model.receivedSize / self.model.expectedSize;;
            }else if (self.model.downloadError) {
                [self.progressView showError];
            }
        }
    }else if (self.model.type == HXPhotoModelMediaTypePhotoGif) {
        if (self.gifImage) {
#if HasSDWebImage
            if (self.sdImageView.image != self.gifImage) {
                self.sdImageView.image = self.gifImage;
            }
#elif HasYYKitOrWebImage
            if (self.animatedImageView.image != self.gifImage) {
                self.animatedImageView.image = self.gifImage;
            }
#else
            if (self.imageView.image != self.gifImage) {
                self.imageView.image = self.gifImage;
            }
#endif
        }else {
            self.requestID = [self.model requestImageDataStartRequestICloud:^(PHImageRequestID iCloudRequestId, HXPhotoModel *model) {
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
            } success:^(NSData *imageData, UIImageOrientation orientation, HXPhotoModel *model, NSDictionary *info) {
                if (weakSelf.model != model) return;
                dispatch_async(dispatch_get_global_queue(0, 0), ^{
                    id image;
#if HasSDWebImage
                    image = [SDAnimatedImage imageWithData:imageData];
#elif HasYYKitOrWebImage
                    image = [YYImage imageWithData:imageData];
#else
                    image = [UIImage hx_animatedGIFWithData:imageData];
#endif
                    dispatch_async(dispatch_get_main_queue(), ^{
#if HasSDWebImage
                        weakSelf.sdImageView.image = image;
                        weakSelf.gifImage = image;
                        [weakSelf setGifFirstFrame];
#elif HasYYKitOrWebImage
                        weakSelf.animatedImageView.image = image;
                        weakSelf.gifImage = image;
#else
                        weakSelf.imageView.image = image;
                        weakSelf.gifImage = image;
                        [weakSelf setGifFirstFrame];
#endif
                        [weakSelf downloadICloudAssetComplete];
                        weakSelf.progressView.hidden = YES;
                        weakSelf.model.tempImage = nil;
                    });
                });
            } failed:^(NSDictionary *info, HXPhotoModel *model) {
                if (weakSelf.model != model) return;
                weakSelf.progressView.hidden = YES;
            }];
        }
    }else {
        if (!self.allowPreviewDirectLoadOriginalImage) {
            [self requestImageData];
        }
    }
}
- (void)setGifFirstFrame {
    if (self.gifImage.images.count == 0) {
        self.gifFirstFrame = self.gifImage;
    }else {
        self.gifFirstFrame = self.gifImage.images.firstObject;
    }
}
- (void)cancelImage {
    if (self.allowPreviewDirectLoadOriginalImage) {
        return;
    }
    if (self.requestID) {
        [[PHImageManager defaultManager] cancelImageRequest:self.requestID];
        self.requestID = -1;
    }
    if (self.model.type == HXPhotoModelMediaTypePhotoGif) {
        if (!self.stopCancel) {
#if HasSDWebImage
            self.sdImageView.image = self.gifFirstFrame;
#elif HasYYKitOrWebImage
            self.animatedImageView.currentAnimatedImageIndex = 0;
#else
            self.imageView.image = self.gifFirstFrame;
#endif
            self.gifImage = nil;
        }else {
            self.stopCancel = NO;
        }
    }
}
- (void)layoutSubviews {
    [super layoutSubviews];
#if HasSDWebImage
    self.sdImageView.frame = self.bounds;
#elif HasYYKitOrWebImage
    self.animatedImageView.frame = self.bounds;
#else
    self.imageView.frame = self.bounds;
#endif
    self.progressView.hx_centerX = self.hx_w / 2;
    self.progressView.hx_centerY = self.hx_h / 2;
}
#if HasYYKitOrWebImage
- (YYAnimatedImageView *)animatedImageView {
    if (!_animatedImageView) {
        _animatedImageView = [[YYAnimatedImageView alloc] init];
        _animatedImageView.clipsToBounds = YES;
        _animatedImageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _animatedImageView;
}
#endif

#if HasSDWebImage
- (SDAnimatedImageView *)sdImageView {
    if (!_sdImageView) {
        _sdImageView = [[SDAnimatedImageView alloc] init];
        _sdImageView.clipsToBounds = YES;
        _sdImageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _sdImageView;
}
#endif

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.clipsToBounds = YES;
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
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
@end
