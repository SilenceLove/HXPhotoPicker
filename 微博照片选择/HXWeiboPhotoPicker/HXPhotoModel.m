//
//  HXPhotoModel.m
//  微博照片选择
//
//  Created by 洪欣 on 17/2/8.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXPhotoModel.h"
#import "HXPhotoTools.h"
#import "UIImage+HXExtension.h"
#import <MediaPlayer/MediaPlayer.h>

@implementation HXPhotoModel 

+ (instancetype)photoModelWithImage:(UIImage *)image {
    return [[self alloc] initWithImage:image];
}

+ (instancetype)photoModelWithVideoURL:(NSURL *)videoURL videoTime:(NSTimeInterval)videoTime {
    return [[self alloc] initWithVideoURL:videoURL videoTime:videoTime];
}

- (instancetype)initWithVideoURL:(NSURL *)videoURL videoTime:(NSTimeInterval)videoTime {
    if (self = [super init]) {
        self.type = HXPhotoModelMediaTypeCameraVideo;
        self.subType = HXPhotoModelMediaSubTypeVideo;
        self.videoURL = videoURL;
        MPMoviePlayerController *player = [[MPMoviePlayerController alloc]initWithContentURL:videoURL] ;
        player.shouldAutoplay = NO;
        UIImage  *image = [player thumbnailImageAtTime:0.1 timeOption:MPMovieTimeOptionNearestKeyFrame];
        NSString *time = [HXPhotoTools getNewTimeFromDurationSecond:videoTime];
        self.videoURL = videoURL;
        self.videoTime = time;
        self.thumbPhoto = image;
    }
    return self;
}

- (instancetype)initWithImage:(UIImage *)image {
    self = [super init];
    if (self) {
        self.type = HXPhotoModelMediaTypeCameraPhoto;
        self.subType = HXPhotoModelMediaSubTypePhoto;
        if (image.imageOrientation != UIImageOrientationUp) {
            image = [image normalizedImage];
        }
        self.thumbPhoto = image;
        self.previewPhoto = image;
        self.imageSize = image.size;
    }
    return self;
}

- (CGSize)imageSize
{
    if (_imageSize.width == 0 || _imageSize.height == 0) {
        _imageSize = CGSizeMake(self.asset.pixelWidth, self.asset.pixelHeight);
    }
    return _imageSize;
}
- (NSString *)localIdentifier {
    if (!_localIdentifier) {
        _localIdentifier = self.asset.localIdentifier;
    }
    return _localIdentifier;
}
- (CGSize)endImageSize
{
    if (_endImageSize.width == 0 || _endImageSize.height == 0) {
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        CGFloat height = [UIScreen mainScreen].bounds.size.height - kNavigationBarHeight;
        CGFloat imgWidth = self.imageSize.width;
        CGFloat imgHeight = self.imageSize.height;
        CGFloat w;
        CGFloat h;
        imgHeight = width / imgWidth * imgHeight;
        if (imgHeight > height) {
            w = height / self.imageSize.height * imgWidth;
            h = height;
        }else {
            w = width;
            h = imgHeight;
        }
        _endImageSize = CGSizeMake(w, h);
    }
    return _endImageSize;
}

- (void)prefetchThumbImage {
//    __weak typeof(self) weakSelf = self;
//    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
//    option.resizeMode = PHImageRequestOptionsResizeModeFast;
//    PHCachingImageManager *cachingManager = [[PHCachingImageManager alloc] init];
//    
//    [cachingManager startCachingImagesForAssets:@[self.asset] targetSize:self.requestSize contentMode:PHImageContentModeAspectFill options:option];
    
//    self.requestID = [[PHImageManager defaultManager] requestImageForAsset:self.asset targetSize:self.requestSize contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
//        NSError *error = [info objectForKey:PHImageErrorKey];
//        BOOL cancel = [[info objectForKey:PHImageCancelledKey] boolValue];
//        BOOL degraded = [[info objectForKey:PHImageResultIsDegradedKey] boolValue];
//        if ((!error && !cancel && !degraded) && result) {
//            weakSelf.thumbPhoto = result; 
//        }
//    }];
//    self.requestID = [HXPhotoTools getHighQualityFormatPhotoForPHAsset:self.asset size:self.requestSize completion:^(UIImage *image, NSDictionary *info) {
//        weakSelf.thumbPhoto = image;
//    } error:^(NSDictionary *info) {
//        
//    }];
}

- (void)cancelImageRequest {
//    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
//    option.resizeMode = PHImageRequestOptionsResizeModeFast;
//    PHCachingImageManager *cachingManager = [[PHCachingImageManager alloc] init];
//    [cachingManager stopCachingImagesForAssets:@[self.asset] targetSize:self.requestSize contentMode:PHImageContentModeAspectFill options:option];
//    if (!self.thumbPhoto && self.requestID) {
//        [[PHImageManager defaultManager] cancelImageRequest:self.requestID];
//        self.requestID = -1;
//    }
}

- (CGSize)requestSize {
    if (_requestSize.width == 0 || _requestSize.height == 0) {
        CGFloat width = ([UIScreen mainScreen].bounds.size.width - 1 * self.rowCount - 1 ) / self.rowCount;
        CGSize size;
//        if (self.imageSize.width > self.imageSize.height / 9 * 15) {
//            size = CGSizeMake(width, width * [UIScreen mainScreen].scale);
//        }else if (self.imageSize.height > self.imageSize.width / 9 * 15) {
//            size = CGSizeMake(width * [UIScreen mainScreen].scale, width);
//        }else {
            if ([UIScreen mainScreen].bounds.size.width == 375) {
                size = CGSizeMake(width * 1.2, width * 1.2);
            }else {
                size = CGSizeMake(width * 1.4, width * 1.4);
            }
//        }
        if ([UIScreen mainScreen].bounds.size.width == 320) {
            size = CGSizeMake(width * 0.8, width * 0.8);
        }
        _requestSize = size;
    }
    return _requestSize;
}
- (void)dealloc {
//    [self cancelImageRequest];
}
@end
