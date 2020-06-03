//
//  HXPreviewImageView.m
//  照片选择器
//
//  Created by 洪欣 on 2019/11/15.
//  Copyright © 2019 洪欣. All rights reserved.
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
- (UIImage *)image {
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
HXWeakSelf
    if (model.type == HXPhotoModelMediaTypeCameraPhoto || model.type == HXPhotoModelMediaTypeCameraVideo) {
        if (model.networkPhotoUrl) {
            self.progressView.hidden = model.downloadComplete;
            CGFloat progress = (CGFloat)model.receivedSize / model.expectedSize;
            self.progressView.progress = progress;
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
                        if (weakSelf.downloadICloudAssetComplete) { weakSelf.downloadICloudAssetComplete();
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
        }else {
#if HasSDWebImage
            self.sdImageView.image = model.thumbPhoto;
#elif HasYYKitOrWebImage
            self.animatedImageView.image = model.thumbPhoto;
#else
            self.imageView.image = model.thumbPhoto;
#endif
            model.tempImage = nil;
        }
    }else {
        if (model.type == HXPhotoModelMediaTypeLivePhoto) {
            if (model.tempImage) {
#if HasSDWebImage
                self.sdImageView.image = model.tempImage;
#elif HasYYKitOrWebImage
                self.animatedImageView.image = model.tempImage;
#else
                self.imageView.image = model.tempImage;
#endif
                model.tempImage = nil;
            }else {
                self.requestID = [model requestThumbImageWithSize:CGSizeMake(self.hx_w * 0.5, self.hx_h * 0.5) completion:^(UIImage *image, HXPhotoModel *model, NSDictionary *info) {
                    if (weakSelf.model != model) return;
#if HasSDWebImage
                    weakSelf.sdImageView.image = image;
#elif HasYYKitOrWebImage
                    weakSelf.animatedImageView.image = image;
#else
                    weakSelf.imageView.image = image;
#endif
                }];
            }
        }else {
            if (model.previewPhoto) {
#if HasSDWebImage
                self.sdImageView.image = model.previewPhoto;
#elif HasYYKitOrWebImage
                self.animatedImageView.image = model.previewPhoto;
#else
                self.imageView.image = model.previewPhoto;
#endif
                model.tempImage = nil;
            }else {
                if (model.tempImage) {
#if HasSDWebImage
                    self.sdImageView.image = model.tempImage;
#elif HasYYKitOrWebImage
                    self.animatedImageView.image = model.tempImage;
#else
                    self.imageView.image = model.tempImage;
#endif
                    model.tempImage = nil;
                }else {
                    CGSize requestSize;
                    if (self.hx_h > self.hx_w / 9 * 20 ||
                        self.hx_w > self.hx_h / 9 * 20) {
                        requestSize = CGSizeMake(self.hx_w * 0.6, self.hx_h * 0.6);
                    }else {
                        requestSize = CGSizeMake(model.endImageSize.width, model.endImageSize.height);
                    }
                    self.requestID =[model requestThumbImageWithSize:requestSize completion:^(UIImage *image, HXPhotoModel *model, NSDictionary *info) {
                        if (weakSelf.model != model) return;
#if HasSDWebImage
                        weakSelf.sdImageView.image = image;
#elif HasYYKitOrWebImage
                        weakSelf.animatedImageView.image = image;
#else
                        weakSelf.imageView.image = image;
#endif
                    }];
                }
            }
        }
    }
}
- (void)requestHDImage {
    CGSize size;
    CGFloat scale;
    if (HX_IS_IPhoneX_All) {
        scale = 3.0f;
    }else if ([UIScreen mainScreen].bounds.size.width == 320) {
        scale = 2.0;
    }else if ([UIScreen mainScreen].bounds.size.width == 375) {
        scale = 2.5;
    }else {
        scale = 3.0;
    }
    
    if (self.hx_h > self.hx_w / 9 * 20 ||
        self.hx_w > self.hx_h / 9 * 20) {
        size = CGSizeMake(self.superview.hx_w * scale, self.superview.hx_h * scale);
    }else {
        size = CGSizeMake(self.model.endImageSize.width * scale, self.model.endImageSize.height * scale);
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
    }else if (self.model.type == HXPhotoModelMediaTypePhoto) {
        self.requestID = [self.model requestPreviewImageWithSize:size startRequestICloud:^(PHImageRequestID iCloudRequestId, HXPhotoModel *model) {
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
        } success:^(UIImage *image, HXPhotoModel *model, NSDictionary *info) {
            if (weakSelf.model != model) return;
            [weakSelf downloadICloudAssetComplete];
            weakSelf.progressView.hidden = YES;
            CATransition *transition = [CATransition animation];
            transition.duration = 0.2f;
            transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            transition.type = kCATransitionFade;
#if HasSDWebImage
            [weakSelf.sdImageView.layer removeAllAnimations];
            weakSelf.sdImageView.image = image;
            [weakSelf.sdImageView.layer addAnimation:transition forKey:nil];
#elif HasYYKitOrWebImage
            [weakSelf.animatedImageView.layer removeAllAnimations];
            weakSelf.animatedImageView.image = image;
            [weakSelf.animatedImageView.layer addAnimation:transition forKey:nil];
#else
            [weakSelf.imageView.layer removeAllAnimations];
            weakSelf.imageView.image = image;
            [weakSelf.imageView.layer addAnimation:transition forKey:nil];
#endif
        } failed:^(NSDictionary *info, HXPhotoModel *model) {
            if (weakSelf.model != model) return;
            weakSelf.progressView.hidden = YES;
        }];
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
                [weakSelf downloadICloudAssetComplete];
                weakSelf.progressView.hidden = YES;
#if HasSDWebImage
                UIImage *gifImage = [UIImage sd_imageWithGIFData:imageData];
                weakSelf.sdImageView.image = gifImage;
                weakSelf.gifImage = gifImage;
                if (gifImage.images.count == 0) {
                    weakSelf.gifFirstFrame = gifImage;
                }else {
                    weakSelf.gifFirstFrame = gifImage.images.firstObject;
                }
#elif HasYYKitOrWebImage
                YYImage *gifImage = [YYImage imageWithData:imageData];
                weakSelf.animatedImageView.image = gifImage;
                weakSelf.gifImage = gifImage;
#else
                UIImage *gifImage = [UIImage hx_animatedGIFWithData:imageData];
                weakSelf.imageView.image = gifImage;
                weakSelf.gifImage = gifImage;
                if (gifImage.images.count == 0) {
                    weakSelf.gifFirstFrame = gifImage;
                }else {
                    weakSelf.gifFirstFrame = gifImage.images.firstObject;
                }
#endif
                weakSelf.model.tempImage = nil;
            } failed:^(NSDictionary *info, HXPhotoModel *model) {
                if (weakSelf.model != model) return;
                weakSelf.progressView.hidden = YES;
            }];
        }
    }
}
- (void)cancelImage {
    
    if (self.requestID) {
        [[PHImageManager defaultManager] cancelImageRequest:self.requestID];
        self.requestID = -1;
    }
    if (self.model.type == HXPhotoModelMediaTypePhoto) {
#if HasYYWebImage
//        [self.animatedImageView yy_cancelCurrentImageRequest];
#elif HasYYKit
//        [self.animatedImageView cancelCurrentImageRequest];
#elif HasSDWebImage
//        [self.imageView sd_cancelCurrentAnimationImagesLoad];
#endif
    }else if (self.model.type == HXPhotoModelMediaTypePhotoGif) {
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
    if (!CGRectEqualToRect(self.sdImageView.frame, self.bounds)) {
        self.sdImageView.frame = self.bounds;
    }
#elif HasYYKitOrWebImage
    if (!CGRectEqualToRect(self.animatedImageView.frame, self.bounds)) {
        self.animatedImageView.frame = self.bounds;
    }
#else
    if (!CGRectEqualToRect(self.imageView.frame, self.bounds)) {
        self.imageView.frame = self.bounds;
    }
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
