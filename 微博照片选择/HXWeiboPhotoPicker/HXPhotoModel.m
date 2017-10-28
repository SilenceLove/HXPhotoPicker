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

- (NSURL *)fileURL {
    if (self.type == HXPhotoModelMediaTypeCameraVideo) {
        return self.videoURL;
    }
    if (self.type != HXPhotoModelMediaTypeCameraPhoto) {
        return [self.asset valueForKey:@"mainFileURL"];
    }
    return nil;
}

- (NSDate *)creationDate {
    if (self.type == HXPhotoModelMediaTypeCameraPhoto || self.type == HXPhotoModelMediaTypeCameraVideo) {
        return [NSDate date];
    }
    return [self.asset valueForKey:@"creationDate"];
}

- (NSDate *)modificationDate {
    if (self.type == HXPhotoModelMediaTypeCameraPhoto || self.type == HXPhotoModelMediaTypeCameraVideo) {
        return [NSDate date];
    }
    return [self.asset valueForKey:@"modificationDate"];
}

- (NSData *)locationData {
    return [self.asset valueForKey:@"locationData"];
}

- (CLLocation *)location {
    return [self.asset valueForKey:@"location"];
}

+ (instancetype)photoModelWithPHAsset:(PHAsset *)asset {
    return [[self alloc] initWithPHAsset:asset];
}

+ (instancetype)photoModelWithImage:(UIImage *)image {
    return [[self alloc] initWithImage:image];
}

+ (instancetype)photoModelWithVideoURL:(NSURL *)videoURL videoTime:(NSTimeInterval)videoTime {
    return [[self alloc] initWithVideoURL:videoURL videoTime:videoTime];
}

- (instancetype)initWithPHAsset:(PHAsset *)asset{
    if (self = [super init]) {
        self.asset = asset;
        self.type = HXPhotoModelMediaTypePhoto;
        self.type = HXPhotoModelMediaSubTypePhoto;
    }
    return self;
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
        if (self.asset) {
            _imageSize = CGSizeMake(self.asset.pixelWidth, self.asset.pixelHeight);
        }else {
            _imageSize = self.thumbPhoto.size;
        }
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
- (CGSize)endDateImageSize {
    if (_endDateImageSize.width == 0 || _endDateImageSize.height == 0) {
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        CGFloat height = [UIScreen mainScreen].bounds.size.height - kTopMargin - kBottomMargin;
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft){
            if (kDevice_Is_iPhoneX) {
                height = [UIScreen mainScreen].bounds.size.height - kTopMargin - 21;
            }
        }
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
        _endDateImageSize = CGSizeMake(w, h);
    }
    return _endDateImageSize;
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
                size = CGSizeMake(width * 1.4, width * 1.4);
            }else {
                size = CGSizeMake(width * 1.7, width * 1.7);
            }
//        }
        if ([UIScreen mainScreen].bounds.size.width == 320) {
            size = CGSizeMake(width * 0.8, width * 0.8);
        }
        _requestSize = size;
    }
    return _requestSize;
}
- (CGSize)dateBottomImageSize {
    if (_dateBottomImageSize.width == 0 || _dateBottomImageSize.height == 0) {
        CGFloat width = 0;
        CGFloat height = 50;
        CGFloat imgWidth = self.imageSize.width;
        CGFloat imgHeight = self.imageSize.height;
        if (imgHeight > height) {
            width = imgWidth * (height / imgHeight);
        }else {
            width = imgWidth * (imgHeight / height);
        }
        if (width < 50 / 16 * 9) {
            width = 50 / 16 * 9;
        }
        _dateBottomImageSize = CGSizeMake(width, height);
    }
    return _dateBottomImageSize;
}
- (NSString *)barTitle {
    if (!_barTitle) {
        if ([self.creationDate isToday]) {
            _barTitle = @"今天";
        }else if ([self.creationDate isYesterday]) {
            _barTitle = @"昨天";
        }else if ([self.creationDate isSameWeek]) {
            _barTitle = [self.creationDate getNowWeekday];
        }else if ([self.creationDate isThisYear]) {
            _barTitle = [NSString stringWithFormat:@"%@ %@",[self.creationDate dateStringWithFormat:@"MM月dd日"],[self.creationDate getNowWeekday]];
        }else {
            _barTitle = [self.creationDate dateStringWithFormat:@"yyyy年MM月dd日"];
        }
    }
    return _barTitle;
}
- (NSString *)barSubTitle {
    if (!_barSubTitle) {
        _barSubTitle = [self.creationDate dateStringWithFormat:@"HH:mm"];
    }
    return _barSubTitle;
}
- (void)dealloc {
//    [self cancelImageRequest];
}
@end

@implementation HXPhotoDateModel
- (NSString *)dateString {
    if (!_dateString) {
        
        if ([self.date isToday]) {
            _dateString = @"今天";
        }else if ([self.date isYesterday]) {
            _dateString = @"昨天";
        }else if ([self.date isSameWeek]) {
            _dateString = [self.date getNowWeekday];
        }else if ([self.date isThisYear]) {
            _dateString = [NSString stringWithFormat:@"%@ %@",[self.date dateStringWithFormat:@"MM月dd日"],[self.date getNowWeekday]];
        }else {
            _dateString = [self.date dateStringWithFormat:@"yyyy年MM月dd日"];
        }
    }
    return _dateString;
}
- (NSMutableArray *)locationList {
    if (!_locationList) {
        _locationList = [NSMutableArray array];
    }
    return _locationList;
}
@end
