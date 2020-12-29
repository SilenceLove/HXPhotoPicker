//
//  UIImageView+HXExtension.m
//  HXPhotoPickerExample
//
//  Created by Silence on 2018/2/14.
//  Copyright © 2018年 Silence. All rights reserved.
//

#import "UIImageView+HXExtension.h"
#import "HXPhotoDefine.h"
#import "HXPhotoModel.h"

#if __has_include(<SDWebImage/UIImageView+WebCache.h>)
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/SDWebImageManager.h>
#elif __has_include("UIImageView+WebCache.h")
#import "UIImageView+WebCache.h"
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
#import "HXPhotoEdit.h"

@implementation UIImageView (HXExtension)

- (void)hx_setImageWithModel:(HXPhotoModel *)model progress:(void (^)(CGFloat progress, HXPhotoModel *model))progressBlock completed:(void (^)(UIImage * image, NSError * error, HXPhotoModel * model))completedBlock {
    [self hx_setImageWithModel:model original:YES progress:progressBlock completed:completedBlock];
}

- (void)hx_setImageWithModel:(HXPhotoModel *)model original:(BOOL)original progress:(void (^)(CGFloat progress, HXPhotoModel *model))progressBlock completed:(void (^)(UIImage * image, NSError * error, HXPhotoModel * model))completedBlock {
    if (model.photoEdit) {
        UIImage *image = model.photoEdit.editPreviewImage;
        self.image = image;
        model.imageSize = image.size;
        model.thumbPhoto = image;
        model.previewPhoto = image;
        model.downloadComplete = YES;
        model.downloadError = NO;
        if (completedBlock) {
            completedBlock(image, nil, model);
        }
        return;
    }
    if (!model.networkThumbURL) model.networkThumbURL = model.networkPhotoUrl;
#if HasSDWebImage
    HXWeakSelf
    NSString *cacheKey = [[SDWebImageManager sharedManager] cacheKeyForURL:model.networkPhotoUrl];
    [[SDWebImageManager sharedManager].imageCache queryImageForKey:cacheKey options:SDWebImageQueryMemoryData context:nil completion:^(UIImage * _Nullable image, NSData * _Nullable data, SDImageCacheType cacheType) {
        if (image) {
            weakSelf.image = image;
            model.imageSize = image.size;
            model.thumbPhoto = image;
            model.previewPhoto = image;
            model.downloadComplete = YES;
            model.downloadError = NO;
            if (completedBlock) {
                completedBlock(image, nil, model);
            }
        }else {
            NSURL *url = (original || image) ? model.networkPhotoUrl : model.networkThumbURL;
            [weakSelf sd_setImageWithURL:url placeholderImage:model.thumbPhoto options:0 context:nil progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
                model.receivedSize = receivedSize;
                model.expectedSize = expectedSize;
                CGFloat progress = (CGFloat)receivedSize / expectedSize;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (progressBlock) {
                        progressBlock(progress, model);
                    }
                });
            } completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                model.downloadComplete = YES;
                if (error != nil) {
                    model.downloadError = YES;
                }else {
                    if (image) {
                        weakSelf.image = image;
                        model.imageSize = image.size;
                        model.thumbPhoto = image;
                        model.previewPhoto = image;
                        model.downloadError = NO;
                    }
                }
                if (completedBlock) {
                    completedBlock(image,error,model);
                }
            }];
        }
    }];
#elif HasYYKitOrWebImage
    HXWeakSelf
    YYWebImageManager *manager = [YYWebImageManager sharedManager];
    [manager.cache getImageForKey:[manager cacheKeyForURL:model.networkPhotoUrl]  withType:YYImageCacheTypeAll withBlock:^(UIImage * _Nullable image, YYImageCacheType type) {
        if (image) {
            weakSelf.image = image;
            model.imageSize = weakSelf.image.size;
            model.thumbPhoto = weakSelf.image;
            model.previewPhoto = weakSelf.image;
            model.downloadComplete = YES;
            model.downloadError = NO;
            if (completedBlock) {
                completedBlock(weakSelf.image, nil, model);
            }
        }else {
            NSURL *url = original ? model.networkPhotoUrl : model.networkThumbURL;
            [weakSelf yy_setImageWithURL:url placeholder:model.thumbPhoto options:YYWebImageOptionShowNetworkActivity progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                model.receivedSize = receivedSize;
                model.expectedSize = expectedSize;
                CGFloat progress = (CGFloat)receivedSize / expectedSize;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (progressBlock) {
                        progressBlock(progress, model);
                    }
                });
            } transform:^UIImage * _Nullable(UIImage * _Nonnull image, NSURL * _Nonnull url) {
                return image;
            } completion:^(UIImage * _Nullable image, NSURL * _Nonnull url, YYWebImageFromType from, YYWebImageStage stage, NSError * _Nullable error) {
                if (error != nil) {
                    model.downloadError = YES;
                    model.downloadComplete = YES;
                }else {
                    if (image) {
                        weakSelf.image = image;
                        model.imageSize = image.size;
                        model.thumbPhoto = image;
                        model.previewPhoto = image;
                        model.downloadComplete = YES;
                        model.downloadError = NO;
                    }
                }
                if (completedBlock) {
                    completedBlock(image,error,model);
                }
            }];
        }
    }];
#else
    /// 如果都是pod导入的提示找不到话，先将SD或YY 和 HX 的pod全部移除，再 pod install
    /// 然后再 pod HXPhotoPicker/SDWebImage 或者 HXPhotoPicker/YYWebImage
    NSSLog(@"请导入YYWebImage/SDWebImage后再使用网络图片功能");
//    NSAssert(NO, @"请导入YYWebImage/SDWebImage后再使用网络图片功能，HXPhotoPicker为pod导入的那么YY或者SD也必须是pod导入的否则会找不到");
#endif
}

- (void)hx_setImageWithURL:(NSURL *)url
                  progress:(void (^)(CGFloat progress))progressBlock
                 completed:(void (^)(UIImage * image, NSError * error))completedBlock {

#if HasSDWebImage
    HXWeakSelf
    [self sd_setImageWithURL:url placeholderImage:nil options:0 context:nil progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
        CGFloat progress = (CGFloat)receivedSize / expectedSize;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (progressBlock) {
                progressBlock(progress);
            }
        });
    } completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        weakSelf.image = image;
        if (completedBlock) {
            completedBlock(image, error);
        }
    }];
#elif HasYYKitOrWebImage
    HXWeakSelf
    [self yy_setImageWithURL:url placeholder:nil options:YYWebImageOptionShowNetworkActivity progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        CGFloat progress = (CGFloat)receivedSize / expectedSize;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (progressBlock) {
                progressBlock(progress);
            }
        });
    } transform:^UIImage * _Nullable(UIImage * _Nonnull image, NSURL * _Nonnull url) {
        return image;
    } completion:^(UIImage * _Nullable image, NSURL * _Nonnull url, YYWebImageFromType from, YYWebImageStage stage, NSError * _Nullable error) {
        weakSelf.image = image;
        if (completedBlock) {
            completedBlock(image, error);
        }
    }];
#else
    /// 如果都是pod导入的提示找不到话，先将SD或YY 和 HX 的pod全部移除，再 pod install
    /// 然后再 pod HXPhotoPicker/SDWebImage 或者 HXPhotoPicker/YYWebImage
    NSSLog(@"请导入YYWebImage/SDWebImage后再使用网络图片功能");
//    NSAssert(NO, @"请导入YYWebImage/SDWebImage后再使用网络图片功能，HXPhotoPicker为pod导入的那么YY或者SD也必须是pod导入的否则会找不到");
#endif
}
@end
